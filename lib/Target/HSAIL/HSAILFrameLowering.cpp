//===-- HSAILFrameLowering.cpp --------------------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "HSAILFrameLowering.h"
#include "HSAIL.h"
#include "HSAILInstrInfo.h"
#include "HSAILMachineFunctionInfo.h"

#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/RegisterScavenging.h"

using namespace llvm;


int HSAILFrameLowering::getFrameIndexOffset(const MachineFunction &MF,
                                            int FI) const {
  return MF.getFrameInfo()->getObjectOffset(FI);
}

void HSAILFrameLowering::processFunctionBeforeFrameFinalized(
  MachineFunction &MF,
  RegScavenger *RS) const {
}
