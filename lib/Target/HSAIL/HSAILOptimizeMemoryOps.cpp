//===  HSAILOptimizeMemoryOps.cpp - Optimize HSAIL memory operations -*- C++ -*-===//
//===----------------------------------------------------------------------===//
//
// Perform HSAIL memory optimizations:
// 1. Merge scalar loads and stores into their vector equivalents.
//    Pass expects that loads and stores 
//    from same base pointers were glued together
//    during instruction scheduling.
// 2. Eliminate dead stores in swizzles 
//    left after scalarization in instruction selection
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "hsail-memory-opts"

#include "HSAIL.h"
#include "HSAILInstrInfo.h"
#include "HSAILTargetMachine.h"
#include "HSAILSubtarget.h"
#include "HSAILUtilityFunctions.h"

#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Analysis/AliasAnalysis.h"
#include "llvm/Target/TargetOptions.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/LoopInfo.h"

using namespace llvm;

static cl::opt<bool> EnableHsailDSE("hsail-enable-dse", cl::Hidden,
    cl::desc("Enable dead store elimination in HSAIL machine code"),
    cl::init(true));

static cl::opt<bool> EnableMoveKernargs("hsail-enable-move-kernargs", cl::Hidden,
    cl::desc("Move ld_kernargs with one use under condition directly into this condition"),
    cl::init(true));

static cl::opt<bool> EnableVecLdSt("hsail-enable-vec-ld-st", cl::Hidden,
    cl::desc("Enable vector load store in HSAIL machine code"),
    cl::init(true));

namespace llvm {
void initializeHSAILOptimizeMemoryOpsPass(PassRegistry &);
}

namespace 
{
  class HSAILOptimizeMemoryOps: public MachineFunctionPass
  {
  public:
    static char ID;

    explicit HSAILOptimizeMemoryOps(const HSAILTargetMachine &aTM): 
      MachineFunctionPass(ID), TM(aTM) { initializeHSAILOptimizeMemoryOpsPass(*PassRegistry::getPassRegistry()); }

    // Default Constructor required for initiallizing PASS
    explicit HSAILOptimizeMemoryOps():
      MachineFunctionPass(ID), TM(TM) { initializeHSAILOptimizeMemoryOpsPass(*PassRegistry::getPassRegistry()); }

    virtual bool runOnMachineFunction(MachineFunction &F) override;

    virtual const char *getPassName() const override
    { 
     return "HSAIL memory optimizations";
    }

    virtual void getAnalysisUsage(AnalysisUsage &AU) const override {
      AU.addRequired<AliasAnalysis>();
      AU.addRequired<LoopInfoWrapperPass>();
      AU.addRequired<PostDominatorTree>();
      MachineFunctionPass::getAnalysisUsage(AU);
    }

  private:
    // Check that load/store memoperands are equal
    // Important: It does not check offsets for equality
    bool IsMemOpsEqual(const MachineMemOperand *memop1,
                       const MachineMemOperand *memop2) const;
    
    // Check if two memory accesses are the same except for offsets and thus
    // can be folded together.
    bool compareMemoryAccess(const MachineRegisterInfo &MRI,
                             const MachineInstr* base_inst,
                             const MachineInstr* inst) const;

    // Remove redundant vector loads/stores left after scalarization
    bool EliminateDeadStores(MachineFunction &F);

    // Merge loads/stores into their vector equivalents
    bool MergeLoadsStores(MachineFunction &F);
    // Add fake operations into worklist in case it is profitable to
    // make wider load
    // Returns true if it performed some changes
    bool ExtendSwizzles(SmallVectorImpl<MachineInstr *> &Worklist,
      MachineRegisterInfo &MRI, MachineFunction &F);

    bool MoveKernargs(MachineFunction &F);

    bool isSafeToMove(const MachineInstr *inst);

  private:
    const HSAILTargetMachine &TM;
    const HSAILInstrInfo *TII;

    AliasAnalysis *AA;
    PostDominatorTree *PDT;
    LoopInfo *LI;
  };

  char HSAILOptimizeMemoryOps::ID = 0;
}

// Register pass in passRegistry so that
// the pass info gets populated for printing debug info
INITIALIZE_PASS_BEGIN(HSAILOptimizeMemoryOps, "hsail-memory-opts",
                "HSAIL memory optimizations", false, false)
