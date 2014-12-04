//===-- HSAILTargetInfo.cpp - HSAIL Target Implementation -----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "../HSAIL.h"
#include "llvm/Module.h"
#include "llvm/Support/TargetRegistry.h"
using namespace llvm;

Target llvm::TheHSAIL_32Target, llvm::TheHSAIL_64Target;

extern "C" void LLVMInitializeHSAILTargetInfo()
{
  RegisterTarget<Triple::hsail, /*HasJIT=*/false>
    X(TheHSAIL_32Target, "hsail", "32-bit HSAIL: small machine model, addresses are 32 bit");

  RegisterTarget<Triple::hsail_64, /*HasJIT=*/false>
    Y(TheHSAIL_64Target, "hsail-64", "64-bit HSAIL: large machine model, addresses are 64 bit");
}
