//===------ HSAILSubtarget.cpp - Define Subtarget for the HSAIL -----------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the HSAIL specific subclass of TargetMachine.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "subtarget"
#include "HSAILSubtarget.h"
#include "HSAILFrameLowering.h"
#include "HSAILInstrInfo.h"
#include "HSAILDevice.h"

#define GET_SUBTARGETINFO_ENUM
#define GET_SUBTARGETINFO_TARGET_DESC
#define GET_SUBTARGETINFO_CTOR
#include "HSAILGenSubtargetInfo.inc"

#include "llvm/IR/GlobalValue.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/Host.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetOptions.h"
#include "llvm/ADT/SmallVector.h"
using namespace llvm;

static std::string computeDataLayout(const HSAILSubtarget &ST) {
  if (ST.is64Bit()) {
    return "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16"
           "-i32:32:32-i64:64:64-f32:32:32-f64:64:64-f80:32:32"
           "-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64"
           "-v96:128:128-v128:128:128-v192:256:256-v256:256:256"
           "-v512:512:512-v1024:1024:1024-v2048:2048:2048"
           "-n32:64";
  }

  return "e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16"
         "-i32:32:32-i64:64:64-f32:32:32-f64:64:64-f80:32:32"
         "-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64"
         "-v96:128:128-v128:128:128-v192:256:256-v256:256:256"
         "-v512:512:512-v1024:1024:1024-v2048:2048:2048"
         "-n32:64";
}

HSAILSubtarget::HSAILSubtarget(StringRef TT, StringRef CPU, StringRef FS,
                               HSAILTargetMachine &TM) :
  HSAILGenSubtargetInfo(TT, CPU, FS),
  TargetTriple(TT),
  DevName(CPU.empty() ? "generic" : CPU.str()),
  Is64Bit(TargetTriple.getArch() == Triple::hsail64),
  DL(computeDataLayout(initializeSubtargetDependencies(DevName, FS))),
  FrameLowering(TargetFrameLowering::StackGrowsUp, 16, 0),
  TLInfo(),
  InstrInfo(),
  imageHandles(new HSAILImageHandles()),
  mDevice(nullptr) {
  HSAILDevice::is64bit = Is64Bit; // FIXME
  mDevice = new HSAILDevice(this); // FIXME: Remove this

  // The constructor for TargetLoweringBase calls
  // HSAILSubtarget::getDataLayout(), so we need to initialize
  // HSAILTargetLowering after we have determined the device.
  InstrInfo.reset(new HSAILInstrInfo(*this));
  TLInfo.reset(new HSAILTargetLowering(TM));
}

HSAILSubtarget &HSAILSubtarget::initializeSubtargetDependencies(StringRef GPU,
                                                                StringRef FS) {
  ParseSubtargetFeatures(GPU, FS);
  return *this;
}

//
// Support for processing Image and Sampler kernel args and operands.
//
unsigned
HSAILImageHandles::findOrCreateImageHandle(const char* sym) {
  // Check for image arg with same value already present
  std::string symStr = sym;
  for (unsigned i = 0; i < HSAILImageArgs.size(); i++) {
    if (HSAILImageArgs[i] == symStr) {
      return i;
    }
  }
  HSAILImageArgs.push_back(symStr);
  return HSAILImageArgs.size() - 1;
}

unsigned
HSAILImageHandles::findOrCreateSamplerHandle(unsigned int u) {
  // Check for handle with same value already present
  for (unsigned i = 0; i < HSAILSamplers.size(); i++) {
    if (getSamplerValue(i) == u) {
      return i;
    }
  }
  HSAILSamplerHandle* handle = new HSAILSamplerHandle(u);
  HSAILSamplers.push_back(handle);
  return HSAILSamplers.size() - 1;
}

HSAILSamplerHandle*
HSAILImageHandles::getSamplerHandle(unsigned index) {
  assert(index < HSAILSamplers.size() && "Invalid sampler index");
  return HSAILSamplers[index];
}

std::string
HSAILImageHandles::getImageSymbol(unsigned index) {
  assert(index < HSAILImageArgs.size() && "Invalid image arg index");
  return HSAILImageArgs[index];
}

std::string HSAILImageHandles::getSamplerSymbol(unsigned index) {
  assert(index < HSAILSamplers.size() && "Invalid sampler index");
  return HSAILSamplers[index]->getSym();
}

unsigned
HSAILImageHandles::getSamplerValue(unsigned index) {
  assert(index < HSAILSamplers.size() && "Invalid sampler index");
  return HSAILSamplers[index]->getVal();
}

bool
HSAILImageHandles::isSamplerSym(std::string sym) {
  for (unsigned i = 0; i < HSAILSamplers.size(); i++) {
    if (getSamplerSymbol(i) == sym) {
      return true;
    }
  }
  return false;
}

void
HSAILImageHandles::finalize() {
  //printf("ImageHandles before finalize\n");
  //dump();
  char buf[16];
  for (unsigned i = 0; i < HSAILSamplers.size(); i++) {
    if (getSamplerSymbol(i).empty()) {
      sprintf(buf, "%s%u", "__Samp", index);
      HSAILSamplers[i]->setSym(buf);
      index++;
    }
  }
  //printf("ImageHandles after finalize\n");
  //dump();
}

void
HSAILImageHandles::clearImageArgs() {
  HSAILImageArgs.clear();
}

void
HSAILImageHandles::dump() {
  printf("Image args: ");
  for (unsigned i = 0; i < HSAILImageArgs.size(); i++) {
    printf("[%u] %s ", i, HSAILImageArgs[i].c_str());
  }
  printf("\n");
  printf("Samplers:\n");
  for (unsigned i = 0; i < HSAILSamplers.size(); i++) {
    printf("[%u] ", i);
    HSAILSamplers[i]->dump();
    printf("\n");
  }
  printf("\n");
}

