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
#include "HSAILMachineFunctionInfo.h"
#include "HSAILModuleInfo.h"
#include "HSAILUtilityFunctions.h"
using namespace llvm;

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

void HSAILPrintfInfo::addOperand(size_t idx, uint32_t size) {
  mOperands.resize((unsigned)(idx + 1));
  mOperands[(unsigned)idx] = size;
}

uint32_t HSAILPrintfInfo::getPrintfID() {
  return mPrintfID;
}

void HSAILPrintfInfo::setPrintfID(uint32_t id) {
  mPrintfID = id;
}

size_t HSAILPrintfInfo::getNumOperands() {
  return mOperands.size();
}

uint32_t HSAILPrintfInfo::getOperandID(uint32_t idx) {
  return mOperands[idx];
}

HSAILMachineFunctionInfo::HSAILMachineFunctionInfo(MachineFunction& MF)
  : RegisterPartitioning(0),
    ParamManager(MF.getTarget().getSubtargetImpl()->getDataLayout()) {
  const Function *F = MF.getFunction();
  mMF = &MF;
  MachineModuleInfo &mmi = MF.getMMI();
  const HSAILTargetMachine *TM =
      reinterpret_cast<const HSAILTargetMachine*>(&MF.getTarget());
  HSAILModuleInfo *AMI = &(mmi.getObjFileInfo<HSAILModuleInfo>());
  AMI->processModule(mmi.getModule(), TM);
  for (Module::const_iterator I = F->getParent()->begin(),
      E = F->getParent()->end(); I != E; ++I) {
    // Map all the known names to a unique number
    AMI->getOrCreateFunctionID(I->getName());
  }
  mSTM = TM->getSubtargetImpl();
  mKernel = AMI->getKernel(F->getName());

  mScratchSize = -1;
  mPrivateMemSize = -1;
  mGroupMemSize = -1;
  mArgSize = -1;
  mStackSize = -1;
}

bool
HSAILMachineFunctionInfo::usesHWConstant(std::string name) const
{
  const HSAILConstPtr *curConst = getConstPtr(mKernel, name);
  if (curConst) {
    return curConst->usesHardware;
  } else {
    return false;
  }
}

bool
HSAILMachineFunctionInfo::isKernel() const
{
  return mKernel != NULL && mKernel->mKernel;
}

HSAILKernel*
HSAILMachineFunctionInfo::getKernel()
{
  return mKernel;
}

  uint32_t
HSAILMachineFunctionInfo::getScratchSize()
{
  const DataLayout *DL = mMF->getTarget().getSubtargetImpl()->getDataLayout();

  if (mScratchSize == -1) {
    mScratchSize = 0;
    Function::const_arg_iterator I = mMF->getFunction()->arg_begin();
    Function::const_arg_iterator Ie = mMF->getFunction()->arg_end();
    while (I != Ie) {
      // FIXME: Mishandling byval structs
      Type *curType = I->getType();
      mScratchSize += RoundUpToAlignment(DL->getTypeStoreSize(curType), 16);
      ++I;
    }
    // mScratchSize += ((mScratchSize + 15) & ~15); // possible typo: doubling mScratchSize
  }
  return (uint32_t)mScratchSize;
}

size_t HSAILMachineFunctionInfo::getPrivateSize()
{
  if (mPrivateMemSize == -1) {
    const DataLayout *DL = mMF->getTarget().getSubtargetImpl()->getDataLayout();

    mPrivateMemSize = 0;
    SmallPtrSet<const GlobalVariable*,16> thisFuncPvtVarsSet;
    for (MachineFunction::const_iterator I = mMF->begin(), E = mMF->end(); I != E; ++I){
      for (MachineBasicBlock::const_iterator II = I->begin(), IE = I->end(); II != IE; ++II) {
        const MachineInstr *LastMI = II;
        for (unsigned int opNum = 0; opNum < LastMI->getNumOperands(); opNum++) {
          const MachineOperand &MO = LastMI->getOperand(opNum);
          if (MO.getType() == MachineOperand::MO_GlobalAddress){
            if (const GlobalVariable *GV =  dyn_cast<GlobalVariable>(MO.getGlobal())){
              if  (GV->getType()->getAddressSpace() == HSAILAS::PRIVATE_ADDRESS){
                if( thisFuncPvtVarsSet.insert(GV) ){
                  mPrivateMemSize += DL->getTypeAllocSize(GV->getType()->getElementType());
                }
              }
            }
          }
        }
      }
    }
    mPrivateMemSize = ((mPrivateMemSize + 15) & ~15);
  }
  return (uint32_t)mPrivateMemSize;
}

