//===-- AMDOpenCLKernenv.h - HSAIL kernenv for OpenCL -----*- C++ -*---=======//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// \file
// \brief Declare OpenCL dispatch-specific constants that are passed
//        as additional arguments (the "kernenv") to the HSAIL kernel.
//
//===----------------------------------------------------------------------===//

#ifndef __AMD_OPENCL_KERNENV_H__
#define __AMD_OPENCL_KERNENV_H__

#include <llvm/ADT/StringRef.h>
#include <llvm/IR/DerivedTypes.h>
#include <llvm/Support/ErrorHandling.h>

namespace llvm {
class LLVMContext;

namespace HSAIL {
enum {
  KE_GOFFSET_0,
  KE_GOFFSET_1,
  KE_GOFFSET_2,
  KE_OCL12_NUM_ARGS,
  KE_PRINTF_BFR = KE_OCL12_NUM_ARGS,
  KE_VQ_PTR,
  KE_AQLWRAP_PTR,
  KE_OCL20_NUM_ARGS,
  KE_NUM_ARGS = KE_OCL20_NUM_ARGS // Always the last member.
};
}

static inline StringRef getKernenvArgName(unsigned ID) {
  switch (ID) {
  case HSAIL::KE_GOFFSET_0:
    return "__global_offset_0";
  case HSAIL::KE_GOFFSET_1:
    return "__global_offset_1";
  case HSAIL::KE_GOFFSET_2:
    return "__global_offset_2";
  case HSAIL::KE_PRINTF_BFR:
    return "__printf_buffer";
  case HSAIL::KE_VQ_PTR:
    return "__vqueue_pointer";
  case HSAIL::KE_AQLWRAP_PTR:
    return "__aqlwrap_pointer";
  default:
    llvm_unreachable("unexpected Kernenv argument ID");
  }
}

static inline Type *getKernenvArgType(unsigned ID, LLVMContext &C,
                                      bool is64bit) {
  if (ID == HSAIL::KE_PRINTF_BFR)
    return Type::getInt8PtrTy(C, 1);
  return (is64bit ? Type::getInt64Ty(C) : Type::getInt32Ty(C));
}

static inline StringRef getKernenvArgTypeName(unsigned ID) { return "size_t"; }
}

#endif // __AMD_OPENCL_KERNENV_H__
