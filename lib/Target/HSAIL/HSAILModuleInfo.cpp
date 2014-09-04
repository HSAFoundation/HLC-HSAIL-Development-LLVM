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
#include "HSAILAlgorithms.tpp"
#include "HSAILDevices.h"
#include "HSAILKernel.h"
#include "HSAILMachineFunctionInfo.h"
#include "HSAILSubtarget.h"
#include "HSAILUtilityFunctions.h"
//#include "HSAILParseMetadata.h"
#include "llvm/Constants.h"
#include "llvm/DerivedTypes.h"
#include "llvm/Instructions.h"
#include "llvm/CodeGen/MachineConstantPool.h"
#include "llvm/Support/FormattedStream.h"
#include <cstdio>

using namespace llvm;

static inline uint32_t AlignDown_32(uint32_t Value, uint32_t Alignment) {
  return Value & ~(Alignment - 1);
}

static inline uint32_t AlignUp_32(uint32_t Value, uint32_t Alignment) {
  return AlignDown_32(Value + Alignment - 1, Alignment);
}

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
    StringMapEntry<HSAILKernel*> cur = *kb;
    HSAILKernel *ptr = cur.getValue();
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

void HSAILModuleInfo::parseEdgGlobalVariables(const Module *M, const HSAILTargetMachine *mTM)
{
  Module::const_global_iterator GI;
  Module::const_global_iterator GE;

  for (GI = M->global_begin(), GE = M->global_end(); GI != GE; ++GI) {
    const GlobalVariable *GV = GI;
    llvm::StringRef GVName = GV->getName();
    const char *name = GVName.data();
    if (!strncmp(name, "sgv", 3)) {
      mKernelArgs[GVName] = parseSGV(GV);
    } else if (!strncmp(name, "llvm.image.annotations", 22)) {
      parseImageAnnotate(GV);
    } else if (!strncmp(name, "llvm.global.annotations", 23)) {
      parseGlobalAnnotate(GV);
    } else if (!strncmp(name, "llvm.sampler.annotations", 24)) {
      parseSamplerAnnotate(GV);
    } else if (GVName.startswith("llvm.argtypename.annotations.")) {
      parseArgTypeNames(GV);
    } else if (strstr(name, "cllocal")) {
      parseAutoArray(GV, false);
    } else if (strstr(name, "clregion")) {
      parseAutoArray(GV, true);
    }
  }
}

