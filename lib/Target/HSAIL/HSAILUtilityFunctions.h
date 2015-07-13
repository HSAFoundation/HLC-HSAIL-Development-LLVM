//===-- HSAILUtilityFunctions.h - Utility Functions Header ------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//==-----------------------------------------------------------------------===//
//
// This file provides declarations for functions that are used across different
// classes and provide various conversions or utility to shorten the code
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_HSAIL_HSAILUTILITYFUNCTIONS_H
#define LLVM_LIB_TARGET_HSAIL_HSAILUTILITYFUNCTIONS_H

#include "HSAIL.h"
#include "HSAILBrigDefs.h"
#include "HSAILTargetMachine.h"

namespace llvm {
class GlobalVariable;
class HSAILMachineFunctionInfo;
class MachineInstr;
class TargetRegisterClass;
class Type;

namespace HSAIL {

BrigType getBrigType(Type *Ty, const DataLayout &DL, bool Signed = false);

/// Returns the type to use when expressing the type in HSAIL. If this will be
/// expressed as an HSAIL array, set NElts to the number of elements,
/// otherwise 0.
Type *analyzeType(Type *Ty, unsigned &NElts, const DataLayout &DL);

unsigned getAlignTypeQualifier(Type *ty, const DataLayout &DL,
                               bool isPreferred);

static inline bool isConv(const MachineInstr *MI) {
  return MI->getDesc().TSFlags & HSAILInstrFlags::IS_CONV;
}

static inline bool isImageInst(const MachineInstr *MI) {
  return MI->getDesc().TSFlags & HSAILInstrFlags::IS_IMAGEINST;
}

bool isKernelFunc(const Function *F);
bool isSPIRModule(const Module &M);

bool notUsedInKernel(const GlobalVariable *GV);
bool isIgnoredGV(const GlobalVariable *GV);

bool sanitizedGlobalValueName(StringRef, SmallVectorImpl<char> &);
bool sanitizeGlobalValueName(llvm::GlobalValue *GV);

} // End namespace HSAIL

} // End namespace llvm

#endif
