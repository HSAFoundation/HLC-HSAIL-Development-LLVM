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

#include "HSAILSubtarget.h"

#include "llvm/IR/DataLayout.h"
#include "llvm/Support/Debug.h"

#define DEBUG_TYPE "subtarget"

#define GET_SUBTARGETINFO_CTOR
#define GET_SUBTARGETINFO_TARGET_DESC
#include "HSAILGenSubtargetInfo.inc"

using namespace llvm;

HSAILSubtarget::HSAILSubtarget(const Triple &TT, StringRef CPU, StringRef FS,
                               HSAILTargetMachine &TM)
    : HSAILGenSubtargetInfo(TT, CPU, FS), TargetTriple(TT),
      DevName(CPU.empty() ? "generic" : CPU.str()),
      IsLargeModel(TargetTriple.getArch() == Triple::hsail64),
      HasImages(false),
      IsGCN(false),
      FrameLowering(TargetFrameLowering::StackGrowsUp, 16, 0), TLInfo(),
      InstrInfo(), imageHandles(new HSAILImageHandles()) {
  initializeSubtargetDependencies(CPU, FS);

  InstrInfo.reset(new HSAILInstrInfo(*this));
  TLInfo.reset(new HSAILTargetLowering(TM, *this));
}

HSAILSubtarget &HSAILSubtarget::initializeSubtargetDependencies(StringRef GPU,
                                                                StringRef FS) {
  ParseSubtargetFeatures(GPU, FS);
  return *this;
}

//
// Support for processing Image and Sampler kernel args and operands.
//
unsigned HSAILImageHandles::findOrCreateImageHandle(const char *sym) {
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

unsigned HSAILImageHandles::findOrCreateSamplerHandle(unsigned int u) {
  // Check for handle with same value already present
  for (unsigned i = 0; i < HSAILSamplers.size(); i++) {
    if (getSamplerValue(i) == u) {
      return i;
    }
  }
  HSAILSamplerHandle *handle = new HSAILSamplerHandle(u);
  HSAILSamplers.push_back(handle);
  return HSAILSamplers.size() - 1;
}

HSAILSamplerHandle *HSAILImageHandles::getSamplerHandle(unsigned index) {
  assert(index < HSAILSamplers.size() && "Invalid sampler index");
  return HSAILSamplers[index];
}

std::string HSAILImageHandles::getImageSymbol(unsigned index) {
  assert(index < HSAILImageArgs.size() && "Invalid image arg index");
  return HSAILImageArgs[index];
}

std::string HSAILImageHandles::getSamplerSymbol(unsigned index) {
  assert(index < HSAILSamplers.size() && "Invalid sampler index");
  return HSAILSamplers[index]->getSym();
}

unsigned HSAILImageHandles::getSamplerValue(unsigned index) {
  assert(index < HSAILSamplers.size() && "Invalid sampler index");
  return HSAILSamplers[index]->getVal();
}

bool HSAILImageHandles::isSamplerSym(std::string sym) {
  for (unsigned i = 0; i < HSAILSamplers.size(); i++) {
    if (getSamplerSymbol(i) == sym) {
      return true;
    }
  }
  return false;
}

void HSAILImageHandles::finalize() {
  // printf("ImageHandles before finalize\n");
  // dump();
  char buf[16];
  for (unsigned i = 0; i < HSAILSamplers.size(); i++) {
    if (getSamplerSymbol(i).empty()) {
      sprintf(buf, "%s%u", "__Samp", index);
      HSAILSamplers[i]->setSym(buf);
      index++;
    }
  }
}

void HSAILImageHandles::clearImageArgs() { HSAILImageArgs.clear(); }
