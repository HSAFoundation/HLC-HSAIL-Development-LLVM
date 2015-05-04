//===- HSAILRegisterInfo.cpp - HSAIL Register Information -------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the HSAIL implementation of the TargetRegisterInfo class.
// This file is responsible for the frame pointer elimination optimization
// on HSAIL.
//
//===----------------------------------------------------------------------===//

#include "HSAIL.h"
#include "HSAILBrig.h"
#include "HSAILRegisterInfo.h"
#include "HSAILMachineFunctionInfo.h"
#include "HSAILSubtarget.h"
#include "HSAILTargetMachine.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Type.h"
#include "llvm/CodeGen/ValueTypes.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
//#include "llvm/CodeGen/MachineLocation.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/RegisterScavenging.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/Target/TargetFrameLowering.h"
#include "llvm/Target/TargetInstrInfo.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetOptions.h"
#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"

#define DEBUG_TYPE "hsail-reginfo"

using namespace llvm;

static cl::opt<int> HSAILReg32PressureLimit(
    "hsail-reg32-pressure-limit", cl::Hidden, cl::init(24),
    cl::desc("Register pressure limit for 32 bit HSAIL registers"));

static cl::opt<int> HSAILReg64PressureLimit(
    "hsail-reg64-pressure-limit", cl::Hidden, cl::init(18),
    cl::desc("Register pressure limit for 64 bit HSAIL registers"));

static cl::opt<int> HSAILRegSlots(
    "hsail-reg-slots", cl::Hidden, cl::init(0),
    cl::desc("A number of 64-bit slots allocated for $s registers"));

HSAILRegisterInfo::HSAILRegisterInfo(HSAILSubtarget &st)
    : HSAILGenRegisterInfo(0, 0), ST(st) {}

const uint16_t *
HSAILRegisterInfo::getCalleeSavedRegs(const MachineFunction *MF) const {
  static const uint16_t CalleeSavedRegs[] = {0};
  return CalleeSavedRegs;
}

BitVector
HSAILRegisterInfo::getRegsAvailable(const TargetRegisterClass *RC) const {
  BitVector Mask(getNumRegs());
  for (TargetRegisterClass::iterator I = RC->begin(), E = RC->end(); I != E;
       ++I)
    Mask.set(*I);
  return Mask;
}

BitVector HSAILRegisterInfo::getReservedRegs(const MachineFunction &MF) const {
  BitVector Reserved(getNumRegs());

  // We can have up to 128 s-registers, but we should have (s + 2*d + 4*q) <=
  // 128.
  // Let's calulate the number of 32 and 64 bit VRs used in the function
  // and partition register file accordingly.
  HSAILMachineFunctionInfo *MFI = const_cast<HSAILMachineFunctionInfo *>(
      MF.getInfo<HSAILMachineFunctionInfo>());
  unsigned NumSlotsTotal = HSAIL::GPR64RegClass.getNumRegs();
  // Default register file partitioning 64 s-regs + 32 d-regs, RegSlots = 32.
  unsigned RegSlots = NumSlotsTotal / 2;

  // First query for this function, calculate register use
  if (MFI->getRegisterPartitioning() == 0) {
    const MachineRegisterInfo &RI = MF.getRegInfo();
    unsigned rc32 = 0, rc64 = 0;
    for (unsigned i = 0, e = RI.getNumVirtRegs(); i != e; ++i) {
      switch (RI.getRegClass(index2VirtReg(i))->getSize()) {
      case 4:
        rc32++;
        break;
      case 8:
        rc64++;
        break;
      }
    }

    if (HSAILRegSlots > 0) {
      RegSlots = HSAILRegSlots;
    } else {
      // Calculate register file partitioning. We have 64 allocatable slots
      // which
      // are either 1 d-register or a pair of s-registers. 8 slots are reserved
      // for 16 s-registers $s0..$s15, 8 are for 8 d-registers $d0..$d7.
      // Default partitioning is 64 s-registers + 32 d-registers, which is
      // RegSlots = 32

      // If we have a small amount of 64 bit VRs, but high 32 bit register
      // pressure reallocate slots to decrease 64 bit registers
      if (rc64 < (NumSlotsTotal - RegSlots) && rc32 > (RegSlots * 2)) {
        RegSlots = NumSlotsTotal - rc64;
      }
      // The opposite situation, we have a small demand on 32 bit registers but
      // high pressure for 64 bit
      else if (rc32 < (RegSlots * 2) && rc64 > (NumSlotsTotal - RegSlots)) {
        RegSlots = (rc32 + 1) / 2;
      }
    }

    // Always preserve room for at least 16 s-registers and 8 d-registers
    if (RegSlots < 8)
      RegSlots = 8;
    else if (RegSlots > (NumSlotsTotal - 8))
      RegSlots = NumSlotsTotal - 8;

    MFI->setRegisterPartitioning(RegSlots);
    DEBUG(dbgs() << "\nFunction: " << MF.getFunction()->getName()
                 << " VR count: 32 bit = " << rc32 << ", 64 bit = " << rc64
                 << ", register file partitioning: " << RegSlots * 2 << " $s + "
                 << NumSlotsTotal - RegSlots << " $d\n\n");
  } else {
    RegSlots = MFI->getRegisterPartitioning();
  }

  unsigned Reg;
  unsigned LastSReg = HSAIL::S0 + HSAIL::GPR32RegClass.getNumRegs() - 1;
  for (Reg = HSAIL::S0 + RegSlots * 2; Reg <= LastSReg; ++Reg) {
    Reserved.set(Reg);
  }
  unsigned LastDReg = HSAIL::D0 + HSAIL::GPR64RegClass.getNumRegs() - 1;
  for (Reg = HSAIL::D0 + (NumSlotsTotal - RegSlots); Reg <= LastDReg; ++Reg) {
    Reserved.set(Reg);
  }

  return Reserved;
}