size_t HSAILMachineFunctionInfo::getGroupSize()
{
  if (mGroupMemSize == -1) {
    const DataLayout *DL = mMF->getTarget().getSubtargetImpl()->getDataLayout();

    mGroupMemSize = 0;
    SmallPtrSet<const GlobalVariable*,16> thisFuncGrpVarsSet;
    for (MachineFunction::const_iterator I = mMF->begin(), E = mMF->end(); I != E; ++I){
      for (MachineBasicBlock::const_iterator II = I->begin(), IE = I->end(); II != IE; ++II) {
        const MachineInstr *LastMI = II;
        for (unsigned int opNum = 0; opNum < LastMI->getNumOperands(); opNum++) {
          const MachineOperand &MO = LastMI->getOperand(opNum);
          if (MO.getType() == MachineOperand::MO_GlobalAddress){
            if (const GlobalVariable *GV =  dyn_cast<GlobalVariable>(MO.getGlobal())){
              if  (GV->getType()->getAddressSpace() == HSAILAS::GROUP_ADDRESS){
                if( thisFuncGrpVarsSet.insert(GV) ){
                  mGroupMemSize += DL->getTypeAllocSize(GV->getType()->getElementType());
                }
              }
            }
          }
        }
      }
    }
    mGroupMemSize = ((mGroupMemSize + 15) & ~15);
  }
  return (uint32_t)mGroupMemSize;
}

uint32_t
HSAILMachineFunctionInfo::getStackSize()
{
  if (mStackSize == -1) {
    uint32_t privSize = 0;
    const MachineFrameInfo *MFI = mMF->getFrameInfo();
    privSize = MFI->getOffsetAdjustment() + MFI->getStackSize();
    const HSAILTargetMachine *TM =
      reinterpret_cast<const HSAILTargetMachine*>(&mMF->getTarget());
    bool addStackSize = TM->getOptLevel() == CodeGenOpt::None;
    Function::const_arg_iterator I = mMF->getFunction()->arg_begin();
    Function::const_arg_iterator Ie = mMF->getFunction()->arg_end();
    while (I != Ie) {
      Type *curType = I->getType();
      ++I;
      if (dyn_cast<PointerType>(curType)) {
        Type *CT = dyn_cast<PointerType>(curType)->getElementType();
        if (CT->isStructTy()
            && dyn_cast<PointerType>(curType)->getAddressSpace()
            == HSAILAS::PRIVATE_ADDRESS) {
          addStackSize = true;
        }
      }
    }
    if (addStackSize) {
      privSize += getScratchSize();
    }
    mStackSize = privSize;
  }
  return (uint32_t)mStackSize;

}

// FIXME: Remove this
uint32_t
HSAILMachineFunctionInfo::addi32Literal(uint32_t val, int Opcode) {
  return mIntLits[val];
}

  void
HSAILMachineFunctionInfo::addErrorMsg(const char *msg, ErrorMsgEnum val)
{
  if (val == DEBUG_ONLY) {
#if defined(DEBUG) || defined(_DEBUG)
    mErrors.insert(msg);
#endif
  }  else if (val == RELEASE_ONLY) {
#if !defined(DEBUG) && !defined(_DEBUG)
    mErrors.insert(msg);
#endif
  } else if (val == ALWAYS) {
    mErrors.insert(msg);
  }
}

  void
HSAILMachineFunctionInfo::addMetadata(const char *md, bool kernelOnly)
{
  addMetadata(std::string(md), kernelOnly);
}

  void
HSAILMachineFunctionInfo::addMetadata(std::string md, bool kernelOnly)
{
  if (kernelOnly) {
    mMetadataKernel.push_back(md);
  } else {
    mMetadataFunc.insert(md);
  }
}

