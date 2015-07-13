//===-- HSAILModuleInfo.cpp -----------------------------------------------===//

//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "HSAILModuleInfo.h"
#include "HSAILTargetMachine.h"

using namespace llvm;

HSAILModuleInfo::HSAILModuleInfo(const MachineModuleInfo &MMI) {
  mMMI = &MMI;
  mOffset = 0;
  mReservedBuffs = 0;
  symTab = nullptr;
  mCurrentCPOffset = 0;
  mPrintfOffset = 0;
  mProcessed = false;
}

HSAILModuleInfo::~HSAILModuleInfo() {
  for (StringMap<HSAILKernel *>::iterator kb = mKernels.begin(),
                                          ke = mKernels.end();
       kb != ke; ++kb) {
    HSAILKernel *ptr = kb->getValue();
    delete ptr;
  }
}

static const HSAILConstPtr *getConstPtr(const HSAILKernel *krnl,
                                        const std::string &arg) {
  if (!krnl) {
    return nullptr;
  }
  SmallVector<HSAILConstPtr, 8>::const_iterator begin, end;
  for (begin = krnl->constPtr.begin(), end = krnl->constPtr.end(); begin != end;
       ++begin) {
    if (!strcmp(begin->name.data(), arg.c_str())) {
      return &(*begin);
    }
  }
  return nullptr;
}

void HSAILModuleInfo::processModule(const Module *M,
                                    const HSAILTargetMachine *mTM) {
  mSTM = mTM->getSubtargetImpl();
  if (mProcessed) {
    return;
  }

  // Make sure we only process the module once even though this function
  // is called everytime a MachineFunctionInfo object is instantiated.
  mProcessed = true;
}

HSAILKernel *HSAILModuleInfo::getKernel(StringRef name) {
  StringMap<HSAILKernel *>::iterator iter = mKernels.find(name);
  if (iter == mKernels.end()) {
    return nullptr;
  } else {
    return iter->second;
  }
}

bool HSAILModuleInfo::isWriteOnlyImage(StringRef name, uint32_t iID) const {
  const StringMap<HSAILKernel *>::const_iterator kiter = mKernels.find(name);
  if (kiter == mKernels.end()) {
    return false;
  }
  return kiter->second->writeOnly.count(iID);
}

bool HSAILModuleInfo::isReadOnlyImage(StringRef name, uint32_t iID) const {
  const StringMap<HSAILKernel *>::const_iterator kiter = mKernels.find(name);
  if (kiter == mKernels.end()) {
    return false;
  }
  return kiter->second->readOnly.count(iID);
}

bool HSAILModuleInfo::isReadWriteImage(StringRef name, uint32_t iID) const {
  const StringMap<HSAILKernel *>::const_iterator kiter = mKernels.find(name);
  if (kiter == mKernels.end()) {
    return false;
  }
  return kiter->second->readWrite.count(iID);
}

bool HSAILModuleInfo::usesHWConstant(const HSAILKernel *krnl, StringRef arg) {
  const HSAILConstPtr *curConst = getConstPtr(krnl, arg);
  if (!curConst) {
    return false;
  }
  return curConst->usesHardware;
}

uint32_t HSAILModuleInfo::getConstPtrCB(const HSAILKernel *krnl,
                                        StringRef Arg) {
  const HSAILConstPtr *curConst = getConstPtr(krnl, Arg);
  if (!curConst) {
    return 0;
  }
  return curConst->cbNum;
}

uint32_t HSAILModuleInfo::getOrCreateFunctionID(const std::string &func) {
  const unsigned int RESERVED_FUNCS = 1024;

  uint32_t id;
  if (mFuncNames.find(func) == mFuncNames.end()) {
    id = mFuncNames.size() + RESERVED_FUNCS + mFuncPtrNames.size();
    mFuncNames[func] = id;
  } else {
    id = mFuncNames[func];
  }
  return id;
}
