//===- HSAILInstrInfo.h - HSAIL Instruction Information --------*- C++ -*- ===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the HSAIL implementation of the TargetInstrInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef _HSAIL_INSTRUCTION_INFO_H_
#define _HSAIL_INSTRUCTION_INFO_H_

#include "HSAIL.h"
#include "HSAILRegisterInfo.h"
#include "llvm/Target/TargetInstrInfo.h"

#define GET_INSTRINFO_HEADER
#include "HSAILGenInstrInfo.inc"

namespace llvm {
class HSAILSubtarget;
class RegScavenger;

class HSAILInstrInfo : public HSAILGenInstrInfo {
  const HSAILRegisterInfo RI;

public:
  explicit HSAILInstrInfo(HSAILSubtarget &st);

  ~HSAILInstrInfo();

  const HSAILRegisterInfo &getRegisterInfo() const { return RI; }

  bool isCoalescableExtInstr(const MachineInstr &MI, unsigned &SrcReg,
                             unsigned &DstReg, unsigned &SubIdx) const override;

  unsigned isLoadFromStackSlot(const MachineInstr *MI,
                               int &FrameIndex) const override;

  unsigned isLoadFromStackSlotPostFE(const MachineInstr *MI,
                                     int &FrameIndex) const override;

  unsigned isStoreToStackSlot(const MachineInstr *MI,
                              int &FrameIndex) const override;

  unsigned isStoreToStackSlotPostFE(const MachineInstr *MI,
                                    int &FrameIndex) const override;

  bool AnalyzeBranch(MachineBasicBlock &MBB, MachineBasicBlock *&TBB,
                     MachineBasicBlock *&FBB,
                     SmallVectorImpl<MachineOperand> &Cond,
                     bool AllowModify = false) const override;

  unsigned RemoveBranch(MachineBasicBlock &MBB) const override;

  unsigned InsertBranch(MachineBasicBlock &MBB, MachineBasicBlock *TBB,
                        MachineBasicBlock *FBB,
                        ArrayRef<MachineOperand> Cond,
                        DebugLoc DL) const override;

  void copyPhysReg(MachineBasicBlock &MBB, MachineBasicBlock::iterator MI,
                   DebugLoc DL, unsigned DestReg, unsigned SrcReg,
                   bool KillSrc) const override;

  void storeRegToStackSlot(MachineBasicBlock &MBB,
                           MachineBasicBlock::iterator MI, unsigned SrcReg,
                           bool isKill, int FrameIndex,
                           const TargetRegisterClass *RC,
                           const TargetRegisterInfo *TRI) const override;

  void loadRegFromStackSlot(MachineBasicBlock &MBB,
                            MachineBasicBlock::iterator MI, unsigned DestReg,
                            int FrameIndex, const TargetRegisterClass *RC,
                            const TargetRegisterInfo *TRI) const override;

public:
  bool areLoadsFromSameBasePtr(SDNode *Node1, SDNode *Node2, int64_t &Offset1,
                               int64_t &Offset2) const override;

  bool shouldScheduleLoadsNear(SDNode *Node1, SDNode *Node2, int64_t Offset1,
                               int64_t Offset2,
                               unsigned NumLoads) const override;

  bool
  ReverseBranchCondition(SmallVectorImpl<MachineOperand> &Cond) const override;

  bool isSafeToMoveRegClassDefs(const TargetRegisterClass *RC) const override;

  RegScavenger *getRS() const { return RS; }

  bool expandPostRAPseudo(MachineBasicBlock::iterator MBBI) const override;

  const TargetRegisterClass *getOpRegClass(const MachineRegisterInfo &MRI,
                                           const MachineInstr &MI,
                                           unsigned OpNo) const;

  bool verifyInstruction(const MachineInstr *MI,
                         StringRef &ErrInfo) const override;

  /// \brief Returns the operand named \p Op.  If \p MI does not have an
  /// operand named \c Op, this function returns nullptr.
  MachineOperand *getNamedOperand(MachineInstr &MI, unsigned OperandName) const;

  const MachineOperand *getNamedOperand(const MachineInstr &MI,
                                        unsigned OpName) const {
    return getNamedOperand(const_cast<MachineInstr &>(MI), OpName);
  }

  int64_t getNamedModifierOperand(const MachineInstr &MI,
                                  unsigned OpName) const {
    return getNamedOperand(MI, OpName)->getImm();
  }

  int64_t getNamedModifierOperand(MachineInstr &MI, unsigned OpName) const {
    return getNamedOperand(MI, OpName)->getImm();
  }

  bool isInstBasic(uint16_t Opcode) const {
    return get(Opcode).TSFlags & HSAILInstrFlags::InstBasic;
  }

  bool isInstMod(uint16_t Opcode) const {
    return get(Opcode).TSFlags & HSAILInstrFlags::InstMod;
  }

  bool isInstSourceType(uint16_t Opcode) const {
    return get(Opcode).TSFlags & HSAILInstrFlags::InstSourceType;
  }

  bool isInstLane(uint16_t Opcode) const {
    return get(Opcode).TSFlags & HSAILInstrFlags::InstLane;
  }

  bool isInstBr(uint16_t Opcode) const {
    return get(Opcode).TSFlags & HSAILInstrFlags::InstBr;
  }

  bool isInstSeg(uint16_t Opcode) const {
    return get(Opcode).TSFlags & HSAILInstrFlags::InstSeg;
  }

  bool isInstSegCvt(uint16_t Opcode) const {
    return get(Opcode).TSFlags & HSAILInstrFlags::InstSegCvt;
  }

  bool isInstMemFence(uint16_t Opcode) const {
    return get(Opcode).TSFlags & HSAILInstrFlags::InstMemFence;
  }

  bool isInstCmp(uint16_t Opcode) const {
    return get(Opcode).TSFlags & HSAILInstrFlags::InstCmp;
  }

  bool isInstMem(uint16_t Opcode) const {
    return get(Opcode).TSFlags & HSAILInstrFlags::InstMem;
  }

  bool isInstAtomic(uint16_t Opcode) const {
    return get(Opcode).TSFlags & HSAILInstrFlags::InstAtomic;
  }

  bool isInstImage(uint16_t Opcode) const {
    return get(Opcode).TSFlags & HSAILInstrFlags::InstImage;
  }

  bool isInstCvt(uint16_t Opcode) const {
    return get(Opcode).TSFlags & HSAILInstrFlags::InstCvt;
  }

  bool isInstAddr(uint16_t Opcode) const {
    return get(Opcode).TSFlags & HSAILInstrFlags::InstAddr;
  }

  uint16_t getBrigOpcode(uint16_t Opcode) const {
    return (get(Opcode).TSFlags & HSAILInstrFlags::InstBrigOpcode) >>
           Log2_64(HSAILInstrFlags::InstBrigOpcodeLo);
  }

private:
  RegScavenger *RS;
};

namespace HSAIL {
int getAtomicRetOp(uint16_t Opcode);
int getAtomicNoRetOp(uint16_t Opcode);

int16_t getNamedOperandIdx(uint16_t Opcode, uint16_t NamedIndex);

// FIXME: This is a thin wrapper around the similarly named and generated
// getLdStVectorOpcode, which we should use directly.
int getVectorLdStOpcode(uint16_t Opcode, unsigned vsize);
}

} // End llvm namespace

#endif // _HSAIL_INSTR_INFO_H_