bool
HSAILMachineFunctionInfo::isSignedIntType(const Value* ptr)
{
  if (!mSTM->supportMetadata30()) return true;
  std::string signedNames = "llvm.signedOrSignedpointee.annotations.";
  std::string argName = ptr->getName();
  if (!mMF) return false;
  signedNames += mMF->getFunction()->getName();
  const GlobalVariable *GV = 
    mMF->getFunction()->getParent()->getGlobalVariable(signedNames);
  if (!GV || !GV->hasInitializer()) return false;
  const ConstantArray *CA = dyn_cast<ConstantArray>(GV->getInitializer());
  if (!CA) return false;
  for (uint32_t start = 0, stop = CA->getNumOperands(); start < stop; ++start) {
    const ConstantExpr *nameField = dyn_cast<ConstantExpr>(CA->getOperand(start));
    if (!nameField) continue;

    const GlobalVariable *nameGV = 
      dyn_cast<GlobalVariable>(nameField->getOperand(0));
    if (!nameGV || !nameGV->hasInitializer()) continue;

    const ConstantDataSequential *nameArray =
      dyn_cast<ConstantDataSequential>(nameGV->getInitializer());
    if (!nameArray) continue;

    std::string nameStr = nameArray->getAsString();
    // We don't want to include the newline
    if (!nameStr.compare(0, nameStr.length()-1, argName)) return true;
  }
  return false;
}
bool
HSAILMachineFunctionInfo::isVolatilePointer(const Value* ptr)
{
  if (!mSTM->supportMetadata30()) return false;
  std::string signedNames = "llvm.volatilepointer.annotations.";
  std::string argName = ptr->getName();
  if (!mMF) return false;
  signedNames += mMF->getFunction()->getName();
  const GlobalVariable *GV = 
    mMF->getFunction()->getParent()->getGlobalVariable(signedNames);
  if (!GV || !GV->hasInitializer()) return false;
  const ConstantArray *CA = dyn_cast<ConstantArray>(GV->getInitializer());
  if (!CA) return false;
  for (uint32_t start = 0, stop = CA->getNumOperands(); start < stop; ++start) {
    const ConstantExpr *nameField = dyn_cast<ConstantExpr>(CA->getOperand(start));
    if (!nameField) continue;

    const GlobalVariable *nameGV = 
      dyn_cast<GlobalVariable>(nameField->getOperand(0));
    if (!nameGV || !nameGV->hasInitializer()) continue;

    const ConstantDataSequential *nameArray =
      dyn_cast<ConstantDataSequential>(nameGV->getInitializer());
    if (!nameArray) continue;

    std::string nameStr = nameArray->getAsString();
    // We don't want to include the newline
    if (!nameStr.compare(0, nameStr.length()-1, argName)) return true;
  }
  return false;
}
bool
HSAILMachineFunctionInfo::isRestrictPointer(const Value* ptr)
{
  if (!mSTM->supportMetadata30()) return false;
  std::string signedNames = "llvm.restrictpointer.annotations.";
  std::string argName = ptr->getName();
  if (!mMF) return false;
  signedNames += mMF->getFunction()->getName();
  const GlobalVariable *GV = 
    mMF->getFunction()->getParent()->getGlobalVariable(signedNames);
  if (!GV || !GV->hasInitializer()) return false;
  const ConstantArray *CA = dyn_cast<ConstantArray>(GV->getInitializer());
  if (!CA) return false;
  for (uint32_t start = 0, stop = CA->getNumOperands(); start < stop; ++start) {
    const ConstantExpr *nameField = dyn_cast<ConstantExpr>(CA->getOperand(start));
    if (!nameField) continue;

    const GlobalVariable *nameGV = 
      dyn_cast<GlobalVariable>(nameField->getOperand(0));
    if (!nameGV || !nameGV->hasInitializer()) continue;

    const ConstantDataSequential *nameArray =
      dyn_cast<ConstantDataSequential>(nameGV->getInitializer());
    if (!nameArray) continue;

    std::string nameStr = nameArray->getAsString();
    // We don't want to include the newline
    if (!nameStr.compare(0, nameStr.length()-1, argName)) return true;
  }
  return false;
}

bool
HSAILMachineFunctionInfo::isConstantArgument(const Value* ptr)
{
  if (!mSTM->supportMetadata30()) return false;
  std::string signedNames = "llvm.argtypeconst.annotations.";
  std::string argName = ptr->getName();
  if (!mMF) return false;
  signedNames += mMF->getFunction()->getName();
  const GlobalVariable *GV = 
    mMF->getFunction()->getParent()->getGlobalVariable(signedNames);
  if (!GV || !GV->hasInitializer()) return false;
  const ConstantArray *CA = dyn_cast<ConstantArray>(GV->getInitializer());
  if (!CA) return false;
  for (uint32_t start = 0, stop = CA->getNumOperands(); start < stop; ++start) {
    const ConstantExpr *nameField = dyn_cast<ConstantExpr>(CA->getOperand(start));
    if (!nameField) continue;

    const GlobalVariable *nameGV = 
      dyn_cast<GlobalVariable>(nameField->getOperand(0));
    if (!nameGV || !nameGV->hasInitializer()) continue;

    const ConstantDataSequential *nameArray =
      dyn_cast<ConstantDataSequential>(nameGV->getInitializer());
    if (!nameArray) continue;

    std::string nameStr = nameArray->getAsString();
    // We don't want to include the newline
    if (!nameStr.compare(0, nameStr.length()-1, argName)) return true;
  }
  return false;
}
