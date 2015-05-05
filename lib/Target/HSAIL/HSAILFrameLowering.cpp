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
  MachineFrameInfo *MFI = MF.getFrameInfo();

  const HSAILMachineFunctionInfo *Info = MF.getInfo<HSAILMachineFunctionInfo>();

  // If we don't have a RegScavenger available for some reason, conservatively
  // assume we will need an emergency stack slot.
  bool RequireEmergencySlot = (RS == nullptr);

  for (MachineBasicBlock &MBB : MF) {
    if (RS && Info->hasSpilledCRs())
      RS->enterBasicBlock(&MBB);

    for (MachineInstr &MI : MBB) {
      unsigned Opc = MI.getOpcode();
      int AddrIdx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::address);
      if (AddrIdx == -1) {
        // All instructions capable of having a FrameIndex should have an
        // address operand.
        continue;
      }

      MachineOperand &Base = MI.getOperand(AddrIdx);
      if (!Base.isFI())
        continue;

      // If we are spilling condition registers, see if we will need an
      // emergency stack slot.
      if (RS && (Opc == HSAIL::SPILL_B1 || Opc == HSAIL::RESTORE_B1)) {
        RS->forward(&MI);
        if (RS->FindUnusedReg(&HSAIL::GPR32RegClass) == HSAIL::NoRegister)
          RequireEmergencySlot = true;
      }
    }
  }

  if (RequireEmergencySlot) {
    int ScavengeFI = MFI->CreateStackObject(HSAIL::GPR32RegClass.getSize(),
                                            HSAIL::GPR32RegClass.getAlignment(),
                                            true);
    RS->addScavengingFrameIndex(ScavengeFI);
  }
}
