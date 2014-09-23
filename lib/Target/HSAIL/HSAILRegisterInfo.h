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
//#include "HSAILGenRegisterInfo.h.inc"
#define GET_REGINFO_HEADER
#include "HSAILGenRegisterInfo.inc"

namespace llvm {
  class Type;
  class TargetInstrInfo;
  class HSAILSubtarget;

  /// DWARFFlavour - Flavour of dwarf regnumbers
  ///
  namespace DWARFFlavour {
    enum {
      HSAIL_Generic = 0
    };
  }

class HSAILRegisterInfo : public HSAILGenRegisterInfo {
private:
  HSAILSubtarget &ST;

public:
  HSAILRegisterInfo(HSAILSubtarget &st);

  /// getCalleeSavedRegs - Return a null-terminated list of all of the
  /// callee saved registers on this target. The register should be in the
  /// order of desired callee-save stack frame offset. The first register is
  /// closed to the incoming stack pointer if stack grows down, and vice versa.
  virtual const uint16_t *
  getCalleeSavedRegs(const MachineFunction *MF = 0) const;

  /// getRegsAvailable - Return all available registers in the register class
  /// in Mask.
  BitVector
  getRegsAvailable(const TargetRegisterClass *RC) const;

  /// getReservedRegs - Returns a bitset indexed by physical register number
  /// indicating if a register is a special register that has particular uses
  /// and should be considered unavailable at all times, e.g. SP, RA. This is
  /// used by register scavenger to determine what registers are free.
  BitVector getReservedRegs(const MachineFunction &MF) const override;

  /// getPointerRegClass - Returns a TargetRegisterClass used for pointer
  /// values.  If a target supports multiple different pointer register classes,
  /// kind specifies which one is indicated.
  const TargetRegisterClass *getPointerRegClass(const MachineFunction &MF,
                                                unsigned Kind = 0) const override;

  /// Code Generation virtual methods...
  ///
  bool trackLivenessAfterRegAlloc(const MachineFunction &MF) const override;

  /// requiresRegisterScavenging - returns true if the target requires (and can
  /// make use of) the register scavenger.
  bool requiresRegisterScavenging(const MachineFunction &MF) const override;

  /// requiresFrameIndexScavenging - returns true if the target requires post
  /// PEI scavenging of registers for materializing frame index constants.
  bool requiresFrameIndexScavenging(const MachineFunction &MF) const override;

  /// eliminateCallFramePseudoInstr - This method is called during prolog/epilog
  /// code insertion to eliminate call frame setup and destroy pseudo
  /// instructions (but only if the Target is using them).  It is responsible
  /// for eliminating these instructions, replacing them with concrete
  /// instructions.  This method need only be implemented if using call frame
  /// setup/destroy pseudo instructions.
  virtual void
  eliminateCallFramePseudoInstr(MachineFunction &MF,
                                MachineBasicBlock &MBB,
                                MachineBasicBlock::iterator MI) const;

  /// saveScavengerRegister - Spill the register so it can be used by the
  /// register scavenger. Return true if the register was spilled, false
  /// otherwise. If this function does not spill the register, the scavenger
  /// will instead spill it to the emergency spill slot.
  virtual bool
  saveScavengerRegister(MachineBasicBlock &MBB,
                        MachineBasicBlock::iterator I,
                        MachineBasicBlock::iterator &UseMI,
                        const TargetRegisterClass *RC,
                        unsigned Reg) const;

  // Save scavenger register and provide a frame index for it.
  bool
  saveScavengerRegisterToFI(MachineBasicBlock &MBB,
                        MachineBasicBlock::iterator I,
                        MachineBasicBlock::iterator &UseMI,
                        const TargetRegisterClass *RC,
                        unsigned Reg, int FI) const;

  /// eliminateFrameIndex - This method must be overriden to eliminate abstract
  /// frame indices from instructions which may use them.  The instruction
  /// referenced by the iterator contains an MO_FrameIndex operand which must be
  /// eliminated by this method.  This method may modify or replace the
  /// specified instruction, as long as it keeps the iterator pointing at the
  /// finished product. SPAdj is the SP adjustment due to call frame setup
  /// instruction.
  virtual void
  eliminateFrameIndex(MachineBasicBlock::iterator MI,
                      int SPAdj, unsigned FIOperandNum,
                      RegScavenger *RS=NULL) const;

  //===--------------------------------------------------------------------===//
  /// Debug information queries.
  /*
  /// getDwarfRegNum - Map a target register to an equivalent dwarf register
  /// number.  Returns -1 if there is no equivalent value.  The second
  /// parameter allows targets to use different numberings for EH info and
  /// debugging info.
  virtual int
  getDwarfRegNum(unsigned RegNum, bool isEH) const;
  */

  /// getFrameRegister - This method should return the register used as a base
  /// for values allocated in the current stack frame.
  virtual unsigned
  getFrameRegister(const MachineFunction &MF) const;

  /// getRARegister - This method should return the register where the return
  /// address can be found.
  virtual unsigned
  getRARegister() const;

  /// getRegPressureLimit - Return the register pressure "high water mark" for
  /// the specific register class. The scheduler is in high register pressure
  /// mode (for the specific register class) if it goes over the limit.
  virtual unsigned
  getRegPressureLimit(const TargetRegisterClass *RC,
                      MachineFunction &MF) const;
};

} // End llvm namespace

#endif // _HSAIL_REGISTER_INFO_H_
