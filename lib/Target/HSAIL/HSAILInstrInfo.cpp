//===- HSAILInstrInfo.cpp - HSAIL Instruction Information ----------------===//
//
// This file contains the HSAIL implementation of the TargetInstrInfo class.
//
//===---------------------------------------------------------------------===//
#include "HSAILInstrInfo.h"
#include "HSAILBrig.h"
#include "HSAILTargetMachine.h"
#include "HSAILUtilityFunctions.h"
#include "llvm/IR/Instructions.h"
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
#include "llvm/IR/Verifier.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/Pass.h"
#include "llvm/ADT/SmallPtrSet.h"

#include <queue>

#define GET_INSTRINFO_CTOR_DTOR
#define GET_INSTRINFO_NAMED_OPS
#define GET_INSTRMAP_INFO
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

static unsigned getBrigTypeFromRCID(unsigned ID) {
  switch (ID) {
  case HSAIL::CRRegClassID:
    return Brig::BRIG_TYPE_B1;
  case HSAIL::GPR32RegClassID:
    return Brig::BRIG_TYPE_B32;
  case HSAIL::GPR64RegClassID:
    return Brig::BRIG_TYPE_B64;
  default:
    llvm_unreachable("unhandled register class ID");
  }
}
HSAILInstrInfo::HSAILInstrInfo(HSAILSubtarget &st)
  : HSAILGenInstrInfo(),
//  : TargetInstrInfoImpl(HSAILInsts, array_lengthof(HSAILInsts)),
    RI(st)
{
  RS = new RegScavenger();
}

HSAILInstrInfo::~HSAILInstrInfo()
{
  delete RS;
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
  const MCInstrDesc &MCID = get(MI->getOpcode());
  if (!MCID.mayLoad() || !MI->hasOneMemOperand())
    return HSAIL::NoRegister;

  const MachineOperand *Segment = getNamedOperand(*MI, HSAIL::OpName::segment);
  if (!Segment || Segment->getImm() != HSAILAS::SPILL_ADDRESS)
    return HSAIL::NoRegister;

  const MachineOperand &Base = HSAIL::getBase(MI);
  if (Base.isFI()) {
    FrameIndex = Base.getIndex();
    return MI->getOperand(0).getReg();
  }

  return HSAIL::NoRegister;
}

unsigned
HSAILInstrInfo::isLoadFromStackSlotPostFE(const MachineInstr *MI,
                                          int &FrameIndex) const
{
  return isLoadFromStackSlot(MI, FrameIndex);
}

unsigned
HSAILInstrInfo::isStoreToStackSlot(const MachineInstr *MI,
                                   int &FrameIndex) const
{
  const MCInstrDesc &MCID = get(MI->getOpcode());
  if (!MCID.mayStore() || !MI->hasOneMemOperand())
    return 0;

  const MachineOperand *Segment = getNamedOperand(*MI, HSAIL::OpName::segment);
  if (!Segment || Segment->getImm() != HSAILAS::SPILL_ADDRESS)
    return HSAIL::NoRegister;

  const MachineOperand &Base = HSAIL::getBase(MI);
  if (Base.isFI()) {
    FrameIndex = Base.getIndex();
    return MI->getOperand(0).getReg();
  }

  return HSAIL::NoRegister;
}

