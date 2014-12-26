//===- llvm/Analysis/AMDKernelSymbols.h - Find Kernel symbols ---*- C++ -*-===//
//
// Copyright (c) 2012 Advanced Micro Devices, Inc. All rights reserved.
//
//===----------------------------------------------------------------------===//
//
// Find all AMD Kernel specific symbols.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_ANALYSIS_AMDKERNELSYMBOLS_H
#define LLVM_ANALYSIS_AMDKERNELSYMBOLS_H

#include "llvm/ADT/SetVector.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/IR/Function.h"

namespace llvm {

class Module;

class KernelSymbols {
protected:
  // We use SetVector instead of a Set to make the iterator deterministic
  // between different runs.
  // We use SetVector instead of a Vector for fast search.
  //
  typedef SetVector<const Function *,
                    SmallVector<const Function *, 16>,
                    SmallPtrSet<const Function *, 8> >      FuncsSet;
  typedef SetVector<const GlobalValue *,
                    SmallVector<const GlobalValue *, 16>,
                    SmallPtrSet<const GlobalValue *, 8> >   GlobalsSet;

  FuncsSet Kernels;
  FuncsSet Stubs;
  GlobalsSet Reserved;

public:
  static char ID; // Class identification, replacement for typeinfo

  KernelSymbols() { }

  /// replaceKernel - Replace the kernel function by another.
  void replaceKernel(const Function *From, const Function *To);

  /// replaceStub - Replace the stub function by another.
  void replaceStub(const Function *From, const Function *To);

  /// replaceGlobal - Replace the global value by another.
  void replaceGlobal(const GlobalValue *From, const GlobalValue *To);

  const Function *getStubOfKernel(const Function *Kernel) const;
  const Function *getKernelOfStub(const Function *Stub) const;

  bool isKernel(const Function *F) const { return Kernels.count(F); }
  bool isStub(const Function *F) const { return Stubs.count(F); }
  bool isReserved(const GlobalValue *GV) const { return Reserved.count(GV); }

  bool isKnown(const Function *F) const {
    return isKernel(F) || isStub(F) || isReserved(F);
  }
  bool isKnown(const GlobalValue *GV) const {
      return !isa<Function>(GV) ? isReserved(GV) : isKnown(cast<Function>(GV));
  }

  unsigned getNumKernels() const { return (unsigned)Kernels.size(); }
  unsigned getNumStubs() const { return (unsigned)Stubs.size(); }
  unsigned getNumReservedGlobals() const { return (unsigned)Reserved.size(); }

  typedef FuncsSet::iterator kernels_iterator;
  typedef FuncsSet::const_iterator const_kernels_iterator;
  //===--------------------------------------------------------------------===//
  // Kernels iterator forwarding functions
  //
  kernels_iterator        kernels_begin()       { return Kernels.begin(); }
  const_kernels_iterator  kernels_begin() const { return Kernels.begin(); }
  kernels_iterator        kernels_end  ()       { return Kernels.end();   }
  const_kernels_iterator  kernels_end  () const { return Kernels.end();   }

  size_t                  kernels_size () const { return Kernels.size();  }
  bool                    kernels_empty() const { return Kernels.empty(); }


  typedef FuncsSet::iterator stubs_iterator;
  typedef FuncsSet::const_iterator const_stubs_iterator;
  //===--------------------------------------------------------------------===//
  // Stubs iterator forwarding functions
  //
  stubs_iterator        stubs_begin()       { return Stubs.begin(); }
  const_stubs_iterator  stubs_begin() const { return Stubs.begin(); }
  stubs_iterator        stubs_end  ()       { return Stubs.end();   }
  const_stubs_iterator  stubs_end  () const { return Stubs.end();   }

  size_t                stubs_size () const { return Stubs.size();  }
  bool                  stubs_empty() const { return Stubs.empty(); }
};

} // End llvm namespace

#endif
