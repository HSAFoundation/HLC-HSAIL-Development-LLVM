//= HSAILTargetFrameLowering.cpp - Define frame lowering for HSAIL -*- C++ -*-==//
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

#include "llvm/GlobalVariable.h"
#include "llvm/Module.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "HSAILFrameLowering.h"
#include "HSAILRegisterInfo.h"
#include "HSAILTargetMachine.h"
using namespace llvm;

/// getCalleeSavedSpillSlots - This method returns a pointer to an array of
/// pairs, that contains an entry for each callee saved register that must be
/// spilled to a particular stack location if it is spilled.
///
/// Each entry in this array contains a <register,offset> pair, indicating the
/// fixed offset from the incoming stack pointer that each register should be
/// spilled at. If a register is not listed here, the code generator is
/// allowed to spill it anywhere it chooses.
///
const TargetFrameLowering::SpillSlot*
HSAILFrameLowering::getCalleeSavedSpillSlots(unsigned &NumEntries) const
{
  assert(!"When do we hit this?");
  return NULL;
}
#if 0
/// targetHandlesStackFrameRounding - Returns true if the target is
/// responsible for rounding up the stack frame (probably at emitPrologue
/// time).
bool
HSAILFrameLowering::targetHandlesStackFrameRounding() const
{
  assert(!"When do we hit this?");
  return false;
}
#endif

#if 0
/// spillCalleeSavedRegisters - Issues instruction(s) to spill all callee
/// saved registers and returns true if it isn't possible / profitable to do
/// so by issuing a series of store instructions via
/// storeRegToStackSlot(). Returns false otherwise.
bool
HSAILFrameLowering::spillCalleeSavedRegisters(MachineBasicBlock &MBB,
                                              MachineBasicBlock::iterator MI,
                                              const std::vector<CalleeSavedInfo> &CSI,
                                              const TargetRegisterInfo *TRI) const
{
  assert(!"When do we hit this?");
  return false;
}
#endif
#if 0
/// restoreCalleeSavedRegisters - Issues instruction(s) to restore all callee
/// saved registers and returns true if it isn't possible / profitable to do
/// so by issuing a series of load instructions via loadRegToStackSlot().
/// Returns false otherwise.
bool
HSAILFrameLowering::restoreCalleeSavedRegisters(MachineBasicBlock &MBB,
                                                MachineBasicBlock::iterator MI,
                                                const std::vector<CalleeSavedInfo> &CSI,
                                                const TargetRegisterInfo *TRI) const
{
  assert(!"When do we hit this?");
  return false;
}
#endif

/// hasFP - Return true if the specified function should have a dedicated
/// frame pointer register. For most targets this is true only if the function
/// has variable sized allocas or if frame pointer elimination is disabled.
bool
HSAILFrameLowering::hasFP(const MachineFunction &MF) const
{
  return false;
}

#if 0
/// hasReservedCallFrame - Under normal circumstances, when a frame pointer is
/// not required, we reserve argument space for call sites in the function
/// immediately on entry to the current function. This eliminates the need for
/// add/sub sp brackets around call sites. Returns true if the call frame is
/// included as part of the stack frame.
bool
HSAILFrameLowering::hasReservedCallFrame(const MachineFunction &MF) const
{
  assert(!"When do we hit this?");
  return false;
}
#endif
#if 0
/// canSimplifyCallFramePseudos - When possible, it's best to simplify the
/// call frame pseudo ops before doing frame index elimination. This is
/// possible only when frame index references between the pseudos won't
/// need adjusting for the call frame adjustments. Normally, that's true
/// if the function has a reserved call frame or a frame pointer. Some
/// targets (Thumb2, for example) may have more complicated criteria,
/// however, and can override this behavior.
bool
HSAILFrameLowering::canSimplifyCallFramePseudos(const MachineFunction &MF) const
{
  assert(!"When do we hit this?");
  return false;
}
#endif
#if 0
/// getInitialFrameState - Returns a list of machine moves that are assumed
/// on entry to all functions.  Note that LabelID is ignored (assumed to be
/// the beginning of the function.)
void
HSAILFrameLowering::getInitialFrameState(std::vector<MachineMove> &Moves) const
{
  assert(!"When do we hit this?");
}
#endif

/// getFrameIndexOffset - Returns the displacement from the frame register to
/// the stack frame of the specified index.
int
HSAILFrameLowering::getFrameIndexOffset(const MachineFunction &MF, int FI) const
{
  // This logic has been taken from HSAILRegisterInfo.cpp
  const MachineFrameInfo *MFI = MF.getFrameInfo();
  return MFI->getObjectOffset(FI);	
}
#if 0
/// getFrameIndexReference - This method should return the base register
/// and offset used to reference a frame index location. The offset is
/// returned directly, and the base register is returned via FrameReg.
int
HSAILFrameLowering::getFrameIndexReference(const MachineFunction &MF,
                                           int FI,
                                           unsigned &FrameReg) const
{
  assert(!"When do we hit this?");
  return 0;
}
#endif
#if 0
/// processFunctionBeforeCalleeSavedScan - This method is called immediately
/// before PrologEpilogInserter scans the physical registers used to determine
/// what callee saved registers should be spilled. This method is optional.
void
HSAILFrameLowering::processFunctionBeforeCalleeSavedScan(MachineFunction &MF,
                                                         RegScavenger *RS) const
{
  assert(!"When do we hit this?");
}
#endif
#if 0
/// processFunctionBeforeFrameFinalized - This method is called immediately
/// before the specified function's frame layout (MF.getFrameInfo()) is
/// finalized.  Once the frame is finalized, MO_FrameIndex operands are
/// replaced with direct constants.  This method is optional.
void
HSAILFrameLowering::processFunctionBeforeFrameFinal()
{
  assert(!"When do we hit this?");
}
#endif
