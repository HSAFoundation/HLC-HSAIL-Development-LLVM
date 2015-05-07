//===-- HSAILKernelManager.h ------------------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
/// \file HSAILKernelManager.h
/// Class that handles the metadata/abi management for the
/// AsmPrinter. Handles the parsing and generation of the metadata
/// for each kernel and keeps track of its arguments.
//
//===----------------------------------------------------------------------===//

#ifndef _HSAILKERNELMANAGER_H_
#define _HSAILKERNELMANAGER_H_
#include "HSAIL.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/IR/ValueMap.h"
#include "llvm/IR/Function.h"
#include "llvm/CodeGen/MachineBasicBlock.h"
#include <string>
#include <set>
#include <map>

namespace HSAIL_ASM {
class Brigantine;
}

namespace llvm {
class HSAILSubtarget;
class HSAILMachineFunctionInfo;
class HSAILModuleInfo;
class HSAILTargetMachine;
class StructType;
class Value;
class TypeSymbolTable;
class MachineFunction;
class MachineInstr;
class ConstantFP;
class HSAILPrintfInfo;

class HSAILKernelManager {
public:
  typedef enum { RELEASE_ONLY, DEBUG_ONLY, ALWAYS } ErrorMsgEnum;
  HSAILKernelManager(HSAILTargetMachine *TM);
  virtual ~HSAILKernelManager();

  /// Clear the state of the KernelManager putting it in its most initial state.
  void clear();
  void setMF(MachineFunction *MF);

  /// Process the specific kernel parsing out the parameter information for the
  /// kernel.
  void processArgMetadata(raw_ostream &ignored, uint32_t buf, bool kernel);

  /// Prints the header for the kernel which includes the groupsize declaration
  /// and calculation of the local/group/global id's.
  void printHeader(const std::string &name);

  void brigEmitMetaData(HSAIL_ASM::Brigantine &brig, uint32_t id,
                        bool isKernel = false);

  /// Set bool value on whether to consider the function a kernel or a normal
  /// function.
  void setKernel(bool kernel);

  /// Set the unique ID of the kernel/function.
  void setID(uint32_t id);

  /// Set the name of the kernel/function.
  void setName(const std::string &name);

  // Get the UAV id for the specific pointer value.
  uint32_t getUAVID(const Value *value);

private:
  void updatePtrArg(llvm::Function::const_arg_iterator Ip, int counter,
                    bool isKernel, const Function *F, int pointerCount);
  /// Name of the current kernel.
  std::string mName;
  uint32_t mUniqueID;
  bool mIsKernel;
  bool mWasKernel;

  /// Flag to specify if an image write has occured or not in order to not add a
  /// compiler specific write if no other writes to memory occured.
  bool mHasImageWrite;
  bool mHasOutputInst;

  /// Map from const Value * to UAV ID.
  std::map<const Value *, uint32_t> mValueIDMap;

  HSAILTargetMachine *mTM;
  const HSAILSubtarget *mSTM;
  /// This is the global offset of the printf string id's.
  MachineFunction *mMF;
  HSAILMachineFunctionInfo *mMFI;
  HSAILModuleInfo *mAMI;
}; // class HSAILKernelManager

} // llvm namespace
#endif // _HSAILKERNELMANAGER_H_