INITIALIZE_PASS_DEPENDENCY(LoopInfoWrapperPass)
INITIALIZE_PASS_DEPENDENCY(PostDominatorTree)
INITIALIZE_PASS_END(HSAILOptimizeMemoryOps, "hsail-memory-opts",
                "HSAIL memory optimizations", false, false)


FunctionPass *llvm::createHSAILOptimizeMemoryOps(const HSAILTargetMachine &TM)
{
  return new HSAILOptimizeMemoryOps(TM);
}

// Resolved undefined utility functions
static MachineOperand getBase(const MachineInstr* MI) {
  int AddrIdx = HSAIL::getNamedOperandIdx(MI->getOpcode(), HSAIL::OpName::address);
  return MI->getOperand(AddrIdx + HSAILADDRESS::BASE);
}

static MachineOperand getIndex(const MachineInstr* MI) {
  int AddrIdx = HSAIL::getNamedOperandIdx(MI->getOpcode(), HSAIL::OpName::address);
  return MI->getOperand(AddrIdx + HSAILADDRESS::REG);
}

static MachineOperand getOffset(const MachineInstr* MI) {
  int AddrIdx = HSAIL::getNamedOperandIdx(MI->getOpcode(), HSAIL::OpName::address);
  return MI->getOperand(AddrIdx + HSAILADDRESS::OFFSET);
}

static MachineOperand getBrigType(const MachineInstr* MI) {
  int TypeIdx = HSAIL::getNamedOperandIdx(MI->getOpcode(), HSAIL::OpName::TypeLength);
  return MI->getOperand(TypeIdx);
}

static int addressOpNum(const llvm::MachineInstr *MI) {
  return HSAIL::getNamedOperandIdx(MI->getOpcode(), HSAIL::OpName::address);
}

static inline bool isLoad(const MachineInstr *MI) {
  if (!MI->hasOneMemOperand() ||
      !MI->hasOrderedMemoryRef() ||
      !MI->mayLoad())
    return false;
  int op = MI->getOpcode();
  return (llvm::HSAIL::getVectorLdStOpcode(op, 1) == op);
}

static inline bool isStore(const MachineInstr *MI) {
  if (!MI->hasOneMemOperand() ||
      !MI->hasOrderedMemoryRef() ||
      !MI->mayStore())
    return false;
  int op = MI->getOpcode();
  return (llvm::HSAIL::getVectorLdStOpcode(op, 1) == op);
}

static bool HSAILisArgInst(const HSAILInstrInfo *TII, const llvm::MachineInstr *MI)
{
  unsigned op = MI->getOpcode();
  const MCInstrDesc &MCID = TII->get(op);
  if (!MCID.mayLoad() || !MI->hasOneMemOperand()) return false;
  unsigned as = (*MI->memoperands_begin())->getPointerInfo().getAddrSpace();
  if (as != HSAILAS::KERNARG_ADDRESS && as != HSAILAS::ARG_ADDRESS) return false;
  return true;
}

static bool isBitType(unsigned type)
{
    switch(type)
    {
    case BRIG_TYPE_B1:
    case BRIG_TYPE_B8:
    case BRIG_TYPE_B16:
    case BRIG_TYPE_B32:
    case BRIG_TYPE_B64:
    case BRIG_TYPE_B128:
        return true;

    default:
        return false;
    }
}

