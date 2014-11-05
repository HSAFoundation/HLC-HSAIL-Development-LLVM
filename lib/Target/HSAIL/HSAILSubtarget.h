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
#include "HSAILFrameLowering.h"
#include "HSAILInstrInfo.h"
#include "HSAILISelLowering.h"
#include "llvm/ADT/Triple.h"
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
class HSAILTargetMachine;
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
  Triple TargetTriple;
  std::string DevName;
  bool Is64Bit;
  const DataLayout DL;
  HSAILFrameLowering FrameLowering;
  std::unique_ptr<HSAILTargetLowering> TLInfo;
  std::unique_ptr<HSAILInstrInfo> InstrInfo;

  // FIXME: It makes no sense for this to be here.
  HSAILImageHandles *imageHandles;

  // FIXME: This should be merged to here
  const HSAILDevice *mDevice;

public:

  /// This constructor initializes the data members to match that
  /// of the specified triple.
  ///

  HSAILSubtarget(StringRef TT, StringRef CPU, StringRef FS,
                 HSAILTargetMachine &TM);
  HSAILSubtarget &initializeSubtargetDependencies(StringRef GPU, StringRef FS);

  const HSAILRegisterInfo *getRegisterInfo() const override {
    return &getInstrInfo()->getRegisterInfo();
  }

  const HSAILInstrInfo *getInstrInfo() const override {
    return InstrInfo.get();
  }

  const HSAILTargetLowering *getTargetLowering() const override {
    return TLInfo.get();
  }

  const HSAILFrameLowering *getFrameLowering() const override {
    return &FrameLowering;
  }

  void ParseSubtargetFeatures(StringRef CPU, StringRef FS);

  bool isOverride(HSAILDeviceInfo::Caps) const;
  bool is64Bit() const {
    return Is64Bit;
  }

  // FIXME: Remove this
  bool supportMetadata30() const {
    return true;
  }

  // FIXME: Remove this
  const HSAILDevice* device() const {
    return mDevice;
  }

  const DataLayout *getDataLayout() const override {
    return &DL;
  }

  StringRef getDeviceName() const {
    return DevName;
  }

  HSAILImageHandles *getImageHandles() const {
    return imageHandles;
  }
};

} // End llvm namespace

#endif
