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
#include "HSAILRegisterInfo.h"
#include "HSAILMachineFunctionInfo.h"
#include "HSAILSubtarget.h"
#include "HSAILTargetMachine.h"
#include "llvm/Constants.h"
#include "llvm/Function.h"
#include "llvm/Type.h"
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

HSAILRegisterInfo::HSAILRegisterInfo(HSAILTargetMachine &tm,
                                     const TargetInstrInfo &tii)
  : HSAILGenRegisterInfo(0, 0), TM(tm), TII(tii) {}

/// getCalleeSavedRegs - Return a null-terminated list of all of the
/// callee saved registers on this target. The register should be in the
/// order of desired callee-save stack frame offset. The first register is
/// closed to the incoming stack pointer if stack grows down, and vice versa.
const uint16_t*
HSAILRegisterInfo::getCalleeSavedRegs(const MachineFunction *MF) const
{
  static const uint16_t CalleeSavedRegs[] = { 0 };
  return CalleeSavedRegs;
}

/// getRegsAvailable - Return all available registers in the register class
/// in Mask.
BitVector
HSAILRegisterInfo::getRegsAvailable(const TargetRegisterClass *RC) const
{
  BitVector Mask(getNumRegs());
  for (TargetRegisterClass::iterator I = RC->begin(), E = RC->end();
       I != E; ++I)
    Mask.set(*I);
  return Mask;
}