static unsigned getBrigTypeNumBits(unsigned arg) {
  switch( arg ) {
    case BRIG_TYPE_B1                   : return 1;
    case BRIG_TYPE_B128                 : return 128;
    case BRIG_TYPE_B16                  : return 16;
    case BRIG_TYPE_B32                  : return 32;
    case BRIG_TYPE_B64                  : return 64;
    case BRIG_TYPE_B8                   : return 8;
    case BRIG_TYPE_F16                  : return 16;
    case BRIG_TYPE_F16X2                : return 32;
    case BRIG_TYPE_F16X4                : return 64;
    case BRIG_TYPE_F16X8                : return 128;
    case BRIG_TYPE_F32                  : return 32;
    case BRIG_TYPE_F32X2                : return 64;
    case BRIG_TYPE_F32X4                : return 128;
    case BRIG_TYPE_F64                  : return 64;
    case BRIG_TYPE_F64X2                : return 128;
    case BRIG_TYPE_ROIMG                : return 64;
    case BRIG_TYPE_RWIMG                : return 64;
    case BRIG_TYPE_S16                  : return 16;
    case BRIG_TYPE_S16X2                : return 32;
    case BRIG_TYPE_S16X4                : return 64;
    case BRIG_TYPE_S16X8                : return 128;
    case BRIG_TYPE_S32                  : return 32;
    case BRIG_TYPE_S32X2                : return 64;
    case BRIG_TYPE_S32X4                : return 128;
    case BRIG_TYPE_S64                  : return 64;
    case BRIG_TYPE_S64X2                : return 128;
    case BRIG_TYPE_S8                   : return 8;
    case BRIG_TYPE_S8X16                : return 128;
    case BRIG_TYPE_S8X4                 : return 32;
    case BRIG_TYPE_S8X8                 : return 64;
    case BRIG_TYPE_SAMP                 : return 64;
    case BRIG_TYPE_SIG32                : return 64;
    case BRIG_TYPE_SIG64                : return 64;
    case BRIG_TYPE_U16                  : return 16;
    case BRIG_TYPE_U16X2                : return 32;
    case BRIG_TYPE_U16X4                : return 64;
    case BRIG_TYPE_U16X8                : return 128;
    case BRIG_TYPE_U32                  : return 32;
    case BRIG_TYPE_U32X2                : return 64;
    case BRIG_TYPE_U32X4                : return 128;
    case BRIG_TYPE_U64                  : return 64;
    case BRIG_TYPE_U64X2                : return 128;
    case BRIG_TYPE_U8                   : return 8;
    case BRIG_TYPE_U8X16                : return 128;
    case BRIG_TYPE_U8X4                 : return 32;
    case BRIG_TYPE_U8X8                 : return 64;
    case BRIG_TYPE_WOIMG                : return 64;
    default : assert(0); return 0;
    }
}

bool HSAILOptimizeMemoryOps::IsMemOpsEqual(
  const MachineMemOperand *memop1,
  const MachineMemOperand *memop2) const
{
  const Value *P1 = memop1->getValue();
  const Value *P2 = memop2->getValue();
  if (P1 == NULL || P2 == NULL) {
    return false;
  }
  if (isa<UndefValue>(P1) && isa<UndefValue>(P2)) {
    const MDNode* Tag1 = memop1->getAAInfo().TBAA;
    const MDNode* Tag2 = memop2->getAAInfo().TBAA;
    if (Tag1 == NULL || Tag2 == NULL)
      // Cannot conclude if one undef is the same as another one.
      return false;
    if (Tag1 != Tag2)
      return false;
  }
  if (memop1->getSize() != memop2->getSize() ||
      memop1->getPointerInfo().getAddrSpace() !=
        memop2->getPointerInfo().getAddrSpace() ||
      AA->alias(P1, P2) != MustAlias) {
    return false;
  }
  return true;
}

bool HSAILOptimizeMemoryOps::compareMemoryAccess(const MachineRegisterInfo &MRI,
                                                 const MachineInstr* base_inst,
                                                 const MachineInstr* inst) const {
  // It should be load or store with same segment, type and length
  // as others in worklist.
  MachineMemOperand *base_memop = *base_inst->memoperands_begin();
  MachineMemOperand *new_memop = *inst->memoperands_begin();
  if (new_memop->getFlags() != base_memop->getFlags())
    return false;
  bool same_reg = false;
  if (!IsMemOpsEqual(new_memop, base_memop)) {
    // Second chance: memory operands might differ, but registers be the same.
    same_reg = getBase(base_inst).isIdenticalTo(getBase(inst)) &&
               getIndex(base_inst).isIdenticalTo(getIndex(inst));
    if (!same_reg)
      return false;
  }
  unsigned T1 = getBrigType(base_inst).getImm(),
           T2 = getBrigType(inst).getImm();
  if (T1 != T2) {
    unsigned size1 = getBrigTypeNumBits(T1),
             size2 = getBrigTypeNumBits(T2);
    if (size1 != size2)
      return false;
    if (!isBitType(T1) && !isBitType(T2) && size1 < 32)
      return false;
  }

  // All registers should have same register size.
  unsigned inst_op = 0, base_op = 0;
  while (inst_op < inst->getNumOperands() &&
         base_op < inst->getNumOperands()) {
    if (!inst->getOperand(inst_op).isReg() ||
        inst->getOperand(inst_op).getReg() == 0) {
      ++inst_op;
      ++base_op;
      continue;
    }
    if (!base_inst->getOperand(base_op).isReg() ||
        base_inst->getOperand(base_op).getReg() == 0) {
      ++inst_op;
      ++base_op;
      continue;
    }

    if (MRI.getRegClass(inst->getOperand(inst_op).getReg())->getSize() !=
        MRI.getRegClass(base_inst->getOperand(base_op).getReg())->getSize()) {
      return false;
    }
    ++inst_op;
    ++base_op;
  }

  if (same_reg) {
    // Memory access has the same base but different memory operands - patch
    // the second memory operand.
    new_memop->setOffset(base_memop->getOffset() + getOffset(inst).getImm() -
                         getOffset(base_inst).getImm());
    new_memop->setValue(base_memop->getValue());
  }

  return true;
}

