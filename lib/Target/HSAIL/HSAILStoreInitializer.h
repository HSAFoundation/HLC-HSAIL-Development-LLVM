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

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/Support/EndianStream.h"

#include <vector>

namespace llvm {

class AsmPrinter;
class APInt;
class Constant;
class DataLayout;
class GlobalValue;
class MCExpr;
class StringRef;
class Type;

class StoreInitializer {
public:
  // Track offset wher the the address of a global needs to be inserted.
  struct VarInitOffset {
    uint64_t BaseOffset;
    const MCExpr *Expr;

    VarInitOffset(uint64_t Offset, const MCExpr *E)
        : BaseOffset(Offset), Expr(E) {}
  };

private:
  const DataLayout &DL;
  AsmPrinter &AP;
  uint32_t InitEltSize;
  bool IsFPElt;

  SmallString<1024> m_data;
  raw_svector_ostream OS;
  support::endian::Writer<support::little> LE;

  std::vector<VarInitOffset> VarInitAddresses;

  void initVarWithAddress(const GlobalValue *GV, StringRef Var,
                          const APInt &Offset);

  void printFloat(uint32_t, raw_ostream &O);
  void printDouble(uint64_t, raw_ostream &O);

public:
  StoreInitializer(Type *EltTy, AsmPrinter &AP);

  void append(const Constant *CV, StringRef Var);

  ArrayRef<VarInitOffset> varInitAddresses() const {
    return makeArrayRef(VarInitAddresses);
  }

  StringRef str() { return OS.str(); }

  size_t elementCount() { return dataSizeInBytes() / InitEltSize; }

  size_t dataSizeInBytes() {
    // Be sure to flush the stream before computing the size.
    return OS.str().size();
  }

  void print(raw_ostream &O);
};
}

#endif