bool HSAILRegisterInfo::trackLivenessAfterRegAlloc(
    const MachineFunction &MF) const {
  // Only enable when post-RA scheduling is enabled and this is needed.
  // TODO: HSA
  return true;
}

const TargetRegisterClass *
HSAILRegisterInfo::getPointerRegClass(const MachineFunction &MF,
                                      unsigned Kind) const {
  if (Kind == 32)
    return &HSAIL::GPR32RegClass;

  assert(Kind == 0);

  if (ST.is64Bit())
    return &HSAIL::GPR64RegClass;
  return &HSAIL::GPR32RegClass;
}

bool HSAILRegisterInfo::requiresRegisterScavenging(
    const MachineFunction &MF) const {
  return true;
}

/// requiresFrameIndexScavenging - returns true if the target requires post
/// PEI scavenging of registers for materializing frame index constants.
bool HSAILRegisterInfo::requiresFrameIndexScavenging(
    const MachineFunction &MF) const {
  return true;
}

static int getScavengingFrameIndex(RegScavenger *RS) {

  SmallVector<int, 8> FI;
  RS->getScavengingFrameIndices(FI);
  return FI[0];
}

// Save scavenger register and provide a frame index for it.
bool HSAILRegisterInfo::saveScavengerRegisterToFI(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator I,
    MachineBasicBlock::iterator &UseMI, const TargetRegisterClass *RC,
    unsigned Reg, int FI) const {
  const HSAILInstrInfo &HII =
      *static_cast<const HSAILInstrInfo *>(ST.getInstrInfo());
  RegScavenger *RS = HII.getRS();

  assert(RS != 0 && "Register scavenger has not been created");

  // Setup emergency spill location
  RS->addScavengingFrameIndex(FI);

  assert(getScavengingFrameIndex(RS) >= 0 &&
         "Cannot scavenge register without an emergency spill slot!");

  // Store the scavenged register to its stack spill location
  HII.storeRegToStackSlot(MBB, I, Reg, true /* isKill */,
                          getScavengingFrameIndex(RS), RC, this);

  // Restore the scavenged register before its use (or first terminator).
  HII.loadRegFromStackSlot(MBB, UseMI, Reg, getScavengingFrameIndex(RS), RC,
                           this);

  // HSAIL Target saves/restores the scavenged register
  return true;
}

void HSAILRegisterInfo::lowerSpillB1(MachineBasicBlock::iterator II,
                                     int FrameIndex) const {
  MachineBasicBlock *MBB = II->getParent();
  MachineFunction *MF = MBB->getParent();
  MachineInstr &MI = *II;
  const HSAILInstrInfo *TII = ST.getInstrInfo();
  MachineRegisterInfo &MRI = MF->getRegInfo();
  unsigned TempGPR32 = MRI.createVirtualRegister(&HSAIL::GPR32RegClass);

  DebugLoc DL = MI.getDebugLoc();
  BuildMI(*MBB, II, DL, TII->get(HSAIL::CVT_U32_B1), TempGPR32)
    .addImm(0)             // ftz
    .addImm(0)             // round
    .addImm(BRIG_TYPE_U32) // destTypedestLength
    .addImm(BRIG_TYPE_B1)  // srcTypesrcLength
    .addOperand(MI.getOperand(0));

  MI.setDesc(TII->get(HSAIL::ST_U32));
  MI.getOperand(0).setReg(TempGPR32);
  MI.getOperand(0).setIsKill();

  MachineOperand *TypeOp = TII->getNamedOperand(MI, HSAIL::OpName::TypeLength);
  TypeOp->setImm(BRIG_TYPE_U32);
}

