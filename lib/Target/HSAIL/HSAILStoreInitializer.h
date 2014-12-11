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

#include "llvm/ADT/SmallString.h"
#include "llvm/Support/EndianStream.h"

#include "libHSAIL/HSAILItems.h"

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

  SmallString<1024> m_data;
  raw_svector_ostream OS;
  support::endian::Writer<support::little> LE;

  void initVarWithAddress(const GlobalValue *GV, StringRef Var,
                          const APInt &Offset);

public:
  StoreInitializer(Brig::BrigType16_t type, BRIGAsmPrinter &asmPrinter);

  void append(const Constant *CV, StringRef Var);

  StringRef str() const {
    return StringRef(m_data);
  }

  size_t elementCount() {
    return dataSizeInBytes() / HSAIL_ASM::getBrigTypeNumBytes(m_type);
  }

  size_t dataSizeInBytes() {
    // Be sure to flush the stream before computing the size.
    return OS.str().size();
  }
};

}

#endif
