//===-- HSAILInstrInfo.cpp - HSAIL Instruction Information ----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "HSAILInstrInfo.h"
#include "HSAILBrigDefs.h"
#include "HSAILTargetMachine.h"
#include "HSAILUtilityFunctions.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/RegisterScavenging.h"
#include "llvm/Support/CommandLine.h"

#include <queue>

#define GET_INSTRINFO_CTOR_DTOR
#define GET_INSTRMAP_INFO
#include "HSAILGenInstrInfo.inc"
using namespace llvm;
namespace llvm {

static cl::opt<bool> DisableBranchAnalysis("disable-branch-analysis",
                                           cl::Hidden,
                                           cl::desc("Disable branch analysis"));
static cl::opt<bool>
    DisableCondReversion("disable-branch-cond-reversion", cl::Hidden,
                         cl::desc("Disable branch condition reversion"));

// Reverse conditions in branch analysis
// It marks whether or not we need to reverse condition
// when we insert new branch
enum CondReverseFlag {
  COND_IRREVERSIBLE,     // For branches that can not be reversed
  COND_REVERSE_POSITIVE, // Don't need invertion
  COND_REVERSE_NEGATIVE, // Need invertion
  COND_REVERSE_DEPENDANT // Indicates that this condition has exactly
                         // one depency which should be reverted with it
};

HSAILInstrInfo::HSAILInstrInfo(HSAILSubtarget &st)
    : HSAILGenInstrInfo(),
      //  : TargetInstrInfoImpl(HSAILInsts, array_lengthof(HSAILInsts)),
      RI(st) {
  RS = new RegScavenger();
}

HSAILInstrInfo::~HSAILInstrInfo() { delete RS; }

bool HSAILInstrInfo::isCoalescableExtInstr(const MachineInstr &MI,
                                           unsigned &SrcReg, unsigned &DstReg,
                                           unsigned &SubIdx) const {
  // HSAIL does not have any registers that overlap and cause
  // an extension.
  return false;
}

unsigned HSAILInstrInfo::isLoadFromStackSlot(const MachineInstr *MI,
                                             int &FrameIndex) const {
  const MCInstrDesc &MCID = get(MI->getOpcode());
  if (!MCID.mayLoad() || !MI->hasOneMemOperand())
    return HSAIL::NoRegister;

  const MachineOperand *Segment = getNamedOperand(*MI, HSAIL::OpName::segment);
  if (!Segment || Segment->getImm() != HSAILAS::SPILL_ADDRESS)
    return HSAIL::NoRegister;

  int AddressIdx =
      HSAIL::getNamedOperandIdx(MI->getOpcode(), HSAIL::OpName::address);
  const MachineOperand &Base = MI->getOperand(AddressIdx + HSAILADDRESS::BASE);

  if (Base.isFI()) {
    FrameIndex = Base.getIndex();
    return MI->getOperand(0).getReg();
  }

  return HSAIL::NoRegister;
}

unsigned HSAILInstrInfo::isLoadFromStackSlotPostFE(const MachineInstr *MI,
                                                   int &FrameIndex) const {
  return isLoadFromStackSlot(MI, FrameIndex);
}

unsigned HSAILInstrInfo::isStoreToStackSlot(const MachineInstr *MI,
                                            int &FrameIndex) const {
  const MCInstrDesc &MCID = get(MI->getOpcode());
  if (!MCID.mayStore() || !MI->hasOneMemOperand())
    return 0;

  const MachineOperand *Segment = getNamedOperand(*MI, HSAIL::OpName::segment);
  if (!Segment || Segment->getImm() != HSAILAS::SPILL_ADDRESS)
    return HSAIL::NoRegister;

  int AddressIdx =
      HSAIL::getNamedOperandIdx(MI->getOpcode(), HSAIL::OpName::address);
  const MachineOperand &Base = MI->getOperand(AddressIdx + HSAILADDRESS::BASE);
  if (Base.isFI()) {
    FrameIndex = Base.getIndex();
    return MI->getOperand(0).getReg();
  }

  return HSAIL::NoRegister;
}

unsigned HSAILInstrInfo::isStoreToStackSlotPostFE(const MachineInstr *MI,
                                                  int &FrameIndex) const {
  return isStoreToStackSlot(MI, FrameIndex);
}

static bool IsDefBeforeUse(MachineBasicBlock &MBB, unsigned Reg,
                           const MachineRegisterInfo &MRI, bool &CanReverse) {
  // TODO_HSA: With LiveVariable analysis we can make it
  // a lot more effectively.
  // But currently we can not rely on any of the analysis results
  // In latest llvm exist MRI::tracksLiveness flag
  // if it is true we don't need this costly bfs search

  CanReverse = true;

  std::queue<MachineBasicBlock *> Q;
  SmallPtrSet<MachineBasicBlock *, 32> Visited;

  Q.push(&MBB);

  while (!Q.empty()) {
    MachineBasicBlock *cur_mbb = Q.front();
    Q.pop();

    for (MachineBasicBlock::succ_iterator succ = cur_mbb->succ_begin(),
                                          succ_end = cur_mbb->succ_end();
         succ != succ_end; ++succ)
      if (!Visited.count(*succ)) {
        Visited.insert(*succ);

        bool need_process_futher = true;

        // Process basic block
        for (MachineBasicBlock::iterator instr = (*succ)->begin(),
                                         instr_end = (*succ)->end();
             instr != instr_end; ++instr) {
          if (instr->readsRegister(Reg)) {
            // Always abort on circular dependencies
            // Which will require to insert or remove not
            // FIXME: This detects only single BB loop uses where the
            // definition is also inside the loop.
            if (instr->getParent() == &MBB &&
                (instr->isBranch() || (instr->getOpcode() == HSAIL::NOT_B1))) {
              CanReverse = false;
            }

            return false;
          }
          if (instr->definesRegister(Reg)) {
            need_process_futher = false;
            break;
          }
        }

        // Schedule basic block
        if (need_process_futher)
          Q.push(*succ);
      }
  }

  return true;
}

static bool CheckSpillAfterDef(MachineInstr *start, unsigned reg,
                               bool &canBeSpilled) {
  MachineBasicBlock *MBB = start->getParent();
  MachineBasicBlock::reverse_iterator B(start);
  MachineBasicBlock::reverse_iterator E = MBB->rend();
  if (E == B)
    return false; // empty block check
  ++B;            // skip branch instr itself
  for (MachineBasicBlock::reverse_iterator I = B; I != E; ++I) {
    if (I->definesRegister(reg)) {
      return true;
    }
    if (I->readsRegister(reg) && (HSAIL::isConv(&*I) || I->mayStore())) {
      canBeSpilled = true;
      return true;
    }
  }
  return false;
}

static bool IsSpilledAfterDef(MachineInstr *start, unsigned reg) {
  bool canBeSpilled = false;
  if (!CheckSpillAfterDef(start, reg, canBeSpilled)) {
    std::queue<MachineBasicBlock *> Q;
    SmallPtrSet<MachineBasicBlock *, 32> Visited;
    MachineBasicBlock *MBB = start->getParent();
    Q.push(MBB);
    while (!Q.empty() && !canBeSpilled) {
      MachineBasicBlock *cur_mbb = Q.front();
      Q.pop();
      for (MachineBasicBlock::pred_iterator pred = cur_mbb->pred_begin(),
                                            pred_end = cur_mbb->pred_end();
           pred != pred_end; ++pred) {
        if (!Visited.count(*pred) && !(*pred)->empty()) {
          Visited.insert(*pred);
          MachineInstr *instr;
          MachineBasicBlock::instr_iterator termIt =
              (*pred)->getFirstInstrTerminator();
          if (termIt == (*pred)->instr_end()) {
            instr = &*(*pred)->rbegin();
          } else {
            instr = termIt;
          }
          if (!CheckSpillAfterDef(instr, reg, canBeSpilled)) {
            Q.push(*pred);
          }
        }
      }
    }
  }
  return canBeSpilled;
}

bool HSAILInstrInfo::AnalyzeBranch(MachineBasicBlock &MBB,
                                   MachineBasicBlock *&TBB,
                                   MachineBasicBlock *&FBB,
                                   SmallVectorImpl<MachineOperand> &Cond,
                                   bool AllowModify) const {
  const MachineRegisterInfo &MRI = MBB.getParent()->getRegInfo();
  if (DisableBranchAnalysis)
    return true;

  // Start from the bottom of the block and work up, examining the
  // terminator instructions.
  MachineBasicBlock::iterator I = MBB.end();
  MachineBasicBlock::iterator UnCondBrIter = MBB.end();

  while (I != MBB.begin()) {
    --I;
    if (I->isDebugValue())
      continue;

    // Working from the bottom, when we see a non-terminator instruction, we're
    // done.
    if (!isUnpredicatedTerminator(I))
      break;

    // A terminator that isn't a branch can't easily be handled by this
    // analysis.
    if (!I->getDesc().isBranch())
      return true;

    // Handle unconditional branches.
    if (I->getOpcode() == HSAIL::BR) {
      int Src0Idx = HSAIL::getNamedOperandIdx(HSAIL::BR, HSAIL::OpName::src0);
      UnCondBrIter = I;

      Cond.clear();
      FBB = 0;

      if (!AllowModify) {
        TBB = I->getOperand(Src0Idx).getMBB();
        continue;
      }

      // If the block has any instructions after a JMP, delete them.
      while (std::next(I) != MBB.end())
        std::next(I)->eraseFromParent();

      // Delete the JMP if it's equivalent to a fall-through.
      if (MBB.isLayoutSuccessor(I->getOperand(Src0Idx).getMBB())) {
        TBB = 0;
        I->eraseFromParent();
        I = MBB.end();
        UnCondBrIter = MBB.end();
        continue;
      }

      // TBB is used to indicate the unconditional destination.
      TBB = I->getOperand(Src0Idx).getMBB();
      continue;
    }

    // Handle conditional branches.

    // First conditional branch
    if (Cond.empty()) {
      int Src0Idx = HSAIL::getNamedOperandIdx(HSAIL::CBR, HSAIL::OpName::src0);
      int Src1Idx = HSAIL::getNamedOperandIdx(HSAIL::CBR, HSAIL::OpName::src1);

      FBB = TBB;
      TBB = I->getOperand(Src1Idx).getMBB();

      // Insert condition as pair - (register, reverse flag)
      // Or in case if there is dependencies
      // (register, COND_REVERSE_DEPENDANT, free reg num, reverse flag)
      Cond.push_back(I->getOperand(Src0Idx));

      if (DisableCondReversion) {
        Cond.push_back(MachineOperand::CreateImm(COND_IRREVERSIBLE));
        continue;
      }

      // Determine condition dependencies
      unsigned reg = I->getOperand(Src0Idx).getReg();
      bool can_reverse = false;
      bool is_def_before_use = IsDefBeforeUse(MBB, reg, MRI, can_reverse);
      if (can_reverse) {
        /* Here we're taking care of the possible control register spilling
         that occur between it's definition and branch. If it does, we're not
         allowed to inverse branch because some other place rely on the
         unspilled value.
       */
        can_reverse = !IsSpilledAfterDef(I, reg);
      }
      // Can not reverse instruction which will require to
      // insert or remove 'not_b1' inside loop
      // Also, we avoid reversing for that comparisons
      // whose result is spilled in between the definition and use.
      if (!can_reverse) {
        Cond.push_back(MachineOperand::CreateImm(COND_IRREVERSIBLE));
        continue;
      }

      // If there is no uses of condition register we can just reverse
      // instruction and be fine
      if (is_def_before_use) {
        Cond.push_back(MachineOperand::CreateImm(COND_REVERSE_POSITIVE));
        continue;
      }

      // There is uses of this instruction somewhere down the control flow
      // Try to use RegisterScavenger to get free register
      // If there is no such one than do not inverse condition
      if (!MRI.tracksLiveness()) {
        Cond.push_back(MachineOperand::CreateImm(COND_IRREVERSIBLE));
        continue;
      }

      unsigned free_reg = 0;
      if (!TargetRegisterInfo::isVirtualRegister(Cond[0].getReg())) {
        RS->enterBasicBlock(&MBB);
        RS->forward(std::prev(MBB.end()));

        free_reg = RS->FindUnusedReg(&HSAIL::CRRegClass);
        if (free_reg == 0) {
          Cond.push_back(MachineOperand::CreateImm(COND_IRREVERSIBLE));
          continue;
        }
        RS->setRegUsed(free_reg);
      }

      // Everything is ok - mark condition as reversible
      Cond.push_back(MachineOperand::CreateImm(COND_REVERSE_DEPENDANT));
      Cond.push_back(MachineOperand::CreateImm(free_reg));
      Cond.push_back(MachineOperand::CreateImm(COND_REVERSE_POSITIVE));
      continue;
    }

    // Can not handle more than one conditional branch
    return true;
  }

  return false;
}

static BrigCompareOperation invIntCondOp(BrigCompareOperation Op) {
  switch (Op) {
  case BRIG_COMPARE_EQ:
    return BRIG_COMPARE_NE;
  case BRIG_COMPARE_GE:
    return BRIG_COMPARE_LT;
  case BRIG_COMPARE_GT:
    return BRIG_COMPARE_LE;
  case BRIG_COMPARE_LE:
    return BRIG_COMPARE_GT;
  case BRIG_COMPARE_LT:
    return BRIG_COMPARE_GE;
  case BRIG_COMPARE_NE:
    return BRIG_COMPARE_EQ;
  default:
    return Op;
  }
}

static BrigCompareOperation invFPCondOp(BrigCompareOperation Op) {
  switch (Op) {
  case BRIG_COMPARE_NUM:
    return BRIG_COMPARE_NAN;
  case BRIG_COMPARE_EQ:
    return BRIG_COMPARE_NEU;
  case BRIG_COMPARE_GE:
    return BRIG_COMPARE_LTU;
  case BRIG_COMPARE_GT:
    return BRIG_COMPARE_LEU;
  case BRIG_COMPARE_LE:
    return BRIG_COMPARE_GTU;
  case BRIG_COMPARE_LT:
    return BRIG_COMPARE_GEU;
  case BRIG_COMPARE_NE:
    return BRIG_COMPARE_EQU;
  case BRIG_COMPARE_EQU:
    return BRIG_COMPARE_NE;
  case BRIG_COMPARE_GEU:
    return BRIG_COMPARE_LT;
  case BRIG_COMPARE_GTU:
    return BRIG_COMPARE_LE;
  case BRIG_COMPARE_LEU:
    return BRIG_COMPARE_GT;
  case BRIG_COMPARE_LTU:
    return BRIG_COMPARE_GE;
  case BRIG_COMPARE_NEU:
    return BRIG_COMPARE_EQ;
  case BRIG_COMPARE_NAN:
    return BRIG_COMPARE_NUM;
  default:
    return Op;
  }
}

static bool isFPBrigType(BrigType BT) {
  switch (BT) {
  case BRIG_TYPE_F32:
  case BRIG_TYPE_F64:
  case BRIG_TYPE_F16:
    return true;
  default:
    return false;
  }
}

// Helper for `HSAILInstrInfo::InsertBranch`
// Reverse branch condition
// Different from `HSAILInstrInfo::ReverseBranchCondition`
// because it actually generates reversion code
// Returns register with condition result
static unsigned GenerateBranchCondReversion(MachineBasicBlock &MBB,
                                            const MachineOperand &CondOp,
                                            const HSAILInstrInfo *TII,
                                            DebugLoc DL) {
  assert(CondOp.isReg());
  unsigned cond_reg = CondOp.getReg();

  MachineRegisterInfo &MRI = MBB.getParent()->getRegInfo();

  MachineInstr *cond_expr = nullptr;

  // Manualy search for latest usage of condition register in MBB
  MachineBasicBlock::iterator I = MBB.end();

  while (I != MBB.begin()) {
    --I;

    if (I->definesRegister(cond_reg)) {
      cond_expr = &*I;
      break;
    }
  }

  // If condition is compare instruction - reverse it
  bool need_insert_not = false;
  if (cond_expr && cond_expr->isCompare()) {
    MachineOperand *CmpOp = TII->getNamedOperand(*cond_expr, HSAIL::OpName::op);

    BrigType CmpType = static_cast<BrigType>(
        TII->getNamedOperand(*cond_expr, HSAIL::OpName::sourceType)->getImm());

    BrigCompareOperation OrigOp =
        static_cast<BrigCompareOperation>(CmpOp->getImm());

    BrigCompareOperation RevOp =
        isFPBrigType(CmpType) ? invFPCondOp(OrigOp) : invIntCondOp(OrigOp);

    if (OrigOp != RevOp) // Can invert the operation.
      CmpOp->setImm(RevOp);
    else
      need_insert_not = true;
  }
  // If condition is logical not - just remove it
  else if (cond_expr && cond_expr->getOpcode() == HSAIL::NOT_B1) {
    cond_reg = cond_expr->getOperand(1).getReg();
    cond_expr->eraseFromParent();
  } else
    need_insert_not = true;

  // Else insert logical not
  if (need_insert_not) {
    // If we are before register allocation we need to maintain SSA form
    if (TargetRegisterInfo::isVirtualRegister(CondOp.getReg()))
      cond_reg = MRI.createVirtualRegister(MRI.getRegClass(CondOp.getReg()));

    BuildMI(&MBB, DL, TII->get(HSAIL::NOT_B1))
        .addReg(cond_reg, RegState::Define)
        .addReg(CondOp.getReg())
        .addImm(BRIG_TYPE_B1);
  }

  return cond_reg;
}

unsigned HSAILInstrInfo::InsertBranch(
    MachineBasicBlock &MBB, MachineBasicBlock *TBB, MachineBasicBlock *FBB,
    ArrayRef<MachineOperand> Cond, DebugLoc DL) const {
  // Shouldn't be a fall through.
  assert(TBB && "InsertBranch must not be told to insert a fallthrough");

  if (Cond.empty()) {
    // Unconditional branch?
    assert(!FBB && "Unconditional branch with multiple successors!");
    BuildMI(&MBB, DL, get(HSAIL::BR))
        .addImm(BRIG_WIDTH_ALL)
        .addMBB(TBB)
        .addImm(BRIG_TYPE_NONE);
    return 1;
  }

  // AnalyzeBranch can handle only one condition
  if (Cond.size() != 2 && Cond.size() != 4)
    return 0;

  // Conditional branch.
  // According to HSAIL spec condition MUST be a control register
  assert(Cond[0].isReg());
  unsigned cond_reg = Cond[0].getReg();

  // Reverse condition
  switch (static_cast<CondReverseFlag>(Cond[1].getImm())) {
  case COND_REVERSE_DEPENDANT:
    assert(Cond.size() == 4 && Cond[2].isImm());

    if (Cond[3].getImm() == COND_REVERSE_NEGATIVE) {
      MachineRegisterInfo &MRI = MBB.getParent()->getRegInfo();
      if (TargetRegisterInfo::isVirtualRegister(Cond[0].getReg()))
        cond_reg = MRI.createVirtualRegister(MRI.getRegClass(Cond[0].getReg()));
      else
        cond_reg = Cond[2].getImm();

      BuildMI(&MBB, DL, get(HSAIL::NOT_B1))
          .addReg(cond_reg, RegState::Define)
          .addReg(Cond[0].getReg())
          .addImm(BRIG_TYPE_B1);
    }

    break;
  case COND_REVERSE_NEGATIVE:
    cond_reg = GenerateBranchCondReversion(MBB, Cond[0], this, DL);
    break;
  case COND_REVERSE_POSITIVE:
  case COND_IRREVERSIBLE:
    // Do nothing
    break;
  }

  unsigned Count = 0;

  BuildMI(&MBB, DL, get(HSAIL::CBR))
      .addImm(BRIG_WIDTH_1)
      .addReg(cond_reg)
      .addMBB(TBB)
      .addImm(BRIG_TYPE_B1);

  ++Count;

  if (FBB) {
    // Two-way Conditional branch. Insert the second branch.
    BuildMI(&MBB, DL, get(HSAIL::BR))
        .addImm(BRIG_WIDTH_ALL)
        .addMBB(FBB)
        .addImm(BRIG_TYPE_NONE);

    ++Count;
  }

  return Count;
}

unsigned int HSAILInstrInfo::RemoveBranch(MachineBasicBlock &MBB) const {
  MachineBasicBlock::iterator I = MBB.end();
  unsigned Count = 0;

  while (I != MBB.begin()) {
    --I;
    if (I->isDebugValue())
      continue;

    if (I->getOpcode() != HSAIL::BR && I->getOpcode() != HSAIL::CBR)
      break;

    // Remove the branch.
    I->eraseFromParent();
    I = MBB.end();
    ++Count;
  }

  return Count;
}

void HSAILInstrInfo::storeRegToStackSlot(MachineBasicBlock &MBB,
                                         MachineBasicBlock::iterator MI,
                                         unsigned SrcReg, bool isKill,
                                         int FrameIndex,
                                         const TargetRegisterClass *RC,
                                         const TargetRegisterInfo *TRI) const {
  unsigned int Opc = 0;
  MachineFunction &MF = *MBB.getParent();
  MachineFrameInfo &MFI = *MF.getFrameInfo();
  DebugLoc DL;

  unsigned BT;
  switch (RC->getID()) {
  default:
    llvm_unreachable("unrecognized TargetRegisterClass");
    break;
  case HSAIL::GPR32RegClassID:
    Opc = HSAIL::ST_U32;
    BT = BRIG_TYPE_U32;
    break;
  case HSAIL::GPR64RegClassID:
    Opc = HSAIL::ST_U64;
    BT = BRIG_TYPE_U64;
    break;
  case HSAIL::CRRegClassID: {
    HSAILMachineFunctionInfo *MFI = MF.getInfo<HSAILMachineFunctionInfo>();
    MFI->setHasSpilledCRs();
    Opc = HSAIL::SPILL_B1;
    BT = BRIG_TYPE_B1;
    break;
  }
  }
  if (MI != MBB.end()) {
    DL = MI->getDebugLoc();
  }

  switch (RC->getID()) {
  default:
    llvm_unreachable("unrecognized TargetRegisterClass");
    break;
  case HSAIL::CRRegClassID:
  case HSAIL::GPR32RegClassID:
  case HSAIL::GPR64RegClassID: {
    MachineMemOperand *MMO = MF.getMachineMemOperand(
        MachinePointerInfo::getFixedStack(FrameIndex),
        MachineMemOperand::MOStore, MFI.getObjectSize(FrameIndex),
        MFI.getObjectAlignment(FrameIndex));

    BuildMI(MBB, MI, DL, get(Opc))
        .addReg(SrcReg, getKillRegState(isKill)) // src
        .addFrameIndex(FrameIndex)               // address_base
        .addReg(HSAIL::NoRegister)               // address_reg
        .addImm(0)                               // address_offset
        .addImm(BT)                              // TypeLength
        .addImm(HSAILAS::SPILL_ADDRESS)          // segment
        .addImm(MMO->getAlignment())
        .addMemOperand(MMO);
    break;
  }
  }
}

void HSAILInstrInfo::loadRegFromStackSlot(MachineBasicBlock &MBB,
                                          MachineBasicBlock::iterator MI,
                                          unsigned DestReg, int FrameIndex,
                                          const TargetRegisterClass *RC,
                                          const TargetRegisterInfo *TRI) const {
  unsigned int Opc = 0;
  MachineFunction &MF = *MBB.getParent();
  MachineFrameInfo &MFI = *MF.getFrameInfo();
  DebugLoc DL;

  unsigned BT;
  switch (RC->getID()) {
  default:
    llvm_unreachable("unrecognized TargetRegisterClass");
    break;
  case HSAIL::GPR32RegClassID:
    Opc = HSAIL::LD_U32;
    BT = BRIG_TYPE_U32;
    break;
  case HSAIL::GPR64RegClassID:
    Opc = HSAIL::LD_U64;
    BT = BRIG_TYPE_U64;
    break;
  case HSAIL::CRRegClassID:
    Opc = HSAIL::RESTORE_B1;
    BT = BRIG_TYPE_B1;
    break;
  }
  if (MI != MBB.end()) {
    DL = MI->getDebugLoc();
  }

  switch (RC->getID()) {
  default:
    llvm_unreachable("unrecognized TargetRegisterClass");
    break;
  case HSAIL::GPR32RegClassID:
  case HSAIL::GPR64RegClassID:
  case HSAIL::CRRegClassID: {
    MachineMemOperand *MMO = MF.getMachineMemOperand(
        MachinePointerInfo::getFixedStack(FrameIndex),
        MachineMemOperand::MOLoad, MFI.getObjectSize(FrameIndex),
        MFI.getObjectAlignment(FrameIndex));
    BuildMI(MBB, MI, DL, get(Opc))
        .addReg(DestReg, RegState::Define) // dest
        .addFrameIndex(FrameIndex)         // address_base
        .addReg(HSAIL::NoRegister)         // address_reg
        .addImm(0)                         // address_offset
        .addImm(BT)                        // TypeLength
        .addImm(HSAILAS::SPILL_ADDRESS)    // segment
        .addImm(MMO->getAlignment())       // align
        .addImm(BRIG_WIDTH_1)              // width
        .addImm(0)                         // mask
        .addMemOperand(MMO);
    break;
  }
  }
}

bool HSAILInstrInfo::areLoadsFromSameBasePtr(SDNode *Node1, SDNode *Node2,
                                             int64_t &Offset1,
                                             int64_t &Offset2) const {
  // Warning! This function will handle not only load but store nodes too
  // because there is no real difference between memory operands in loads and
  // stores.
  // Do not change name of this function to avoid more changes in core llvm.

  if (!Node1->isMachineOpcode() || !Node2->isMachineOpcode())
    return false;

  MachineSDNode *mnode1 = cast<MachineSDNode>(Node1),
                *mnode2 = cast<MachineSDNode>(Node2);

  if (mnode1->memoperands_empty() || mnode2->memoperands_empty())
    return false;

  if ((mnode1->memoperands_begin() + 1) != mnode1->memoperands_end() ||
      (mnode2->memoperands_begin() + 1) != mnode2->memoperands_end())
    return false;

  MachineMemOperand *mo1, *mo2;

  mo1 = *mnode1->memoperands_begin();
  mo2 = *mnode2->memoperands_begin();

  // TODO_HSA: Consider extension types to be checked explicitly
  if (mo1->getSize() != mo2->getSize() ||
      mo1->getPointerInfo().getAddrSpace() !=
          mo2->getPointerInfo().getAddrSpace() ||
      mo1->getValue() != mo2->getValue() ||
      mo1->getFlags() != mo2->getFlags()) {
    return false;
  }

  Offset1 = mo1->getOffset();
  Offset2 = mo2->getOffset();

  return true;
}

bool HSAILInstrInfo::shouldScheduleLoadsNear(SDNode *Node1, SDNode *Node2,
                                             int64_t Offset1, int64_t Offset2,
                                             unsigned NumLoads) const {
  // Warning! This function will handle not only load but store nodes too
  // because there is no real difference between memory operands in loads and
  // stores.

  // Assume that 'areLoadsFromSameBasePtr' returned true

  if (!Node1->isMachineOpcode())
    return false;

  MachineSDNode *mnode1 = cast<MachineSDNode>(Node1);

  // Check that loads are close enough
  if (Offset2 - Offset1 <=
      4 * (int64_t)(*mnode1->memoperands_begin())->getSize())
    return true;
  return false;
}

bool HSAILInstrInfo::ReverseBranchCondition(
    SmallVectorImpl<MachineOperand> &Cond) const {
  if (Cond.size() < 2)
    return true;

  // AnalyzeBranch should always return conditions as pairs
  assert(Cond.size() % 2 == 0);

  for (SmallVectorImpl<MachineOperand>::iterator I = Cond.begin(),
                                                 E = Cond.end();
       I != E; ++I) {
    ++I;
    if (static_cast<CondReverseFlag>(I->getImm()) == COND_IRREVERSIBLE)
      return true;
  }

  for (SmallVectorImpl<MachineOperand>::iterator I = Cond.begin(),
                                                 E = Cond.end();
       I != E; ++I) {
    ++I;

    assert(I->isImm());

    CondReverseFlag cond_rev_flag = static_cast<CondReverseFlag>(I->getImm());

    switch (cond_rev_flag) {
    case COND_REVERSE_POSITIVE:
      cond_rev_flag = COND_REVERSE_NEGATIVE;
      break;
    case COND_REVERSE_NEGATIVE:
      cond_rev_flag = COND_REVERSE_POSITIVE;
      break;
    case COND_REVERSE_DEPENDANT:
      cond_rev_flag = COND_REVERSE_DEPENDANT;
      break;
    default:
      llvm_unreachable("Unknown cond reverse flag");
    }

    I->setImm(cond_rev_flag);
  }

  return false;
}

bool HSAILInstrInfo::isSafeToMoveRegClassDefs(
    const TargetRegisterClass *RC) const {
  // Micah: HSAIL does not have any constraints about moving defs.
  return true;
}

void HSAILInstrInfo::copyPhysReg(MachineBasicBlock &MBB,
                                 MachineBasicBlock::iterator MI, DebugLoc DL,
                                 unsigned DestReg, unsigned SrcReg,
                                 bool KillSrc) const {
  if (HSAIL::GPR32RegClass.contains(DestReg, SrcReg)) {
    BuildMI(MBB, MI, DL, get(HSAIL::MOV_B32), DestReg)
        .addReg(SrcReg, getKillRegState(KillSrc))
        .addImm(BRIG_TYPE_B32);
    return;
  }

  if (HSAIL::GPR64RegClass.contains(DestReg, SrcReg)) {
    BuildMI(MBB, MI, DL, get(HSAIL::MOV_B64), DestReg)
        .addReg(SrcReg, getKillRegState(KillSrc))
        .addImm(BRIG_TYPE_B64);
    return;
  }

  if (HSAIL::CRRegClass.contains(DestReg, SrcReg)) {
    BuildMI(MBB, MI, DL, get(HSAIL::MOV_B1), DestReg)
        .addReg(SrcReg, getKillRegState(KillSrc))
        .addImm(BRIG_TYPE_B1);
    return;
  }

  unsigned SrcBT = -1;
  unsigned DestBT = -1;
  unsigned CvtOpc = -1;

  if (HSAIL::GPR32RegClass.contains(DestReg) &&
      HSAIL::CRRegClass.contains(SrcReg)) {
    DestBT = BRIG_TYPE_B1;
    SrcBT = BRIG_TYPE_U32;
    CvtOpc = HSAIL::CVT_B1_U32;
  } else if (HSAIL::CRRegClass.contains(DestReg) &&
             HSAIL::GPR32RegClass.contains(SrcReg)) {
    DestBT = BRIG_TYPE_U32;
    SrcBT = BRIG_TYPE_B1;
    CvtOpc = HSAIL::CVT_U32_B1;
  } else if (HSAIL::GPR64RegClass.contains(DestReg) &&
             HSAIL::GPR32RegClass.contains(SrcReg)) {
    DestBT = BRIG_TYPE_U32;
    SrcBT = BRIG_TYPE_U64;
    CvtOpc = HSAIL::CVT_U32_U64;
  } else if (HSAIL::GPR32RegClass.contains(DestReg) &&
             HSAIL::GPR64RegClass.contains(SrcReg)) {
    // Truncation can occur if a function was defined with different return
    // types in different places.
    DestBT = BRIG_TYPE_U64;
    SrcBT = BRIG_TYPE_U32;
    CvtOpc = HSAIL::CVT_U64_U32;
  } else {
    assert(!"When do we hit this?");
    return TargetInstrInfo::copyPhysReg(MBB, MI, DL, DestReg, SrcReg, KillSrc);
  }

  BuildMI(MBB, MI, DL, get(CvtOpc), DestReg)
      .addImm(0)      // ftz
      .addImm(0)      // round
      .addImm(DestBT) // destTypedestLength
      .addImm(SrcBT)  // srcTypesrcLength
      .addReg(SrcReg, getKillRegState(KillSrc));
}

bool HSAILInstrInfo::expandPostRAPseudo(
    MachineBasicBlock::iterator MBBI) const {
  MachineInstr &MI = *MBBI;
  return HSAILGenInstrInfo::expandPostRAPseudo(MI);
}

const TargetRegisterClass *
HSAILInstrInfo::getOpRegClass(const MachineRegisterInfo &MRI,
                              const MachineInstr &MI, unsigned OpNo) const {

  const MachineOperand &MO = MI.getOperand(OpNo);
  if (!MO.isReg())
    return nullptr;

  unsigned Reg = MO.getReg();
  if (TargetRegisterInfo::isVirtualRegister(Reg))
    return MRI.getRegClass(Reg);

  return RI.getPhysRegClass(Reg);
}

bool HSAILInstrInfo::verifyInstruction(const MachineInstr *MI,
                                       StringRef &ErrInfo) const {
  return true;
}

MachineOperand *HSAILInstrInfo::getNamedOperand(MachineInstr &MI,
                                                unsigned OperandName) const {
  int Idx = HSAIL::getNamedOperandIdx(MI.getOpcode(), OperandName);
  if (Idx == -1)
    return nullptr;

  return &MI.getOperand(Idx);
}
}

// FIXME: Should just use generated version directly.
int HSAIL::getVectorLdStOpcode(uint16_t Opcode, unsigned vsize) {
  // HSAIL::vec_size enum is generated from instruction mappings and defined in
  // HSAILGenInstrInfo.inc. It starts with vec_size_1 value which is equal to
  // zero, so we need to subtract one from size.
  return HSAIL::getLdStVectorOpcode(Opcode, HSAIL::vec_size(vsize - 1));
}
