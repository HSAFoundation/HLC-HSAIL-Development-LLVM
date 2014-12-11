//===-- HSAILStoreInitializer.cpp -----------------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "HSAILStoreInitializer.h"
#include "HSAILUtilityFunctions.h"

#include "BRIGAsmPrinter.h"

#include "llvm/ADT/SmallString.h"
#include "llvm/IR/Constants.h"
#include "llvm/Support/raw_ostream.h"

#include "libHSAIL/Brig.h"

using namespace llvm;
using namespace HSAIL_ASM;

StoreInitializer::StoreInitializer(Brig::BrigType16_t type,
                                   BRIGAsmPrinter &asmPrinter)
  : m_type(type),
    m_asmPrinter(asmPrinter),
    DL(m_asmPrinter.getDataLayout()),
    Subtarget(m_asmPrinter.getSubtarget()),
    m_reqNumZeroes(0),
    m_data(),
    OS(m_data),
    LE(OS) {

//  assert(m_type == Brig::BRIG_TYPE_U8);
}

void StoreInitializer::initVarWithAddress(const GlobalValue *GV, StringRef Var,
                                          const APInt &Offset) {
  SmallString<256> InitStr;
  raw_svector_ostream O(InitStr);

  assert(GV->hasName()); // FIXME: Anonymous global are allowed.

  O << "initvarwithaddress:" << Var << ':' << dataSizeInBytes() << ':'
    << HSAIL_ASM::getBrigTypeNumBytes(m_type) << ':'
    << BRIGAsmPrinter::getSymbolPrefix(*GV)
    << GV->getName() << ':' << Offset.toString(10, false);

  HSAIL_ASM::DirectivePragma pgm =
      m_asmPrinter.brigantine.append<HSAIL_ASM::DirectivePragma>();
  HSAIL_ASM::ItemList opnds;

  StringRef Str(O.str());
  opnds.push_back(m_asmPrinter.brigantine.createOperandString(HSAIL_ASM::SRef(Str.begin(), Str.end())));
  pgm.operands() = opnds;

  unsigned AS = GV->getType()->getAddressSpace();
  if (DL.getPointerSize(AS) == 8)
    LE.write(static_cast<uint64_t>(0));
  else
    LE.write(static_cast<uint32_t>(0));
}

