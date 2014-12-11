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

class APInt;
class Constant;
class DataLayout;
class GlobalValue;
class StringRef;

class StoreInitializer {
public:
  // Track offset wher the the address of a global needs to be inserted.
  struct VarInitOffset {
    uint64_t BaseOffset;
    uint64_t VarOffset;
    const GlobalValue *GV;

    VarInitOffset(uint64_t Base, const GlobalValue *G, uint64_t Var)
      : BaseOffset(Base),
        VarOffset(Var),
        GV(G) {}
  };

private:
  uint32_t InitEltSize;
  const DataLayout &DL;

  SmallString<1024> m_data;
  raw_svector_ostream OS;
  support::endian::Writer<support::little> LE;

  std::vector<VarInitOffset> VarInitAddresses;

  void initVarWithAddress(const GlobalValue *GV, StringRef Var,
                          const APInt &Offset);

public:
  StoreInitializer(uint32_t InitEltSize, const DataLayout &DL);

  void append(const Constant *CV, StringRef Var);

  ArrayRef<VarInitOffset> varInitAddresses() const {
    return makeArrayRef(VarInitAddresses);
  }

  StringRef str() const {
    return StringRef(m_data);
  }

  size_t elementCount() {
    return dataSizeInBytes() / InitEltSize;
  }

  size_t dataSizeInBytes() {
    // Be sure to flush the stream before computing the size.
    return OS.str().size();
  }
};

}

#endif
