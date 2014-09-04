//===---- HSAILSubtarget.h - Define Subtarget for the HSAIL -----*- C++ -*--==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file declares the HSAIL specific subclass of TargetSubtarget.
//
//===----------------------------------------------------------------------===//

#ifndef _HSAIL_SUBTARGET_H_
#define _HSAIL_SUBTARGET_H_

#include "HSAIL.h"
#include "HSAILDevice.h"
#include "llvm/ADT/Triple.h"
//#include "llvm/Target/TargetSubtarget.h"
#include "llvm/Target/TargetSubtargetInfo.h"
#include "llvm/IR/CallingConv.h"
#include "llvm/IR/DataLayout.h"
#define GET_SUBTARGETINFO_HEADER
#include "HSAILGenSubtargetInfo.inc"

#include <string>
#include <cstdio>
#include "llvm/ADT/SmallVector.h"
#define MAX_CB_SIZE (1 << 16)

namespace llvm {
class GlobalValue;
class TargetMachine;

/// PICStyles - The X86 backend supports a number of different styles of PIC.
namespace PICStyles {
  enum Style {
    None              // Set when in -static mode (not PIC or DynamicNoPIC mode).
  };
}

class HSAILSamplerHandle {
private:
  std::string   mSym;
  unsigned int  mVal;
  //bool          mGlobal;
  bool          mIsRO;
  bool          mEmitted;

public:
  HSAILSamplerHandle(HSAILSamplerHandle &copy) {
    mSym = copy.mSym;
    mVal = copy.mVal;
    //mGlobal = copy.mGlobal;
    mIsRO = copy.mIsRO;
    mEmitted = copy.mEmitted;
  }

  HSAILSamplerHandle(/*bool isImage, */const char* sym) {
    mSym = sym;
    mVal = 0;
    //mGlobal = false;
    mIsRO = false;
    mEmitted = false;
  }

  HSAILSamplerHandle(/*bool isImage, */unsigned int u) {
    mVal = u;
    //mGlobal = false;
    mIsRO = false;
    mEmitted = false;
}

  inline void setSym(std::string str) { mSym = str; }
  inline std::string getSym() { return mSym; }
  inline unsigned int getVal() { return mVal; }
  //inline bool isGlobal()  { return mGlobal; }
  //inline void setGlobal() { mGlobal = true; }
  inline bool isRO() { return mIsRO; }
  inline void setRO() { mIsRO = true; }
  inline bool isEmitted() { return mEmitted; }
  inline void setEmitted() { mEmitted = true; }

  inline void dump() { 
    //printf("mSym: %s, mVal: %d, mGlobal: %d, mEmitted: %d", 
      //mSym.c_str(), mVal, mGlobal, mEmitted); 
    printf("mSym: %s, mVal: %u, RO: %d, mEmitted: %d",
           mSym.c_str(), mVal, mIsRO, mEmitted);
  }
};

class HSAILImageHandles {
private:
  // Image and sampler kernel args
  SmallVector<std::string, 16> HSAILImageArgs;

  // Sampler initializers
  SmallVector<HSAILSamplerHandle*, 16> HSAILSamplers;
  unsigned index;
public:
  HSAILImageHandles() {index = 0;}
  // TODO_HSA Add a destructor
  
  SmallVector<HSAILSamplerHandle*, 16> getSamplerHandles() { return HSAILSamplers; }
  HSAILSamplerHandle* getSamplerHandle(unsigned index);

  unsigned findOrCreateImageHandle(const char* sym);
  unsigned findOrCreateSamplerHandle(unsigned int u);

  std::string getImageSymbol(unsigned index);
  std::string getSamplerSymbol(unsigned index);
  unsigned getSamplerValue(unsigned index);

  bool isSamplerSym(std::string sym);

  void finalize();
  void clearImageArgs();

  void dump();
};

class HSAILKernelManager;
class HSAILDevice;

class HSAILSubtarget : public HSAILGenSubtargetInfo {
protected:
  enum HSAILXXXEnum {
    XXX,
    None
  };