bool HSAILOptimizeMemoryOps::ExtendSwizzles(
  SmallVectorImpl<MachineInstr *> &Worklist,
  MachineRegisterInfo &MRI,
  MachineFunction &MF)
{
  assert(Worklist.size() > 0 && Worklist.size() <= 4);
  
  MachineMemOperand *base_memop = *(Worklist.front()->memoperands_begin());
  Type *memop_type = base_memop->getValue()->getType()->getPointerElementType();
  
  // Check if it's profitable to extend
  // For now assume that _v3 is less effective than _v4
  // but not for 32 bit values - we use secret knowledge that 
  // finalizer will have _load_dwordx3 operations.
  // TODO_HSA: Check memory segment. 
  //           We don't have some operations in finalizer for the group segment.
  if (!(isa<VectorType>(memop_type) && 
        cast<VectorType>(memop_type)->getNumElements() == 4 &&
        Worklist.size() == 3 &&
        memop_type->getScalarSizeInBits() < 32))
    return false;

  // Missing load is in the end of the worklist
  bool end_missing = base_memop->getOffset() == 0;
  // Missing load is in the beginning of the worklist
  bool begin_missing = 
    base_memop->getOffset() * 8 == memop_type->getScalarSizeInBits();

  if (end_missing || begin_missing)
  {
    // Create "fake" load
    MachineInstrBuilder fake_load = BuildMI(
      *Worklist.front()->getParent()->getParent(), 
      Worklist.front()->getDebugLoc(),
      TII->get(Worklist.front()->getOpcode()));

    unsigned fake_reg = MRI.createVirtualRegister(
      MRI.getRegClass(Worklist.front()->getOperand(0).getReg()));
    fake_load.addReg(fake_reg, RegState::Define);

    if (end_missing)
      Worklist.push_back(fake_load);
    else if (begin_missing)
    {
      // Add address and the rest of operands
      for (unsigned i = addressOpNum(Worklist.front()); 
           i < Worklist.front()->getNumOperands(); ++i)
      {
        fake_load.addOperand(Worklist.front()->getOperand(i));
      }      

      // Set up correct offset (one element back)
      assert(getOffset(fake_load).isImm());
      int64_t element_size = memop_type->getScalarSizeInBits() / 8;
      // in instruction operands
      getOffset(fake_load).setImm(
        getOffset(fake_load).getImm() - element_size);
      // in memory operands
      fake_load->addMemOperand(MF, MF.getMachineMemOperand(base_memop, 
        -element_size, base_memop->getSize()));

      Worklist.insert(Worklist.begin(), fake_load);
    }

    return true;
  }

  return false;
}

static bool hasVectorForm(const MachineInstr* inst) {

  if (!inst->hasOneMemOperand() ||
     (!inst->mayLoad() && !inst->mayStore()))
    return false;

  // Only process known forms of scalar loads and stores.
  int op = inst->getOpcode();
  if (HSAIL::getVectorLdStOpcode(op, 1) != op)
    return false;

  
  switch (getBrigType(inst).getImm()) {
  case BRIG_TYPE_U8:
  case BRIG_TYPE_S8:
  case BRIG_TYPE_B8:
  case BRIG_TYPE_U16:
  case BRIG_TYPE_S16:
  case BRIG_TYPE_B16:
  case BRIG_TYPE_U32:
  case BRIG_TYPE_S32:
  case BRIG_TYPE_B32:
  case BRIG_TYPE_U64:
  case BRIG_TYPE_S64:
  case BRIG_TYPE_B64:
  case BRIG_TYPE_F32:
  case BRIG_TYPE_F64:
    return true;
  }

  return false;

}

