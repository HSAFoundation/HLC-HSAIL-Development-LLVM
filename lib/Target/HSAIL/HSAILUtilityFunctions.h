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

#ifndef HSAILUTILITYFUNCTIONS_H_
#define HSAILUTILITYFUNCTIONS_H_

#include "HSAIL.h"
#include "HSAILBrig.h"
#include "HSAILTargetMachine.h"
#include "llvm/ADT/SmallVector.h"

// Utility functions from ID
//
namespace llvm {
class TargetRegisterClass;
class SDValue;
class SDNode;
class Value;
class Type;
class TypeSymbolTable;
class StructType;
class IntegerType;
class FunctionType;
class VectorType;
class ArrayType;
class PointerType;
class MachineInstr;
class HSAILMachineFunctionInfo;
class GlobalVariable;
class SelectionDAG;
class DebugLoc;

namespace HSAIL {

uint64_t getNumElementsInHSAILType(Type *type, const DataLayout &dataLayout);
BrigType getBrigType(Type *Ty, const DataLayout &DL, bool Signed = false);

/// Returns the type to use when expressing the type in HSAIL. If this will be
/// expressed as an HSAIL array, set NElts to the number of elements,
/// otherwise 0.
Type *analyzeType(Type *Ty, unsigned &NElts, const DataLayout &DL);

unsigned getAlignTypeQualifier(Type *ty, const DataLayout &DL,
                               bool isPreferred);

const char *getTypeName(Type *ptr, const char *symTab,
                        HSAILMachineFunctionInfo *mMFI, bool signedType);

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

#endif // HSAILUTILITYFUNCTIONS_H_
