//=-- HSAILFrameLowering.h - Define HSAIL frame lowering ---------*- C++ -*-==//
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

#ifndef LIB_TARGET_HSAIL_HSAILFRAMELOWERING_H
#define LIB_TARGET_HSAIL_HSAILFRAMELOWERING_H

#include "llvm/Target/TargetFrameLowering.h"


namespace llvm {

class HSAILFrameLowering : public TargetFrameLowering {
public:
  explicit HSAILFrameLowering(StackDirection D, unsigned StackAl, int LAO,
                              unsigned TransAl = 1)
      : TargetFrameLowering(D, StackAl, LAO, TransAl) {}

  void emitPrologue(MachineFunction &MF,
                    MachineBasicBlock &MBB) const override {};

  void emitEpilogue(MachineFunction &MF,
                    MachineBasicBlock &MBB) const override{}

  bool hasFP(const MachineFunction &MF) const override { return false; }

  int getFrameIndexReference(const MachineFunction &MF, int FI,
                             unsigned &FrameReg) const override;

  void processFunctionBeforeFrameFinalized(
    MachineFunction &F,
    RegScavenger *RS = nullptr) const override;
};

} // End llvm namespace

#endif
