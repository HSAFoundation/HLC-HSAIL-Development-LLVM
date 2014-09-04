//===- HSAILInstrInfo.cpp - HSAIL Instruction Information ----------------===//
//
// This file contains the HSAIL implementation of the TargetInstrInfo class.
//
//===---------------------------------------------------------------------===//

#include <queue>
#include "HSAILTargetMachine.h"
#include "HSAILInstrInfo.h"
#include "HSAILUtilityFunctions.h"
#include "llvm/Instructions.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/MachineMemOperand.h"
#include "llvm/CodeGen/PseudoSourceValue.h"
#include "llvm/CodeGen/RegisterScavenging.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Analysis/Verifier.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/Pass.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "libHSAIL/Brig.h"

#define GET_INSTRINFO_CTOR
#define GET_INSTRINFO_MC_DESC
//#define GET_INSTRINFO_ENUM
#include "HSAILGenInstrInfo.inc"
using namespace llvm;
namespace llvm {

static cl::opt<bool> DisableBranchAnalysis("disable-branch-analysis", 
  cl::Hidden, cl::desc("Disable branch analysis"));
static cl::opt<bool> DisableCondReversion("disable-branch-cond-reversion", 
  cl::Hidden, cl::desc("Disable branch condition reversion"));

// Reverse conditions in branch analysis
// It marks whether or not we need to reverse condition
// when we insert new branch
enum CondReverseFlag {
  COND_IRREVERSIBLE,      // For branches that can not be reversed
  COND_REVERSE_POSITIVE,  // Don't need invertion
  COND_REVERSE_NEGATIVE,  // Need invertion
  COND_REVERSE_DEPENDANT  // Indicates that this condition has exactly 
                          // one depency which should be reverted with it
};

static unsigned int getMoveInstFromID(unsigned int ID) {
  switch (ID) {
  default:
    assert(0 && "Passed in ID does not match any move instructions.");
  case HSAIL::CRRegClassID:
    return HSAIL::mov_r_b1;
  case HSAIL::GPR32RegClassID:
    return HSAIL::mov_r_b32;
  case HSAIL::GPR64RegClassID:
    return HSAIL::mov_r_b64;
  };
  return -1;
}

HSAILInstrInfo::HSAILInstrInfo(HSAILTargetMachine &tm)
  : HSAILGenInstrInfo(),
//  : TargetInstrInfoImpl(HSAILInsts, array_lengthof(HSAILInsts)),
    TM(tm),
    RI(tm, *this)
{
  RS = new RegScavenger();
}

HSAILInstrInfo::~HSAILInstrInfo()
{
  delete RS;
}

/// Return true if the instruction is a register to register move and leave the
/// source and dest operands in the passed parameters.
bool
HSAILInstrInfo::isMoveInstr(const MachineInstr &MI,
                            unsigned int &SrcReg,
                            unsigned int &DstReg,
                            unsigned int &SrcSubIdx,
                            unsigned int &DstSubIdx) const
{
  return (
         MI.getOpcode() == HSAIL::mov_r_b1
      || MI.getOpcode() == HSAIL::mov_r_b32
      || MI.getOpcode() == HSAIL::mov_r_b64
      || MI.getOpcode() == HSAIL::mov_i_b1
      || MI.getOpcode() == HSAIL::mov_i_u32
      || MI.getOpcode() == HSAIL::mov_i_u64
      || MI.getOpcode() == HSAIL::mov_i_f64
      || MI.getOpcode() == HSAIL::mov_i_f32
      );
}

bool
HSAILInstrInfo::isCoalescableExtInstr(const MachineInstr &MI,
                                      unsigned &SrcReg,
                                      unsigned &DstReg,
                                      unsigned &SubIdx) const
{
  // HSAIL does not have any registers that overlap and cause
  // an extension.
  return false;
}

unsigned
HSAILInstrInfo::isLoadFromStackSlot(const MachineInstr *MI,
                                    int &FrameIndex) const
{
  switch (MI->getOpcode()) {
  default:
    return 0;
  case HSAIL::spill_ld_u32_v1:
  case HSAIL::spill_ld_u64_v1:
  case HSAIL::spill_ld_b1:
    for (unsigned i = 0, e = MI->getNumOperands(); i != e; ++i) {
      if (MI->getOperand(i).isFI()) {
        FrameIndex = MI->getOperand(i).getIndex();
        return MI->getOperand(0).getReg();
      }
    }
    break;
  }
  return 0;
}

unsigned
HSAILInstrInfo::isLoadFromStackSlotPostFE(const MachineInstr *MI,
                                          int &FrameIndex) const
{
  return isLoadFromStackSlot(MI, FrameIndex);
}

bool
HSAILInstrInfo::hasLoadFromStackSlot(const MachineInstr *MI,
                                     const MachineMemOperand *&MMO,
                                     int &FrameIndex) const
{
  return TargetInstrInfoImpl::hasLoadFromStackSlot(MI, MMO, FrameIndex);
}

unsigned
HSAILInstrInfo::isStoreToStackSlot(const MachineInstr *MI,
                                   int &FrameIndex) const
{
  switch (MI->getOpcode()) {
  default:
    return 0;
  case HSAIL::spill_st_u32_v1:
  case HSAIL::spill_st_u64_v1:
  case HSAIL::spill_st_b1:
    for (unsigned i = 0, e = MI->getNumOperands(); i != e; ++i) {
      if (MI->getOperand(i).isFI()) {
        FrameIndex = MI->getOperand(i).getIndex();
        return MI->getOperand(0).getReg();
      }
    }
    break;
  }
  return 0;
}

unsigned
HSAILInstrInfo::isStoreToStackSlotPostFE(const MachineInstr *MI,
                                           int &FrameIndex) const
{
  return isStoreToStackSlot(MI, FrameIndex);
}

bool
HSAILInstrInfo::hasStoreToStackSlot(const MachineInstr *MI,
                                      const MachineMemOperand *&MMO,
                                      int &FrameIndex) const
{
  return TargetInstrInfoImpl::hasStoreToStackSlot(MI, MMO, FrameIndex);
}
MachineInstr*
HSAILInstrInfo::convertToThreeAddress(MachineFunction::iterator &MFI,
                                      MachineBasicBlock::iterator &MBBI,
                                      LiveVariables *LV) const
{
  return TargetInstrInfoImpl::convertToThreeAddress(MFI, MBBI, LV);
}

bool
HSAILInstrInfo::getNextBranchInstr(MachineBasicBlock::iterator &iter,
                                   MachineBasicBlock &MBB) const
{
  //return TargetInstrInfo::getNextBranchInstr(iter, MBB);
  return false;
}

static bool
IsDefBeforeUse(MachineBasicBlock &MBB, unsigned Reg, 
  const MachineRegisterInfo &MRI,
  bool &CanReverse)
{
  // TODO_HSA: With LiveVariable analysis we can make it
  // a lot more effectively.
  // But currently we can not rely on any of the analysis results
  // In latest llvm exist MRI::tracksLiveness flag
  // if it is true we don't need this costly bfs search

  CanReverse = true;

  if (MRI.hasOneUse(Reg))
    return true;

  std::queue<MachineBasicBlock *> Q;
  SmallPtrSet<MachineBasicBlock*, 32> Visited;

  Q.push(&MBB);

  while (!Q.empty())
  {
    MachineBasicBlock *cur_mbb = Q.front();
    Q.pop();

    for (MachineBasicBlock::succ_iterator succ = cur_mbb->succ_begin(),
         succ_end = cur_mbb->succ_end(); succ != succ_end; ++succ)
      if (!Visited.count(*succ))
      {
        Visited.insert(*succ);

        bool need_process_futher = true;
        
        // Process basic block
        for (MachineBasicBlock::iterator instr = (*succ)->begin(),
             instr_end = (*succ)->end(); instr != instr_end; ++instr)
        {
          if (instr->readsRegister(Reg))
          {
            // Always abort on circular dependencies
            // Which will require to insert or remove not
            if (instr->getParent() == &MBB && 
                (instr->isBranch() ||
                 instr->getOpcode() == HSAIL::not_b1))
            {
              CanReverse = false;
            }

            return false;
          }
          if (instr->definesRegister(Reg))
          {
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

static bool
CheckSpillAfterDef(MachineInstr * start, unsigned reg, bool& canBeSpilled)
{
  MachineBasicBlock * MBB = start->getParent();
  MachineBasicBlock::reverse_iterator B(start);
  MachineBasicBlock::reverse_iterator E = MBB->rend();
  if (E == B) return false; // empty block check
  ++B; // skip branch instr itself
  for (MachineBasicBlock::reverse_iterator I = B; I != E; ++I) {
    if (I->definesRegister(reg))
    {
      return true;
    }
    if (I->readsRegister(reg) && (isConv(&*I) || I->mayStore())) {
      canBeSpilled = true;
      return true;
    }
  }
  return false;
}

static bool
IsSpilledAfterDef(MachineInstr * start, unsigned reg)
{
  bool canBeSpilled = false;
  if (!CheckSpillAfterDef(start, reg, canBeSpilled))
  {
    std::queue<MachineBasicBlock *> Q;
    SmallPtrSet<MachineBasicBlock*, 32> Visited;
    MachineBasicBlock * MBB = start->getParent();
    Q.push(MBB);
    while (!Q.empty() && !canBeSpilled)
    {
      MachineBasicBlock *cur_mbb = Q.front();
      Q.pop();
      for (MachineBasicBlock::pred_iterator pred = cur_mbb->pred_begin(),
        pred_end = cur_mbb->pred_end(); pred != pred_end; ++pred)
      {
        if (!Visited.count(*pred) && !(*pred)->empty())
        {
          Visited.insert(*pred);
          MachineInstr * instr;
          MachineBasicBlock::instr_iterator termIt = (*pred)->getFirstInstrTerminator();
          if (termIt == (*pred)->instr_end())
          {
            instr =  &*(*pred)->rbegin();
          } else {
            instr = termIt;
          }
          if (!CheckSpillAfterDef(instr, reg, canBeSpilled))
          {
            Q.push(*pred);
          }
        }
      }
    }
  }
  return canBeSpilled;
}

bool
HSAILInstrInfo::AnalyzeBranch(MachineBasicBlock &MBB,
                              MachineBasicBlock *&TBB,
                              MachineBasicBlock *&FBB,
                              SmallVectorImpl<MachineOperand> &Cond,
                              bool AllowModify,
                              bool IgnoreDependencies) const
{
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

    // Don't know anything about indirect branches.
    if (I->getOpcode() == HSAIL::branch_ind)
      return true;

    // Handle unconditional branches.
    if (I->getOpcode() == HSAIL::branch) {
      UnCondBrIter = I;

      Cond.clear();
      FBB = 0;

      if (!AllowModify) {
        TBB = I->getOperand(0).getMBB();
        continue;
      }

      // If the block has any instructions after a JMP, delete them.
      while (llvm::next(I) != MBB.end())
        llvm::next(I)->eraseFromParent();

      // Delete the JMP if it's equivalent to a fall-through.
      if (MBB.isLayoutSuccessor(I->getOperand(0).getMBB())) {
        TBB = 0;
        I->eraseFromParent();
        I = MBB.end();
        UnCondBrIter = MBB.end();
        continue;
      }

      // TBB is used to indicate the unconditional destination.
      TBB = I->getOperand(0).getMBB();
      continue;
    }

    // Handle conditional branches.

    // First conditional branch
    if (Cond.empty()) 
    {
      MachineBasicBlock *TargetBB = I->getOperand(1).getMBB();

      FBB = TBB;
      TBB = I->getOperand(1).getMBB();

      // Insert condition as pair - (register, reverse flag)
      // Or in case if there is dependencies
      // (register, COND_REVERSE_DEPENDANT, free reg num, reverse flag)
      Cond.push_back(I->getOperand(0));

      if (DisableCondReversion)
      {
        Cond.push_back(MachineOperand::CreateImm(COND_IRREVERSIBLE));
        continue;
      }

      // Determine condition dependencies
      unsigned reg = I->getOperand(0).getReg();
      bool can_reverse = false;
      bool is_def_before_use = IsDefBeforeUse(MBB, reg, MRI, can_reverse);
      if (can_reverse)
      {
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
      if (!can_reverse)
      {
        Cond.push_back(MachineOperand::CreateImm(COND_IRREVERSIBLE));
        continue;
      }

      // If there is no uses of condition register we can just reverse 
      // instruction and be fine
      if (is_def_before_use)
      {
        Cond.push_back(MachineOperand::CreateImm(COND_REVERSE_POSITIVE));
        continue;
      }

      // There is uses of this instruction somewhere down the control flow
      // Try to use RegisterScavenger to get free register
      // If there is no such one than do not inverse condition
      if (!MRI.tracksLiveness())
      {
        Cond.push_back(MachineOperand::CreateImm(COND_IRREVERSIBLE));
        continue;
      }

      unsigned free_reg = 0;
      if (!TargetRegisterInfo::isVirtualRegister(Cond[0].getReg()))
      {
        RS->enterBasicBlock(&MBB);
        RS->forward(prior(MBB.end()));

        free_reg = RS->FindUnusedReg(&HSAIL::CRRegClass);
        if (free_reg == 0)
        {
          Cond.push_back(MachineOperand::CreateImm(COND_IRREVERSIBLE));
          continue;
        }
        RS->setUsed(free_reg);
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

unsigned int
HSAILInstrInfo::getBranchInstr(const MachineOperand &op) const
{
  //return TargetInstrInfoImpl::getBranchInstr(op);
  return 0;
}

static unsigned short
ReverseConditionOpcode( unsigned short OpCode, bool &IsOk )
{
  IsOk = true;
#define REVERSE_OPCODE(op_name, rev_op_name, op_type) \
  case HSAIL::cmp_i1_##op_name##_##op_type##_rr: return HSAIL::cmp_i1_##rev_op_name##_##op_type##_rr; \
  case HSAIL::cmp_i1_##op_name##_##op_type##_ri: return HSAIL::cmp_i1_##rev_op_name##_##op_type##_ri; \
  case HSAIL::cmp_i32_##op_name##_##op_type##_rr: return HSAIL::cmp_i32_##rev_op_name##_##op_type##_rr; \
  case HSAIL::cmp_i32_##op_name##_##op_type##_ri: return HSAIL::cmp_i32_##rev_op_name##_##op_type##_ri; \
  case HSAIL::cmp_i64_##op_name##_##op_type##_rr: return HSAIL::cmp_i64_##rev_op_name##_##op_type##_rr; \
  case HSAIL::cmp_i64_##op_name##_##op_type##_ri: return HSAIL::cmp_i64_##rev_op_name##_##op_type##_ri

  switch (OpCode)
  {
  REVERSE_OPCODE(eq, ne, i1);
  REVERSE_OPCODE(eq, ne, i32);
  REVERSE_OPCODE(eq, ne, i64);
  
  REVERSE_OPCODE(ge, lt, i32);
  REVERSE_OPCODE(ge, lt, i64);
  REVERSE_OPCODE(uge, ult, i32);
  REVERSE_OPCODE(uge, ult, i64);

  REVERSE_OPCODE(gt, le, i32);
  REVERSE_OPCODE(gt, le, i64);
  REVERSE_OPCODE(ugt, ule, i32);
  REVERSE_OPCODE(ugt, ule, i64);

  REVERSE_OPCODE(le, gt, i32);
  REVERSE_OPCODE(le, gt, i64);
  REVERSE_OPCODE(ule, ugt, i32);
  REVERSE_OPCODE(ule, ugt, i64);

  REVERSE_OPCODE(lt, ge, i32);
  REVERSE_OPCODE(lt, ge, i64);
  REVERSE_OPCODE(ult, uge, i32);
  REVERSE_OPCODE(ult, uge, i64);

  REVERSE_OPCODE(ne, eq, i1);
  REVERSE_OPCODE(ne, eq, i32);
  REVERSE_OPCODE(ne, eq, i64);

  REVERSE_OPCODE(o, uo, f32);
  REVERSE_OPCODE(o, uo, f64);

  REVERSE_OPCODE(oeq, une, f32);
  REVERSE_OPCODE(oeq, une, f64);

  REVERSE_OPCODE(oge, ult, f32);
  REVERSE_OPCODE(oge, ult, f64);

  REVERSE_OPCODE(ogt, ule, f32);
  REVERSE_OPCODE(ogt, ule, f64);

  REVERSE_OPCODE(ole, ugt, f32);
  REVERSE_OPCODE(ole, ugt, f64);

  REVERSE_OPCODE(olt, uge, f32);
  REVERSE_OPCODE(olt, uge, f64);

  REVERSE_OPCODE(one, ueq, f32);
  REVERSE_OPCODE(one, ueq, f64);

  REVERSE_OPCODE(eq, ne, f32);
  REVERSE_OPCODE(eq, ne, f64);

  REVERSE_OPCODE(ge, lt, f32);
  REVERSE_OPCODE(ge, lt, f64);

  REVERSE_OPCODE(gt, le, f32);
  REVERSE_OPCODE(gt, le, f64);

  REVERSE_OPCODE(le, gt, f32);
  REVERSE_OPCODE(le, gt, f64);

  REVERSE_OPCODE(lt, ge, f32);
  REVERSE_OPCODE(lt, ge, f64);

  REVERSE_OPCODE(ne, eq, f32);
  REVERSE_OPCODE(ne, eq, f64);

  REVERSE_OPCODE(ueq, one, f32);
  REVERSE_OPCODE(ueq, one, f64);

  REVERSE_OPCODE(uge, olt, f32);
  REVERSE_OPCODE(uge, olt, f64);

  REVERSE_OPCODE(ugt, ole, f32);
  REVERSE_OPCODE(ugt, ole, f64);

  REVERSE_OPCODE(ule, ogt, f32);
  REVERSE_OPCODE(ule, ogt, f64);

  REVERSE_OPCODE(ult, oge, f32);
  REVERSE_OPCODE(ult, oge, f64);

  REVERSE_OPCODE(une, oeq, f32);
  REVERSE_OPCODE(une, oeq, f64);

  REVERSE_OPCODE(uo, o, f32);
  REVERSE_OPCODE(uo, o, f64);

  default: 
    assert(!"Unknown comparison opcode");
    IsOk = false;
  }

#undef REVERSE_OPCODE

  return 0;
}

// Helper for `HSAILInstrInfo::InsertBranch`
// Reverse branch condition 
// Different from `HSAILInstrInfo::ReverseBranchCondition`
// because it actually generates reversion code 
// Returns register with condition result
static unsigned GenerateBranchCondReversion( 
  MachineBasicBlock &MBB, 
  const MachineOperand &CondOp,
  const HSAILInstrInfo *TII,
  DebugLoc DL)
{
  assert(CondOp.isReg());
  unsigned cond_reg = CondOp.getReg();

  MachineRegisterInfo &MRI = MBB.getParent()->getRegInfo();

  MachineInstr *cond_expr = NULL;

  // Manualy search for latest usage of condition register in MBB
  MachineBasicBlock::iterator I = MBB.end();

  while (I != MBB.begin()) 
  {
    --I;

    if (I->definesRegister(cond_reg))
    {
      cond_expr = &*I;
      break;
    }
  }

  // If condition is compare instruction - reverse it
  bool need_insert_not = false;
  if (cond_expr && cond_expr->getDesc().isCompare())
  {   
    bool can_reverse = false;
    unsigned short reversed_opcode = 
      ReverseConditionOpcode(cond_expr->getOpcode(), can_reverse);
      
    if (can_reverse)
      cond_expr->setDesc(TII->get(reversed_opcode));
    else
      need_insert_not = true;
  }
  // If condition is logical not - just remove it
  else if (cond_expr && cond_expr->getOpcode() == HSAIL::not_b1)
  {
    cond_reg = cond_expr->getOperand(1).getReg();
    cond_expr->eraseFromParent();
  }
  else
    need_insert_not = true;
    
  // Else insert logical not
  if (need_insert_not)
  {
    // If we are before register allocation we need to maintain SSA form
    if (TargetRegisterInfo::isVirtualRegister(CondOp.getReg()))
      cond_reg = MRI.createVirtualRegister(MRI.getRegClass(CondOp.getReg()));

    BuildMI(&MBB, DL, TII->get(HSAIL::not_b1))
      .addReg(cond_reg, RegState::Define)
      .addReg(CondOp.getReg());
  }

  return cond_reg;
}

unsigned
HSAILInstrInfo::InsertBranch(MachineBasicBlock &MBB,
                             MachineBasicBlock *TBB,
                             MachineBasicBlock *FBB,
                             const SmallVectorImpl<MachineOperand> &Cond,
                             DebugLoc DL) const
{
  // Shouldn't be a fall through.
  assert(TBB && "InsertBranch must not be told to insert a fallthrough");

  if (Cond.empty()) {
    // Unconditional branch?
    assert(!FBB && "Unconditional branch with multiple successors!");
    BuildMI(&MBB, DL, get(HSAIL::branch)).addMBB(TBB);
    return 1;
  }

  // AnalyzeBranch can handle only one condition
  if (Cond.size() != 2 &&
      Cond.size() != 4)
    return 0;

  // Conditional branch.
  // According to HSAIL spec condition MUST be a control register
  assert(Cond[0].isReg());
  unsigned cond_reg = Cond[0].getReg();

  // Reverse condition
  switch (static_cast<CondReverseFlag>(Cond[1].getImm()))
  {
  case COND_REVERSE_DEPENDANT:
    assert(Cond.size() == 4 && Cond[2].isImm());

    if (Cond[3].getImm() == COND_REVERSE_NEGATIVE)
    {
      MachineRegisterInfo &MRI = MBB.getParent()->getRegInfo();
      if (TargetRegisterInfo::isVirtualRegister(Cond[0].getReg()))
        cond_reg = MRI.createVirtualRegister(MRI.getRegClass(Cond[0].getReg()));
      else
        cond_reg = Cond[2].getImm();

      BuildMI(&MBB, DL, get(HSAIL::not_b1))
        .addReg(cond_reg, RegState::Define)
        .addReg(Cond[0].getReg());
    }    
    
    break;
  case COND_REVERSE_NEGATIVE:
    cond_reg = GenerateBranchCondReversion(MBB, Cond[0], this, DL);
    break;
  case COND_REVERSE_POSITIVE:
  case COND_IRREVERSIBLE:
    // Do nothing
    break;
  default:
    llvm_unreachable("Unknown CondReverse code");
    return 0;
  }

  unsigned Count = 0;

  BuildMI(&MBB, DL, get(HSAIL::branch_cond)).addReg(cond_reg).addMBB(TBB);
  
  ++Count;

  if (FBB) {
    // Two-way Conditional branch. Insert the second branch.
    BuildMI(&MBB, DL, get(HSAIL::branch)).addMBB(FBB);
    ++Count;
  }

  return Count;
}

unsigned int
HSAILInstrInfo::RemoveBranch(MachineBasicBlock &MBB) const
{
  MachineBasicBlock::iterator I = MBB.end();
  unsigned Count = 0;

  while (I != MBB.begin()) {
    --I;
    if (I->isDebugValue())
      continue;
    
    if (I->getOpcode() != HSAIL::branch &&
        I->getOpcode() != HSAIL::branch_cond && 
        I->getOpcode() != HSAIL::branch_ind)
      break;

    // Remove the branch.
    I->eraseFromParent();
    I = MBB.end();
    ++Count;
  }

  return Count;
}

bool
HSAILInstrInfo::copyRegToReg(MachineBasicBlock &MBB,
                             MachineBasicBlock::iterator I,
                             unsigned DestReg, unsigned SrcReg,
                             const TargetRegisterClass *DestRC,
                             const TargetRegisterClass *SrcRC,
                             DebugLoc DL) const
{
  int movInst = getMoveInstFromID(DestRC->getID());

  if (DestRC != SrcRC) {
    assert(!"When do we hit this?");
  } else {
    BuildMI(MBB, I, DL, get(movInst), DestReg).addReg(SrcReg);
  }
  return true;
}

// Emergency spill frame indexes for functions
static DenseMap<const MachineFunction*, int> emergencyStackSlot;

// Creates or returns a 32 bit emergency frame index for a function
static int
getEmergencyStackSlot(MachineFunction* MF)
{
  if (emergencyStackSlot.find(MF) == emergencyStackSlot.end()) {
    emergencyStackSlot.insert(std::make_pair(MF,
      MF->getFrameInfo()->CreateSpillStackObject(HSAIL::GPR32RegClass.getSize(),
       HSAIL::GPR32RegClass.getAlignment())));
  }
  return emergencyStackSlot[MF];
}

void
HSAILInstrInfo::storeRegToStackSlot(MachineBasicBlock &MBB,
                                    MachineBasicBlock::iterator MI,
                                    unsigned SrcReg, 
                                    bool isKill,
                                    int FrameIndex,
                                    const TargetRegisterClass *RC,
                                    const TargetRegisterInfo *TRI) const
{
  unsigned int Opc = 0;
  MachineInstr *curMI = MI;
  MachineFunction &MF = *MBB.getParent();
  MachineFrameInfo &MFI = *MF.getFrameInfo();
  DebugLoc DL;
  const HSAILRegisterInfo *HRI = TM.getRegisterInfo();
  
  switch (RC->getID()) {
    default:
      assert(0 && "unrecognized TargetRegisterClass");
      break;
    case HSAIL::GPR32RegClassID:
      Opc = HSAIL::spill_st_u32_v1;
      break;
    case HSAIL::GPR64RegClassID:
      Opc = HSAIL::spill_st_u64_v1;
      break;
    case HSAIL::CRRegClassID:
      Opc = HSAIL::spill_st_b1;
      break;
  }
  if (MI != MBB.end()) {
    DL = MI->getDebugLoc();
  }

  MachineMemOperand *MMO;
  MachineInstr *nMI;
  switch (RC->getID()) {
    default:
      assert(0 && "unrecognized TargetRegisterClass");
      break;
    case HSAIL::CRRegClassID:
      // We may need a stack slot for spilling a temp GPR32 after expansion
      // of pseudo insns spill_st_b1/spill_ld_b1. After frame finalization
      // it will be too late to create it, so create it now.
      // Note, there is no need to do it in loadRegFromStackSlot() because
      // there is no spill load w/o a spill store.
      (void) getEmergencyStackSlot(&MF);
      // Fall through
    case HSAIL::GPR32RegClassID:
    case HSAIL::GPR64RegClassID:
      MMO = MF.getMachineMemOperand(
          MachinePointerInfo::getFixedStack(FrameIndex),
          MachineMemOperand::MOStore,
          MFI.getObjectSize(FrameIndex),
          MFI.getObjectAlignment(FrameIndex));
      nMI = BuildMI(MBB, MI, DL, get(Opc))
          .addReg(SrcReg, getKillRegState(isKill))
          .addFrameIndex(FrameIndex)
          .addReg(0)
          .addImm(0)
          .addImm(1)
          .addMemOperand(MMO);            
      break;
  }
}

void
HSAILInstrInfo::loadRegFromStackSlot(MachineBasicBlock &MBB,
                                     MachineBasicBlock::iterator MI,
                                     unsigned DestReg,
                                     int FrameIndex,
                                     const TargetRegisterClass *RC,
                                     const TargetRegisterInfo *TRI) const
{
  unsigned int Opc = 0;
  MachineInstr *curMI = MI;
  MachineFunction &MF = *MBB.getParent();
  MachineFrameInfo &MFI = *MF.getFrameInfo();
  DebugLoc DL;
  const HSAILRegisterInfo *HRI = TM.getRegisterInfo();

  switch (RC->getID()) {
    default:
      assert(0 && "unrecognized TargetRegisterClass");
      break;
    case HSAIL::GPR32RegClassID:
      Opc = HSAIL::spill_ld_u32_v1;
      break;
    case HSAIL::GPR64RegClassID:
      Opc = HSAIL::spill_ld_u64_v1;
      break;
    case HSAIL::CRRegClassID:
      Opc = HSAIL::spill_ld_b1;
      break;
  }
  if (MI != MBB.end()) {
    DL = MI->getDebugLoc();
  }
  MachineMemOperand *MMO;
  MachineInstr *nMI;
  switch (RC->getID()) {
    default:
      assert(0 && "unrecognized TargetRegisterClass");
      break;
    case HSAIL::GPR32RegClassID:
    case HSAIL::GPR64RegClassID:
    case HSAIL::CRRegClassID:
      MMO = MF.getMachineMemOperand(MachinePointerInfo::getFixedStack(FrameIndex),
        MachineMemOperand::MOLoad,
        MFI.getObjectSize(FrameIndex),
        MFI.getObjectAlignment(FrameIndex));
      nMI = BuildMI(MBB, MI, DL, get(Opc))
          .addReg(DestReg, RegState::Define)
          .addFrameIndex(FrameIndex)
          .addReg(0)
          .addImm(0)
          .addImm(Brig::BRIG_WIDTH_1)
          .addImm(1)
          .addImm(0)
          .addMemOperand(MMO);
      break;
  }
}

MachineInstr*
HSAILInstrInfo::foldMemoryOperandImpl(MachineFunction &MF,
                                      MachineInstr *MI,
                                      const SmallVectorImpl<unsigned> &Ops,
                                      int FrameIndex) const
{
  //TODO: Implement this function
  return NULL;
}

MachineInstr*
HSAILInstrInfo::foldMemoryOperandImpl(MachineFunction &MF,
                                      MachineInstr *MI,
                                      const SmallVectorImpl<unsigned> &Ops,
                                      MachineInstr *LoadMI) const
{
  //TODO: Implement this function
  return NULL;
}

bool
HSAILInstrInfo::canFoldMemoryOperand(const MachineInstr *MI,
                                     const SmallVectorImpl<unsigned> &Ops) 
                                     const
{
  //TODO: Implement this function
  return false;
}

bool
HSAILInstrInfo::unfoldMemoryOperand(MachineFunction &MF,
                                    MachineInstr *MI,
                                    unsigned Reg,
                                    bool UnfoldLoad,
                                    bool UnfoldStore,
                                    SmallVectorImpl<MachineInstr*> &NewMIs) 
                                    const
{
  //TODO: Implement this function
  return false;
}

bool
HSAILInstrInfo::unfoldMemoryOperand(SelectionDAG &DAG,
                                    SDNode *N,
                                    SmallVectorImpl<SDNode*> &NewNodes) const
{
  //TODO: Implement this function
  return false;
}

unsigned
HSAILInstrInfo::getOpcodeAfterMemoryUnfold(unsigned Opc,
                                           bool UnfoldLoad,
                                           bool UnfoldStore,
                                           unsigned *LoadRegIndex) const
{
  //TODO: Implement this function
  return 0;
}

bool
HSAILInstrInfo::areLoadsFromSameBasePtr(SDNode *Node1,
                                        SDNode *Node2,
                                        int64_t &Offset1,
                                        int64_t &Offset2) const
{ 
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
      mo1->getFlags() != mo2->getFlags())
  {
    return false;
  }

  Offset1 = mo1->getOffset();
  Offset2 = mo2->getOffset();

  return true;
}

bool
HSAILInstrInfo::shouldScheduleLoadsNear(SDNode *Node1,
                                        SDNode *Node2,
                                        int64_t Offset1,
                                        int64_t Offset2,
                                        unsigned NumLoads) const
{
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

bool
HSAILInstrInfo::shouldScheduleWithNormalPriority(SDNode* instruction) const
{
  return TargetInstrInfoImpl::shouldScheduleWithNormalPriority(instruction);
}

bool
HSAILInstrInfo::ReverseBranchCondition(SmallVectorImpl<MachineOperand> &Cond)
                                       const
{
  if (Cond.size() < 2)
    return true;

  // AnalyzeBranch should always return conditions as pairs
  assert(Cond.size() % 2 == 0);

  for (SmallVectorImpl<MachineOperand>::iterator I = Cond.begin(),
       E = Cond.end();
       I != E; ++I)
  {
    ++I;
    if (static_cast<CondReverseFlag>(I->getImm()) == COND_IRREVERSIBLE)
      return true;
  }


  for (SmallVectorImpl<MachineOperand>::iterator I = Cond.begin(),
       E = Cond.end();
       I != E; ++I)
  {
    ++I;

    assert(I->isImm());

    CondReverseFlag cond_rev_flag = static_cast<CondReverseFlag>(I->getImm());

    switch (cond_rev_flag)
    {
    case COND_REVERSE_POSITIVE: cond_rev_flag = COND_REVERSE_NEGATIVE; break;
    case COND_REVERSE_NEGATIVE: cond_rev_flag = COND_REVERSE_POSITIVE; break;
    case COND_REVERSE_DEPENDANT: cond_rev_flag = COND_REVERSE_DEPENDANT; break;
    default: llvm_unreachable("Unknown cond reverse flag");
    }

    I->setImm(cond_rev_flag);
  }

  return false;
}

void
HSAILInstrInfo::insertNoop(MachineBasicBlock &MBB,
                           MachineBasicBlock::iterator MI) const
{
  return TargetInstrInfoImpl::insertNoop(MBB, MI);
}

bool
HSAILInstrInfo::isPredicated(const MachineInstr *MI) const
{
  return TargetInstrInfoImpl::isPredicated(MI);
}

bool
HSAILInstrInfo::SubsumesPredicate(const SmallVectorImpl<MachineOperand> &Pred1,
                                  const SmallVectorImpl<MachineOperand> &Pred2)
                                  const
{
  return TargetInstrInfoImpl::SubsumesPredicate(Pred1, Pred2);
}

bool
HSAILInstrInfo::DefinesPredicate(MachineInstr *MI,
                                 std::vector<MachineOperand> &Pred) const
{
  return TargetInstrInfoImpl::DefinesPredicate(MI, Pred);
}

bool
HSAILInstrInfo::isPredicable(MachineInstr *MI) const
{
  return TargetInstrInfoImpl::isPredicable(MI);
}
bool
HSAILInstrInfo::isSafeToMoveRegClassDefs(const TargetRegisterClass *RC) const
{
  // Micah: HSAIL does not have any constraints about moving defs.
  return true;
}
unsigned
HSAILInstrInfo::GetInstSizeInBytes(const MachineInstr *MI) const
{
  return 0;
}

bool
HSAILInstrInfo::isReallyTriviallyReMaterializable(const MachineInstr *MI,
                                  AliasAnalysis *AA) const
{
  return TargetInstrInfoImpl::isReallyTriviallyReMaterializable(MI, AA);
}

void
HSAILInstrInfo::reMaterialize(MachineBasicBlock &MBB,
                              MachineBasicBlock::iterator MI,
                              unsigned DestReg, unsigned SubIdx,
                              const MachineInstr *Orig,
                              const TargetRegisterInfo &TRI) const
{
  return TargetInstrInfoImpl::reMaterialize(MBB, MI, DestReg, SubIdx, 
      Orig, TRI);
}

bool
HSAILInstrInfo::findCommutedOpIndices(MachineInstr *MI,
                      unsigned &SrcOpIdx1,
                      unsigned &SrcOpIdx2) const
{
  return TargetInstrInfoImpl::findCommutedOpIndices(MI, SrcOpIdx1, SrcOpIdx2);
}

bool
HSAILInstrInfo::produceSameValue(const MachineInstr *MI0,
                 const MachineInstr *MI1,
                 const MachineRegisterInfo *MRI) const
{
  return TargetInstrInfoImpl::produceSameValue(MI0, MI1, MRI);
}

MachineInstr*
HSAILInstrInfo::duplicate(MachineInstr *Orig,
                          MachineFunction &MF) const
{
  return TargetInstrInfoImpl::duplicate(Orig, MF);
}

MachineInstr*
HSAILInstrInfo::commuteInstruction(MachineInstr *MI,
                                   bool NewMI) const
{
  return TargetInstrInfoImpl::commuteInstruction(MI, NewMI);
}

void
HSAILInstrInfo::ReplaceTailWithBranchTo(MachineBasicBlock::iterator Tail,
                                        MachineBasicBlock *NewDest) const
{
  return TargetInstrInfoImpl::ReplaceTailWithBranchTo(Tail, NewDest);
}

bool
HSAILInstrInfo::isLegalToSplitMBBAt(MachineBasicBlock &MBB,
                                    MachineBasicBlock::iterator MBBI) const
{
  return TargetInstrInfoImpl::isLegalToSplitMBBAt(MBB, MBBI);
}

bool
HSAILInstrInfo::isProfitableToIfCvt(MachineBasicBlock &MBB,
                                    unsigned NumCycles,
                                    unsigned ExtraPredCycles,
                                    const BranchProbability &Probability) const
{
  return TargetInstrInfoImpl::isProfitableToIfCvt(MBB, NumCycles, 
      ExtraPredCycles, Probability);
}

bool
HSAILInstrInfo::isProfitableToIfCvt(MachineBasicBlock &TMBB,
                                    unsigned NumTCycles,
                                    unsigned ExtraTCycles,
                                    MachineBasicBlock &FMBB,
                                    unsigned NumFCycles,
                                    unsigned ExtraFCycles,
				    const BranchProbability &Probability) const
{
  return TargetInstrInfoImpl::isProfitableToIfCvt(TMBB, NumTCycles, 
      ExtraTCycles, FMBB, NumFCycles, ExtraFCycles, 
      Probability);
}

bool
HSAILInstrInfo::isProfitableToDupForIfCvt(MachineBasicBlock &MBB,
                                          unsigned NumCycles,
				    const BranchProbability &Probability) const
{
  return TargetInstrInfoImpl::isProfitableToDupForIfCvt(MBB, NumCycles, 
      Probability);
}

void
HSAILInstrInfo::copyPhysReg(MachineBasicBlock &MBB,
                            MachineBasicBlock::iterator MI,
                            DebugLoc DL,
                            unsigned DestReg,
                            unsigned SrcReg,
                            bool KillSrc) const
{
  unsigned Opc = 0;

  if (HSAIL::GPR64RegClass.contains(DestReg, SrcReg)) {
    Opc = HSAIL::mov_r_b64;
  } else if (HSAIL::GPR32RegClass.contains(DestReg, SrcReg)) {
    Opc = HSAIL::mov_r_b32;
  } else if (HSAIL::CRRegClass.contains(DestReg, SrcReg)) {
    Opc = HSAIL::mov_r_b1;
  } else if (HSAIL::GPR32RegClass.contains(DestReg) && 
             HSAIL::CRRegClass.contains(SrcReg)) {
    Opc = HSAIL::cvt_b1_u32;
  } else if (HSAIL::CRRegClass.contains(DestReg) && 
             HSAIL::GPR32RegClass.contains(SrcReg)) {
    Opc = HSAIL::cvt_u32_b1;
  } else if (HSAIL::GPR64RegClass.contains(DestReg) && 
             HSAIL::GPR32RegClass.contains(SrcReg)) {
    Opc = HSAIL::cvt_u32_u64;
  } else if (HSAIL::GPR32RegClass.contains(DestReg) &&
             HSAIL::GPR64RegClass.contains(SrcReg)) {
    // Truncation can occur if a function was defined with different return
    // types in different places.
    Opc = HSAIL::cvt_u64_u32;
  } else {
    assert(!"When do we hit this?");
    return TargetInstrInfoImpl::copyPhysReg(MBB, MI, DL, DestReg, SrcReg, 
        KillSrc);
  }

  BuildMI(MBB, MI, DL, get(Opc), DestReg)
    .addReg(SrcReg, getKillRegState(KillSrc));

}

MachineInstr*
HSAILInstrInfo::emitFrameIndexDebugValue(MachineFunction &MF,
                         int FrameIx,
                         uint64_t Offset,
                         const MDNode *MDPtr,
                         DebugLoc dl) const
{
  return TargetInstrInfoImpl::emitFrameIndexDebugValue(MF, FrameIx, Offset, 
      MDPtr, dl);
}

bool
HSAILInstrInfo::isUnpredicatedTerminator(const MachineInstr *MI) const
{
  return TargetInstrInfoImpl::isUnpredicatedTerminator(MI);
}

bool
HSAILInstrInfo::PredicateInstruction(MachineInstr *MI,
                                   const SmallVectorImpl<MachineOperand> &Pred)
                                   const
{
  return TargetInstrInfoImpl::PredicateInstruction(MI, Pred);
}

bool
HSAILInstrInfo::isSchedulingBoundary(const MachineInstr *MI,
                                     const MachineBasicBlock *MBB,
                                     const MachineFunction &MF) const
{
  return TargetInstrInfoImpl::isSchedulingBoundary(MI, MBB, MF);
}

unsigned
HSAILInstrInfo::getInlineAsmLength(const char *Str,
                                   const MCAsmInfo &MAI) const
{
  return TargetInstrInfoImpl::getInlineAsmLength(Str, MAI);
}
ScheduleHazardRecognizer*
HSAILInstrInfo::CreateTargetHazardRecognizer(const TargetMachine *TM,
                                             const ScheduleDAG *DAG) const
{
  // TODO: Need to add a real hazard recognizer so that we can make sure
  // certain instructions don't get scheduled back to back.
  return TargetInstrInfoImpl::
    CreateTargetHazardRecognizer(TM, DAG);
}
ScheduleHazardRecognizer*
HSAILInstrInfo::CreateTargetPostRAHazardRecognizer(
                                         const InstrItineraryData* IID,
                                         const ScheduleDAG *DAG) const
{
  // TODO: Need to add a real hazard recognizer so that we can make sure
  // certain instructions don't get scheduled back to back.
  return TargetInstrInfoImpl::
    CreateTargetPostRAHazardRecognizer(IID, DAG);
}

bool
HSAILInstrInfo::AnalyzeCompare(const MachineInstr *MI,
               unsigned &SrcReg,
               int &Mask,
               int &Value) const
{
  if (MI->getDesc().isCompare())
  {
    if (!MI->getOperand(0).isReg() || !MI->getOperand(0).isDef())
      return false;
    SrcReg = MI->getOperand(0).getReg();
    return true;
  }
  return true;
}

bool
HSAILInstrInfo::OptimizeCompareInstr(MachineInstr *CmpInstr,
                                     unsigned SrcReg,
                                     int Mask,
                                     int Value,
                                     const MachineRegisterInfo *MRI) const
{
  // Simplify constructions like this:
  //   cmp_gt $c0, $s2, $s1 ;
  //   cmov   $s1, $c0, -1, 0 ;
  //   cmp_eq $c0, $s1, 0 ;
  // Instead we should get:
  //   not cmp_gt $c0, $s2, $s1 ;

  if (!MRI->isSSA())
    return false;

  // Assume CmpInstr is the first instruction in our construction
  if (!CmpInstr->getDesc().isCompare())
    return false;

  // Check that there is only one user os SrcReg and it is 'cmov_ii c, -1, 0'
  if (!MRI->hasOneUse(SrcReg))
    return false;

  MachineInstr &cmov = *MRI->use_begin(SrcReg);
  if (cmov.getOpcode() != HSAIL::cmov_b32_i_ii &&
      cmov.getOpcode() != HSAIL::cmov_b64_i_ii)
    return false;

  if ((!cmov.getOperand(2).isImm() || !cmov.getOperand(3).isImm()) &&
      (cmov.getOperand(2).getImm() != -1 || cmov.getOperand(3).getImm() != 0))
    return false;

  // Check that there is only one user of cmov and it is cmp_eq or cmp_ne 
  // with zero
  if (!cmov.getOperand(0).isReg() || 
      !MRI->hasOneUse(cmov.getOperand(0).getReg()))
    return false;

  MachineInstr &cmp_eq = *MRI->use_begin(cmov.getOperand(0).getReg());
  
  int is_cmp_eq_or_ne = -1;
  switch (cmp_eq.getOpcode()) {
  case HSAIL::cmp_i1_eq_i1_ri:
  case HSAIL::cmp_i1_eq_i1_rr:
  case HSAIL::cmp_i1_eq_i32_ri:
  case HSAIL::cmp_i1_eq_i32_rr:
  case HSAIL::cmp_i1_eq_i64_ri:
  case HSAIL::cmp_i1_eq_i64_rr:
  case HSAIL::cmp_i1_eq_f32_ri:
  case HSAIL::cmp_i1_eq_f32_rr:
  case HSAIL::cmp_i1_eq_f64_ri:
  case HSAIL::cmp_i1_eq_f64_rr:
  case HSAIL::cmp_i32_eq_i1_ri:
  case HSAIL::cmp_i32_eq_i1_rr:
  case HSAIL::cmp_i32_eq_i32_ri:
  case HSAIL::cmp_i32_eq_i32_rr:
  case HSAIL::cmp_i32_eq_i64_ri:
  case HSAIL::cmp_i32_eq_i64_rr:
  case HSAIL::cmp_i32_eq_f32_ri:
  case HSAIL::cmp_i32_eq_f32_rr:
  case HSAIL::cmp_i32_eq_f64_ri:
  case HSAIL::cmp_i32_eq_f64_rr:
  case HSAIL::cmp_i64_eq_i1_ri:
  case HSAIL::cmp_i64_eq_i1_rr:
  case HSAIL::cmp_i64_eq_i32_ri:
  case HSAIL::cmp_i64_eq_i32_rr:
  case HSAIL::cmp_i64_eq_i64_ri:
  case HSAIL::cmp_i64_eq_i64_rr:
  case HSAIL::cmp_i64_eq_f32_ri:
  case HSAIL::cmp_i64_eq_f32_rr:
  case HSAIL::cmp_i64_eq_f64_ri:
  case HSAIL::cmp_i64_eq_f64_rr:
    is_cmp_eq_or_ne = 0;
    break;

  case HSAIL::cmp_i1_ne_i1_ri:
  case HSAIL::cmp_i1_ne_i1_rr:
  case HSAIL::cmp_i1_ne_i32_ri:
  case HSAIL::cmp_i1_ne_i32_rr:
  case HSAIL::cmp_i1_ne_i64_ri:
  case HSAIL::cmp_i1_ne_i64_rr:
  case HSAIL::cmp_i1_ne_f32_ri:
  case HSAIL::cmp_i1_ne_f32_rr:
  case HSAIL::cmp_i1_ne_f64_ri:
  case HSAIL::cmp_i1_ne_f64_rr:
  case HSAIL::cmp_i32_ne_i1_ri:
  case HSAIL::cmp_i32_ne_i1_rr:
  case HSAIL::cmp_i32_ne_i32_ri:
  case HSAIL::cmp_i32_ne_i32_rr:
  case HSAIL::cmp_i32_ne_i64_ri:
  case HSAIL::cmp_i32_ne_i64_rr:
  case HSAIL::cmp_i32_ne_f32_ri:
  case HSAIL::cmp_i32_ne_f32_rr:
  case HSAIL::cmp_i32_ne_f64_ri:
  case HSAIL::cmp_i32_ne_f64_rr:
  case HSAIL::cmp_i64_ne_i1_ri:
  case HSAIL::cmp_i64_ne_i1_rr:
  case HSAIL::cmp_i64_ne_i32_ri:
  case HSAIL::cmp_i64_ne_i32_rr:
  case HSAIL::cmp_i64_ne_i64_ri:
  case HSAIL::cmp_i64_ne_i64_rr:
  case HSAIL::cmp_i64_ne_f32_ri:
  case HSAIL::cmp_i64_ne_f32_rr:
  case HSAIL::cmp_i64_ne_f64_ri:
  case HSAIL::cmp_i64_ne_f64_rr:
    is_cmp_eq_or_ne = 1;
    break;

  default:
    return false;
  }

  assert(is_cmp_eq_or_ne != -1);

  if (!cmp_eq.getOperand(2).isImm() || cmp_eq.getOperand(2).getImm() != 0)
    return false;

  // We are in the target construction. Replace it with one compare.

  // Reverse CmpInstr
  if (is_cmp_eq_or_ne == 0)
  {
	bool IsOk;
	unsigned reversed_cond = 
		ReverseConditionOpcode(CmpInstr->getOpcode(), IsOk);
	if (!IsOk)
	  return false;

	CmpInstr->setDesc(get(reversed_cond));
  }

  // Replace all uses of cmp_eq with CmpInstr
  const_cast<MachineRegisterInfo*>(MRI)->replaceRegWith(
	  SrcReg, cmp_eq.getOperand(0).getReg());

  // Erase cmov and eq
  cmov.eraseFromParent();
  cmp_eq.eraseFromParent();

  return true;
}

bool
HSAILInstrInfo::FoldImmediate(MachineInstr *UseMI,
                              MachineInstr *DefMI,
                              unsigned Reg,
                              MachineRegisterInfo *MRI) const
{
  return TargetInstrInfoImpl::FoldImmediate(UseMI, DefMI, Reg, MRI);
}

unsigned
HSAILInstrInfo::getNumMicroOps(const InstrItineraryData *ItinData,
                               const MachineInstr *MI) const
{
  return TargetInstrInfoImpl::getNumMicroOps(ItinData, MI);
}

int
HSAILInstrInfo::getOperandLatency(const InstrItineraryData *ItinData,
                                  const MachineInstr *DefMI,
                                  unsigned DefIdx,
                                  const MachineInstr *UseMI,
                                  unsigned UseIdx) const
{
  //assert(!"When do we hit this?");
  return 1;
}

int
HSAILInstrInfo::getOperandLatency(const InstrItineraryData *ItinData,
                                  SDNode *DefNode,
                                  unsigned DefIdx,
                                  SDNode *UseNode,
                                  unsigned UseIdx) const
{
  //assert(!"When do we hit this?");
  return 1;
}

unsigned
HSAILInstrInfo::getInstrLatency(const InstrItineraryData *ItinData,
                                const MachineInstr *MI,
                                unsigned *PredCost) const
{
  //assert(!"When do we hit this?");
  return 1;
}

int
HSAILInstrInfo::getInstrLatency(const InstrItineraryData *ItinData,
                                SDNode *Node) const
{
  //assert(!"When do we hit this?");
  return 1;
}

bool
HSAILInstrInfo::hasHighOperandLatency(const InstrItineraryData *ItinData,
                                      const MachineRegisterInfo *MRI,
                                      const MachineInstr *DefMI,
                                      unsigned DefIdx,
                                      const MachineInstr *UseMI,
                                      unsigned UseIdx) const
{
  return TargetInstrInfoImpl::hasHighOperandLatency(ItinData, MRI, DefMI, 
      DefIdx, UseMI, UseIdx);
}

bool
HSAILInstrInfo::hasLowDefLatency(const InstrItineraryData *ItinData,
                                 const MachineInstr *DefMI,
                                 unsigned DefIdx) const
{
  return TargetInstrInfoImpl::hasLowDefLatency(ItinData, DefMI, DefIdx);
}

/// Get a free GPR32 or insert spill and reload around specified instruction
/// and return fried register
unsigned
HSAILInstrInfo::getTempGPR32PostRA(MachineBasicBlock::iterator MBBI) const
{
  MachineBasicBlock* MBB = MBBI->getParent();
  RS->enterBasicBlock(MBB);
  RS->forward(MBBI);
  unsigned tempU32 = RS->FindUnusedReg(&HSAIL::GPR32RegClass);
  if (!tempU32) {
    BitVector AS = RI.getAllocatableSet(*(MBB->getParent()),
                                        &HSAIL::GPR32RegClass);
    // Remove any candidates touched by instruction.
    for (unsigned i = 0, e = MBBI->getNumOperands(); i != e; ++i) {
      const MachineOperand &MO = MBBI->getOperand(i);
      if (MO.isRegMask())
        AS.clearBitsNotInMask(MO.getRegMask());
      if (!MO.isReg() || MO.isUndef() || !MO.getReg())
        continue;
      if (!TargetRegisterInfo::isVirtualRegister(MO.getReg())) {
        AS.reset(MO.getReg());
      }
    }
    tempU32 = AS.find_first();
    MachineBasicBlock::iterator UseMI (MBBI);
    RI.saveScavengerRegisterToFI(*MBB, *MBBI, ++UseMI, &HSAIL::GPR32RegClass,
      tempU32, getEmergencyStackSlot(MBB->getParent()));
    RI.eliminateFrameIndex(--MBBI, 0, RS);
    RI.eliminateFrameIndex(--UseMI, 0, RS);
  }
  return tempU32;
}

bool
HSAILInstrInfo::expandPostRAPseudo(MachineBasicBlock::iterator MBBI) const
{
  MachineBasicBlock* MBB = MBBI->getParent();
  MachineInstr &MI = *MBBI;
  unsigned opcode = MI.getOpcode();

  switch (opcode) {
  case HSAIL::spill_st_b1:
    {
      unsigned tempU32 = getTempGPR32PostRA(MBBI);
      BuildMI(*MBB, MBBI, MI.getDebugLoc(),
         get(HSAIL::cvt_b1_u32))
        .addReg(tempU32, RegState::Define)
        .addOperand(MI.getOperand(0));
      MI.setDesc(get(HSAIL::spill_st_u32_v1));
      MI.getOperand(0).setReg(tempU32);
      MI.getOperand(0).setIsKill();
      RS->setUsed(tempU32);
    }
    return true;
  case HSAIL::spill_ld_b1:
    {
      unsigned tempU32 = getTempGPR32PostRA(MBBI);
      BuildMI(*MBB, ++MBBI, MI.getDebugLoc(),
         get(HSAIL::cvt_u32_b1))
        .addOperand(MI.getOperand(0))
        .addReg(tempU32, RegState::Kill);
      MI.setDesc(get(HSAIL::spill_ld_u32_v1));
      MI.getOperand(0).setReg(tempU32);
      MI.getOperand(0).setIsDef();
      RS->setUsed(tempU32);
    }
    return true;
  }
  return HSAILGenInstrInfo::expandPostRAPseudo(MI);
}
}
