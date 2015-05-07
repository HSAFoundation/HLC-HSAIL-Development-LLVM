//===-- HSAILKernelManager.cpp --------------------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "HSAILKernelManager.h"
#include "AMDOpenCLKernenv.h"
#include "HSAILCompilerErrors.h"
#include "HSAILKernel.h"
#include "HSAILMachineFunctionInfo.h"
#include "HSAILModuleInfo.h"
#include "HSAILSubtarget.h"
#include "HSAILTargetMachine.h"
#include "HSAILUtilityFunctions.h"
#include "HSAILOpaqueTypes.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"

#include "llvm/ADT/StringExtras.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/Support/FormattedStream.h"
#include "llvm/Support/MathExtras.h"

#include "libHSAIL/HSAILBrigantine.h"
#include "libHSAIL/HSAILItems.h"

using namespace llvm;
#define NUM_EXTRA_SLOTS_PER_IMAGE 1

// This header file is required for generating global variables for kernel
// argument info.
namespace clk {
typedef unsigned int uint;
typedef uint32_t cl_mem_fence_flags;
//#include <amdocl/cl_kernel.h>
// kernel arg access qualifier and type qualifier
typedef enum clk_arg_qualifier_t {
  Q_NONE = 0,

  // for image type only, access qualifier
  Q_READ = 1,
  Q_WRITE = 2,

  // for pointer type only
  Q_CONST = 4, // pointee
  Q_RESTRICT = 8,
  Q_VOLATILE = 16, // pointee
  Q_PIPE = 32      // pipe

} clk_arg_qualifier_t;

} // end of namespace clk


static const char *getTypeName(Type *ptr, const char *symTab,
                               HSAILMachineFunctionInfo *mfi, bool signedType) {
  switch (ptr->getTypeID()) {
  case Type::StructTyID: {
    OpaqueType OT = GetOpaqueType(ptr);

    switch (OT) {
    case NotOpaque:
      return "struct";
    case Event:
      return "event";
    case Sampler:
      return "sampler";
    case I1D:
      return "image1d";
    case I1DB:
      return "image1d_buffer";
    case I1DA:
      return "image1d_array";
    case I2D:
      return "image2d";
    case I2DA:
      return "image2d_array";
    case I3D:
      return "image3d";
    case I2DDepth:
      return "image2ddepth";
    case I2DADepth:
      return "image2dadepth";
    case Sema:
      return "semaphore";
    case C32:
      return "counter32";
    case C64:
      return "counter64";
    case ReserveId:
      return "reserveId";
    case CLKEventT:
      return "clk_event_t";
    case QueueT:
      return "queue_t";
    case UnknownOpaque:
      return "opaque";
    }
  }
  case Type::HalfTyID:
    return "half";
  case Type::FloatTyID:
    return "float";
  case Type::DoubleTyID: {
    return "double";
  }
  case Type::IntegerTyID: {
    LLVMContext &ctx = ptr->getContext();
    if (ptr == Type::getInt8Ty(ctx)) {
      return (signedType) ? "i8" : "u8";
    } else if (ptr == Type::getInt16Ty(ctx)) {
      return (signedType) ? "i16" : "u16";
    } else if (ptr == Type::getInt32Ty(ctx)) {
      return (signedType) ? "i32" : "u32";
    } else if (ptr == Type::getInt64Ty(ctx)) {
      return (signedType) ? "i64" : "u64";
    }
    break;
  }
  default:
    break;
  case Type::ArrayTyID: {
    const ArrayType *AT = cast<ArrayType>(ptr);
    ptr = AT->getElementType();
    return getTypeName(ptr, symTab, mfi, signedType);
    break;
  }
  case Type::VectorTyID: {
    const VectorType *VT = cast<VectorType>(ptr);
    ptr = VT->getElementType();
    return getTypeName(ptr, symTab, mfi, signedType);
    break;
  }
  case Type::PointerTyID: {
    const PointerType *PT = cast<PointerType>(ptr);
    ptr = PT->getElementType();
    return getTypeName(ptr, symTab, mfi, signedType);
    break;
  }
  case Type::FunctionTyID: {
    const FunctionType *FT = cast<FunctionType>(ptr);
    ptr = FT->getReturnType();
    return getTypeName(ptr, symTab, mfi, signedType);
    break;
  }
  }
  ptr->dump();
  if (mfi) {
#if 0
    mfi->addErrorMsg(amd::CompilerErrorMessage[UNKNOWN_TYPE_NAME]);
#endif
  }
  return "unknown";
}