/// getReservedRegs - Returns a bitset indexed by physical register number
/// indicating if a register is a special register that has particular uses
/// and should be considered unavailable at all times, e.g. SP, RA. This is
/// used by register scavenger to determine what registers are free.
BitVector
HSAILRegisterInfo::getReservedRegs(const MachineFunction &MF) const
{
  BitVector Reserved(getNumRegs());

  // We can have up to 128 s-registers, but we should have (s + 2*d + 4*q) <= 128.
  // Let's calulate the number of 32 and 64 bit VRs used in the function
  // and partition register file accordingly.
  static std::map<unsigned, unsigned> FunctionToRegPartionMap;
  unsigned NumSlotsTotal = HSAIL::GPR64RegClass.getNumRegs();
  // Default register file partitioning 64 s-regs + 32 d-regs, RegSlots = 32.
  unsigned RegSlots = NumSlotsTotal / 2;

  // First query for this function, calculate register use
  if (FunctionToRegPartionMap.find(MF.getFunctionNumber()) ==
      FunctionToRegPartionMap.end()) {
    const MachineRegisterInfo& RI = MF.getRegInfo();
    unsigned rc32 = 0, rc64 = 0;
    for( unsigned i = 0, e = RI.getNumVirtRegs(); i != e; ++i) {
      switch ( RI.getRegClass(index2VirtReg(i))->getSize() ) {
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
      // Calculate register file partitioning. We have 64 allocatable slots which
      // are either 1 d-register or a pair of s-registers. 8 slots are reserved
      // for 16 s-registers $s0..$s15, 8 are for 8 d-registers $d0..$d7.
      // Default partitioning is 64 s-registers + 32 d-registers, which is
      // RegSlots = 32

      // If we have a small amount of 64 bit VRs, but high 32 bit register
      // pressure reallocate slots to decrease 64 bit registers
      if( rc64 < (NumSlotsTotal - RegSlots) && rc32 > (RegSlots*2) ) {
        RegSlots = NumSlotsTotal - rc64;
      }
      // The opposite situation, we have a small demand on 32 bit registers but
      // high pressure for 64 bit
      else if( rc32 < (RegSlots*2) && rc64 > (NumSlotsTotal - RegSlots) ) {
        RegSlots = (rc32+1) / 2;
      }
    }

    // Always preserve room for at least 16 s-registers and 8 d-registers
    if (RegSlots < 8) RegSlots = 8;
    else if (RegSlots > (NumSlotsTotal - 8)) RegSlots = NumSlotsTotal - 8;

    FunctionToRegPartionMap[MF.getFunctionNumber()] = RegSlots;
    DEBUG(dbgs() << "\nFunction: " << MF.getFunction()->getName().data()
                 << " VR count: 32 bit = " << rc32 << ", 64 bit = " << rc64
                 << ", register file partitioning: " << RegSlots*2
                 << " $s + " << NumSlotsTotal-RegSlots << " $d\n\n");
  } else {
    RegSlots = FunctionToRegPartionMap[MF.getFunctionNumber()];
  }

  unsigned Reg;
  unsigned LastSReg = HSAIL::S0 + HSAIL::GPR32RegClass.getNumRegs() - 1;
  for( Reg = HSAIL::S0 + RegSlots*2 ; Reg <= LastSReg; ++Reg ) {
    Reserved.set(Reg);
  }
  unsigned LastDReg = HSAIL::D0 + HSAIL::GPR64RegClass.getNumRegs() - 1;
  for( Reg = HSAIL::D0 + (NumSlotsTotal - RegSlots) ; Reg <= LastDReg; ++Reg ) {
    Reserved.set(Reg);
  }

  return Reserved;
}

bool
HSAILRegisterInfo::trackLivenessAfterRegAlloc(const MachineFunction &MF) const {
  // Only enable when post-RA scheduling is enabled and this is needed.
  // TODO: HSA
  return true;
}

/// getSubReg - Returns the physical register number of sub-register "Index"
/// for physical register RegNo. Return zero if the sub-register does not
/// exist.
unsigned
HSAILRegisterInfo::getSubReg(unsigned RegNo, unsigned Index) const
{
  assert(!"When do we hit this?");
  return 0;
}

/// getSubRegIndex - For a given register pair, return the sub-register index
/// if the second register is a sub-register of the first. Return zero
/// otherwise.
unsigned
HSAILRegisterInfo::getSubRegIndex(unsigned RegNo, unsigned SubRegNo) const
{
  assert(!"When do we hit this?");
  return 0;
}

/// canCombineSubRegIndices - Given a register class and a list of
/// subregister indices, return true if it's possible to combine the
/// subregister indices into one that corresponds to a larger
/// subregister. Return the new subregister index by reference. Note the
/// new index may be zero if the given subregisters can be combined to
/// form the whole register.
bool
HSAILRegisterInfo::canCombineSubRegIndices(const TargetRegisterClass *RC,
                                           SmallVectorImpl<unsigned> &SubIndices,
                                           unsigned &NewSubIdx) const
{
  assert(!"When do we hit this?");
  return false;
}

/// getMatchingSuperRegClass - Return a subclass of the specified register
/// class A so that each register in it has a sub-register of the
/// specified sub-register index which is in the specified register class B.
const TargetRegisterClass*
HSAILRegisterInfo::getMatchingSuperRegClass(const TargetRegisterClass *A,
                                            const TargetRegisterClass *B,
                                            unsigned Idx) const
{
  assert(!"When do we hit this?");
  return NULL;
}

/// composeSubRegIndices - Return the subregister index you get from composing
/// two subregister indices.
///
/// If R:a:b is the same register as R:c, then composeSubRegIndices(a, b)
/// returns c. Note that composeSubRegIndices does not tell you about illegal
/// compositions. If R does not have a subreg a, or R:a does not have a subreg
/// b, composeSubRegIndices doesn't tell you.
///
/// The ARM register Q0 has two D subregs dsub_0:D0 and dsub_1:D1. It also has
/// ssub_0:S0 - ssub_3:S3 subregs.
/// If you compose subreg indices dsub_1, ssub_0 you get ssub_2.
unsigned
HSAILRegisterInfo::composeSubRegIndices(unsigned a, unsigned b) const
{
  assert(!"When do we hit this?");
  return 0;
}

/// getPointerRegClass - Returns a TargetRegisterClass used for pointer
/// values.  If a target supports multiple different pointer register classes,
/// kind specifies which one is indicated.
const TargetRegisterClass*
HSAILRegisterInfo::getPointerRegClass(const MachineFunction &MF,
		                      unsigned Kind) const
{
  assert(Kind == 0);

  if (TM.getSubtarget<HSAILSubtarget>().is64Bit())
    return &HSAIL::GPR64RegClass;
  return &HSAIL::GPR32RegClass;
}

/// getCrossCopyRegClass - Returns a legal register class to copy a register
/// in the specified class to or from. Returns NULL if it is possible to copy
/// between a two registers of the specified class.
const TargetRegisterClass*
HSAILRegisterInfo::getCrossCopyRegClass(const TargetRegisterClass *RC) const
{
  assert(!"When do we hit this?");
  return NULL;
}
#if 0
/// getAllocationOrder - Returns the register allocation order for a specified
/// register class in the form of a pair of TargetRegisterClass iterators.
std::pair<TargetRegisterClass::iterator,TargetRegisterClass::iterator>
HSAILRegisterInfo::getAllocationOrder(const TargetRegisterClass *RC,
                                      unsigned HintType,
                                      unsigned HintReg,
                                      const MachineFunction &MF) const
{
  assert(!"When do we hit this?");
  return std::pair<TargetRegisterClass::iterator,TargetRegisterClass::iterator>();
}
#endif
/// ResolveRegAllocHint - Resolves the specified register allocation hint
/// to a physical register. Returns the physical register if it is successful.
unsigned
HSAILRegisterInfo::ResolveRegAllocHint(unsigned Type,
                                       unsigned Reg,
                                       const MachineFunction &MF) const
{
  assert(!"When do we hit this?");
  return 0;
}

/// UpdateRegAllocHint - A callback to allow target a chance to update
/// register allocation hints when a register is "changed" (e.g. coalesced)
/// to another register. e.g. On ARM, some  registers should target
/// register pairs, if one of pair is coalesced to another register, the
/// allocation hint of the other half of the pair should be changed to point
/// to the new register.
void
HSAILRegisterInfo::UpdateRegAllocHint(unsigned Reg,
                                      unsigned NewReg,
                                      MachineFunction &MF) const
{
  //assert(!"When do we hit this?");
}

/// requiresRegisterScavenging - returns true if the target requires (and can
/// make use of) the register scavenger.
bool
HSAILRegisterInfo::requiresRegisterScavenging(const MachineFunction &MF) const
{
  return true;
}

/// requiresFrameIndexScavenging - returns true if the target requires post
/// PEI scavenging of registers for materializing frame index constants.
bool
HSAILRegisterInfo::requiresFrameIndexScavenging(const MachineFunction &MF) const
{
  return true;
}

#if 0
/// requiresVirtualBaseRegisters - Returns true if the target wants the
/// LocalStackAllocation pass to be run and  base registers
/// used for more efficient stack access.
bool
HSAILRegisterInfo::requiresVirtualBaseRegisters(const MachineFunction &MF) const
{
  assert(!"When do we hit this?");
  return false;
}
#endif
/// hasReservedSpillSlot - Return true if target has reserved a spill slot in
/// the stack frame of the given function for the specified register. e.g. On
/// x86, if the frame register is required, the first fixed stack object is
/// reserved as its spill slot. This tells PEI not to create a new stack frame
/// object for the given register. It should be called only after
/// processFunctionBeforeCalleeSavedScan().
bool
HSAILRegisterInfo::hasReservedSpillSlot(const MachineFunction &MF,
                                        unsigned Reg,
                                        int &FrameIdx) const
{
  assert(!"When do we hit this?");
  return false;
}
#if 0
/// needsStackRealignment - true if storage within the function requires the
/// stack pointer to be aligned more than the normal calling convention calls
/// for.
bool
HSAILRegisterInfo::needsStackRealignment(const MachineFunction &MF) const
{
  assert(!"When do we hit this?");
  return false;
}
#endif
/// getFrameIndexInstrOffset - Get the offset from the referenced frame
/// index in the instruction, if there is one.
int64_t
HSAILRegisterInfo::getFrameIndexInstrOffset(const MachineInstr *MI,
                                            int Idx) const
{
  assert(!"When do we hit this?");
  return 0;
}

/// needsFrameBaseReg - Returns true if the instruction's frame index
/// reference would be better served by a base register other than FP
/// or SP. Used by LocalStackFrameAllocation to determine which frame index
/// references it should create new base registers for.
bool
HSAILRegisterInfo::needsFrameBaseReg(MachineInstr *MI, int64_t Offset) const
{
  assert(!"When do we hit this?");
  return false;
}

/// materializeFrameBaseRegister - Insert defining instruction(s) for
/// BaseReg to be a pointer to FrameIdx before insertion point I.
void
HSAILRegisterInfo::materializeFrameBaseRegister(MachineBasicBlock *MBB,
                                                unsigned BaseReg,
                                                int FrameIdx,
                                                int64_t Offset) const
{
  assert(!"When do we hit this?");
}

/// resolveFrameIndex - Resolve a frame index operand of an instruction
/// to reference the indicated base register plus offset instead.
void
HSAILRegisterInfo::resolveFrameIndex(MachineBasicBlock::iterator I,
                                     unsigned BaseReg,
                                     int64_t Offset) const
{
  assert(!"When do we hit this?");
}

/// isFrameOffsetLegal - Determine whether a given offset immediate is
/// encodable to resolve a frame index.
bool
HSAILRegisterInfo::isFrameOffsetLegal(const MachineInstr *MI,
                                      int64_t Offset) const
{
  assert(!"When do we hit this?");
  return false;
}

/// eliminateCallFramePseudoInstr - This method is called during prolog/epilog
/// code insertion to eliminate call frame setup and destroy pseudo
/// instructions (but only if the Target is using them).  It is responsible
/// for eliminating these instructions, replacing them with concrete
/// instructions.  This method need only be implemented if using call frame
/// setup/destroy pseudo instructions.
///
void
HSAILRegisterInfo::eliminateCallFramePseudoInstr(MachineFunction &MF,
                                                 MachineBasicBlock &MBB,
                                                 MachineBasicBlock::iterator MI) const
{
  MBB.erase(MI);
}


/// saveScavengerRegister - Spill the register so it can be used by the
/// register scavenger. Return true if the register was spilled, false
/// otherwise. If this function does not spill the register, the scavenger
/// will instead spill it to the emergency spill slot.
///
bool
HSAILRegisterInfo::saveScavengerRegister(MachineBasicBlock &MBB,
                                         MachineBasicBlock::iterator I,
                                         MachineBasicBlock::iterator &UseMI,
                                         const TargetRegisterClass *RC,
                                         unsigned Reg) const
{
  MachineFunction *MF = MBB.getParent();
  MachineFrameInfo *MFI = MF->getFrameInfo();

  return saveScavengerRegisterToFI(MBB, I, UseMI, RC, Reg,
    MFI->CreateSpillStackObject(RC->getSize(), RC->getAlignment()));
}

// Save scavenger register and provide a frame index for it.
bool
HSAILRegisterInfo::saveScavengerRegisterToFI(MachineBasicBlock &MBB,
                                             MachineBasicBlock::iterator I,
                                             MachineBasicBlock::iterator &UseMI,
                                             const TargetRegisterClass *RC,
                                             unsigned Reg,
                                             int FI) const
{
  MachineFunction *MF = MBB.getParent();
  const TargetMachine &TM = MF->getTarget();
  const TargetRegisterInfo *TRI = TM.getRegisterInfo();
  const HSAILInstrInfo &HII = reinterpret_cast<const HSAILInstrInfo&>(TII);
  RegScavenger *RS = HII.getRS();

  assert(RS != 0 && "Register scavenger has not been created");

  // Setup emergency spill location
  RS->setScavengingFrameIndex(FI);

  assert(RS->getScavengingFrameIndex() >= 0 &&
         "Cannot scavenge register without an emergency spill slot!");

  // Store the scavenged register to its stack spill location
  HII.storeRegToStackSlot(MBB, I, Reg, true /* isKill */, RS->getScavengingFrameIndex(), RC, TRI);

  // Restore the scavenged register before its use (or first terminator).
  HII.loadRegFromStackSlot(MBB, UseMI, Reg, RS->getScavengingFrameIndex(), RC, TRI);

  // HSAIL Target saves/restores the scavenged register
  return true;
}

/// eliminateFrameIndex - This method must be overriden to eliminate abstract
/// frame indices from instructions which may use them.  The instruction
/// referenced by the iterator contains an MO_FrameIndex operand which must be
/// eliminated by this method.  This method may modify or replace the
/// specified instruction, as long as it keeps the iterator pointing at the
/// finished product. SPAdj is the SP adjustment due to call frame setup
/// instruction.
void
HSAILRegisterInfo::eliminateFrameIndex(MachineBasicBlock::iterator II,
                                       int SPAdj,
                                       RegScavenger *RS) const
{
  assert(SPAdj == 0 && "Unexpected");
  MachineInstr &MI = *II;
  MachineFunction &MF = *MI.getParent()->getParent();
  // FrameIndex to Offset translation is usually performed by the
  // target-specific implementation of TargetFrameLowering
  const TargetFrameLowering *TFL = MF.getTarget().getFrameLowering();
  
  unsigned int y = MI.getNumOperands();
  for (unsigned int x = 0; x < y; ++x) {
    if (!MI.getOperand(x).isFI()) {
      continue;
    }
    int FrameIndex = MI.getOperand(x).getIndex();
    int64_t Offset = TFL->getFrameIndexOffset(MF, FrameIndex);
    //int64_t Size = MF.getFrameInfo()->getObjectSize(FrameIndex);
    // An optimization is to only use the offsets if the size
    // is larger than 4, which means we are storing an array
    // instead of just a pointer. If we are size 4 then we can
    // just do register copies since we don't need to worry about
    // indexing dynamically
    if (MI.getOperand(x).isImm() == false)  {
      MI.getOperand(x).ChangeToImmediate(Offset);
    } else {
      MI.getOperand(x).setImm(Offset);
    }
  }
}

//===--------------------------------------------------------------------===//
/// Debug information queries.

/// getDwarfRegNum - Map a target register to an equivalent dwarf register
/// number.  Returns -1 if there is no equivalent value.  The second
/// parameter allows targets to use different numberings for EH info and
/// debugging info.
/*
int
HSAILRegisterInfo::getDwarfRegNum(unsigned RegNum, bool isEH) const
{
  // We only support 32 bit dwarf registers right now.
  unsigned Flavour = DWARFFlavour::HSAIL_Generic;
  return HSAILGenRegisterInfo::getDwarfRegNumFull( RegNum, Flavour );
}
*/
/// getFrameRegister - This method should return the register used as a base
/// for values allocated in the current stack frame.
unsigned
HSAILRegisterInfo::getFrameRegister(const MachineFunction &MF) const
{
  //This value is unused in LLVM
  return HSAIL::NoRegister;
}

/// getRARegister - This method should return the register where the return
/// address can be found.
unsigned
HSAILRegisterInfo::getRARegister() const
{
  assert(!"When do we hit this?");
  return 0;
}

/// getRegPressureLimit - Return the register pressure "high water mark" for
/// the specific register class. The scheduler is in high register pressure
/// mode (for the specific register class) if it goes over the limit.
unsigned
HSAILRegisterInfo::getRegPressureLimit(const TargetRegisterClass *RC,
                                         MachineFunction &MF) const
{
#ifdef _DEBUG
  std::string env("AMD_DEBUG_HSAIL_REGPRESSURELIMIT_");
  env.append(RC->getName());
  const char* pLimit = std::getenv(env.c_str());
  static unsigned reported = 0;
  reported++;
  if (pLimit) {
    unsigned limit = (unsigned)std::atoi(pLimit);
    if (reported <= getNumRegClasses())
      printf("Register pressure limit override for %s is %u\n", RC->getName(), limit);
    return limit;
  }
#endif
  if (RC == &HSAIL::GPR32RegClass) {
    return HSAILReg32PressureLimit;
  }
  if (RC == &HSAIL::GPR64RegClass) {
    return HSAILReg64PressureLimit;
  }
  return 0;
}

#define GET_REGINFO_MC_DESC
#define GET_REGINFO_TARGET_DESC
#include "HSAILGenRegisterInfo.inc"
