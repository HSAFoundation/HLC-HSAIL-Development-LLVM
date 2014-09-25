// Copyright (c) 2011, Advanced Micro Devices, Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the copyright holder nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
// If you use the software (in whole or in part), you shall adhere to all
// applicable U.S., European, and other export laws, including but not limited
// to the U.S. Export Administration Regulations (“EAR”), (15 C.F.R. Sections
// 730 through 774), and E.U. Council Regulation (EC) No 1334/2000 of 22 June
// 2000.  Further, pursuant to Section 740.6 of the EAR, you hereby certify
// that, except pursuant to a license granted by the United States Department
// of Commerce Bureau of Industry and Security or as otherwise permitted
// pursuant to a License Exception under the U.S. Export Administration
// Regulations ("EAR"), you will not (1) export, re-export or release to a
// national of a country in Country Groups D:1, E:1 or E:2 any restricted
// technology, software, or source code you receive hereunder, or (2) export to
// Country Groups D:1, E:1 or E:2 the direct product of such technology or
// software, if such foreign produced direct product is subject to national
// security controls as identified on the Commerce Control List (currently
// found in Supplement 1 to Part 774 of EAR).  For the most current Country
// Group listings, or for additional information about the EAR or your
// obligations under those regulations, please refer to the U.S. Bureau of
// Industry and Security’s website at http://www.bis.doc.gov/.
//
//==-----------------------------------------------------------------------===//
#include "HSAILModuleInfo.h"
#include "HSAILTargetMachine.h"

using namespace llvm;

HSAILModuleInfo::HSAILModuleInfo(const MachineModuleInfo &MMI)
{
  mMMI = &MMI;
  mOffset = 0;
  mReservedBuffs = 0;
  symTab = NULL;
  mCurrentCPOffset = 0;
  mPrintfOffset = 0;
  mProcessed = false;
}

HSAILModuleInfo::~HSAILModuleInfo() {
  for (StringMap<HSAILKernel*>::iterator kb = mKernels.begin(), ke = mKernels.end();
      kb != ke; ++kb) {
    HSAILKernel *ptr = kb->getValue();
    delete ptr;
  }
}

static const HSAILConstPtr *getConstPtr(const HSAILKernel *krnl, const std::string &arg) {
  if (!krnl) {
    return NULL;
  }
  llvm::SmallVector<HSAILConstPtr, DEFAULT_VEC_SLOTS>::const_iterator begin, end;
  for (begin = krnl->constPtr.begin(), end = krnl->constPtr.end();
       begin != end; ++begin) {
    if (!strcmp(begin->name.data(),arg.c_str())) {
      return &(*begin);
    }
  }
  return NULL;
}

void HSAILModuleInfo::processModule(const Module *M,
                                    const HSAILTargetMachine *mTM)
{
  mSTM = mTM->getSubtargetImpl();
  if (mProcessed) {
    return;
  }

  // Make sure we only process the module once even though this function
  // is called everytime a MachineFunctionInfo object is instantiated.
  mProcessed = true;
}

HSAILKernel *
HSAILModuleInfo::getKernel(const llvm::StringRef &name) {
  StringMap<HSAILKernel*>::iterator iter = mKernels.find(name);
  if (iter == mKernels.end()) {
      return NULL;
  } else {
    return iter->second;
  }
}

bool HSAILModuleInfo::isWriteOnlyImage(const llvm::StringRef &name,
                                          uint32_t iID) const {
  const StringMap<HSAILKernel*>::const_iterator kiter = mKernels.find(name);
  if (kiter == mKernels.end()) {
    return false;
  }
  return kiter->second->writeOnly.count(iID);
}

bool HSAILModuleInfo::isReadOnlyImage(const llvm::StringRef &name,
                                         uint32_t iID) const {
  const StringMap<HSAILKernel*>::const_iterator kiter = mKernels.find(name);
  if (kiter == mKernels.end()) {
    return false;
  }
  return kiter->second->readOnly.count(iID);
}

bool HSAILModuleInfo::isReadWriteImage(const llvm::StringRef &name,
                                         uint32_t iID) const {
  const StringMap<HSAILKernel*>::const_iterator kiter = mKernels.find(name);
  if (kiter == mKernels.end()) {
    return false;
  }
  return kiter->second->readWrite.count(iID);
}

bool HSAILModuleInfo::usesHWConstant(const HSAILKernel *krnl,
    const llvm::StringRef &arg) {
  const HSAILConstPtr *curConst = getConstPtr(krnl, arg);
  if (!curConst) {
    return false;
  }
  return curConst->usesHardware;
}

uint32_t HSAILModuleInfo::getConstPtrCB(const HSAILKernel *krnl,
                                           const llvm::StringRef &arg)
{
  const HSAILConstPtr *curConst = getConstPtr(krnl, arg);
  if (!curConst) {
    return 0;
  }
  return curConst->cbNum;
}

uint32_t HSAILModuleInfo::getOrCreateFunctionID(const std::string &func) {
  uint32_t id;
  if (mFuncNames.find(func) == mFuncNames.end()) {
    id = mFuncNames.size() + RESERVED_FUNCS + mFuncPtrNames.size();
    mFuncNames[func] = id;
  } else {
    id = mFuncNames[func];
  }
  return id;
}
