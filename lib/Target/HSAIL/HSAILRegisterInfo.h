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
  class HSAILTargetMachine;

  /// DWARFFlavour - Flavour of dwarf regnumbers
  ///
  namespace DWARFFlavour {
    enum {
      HSAIL_Generic = 0
    };
  }

class HSAILRegisterInfo : public HSAILGenRegisterInfo {
public:
  HSAILTargetMachine &TM;
  const TargetInstrInfo &TII;

private:
  /// Is64Bit - Is the target 64-bits.
  bool Is64Bit;

public:
  HSAILRegisterInfo(HSAILTargetMachine &tm, const TargetInstrInfo &tii);

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
  virtual BitVector
  getReservedRegs(const MachineFunction &MF) const;

  /// getSubReg - Returns the physical register number of sub-register "Index"
  /// for physical register RegNo. Return zero if the sub-register does not
  /// exist.
  virtual unsigned
  getSubReg(unsigned RegNo, unsigned Index) const;

  /// getSubRegIndex - For a given register pair, return the sub-register index
  /// if the second register is a sub-register of the first. Return zero
  /// otherwise.
  virtual unsigned
  getSubRegIndex(unsigned RegNo, unsigned SubRegNo) const;

  /// canCombineSubRegIndices - Given a register class and a list of
  /// subregister indices, return true if it's possible to combine the
  /// subregister indices into one that corresponds to a larger
  /// subregister. Return the new subregister index by reference. Note the
  /// new index may be zero if the given subregisters can be combined to
  /// form the whole register.
  virtual bool
  canCombineSubRegIndices(const TargetRegisterClass *RC,
                          SmallVectorImpl<unsigned> &SubIndices,
                          unsigned &NewSubIdx) const;

  /// getMatchingSuperRegClass - Return a subclass of the specified register
  /// class A so that each register in it has a sub-register of the
  /// specified sub-register index which is in the specified register class B.
  virtual const TargetRegisterClass*
  getMatchingSuperRegClass(const TargetRegisterClass *A,
                           const TargetRegisterClass *B,
                           unsigned Idx) const;

  /// composeSubRegIndices - Return the subregister index you get from composing
  /// two subregister indices.
  ///
  /// If R:a:b is the same register as R:c, then composeSubRegIndices(a, b)
  /// returns c. Note that composeSubRegIndices does not tell you about illegal
  /// compositions. If R does not have a subreg a, or R:a does not have a subreg
  /// b, composeSubRegIndices doesn't tell you.
  ///
  /// The ARM register Q0 has two D subregs dsub_0:D0 and dsub_1:D1. It also has
  /// ssub_0:S0 - ssub_3:S3 subregs.
  /// If you compose subreg indices dsub_1, ssub_0 you get ssub_2.
  ///
  virtual unsigned
  composeSubRegIndices(unsigned a, unsigned b) const;

  /// getPointerRegClass - Returns a TargetRegisterClass used for pointer
  /// values.  If a target supports multiple different pointer register classes,
  /// kind specifies which one is indicated.
  virtual const TargetRegisterClass*
  getPointerRegClass(const MachineFunction &MF, unsigned Kind=0) const;

  /// getCrossCopyRegClass - Returns a legal register class to copy a register
  /// in the specified class to or from. Returns NULL if it is possible to copy
  /// between a two registers of the specified class.
  virtual const TargetRegisterClass*
  getCrossCopyRegClass(const TargetRegisterClass *RC) const;

  /// Code Generation virtual methods...
  ///
  virtual bool trackLivenessAfterRegAlloc(const MachineFunction &MF) const;

#if 0
  /// getAllocationOrder - Returns the register allocation order for a specified
  /// register class in the form of a pair of TargetRegisterClass iterators.
  virtual std::pair<TargetRegisterClass::iterator,TargetRegisterClass::iterator>
  getAllocationOrder(const TargetRegisterClass *RC,
                     unsigned HintType,
                     unsigned HintReg,
                     const MachineFunction &MF) const;
#endif
  /// ResolveRegAllocHint - Resolves the specified register allocation hint
  /// to a physical register. Returns the physical register if it is successful.
  virtual unsigned
  ResolveRegAllocHint(unsigned Type,
                      unsigned Reg,
                      const MachineFunction &MF) const;

  /// UpdateRegAllocHint - A callback to allow target a chance to update
  /// register allocation hints when a register is "changed" (e.g. coalesced)
  /// to another register. e.g. On ARM, some virtual registers should target
  /// register pairs, if one of pair is coalesced to another register, the
  /// allocation hint of the other half of the pair should be changed to point
  /// to the new register.
  virtual void
  UpdateRegAllocHint(unsigned Reg,
                     unsigned NewReg,
                     MachineFunction &MF) const;

  /// requiresRegisterScavenging - returns true if the target requires (and can
  /// make use of) the register scavenger.
  virtual bool
  requiresRegisterScavenging(const MachineFunction &MF) const;

  /// requiresFrameIndexScavenging - returns true if the target requires post
  /// PEI scavenging of registers for materializing frame index constants.
  virtual bool
  requiresFrameIndexScavenging(const MachineFunction &MF) const;

#if 0
  /// requiresVirtualBaseRegisters - Returns true if the target wants the
  /// LocalStackAllocation pass to be run and virtual base registers
  /// used for more efficient stack access.
  virtual bool
  requiresVirtualBaseRegisters(const MachineFunction &MF) const;
#endif
  /// hasReservedSpillSlot - Return true if target has reserved a spill slot in
  /// the stack frame of the given function for the specified register. e.g. On
  /// x86, if the frame register is required, the first fixed stack object is
  /// reserved as its spill slot. This tells PEI not to create a new stack frame
  /// object for the given register. It should be called only after
  /// processFunctionBeforeCalleeSavedScan().
  virtual bool
  hasReservedSpillSlot(const MachineFunction &MF,
                       unsigned Reg,
                       int &FrameIdx) const;
#if 0
  /// needsStackRealignment - true if storage within the function requires the
  /// stack pointer to be aligned more than the normal calling convention calls
  /// for.
  virtual bool
  needsStackRealignment(const MachineFunction &MF) const;
#endif
  /// getFrameIndexInstrOffset - Get the offset from the referenced frame
  /// index in the instruction, if there is one.
  virtual int64_t
  getFrameIndexInstrOffset(const MachineInstr *MI,
                           int Idx) const;

  /// needsFrameBaseReg - Returns true if the instruction's frame index
  /// reference would be better served by a base register other than FP
  /// or SP. Used by LocalStackFrameAllocation to determine which frame index
  /// references it should create new base registers for.
  virtual bool
  needsFrameBaseReg(MachineInstr *MI, int64_t Offset) const;

  /// materializeFrameBaseRegister - Insert defining instruction(s) for
  /// BaseReg to be a pointer to FrameIdx before insertion point I.
  virtual void
  materializeFrameBaseRegister(MachineBasicBlock *MBB,
                               unsigned BaseReg,
                               int FrameIdx,
                               int64_t Offset) const;

  /// resolveFrameIndex - Resolve a frame index operand of an instruction
  /// to reference the indicated base register plus offset instead.
  virtual void
  resolveFrameIndex(MachineBasicBlock::iterator I,
                    unsigned BaseReg,
                    int64_t Offset) const;

  /// isFrameOffsetLegal - Determine whether a given offset immediate is
  /// encodable to resolve a frame index.
  virtual bool
  isFrameOffsetLegal(const MachineInstr *MI,
                     int64_t Offset) const;

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
