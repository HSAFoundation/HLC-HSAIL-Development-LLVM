
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
// to the U.S. Export Administration Regulations (EAR), (15 C.F.R. Sections
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
// Industry and Securitys website at http://www.bis.doc.gov/.
//
//==-----------------------------------------------------------------------===//
#include "libHSAIL/HSAILBrigantine.h"
#include "HSAILKernelManager.h"
#include "AMDOpenCLKernenv.h"
#include "HSAILAlgorithms.tpp"
#include "HSAILDeviceInfo.h"
#include "HSAILDevices.h"
#include "HSAILCompilerErrors.h"
#include "HSAILKernel.h"
#include "HSAILMachineFunctionInfo.h"
#include "HSAILModuleInfo.h"
#include "HSAILSubtarget.h"
#include "HSAILTargetMachine.h"
#include "HSAILUtilityFunctions.h"
#include "HSAILOpaqueTypes.h"
#include "HSAILLLVMVersion.h"
#include "libHSAIL/HSAILBrigantine.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/Support/FormattedStream.h"
#include "llvm/Support/MathExtras.h"
#include <cstdio>
#include <ostream>
#include <sstream>
#include <algorithm>
#include <string>
#include <queue>
#include <list>
#include <utility>
using namespace llvm;
#define NUM_EXTRA_SLOTS_PER_IMAGE 1

// This header file is required for generating global variables for kernel
// argument info.
namespace clk {
typedef unsigned int uint;
typedef uint32_t cl_mem_fence_flags;
//#include <amdocl/cl_kernel.h>
//kernel arg access qualifier and type qualifier
typedef enum clk_arg_qualifier_t
{
    Q_NONE = 0,

    //for image type only, access qualifier
    Q_READ = 1,
    Q_WRITE = 2,

    //for pointer type only
    Q_CONST = 4, // pointee
    Q_RESTRICT = 8,
    Q_VOLATILE = 16,  // pointee
    Q_PIPE = 32  // pipe

} clk_arg_qualifier_t;

} // end of namespace clk

static bool errorPrint(const char *ptr, OSTREAM_TYPE &O) {
  if (ptr[0] == 'E') {
    O << ";error:" << ptr << "\n";
  } else {
    O << ";warning:" << ptr << "\n";
  }
  return false;
}

static bool
printfPrint(std::pair<const std::string, HSAILPrintfInfo *> &data, OSTREAM_TYPE &O) {
  O << ";printf_fmt:" << data.second->getPrintfID();
  // Number of operands
  O << ":" << data.second->getNumOperands();
  // Size of each operand
  for (size_t i = 0, e = data.second->getNumOperands(); i < e; ++i) {
    O << ":" << (data.second->getOperandID(i) >> 3);
  }
  const char *ptr = data.first.c_str();
  uint32_t size = data.first.size() - 1;
  // The format string size
  O << ":" << size << ":";
  for (size_t i = 0; i < size; ++i) {
    if (ptr[i] == '\r') {
      O << "\\r";
    } else if (ptr[i] == '\n') {
      O << "\\n";
    } else {
      O << ptr[i];
    }
  }
  O << ";\n";   // c_str() is cheap way to trim
  return false;
}

