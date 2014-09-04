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
#include "HSAILCompilerErrors.h"
#include "HSAILModuleInfo.h"
#include "HSAILSubtarget.h"
#include "HSAILTargetMachine.h"
#include "HSAILUtilityFunctions.h"
#include "HSAILOpaqueTypes.h"
#include "llvm/Constants.h"
#include "llvm/DerivedTypes.h"
#include "llvm/Function.h"
#include "llvm/Instructions.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/Support/FormattedStream.h"
#include <cstdio>
#include <ostream>
#include <algorithm>
#include <string>
#include <queue>
#include <list>
#include <utility>
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

HSAILMachineFunctionInfo::HSAILMachineFunctionInfo()
  : CalleeSavedFrameSize(0), BytesToPopOnReturn(0),
  DecorationStyle(None), ReturnAddrIndex(0),
  TailCallReturnAddrDelta(0),
  SRetReturnReg(0), UsesLDS(false), LDSArg(false),
  UsesGDS(false), GDSArg(false),
  mReservedLits(11)
{
  memset(mUsedMem, 0, sizeof(mUsedMem));
  mMF = NULL;
  mKernel = NULL;
  mScratchSize = -1;
  mPrivateMemSize = -1;
  mGroupMemSize = -1;
  mArgSize = -1;
  mStackSize = -1;
}

