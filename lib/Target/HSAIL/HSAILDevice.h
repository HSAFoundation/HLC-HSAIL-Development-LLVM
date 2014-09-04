//===---- HSAILDevice.h - Define Device Data for HSAIL -----*- C++ -*------===//
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
//
// Interface for the subtarget data classes.
//
//===----------------------------------------------------------------------===//
// This file will define the interface that each generation needs to
// implement in order to correctly answer queries on the capabilities of the
// specific hardware.
//===----------------------------------------------------------------------===//
#ifndef _HSAILDEVICEIMPL_H_
#define _HSAILDEVICEIMPL_H_
#include "HSAIL.h"
#include "HSAILDeviceInfo.h"
#include "HSAILLLVMVersion.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/ADT/BitVector.h"
namespace llvm {
  class HSAILSubtarget;
  class HSAILIOExpansion;
  class HSAILPointerManager;
//===----------------------------------------------------------------------===//
// Interface for data that is specific to a single device
//===----------------------------------------------------------------------===//
class HSAILDevice {
public:
  HSAILDevice(HSAILSubtarget *ST);
  virtual ~HSAILDevice();

  // Enum values for the various memory types.
  enum {
    RAW_UAV_ID   = 0,
    ARENA_UAV_ID = 1,
    LDS_ID       = 2,
    GDS_ID       = 3,
    SCRATCH_ID   = 4,
    CONSTANT_ID  = 5,
    GLOBAL_ID    = 6,
    MAX_IDS      = 7
  } IO_TYPE_IDS;

  // Returns the max LDS size that the hardware supports.  Size is in
  // bytes.
  virtual size_t getMaxLDSSize() const = 0;

  // Returns the max GDS size that the hardware supports if the GDS is
  // supported by the hardware.  Size is in bytes.
  virtual size_t getMaxGDSSize() const;

  // Returns the max number of hardware constant address spaces that
  // are supported by this device.
  virtual size_t getMaxNumCBs() const;

  // Returns the max number of bytes a single hardware constant buffer
  // can support.  Size is in bytes.
  virtual size_t getMaxCBSize() const;

  // Returns the max number of bytes allowed by the hardware scratch
  // buffer.  Size is in bytes.
  virtual size_t getMaxScratchSize() const;

  // Get the flag that corresponds to the device.
  virtual uint32_t getDeviceFlag() const;

  // Returns the number of work-items that exist in a single hardware
  // wavefront.
  virtual size_t getWavefrontSize() const = 0;

  // Get the generational name of this specific device.
  virtual uint32_t getGeneration() const = 0;

  // Get the stack alignment of this specific device.
  virtual uint32_t getStackAlignment() const;

  // Get the resource ID for this specific device.
  virtual uint32_t getResourceID(uint32_t DeviceID) const = 0;

  // Get the max number of UAV's for this device.
  virtual uint32_t getMaxNumUAVs() const = 0;

  // Interface to get the IO Expansion pass for each device.
  virtual FunctionPass*  getIOExpansion(
    TargetMachine&, CodeGenOpt::Level) const = 0;

  // Interface to get the Asm printer for each device.
  virtual AsmPrinter* getAsmPrinter(HSAIL_ASM_PRINTER_ARGUMENTS) const = 0;

  // Interface to get the Pointer manager pass for each device.
  virtual FunctionPass*  getPointerManager(
    TargetMachine&, CodeGenOpt::Level) const = 0;

  // API utilizing more detailed capabilities of each family of
  // cards. If a capability is supported, then either usesHardware or
  // usesSoftware returned true.  If usesHardware returned true, then
  // usesSoftware must return false for the same capability.  Hardware
  // execution means that the feature is done natively by the hardware
  // and is not emulated by the softare.  Software execution means
  // that the feature could be done in the hardware, but there is
  // software that emulates it with possibly using the hardware for
  // support since the hardware does not fully comply with OpenCL
  // specs.
  bool isSupported(HSAILDeviceInfo::Caps Mode) const;
  bool usesHardware(HSAILDeviceInfo::Caps Mode) const;
  bool usesSoftware(HSAILDeviceInfo::Caps Mode) const;
  virtual std::string getDataLayout() const;
  static const unsigned int MAX_LDS_SIZE_700 = 16384;
  static const unsigned int MAX_LDS_SIZE_800 = 32768;
  static const unsigned int WavefrontSize = 64;
  static const unsigned int HalfWavefrontSize = 32;
  static const unsigned int QuarterWavefrontSize = 16;
protected:
  virtual void setCaps();
  llvm::BitVector mHWBits;
  llvm::BitVector mSWBits;
  HSAILSubtarget *mSTM;
  uint32_t mDeviceFlag;
private:
  HSAILDeviceInfo::ExecutionMode getExecutionMode(
    HSAILDeviceInfo::Caps Caps) const;
}; // HSAILDevice

} // namespace llvm
#endif // _HSAILDEVICEIMPL_H_
