//===-- HSAILStoreInitializer.h ---------------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_HSAIL_HSAILSTOREINITIALIZER_H
#define LLVM_LIB_TARGET_HSAIL_HSAILSTOREINITIALIZER_H

#include "libHSAIL/HSAILItems.h"
#include "libHSAIL/HSAILUtilities.h"

namespace llvm {

class APInt;
class BRIGAsmPrinter;
class Constant;
class DataLayout;
class GlobalValue;
class HSAILSubtarget;
class StringRef;

class StoreInitializer {
private:
  Brig::BrigType16_t m_type;
  BRIGAsmPrinter &m_asmPrinter;
  const DataLayout &DL;
  const HSAILSubtarget &Subtarget;
  unsigned m_reqNumZeroes;
  HSAIL_ASM::ArbitraryData m_data;

  template <Brig::BrigTypeX BrigTypeId>
  void pushValue(typename HSAIL_ASM::BrigType<BrigTypeId>::CType value);

  template <Brig::BrigTypeX BrigTypeId>
  void pushValueImpl(typename HSAIL_ASM::BrigType<BrigTypeId>::CType value);

  void initVarWithAddress(const GlobalValue *GV, StringRef Var,
                          const APInt &Offset);

public:
  StoreInitializer(Brig::BrigType16_t type, BRIGAsmPrinter &asmPrinter);

  void append(const Constant *CV, StringRef Var);

  HSAIL_ASM::SRef toSRef() const {
    return m_data.toSRef();
  }

  size_t elementCount() const {
    return m_data.numBytes() / HSAIL_ASM::getBrigTypeNumBytes(m_type);
  }

  size_t dataSizeInBytes() const {
    return m_data.numBytes();
  }
};

}

#endif
