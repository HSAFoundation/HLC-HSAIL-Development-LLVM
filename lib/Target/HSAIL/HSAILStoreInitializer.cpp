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
    m_reqNumZeroes(0) {}

template <Brig::BrigTypeX BrigTypeId>
void StoreInitializer::pushValue(
    typename HSAIL_ASM::BrigType<BrigTypeId>::CType value) {
  using namespace Brig;

  // Need to check whether BrigTypeId matches initializer type.
  if (m_type == HSAIL_ASM::BrigType<BrigTypeId>::asBitType::value) {
    pushValueImpl<BrigTypeId>(value);
    return;
  }

  assert(m_type == BRIG_TYPE_B8); // struct case
  const uint8_t(&src)[sizeof(value)] =
    *reinterpret_cast<const uint8_t(*)[sizeof(value)]>(&value);

  for (unsigned int i = 0; i < sizeof(value); ++i)
    pushValueImpl<BRIG_TYPE_U8>(src[i]);
}

template <Brig::BrigTypeX BrigTypeId>
void StoreInitializer::pushValueImpl(
    typename HSAIL_ASM::BrigType<BrigTypeId>::CType value) {

  assert(m_type == HSAIL_ASM::BrigType<BrigTypeId>::asBitType::value);
  typedef typename HSAIL_ASM::BrigType<BrigTypeId>::CType CType;
  if (m_reqNumZeroes > 0) {
    for (unsigned i = m_reqNumZeroes; i > 0; --i)
      m_data.push_back(CType());

    m_reqNumZeroes = 0;
  }

  m_data.push_back(value);
}

void StoreInitializer::initVarWithAddress(const Value *V, StringRef Var,
                                          const APInt &Offset) {
  SmallString<256> InitStr;
  raw_svector_ostream O(InitStr);

  const GlobalVariable *GV = cast<GlobalVariable>(V);
  assert(V->hasName()); // FIXME: Anonymous global are allowed.

  O << "initvarwithaddress:" << Var << ':' << dataSizeInBytes() << ':'
    << HSAIL_ASM::getBrigTypeNumBytes(m_type) << ':'
    << BRIGAsmPrinter::getSymbolPrefix(*GV)
    << V->getName() << ':' << Offset.toString(10, false);

  HSAIL_ASM::DirectivePragma pgm =
      m_asmPrinter.brigantine.append<HSAIL_ASM::DirectivePragma>();
  HSAIL_ASM::ItemList opnds;

  StringRef Str(O.str());
  opnds.push_back(m_asmPrinter.brigantine.createOperandString(HSAIL_ASM::SRef(Str.begin(), Str.end())));
  pgm.operands() = opnds;

  unsigned AS = GV->getType()->getAddressSpace();
  if (DL.getPointerSize(AS) == 8)
    pushValue<Brig::BRIG_TYPE_B64>(0);
  else
    pushValue<Brig::BRIG_TYPE_B32>(0);
}

void StoreInitializer::append(const Constant *CV, StringRef Var) {
  using namespace Brig;

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
    const ConstantStruct *s = cast<ConstantStruct>(CV);
    const StructLayout *layout = DL.getStructLayout(s->getType());
    uint64_t const initStartOffset = m_data.numBytes();
    for (unsigned i = 0, e = s->getNumOperands(); i < e; ++i) {
      append(cast<Constant>(s->getOperand(i)), Var);
      // Match structure layout by padding with zeroes
      uint64_t const nextElemOffset = (i + 1) < e
                                          ? layout->getElementOffset(i + 1)
                                          : layout->getSizeInBytes();
      uint64_t const structInitSize = m_data.numBytes() - initStartOffset;
      assert(nextElemOffset >= structInitSize);
      m_reqNumZeroes = nextElemOffset - structInitSize;
      if (m_reqNumZeroes) {
        m_reqNumZeroes--;
        pushValue<BRIG_TYPE_U8>(0);
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
      pushValue<BRIG_TYPE_B1>(CI->getZExtValue() ? 1 : 0);
    } else {
      switch (CI->getBitWidth()) {
      case 8:
        pushValue<BRIG_TYPE_U8>(*CI->getValue().getRawData());
        break;
      case 16:
        pushValue<BRIG_TYPE_U16>(*CI->getValue().getRawData());
        break;
      case 32:
        pushValue<BRIG_TYPE_U32>(*CI->getValue().getRawData());
        break;
      case 64:
        pushValue<BRIG_TYPE_U64>(*CI->getValue().getRawData());
        break;
      }
    }
    break;
  }
  case Value::ConstantFPVal: {
    const ConstantFP *CFP = cast<ConstantFP>(CV);
    if (CFP->getType()->isFloatTy()) {
      pushValue<BRIG_TYPE_F32>(HSAIL_ASM::f32_t::fromRawBits(
          *CFP->getValueAPF().bitcastToAPInt().getRawData()));
    } else if (CFP->getType()->isDoubleTy()) {
      pushValue<BRIG_TYPE_F64>(HSAIL_ASM::f64_t::fromRawBits(
          *CFP->getValueAPF().bitcastToAPInt().getRawData()));
    }
    break;
  }
  case Value::ConstantPointerNullVal:
    if (Subtarget.is64Bit())
      pushValue<BRIG_TYPE_B64>(0);
    else
      pushValue<BRIG_TYPE_B32>(0);

    break;

  case Value::ConstantAggregateZeroVal:
    m_reqNumZeroes += HSAIL::getNumElementsInHSAILType(CV->getType(), DL);
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
        initVarWithAddress(Ptr, Var, Offset);
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
    assert(V->hasName());

    unsigned AS = cast<PointerType>(V->getType())->getAddressSpace();
    unsigned PtrSize = DL.getPointerSizeInBits(AS);
    initVarWithAddress(V, Var, APInt(PtrSize, 0));
    break;
  }
  default:
    llvm_unreachable("unhandled initializer");
  }
}
