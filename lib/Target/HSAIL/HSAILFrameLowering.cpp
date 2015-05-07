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

  DenseMap<int, uint64_t> SpillMap;
  DenseMap<int, uint64_t> PrivateMap;

  int64_t SpillSize = 0;
  int64_t PrivateSize = 0;
  unsigned SpillAlign = 4;
  unsigned PrivateAlign = 4;

  for (int I = MFI->getObjectIndexBegin(), E = MFI->getObjectIndexEnd();
       I != E; ++I) {
    if (MFI->isDeadObjectIndex(I))
      continue;

    unsigned Size = MFI->getObjectSize(I);
    unsigned Align = MFI->getObjectAlignment(I);
    unsigned Offset = MFI->getObjectOffset(I);

    assert(Offset == 0 &&
           "Stack object offsets should be 0 before frame finalized");

    if (MFI->isSpillSlotObjectIndex(I)) {
      // Adjust to alignment boundary.
      SpillSize = (SpillSize + Align - 1) / Align * Align;
      SpillMap[I] = SpillSize; // Offset

      SpillSize += Size;
      SpillAlign = std::max(SpillAlign, Align);
    } else {
      PrivateSize = (PrivateSize + Align - 1) / Align * Align;
      PrivateMap[I] = PrivateSize; // Offset

      PrivateSize += Size;
      PrivateAlign = std::max(PrivateAlign, Align);
    }

    MFI->RemoveStackObject(I);
  }

  int PrivateIndex = -1;
  int SpillIndex = -1;

  if (PrivateSize != 0)
    PrivateIndex = MFI->CreateStackObject(PrivateSize, PrivateAlign, false);

  if (SpillSize != 0)
    SpillIndex = MFI->CreateSpillStackObject(SpillSize, SpillAlign);

  for (MachineBasicBlock &MBB : MF) {
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

      int Index = Base.getIndex();
      MachineOperand &Offset = MI.getOperand(AddrIdx + 2);
      int64_t OrigOffset = Offset.getImm();

      if (MFI->isSpillSlotObjectIndex(Index)) {
        Base.setIndex(SpillIndex);
        Offset.setImm(SpillMap[Index] + OrigOffset);
      } else {
        Base.setIndex(PrivateIndex);
        Offset.setImm(PrivateMap[Index] + OrigOffset);
      }
    }
  }
}