/// \brief Move COPY operations earlier to improve merging
///
/// For (ld|st)_(private|group), the backend inserts extra COPY
/// operations that convert 64-bit pointer values into 32-bit pointer
/// values. These extra operations break the sequence of ld/st
/// operations that can be merged. So we move *all* COPY operations to
/// safe locations closer to the beginning of the basic block.
///
/// This is actually a workaround for the code that looks for merge
/// candidates. A better fix is to safely skip operations that are
/// independent of the load/stores being merged.
static bool rescheduleCopyOperations(MachineFunction &F) {
  bool is_changed = false;
  const MachineRegisterInfo &MRI = F.getRegInfo();
  assert(MRI.isSSA());

  for (MachineFunction::iterator bb_it = F.begin(), bb_end = F.end();
       bb_it != bb_end; ++bb_it) {
    for (MachineBasicBlock::instr_iterator inst_it = bb_it->instr_begin(),
           inst_end = bb_it->instr_end(); inst_it != inst_end;) {
      MachineBasicBlock::instr_iterator II = *inst_it++; // note the post-increment
      if (!II->isCopy()) continue;

      MachineOperand &Op1 = II->getOperand(1);
      MachineInstr *Def = Op1.isReg() ? MRI.getVRegDef(Op1.getReg()) : NULL;

      if (!Def || Def->getParent() != bb_it || Def->isPHI()) {
        bb_it->remove(II);
        bb_it->insert(bb_it->getFirstNonPHI(), II);
        is_changed = true;
      } else {
        // We cannot move it to the top of the basic block.
        // If we simply move it after its def, we might move copy after the
        // load or store, thus preventing that load or store from being merged.
        // Let's check if the result of the copy is actually used as an operand
        // of a load or store and only move if it is.
        MachineOperand &Op0 = II->getOperand(0);
        if (Op0.isReg()) {
          unsigned Reg0 = Op0.getReg();
          // Practically we are concerned about the first/the only use.
          if (MRI.use_empty(Reg0))
            continue;
          const MachineInstr *FirstUser = &*MRI.use_instr_begin(Reg0);
          if (!isLoad(FirstUser) && !isStore(FirstUser))
            continue;
        }
        bb_it->remove(II);
        bb_it->insertAfter((MachineBasicBlock::instr_iterator)Def, II);
        is_changed = true;
      }
    }
  }

  return is_changed;
}

bool HSAILOptimizeMemoryOps::isSafeToMove(const MachineInstr *inst)
{   
   if (inst->isCall() || (inst->mayLoad() && inst->hasOrderedMemoryRef())) {
     return false;
   }
 
   if (inst->isPosition() || inst->isDebugValue() || inst->isTerminator() ||
     inst->hasUnmodeledSideEffects())
     return false;

    return true;
}

