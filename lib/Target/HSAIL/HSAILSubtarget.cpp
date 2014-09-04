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
#include "HSAILInstrInfo.h"
#include "HSAILDevice.h"

#define GET_SUBTARGETINFO_ENUM
#define GET_SUBTARGETINFO_CTOR
#define GET_SUBTARGETINFO_MC_DESC
#define GET_SUBTARGETINFO_TARGET_DESC
#include "HSAILGenSubtargetInfo.inc"

#include "llvm/IR/GlobalValue.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/Host.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetOptions.h"
#include "llvm/ADT/SmallVector.h"
using namespace llvm;

HSAILSubtarget::HSAILSubtarget(llvm::StringRef TT, llvm::StringRef CPU, llvm::StringRef FS,
    bool is64bitTarget)
  : HSAILGenSubtargetInfo( TT, CPU, FS ), TargetTriple(TT)
{
  memset(CapsOverride, 0, sizeof(*CapsOverride) * 
         HSAILDeviceInfo::MaxNumberCapabilities);
  mVersion = 0;
  mMetadata30 = true;
  mIs32on64bit = false;
  mDefaultSize[0] = 64;
  mDefaultSize[1] = 1;
  mDefaultSize[2] = 1;
  std::string GPU = CPU.str() == "" ? "generic" : CPU.str();
  mIs64bit = is64bitTarget;
  // Check for 32-bit target on 64-bit OS
  if (sizeof(void *) == 8)
    mIs32on64bit = !is64bitTarget;
  ParseSubtargetFeatures(GPU, FS);
  mDevName = GPU;
  mDevice = getDeviceFromName(GPU, this, mIs64bit);
  HSAILDeviceInfo::is64bit = mIs64bit;
  imageHandles = new HSAILImageHandles();
}

bool
HSAILSubtarget::isOverride(HSAILDeviceInfo::Caps caps) const
{
  assert(caps < HSAILDeviceInfo::MaxNumberCapabilities &&
      "Caps index is out of bounds!");
  return CapsOverride[caps];
}

bool
HSAILSubtarget::is64Bit() const 
{
  return mIs64bit;
}

bool
HSAILSubtarget::supportMetadata30() const
{
  return mMetadata30;
}

size_t
HSAILSubtarget::getDefaultSize(uint32_t dim) const
{
  if (dim >= 3) {
    return 1;
  } else {
    return mDefaultSize[dim];
  }

}

unsigned
HSAILSubtarget::getSpecialAddressLatency() const
{
  assert(!"When do we hit this?");
  return 0;
}
#if 0
bool
HSAILSubtarget::enablePostRAScheduler(CodeGenOpt::Level OptLevel,
                                      AntiDepBreakMode& Mode,
                                      RegClassVector& CriticalPathRCs) const
{
  assert(!"When do we hit this?");
  return false;
}
#endif
void
HSAILSubtarget::adjustSchedDependency(SUnit *def, SUnit *use, SDep& dep) const
{
  //assert(!"When do we hit this?");
}

std::string
HSAILSubtarget::getDeviceName() const
{
  return mDevName;
}

const HSAILDevice *
HSAILSubtarget::device() const
{
  return mDevice;
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
      sprintf(buf, "%s%u", "Samp", index);
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