  bool CapsOverride[HSAILDeviceInfo::MaxNumberCapabilities];
  mutable HSAILKernelManager *mKM;
  const HSAILDevice *mDevice;
  size_t mDefaultSize[3];
  size_t mMinimumSize[3];
  std::string mDevName;
  uint32_t mVersion;
  bool mIs64bit;
  bool mIs32on64bit;
  bool mMetadata30;
  /// HSAILXXXLevel - none supported.
  HSAILXXXEnum HSAILXXXLevel;

  // stackAlignment - The minimum alignment known to hold of the stack frame on
  /// entry to the function and which must be maintained by every function.
  unsigned stackAlignment;

  /// TargetTriple - What processor and OS we're targeting.
  Triple TargetTriple;

  HSAILImageHandles* imageHandles;

public:

  /// This constructor initializes the data members to match that
  /// of the specified triple.
  ///

  HSAILSubtarget(llvm::StringRef TT, llvm::StringRef CPU, llvm::StringRef FS,
      bool is64bitTarget);

  /// getSpecialAddressLatency - For targets where it is beneficial to
  /// backschedule instructions that compute addresses, return a value
  /// indicating the number of scheduling cycles of backscheduling that
  /// should be attempted.
  virtual unsigned
  getSpecialAddressLatency() const;
#if 0
  // enablePostRAScheduler - If the target can benefit from post-regalloc
  // scheduling and the specified optimization level meets the requirement
  // return true to enable post-register-allocation scheduling. In
  // CriticalPathRCs return any register classes that should only be broken
  // if on the critical path.
  virtual bool
  enablePostRAScheduler(CodeGenOpt::Level OptLevel,
                        AntiDepBreakMode& Mode,
                        RegClassVector& CriticalPathRCs) const;
#endif
  // adjustSchedDependency - Perform target specific adjustments to
  // the latency of a schedule dependency.
  virtual void
  adjustSchedDependency(SUnit *def,
                        SUnit *use,
                        SDep& dep) const;

  /// getStackAlignment - Returns the minimum alignment known to hold of the
  /// stack frame on entry to the function and which must be maintained by every
  /// function for this subtarget.
  unsigned getStackAlignment() const { return stackAlignment; }
  bool isOverride(HSAILDeviceInfo::Caps) const;
  bool is64Bit() const;
  bool supportMetadata30() const;
  const HSAILDevice* device() const;
  const DataLayout *getDataLayout() const override { return new DataLayout(mDevice->getDataLayout()); }
  std::string getDeviceName() const;
  virtual size_t getDefaultSize(uint32_t dim) const;

   /// ParseSubtargetFeatures - Parses features string setting specified
  /// subtarget options.  Definition of function is auto generated by tblgen.
 
  // std::string ParseSubtargetFeatures(const std::string &FS,
  //                                 const std::string &CPU);

  void ParseSubtargetFeatures( llvm::StringRef CPU,
            llvm::StringRef FS);

  // Address space mappings are defined in HSAIL.h
  unsigned getFlatAS() const { return HSAILAS::FLAT_ADDRESS; }
  unsigned getGlobalAS() const { return HSAILAS::GLOBAL_ADDRESS; }
  unsigned getConstantAS() const { return HSAILAS::CONSTANT_ADDRESS; }
  unsigned getGroupAS() const { return HSAILAS::GROUP_ADDRESS; }
  unsigned getPrivateAS() const { return HSAILAS::PRIVATE_ADDRESS; }
  unsigned getSpillAS() const { return HSAILAS::SPILL_ADDRESS; }
  unsigned getRegionAS() const { return HSAILAS::REGION_ADDRESS; }
  unsigned getKernargAS() const { return HSAILAS::KERNARG_ADDRESS; }
  unsigned getArgAS() const { return HSAILAS::ARG_ADDRESS; }

  HSAILImageHandles* getImageHandles() const { return imageHandles; }

};

} // End llvm namespace

#endif
