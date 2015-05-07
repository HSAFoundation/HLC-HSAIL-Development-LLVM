//=- HSAILRegisterInfo.h - HSAIL Register Information Impl --------*- C++ -*-=//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the HSAIL implementation of the TargetRegisterInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef _HSAIL_REGISTER_INFO_H_
#define _HSAIL_REGISTER_INFO_H_

#include "llvm/Target/TargetRegisterInfo.h"

#define GET_REGINFO_HEADER
#include "HSAILGenRegisterInfo.inc"

namespace llvm {
class Type;
class TargetInstrInfo;
class HSAILSubtarget;

/// DWARFFlavour - Flavour of dwarf regnumbers
///
namespace DWARFFlavour {
enum { HSAIL_Generic = 0 };
}

class HSAILRegisterInfo : public HSAILGenRegisterInfo {
private:
  HSAILSubtarget &ST;

  void lowerSpillB1(MachineBasicBlock::iterator II, int FrameIndex) const;
  void lowerRestoreB1(MachineBasicBlock::iterator II, int FrameIndex) const;

public:
  HSAILRegisterInfo(HSAILSubtarget &st);

  const uint16_t *
  getCalleeSavedRegs(const MachineFunction *MF = nullptr) const override;

  BitVector getRegsAvailable(const TargetRegisterClass *RC) const;

  BitVector getReservedRegs(const MachineFunction &MF) const override;

  bool trackLivenessAfterRegAlloc(const MachineFunction &MF) const override;

  bool requiresRegisterScavenging(const MachineFunction &MF) const override;

  bool requiresFrameIndexScavenging(const MachineFunction &MF) const override;

  bool saveScavengerRegister(MachineBasicBlock &MBB,
                             MachineBasicBlock::iterator I,
                             MachineBasicBlock::iterator &UseMI,
                             const TargetRegisterClass *RC,
                             unsigned Reg) const override;

  void eliminateFrameIndex(MachineBasicBlock::iterator MI, int SPAdj,
                           unsigned FIOperandNum,
                           RegScavenger *RS = nullptr) const override;

  unsigned getFrameRegister(const MachineFunction &MF) const override;

  unsigned getRegPressureLimit(const TargetRegisterClass *RC,
                               MachineFunction &MF) const override;

  const TargetRegisterClass *getPhysRegClass(unsigned Reg) const;
};

} // End llvm namespace

#endif // _HSAIL_REGISTER_INFO_H_
