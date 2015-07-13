//==-- HSAILModuleInfo.h ----------------------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//==-----------------------------------------------------------------------===//
//
/// \file
/// This is an MMI implementation for HSAIL targets.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_HSAIL_HSAILMODULEINFO_H
#define LLVM_LIB_TARGET_HSAIL_HSAILMODULEINFO_H

#include "HSAIL.h"
#include "HSAILKernel.h"
#include "llvm/IR/Module.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/Support/raw_ostream.h"
#include <string>
#include <set>

namespace llvm {
class Argument;
class TypeSymbolTable;
class GlobalValue;
class MachineFunction;
class GlobalValue;

class HSAILMachineFunctionInfo;
class HSAILModuleInfo : public MachineModuleInfoImpl {

  void parseEdgGlobalVariables(const Module *M, const HSAILTargetMachine *mTM);

protected:
  const MachineModuleInfo *mMMI;

public:
  HSAILModuleInfo(const MachineModuleInfo &);
  virtual ~HSAILModuleInfo();

  void processModule(const Module *MF, const HSAILTargetMachine *mTM);

  /// Process the given module and parse out the global variable metadata passed
  /// down from the frontend-compiler

  /// Returns true if the image ID corresponds to a read only image.
  bool isReadOnlyImage(StringRef Name, uint32_t iID) const;

  /// Returns true if the image ID corresponds to a write only image.
  bool isWriteOnlyImage(StringRef Name, uint32_t iID) const;

  /// Returns true if the image ID corresponds to a read write image.
  bool isReadWriteImage(StringRef name, uint32_t iID) const;

  /// Get a reference to the kernel metadata information for the given function
  /// name.
  HSAILKernel *getKernel(StringRef Name);

  /// Query if the constant argument uses hardware or not
  bool usesHWConstant(const HSAILKernel *krnl, StringRef Arg);

  /// Query the constant buffer number for a constant pointer.
  uint32_t getConstPtrCB(const HSAILKernel *krnl, StringRef Arg);

  /// Get the unique function ID for the specific function name and create a new
  /// unique ID if it is not found.
  uint32_t getOrCreateFunctionID(const GlobalValue *func);
  uint32_t getOrCreateFunctionID(const std::string &func);

  void add_printf_offset(uint32_t offset) { mPrintfOffset += offset; }
  uint32_t get_printf_offset() { return mPrintfOffset; }

public:
  StringMap<HSAILKernel *> mKernels;

private:
  StringMap<HSAILKernelAttr> mKernelArgs;
  StringMap<HSAILArrayMem> mArrayMems;
  StringMap<uint32_t> mFuncNames;
  DenseMap<const GlobalValue *, uint32_t> mFuncPtrNames;
  DenseMap<uint32_t, StringRef> mImageNameMap;
  StringMap<std::set<std::string>> mSamplerSet;
  std::set<StringRef> mByteStore;
  std::set<StringRef> mIgnoreStr;
  DenseMap<const Argument *, int32_t> mArgIDMap;
  const char *symTab;
  const HSAILSubtarget *mSTM;
  size_t mOffset;
  uint32_t mReservedBuffs;
  uint32_t mCurrentCPOffset;
  uint32_t mPrintfOffset;
  bool mProcessed;
};
} // end namespace llvm

#endif