void HSAILKernelManager::updatePtrArg(Function::const_arg_iterator Ip,
                                      int counter, bool isKernel,
                                      const Function *F, int pointerCount) {
  assert(F && "Cannot pass a nullptr Pointer to F!");
  assert(Ip->getType()->isPointerTy() &&
         "Argument must be a pointer to be passed into this function!\n");
  std::string ptrArg("pointer:");
  const char *symTab = "NoSymTab";
  uint32_t ptrID = getUAVID(Ip);
  PointerType *PT = cast<PointerType>(Ip->getType());
  uint32_t Align = 4;
  const char *MemType = "uav";
  if (PT->getElementType()->isSized()) {
    Align =
        mTM->getDataLayout()->getTypeAllocSize(
            PT->getElementType());
    if ((Align & (Align - 1)))
      Align = NextPowerOf2(Align);
  }
  ptrArg += Ip->getName().str() + ":" +
            getTypeName(PT, symTab, mMFI, mMFI->isSignedIntType(Ip)) +
            ":1:1:" + itostr(counter * 16) + ":";
  switch (PT->getAddressSpace()) {
  case HSAILAS::ADDRESS_NONE:
    // O << "No Address space qualifier!";
    mMFI->addErrorMsg(hsa::CompilerErrorMessage[INTERNAL_ERROR]);
    assert(1);
    break;
  case HSAILAS::GLOBAL_ADDRESS:
    mMFI->uav_insert(ptrID);
    break;
  case HSAILAS::READONLY_ADDRESS: {
    if (isKernel) {
      const HSAILKernel *t = mAMI->getKernel(F->getName());
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
    MemType = "hp\0";
    break;
  case HSAILAS::REGION_ADDRESS:
    mMFI->setUsesRegion();
    MemType = "hr\0";
    ptrID = 0;
    break;
  case HSAILAS::GROUP_ADDRESS:
    mMFI->setUsesLocal();
    MemType = "hl\0";
    ptrID = 1;
    break;
  };
  ptrArg += std::string(MemType) + ":";
  ptrArg += itostr(ptrID) + ":";
  ptrArg += itostr(Align) + ":";
  const Value *ptr = Ip;
  if (mMFI->read_ptr_count(ptr)) {
    ptrArg += "RO";
    // FIXME: add write-only pointer detection.
    //} else if (mMFI->write_ptr_count(ptr)) {
    //  ptrArg += "WO";
  } else {
    ptrArg += "RW";
  }

  const Module *M = mMF->getMMI().getModule();
  bool isSPIR = HSAIL::isSPIRModule(*M);
  if (isSPIR) {
    if (pointerCount == 0)
      ptrArg += ":0:0:0"; // skip the print_buffer pointer
    // No need update the kernel info for block kernels (child kernel).
    else if (!F->getName().startswith("__OpenCL___amd_blocks_func__")) {
      int typeQual =
          mAMI->getKernel(F->getName())->accessTypeQualifer[pointerCount - 1];
      ptrArg += (typeQual & clk::Q_VOLATILE) ? ":1" : ":0";
      ptrArg += (typeQual & clk::Q_RESTRICT) ? ":1" : ":0";
      ptrArg += (typeQual & clk::Q_PIPE) ? ":1" : ":0";
    }
  } else {
    ptrArg += (mMFI->isVolatilePointer(Ip)) ? ":1" : ":0";
    ptrArg += (mMFI->isRestrictPointer(Ip)) ? ":1" : ":0";
  }
  mMFI->addMetadata(ptrArg, true);
}

HSAILKernelManager::HSAILKernelManager(HSAILTargetMachine *TM) {
  mTM = TM;
  mSTM = mTM->getSubtargetImpl();
  mMFI = nullptr;
  mAMI = nullptr;
  mMF = nullptr;
  clear();
}

HSAILKernelManager::~HSAILKernelManager() { clear(); }

void HSAILKernelManager::setMF(MachineFunction *MF) {
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

void HSAILKernelManager::processArgMetadata(raw_ostream &ignored, uint32_t buf,
                                            bool isKernel) {
  const Function *F = mMF->getFunction();
  const char *symTab = "NoSymTab";
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
      argMeta +=
          Ip->getName().str() + ":" +
          getTypeName(cType, symTab, mMFI, mMFI->isSignedIntType(Ip)) +
          ":";
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
          case I1D:
            imageArg += "1D:";
            break;
          case I1DA:
            imageArg += "1DA:";
            break;
          case I1DB:
            imageArg += "1DB:";
            break;
          case I2D:
            imageArg += "2D:";
            break;
          case I2DA:
            imageArg += "2DA:";
            break;
          case I3D:
            imageArg += "3D:";
            break;
          case I2DDepth:
            imageArg += "2DDepth:";
            break;
          case I2DADepth:
            imageArg += "2DADepth:";
            break;
          default:
            llvm_unreachable("unknown image type");
            break;
          }
          if (isKernel) {
            if (mAMI->isReadOnlyImage(mMF->getFunction()->getName(),
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
          counterArg += Ip->getName().str() + ":" +
                        itostr(OT == C32 ? 32 : 64) + ":" +
                        itostr(CounterNum++) + ":1:" + itostr(mCBSize * 16);
          mMFI->addMetadata(counterArg, true);
          ++mCBSize;
        } else if (OT == Sema) {
          std::string semaArg("sema:");
          semaArg += Ip->getName().str() + ":" + itostr(SemaNum++) + ":1:" +
                     itostr(mCBSize * 16);
          mMFI->addMetadata(semaArg, true);
          ++mCBSize;
        } else if (OT == Sampler) {
          std::string samplerArg("sampler:");
          samplerArg += Ip->getName().str() + ":" + itostr(SamplerNum++) +
                        ":1:" + itostr(mCBSize * 16);
          mMFI->addMetadata(samplerArg, true);
          ++mCBSize;
        } else if (OT == QueueT) {
          std::string queueArg("queue:");
          PointerType *PT = cast<PointerType>(Ip->getType());
          const char *MemType = "uav";
          if (PT->getAddressSpace() == HSAILAS::PRIVATE_ADDRESS) {
            MemType = "hp\0";
          }
          queueArg +=
              Ip->getName().str() + ":" +
              getTypeName(PT, symTab, mMFI, mMFI->isSignedIntType(Ip)) +
              ":1:1:" + itostr(mCBSize * 16) + ":" + MemType;
          mMFI->addMetadata(queueArg, true);
          ++mCBSize;
        } else {
          updatePtrArg(Ip, mCBSize, isKernel, F, pointerCount++);
          ++mCBSize;
        }
      } else if (CT->getTypeID() == Type::StructTyID &&
                 Ip->hasByValAttr()) { // To distinguish pass-by-value from
                                       // pass-by-ptr.
        // When struct is passed-by-value, the pointer to the struct copy
        // is passed to the kernel. Relevant RTI is generated here
        // (value...struct).
        // [Informative: RTI for pass-by-pointer case (pointer...struct) is
        // generated
        // in the next "else if" block.]
        const DataLayout *dl = mTM->getDataLayout();
        const StructLayout *sl = dl->getStructLayout(dyn_cast<StructType>(CT));
        int bytesize = sl->getSizeInBytes();
        int reservedsize = (bytesize + 15) & ~15;
        int numSlots = reservedsize >> 4;
        if (!numSlots) {
          numSlots = 1;
        }
        std::string structArg("value:");
        structArg += Ip->getName().str() + ":struct:" + itostr(bytesize) +
                     ":1:" + itostr(mCBSize * 16);
        mMFI->addMetadata(structArg, true);
        mCBSize += numSlots;
      } else if (CT->isIntOrIntVectorTy() || CT->isFPOrFPVectorTy() ||
                 CT->getTypeID() == Type::ArrayTyID ||
                 CT->getTypeID() == Type::PointerTyID ||
                 PT->getAddressSpace() != HSAILAS::PRIVATE_ADDRESS) {
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
    const Module *M = mMF->getMMI().getModule();
    bool isSPIR = HSAIL::isSPIRModule(*M);
    bool isConstArg = false;

    StringRef FuncName = F->getName();
    // No need update the kernel info for block kernels (child kernel).
    if (isSPIR && !FuncName.startswith("__OpenCL___amd_blocks_func_")) {
      if (NumArg >= HSAIL::KE_NUM_ARGS) {
        int typeQual = mAMI->getKernel(F->getName())
                           ->accessTypeQualifer[NumArg - HSAIL::KE_NUM_ARGS];
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

void HSAILKernelManager::printHeader(const std::string &name) {
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

void HSAILKernelManager::setID(uint32_t id) { mUniqueID = id; }

void HSAILKernelManager::setName(const std::string &name) { mName = name; }

class RTI {
  std::string m_str;
  HSAIL_ASM::Brigantine &m_brig;
  mutable raw_string_ostream m_os;

public:
  RTI(HSAIL_ASM::Brigantine &brig) : m_brig(brig), m_os(m_str) {}

  ~RTI() {
    HSAIL_ASM::DirectivePragma pragma =
        m_brig.append<HSAIL_ASM::DirectivePragma>();
    HSAIL_ASM::ItemList opnds;
    opnds.push_back(m_brig.createOperandString("AMD RTI"));
    const std::string &str = m_os.str();
    opnds.push_back(m_brig.createOperandString(str));
    pragma.operands() = opnds;
  }

  raw_string_ostream &os() const { return m_os; }
};

template <typename T> const RTI &operator<<(const RTI &os, const T &s) {
  os.os() << s;
  return os;
}
const RTI &operator<<(const RTI &os, const char *s) {
  os.os() << s;
  return os;
}

void HSAILKernelManager::brigEmitMetaData(HSAIL_ASM::Brigantine &brig,
                                          uint32_t id, bool isKernel) {

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
      HSAIL_ASM::DirectiveControl dc =
          brig.append<HSAIL_ASM::DirectiveControl>();
      dc.control() = BRIG_CONTROL_REQUIREDWORKGROUPSIZE;

      HSAIL_ASM::ItemList opnds;
      for (int i = 0; i < 3; ++i) {
        opnds.push_back(
            brig.createImmed(kernel->sgv->reqGroupSize[i], BRIG_TYPE_U32));
      }
      dc.operands() = opnds;
    }
  }

  if (isKernel) {
    std::string emptyStr("");
    std::string &refEmptyStr(emptyStr);
    raw_string_ostream oss(refEmptyStr);
    // function name
    RTI(brig) << "ARGSTART:" << mName;
    if (isKernel) {
      // version
      RTI(brig) << "version:"
                << itostr(mSTM->supportMetadata30() ? HSAIL_MAJOR_VERSION : 2)
                << ":" << itostr(HSAIL_MINOR_VERSION) + ":"
                << itostr(mSTM->supportMetadata30() ? HSAIL_REVISION_NUMBER
                                                    : HSAIL_20_REVISION_NUMBER);
      // device info
      RTI(brig) << "device:" << mSTM->getDeviceName();
    }
    RTI(brig) << "uniqueid:" << kernelId;
    if (kernel) {
      size_t hwlocal = ((kernel->curHWSize + 3) & (~0x3));
      size_t hwregion = ((kernel->curHWRSize + 3) & (~0x3));
      // private memory
      RTI(brig) << "memory:"
                << "hwprivate:"
                << (((mMFI->getStackSize() + mMFI->getPrivateSize() + 15) &
                     (~0xF)));
      // region memory
      RTI(brig) << "memory:"
                << "hwregion:" << hwregion;
      // local memory
      RTI(brig) << "memory:"
                << "hwlocal:" << hwlocal + mMFI->getGroupSize();
      if (kernel && isKernel && kernel->sgv) {
        if (kernel->sgv->mHasRWG) {
          RTI(brig) << "cws:" << kernel->sgv->reqGroupSize[0] << ":"
                    << kernel->sgv->reqGroupSize[1] << ":"
                    << kernel->sgv->reqGroupSize[2];
        }
        if (kernel->sgv->mHasRWR) {
          RTI(brig) << "crs:" << kernel->sgv->reqRegionSize[0] << ":"
                    << kernel->sgv->reqRegionSize[1] << ":"
                    << kernel->sgv->reqRegionSize[2];
        }
      }
    }
    if (isKernel) {
      for (std::vector<std::string>::iterator ib = mMFI->kernel_md_begin(),
                                              ie = mMFI->kernel_md_end();
           ib != ie; ++ib) {
        std::string md = *ib;
        if (md.find("argmap") == std::string::npos) {
          RTI(brig) << (*ib);
        }
      }
    }

    for (std::set<std::string>::iterator ib = mMFI->func_md_begin(),
                                         ie = mMFI->func_md_end();
         ib != ie; ++ib) {
      RTI(brig) << (*ib);
    }

    if (!mMFI->func_empty()) {
      oss.str().clear();
      oss << "function:" << mMFI->func_size();

      for (unsigned FID : mMFI->funcs())
        oss << ':' << FID;

      RTI(brig) << oss.str();
    }

    if (isKernel) {
      for (StringMap<SamplerInfo>::iterator smb = mMFI->sampler_begin(),
                                            sme = mMFI->sampler_end();
           smb != sme; ++smb) {
        RTI(brig) << "sampler:" << (*smb).second.name << ":"
                  << (*smb).second.idx << ":"
                  << ((*smb).second.val == (uint32_t)-1 ? 0 : 1) << ":"
                  << ((*smb).second.val != (uint32_t)-1 ? (*smb).second.val
                                                        : 0);
      }
    }
    if (mSTM->isLargeModel()) {
      RTI(brig) << "memory:64bitABI";
    }

    if (isKernel) {
      RTI(brig) << "privateid:" << DEFAULT_SCRATCH_ID;
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

  return DEFAULT_RAW_UAV_ID;
}