void HSAILKernelManager::updatePtrArg(Function::const_arg_iterator Ip,
                                      int counter, bool isKernel,
                                      const Function *F, int pointerCount) {
  assert(F && "Cannot pass a NULL Pointer to F!");
  assert(Ip->getType()->isPointerTy() &&
         "Argument must be a pointer to be passed into this function!\n");
  std::string ptrArg("pointer:");
  const char *symTab = "NoSymTab";
  uint32_t ptrID = getUAVID(Ip);
  PointerType *PT = cast<PointerType>(Ip->getType());
  uint32_t Align = 4;
  const char *MemType = "uav";
  if (PT->getElementType()->isSized()) {
    Align = mTM->getSubtarget<HSAILSubtarget>().getDataLayout()->getTypeAllocSize(PT->getElementType());
    if ((Align & (Align - 1))) Align = NextPowerOf2(Align);
  }
  ptrArg += Ip->getName().str() + ":" + 
    HSAIL::HSAILgetTypeName(PT, symTab, mMFI, 
                     mMFI->isSignedIntType(Ip)) + ":1:1:" +
    itostr(counter * 16) + ":";
  switch (PT->getAddressSpace()) {
  case HSAILAS::ADDRESS_NONE:
    //O << "No Address space qualifier!";
    mMFI->addErrorMsg(hsa::CompilerErrorMessage[INTERNAL_ERROR]);
    assert(1);
    break;
  case HSAILAS::GLOBAL_ADDRESS:
    mMFI->uav_insert(ptrID);
    break;
  case HSAILAS::CONSTANT_ADDRESS: {
    if (isKernel && mSTM->device()->usesHardware(HSAILDeviceInfo::ConstantMem)){
      const HSAILKernel* t = mAMI->getKernel(F->getName());
      if (mAMI->usesHWConstant(t, Ip->getName())) {
        MemType = /*(isSI) ? "uc\0" :*/ "hc\0";
        ptrID = mAMI->getConstPtrCB(t, Ip->getName());
      } else {
        MemType = "c\0";
        mMFI->uav_insert(ptrID);
      }
    } else {
      MemType = "c\0";
      mMFI->uav_insert(ptrID);
    }
    break; 
  }
  default:
  case HSAILAS::PRIVATE_ADDRESS:
    if (mSTM->device()->usesHardware(HSAILDeviceInfo::PrivateMem)) {
      MemType = "hp\0";
    } else {
      MemType = "p\0";
      mMFI->uav_insert(ptrID);
    }
    break;
  case HSAILAS::REGION_ADDRESS:
    mMFI->setUsesRegion();
    if (mSTM->device()->usesHardware(HSAILDeviceInfo::RegionMem)) {
      MemType = "hr\0";
      ptrID = 0;
    } else {
      MemType = "r\0";
      mMFI->uav_insert(ptrID);
    }
    break;
  case HSAILAS::GROUP_ADDRESS:
    mMFI->setUsesLocal();
    if (mSTM->device()->usesHardware(HSAILDeviceInfo::LocalMem)) {
      MemType = "hl\0";
      ptrID = 1;
    } else {
      MemType = "l\0";
      mMFI->uav_insert(ptrID);
    }
    break;
  };
  ptrArg += std::string(MemType) + ":";
  ptrArg += itostr(ptrID) + ":";
  ptrArg += itostr(Align) + ":";
  const Value* ptr = Ip;
  if (mMFI->read_ptr_count(ptr)) {
    ptrArg += "RO";
  // FIXME: add write-only pointer detection.
  //} else if (mMFI->write_ptr_count(ptr)) {
  //  ptrArg += "WO";
  } else {
    ptrArg += "RW";
  }

  const Module* M = mMF->getMMI().getModule();
  bool isSPIR = HSAIL::isSPIRModule(*M);
  if (isSPIR) {
    if (pointerCount == 0)
      ptrArg += ":0:0:0"; //skip the print_buffer pointer
    // No need update the kernel info for block kernels (child kernel).
    else if (!F->getName().startswith("__OpenCL___amd_blocks_func__"))
    {
      int typeQual = mAMI->getKernel(F->getName())->
         accessTypeQualifer[pointerCount-1];
      ptrArg += (typeQual & clk::Q_VOLATILE) ? ":1" : ":0";
      ptrArg += (typeQual & clk::Q_RESTRICT) ? ":1" : ":0";
      ptrArg += (typeQual & clk::Q_PIPE)     ? ":1" : ":0";
    }
  } else {
    ptrArg += (mMFI->isVolatilePointer(Ip)) ? ":1" : ":0";
    ptrArg += (mMFI->isRestrictPointer(Ip)) ? ":1" : ":0";
  }
  mMFI->addMetadata(ptrArg, true);
}

HSAILKernelManager::HSAILKernelManager(HSAILTargetMachine *TM)
{
  mTM = TM;
  mSTM = mTM->getSubtargetImpl();
  mMFI = NULL;
  mAMI = NULL;
  mMF = NULL;
  clear();
}

HSAILKernelManager::~HSAILKernelManager() {
  clear();
}

void 
HSAILKernelManager::setMF(MachineFunction *MF)
{
  mMF = MF;
  mMFI = MF->getInfo<HSAILMachineFunctionInfo>();
  mAMI = &(MF->getMMI().getObjFileInfo<HSAILModuleInfo>());
}

