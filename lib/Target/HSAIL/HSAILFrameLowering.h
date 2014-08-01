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

#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
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

  /// emitProlog/emitEpilog - These methods insert prolog and epilog code into
  /// the function.
  virtual void
  emitPrologue(MachineFunction &MF) const {};

  virtual void
  emitEpilogue(MachineFunction &MF, MachineBasicBlock &MBB) const {};
  /// hasFP - Return true if the specified function should have a dedicated
  /// frame pointer register. For most targets this is true only if the function
  /// has variable sized allocas or if frame pointer elimination is disabled.
  virtual bool
  hasFP(const MachineFunction &MF) const { return false; };
  /// getFrameIndexOffset - Returns the displacement from the frame register to
  /// the stack frame of the specified index.
  virtual int
  getFrameIndexOffset(const MachineFunction &MF, int FI) const {
    return MF.getFrameInfo()->getObjectOffset(FI);
  };
}; // HSAILFrameLowering

} // End llvm namespace

#endif // _HSAIL_FRAME_LOWERING_H_
