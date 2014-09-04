#include "HSAILDevices.h"
#include "HSAILSubtarget.h"
#include <string>
using namespace llvm;
namespace llvm {

HSAILDevice* getDeviceFromName(
  const std::string &deviceName, 
  HSAILSubtarget *ptr, 
  bool is64bit, 
  bool is64on32bit)
{
  if (deviceName == "generic") {
    if (is64bit) {
      return new HSAILGenericDevice(ptr);
    } else {
      return new HSAILGenericDevice(ptr);
    } 
  }
  else if (deviceName == "generic_flat") {
    if (is64bit) {
      return new HSAILGenericDeviceFlat(ptr);
    } else {
      return new HSAILGenericDeviceFlat(ptr);
    }
  }
  return 0x0;
}
namespace HSAILDeviceInfo{
  bool is64bit;
}
}

HSAILGenericDevice::HSAILGenericDevice(HSAILSubtarget *ST)
: HSAILDevice(ST) {
  setCaps();
  std::string name = ST->getDeviceName();
  mDeviceFlag = OCL_DEVICE_ALL;
}

HSAILGenericDevice::~HSAILGenericDevice() {
}

size_t HSAILGenericDevice::getMaxLDSSize() const {
  if (usesHardware(HSAILDeviceInfo::LocalMem)) {
    return MAX_LDS_SIZE_800;
  } else {
    return 0;
  }
}
size_t HSAILGenericDevice::getMaxGDSSize() const {
  if (usesHardware(HSAILDeviceInfo::RegionMem)) {
    return MAX_LDS_SIZE_800;
  } else {
    return 0;
  }
}
uint32_t HSAILGenericDevice::getMaxNumUAVs() const {
  return 12;
}

uint32_t HSAILGenericDevice::getResourceID(uint32_t id) const {
  switch(id) {
  default:
    assert(0 && "ID type passed in is unknown!");
    break;
  case CONSTANT_ID:
  case RAW_UAV_ID:
    return DEFAULT_RAW_UAV_ID;
  case GLOBAL_ID:
  case ARENA_UAV_ID:
    return DEFAULT_ARENA_UAV_ID;
  case LDS_ID:
    if (usesHardware(HSAILDeviceInfo::LocalMem)) {
      return DEFAULT_LDS_ID;
    } else {
      return DEFAULT_ARENA_UAV_ID;
    }
  case GDS_ID:
    if (usesHardware(HSAILDeviceInfo::RegionMem)) {
      return DEFAULT_GDS_ID;
    } else {
      return DEFAULT_ARENA_UAV_ID;
    }
  case SCRATCH_ID:
    if (usesHardware(HSAILDeviceInfo::PrivateMem)) {
      return DEFAULT_SCRATCH_ID;
    } else {
      return DEFAULT_ARENA_UAV_ID;
    }
  };
  return 0;
}

size_t HSAILGenericDevice::getWavefrontSize() const {
  return HSAILDevice::WavefrontSize;
}

uint32_t HSAILGenericDevice::getGeneration() const {
  return HSAILDeviceInfo::HD5XXX;
}

void HSAILGenericDevice::setCaps() {
  mSWBits.set(HSAILDeviceInfo::ArenaSegment);
  mHWBits.set(HSAILDeviceInfo::ArenaUAV);
  mHWBits.set(HSAILDeviceInfo::Semaphore);
  mSWBits.set(HSAILDeviceInfo::Signed24BitOps);
  if (mSTM->isOverride(HSAILDeviceInfo::ByteStores)) {
    mHWBits.set(HSAILDeviceInfo::ByteStores);
  }
  if (mSTM->isOverride(HSAILDeviceInfo::Debug)) {
    mSWBits.set(HSAILDeviceInfo::LocalMem);
    mSWBits.set(HSAILDeviceInfo::RegionMem);
  } else {
    mHWBits.set(HSAILDeviceInfo::LocalMem);
    mHWBits.set(HSAILDeviceInfo::RegionMem);
  }
  mHWBits.set(HSAILDeviceInfo::Images);
  if (mSTM->isOverride(HSAILDeviceInfo::MultiUAV)) {
    mHWBits.set(HSAILDeviceInfo::MultiUAV);
  }
  mSWBits.set(HSAILDeviceInfo::ArenaVectors);
  mHWBits.set(HSAILDeviceInfo::TmrReg);
}
FunctionPass* 
HSAILGenericDevice::getIOExpansion(
    TargetMachine& TM, CodeGenOpt::Level OptLevel) const
{
  // return new HSAILEGIOExpansion(TM, OptLevel);
  return 0x0;
}

AsmPrinter*
HSAILGenericDevice::getAsmPrinter(HSAIL_ASM_PRINTER_ARGUMENTS) const
{
  // return new HSAILEGAsmPrinter(ASM_PRINTER_ARGUMENTS);
  return 0x0;
}