bool HSAILOptimizeMemoryOps::MergeLoadsStores(MachineFunction &F)
{
  MachineRegisterInfo &MRI = F.getRegInfo();
  bool is_changed = false;

  for (MachineFunction::iterator bb_it = F.begin(), bb_end = F.end(); 
       bb_it != bb_end; ++bb_it)
  {
    for (MachineBasicBlock::iterator inst_it = bb_it->begin(), 
         inst_end = bb_it->end(); inst_it != inst_end; /* no increment */)
    {
      SmallVector<MachineInstr*, 4> worklist;
      MachineMemOperand *base_memop = 0;
      const MCInstrDesc *base_mcid = 0;
      MachineInstr *base_inst = 0;
      int64_t base_offset = 0;
      MachineBasicBlock::iterator base_it;

      // Compute worklist of loads which can be merged into vectors
      while (inst_it != inst_end && worklist.size() < 4)
      {
        MachineInstr *inst = inst_it;
        //bool iss = inst->mayStore();
        
        const MCInstrDesc &MCID = TII->get(inst->getOpcode());
        // Instructions in worklist should have only one mem operand and 
        // all of them should be either mayLoad or mayStore or both
        //
        // TODO: Do not depend on the presence of consecutive
        // operations. Intervening non-mergeable operations can
        // actually be skipped under certain conditions. Such can
        // eliminate the call to rescheduleCopyOperations(), besides
        // potentially improving the effectiveness of this
        // optimization.
        if (!hasVectorForm(inst) ||
            (base_mcid != 0 && base_mcid->Flags != MCID.Flags))
        {
          if (worklist.empty())
          {
            ++inst_it;
            continue;
          }
          break;
        }

        if (worklist.empty())
        {
          worklist.push_back(inst_it);
          base_memop = *inst->memoperands_begin();
          base_offset = base_memop->getOffset();
          base_mcid = &MCID;
          base_inst = inst;
          base_it = inst_it;
          ++inst_it;
          continue;
        }
 
        if (!compareMemoryAccess(MRI, base_inst, inst))
          break;
      
   
        MachineMemOperand *new_memop = *inst->memoperands_begin();
        int64_t new_offset = new_memop->getOffset();

        // Out of order access.
        if (new_offset < base_offset) {
          if ((base_offset - new_offset) / new_memop->getSize() > 4) {
            break; // Too far anyway.
          }

          if( (base_offset - new_offset) % new_memop->getSize() != 0) {
            break; //overlap
          }

          if (!isSafeToMove(inst)) {
            break;
          }
       
          // Move instruction to be in order and restart analysis.
          DEBUG(dbgs() << "Moving " << *inst << " before " << *base_inst << '\n');
          bb_it->remove(inst);
          // Restart scan.
          inst_it = bb_it->insert(base_it, inst);
          // There new offset is still non-zero, so may be more preceeding
          // operations - restart from the beginning of basic block.
          if (new_offset != 0)
            inst_it = bb_it->begin();
          worklist.clear();
          base_mcid = nullptr;
          is_changed = true;
          break;
        }

        // Offsets are too far, more than a cacheline. No vector load can handle
        // object elements that big (64 /4 = 16 bytes) as well. This also handles
        // the case if there is more than 4Gb between pointers.
        if ((new_offset - base_offset) > 64)
          break;
        // Check that it is exactly next vector element
        unsigned num_ops_between = ((new_offset - base_offset) / 
          new_memop->getSize()) - worklist.size();
        bool not_complete_load = ((new_offset - base_offset) %
          (new_memop->getSize())) != 0;

        if (base_mcid->mayLoad() && 
            num_ops_between <= 4 - worklist.size() - 1 &&
            !not_complete_load)
        {
          // Look ahead as there can be some more out of order accesses.
          if (num_ops_between > 0) {
            MachineBasicBlock::iterator ahead_it = std::next(inst_it);
            bool local_changed = false;
            for (unsigned limit = 4 - worklist.size();
                 ahead_it != inst_end && limit > 0; ++ahead_it, --limit) {
              MachineInstr *i = ahead_it;
              const MCInstrDesc &MCID = TII->get(i->getOpcode());
              if (!hasVectorForm(i) || (base_mcid->Flags != MCID.Flags))
                break;
              if (!compareMemoryAccess(MRI, base_inst, i))
                break;
              MachineMemOperand *i_memop = *i->memoperands_begin();
              int64_t i_offset = i_memop->getOffset();
              if (i_offset < new_offset) {
                // Found out of order access in the middle of the vector.
                if ((new_offset - i_offset) % new_memop->getSize() != 0)
                  break;
                bool SawStore = false;
                if (!i->isSafeToMove(AA, SawStore))
                  break;
                DEBUG(dbgs() << "Moving " << *i << " before " << *inst << '\n');
                bb_it->remove(i);
                inst_it = bb_it->insert(inst_it, i);
                is_changed = local_changed = true;
                break;
              }
            }
            if (local_changed)
              continue; // Restart from new instruction.
          }

          // Insert "fake" loads in order to fill gaps in vector
          for (unsigned i = 0; i < num_ops_between; i++)
          {
            MachineInstrBuilder fake_load = BuildMI(
              F, 
              worklist.front()->getDebugLoc(), 
              *base_mcid);

            unsigned fake_reg = MRI.createVirtualRegister(
              MRI.getRegClass(inst_it->getOperand(0).getReg()));
            fake_load.addReg(fake_reg, RegState::Define);

            worklist.push_back(fake_load);
          }
        }
        else if (num_ops_between != 0 || not_complete_load)
          break;
 
        // Add new item to the worklist
        worklist.push_back(inst_it);
        ++inst_it;
      } // end while --- ehat we care

      // Now we are ready to perform merging
      if (worklist.size() <= 1)
        continue;

      // In case if there was swizzles some loads may be already deleted
      // in some case it's better to restore them
      // for example to avoid ld_v3
      // TODO_HSA: Check if it is profitable for stores
      if (!base_mcid->mayStore())
      {
        if (ExtendSwizzles(worklist, MRI, F))
        {
          // It is possible that base instruction has changed
          base_inst = worklist.front();
          base_memop = *base_inst->memoperands_begin();
          base_offset = base_memop->getOffset();
          base_mcid = &TII->get(base_inst->getOpcode());
        }
      }
      
      DEBUG(dbgs() << "Merging " << worklist.size() << 
        "instructions starting with " << worklist[0] << "\n");

      // Create vector instruction
      int vec_opc =
        HSAIL::getVectorLdStOpcode(base_inst->getOpcode(), worklist.size());
      if (vec_opc <= 0)
        continue;
  
      MachineInstrBuilder builder = 
        BuildMI(*bb_it, inst_it, base_inst->getDebugLoc(), TII->get(vec_opc));

      unsigned BT = getBrigType(base_inst).getImm();
      // Insert def registers and look for a non-bit type to use with extload.
      for (unsigned i = 0; i < worklist.size(); ++i)
      {
        builder.addOperand(worklist[i]->getOperand(0));

        MachineOperand &inserted_op = 
          builder->getOperand(builder->getNumOperands() - 1);
        if (inserted_op.isReg() && inserted_op.isDef())
          inserted_op.setIsEarlyClobber();

        if (isBitType(BT) &&
            worklist[i]->getNumOperands() > HSAILADDRESS::ADDRESS_NUM_OPS)
          BT = getBrigType(worklist[i]).getImm();
      }

      // Insert source address and offset if necessary
      for (unsigned i = 1; i < base_inst->getNumOperands(); ++i)
        builder.addOperand(base_inst->getOperand(i));

      // Set correct load brig type.
      getBrigType(builder).setImm(BT);
 
      // Construct new correct one memory operand
      builder.addMemOperand(F.getMachineMemOperand(base_memop->getPointerInfo(),
        base_memop->getFlags(), base_memop->getSize() * worklist.size(),
        base_memop->getAlignment(), base_memop->getAAInfo()));

      // Remove old scalar loads
      for (unsigned i = 0; i < worklist.size(); ++i)
      {
        if (worklist[i]->getParent())
          worklist[i]->eraseFromParent();
        else
          F.DeleteMachineInstr(worklist[i]);
      }
      is_changed = true;
    }
  }

  return is_changed;
}

