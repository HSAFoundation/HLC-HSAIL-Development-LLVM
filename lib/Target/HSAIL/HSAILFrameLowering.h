//=-- HSAILTargetFrameLowering.h - Define HSAIL frame lowering ---*- C++ -*-==//
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

#include "llvm/Target/TargetFrameLowering.h"


namespace llvm {

class HSAILFrameLowering : public TargetFrameLowering {
public:
  explicit HSAILFrameLowering(StackDirection D, unsigned StackAl, int LAO,
                              unsigned TransAl = 1)
      : TargetFrameLowering(D, StackAl, LAO, TransAl) {}

  void emitPrologue(MachineFunction &MF) const override {};

  void emitEpilogue(MachineFunction &MF,
                    MachineBasicBlock &MBB) const override{}

  bool hasFP(const MachineFunction &MF) const override { return false; }

  int getFrameIndexOffset(const MachineFunction &MF, int FI) const override;

  void processFunctionBeforeFrameFinalized(
    MachineFunction &F,
    RegScavenger *RS = nullptr) const override;
};

} // End llvm namespace

#endif // _HSAIL_FRAME_LOWERING_H_