void HSAILModuleInfo::parseArgTypeNames(const GlobalVariable *GV) {
  StringRef Name = GV->getName();
  StringRef KernelName = Name.substr(strlen("llvm.argtypename.annotations."));

  HSAILKernel *tmp;
  if (mKernels.find(KernelName) != mKernels.end()) {
    tmp = mKernels[KernelName];
  } else {
    tmp = new HSAILKernel();
    mKernels[KernelName] = tmp;
  }

  const ConstantArray *NameArray = cast<ConstantArray>(GV->getInitializer());
  
  for (unsigned i = 0, e = NameArray->getNumOperands(); i != e; ++i) {
    const ConstantExpr *Bitcast = cast<ConstantExpr>(NameArray->getOperand(i));
    assert(Bitcast->getOpcode() == Instruction::BitCast);
    const GlobalVariable *StringGV
      = cast<GlobalVariable>(Bitcast->getOperand(0));
    const ConstantDataArray *String
      = cast<ConstantDataArray>(StringGV->getInitializer());
    tmp->ArgTypeNames.push_back(String->getAsCString().str());
  }
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

int32_t HSAILModuleInfo::getArrayOffset(const llvm::StringRef &a) const {
  StringMap<HSAILArrayMem>::const_iterator iter = mArrayMems.find(a);
  if (iter != mArrayMems.end()) {
    return iter->second.offset;
  } else {
    return -1;
  }
}

// As of right now we only care about the required group size
// so we can skip the variable encoding
HSAILKernelAttr HSAILModuleInfo::parseSGV(const GlobalVariable *GV) {
  HSAILKernelAttr nArg;
  memset(&nArg, 0, sizeof(nArg));
  for (int x = 0; x < 3; ++x) {
    nArg.reqGroupSize[x] = mSTM->getDefaultSize(x);
    nArg.reqRegionSize[x] = mSTM->getDefaultSize(x);
  }

  const ConstantDataSequential *CA = dyn_cast<ConstantDataSequential>(GV->getInitializer());
  if (!CA) // sgv may have a zeroinitializer
    return nArg;

  std::string init = CA->getAsString();
  size_t pos = init.find("RWG");
  if (pos != llvm::StringRef::npos) {
    pos += 3;
    std::string LWS = init.substr(pos, init.length() - pos);
    const char *lws = LWS.c_str();
    int read_items = 
      sscanf(lws, "%u,%u,%u", &(nArg.reqGroupSize[0]),
        &(nArg.reqGroupSize[1]),
        &(nArg.reqGroupSize[2]));
    assert(read_items == 3);
    nArg.mHasRWG = true;
  }
  pos = init.find("RWR");
  if (pos != llvm::StringRef::npos) {
    pos += 3;
    std::string LWS = init.substr(pos, init.length() - pos);
    const char *lws = LWS.c_str();
    int read_items = 
      sscanf(lws, "%u,%u,%u", &(nArg.reqRegionSize[0]),
        &(nArg.reqRegionSize[1]),
        &(nArg.reqRegionSize[2]));
    assert(read_items == 3);
    nArg.mHasRWR = true;
  }
  return nArg;
}

void HSAILModuleInfo::parseSamplerAnnotate(const GlobalVariable *GV)
{
  const ConstantArray *CA = cast<ConstantArray>(GV->getInitializer());
  uint32_t numOps = CA->getNumOperands();
  for (uint32_t x = 0; x < numOps; ++x) {
    const ConstantExpr *nameField = cast<ConstantExpr>(CA->getOperand(x));
    const GlobalVariable *nameGV = 
      cast<GlobalVariable>(nameField->getOperand(0));
    const ConstantDataSequential *nameArray =
      cast<ConstantDataSequential>(nameGV->getInitializer());
    std::string nameStr = nameArray->getAsString();
    mSamplerSet[GV->getName()].insert(nameStr.substr(0, nameStr.size()-1));
  }
}

std::set<std::string> *
HSAILModuleInfo::getSamplerForKernel(llvm::StringRef &ref)
{
  return (mSamplerSet.find(ref) != mSamplerSet.end()) ? &mSamplerSet[ref] : NULL;
}

void HSAILModuleInfo::parseImageAnnotate(const GlobalVariable *GV) {
  const ConstantArray *CA = cast<ConstantArray>(GV->getInitializer());
  uint32_t e = CA->getNumOperands();
  HSAILKernel *k;
  llvm::StringRef name = GV->getName().data() + 23;
  if (mKernels.find(name) != mKernels.end()) {
    k = mKernels[name];
  } else {
    k = new HSAILKernel();
  }
  k->mName = name;
  for (uint32_t i = 0; i != e; ++i) {
    const Value *V = CA->getOperand(i);
    const Constant *C = cast<Constant>(V);
    const ConstantStruct *CS = cast<ConstantStruct>(C);
    assert(CS->getNumOperands() == 2);
    const ConstantInt *CI = cast<ConstantInt>(CS->getOperand(1));
    uint32_t val = (uint32_t)CI->getZExtValue();
    if (val == 1) {
      k->readOnly.insert(i);
    } else if (val == 2) {
      k->writeOnly.insert(i);
    } else if (val == 3) {
      k->readWrite.insert(i);
    } else {
      assert(!"Unknown image type value!");
    }
  }
  mKernels[name] = k;
}

void HSAILModuleInfo::parseAutoArray(const GlobalVariable *GV, bool isRegion) {
  Type *Ty = GV->getType();
  HSAILArrayMem tmp;
  tmp.isHW = true;
  tmp.offset = 0;
  tmp.align = std::max(GV->getAlignment(), 16U);
  tmp.vecSize = HSAILgetTypeSize(Ty, true);
  tmp.isRegion = isRegion;
  mArrayMems[GV->getName()] = tmp;
}

void HSAILModuleInfo::parseGlobalAnnotate(const GlobalVariable *GV) {
  const ConstantArray *CA = cast<ConstantArray>(GV->getInitializer());

  unsigned int nKernels = CA->getNumOperands();
  for (unsigned int i = 0, e = nKernels; i != e; ++i) {
    parseKernelInformation(CA->getOperand(i));
  }
}

void HSAILModuleInfo::parseKernelInformation(const Value *V) {
  const ConstantStruct *CS = cast<ConstantStruct>(V);

  // The first operand is always a pointer to the HSAILKernel.
  const Constant *CV = dyn_cast<Constant>(CS->getOperand(0));
  llvm::StringRef HSAILKernelName = (*(CV->op_begin()))->getName();

  // If we have images, then we have already created the HSAILKernel and we just need
  // to get the HSAILKernel information.
  HSAILKernel *tmp;
  if (mKernels.find(HSAILKernelName) != mKernels.end()) {
    tmp = mKernels[HSAILKernelName];
  } else {
    tmp = new HSAILKernel();
    mKernels[HSAILKernelName] = tmp;
  }
  tmp->mKernel = true;
  tmp->mName = HSAILKernelName;

  // The second operand is SGV, there can only be one so we don't need to worry
  // about parsing out multiple data points.
  CV = cast<Constant>(CS->getOperand(1));

  llvm::StringRef sgvName;
  sgvName = (*(CV->op_begin()))->getName();

  if (mKernelArgs.find(sgvName) != mKernelArgs.end()) {
    tmp->sgv = &mKernelArgs[sgvName];
  }
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

bool HSAILModuleInfo::isKernel(const llvm::StringRef &name) const {
  return (mKernels.find(name) != mKernels.end());
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

int32_t HSAILModuleInfo::getArgID(const Argument *arg) {
  DenseMap<const Argument *, int32_t>::iterator argiter = mArgIDMap.find(arg);
  if (argiter != mArgIDMap.end()) {
    return argiter->second;
  } else {
    return -1;
  }
}

uint32_t
HSAILModuleInfo::getRegion(const llvm::StringRef &name, uint32_t dim) const {
  StringMap<HSAILKernel*>::const_iterator iter = mKernels.find(name);
  if (iter != mKernels.end() && iter->second->sgv) {
    HSAILKernelAttr *sgv = iter->second->sgv;
    switch (dim) {
    default: break;
    case 0:
    case 1:
    case 2:
      return sgv->reqRegionSize[dim];
      break;
    case 3:
      return sgv->reqRegionSize[0] *
             sgv->reqRegionSize[1] *
             sgv->reqRegionSize[2];
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

bool HSAILModuleInfo::byteStoreExists(StringRef S) const {
  return mByteStore.find(S) != mByteStore.end();
}

bool HSAILModuleInfo::usesHWConstant(const HSAILKernel *krnl,
    const llvm::StringRef &arg) {
  const HSAILConstPtr *curConst = getConstPtr(krnl, arg);
  if (!curConst) {
    return false;
  }
  return curConst->usesHardware;
}

uint32_t HSAILModuleInfo::getConstPtrSize(const HSAILKernel *krnl,
                                             const llvm::StringRef &arg)
{
  const HSAILConstPtr *curConst = getConstPtr(krnl, arg);
  if (!curConst) {
    return 0;
  }
  return curConst->size;
}

uint32_t HSAILModuleInfo::getConstPtrOff(const HSAILKernel *krnl,
                                            const llvm::StringRef &arg)
{
  const HSAILConstPtr *curConst = getConstPtr(krnl, arg);
  if (!curConst) {
    return 0;
  }
  return curConst->offset;
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

void HSAILModuleInfo::calculateCPOffsets(const MachineFunction *MF,
                                            HSAILKernel *krnl)
{
  const MachineConstantPool *MCP = MF->getConstantPool();
  if (!MCP) {
    return;
  }
  const std::vector<MachineConstantPoolEntry> consts = MCP->getConstants();
  size_t numConsts = consts.size();
  for (size_t x = 0; x < numConsts; ++x) {
    krnl->CPOffsets.push_back(
        std::make_pair(mCurrentCPOffset, consts[x].Val.ConstVal));
    size_t curSize = HSAILgetTypeSize(consts[x].Val.ConstVal->getType(), true);
    // Align the size to the vector boundary
    uint32_t alignment = 16;
    const GlobalValue *GV = dyn_cast<GlobalValue>(consts[x].Val.ConstVal);
    if (GV) {
      alignment = std::max(GV->getAlignment(), 16U);
    }
    curSize = AlignUp_32(curSize, alignment);
    mCurrentCPOffset += curSize;
  }
}

bool HSAILModuleInfo::isConstPtrArray(const HSAILKernel *krnl,
                                         const llvm::StringRef &arg) {
  const HSAILConstPtr *curConst = getConstPtr(krnl, arg);
  if (curConst) {
    return curConst->isArray;
  } else {
    return false;
  }
}

bool HSAILModuleInfo::isConstPtrArgument(const HSAILKernel *krnl,
                                            const llvm::StringRef &arg)
{
  const HSAILConstPtr *curConst = getConstPtr(krnl, arg);
  if (curConst) {
    return curConst->isArgument;
  } else {
    return false;
  }
}

const Value *HSAILModuleInfo::getConstPtrValue(const HSAILKernel *krnl,
                                                  const llvm::StringRef &arg) {
  const HSAILConstPtr *curConst = getConstPtr(krnl, arg);
  if (curConst) {
    return curConst->base;
  } else {
    return NULL;
  }
}

static void
dumpZeroElements(StructType * const T, OSTREAM_TYPE &O, bool asBytes);
static void
dumpZeroElements(IntegerType * const T, OSTREAM_TYPE &O, bool asBytes);
static void
dumpZeroElements(ArrayType * const T, OSTREAM_TYPE &O, bool asBytes);
static void
dumpZeroElements(VectorType * const T, OSTREAM_TYPE &O, bool asBytes);
static void
dumpZeroElements(Type * const T, OSTREAM_TYPE &O, bool asBytes);

void dumpZeroElements(Type * const T, OSTREAM_TYPE &O, bool asBytes) {
  if (!T) {
    return;
  }
  switch(T->getTypeID()) {
  case Type::X86_FP80TyID:
  case Type::FP128TyID:
  case Type::PPC_FP128TyID:
  case Type::LabelTyID:
    assert(0 && "These types are not supported by this backend");
  default:
  case Type::DoubleTyID:
    if (asBytes) {
      O << ":0:0:0:0:0:0:0:0";
    } else {
      O << ":0";
    }
    break;
  case Type::FloatTyID:
  case Type::PointerTyID:
  case Type::FunctionTyID:
    if (asBytes) {
      O << ":0:0:0:0";
    } else {
      O << ":0";
    }
  case Type::IntegerTyID:
    dumpZeroElements(dyn_cast<IntegerType>(T), O, asBytes);
    break;
  case Type::StructTyID:
    {
      const StructType *ST = cast<StructType>(T);
      if (!ST->isOpaque()) {
        dumpZeroElements(dyn_cast<StructType>(T), O, asBytes);
      } else { // A pre-LLVM 3.0 opaque type
        if (asBytes) {
          O << ":0:0:0:0";
        } else {
          O << ":0";
        }
      }
    }
    break;
  case Type::ArrayTyID:
    dumpZeroElements(dyn_cast<ArrayType>(T), O, asBytes);
    break;
  case Type::VectorTyID:
    dumpZeroElements(dyn_cast<VectorType>(T), O, asBytes);
    break;
  };
}

void
dumpZeroElements(StructType * const ST, OSTREAM_TYPE &O, bool asBytes) {
  if (!ST) {
    return;
  }
  Type *curType;
  StructType::element_iterator eib = ST->element_begin();
  StructType::element_iterator eie = ST->element_end();
  for (;eib != eie; ++eib) {
    curType = *eib;
    dumpZeroElements(curType, O, asBytes);
  }
}

void
dumpZeroElements(IntegerType * const IT, OSTREAM_TYPE &O, bool asBytes) {
  if (asBytes) {
    unsigned byteWidth = (IT->getBitWidth() >> 3);
    for (unsigned x = 0; x < byteWidth; ++x) {
      O << ":0";
    }
  }
}

void
dumpZeroElements(ArrayType * const AT, OSTREAM_TYPE &O, bool asBytes) {
  size_t size = AT->getNumElements();
  for (size_t x = 0; x < size; ++x) {
    dumpZeroElements(AT->getElementType(), O, asBytes);
  }
}

void
dumpZeroElements(VectorType * const VT, OSTREAM_TYPE &O, bool asBytes) {
  size_t size = VT->getNumElements();
  for (size_t x = 0; x < size; ++x) {
    dumpZeroElements(VT->getElementType(), O, asBytes);
  }
}

void HSAILModuleInfo::printConstantValue(const Constant *CAval,
                                            OSTREAM_TYPE &O, bool asBytes) {
  if (const ConstantFP *CFP = dyn_cast<ConstantFP>(CAval)) {
    bool isDouble = &CFP->getValueAPF().getSemantics()==&APFloat::IEEEdouble;
    if (isDouble) {
      double val = CFP->getValueAPF().convertToDouble();
      union dtol_union {
        double d;
        uint64_t l;
        char c[8];
      } conv;
      conv.d = val;
      if (!asBytes) {
        O << ":";
        O.write_hex(conv.l);
      } else {
        for (int i = 0; i < 8; ++i) {
          O << ":";
          O.write_hex((unsigned)conv.c[i] & 0xFF);
        }
      }
    } else {
      float val = CFP->getValueAPF().convertToFloat();
      union ftoi_union {
        float f;
        uint32_t u;
        char c[4];
      } conv;
      conv.f = val;
      if (!asBytes) {
        O << ":";
        O.write_hex(conv.u);
      } else {
        for (int i = 0; i < 4; ++i) {
          O << ":";
          O.write_hex((unsigned)conv.c[i] & 0xFF);
        }
      }
    }
  } else if (const ConstantInt *CI = dyn_cast<ConstantInt>(CAval)) {
    uint64_t zVal = CI->getValue().getZExtValue();
    if (!asBytes) {
      O << ":";
      O.write_hex(zVal);
    } else {
      switch (CI->getBitWidth()) {
      default:
        {
          union ltob_union {
            uint64_t l;
            char c[8];
          } conv;
          conv.l = zVal;
          for (int i = 0; i < 8; ++i) {
            O << ":";
            O.write_hex((unsigned)conv.c[i] & 0xFF);
          }
        }
        break;
      case 8:
        O << ":";
        O.write_hex(zVal & 0xFF);
        break;
      case 16:
        {
          union stob_union {
            uint16_t s;
            char c[2];
          } conv;
          conv.s = (uint16_t)zVal;
          O << ":";
          O.write_hex((unsigned)conv.c[0] & 0xFF);
          O << ":";
          O.write_hex((unsigned)conv.c[1] & 0xFF);
        }
        break;
      case 32:
        {
          union itob_union {
            uint32_t i;
            char c[4];
          } conv;
          conv.i = (uint32_t)zVal;
          for (int i = 0; i < 4; ++i) {
            O << ":";
            O.write_hex((unsigned)conv.c[i] & 0xFF);
          }
        }
        break;
      }
    }
  } else if (const ConstantVector *CV = dyn_cast<ConstantVector>(CAval)) {
    int y = CV->getNumOperands()-1;
    int x = 0;
    for (; x < y; ++x) {
      printConstantValue(CV->getOperand(x), O, asBytes);
    }
    printConstantValue(CV->getOperand(x), O, asBytes);
  } else if (const ConstantStruct *CS = dyn_cast<ConstantStruct>(CAval)) {
    int y = CS->getNumOperands();
    int x = 0;
    for (; x < y; ++x) {
      printConstantValue(CS->getOperand(x), O, asBytes);
    }
  } else if (const ConstantAggregateZero *CAZ
      = dyn_cast<ConstantAggregateZero>(CAval)) {
    int y = CAZ->getNumOperands();
    if (y > 0) {
      int x = 0;
      for (; x < y; ++x) {
        printConstantValue((llvm::Constant *)CAZ->getOperand(x),
            O, asBytes);
      }
    } else {
      if (asBytes) {
        dumpZeroElements(CAval->getType(), O, asBytes);
      } else {
        int num_elts = HSAILgetNumElements(CAval->getType())-1;
        for (int x = 0; x < num_elts; ++x) {
          O << ":0";
        }
        O << ":0";
      }
    }
  } else if (const ConstantArray *CA = dyn_cast<ConstantArray>(CAval)) {
    int y = CA->getNumOperands();
    int x = 0;
    for (; x < y; ++x) {
      printConstantValue(CA->getOperand(x), O, asBytes);
    }
  } else if (dyn_cast<ConstantPointerNull>(CAval)) {
    O << ":0";
  } else if (dyn_cast<ConstantExpr>(CAval)) {
    O << ":0";
  } else if (dyn_cast<UndefValue>(CAval)) {
    O << ":0";
  } else {
    assert(0 && "Hit condition which was not expected");
  }
}

static bool isStruct(Type * const T)
{
  if (!T) {
    return false;
  }
  switch (T->getTypeID()) {
  default:
    return false;
  case Type::PointerTyID:
    return isStruct(T->getContainedType(0));
  case Type::StructTyID:
    return true;
  case Type::ArrayTyID:
  case Type::VectorTyID:
    return isStruct(dyn_cast<SequentialType>(T)->getElementType());
  };

}

/// Create a function ID if it is not known or return the known
/// function ID.
uint32_t HSAILModuleInfo::getOrCreateFunctionID(const GlobalValue* func) {
  if (func->getName().size()) {
    return getOrCreateFunctionID(func->getName());
  } 
  uint32_t id;
  if (mFuncPtrNames.find(func) == mFuncPtrNames.end()) {
    id = mFuncPtrNames.size() + RESERVED_FUNCS + mFuncNames.size();
    mFuncPtrNames[func] = id;
  } else {
    id = mFuncPtrNames[func];
  }
  return id;
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