FunctionPass*
HSAILGenericDevice::getPointerManager(
    TargetMachine& TM, CodeGenOpt::Level OptLevel) const
{
  // return new HSAILEGPointerManager(TM, OptLevel);
  return 0x0;
}

// HSA_TODO: get real flat addressing device name
// generic_flat device
HSAILGenericDeviceFlat::HSAILGenericDeviceFlat(HSAILSubtarget *ST)
: HSAILDevice(ST) {
  setCaps();
  std::string name = ST->getDeviceName();
  mDeviceFlag = OCL_DEVICE_ALL;
}

HSAILGenericDeviceFlat::~HSAILGenericDeviceFlat() {
}

size_t HSAILGenericDeviceFlat::getMaxLDSSize() const {
  if (usesHardware(HSAILDeviceInfo::LocalMem)) {
    return MAX_LDS_SIZE_800;
  } else {
    return 0;
  }
}
size_t HSAILGenericDeviceFlat::getMaxGDSSize() const {
  if (usesHardware(HSAILDeviceInfo::RegionMem)) {
    return MAX_LDS_SIZE_800;
  } else {
    return 0;
  }
}
uint32_t HSAILGenericDeviceFlat::getMaxNumUAVs() const {
  return 12;
}

uint32_t HSAILGenericDeviceFlat::getResourceID(uint32_t id) const {
  switch(id) {
  default:
    assert(0 && "ID type passed in is unknown!");
    break;
  case CONSTANT_ID:
  case RAW_UAV_ID:
    return DEFAULT_RAW_UAV_ID;
  case GLOBAL_ID:
  case ARENA_UAV_ID:
    return DEFAULT_ARENA_UAV_ID;
  case LDS_ID:
    if (usesHardware(HSAILDeviceInfo::LocalMem)) {
      return DEFAULT_LDS_ID;
    } else {
      return DEFAULT_ARENA_UAV_ID;
    }
  case GDS_ID:
    if (usesHardware(HSAILDeviceInfo::RegionMem)) {
      return DEFAULT_GDS_ID;
    } else {
      return DEFAULT_ARENA_UAV_ID;
    }
  case SCRATCH_ID:
    if (usesHardware(HSAILDeviceInfo::PrivateMem)) {
      return DEFAULT_SCRATCH_ID;
    } else {
      return DEFAULT_ARENA_UAV_ID;
    }
  };
  return 0;
}

size_t HSAILGenericDeviceFlat::getWavefrontSize() const {
  return HSAILDevice::WavefrontSize;
}

uint32_t HSAILGenericDeviceFlat::getGeneration() const {
  // CI
  return HSAILDeviceInfo::HD8XXX;
}

void HSAILGenericDeviceFlat::setCaps() {
  mSWBits.set(HSAILDeviceInfo::ArenaSegment);
  mHWBits.set(HSAILDeviceInfo::ArenaUAV);
  mHWBits.set(HSAILDeviceInfo::Semaphore);
  mSWBits.set(HSAILDeviceInfo::Signed24BitOps);
  if (mSTM->isOverride(HSAILDeviceInfo::ByteStores)) {
    mHWBits.set(HSAILDeviceInfo::ByteStores);
  }
  if (mSTM->isOverride(HSAILDeviceInfo::Debug)) {
    mSWBits.set(HSAILDeviceInfo::LocalMem);
    mSWBits.set(HSAILDeviceInfo::RegionMem);
  } else {
    mHWBits.set(HSAILDeviceInfo::LocalMem);
    mHWBits.set(HSAILDeviceInfo::RegionMem);
  }
  mHWBits.set(HSAILDeviceInfo::Images);
  if (mSTM->isOverride(HSAILDeviceInfo::MultiUAV)) {
    mHWBits.set(HSAILDeviceInfo::MultiUAV);
  }
  mSWBits.set(HSAILDeviceInfo::ArenaVectors);
  mHWBits.set(HSAILDeviceInfo::TmrReg);
}
FunctionPass*
HSAILGenericDeviceFlat::getIOExpansion(
    TargetMachine& TM, CodeGenOpt::Level OptLevel) const
{
  // return new HSAILEGIOExpansion(TM, OptLevel);
  return 0x0;
}

AsmPrinter*
HSAILGenericDeviceFlat::getAsmPrinter(HSAIL_ASM_PRINTER_ARGUMENTS) const
{
  // return new HSAILEGAsmPrinter(ASM_PRINTER_ARGUMENTS);
  return 0x0;
}

FunctionPass*
HSAILGenericDeviceFlat::getPointerManager(
    TargetMachine& TM, CodeGenOpt::Level OptLevel) const
{
  // return new HSAILEGPointerManager(TM, OptLevel);
  return 0x0;
}