bool HSAILOptimizeMemoryOps::EliminateDeadStores(MachineFunction &F)
{
  bool ret_code = false;
  
  for (MachineFunction::iterator bb_it = F.begin(), bb_end = F.end(); 
       bb_it != bb_end; ++bb_it)
  {
    // For each store search for it opposite load
    for (MachineBasicBlock::iterator store_it = bb_it->begin(), 
         store_end = bb_it->end(); store_it != store_end; )
    {
      MachineInstr *store_inst = &*store_it++;
      if (!store_inst->getDesc().mayStore())
        continue;

      // Get definition of stored register
      if (store_inst->getNumOperands() < 1)
        continue;
      MachineOperand &src_op = store_inst->getOperand(0);
      if (!src_op.isReg())
        continue;
      MachineInstr *src_inst = 
        F.getRegInfo().getVRegDef(src_op.getReg());
      if (!src_inst)
        continue;

      // Get memory operands
      if (!src_inst->hasOneMemOperand() ||
          !store_inst->hasOneMemOperand())
      {
        continue;
      }

      MachineMemOperand *src_memop = *src_inst->memoperands_begin(), 
        *store_memop = *store_inst->memoperands_begin();

      // Check that we can remove this pair of load and store
      bool saw_store = false;
      if (src_inst->getDesc().mayLoad() &&
          IsMemOpsEqual(src_memop, store_memop) &&
          src_memop->getOffset() == store_memop->getOffset() &&
          src_inst->isSafeToMove(AA, saw_store))
      {
        if (F.getRegInfo().hasOneUse(src_op.getReg()))
        {
          DEBUG(dbgs() << "Removing dead load " << src_inst << "\n");
          src_inst->eraseFromParent();
        }
        DEBUG(dbgs() << "Removing dead store " << store_inst << "\n");
        store_inst->eraseFromParent();
        ret_code = true;
      }
    }
  }
  
  return ret_code;
}