void HSAILKernelManager::clear() {
  mUniqueID = 0;
  mWasKernel = false;
  mHasImageWrite = false;
  mHasOutputInst = false;
}

void HSAILKernelManager::processArgMetadata(OSTREAM_TYPE &ignored,
                                            uint32_t buf,
                                            bool isKernel) 
{
  const Function *F = mMF->getFunction();
  const char * symTab = "NoSymTab";
  Function::const_arg_iterator Ip = F->arg_begin();
  Function::const_arg_iterator Ep = F->arg_end();
  int pointerCount = 0;

  if (F->hasStructRetAttr()) {
    assert(Ip != Ep && "Invalid struct return fucntion!");
    mMFI->addErrorMsg(hsa::CompilerErrorMessage[INTERNAL_ERROR]);
    ++Ip;
  }
  uint32_t mCBSize = 0;
  uint32_t CounterNum = 0;
  uint32_t SemaNum = 0;
  uint32_t ROArg = 0;
  uint32_t WOArg = 0;
  uint32_t RWArg = 0;
  uint32_t NumArg = 0;
  uint32_t SamplerNum = 0;

  while (Ip != Ep) {
    Type *cType = Ip->getType();
    if (cType->isIntOrIntVectorTy() || cType->isFPOrFPVectorTy()) {
      std::string argMeta("value:");
      argMeta += Ip->getName().str() + ":" + HSAIL::HSAILgetTypeName(cType, symTab, mMFI
          , mMFI->isSignedIntType(Ip)) + ":";
      int bitsize = cType->getPrimitiveSizeInBits();
      int numEle = 1;
      if (cType->getTypeID() == Type::VectorTyID) {
        numEle = cast<VectorType>(cType)->getNumElements();
      }
      argMeta += itostr(numEle) + ":1:" + itostr((int64_t)mCBSize << 4);
      mMFI->addMetadata(argMeta, true);

      // FIXME: simplify
      if ((bitsize / numEle) < 32) {
        bitsize = numEle >> 2;
      } else {
        bitsize >>= 7;
      }
      if (!bitsize) {
        bitsize = 1;
      }

      mCBSize += bitsize;
    } else if (const PointerType *PT = dyn_cast<PointerType>(cType)) {
      Type *CT = PT->getElementType();
      const StructType *ST = dyn_cast<StructType>(CT);
      if (ST && ST->isOpaque()) {
        OpaqueType OT = GetOpaqueType(ST);
        if (IsImage(OT)) {
           
          std::string imageArg("image:");
          imageArg += Ip->getName().str() + ":";
          switch (OT) {
            case I1D:   imageArg += "1D:";   break;
            case I1DA:  imageArg += "1DA:";  break;
            case I1DB:  imageArg += "1DB:";  break;
            case I2D:   imageArg += "2D:";   break;
            case I2DA:  imageArg += "2DA:";  break;
            case I3D:   imageArg += "3D:";   break;
            case I2DDepth: imageArg += "2DDepth:"; break;
            case I2DADepth: imageArg += "2DADepth:"; break;
            default:    llvm_unreachable("unknown image type"); break;
          }
          if (isKernel) {
            if (mAMI->isReadOnlyImage (mMF->getFunction()->getName(),
                                       (ROArg + WOArg + RWArg))) {
              imageArg += "RO:" + itostr(ROArg);
              ++ROArg;
            } else if (mAMI->isWriteOnlyImage(mMF->getFunction()->getName(),
                                              (ROArg + WOArg + RWArg))) {
              imageArg += "WO:" + itostr(WOArg);
              ++WOArg;
            } else if (mAMI->isReadWriteImage(mMF->getFunction()->getName(),
                                              (ROArg + WOArg + RWArg))) {
              imageArg += "RW:" + itostr(RWArg);
              ++RWArg;
            }
          }
          imageArg += ":1:" + itostr(mCBSize * 16);
          mMFI->addMetadata(imageArg, true);
          mMFI->addi32Literal(mCBSize);
          mCBSize += NUM_EXTRA_SLOTS_PER_IMAGE + 1;
        } else if (OT == C32 || OT == C64) {
          std::string counterArg("counter:");
          counterArg += Ip->getName().str() + ":"
            + itostr(OT == C32 ? 32 : 64) + ":"
            + itostr(CounterNum++) + ":1:" + itostr(mCBSize * 16);
          mMFI->addMetadata(counterArg, true);
          ++mCBSize;
        } else if (OT == Sema) {
          std::string semaArg("sema:");
          semaArg += Ip->getName().str() + ":" + itostr(SemaNum++)
            + ":1:" + itostr(mCBSize * 16);
          mMFI->addMetadata(semaArg, true);
          ++mCBSize;
        } else if (OT == Sampler) {
          std::string samplerArg("sampler:");
          samplerArg += Ip->getName().str() + ":" + itostr(SamplerNum++)
            + ":1:" + itostr(mCBSize * 16);
          mMFI->addMetadata(samplerArg, true);
          ++mCBSize;
        } else if (OT == QueueT) {
          std::string queueArg("queue:");
          PointerType *PT = cast<PointerType>(Ip->getType());
          const char *MemType = "uav";
          if (PT->getAddressSpace() == HSAILAS::PRIVATE_ADDRESS) {
              if (mSTM->device()->usesHardware(HSAILDeviceInfo::PrivateMem)) {
              MemType = "hp\0";
              } else {
               MemType = "p\0";
              }
          }
          queueArg += Ip->getName().str() + ":"
            + HSAIL::HSAILgetTypeName(PT, symTab, mMFI, mMFI->isSignedIntType(Ip))
            + ":1:1:" + itostr(mCBSize * 16) + ":" + MemType;
          mMFI->addMetadata(queueArg, true);
          ++mCBSize;
		} else {
          updatePtrArg(Ip, mCBSize, isKernel, F, pointerCount++);
          ++mCBSize;
        }
      } else if (CT->getTypeID() == Type::StructTyID 
                 && Ip->hasByValAttr()) { // To distinguish pass-by-value from pass-by-ptr.
        // When struct is passed-by-value, the pointer to the struct copy
        // is passed to the kernel. Relevant RTI is generated here (value...struct).
        // [Informative: RTI for pass-by-pointer case (pointer...struct) is generated
        // in the next "else if" block.]     
        const DataLayout *dl = mTM->getSubtarget<HSAILSubtarget>().getDataLayout();
        const StructLayout *sl = dl->getStructLayout(dyn_cast<StructType>(CT));
        int bytesize = sl->getSizeInBytes();
        int reservedsize = (bytesize + 15) & ~15;
        int numSlots = reservedsize >> 4;
        if (!numSlots) {
          numSlots = 1;
        }
        std::string structArg("value:");
        structArg += Ip->getName().str() + ":struct:"
          + itostr(bytesize) + ":1:" + itostr(mCBSize * 16);
        mMFI->addMetadata(structArg, true);
        mCBSize += numSlots;
      } else if (CT->isIntOrIntVectorTy()
                 || CT->isFPOrFPVectorTy()
                 || CT->getTypeID() == Type::ArrayTyID
                 || CT->getTypeID() == Type::PointerTyID
                 || PT->getAddressSpace() != HSAILAS::PRIVATE_ADDRESS) {
        updatePtrArg(Ip, mCBSize, isKernel, F, pointerCount++);
        ++mCBSize;
      } else {
        assert(0 && "Cannot process current pointer argument");
        mMFI->addErrorMsg(hsa::CompilerErrorMessage[INTERNAL_ERROR]);
      }
    } else {
      assert(0 && "Cannot process current kernel argument");
      mMFI->addErrorMsg(hsa::CompilerErrorMessage[INTERNAL_ERROR]);
    }
    const Module* M = mMF->getMMI().getModule();
    bool isSPIR = HSAIL::isSPIRModule(*M);
    bool isConstArg = false;

    StringRef FuncName = F->getName();
    // No need update the kernel info for block kernels (child kernel).
    if (isSPIR && !FuncName.startswith("__OpenCL___amd_blocks_func_")) {
      if (NumArg >= HSAIL::KE_NUM_ARGS) {
       int typeQual = mAMI->getKernel(F->getName())->
                            accessTypeQualifer[NumArg - HSAIL::KE_NUM_ARGS];
       if ((typeQual & clk::Q_CONST))
         isConstArg = true;
      }
    } else if (mMFI->isConstantArgument(Ip)) {
         isConstArg = true;
    }
    if (isConstArg) {
      std::string constArg("constarg:");
      constArg += itostr(NumArg) + ":" + Ip->getName().str();
      mMFI->addMetadata(constArg, true);
    }
    ++NumArg;
    ++Ip;
  }
}