void HSAILRegisterInfo::lowerRestoreB1(MachineBasicBlock::iterator II,
                                       int FrameIndex) const {
  MachineBasicBlock *MBB = II->getParent();
  MachineInstr &MI = *II;
  DebugLoc DL = MI.getDebugLoc();
  unsigned DestReg = MI.getOperand(0).getReg();
  const HSAILInstrInfo *TII = ST.getInstrInfo();

  MachineRegisterInfo &MRI = MBB->getParent()->getRegInfo();
  unsigned TempGPR32 = MRI.createVirtualRegister(&HSAIL::GPR32RegClass);

  BuildMI(*MBB, ++II, DL, TII->get(HSAIL::CVT_B1_U32), DestReg)
    .addImm(0)             // ftz
    .addImm(0)             // round
    .addImm(BRIG_TYPE_B1)  // destTypedestLength
    .addImm(BRIG_TYPE_U32) // srcTypesrcLength
    .addReg(TempGPR32, RegState::Kill);

  MI.setDesc(TII->get(HSAIL::LD_U32));
  MI.getOperand(0).setReg(TempGPR32);
  MI.getOperand(0).setIsDef();

  MachineOperand *TypeOp = TII->getNamedOperand(MI, HSAIL::OpName::TypeLength);
  TypeOp->setImm(BRIG_TYPE_U32);
}

void HSAILRegisterInfo::eliminateFrameIndex(MachineBasicBlock::iterator II,
                                            int SPAdj, unsigned FIOperandNum,
                                            RegScavenger *RS) const {
  assert(SPAdj == 0 && "Unexpected");
  MachineInstr &MI = *II;
  unsigned Opcode = MI.getOpcode();
  MachineFunction &MF = *MI.getParent()->getParent();
  // FrameIndex to Offset translation is usually performed by the
  // target-specific implementation of TargetFrameLowering
  const TargetFrameLowering *TFL =
      MF.getTarget().getSubtarget<HSAILSubtarget>().getFrameLowering();

  assert(HSAIL::getNamedOperandIdx(Opcode, HSAIL::OpName::address) ==
         static_cast<int>(FIOperandNum) &&
         "Frame index should only be used for address operands");

  MachineOperand &Base = MI.getOperand(FIOperandNum);
  int FrameIndex = Base.getIndex();

  if (Opcode == HSAIL::SPILL_B1)
    lowerSpillB1(II, FrameIndex);
  else if (Opcode == HSAIL::RESTORE_B1)
    lowerRestoreB1(II, FrameIndex);


  unsigned int y = MI.getNumOperands();
  for (unsigned int x = 0; x < y; ++x) {
    if (!MI.getOperand(x).isFI()) {
      continue;
    }
    int FrameIndex = MI.getOperand(x).getIndex();
    int64_t Offset = TFL->getFrameIndexOffset(MF, FrameIndex);
    // int64_t Size = MF.getFrameInfo()->getObjectSize(FrameIndex);
    // An optimization is to only use the offsets if the size
    // is larger than 4, which means we are storing an array
    // instead of just a pointer. If we are size 4 then we can
    // just do register copies since we don't need to worry about
    // indexing dynamically
    if (!MI.getOperand(x).isImm()) {
      MI.getOperand(x).ChangeToImmediate(Offset);
    } else {
      MI.getOperand(x).setImm(Offset);
    }
  }
}

//===--------------------------------------------------------------------===//
/// Debug information queries.

unsigned HSAILRegisterInfo::getFrameRegister(const MachineFunction &MF) const {
  // This value is unused in LLVM
  return HSAIL::NoRegister;
}

unsigned HSAILRegisterInfo::getRegPressureLimit(const TargetRegisterClass *RC,
                                                MachineFunction &MF) const {
  if (RC == &HSAIL::GPR32RegClass) {
    return HSAILReg32PressureLimit;
  }
  if (RC == &HSAIL::GPR64RegClass) {
    return HSAILReg64PressureLimit;
  }
  return 0;
}

const TargetRegisterClass *
HSAILRegisterInfo::getPhysRegClass(unsigned Reg) const {
  assert(!TargetRegisterInfo::isVirtualRegister(Reg));

  static const TargetRegisterClass *BaseClasses[] = {
      &HSAIL::GPR32RegClass, &HSAIL::GPR64RegClass, &HSAIL::CRRegClass};

  for (const TargetRegisterClass *BaseClass : BaseClasses) {
    if (BaseClass->contains(Reg))
      return BaseClass;
  }
  return nullptr;
}

#define GET_REGINFO_TARGET_DESC
#include "HSAILGenRegisterInfo.inc"