bool HSAILOptimizeMemoryOps::MoveKernargs(MachineFunction &F)
{
  bool made_change = false;
  
  LI = &getAnalysis<LoopInfoWrapperPass>().getLoopInfo();
  PDT = &getAnalysis<PostDominatorTree>();
  const MachineRegisterInfo &MRI = F.getRegInfo();

  MachineBasicBlock *entry_bb = &F.front();
  if (entry_bb->pred_size() != 0)
    return false; // First basicblock is not an entry to the function

  bool in_arg_scope = false;
  for (MachineBasicBlock::iterator it = entry_bb->begin(), 
       it_end = entry_bb->end(); it != it_end; )
  {
    MachineInstr *kernarg_inst = &*it++;
    unsigned op = kernarg_inst->getOpcode();

    if (op == HSAIL::ARG_SCOPE_START) {
      in_arg_scope = true;
      continue;
    }

    if (in_arg_scope) {
      if (op == HSAIL::ARG_SCOPE_END)
        in_arg_scope = false;
      continue;
    }

    if (!HSAILisArgInst(TII, kernarg_inst))
      continue;

    // Do not move glued loads in an argscope.
    if (kernarg_inst->isInsideBundle() || kernarg_inst->isNotDuplicable())
      continue;

    // Do not bother with multiple uses
    if (!MRI.hasOneUse(kernarg_inst->getOperand(0).getReg()))
      continue;

    // Determine place where to move

    MachineBasicBlock *new_position = nullptr;
    for (MachineInstr::const_mop_iterator DI = kernarg_inst->operands_begin(),
         DE = DI + kernarg_inst->getDesc().getNumDefs(); DI != DE; ++DI) {
      if (MRI.use_empty(DI->getReg()))
        continue;
      MachineRegisterInfo::use_instr_iterator UI = MRI.use_instr_begin(DI->getReg());
      MachineInstr *user = &*UI;
      MachineBasicBlock *new_pos_temp = user->getParent();

      if (user->isPHI())
      {
        // Jump to the correct phi predeccessor 
        unsigned i, e;
        for (i = 1, e = user->getNumOperands(); i < e; i += 2)
          if (user->getOperand(i).getReg() == DI->getReg())
          {
            new_pos_temp = user->getOperand(i + 1).getMBB();
            break;
          }
        assert(i < e && "Unable to find use in PHI node");
      }
      if (new_position && new_pos_temp != new_position) {
        // Different defs of the instruction are used in different basic blocks.
        new_position = nullptr;
        break;
      }
      new_position = new_pos_temp;
    }
    if (!new_position)
      continue;

    // Check that user is inside any control flow
    if (PDT->dominates(
          const_cast<BasicBlock*>(new_position->getBasicBlock()),
          const_cast<BasicBlock*>(entry_bb->getBasicBlock())))
    {
      continue;
    }

    // If it is inside loop
    if (LI->getLoopFor(new_position->getBasicBlock()))
      continue;

    // Ok, it's safe to move this kernarg into the begginning of new_position
    kernarg_inst->removeFromParent();
    new_position->insert(new_position->getFirstNonPHI(), kernarg_inst);
    made_change = true;

    // Reset iterator
    it = entry_bb->begin();
  }

  return made_change;
}

bool HSAILOptimizeMemoryOps::runOnMachineFunction(MachineFunction &F)
{
  bool ret_code = false;

  AA = &getAnalysis<AliasAnalysis>();
  TII = TM.getSubtargetImpl()->getInstrInfo();

  if (EnableHsailDSE)
    ret_code |= EliminateDeadStores(F);
  if (EnableMoveKernargs)
    ret_code |= MoveKernargs(F);
  if (EnableVecLdSt) {
    ret_code |= rescheduleCopyOperations(F);
    ret_code |= MergeLoadsStores(F);
  }

  return ret_code;
}