void StoreInitializer::append(const Constant *CV, StringRef Var) {
  switch (CV->getValueID()) {
  case Value::ConstantArrayVal: { // Recursive type.
    const ConstantArray *CA = cast<ConstantArray>(CV);
    for (unsigned I = 0, E = CA->getNumOperands(); I < E; ++I)
      append(cast<Constant>(CA->getOperand(I)), Var);

    break;
  }
  case Value::ConstantDataArrayVal: {
    const ConstantDataArray *CVE = cast<ConstantDataArray>(CV);
    for (unsigned I = 0, E = CVE->getNumElements(); I < E; ++I)
      append(cast<Constant>(CVE->getElementAsConstant(I)), Var);

    break;
  }
  case Value::ConstantStructVal: { // Recursive type.
    const ConstantStruct *S = cast<ConstantStruct>(CV);
    StructType *ST = S->getType();
    const StructLayout *SL = DL.getStructLayout(ST);

    uint64_t StructSize = DL.getTypeAllocSize(ST);
    uint64_t BaseOffset = SL->getElementOffset(0);

    for (unsigned I = 0, E = S->getNumOperands(); I < E; ++I) {
      Constant *Elt = cast<Constant>(S->getOperand(I));
      append(Elt, Var);

      uint64_t EltSize = DL.getTypeAllocSize(Elt->getType());
      uint64_t EltOffset = SL->getElementOffset(I);

      uint64_t PaddedEltSize;
      if (I == E - 1)
        PaddedEltSize = BaseOffset + StructSize - EltOffset;
      else
        PaddedEltSize = SL->getElementOffset(I + 1) - EltOffset;

      // Match structure layout by padding with zeroes.
      while (EltSize < PaddedEltSize) {
        LE.write(static_cast<uint8_t>(0));
        ++EltSize;
      }
    }
    break;
  }
  case Value::ConstantVectorVal: { // Almost leaf type.
    const ConstantVector *CVE = cast<ConstantVector>(CV);
    for (unsigned I = 0, E = CVE->getType()->getNumElements(); I < E; ++I)
      append(cast<Constant>(CVE->getOperand(I)), Var);
    break;
  }
  case Value::ConstantDataVectorVal: {
    const ConstantDataVector *CVE = cast<ConstantDataVector>(CV);
    for (unsigned I = 0, E = CVE->getNumElements(); I < E; ++I)
      append(cast<Constant>(CVE->getElementAsConstant(I)), Var);

    break;
  }
  case Value::ConstantIntVal: {
    const ConstantInt *CI = cast<ConstantInt>(CV);
    if (CI->getType()->isIntegerTy(1)) {
      //pushValue<BRIG_TYPE_B1>(CI->getZExtValue() ? 1 : 0);
      //XXX
      LE.write(static_cast<uint8_t>(CI->getZExtValue() ? 1 : 0));
    } else {
      switch (CI->getBitWidth()) {
      case 8:
        LE.write(static_cast<uint8_t>(CI->getZExtValue()));
        break;
      case 16:
        LE.write(static_cast<uint16_t>(CI->getZExtValue()));
        break;
      case 32:
        LE.write(static_cast<uint32_t>(CI->getZExtValue()));
        break;
      case 64:
        LE.write(static_cast<uint64_t>(CI->getZExtValue()));
        break;
      }
    }
    break;
  }
  case Value::ConstantFPVal: {
    const ConstantFP *CFP = cast<ConstantFP>(CV);
    if (CFP->getType()->isFloatTy())
      LE.write(CFP->getValueAPF().convertToFloat());
    else if (CFP->getType()->isDoubleTy())
      LE.write(CFP->getValueAPF().convertToDouble());
    else
      llvm_unreachable("unhandled ConstantFP type");
    break;
  }
  case Value::ConstantPointerNullVal: {
    unsigned AS = CV->getType()->getPointerAddressSpace();
    if (DL.getPointerSize(AS) == 8)
      LE.write(static_cast<uint64_t>(0));
    else
      LE.write(static_cast<uint32_t>(0));
    break;
  }
  case Value::ConstantAggregateZeroVal:
    m_reqNumZeroes += HSAIL::getNumElementsInHSAILType(CV->getType(), DL);
    llvm_unreachable("FIXME");
    break;

  case Value::ConstantExprVal: {
    const ConstantExpr *CE = cast<ConstantExpr>(CV);
    if (CE->isGEPWithNoNotionalOverIndexing()) {
      const GEPOperator *GO = dyn_cast<GEPOperator>(CE);
      if (GO) {
        const Value *Ptr = GO->getPointerOperand()->stripPointerCasts();
        assert(Ptr && Ptr->hasName());
        unsigned AS = GO->getPointerAddressSpace();
        unsigned PtrSize = DL.getPointerSizeInBits(AS);
        APInt Offset(PtrSize, 0);
        if (!GO->accumulateConstantOffset(DL, Offset))
          llvm_unreachable("Cannot calculate initializer offset");
        initVarWithAddress(cast<GlobalValue>(Ptr), Var, Offset);
      } else {
        llvm_unreachable("Unhandled ConstantExpr initializer instruction");
      }
    } else if (CE->getOpcode() == Instruction::BitCast) {
      append(cast<Constant>(CE->getOperand(0)), Var);
    } else {
      llvm_unreachable("Unhandled ConstantExpr initializer type");
    }
    break;
  }
  case Value::GlobalVariableVal: {
    const Value *V = CV->stripPointerCasts();

    // FIXME: It is incorrect to stripPointerCasts through an addrspacecast.
    unsigned AS = cast<PointerType>(V->getType())->getAddressSpace();
    unsigned PtrSize = DL.getPointerSizeInBits(AS);
    initVarWithAddress(cast<GlobalValue>(V), Var, APInt(PtrSize, 0));
    break;
  }
  default:
    llvm_unreachable("unhandled initializer");
  }
}