HSAILMachineFunctionInfo::HSAILMachineFunctionInfo(MachineFunction& MF)
  : CalleeSavedFrameSize(0), BytesToPopOnReturn(0),
  DecorationStyle(None), ReturnAddrIndex(0),
  TailCallReturnAddrDelta(0),
  SRetReturnReg(0), UsesLDS(false), LDSArg(false),
  UsesGDS(false), GDSArg(false),
  mReservedLits(11)
{
  memset(mUsedMem, 0, sizeof(mUsedMem));
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

HSAILMachineFunctionInfo::~HSAILMachineFunctionInfo()
{
  for (std::map<std::string, HSAILPrintfInfo*>::iterator pfb = printf_begin(),
      pfe = printf_end(); pfb != pfe; ++pfb) {
    delete pfb->second;
  }
}

unsigned int
HSAILMachineFunctionInfo::getCalleeSavedFrameSize() const
{
  return CalleeSavedFrameSize;
}
void
HSAILMachineFunctionInfo::setCalleeSavedFrameSize(unsigned int bytes)
{
  CalleeSavedFrameSize = bytes;
}
unsigned int
HSAILMachineFunctionInfo::getBytesToPopOnReturn() const
{
  return BytesToPopOnReturn;
}
void
HSAILMachineFunctionInfo::setBytesToPopOnReturn(unsigned int bytes)
{
  BytesToPopOnReturn = bytes;
}
NameDecorationStyle
HSAILMachineFunctionInfo::getDecorationStyle() const
{
  return DecorationStyle;
}
void
HSAILMachineFunctionInfo::setDecorationStyle(NameDecorationStyle style)
{
  DecorationStyle = style;
}
int
HSAILMachineFunctionInfo::getRAIndex() const
{
  return ReturnAddrIndex;
}
void
HSAILMachineFunctionInfo::setRAIndex(int index)
{
  ReturnAddrIndex = index;
}
int
HSAILMachineFunctionInfo::getTCReturnAddrDelta() const
{
  return TailCallReturnAddrDelta;
}
void
HSAILMachineFunctionInfo::setTCReturnAddrDelta(int delta)
{
  TailCallReturnAddrDelta = delta;
}
unsigned int
HSAILMachineFunctionInfo::getSRetReturnReg() const
{
  return SRetReturnReg;
}
void
HSAILMachineFunctionInfo::setSRetReturnReg(unsigned int reg)
{
  SRetReturnReg = reg;
}

void
HSAILMachineFunctionInfo::setUsesLocal()
{
  UsesLDS = true;
}

bool
HSAILMachineFunctionInfo::usesLocal() const
{
  return UsesLDS;
}

void
HSAILMachineFunctionInfo::setHasLocalArg()
{
  LDSArg = true;
}

bool
HSAILMachineFunctionInfo::hasLocalArg() const
{
  return LDSArg;
}



void
HSAILMachineFunctionInfo::setUsesRegion()
{
  UsesGDS = true;
}

bool
HSAILMachineFunctionInfo::usesRegion() const
{
  return UsesGDS;
}

void
HSAILMachineFunctionInfo::setHasRegionArg()
{
  GDSArg = true;
}

bool
HSAILMachineFunctionInfo::hasRegionArg() const
{
  return GDSArg;
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

uint32_t
HSAILMachineFunctionInfo::getLocal(uint32_t dim)
{
  if (mKernel && mKernel->sgv) {
    HSAILKernelAttr *sgv = mKernel->sgv;
    switch (dim) {
    default: break;
    case 0:
    case 1:
    case 2:
      return sgv->reqGroupSize[dim];
      break;
    case 3:
      return sgv->reqGroupSize[0] * sgv->reqGroupSize[1] * sgv->reqGroupSize[2];
    };
  }
  switch (dim) {
  default:
    return 1;
  case 3:
    return mSTM->getDefaultSize(0) *
           mSTM->getDefaultSize(1) *
           mSTM->getDefaultSize(2);
  case 2:
  case 1:
  case 0:
    return mSTM->getDefaultSize(dim);
    break;
  };
  return 1;
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

std::string
HSAILMachineFunctionInfo::getName()
{
  if (mMF) {
    return mMF->getFunction()->getName();
  } else {
    return "";
  }
}

uint32_t
HSAILMachineFunctionInfo::getArgSize()
{
  if (mArgSize == -1) {
    Function::const_arg_iterator I = mMF->getFunction()->arg_begin();
    Function::const_arg_iterator Ie = mMF->getFunction()->arg_end();
    uint32_t Counter = 0;
    while (I != Ie) {
      Type* curType = I->getType();
      if (curType->isIntegerTy() || curType->isFloatingPointTy()) {
        ++Counter;
      } else if (const VectorType *VT = dyn_cast<VectorType>(curType)) {
        Type *ET = VT->getElementType();
        int numEle = VT->getNumElements();
        switch (ET->getPrimitiveSizeInBits()) {
          default:
            if (numEle == 3) {
              Counter++;
            } else {
              Counter += ((numEle + 2) >> 2);
            }
            break;
          case 64:
            if (numEle == 3) {
              Counter += 2;
            } else {
              Counter += (numEle >> 1);
            }
            break;
          case 16:
          case 8:
            switch (numEle) {
              default:
                Counter += ((numEle + 2) >> 2);
              case 2:
                Counter++;
                break;
            }
            break;
        }
      } else if (const PointerType *PT = dyn_cast<PointerType>(curType)) {
        Type *CT = PT->getElementType();
        const StructType *ST = dyn_cast<StructType>(CT);
        if (ST && ST->isOpaque()) {
          if (IsImage(ST)) {
            if (mSTM->device()->isSupported(HSAILDeviceInfo::Images)) {
              Counter += 2;
            } else {
              addErrorMsg(hsa::CompilerErrorMessage[NO_IMAGE_SUPPORT]);
            }
          } else {
            Counter++;
          }
        } else if (CT->isStructTy()
            && PT->getAddressSpace() == HSAILAS::PRIVATE_ADDRESS) {
          Counter += ((HSAILgetTypeSize(ST) + 15) & ~15) >> 4;
        } else if (CT->isIntOrIntVectorTy()
            || CT->isFPOrFPVectorTy()
            || CT->isArrayTy()
            || CT->isPointerTy()
            || PT->getAddressSpace() != HSAILAS::PRIVATE_ADDRESS) {
          ++Counter;
        } else {
          assert(0 && "Current type is not supported!");
          addErrorMsg(hsa::CompilerErrorMessage[INTERNAL_ERROR]);
        }
      } else {
        assert(0 && "Current type is not supported!");
        addErrorMsg(hsa::CompilerErrorMessage[INTERNAL_ERROR]);
      }
      ++I;
    }
    // Convert from slots to bytes by multiplying by 16(shift by 4).
    mArgSize = Counter << 4;
  }
  return (uint32_t)mArgSize;
}
  uint32_t
HSAILMachineFunctionInfo::getScratchSize()
{
  if (mScratchSize == -1) {
    mScratchSize = 0;
    Function::const_arg_iterator I = mMF->getFunction()->arg_begin();
    Function::const_arg_iterator Ie = mMF->getFunction()->arg_end();
    while (I != Ie) {
      Type *curType = I->getType();
      mScratchSize += ((HSAILgetTypeSize(curType) + 15) & ~15);
      ++I;
    }
    // mScratchSize += ((mScratchSize + 15) & ~15); // possible typo: doubling mScratchSize
  }
  return (uint32_t)mScratchSize;
}

size_t HSAILMachineFunctionInfo::getPrivateSize()
{
  if (mPrivateMemSize == -1) {
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
                  mPrivateMemSize += HSAILgetTypeSize(GV->getType(),true);
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
                  mGroupMemSize += HSAILgetTypeSize(GV->getType(),true);
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

uint32_t
HSAILMachineFunctionInfo::addi32Literal(uint32_t val, int Opcode) {
  // Since we have emulated 16/8/1 bit register types with a 32bit real
  // register, we need to sign extend the constants to 32bits in order for
  // comparisons against the constants to work correctly, this fixes some issues
  // we had in conformance failing for saturation.
  // if (Opcode == HSAIL::LOADCONST_i16) {
  //   val = (((int32_t)val << 16) >> 16);
  // } else if (Opcode == HSAIL::LOADCONST_i8) {
  //   val = (((int32_t)val << 24) >> 24);
  // }
  // if (mIntLits.find(val) == mIntLits.end()) {
  //   mIntLits[val] = getNumLiterals();
  // }
  return mIntLits[val];
}

uint32_t
HSAILMachineFunctionInfo::addi64Literal(uint64_t val) {
  if (mLongLits.find(val) == mLongLits.end()) {
    mLongLits[val] = getNumLiterals();
  }
  return mLongLits[val];
}

uint32_t
HSAILMachineFunctionInfo::addi128Literal(uint64_t val_lo, uint64_t val_hi) {
  std::pair<uint64_t, uint64_t> a;
  a.first = val_lo;
  a.second = val_hi;
  if (mVecLits.find(a) == mVecLits.end()) {
    mVecLits[a] = getNumLiterals();
  }
  return mVecLits[a];
}

uint32_t
HSAILMachineFunctionInfo::addf32Literal(uint32_t val) {
  if (mIntLits.find(val) == mIntLits.end()) {
    mIntLits[val] = getNumLiterals();
  }
  return mIntLits[val];
}

uint32_t
HSAILMachineFunctionInfo::addf32Literal(const ConstantFP *CFP) {
  uint32_t val = (uint32_t)CFP->getValueAPF().bitcastToAPInt().getZExtValue();
  if (mIntLits.find(val) == mIntLits.end()) {
    mIntLits[val] = getNumLiterals();
  }
  return mIntLits[val];
}

uint32_t
HSAILMachineFunctionInfo::addf64Literal(uint64_t val) {
  if (mLongLits.find(val) == mLongLits.end()) {
    mLongLits[val] = getNumLiterals();
  }
  return mLongLits[val];
}

uint32_t
HSAILMachineFunctionInfo::addf64Literal(const ConstantFP *CFP) {
  union dtol_union {
    double d;
    uint64_t ul;
  } dval;
  const APFloat &APF = CFP->getValueAPF();
  if (&APF.getSemantics() == (const llvm::fltSemantics *)&APFloat::IEEEsingle) {
    float fval = APF.convertToFloat();
    dval.d = (double)fval;
  } else {
    dval.d = APF.convertToDouble();
  }
  if (mLongLits.find(dval.ul) == mLongLits.end()) {
    mLongLits[dval.ul] = getNumLiterals();
  }
  return mLongLits[dval.ul];
}

  uint32_t
HSAILMachineFunctionInfo::getIntLits(uint32_t offset)
{
  return mIntLits[offset];
}

  uint32_t
HSAILMachineFunctionInfo::getLongLits(uint64_t offset)
{
  return mLongLits[offset];
}

  uint32_t
HSAILMachineFunctionInfo::getVecLits(uint64_t low64, uint64_t high64)
{
  return mVecLits[std::pair<uint64_t, uint64_t>(low64, high64)];
}

size_t
HSAILMachineFunctionInfo::getNumLiterals() const {
  return mLongLits.size() + mIntLits.size() + mVecLits.size() + mReservedLits;
}

  void
HSAILMachineFunctionInfo::addReservedLiterals(uint32_t size)
{
  mReservedLits += size;
}

  uint32_t
HSAILMachineFunctionInfo::addSampler(std::string name, uint32_t val)
{
  if (mSamplerMap.find(name) != mSamplerMap.end()) {
    SamplerInfo newVal = mSamplerMap[name];
    newVal.val = val;
    mSamplerMap[name] = newVal;
    return mSamplerMap[name].idx;
  } else {
    SamplerInfo curVal;
    curVal.name = name;
    curVal.val = val;
    curVal.idx = mSamplerMap.size();
    mSamplerMap[name] = curVal;
    return curVal.idx;
  }
}

void
HSAILMachineFunctionInfo::setUsesMem(unsigned id) {
  assert(id < HSAILDevice::MAX_IDS &&
      "Must set the ID to be less than MAX_IDS!");
  mUsedMem[id] = true;
}

bool
HSAILMachineFunctionInfo::usesMem(unsigned id) {
  assert(id < HSAILDevice::MAX_IDS &&
      "Must set the ID to be less than MAX_IDS!");
  return mUsedMem[id];
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

  uint32_t
HSAILMachineFunctionInfo::addPrintfString(std::string &name, unsigned offset)
{
  if (mPrintfMap.find(name) != mPrintfMap.end()) {
    return mPrintfMap[name]->getPrintfID();
  } else {
    HSAILPrintfInfo *info = new HSAILPrintfInfo;
    info->setPrintfID(mPrintfMap.size() + offset);
    mPrintfMap[name] = info;
    return info->getPrintfID();
  }
}

  void
HSAILMachineFunctionInfo::addPrintfOperand(std::string &name,
    size_t idx,
    uint32_t size)
{
  mPrintfMap[name]->addOperand(idx, size);
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
