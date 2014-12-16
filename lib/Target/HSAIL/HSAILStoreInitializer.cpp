//===-- HSAILStoreInitializer.cpp -----------------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "HSAILStoreInitializer.h"

#include "llvm/ADT/SmallString.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

StoreInitializer::StoreInitializer(uint32_t EltSize,
                                   AsmPrinter &AP)
  : InitEltSize(EltSize),
    DL(AP.getDataLayout()),
    AP(AP),
    m_data(),
    OS(m_data),
    LE(OS) {}

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
  case Value::ConstantAggregateZeroVal: {
    uint64_t Size = DL.getTypeAllocSize(CV->getType());
    for (uint64_t I = 0; I < Size / InitEltSize; ++I) {
      switch (InitEltSize) {
      case 1:
        LE.write(static_cast<uint8_t>(0));
        break;
      case 2:
        LE.write(static_cast<uint16_t>(0));
        break;
      case 4:
        LE.write(static_cast<uint32_t>(0));
        break;
      case 8:
        LE.write(static_cast<uint64_t>(0));
        break;
      default:
        llvm_unreachable("unhandled size");
      }
    }

    break;
  }
  case Value::GlobalVariableVal:
  case Value::ConstantExprVal: {
    const MCExpr *Expr = AP.lowerConstant(CV);

    // Offset that address needs to be written at is the current size of the
    // buffer.
    uint64_t CurrOffset = dataSizeInBytes();

    unsigned Size = DL.getTypeAllocSize(CV->getType());
    switch (Size) {
    case 4:
      LE.write(static_cast<uint32_t>(0));
      break;
    case 8:
      LE.write(static_cast<uint64_t>(0));
      break;
    default:
      llvm_unreachable("unhandled size");
    }

    VarInitAddresses.emplace_back(CurrOffset, Expr);
    break;
  }
  default:
    llvm_unreachable("unhandled initializer");
  }
}
