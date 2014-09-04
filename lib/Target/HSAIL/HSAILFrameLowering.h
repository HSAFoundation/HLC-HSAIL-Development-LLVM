//= HSAILTargetFrameLowering.h - Define frame lowering for HSAIL -*- C++ -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This class implements HSAIL-specific bits of TargetFrameLowering class.
//
//===----------------------------------------------------------------------===//

#ifndef _HSAIL_FRAME_LOWERING_H_
#define _HSAIL_FRAME_LOWERING_H_

#include "HSAILSubtarget.h"
//#include "llvm/CodeGen/MachineLocation.h"
#include "llvm/Target/TargetFrameLowering.h"

namespace llvm {
  class MCSymbol;
  class HSAILTargetMachine;

class HSAILFrameLowering : public TargetFrameLowering {
public:
  explicit HSAILFrameLowering(StackDirection D,
                              unsigned StackAl,
                              int LAO,
                              unsigned TransAl=1)
    : TargetFrameLowering(D, StackAl, LAO, TransAl) {}

  /// getCalleeSavedSpillSlots - This method returns a pointer to an array of
  /// pairs, that contains an entry for each callee saved register that must be
  /// spilled to a particular stack location if it is spilled.
  ///
  /// Each entry in this array contains a <register,offset> pair, indicating the
  /// fixed offset from the incoming stack pointer that each register should be
  /// spilled at. If a register is not listed here, the code generator is
  /// allowed to spill it anywhere it chooses.
  ///
  virtual const SpillSlot*
  getCalleeSavedSpillSlots(unsigned &NumEntries) const;
#if 0
  /// targetHandlesStackFrameRounding - Returns true if the target is
  /// responsible for rounding up the stack frame (probably at emitPrologue
  /// time).
  virtual bool
  targetHandlesStackFrameRounding() const;
#endif
  /// emitProlog/emitEpilog - These methods insert prolog and epilog code into
  /// the function.
  virtual void
  emitPrologue(MachineFunction &MF) const {};

  virtual void
  emitEpilogue(MachineFunction &MF, MachineBasicBlock &MBB) const {};
#if 0
  /// spillCalleeSavedRegisters - Issues instruction(s) to spill all callee
  /// saved registers and returns true if it isn't possible / profitable to do
  /// so by issuing a series of store instructions via
  /// storeRegToStackSlot(). Returns false otherwise.
  virtual bool
  spillCalleeSavedRegisters(MachineBasicBlock &MBB,
                            MachineBasicBlock::iterator MI,
                            const std::vector<CalleeSavedInfo> &CSI,
                            const TargetRegisterInfo *TRI) const;
#endif
#if 0
  /// restoreCalleeSavedRegisters - Issues instruction(s) to restore all callee
  /// saved registers and returns true if it isn't possible / profitable to do
  /// so by issuing a series of load instructions via loadRegToStackSlot().
  /// Returns false otherwise.
  virtual bool
  restoreCalleeSavedRegisters(MachineBasicBlock &MBB,
                              MachineBasicBlock::iterator MI,
                              const std::vector<CalleeSavedInfo> &CSI,
                              const TargetRegisterInfo *TRI) const;
#endif
  /// hasFP - Return true if the specified function should have a dedicated
  /// frame pointer register. For most targets this is true only if the function
  /// has variable sized allocas or if frame pointer elimination is disabled.
  virtual bool
  hasFP(const MachineFunction &MF) const;
#if 0
  /// hasReservedCallFrame - Under normal circumstances, when a frame pointer is
  /// not required, we reserve argument space for call sites in the function
  /// immediately on entry to the current function. This eliminates the need for
  /// add/sub sp brackets around call sites. Returns true if the call frame is
  /// included as part of the stack frame.
  virtual bool
  hasReservedCallFrame(const MachineFunction &MF) const;
#endif
#if 0
  /// canSimplifyCallFramePseudos - When possible, it's best to simplify the
  /// call frame pseudo ops before doing frame index elimination. This is
  /// possible only when frame index references between the pseudos won't
  /// need adjusting for the call frame adjustments. Normally, that's true
  /// if the function has a reserved call frame or a frame pointer. Some
  /// targets (Thumb2, for example) may have more complicated criteria,
  /// however, and can override this behavior.
  virtual bool
  canSimplifyCallFramePseudos(const MachineFunction &MF) const;
#endif
#if 0
  /// getInitialFrameState - Returns a list of machine moves that are assumed
  /// on entry to all functions.  Note that LabelID is ignored (assumed to be
  /// the beginning of the function.)
  virtual void
  getInitialFrameState(std::vector<MachineMove> &Moves) const;
#endif
  /// getFrameIndexOffset - Returns the displacement from the frame register to
  /// the stack frame of the specified index.
  virtual int
  getFrameIndexOffset(const MachineFunction &MF, int FI) const;
#if 0
  /// getFrameIndexReference - This method should return the base register
  /// and offset used to reference a frame index location. The offset is
  /// returned directly, and the base register is returned via FrameReg.
  virtual int
  getFrameIndexReference(const MachineFunction &MF,
                         int FI,
                         unsigned &FrameReg) const;
#endif
#if 0
  /// processFunctionBeforeCalleeSavedScan - This method is called immediately
  /// before PrologEpilogInserter scans the physical registers used to determine
  /// what callee saved registers should be spilled. This method is optional.
  virtual void
  processFunctionBeforeCalleeSavedScan(MachineFunction &MF,
                                       RegScavenger *RS = NULL) const;
#endif
#if 0
  /// processFunctionBeforeFrameFinalized - This method is called immediately
  /// before the specified function's frame layout (MF.getFrameInfo()) is
  /// finalized.  Once the frame is finalized, MO_FrameIndex operands are
  /// replaced with direct constants.  This method is optional.
  virtual void
  processFunctionBeforeFrameFinal();
#endif
}; // HSAILFrameLowering

} // End llvm namespace

#endif // _HSAIL_FRAME_LOWERING_H_