unsigned
HSAILInstrInfo::isStoreToStackSlotPostFE(const MachineInstr *MI,
                                           int &FrameIndex) const
{
  return isStoreToStackSlot(MI, FrameIndex);
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
                 (instr->getOpcode() == HSAIL::not_inst
                  // XXX - & b1?
                   )))
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
    if (I->readsRegister(reg) && (HSAIL::isConv(&*I) || I->mayStore())) {
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

    // Handle unconditional branches.
    if (I->getOpcode() == HSAIL::br_inst) {
      int Src0Idx = HSAIL::getNamedOperandIdx(HSAIL::br_inst, HSAIL::OpName::src0);
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
      int Src0Idx = HSAIL::getNamedOperandIdx(HSAIL::cbr_inst, HSAIL::OpName::src0);
      int Src1Idx = HSAIL::getNamedOperandIdx(HSAIL::cbr_inst, HSAIL::OpName::src1);

      FBB = TBB;
      TBB = I->getOperand(Src1Idx).getMBB();

      // Insert condition as pair - (register, reverse flag)
      // Or in case if there is dependencies
      // (register, COND_REVERSE_DEPENDANT, free reg num, reverse flag)
      Cond.push_back(I->getOperand(Src0Idx));

      if (DisableCondReversion)
      {
        Cond.push_back(MachineOperand::CreateImm(COND_IRREVERSIBLE));
        continue;
      }

      // Determine condition dependencies
      unsigned reg = I->getOperand(Src0Idx).getReg();
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
        RS->forward(std::prev(MBB.end()));

        free_reg = RS->FindUnusedReg(&HSAIL::CRRegClass);
        if (free_reg == 0)
        {
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
  else if (cond_expr && cond_expr->getOpcode() == HSAIL::not_inst)
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

    BuildMI(&MBB, DL, TII->get(HSAIL::not_inst))
      .addReg(cond_reg, RegState::Define)
      .addReg(CondOp.getReg())
      .addImm(Brig::BRIG_TYPE_B1);
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
    BuildMI(&MBB, DL, get(HSAIL::br_inst))
      .addImm(Brig::BRIG_WIDTH_ALL)
      .addMBB(TBB)
      .addImm(Brig::BRIG_TYPE_NONE);
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

      BuildMI(&MBB, DL, get(HSAIL::not_inst))
        .addReg(cond_reg, RegState::Define)
        .addReg(Cond[0].getReg())
        .addImm(Brig::BRIG_TYPE_B1);
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

  BuildMI(&MBB, DL, get(HSAIL::cbr_inst))
    .addImm(Brig::BRIG_WIDTH_1)
    .addReg(cond_reg)
    .addMBB(TBB)
    .addImm(Brig::BRIG_TYPE_B1);

  ++Count;

  if (FBB) {
    // Two-way Conditional branch. Insert the second branch.
    BuildMI(&MBB, DL, get(HSAIL::br_inst))
      .addImm(Brig::BRIG_WIDTH_ALL)
      .addMBB(FBB)
      .addImm(Brig::BRIG_TYPE_NONE);

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

    if (I->getOpcode() != HSAIL::br_inst &&
        I->getOpcode() != HSAIL::cbr_inst)
      break;

    // Remove the branch.
    I->eraseFromParent();
    I = MBB.end();
    ++Count;
  }

  return Count;
}

bool HSAILInstrInfo::copyRegToReg(MachineBasicBlock &MBB,
                                  MachineBasicBlock::iterator I,
                                  unsigned DestReg, unsigned SrcReg,
                                  const TargetRegisterClass *DestRC,
                                  const TargetRegisterClass *SrcRC,
                                  DebugLoc DL) const {
  assert(DestRC == SrcRC);

  BuildMI(MBB, I, DL, get(HSAIL::mov), DestReg)
    .addReg(SrcReg)
    .addImm(getBrigTypeFromRCID(DestRC->getID()));
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
  MachineFunction &MF = *MBB.getParent();
  MachineFrameInfo &MFI = *MF.getFrameInfo();
  DebugLoc DL;

  unsigned BT;
  switch (RC->getID()) {
    default:
      llvm_unreachable("unrecognized TargetRegisterClass");
      break;
    case HSAIL::GPR32RegClassID:
      Opc = HSAIL::st_v1;
      BT = Brig::BRIG_TYPE_U32;
      break;
    case HSAIL::GPR64RegClassID:
      Opc = HSAIL::st_v1;
      BT = Brig::BRIG_TYPE_U64;
      break;
    case HSAIL::CRRegClassID:
      Opc = HSAIL::spill_b1;
      BT = Brig::BRIG_TYPE_B1;
      break;
  }
  if (MI != MBB.end()) {
    DL = MI->getDebugLoc();
  }

  switch (RC->getID()) {
  default:
    llvm_unreachable("unrecognized TargetRegisterClass");
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
  case HSAIL::GPR64RegClassID: {
    MachineMemOperand *MMO
      = MF.getMachineMemOperand(
        MachinePointerInfo::getFixedStack(FrameIndex),
        MachineMemOperand::MOStore,
        MFI.getObjectSize(FrameIndex),
        MFI.getObjectAlignment(FrameIndex));

    // FIXME: Why is this setting kill?
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

void
HSAILInstrInfo::loadRegFromStackSlot(MachineBasicBlock &MBB,
                                     MachineBasicBlock::iterator MI,
                                     unsigned DestReg,
                                     int FrameIndex,
                                     const TargetRegisterClass *RC,
                                     const TargetRegisterInfo *TRI) const
{
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
      Opc = HSAIL::ld_v1;
      BT = Brig::BRIG_TYPE_U32;
      break;
    case HSAIL::GPR64RegClassID:
      Opc = HSAIL::ld_v1;
      BT = Brig::BRIG_TYPE_U64;
      break;
    case HSAIL::CRRegClassID:
      Opc = HSAIL::restore_b1;
      BT = Brig::BRIG_TYPE_B1;
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
    MachineMemOperand *MMO
      = MF.getMachineMemOperand(MachinePointerInfo::getFixedStack(FrameIndex),
                                MachineMemOperand::MOLoad,
                                MFI.getObjectSize(FrameIndex),
                                MFI.getObjectAlignment(FrameIndex));
    BuildMI(MBB, MI, DL, get(Opc))
      .addReg(DestReg, RegState::Define) // dest
      .addFrameIndex(FrameIndex)         // address_base
      .addReg(HSAIL::NoRegister)         // address_reg
      .addImm(0)                         // address_offset
      .addImm(BT)                        // TypeLength
      .addImm(HSAILAS::SPILL_ADDRESS)    // segment
      .addImm(MMO->getAlignment())       // align
      .addImm(Brig::BRIG_WIDTH_1)        // width
      .addImm(0)                         // mask
      .addMemOperand(MMO);
    break;
  }
  }
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

bool
HSAILInstrInfo::isSafeToMoveRegClassDefs(const TargetRegisterClass *RC) const
{
  // Micah: HSAIL does not have any constraints about moving defs.
  return true;
}

void HSAILInstrInfo::copyPhysReg(MachineBasicBlock &MBB,
                                 MachineBasicBlock::iterator MI,
                                 DebugLoc DL,
                                 unsigned DestReg,
                                 unsigned SrcReg,
                                 bool KillSrc) const {
  if (HSAIL::GPR32RegClass.contains(DestReg, SrcReg)) {
    BuildMI(MBB, MI, DL, get(HSAIL::mov), DestReg)
      .addReg(SrcReg, getKillRegState(KillSrc))
      .addImm(Brig::BRIG_TYPE_B32);
      return;
  }

  if (HSAIL::GPR64RegClass.contains(DestReg, SrcReg)) {
    BuildMI(MBB, MI, DL, get(HSAIL::mov), DestReg)
      .addReg(SrcReg, getKillRegState(KillSrc))
      .addImm(Brig::BRIG_TYPE_B64);
      return;
  }

  if (HSAIL::CRRegClass.contains(DestReg, SrcReg)) {
    BuildMI(MBB, MI, DL, get(HSAIL::mov), DestReg)
      .addReg(SrcReg, getKillRegState(KillSrc))
      .addImm(Brig::BRIG_TYPE_B1);
      return;
  }

  unsigned SrcBT = -1;
  unsigned DestBT = -1;

  if (HSAIL::GPR32RegClass.contains(DestReg) &&
      HSAIL::CRRegClass.contains(SrcReg)) {
    DestBT = Brig::BRIG_TYPE_B1;
    SrcBT = Brig::BRIG_TYPE_U32;
  } else if (HSAIL::CRRegClass.contains(DestReg) &&
             HSAIL::GPR32RegClass.contains(SrcReg)) {
    SrcBT = Brig::BRIG_TYPE_B1;
    DestBT = Brig::BRIG_TYPE_U32;
  } else if (HSAIL::GPR64RegClass.contains(DestReg) &&
             HSAIL::GPR32RegClass.contains(SrcReg)) {
    SrcBT = Brig::BRIG_TYPE_U64;
    DestBT = Brig::BRIG_TYPE_U32;
  } else if (HSAIL::GPR32RegClass.contains(DestReg) &&
             HSAIL::GPR64RegClass.contains(SrcReg)) {
    // Truncation can occur if a function was defined with different return
    // types in different places.
    SrcBT = Brig::BRIG_TYPE_U32;
    DestBT = Brig::BRIG_TYPE_U64;
  } else {
    assert(!"When do we hit this?");
    return TargetInstrInfo::copyPhysReg(MBB, MI, DL, DestReg, SrcReg, KillSrc);
  }

  BuildMI(MBB, MI, DL, get(HSAIL::cvt), DestReg)
    .addImm(0)      // ftz
    .addImm(0)      // round
    .addImm(DestBT) // destTypedestLength
    .addImm(SrcBT)  // srcTypesrcLength
    .addReg(SrcReg, getKillRegState(KillSrc));
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

  MachineInstr &cmov = *MRI->use_instr_begin(SrcReg);
  if (cmov.getOpcode() != HSAIL::cmov_inst)
    return false;

  if ((!cmov.getOperand(2).isImm() || !cmov.getOperand(3).isImm()) &&
      (cmov.getOperand(2).getImm() != -1 || cmov.getOperand(3).getImm() != 0))
    return false;

  // Check that there is only one user of cmov and it is cmp_eq or cmp_ne 
  // with zero
  if (!cmov.getOperand(0).isReg() || 
      !MRI->hasOneUse(cmov.getOperand(0).getReg()))
    return false;

  MachineInstr &cmp_eq = *MRI->use_instr_begin(cmov.getOperand(0).getReg());
  
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

    // FIXME: Need to pass correct FrameOperand Idx
    unsigned FIOpIdx = 0;
    RI.eliminateFrameIndex(--MBBI, 0, FIOpIdx, RS);
    RI.eliminateFrameIndex(--UseMI, 0, FIOpIdx,  RS);
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
  case HSAIL::spill_b1:
    {
      unsigned tempU32 = getTempGPR32PostRA(MBBI);
      DebugLoc DL = MI.getDebugLoc();
      BuildMI(*MBB, MBBI, DL, get(HSAIL::cvt), tempU32)
        .addImm(0)                   // ftz
        .addImm(0)                   // round
        .addImm(Brig::BRIG_TYPE_U32) // destTypedestLength
        .addImm(Brig::BRIG_TYPE_B1)  // srcTypesrcLength
        .addOperand(MI.getOperand(0));

      MI.setDesc(get(HSAIL::st_v1));
      MI.getOperand(0).setReg(tempU32);
      MI.getOperand(0).setIsKill();
      HSAIL::getBrigType(&MI).setImm(Brig::BRIG_TYPE_U32);
      RS->setRegUsed(tempU32);
    }
    return true;
  case HSAIL::restore_b1: {
      unsigned tempU32 = getTempGPR32PostRA(MBBI);
      DebugLoc DL = MI.getDebugLoc();

      BuildMI(*MBB, ++MBBI, DL, get(HSAIL::cvt), MI.getOperand(0).getReg())
        .addImm(0)                   // ftz
        .addImm(0)                   // round
        .addImm(Brig::BRIG_TYPE_B1)  // destTypedestLength
        .addImm(Brig::BRIG_TYPE_U32) // srcTypesrcLength
        .addReg(tempU32, RegState::Kill);

      MI.setDesc(get(HSAIL::ld_v1));
      MI.getOperand(0).setReg(tempU32);
      MI.getOperand(0).setIsDef();
      HSAIL::getBrigType(&MI).setImm(Brig::BRIG_TYPE_U32);
      RS->setRegUsed(tempU32);
    }
    return true;
  }
  return HSAILGenInstrInfo::expandPostRAPseudo(MI);
}

const TargetRegisterClass *HSAILInstrInfo::getOpRegClass(
  const MachineRegisterInfo &MRI,
  const MachineInstr &MI,
  unsigned OpNo) const {

  const MachineOperand &MO = MI.getOperand(OpNo);
  if (!MO.isReg())
    return nullptr;

  unsigned Reg = MO.getReg();
  if (TargetRegisterInfo::isVirtualRegister(Reg))
    return MRI.getRegClass(Reg);

  return RI.getPhysRegClass(Reg);
}

static unsigned numStComponents(unsigned Opc) {
  switch (Opc) {
  case HSAIL::st_v1:
    return 1;
  case HSAIL::st_v2:
    return 2;
  case HSAIL::st_v3:
    return 3;
  case HSAIL::st_v4:
    return 4;
  }

  llvm_unreachable("Not a store");
}

bool HSAILInstrInfo::verifyInstruction(const MachineInstr *MI,
                                       StringRef &ErrInfo) const {
  unsigned Opc = MI->getOpcode();
  const MCInstrDesc &Desc = get(Opc);

  const MachineRegisterInfo &MRI = MI->getParent()->getParent()->getRegInfo();

  // Verify that all the load destinations are registers with the same size.
  if (Opc == HSAIL::ld_v1 ||
      Opc == HSAIL::ld_v2 ||
      Opc == HSAIL::ld_v3 ||
      Opc == HSAIL::ld_v4) {
    const TargetRegisterClass *DestRC = getOpRegClass(MRI, *MI, 0);
    if (!DestRC) {
      ErrInfo = "Load into non-register";
      return false;
    }

    for (unsigned I = 0, E = Desc.getNumDefs(); I != E; ++I) {
      const TargetRegisterClass *RC = getOpRegClass(MRI, *MI, I);
      if (RC != DestRC) {
        ErrInfo = "Inconsistent dest register operand";
        return false;
      }
    }
  }

  // Verify that all store sources are registers with the same size.
  if (Opc == HSAIL::st_v1 ||
      Opc == HSAIL::st_v2 ||
      Opc == HSAIL::st_v3 ||
      Opc == HSAIL::st_v4) {
    int NSrc = numStComponents(Opc);
    int BaseSrcIdx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src);

    // FIXME: Verify bounds of immediate src operands.
    const TargetRegisterClass *SrcRC = nullptr;
    for (int SrcIdx = BaseSrcIdx; SrcIdx < BaseSrcIdx + NSrc; ++SrcIdx) {
      const TargetRegisterClass *RC = getOpRegClass(MRI, *MI, SrcIdx);
      if (!SrcRC)
        SrcRC = RC;

      if (RC && RC != SrcRC) {
        ErrInfo = "Inconsistent src register operand";
        return false;
      }
    }
  }

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