void HSAILKernelManager::printHeader(const std::string &name) 
{
  mName = name;
  mAMI->getOrCreateFunctionID(name);
}

/** 
 *
 * HSAIL format for emitting runtime information: 
 * block "rti"
 * blockstring "<metadata>";
 * endblock;
 *
 * @param O 
 * @param id 
 * @param kernel 
 */

void HSAILKernelManager::setKernel(bool kernel) {
  mIsKernel = kernel;
  if (kernel) {
    mWasKernel = mIsKernel;
  }
}

void HSAILKernelManager::setID(uint32_t id)
{
  mUniqueID = id;
}

void HSAILKernelManager::setName(const std::string &name) {
  mName = name;
}

class RTI {
    std::string m_str;
    HSAIL_ASM::Brigantine&  m_brig;
    mutable llvm::raw_string_ostream m_os;
public:
    RTI(HSAIL_ASM::Brigantine&  brig) : m_brig(brig), m_os(m_str) { }

    ~RTI() {
      HSAIL_ASM::DirectivePragma pragma = m_brig.append<HSAIL_ASM::DirectivePragma>();
      HSAIL_ASM::ItemList opnds;
      opnds.push_back(m_brig.createOperandString("AMD RTI"));
      const std::string& str = m_os.str();
      opnds.push_back(m_brig.createOperandString(str));
    pragma.operands() = opnds;
    }

    llvm::raw_string_ostream& os() const { return m_os; }
};

template <typename T>
const RTI& operator << (const RTI& os, const T& s)    { os.os() << s; return os; } 
const RTI& operator << (const RTI& os, const char *s) { os.os() << s; return os; } 

void HSAILKernelManager::brigEmitMetaData(HSAIL_ASM::Brigantine& brig, uint32_t id, bool isKernel) {

    // Initialization block related to current function being processed
    int kernelId = id;
    if (isKernel) {
      kernelId = mAMI->getOrCreateFunctionID(mName);
      mMFI->addCalledFunc(id);
      mUniqueID = kernelId;
      mIsKernel = true;
    }

    const HSAILKernel *kernel = mAMI->getKernel(mName);  
    
    if (kernel && isKernel && kernel->sgv) {
      if (kernel->sgv->mHasRWG) {
          HSAIL_ASM::DirectiveControl dc = brig.append< HSAIL_ASM::DirectiveControl>();
          dc.control() = Brig::BRIG_CONTROL_REQUIREDWORKGROUPSIZE;

          HSAIL_ASM::ItemList opnds;
          for(int i=0; i<3; ++i) {
            opnds.push_back(brig.createImmed(kernel->sgv->reqGroupSize[i],Brig::BRIG_TYPE_U32));
          }
          dc.operands() = opnds;
      }
    }

    if (isKernel) {
      std::string emptyStr("");
      std::string &refEmptyStr(emptyStr);
      llvm::raw_string_ostream oss(refEmptyStr);
      // function name
      RTI(brig)  << "ARGSTART:" << mName;
      if(isKernel) {
        // version
        RTI(brig) << "version:" << itostr(mSTM->supportMetadata30() ? HSAIL_MAJOR_VERSION : 2) << ":"
                        << itostr(HSAIL_MINOR_VERSION) + ":" 
                        << itostr(mSTM->supportMetadata30() ? HSAIL_REVISION_NUMBER : HSAIL_20_REVISION_NUMBER);
        // device info
        RTI(brig) << "device:" << mSTM->getDeviceName();
      }
      RTI(brig) << "uniqueid:" << kernelId;
      if (kernel) {
        size_t local = kernel->curSize;
        size_t hwlocal = ((kernel->curHWSize + 3) & (~0x3));
        size_t region = kernel->curRSize;
        size_t hwregion = ((kernel->curHWRSize + 3) & (~0x3));
        bool usehwlocal = mSTM->device()->usesHardware(HSAILDeviceInfo::LocalMem);
        bool usehwprivate = mSTM->device()->usesHardware(HSAILDeviceInfo::PrivateMem);
        bool usehwregion = mSTM->device()->usesHardware(HSAILDeviceInfo::RegionMem);
        // private memory
        RTI(brig) << "memory:" << ((usehwprivate) ? "hw" : "" ) << "private:" << (((mMFI->getStackSize() + mMFI->getPrivateSize() + 15) & (~0xF)));
        // region memory
        RTI(brig) << "memory:" << ((usehwregion) ? "hw" : "") << "region:" << ((usehwregion) ? hwregion : hwregion + region);
        // local memory
        RTI(brig) << "memory:" << ((usehwlocal) ? "hw" : "") << "local:" << ((usehwlocal) ? hwlocal : hwlocal + local)+mMFI->getGroupSize();
        if (kernel && isKernel && kernel->sgv) {
          if (kernel->sgv->mHasRWG) {
            RTI(brig) << "cws:" << kernel->sgv->reqGroupSize[0] << ":" << kernel->sgv->reqGroupSize[1] << ":" << kernel->sgv->reqGroupSize[2];
          }
          if (kernel->sgv->mHasRWR) {
            RTI(brig) << "crs:" << kernel->sgv->reqRegionSize[0] << ":" << kernel->sgv->reqRegionSize[1] << ":" << kernel->sgv->reqRegionSize[2];
          }
        }
      }
      if (isKernel) {
        for (std::vector<std::string>::iterator ib = mMFI->kernel_md_begin(), ie = mMFI->kernel_md_end(); ib != ie; ++ib) {
          std::string md = *ib;
          if ( md.find("argmap") == std::string::npos ) {
            RTI(brig) << (*ib);
          }
        }
      }

    for (std::set<std::string>::iterator ib = mMFI->func_md_begin(), ie = mMFI->func_md_end(); ib != ie; ++ib) {
      RTI(brig) << (*ib);
    }

    if (!mMFI->func_empty()) {
      oss.str().clear();  
      oss << "function:" << mMFI->func_size();
      binaryForEach(mMFI->func_begin(), mMFI->func_end(), HSAIL::HSAILcommaPrint, oss);
      RTI(brig) << oss.str();
    }

    if (isKernel) {
      for (StringMap<SamplerInfo>::iterator 
        smb = mMFI->sampler_begin(),
        sme = mMFI->sampler_end(); smb != sme; ++ smb) {
        RTI(brig) << "sampler:" << (*smb).second.name << ":" << (*smb).second.idx
          << ":" << ((*smb).second.val == (uint32_t)-1 ? 0 : 1) 
          << ":" << ((*smb).second.val != (uint32_t)-1 ? (*smb).second.val : 0);
      }
    }
    if (mSTM->is64Bit()) {
      RTI(brig) << "memory:64bitABI";
    }

    if (mMFI->errors_empty()) {
      oss.str().clear();  
      binaryForEach(mMFI->errors_begin(), mMFI->errors_end(), errorPrint, oss);
      if ( ! oss.str().empty() ) {
        RTI(brig) << oss.str();
      }
    }
    if (isKernel) {
      RTI(brig) << "privateid:" << mSTM->device()->getResourceID(HSAILDevice::SCRATCH_ID);
    }
    // Metadata for the device enqueue.
    if (kernel && isKernel) {
      RTI(brig) << "enqueue_kernel:" << kernel->EnqueuesKernel;
      RTI(brig) << "kernel_index:" << kernel->KernelIndex;
    }

    if (kernel) {
      for (unsigned I = 0, E = kernel->ArgTypeNames.size(); I != E; ++I) {
        RTI(brig) << "reflection:" << I << ":" << kernel->ArgTypeNames[I];
      }
    }

    RTI(brig) << "ARGEND:" << mName;
  }

  // De-initialization block
  if (isKernel) {
    mIsKernel = false;
    mMFI->eraseCalledFunc(id);
    mUniqueID = id;
  }
}

uint32_t HSAILKernelManager::getUAVID(const Value *value) {
  if (mValueIDMap.find(value) != mValueIDMap.end()) {
    return mValueIDMap[value];
  }

  return mSTM->device()->getResourceID(HSAILDevice::RAW_UAV_ID);
}
