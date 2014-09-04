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

#include "llvm/Target/TargetInstrInfo.h"
#include "HSAIL.h"
#include "HSAILRegisterInfo.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"

#define GET_INSTRINFO_HEADER
#include "HSAILGenInstrInfo.inc"

namespace llvm {
  class HSAILRegisterInfo;
  class HSAILSubtarget;
  class HSAILTargetMachine;
  class RegScavenger;

namespace HSAIL {
  // Enums for memory operand decoding.  Each memory operand is represented with
  // a 5 operand sequence in the form:
  //   [BaseReg, ScaleAmt, IndexReg, Disp, Segment]
  // These enums help decode this.
  enum {
    AddrBaseReg = 0,
    AddrScaleAmt = 1,
    AddrIndexReg = 2,
    AddrDisp = 3,

    /// AddrSegmentReg - The operand # of the segment in the memory operand.
    AddrSegmentReg = 4,

    /// AddrNumOperands - Total number of operands in a memory reference.
    AddrNumOperands = 5
    };

    // HSAIL specific condition code. These correspond to HSAIL_*_COND in
    // HSAILInstrInfo.td. They must be kept in synch.
  enum CondCode {
    COND_A  = 0,
    COND_AE = 1,
    COND_B  = 2,
    COND_BE = 3,
    COND_E  = 4,
    COND_G  = 5,
    COND_GE = 6,
    COND_L  = 7,
    COND_LE = 8,
    COND_NE = 9,
    COND_NO = 10,
    COND_NP = 11,
    COND_NS = 12,
    COND_O  = 13,
    COND_P  = 14,
    COND_S  = 15,

    // Artificial condition codes. These are used by AnalyzeBranch
    // to indicate a block terminated with two conditional branches to
    // the same location. This occurs in code using FCMP_OEQ or FCMP_UNE,
    // which can't be represented on x86 with a single condition. These
    // are never used in MachineInstrs.
    COND_NE_OR_P,
    COND_NP_OR_E,

    COND_INVALID
  };

  // Turn condition code into conditional branch opcode.
  unsigned GetCondBranchFromCond(CondCode CC);

  /// GetOppositeBranchCondition - Return the inverse of the specified cond,
  /// e.g. turning COND_E to COND_NE.
  CondCode GetOppositeBranchCondition(HSAIL::CondCode CC);

}

/// HSAILII - This namespace holds all of the target specific flags that
/// instruction info tracks.
///
namespace HSAILII {
  /// Target Operand Flag enum.
  enum TOF {
    //===------------------------------------------------------------------===//
    // HSAIL Specific MachineOperand flags.

    MO_NO_FLAG,

    /// MO_GOT_ABSOLUTE_ADDRESS - On a symbol operand, this represents a
    /// relocation of:
    ///    SYMBOL_LABEL + [. - PICBASELABEL]
    MO_GOT_ABSOLUTE_ADDRESS,

    /// MO_PIC_BASE_OFFSET - On a symbol operand this indicates that the
    /// immediate should get the value of the symbol minus the PIC base label:
    ///    SYMBOL_LABEL - PICBASELABEL
    MO_PIC_BASE_OFFSET,

    /// MO_GOT - On a symbol operand this indicates that the immediate is the
    /// offset to the GOT entry for the symbol name from the base of the GOT.
    ///
    /// See the HSAIL-64 ELF ABI supplement for more details.
    ///    SYMBOL_LABEL @GOT
    MO_GOT,

    /// MO_GOTOFF - On a symbol operand this indicates that the immediate is
    /// the offset to the location of the symbol name from the base of the GOT.
    ///
    /// See the HSAIL-64 ELF ABI supplement for more details.
    ///    SYMBOL_LABEL @GOTOFF
    MO_GOTOFF,

    /// MO_GOTPCREL - On a symbol operand this indicates that the immediate is
    /// offset to the GOT entry for the symbol name from the current code
    /// location.
    ///
    /// See the HSAIL-64 ELF ABI supplement for more details.
    ///    SYMBOL_LABEL @GOTPCREL
    MO_GOTPCREL,

    /// MO_PLT - On a symbol operand this indicates that the immediate is
    /// offset to the PLT entry of symbol name from the current code location.
    ///
    /// See the HSAIL-64 ELF ABI supplement for more details.
    ///    SYMBOL_LABEL @PLT
    MO_PLT,

    /// MO_TLSGD - On a symbol operand this indicates that the immediate is
    /// some TLS offset.
    ///
    /// See 'ELF Handling for Thread-Local Storage' for more details.
    ///    SYMBOL_LABEL @TLSGD
    MO_TLSGD,

    /// MO_GOTTPOFF - On a symbol operand this indicates that the immediate is
    /// some TLS offset.
    ///
    /// See 'ELF Handling for Thread-Local Storage' for more details.
    ///    SYMBOL_LABEL @GOTTPOFF
    MO_GOTTPOFF,

    /// MO_INDNTPOFF - On a symbol operand this indicates that the immediate is
    /// some TLS offset.
    ///
    /// See 'ELF Handling for Thread-Local Storage' for more details.
    ///    SYMBOL_LABEL @INDNTPOFF
    MO_INDNTPOFF,

    /// MO_TPOFF - On a symbol operand this indicates that the immediate is
    /// some TLS offset.
    ///
    /// See 'ELF Handling for Thread-Local Storage' for more details.
    ///    SYMBOL_LABEL @TPOFF
    MO_TPOFF,

    /// MO_NTPOFF - On a symbol operand this indicates that the immediate is
    /// some TLS offset.
    ///
    /// See 'ELF Handling for Thread-Local Storage' for more details.
    ///    SYMBOL_LABEL @NTPOFF
    MO_NTPOFF,

    /// MO_DLLIMPORT - On a symbol operand "FOO", this indicates that the
    /// reference is actually to the "__imp_FOO" symbol.  This is used for
    /// dllimport linkage on windows.
    MO_DLLIMPORT,

    /// MO_DARWIN_STUB - On a symbol operand "FOO", this indicates that the
    /// reference is actually to the "FOO$stub" symbol.  This is used for calls
    /// and jumps to external functions on Tiger and earlier.
    MO_DARWIN_STUB,

    /// MO_DARWIN_NONLAZY - On a symbol operand "FOO", this indicates that the
    /// reference is actually to the "FOO$non_lazy_ptr" symbol, which is a
    /// non-PIC-base-relative reference to a non-hidden dyld lazy pointer stub.
    MO_DARWIN_NONLAZY,

    /// MO_DARWIN_NONLAZY_PIC_BASE - On a symbol operand "FOO", this indicates
    /// that the reference is actually to "FOO$non_lazy_ptr - PICBASE", which is
    /// a PIC-base-relative reference to a non-hidden dyld lazy pointer stub.
    MO_DARWIN_NONLAZY_PIC_BASE,

    /// MO_DARWIN_HIDDEN_NONLAZY_PIC_BASE - On a symbol operand "FOO", this
    /// indicates that the reference is actually to "FOO$non_lazy_ptr -PICBASE",
    /// which is a PIC-base-relative reference to a hidden dyld lazy pointer
    /// stub.
    MO_DARWIN_HIDDEN_NONLAZY_PIC_BASE,

    /// MO_TLVP - On a symbol operand this indicates that the immediate is
    /// some TLS offset.
    ///
    /// This is the TLS offset for the Darwin TLS mechanism.
    MO_TLVP,

    /// MO_TLVP_PIC_BASE - On a symbol operand this indicates that the immediate
    /// is some TLS offset from the picbase.
    ///
    /// This is the 32-bit TLS offset for Darwin TLS in PIC mode.
    MO_TLVP_PIC_BASE
  };
}

/// HSAILII - This namespace holds all of the target specific flags that
/// instruction info tracks.
///
namespace HSAILII {
  enum {
    //===------------------------------------------------------------------===//
    // Instruction encodings.  These are the standard/most common forms for HSAIL
    // instructions.
    //

    // PseudoFrm - This represents an instruction that is a pseudo instruction
    // or one that has not been implemented yet.  It is illegal to code generate
    // it, but tolerated for intermediate implementation stages.
    Pseudo         = 0,

    /// Raw - This form is for instructions that don't have any operands, so
    /// they are just a fixed opcode value, like 'leave'.
    RawFrm         = 1,

    /// AddRegFrm - This form is used for instructions like 'push r32' that have
    /// their one register operand added to their opcode.
    AddRegFrm      = 2,

    /// MRMDestReg - This form is used for instructions that use the Mod/RM byte
    /// to specify a destination, which in this case is a register.
    ///
    MRMDestReg     = 3,

    /// MRMDestMem - This form is used for instructions that use the Mod/RM byte
    /// to specify a destination, which in this case is memory.
    ///
    MRMDestMem     = 4,

    /// MRMSrcReg - This form is used for instructions that use the Mod/RM byte
    /// to specify a source, which in this case is a register.
    ///
    MRMSrcReg      = 5,

    /// MRMSrcMem - This form is used for instructions that use the Mod/RM byte
    /// to specify a source, which in this case is memory.
    ///
    MRMSrcMem      = 6,

    /// MRM[0-7][rm] - These forms are used to represent instructions that use
    /// a Mod/RM byte, and use the middle field to hold extended opcode
    /// information.  In the intel manual these are represented as /0, /1, ...
    ///

    // First, instructions that operate on a register r/m operand...
    MRM0r = 16,  MRM1r = 17,  MRM2r = 18,  MRM3r = 19, // Format /0 /1 /2 /3
    MRM4r = 20,  MRM5r = 21,  MRM6r = 22,  MRM7r = 23, // Format /4 /5 /6 /7

    // Next, instructions that operate on a memory r/m operand...
    MRM0m = 24,  MRM1m = 25,  MRM2m = 26,  MRM3m = 27, // Format /0 /1 /2 /3
    MRM4m = 28,  MRM5m = 29,  MRM6m = 30,  MRM7m = 31, // Format /4 /5 /6 /7

    // MRMInitReg - This form is used for instructions whose source and
    // destinations are the same register.
    MRMInitReg = 32,

    //// MRM_C1 - A mod/rm byte of exactly 0xC1.
    MRM_C1 = 33,
    MRM_C2 = 34,
    MRM_C3 = 35,
    MRM_C4 = 36,
    MRM_C8 = 37,
    MRM_C9 = 38,
    MRM_E8 = 39,
    MRM_F0 = 40,
    MRM_F8 = 41,
    MRM_F9 = 42,
    MRM_D0 = 45,
    MRM_D1 = 46,

    /// RawFrmImm8 - This is used for the ENTER instruction, which has two
    /// immediates, the first of which is a 16-bit immediate (specified by
    /// the imm encoding) and the second is a 8-bit fixed value.
    RawFrmImm8 = 43,

    /// RawFrmImm16 - This is used for CALL FAR instructions, which have two
    /// immediates, the first of which is a 16 or 32-bit immediate (specified by
    /// the imm encoding) and the second is a 16-bit fixed value.  In the AMD
    /// manual, this operand is described as pntr16:32 and pntr16:16
    RawFrmImm16 = 44,

    FormMask       = 63,

    //===------------------------------------------------------------------===//
    // Actual flags...

    // OpSize - Set if this instruction requires an operand size prefix (0x66),
    // which most often indicates that the instruction operates on 16 bit data
    // instead of 32 bit data.
    OpSize      = 1 << 6,

    // AsSize - Set if this instruction requires an operand size prefix (0x67),
    // which most often indicates that the instruction address 16 bit address
    // instead of 32 bit address (or 32 bit address in 64 bit mode).
    AdSize      = 1 << 7,

    //===------------------------------------------------------------------===//
    // Op0Mask - There are several prefix bytes that are used to form two byte
    // opcodes.  These are currently 0x0F, 0xF3, and 0xD8-0xDF.  This mask is
    // used to obtain the setting of this field.  If no bits in this field is
    // set, there is no prefix byte for obtaining a multibyte opcode.
    //
    Op0Shift    = 8,
    Op0Mask     = 0xF << Op0Shift,

    // TB - TwoByte - Set if this instruction has a two byte opcode, which
    // starts with a 0x0F byte before the real opcode.
    TB          = 1 << Op0Shift,

    // REP - The 0xF3 prefix byte indicating repetition of the following
    // instruction.
    REP         = 2 << Op0Shift,

    // D8-DF - These escape opcodes are used by the floating point unit.  These
    // values must remain sequential.
    D8 = 3 << Op0Shift,   D9 = 4 << Op0Shift,
    DA = 5 << Op0Shift,   DB = 6 << Op0Shift,
    DC = 7 << Op0Shift,   DD = 8 << Op0Shift,
    DE = 9 << Op0Shift,   DF = 10 << Op0Shift,

    // XS, XD - These prefix codes are for single and double precision scalar
    // floating point operations performed in the SSE registers.
    XD = 11 << Op0Shift,  XS = 12 << Op0Shift,

    // T8, TA - Prefix after the 0x0F prefix.
    T8 = 13 << Op0Shift,  TA = 14 << Op0Shift,

    // TF - Prefix before and after 0x0F
    TF = 15 << Op0Shift,

    //===------------------------------------------------------------------===//
    // REX_W - REX prefixes are instruction prefixes used in 64-bit mode.
    // They are used to specify GPRs and SSE registers, 64-bit operand size,
    // etc. We only cares about REX.W and REX.R bits and only the former is
    // statically determined.
    //
    REXShift    = 12,
    REX_W       = 1 << REXShift,

    //===------------------------------------------------------------------===//
    // This three-bit field describes the size of an immediate operand.  Zero is
    // unused so that we can tell if we forgot to set a value.
    ImmShift = 13,
    ImmMask    = 7 << ImmShift,
    Imm8       = 1 << ImmShift,
    Imm8PCRel  = 2 << ImmShift,
    Imm16      = 3 << ImmShift,
    Imm16PCRel = 4 << ImmShift,
    Imm32      = 5 << ImmShift,
    Imm32PCRel = 6 << ImmShift,
    Imm64      = 7 << ImmShift,

    //===------------------------------------------------------------------===//
    // FP Instruction Classification...  Zero is non-fp instruction.

    // FPTypeMask - Mask for all of the FP types...
    FPTypeShift = 16,
    FPTypeMask  = 7 << FPTypeShift,

    // NotFP - The default, set for instructions that do not use FP registers.
    NotFP      = 0 << FPTypeShift,

    // ZeroArgFP - 0 arg FP instruction which implicitly pushes ST(0), f.e. fld0
    ZeroArgFP  = 1 << FPTypeShift,

    // OneArgFP - 1 arg FP instructions which implicitly read ST(0), such as fst
    OneArgFP   = 2 << FPTypeShift,

    // OneArgFPRW - 1 arg FP instruction which implicitly read ST(0) and write a
    // result back to ST(0).  For example, fcos, fsqrt, etc.
    //
    OneArgFPRW = 3 << FPTypeShift,

    // TwoArgFP - 2 arg FP instructions which implicitly read ST(0), and an
    // explicit argument, storing the result to either ST(0) or the implicit
    // argument.  For example: fadd, fsub, fmul, etc...
    TwoArgFP   = 4 << FPTypeShift,

    // CompareFP - 2 arg FP instructions which implicitly read ST(0) and an
    // explicit argument, but have no destination.  Example: fucom, fucomi, ...
    CompareFP  = 5 << FPTypeShift,

    // CondMovFP - "2 operand" floating point conditional move instructions.
    CondMovFP  = 6 << FPTypeShift,

    // SpecialFP - Special instruction forms.  Dispatch by opcode explicitly.
    SpecialFP  = 7 << FPTypeShift,

    // Lock prefix
    LOCKShift = 19,
    LOCK = 1 << LOCKShift,

    // Segment override prefixes. Currently we just need ability to address
    // stuff in gs and fs segments.
    SegOvrShift = 20,
    SegOvrMask  = 3 << SegOvrShift,
    FS          = 1 << SegOvrShift,
    GS          = 2 << SegOvrShift,

    // Execution domain for SSE instructions in bits 22, 23.
    // 0 in bits 22-23 means normal, non-SSE instruction.
    SSEDomainShift = 22,

    OpcodeShift   = 24,
    OpcodeMask    = 0xFF << OpcodeShift,

    //===------------------------------------------------------------------===//
    /// VEX - The opcode prefix used by AVX instructions
    VEX         = 1U << 0,

    /// VEX_W - Has a opcode specific functionality, but is used in the same
    /// way as REX_W is for regular SSE instructions.
    VEX_W       = 1U << 1,

    /// VEX_4V - Used to specify an additional AVX/SSE register. Several 2
    /// address instructions in SSE are represented as 3 address ones in AVX
    /// and the additional register is encoded in VEX_VVVV prefix.
    VEX_4V      = 1U << 2,

    /// VEX_I8IMM - Specifies that the last register used in a AVX instruction,
    /// must be encoded in the i8 immediate field. This usually happens in
    /// instructions with 4 operands.
    VEX_I8IMM   = 1U << 3,

    /// VEX_L - Stands for a bit in the VEX opcode prefix meaning the current
    /// instruction uses 256-bit wide registers. This is usually auto detected
    /// if a VR256 register is used, but some AVX instructions also have this
    /// field marked when using a f256 memory references.
    VEX_L       = 1U << 4,

    /// Has3DNow0F0FOpcode - This flag indicates that the instruction uses the
    /// wacky 0x0F 0x0F prefix for 3DNow! instructions.  The manual documents
    /// this as having a 0x0F prefix with a 0x0F opcode, and each instruction
    /// storing a classifier in the imm8 field.  To simplify our implementation,
    /// we handle this by storeing the classifier in the opcode field and using
    /// this flag to indicate that the encoder should do the wacky 3DNow! thing.
    Has3DNow0F0FOpcode = 1U << 5
  };


  static inline unsigned getSizeOfImm(uint64_t TSFlags) {
    switch (TSFlags & HSAILII::ImmMask) {
    default: assert(0 && "Unknown immediate size");
    case HSAILII::Imm8:
    case HSAILII::Imm8PCRel:  return 1;
    case HSAILII::Imm16:
    case HSAILII::Imm16PCRel: return 2;
    case HSAILII::Imm32:
    case HSAILII::Imm32PCRel: return 4;
    case HSAILII::Imm64:      return 8;
    }
  }

  /// isImmPCRel - Return true if the immediate of the specified instruction's
  /// TSFlags indicates that it is pc relative.
  static inline unsigned isImmPCRel(uint64_t TSFlags) {
    switch (TSFlags & HSAILII::ImmMask) {
    default: assert(0 && "Unknown immediate size");
    case HSAILII::Imm8PCRel:
    case HSAILII::Imm16PCRel:
    case HSAILII::Imm32PCRel:
      return true;
    case HSAILII::Imm8:
    case HSAILII::Imm16:
    case HSAILII::Imm32:
    case HSAILII::Imm64:
      return false;
    }
  }

  /// getMemoryOperandNo - The function returns the MCInst operand # for the
  /// first field of the memory operand.  If the instruction doesn't have a
  /// memory operand, this returns -1.
  ///
  /// Note that this ignores tied operands.  If there is a tied register which
  /// is duplicated in the MCInst (e.g. "EAX = addl EAX, [mem]") it is only
  /// counted as one operand.
  ///
  static inline int getMemoryOperandNo(uint64_t TSFlags) {
    switch (TSFlags & HSAILII::FormMask) {
    case HSAILII::MRMInitReg:  assert(0 && "FIXME: Remove this form");
    default: assert(0 && "Unknown FormMask value in getMemoryOperandNo!");
    case HSAILII::Pseudo:
    case HSAILII::RawFrm:
    case HSAILII::AddRegFrm:
    case HSAILII::MRMDestReg:
    case HSAILII::MRMSrcReg:
    case HSAILII::RawFrmImm8:
    case HSAILII::RawFrmImm16:
       return -1;
    case HSAILII::MRMDestMem:
      return 0;
    case HSAILII::MRMSrcMem: {
      bool HasVEX_4V = (TSFlags >> 32) & HSAILII::VEX_4V;
      unsigned FirstMemOp = 1;
      if (HasVEX_4V)
        ++FirstMemOp;// Skip the register source (which is encoded in VEX_VVVV).

      // FIXME: Maybe lea should have its own form?  This is a horrible hack.
      //if (Opcode == HSAIL::LEA64r || Opcode == HSAIL::LEA64_32r ||
      //    Opcode == HSAIL::LEA16r || Opcode == HSAIL::LEA32r)
      return FirstMemOp;
    }
    case HSAILII::MRM0r: case HSAILII::MRM1r:
    case HSAILII::MRM2r: case HSAILII::MRM3r:
    case HSAILII::MRM4r: case HSAILII::MRM5r:
    case HSAILII::MRM6r: case HSAILII::MRM7r:
      return -1;
    case HSAILII::MRM0m: case HSAILII::MRM1m:
    case HSAILII::MRM2m: case HSAILII::MRM3m:
    case HSAILII::MRM4m: case HSAILII::MRM5m:
    case HSAILII::MRM6m: case HSAILII::MRM7m:
      return 0;
    case HSAILII::MRM_C1:
    case HSAILII::MRM_C2:
    case HSAILII::MRM_C3:
    case HSAILII::MRM_C4:
    case HSAILII::MRM_C8:
    case HSAILII::MRM_C9:
    case HSAILII::MRM_E8:
    case HSAILII::MRM_F0:
    case HSAILII::MRM_F8:
    case HSAILII::MRM_F9:
    case HSAILII::MRM_D0:
    case HSAILII::MRM_D1:
      return -1;
    }
  }
}

inline static bool isScale(const MachineOperand &MO) {
  return MO.isImm() &&
    (MO.getImm() == 1 || MO.getImm() == 2 ||
     MO.getImm() == 4 || MO.getImm() == 8);
}

inline static bool isLeaMem(const MachineInstr *MI, unsigned Op) {
  if (MI->getOperand(Op).isFI()) return true;
  return Op+4 <= MI->getNumOperands() &&
    MI->getOperand(Op  ).isReg() && isScale(MI->getOperand(Op+1)) &&
    MI->getOperand(Op+2).isReg() &&
    (MI->getOperand(Op+3).isImm() ||
     MI->getOperand(Op+3).isGlobal() ||
     MI->getOperand(Op+3).isCPI() ||
     MI->getOperand(Op+3).isJTI());
}

inline static bool isMem(const MachineInstr *MI, unsigned Op) {
  if (MI->getOperand(Op).isFI()) return true;
  return Op+5 <= MI->getNumOperands() &&
    MI->getOperand(Op+4).isReg() &&
    isLeaMem(MI, Op);
}

  //class HSAILInstrInfo : public TargetInstrInfoImpl {
class HSAILInstrInfo : public HSAILGenInstrInfo {
  HSAILTargetMachine &TM;
  const HSAILRegisterInfo RI;

public:
  explicit HSAILInstrInfo(HSAILTargetMachine &tm);

  ~HSAILInstrInfo();

  /// getRegisterInfo - TargetInstrInfo is a superset of MRegister info.  As
  /// such, whenever a client has an instance of instruction info, it should
  /// always be able to get register info as well (through this method).
  virtual const HSAILRegisterInfo&
  getRegisterInfo() const
  {
    return RI;
  }

  /// isReallyTriviallyReMaterializable - For instructions with opcodes for
  /// which the M_REMATERIALIZABLE flag is set, this hook lets the target
  /// specify whether the instruction is actually trivially rematerializable,
  /// taking into consideration its operands. This predicate must return false
  /// if the instruction has any side effects other than producing a value, or
  /// if it requres any address registers that are not always available.
  virtual bool
  isReallyTriviallyReMaterializable(const MachineInstr *MI,
                                    AliasAnalysis *AA) const;

  /// isCoalescableExtInstr - Return true if the instruction is a "coalescable"
  /// extension instruction. That is, it's like a copy where it's legal for the
  /// source to overlap the destination. e.g. X86::MOVSX64rr32. If this returns
  /// true, then it's expected the pre-extension value is available as a subreg
  /// of the result register. This also returns the sub-register index in
  /// SubIdx.
  virtual bool
  isCoalescableExtInstr(const MachineInstr &MI,
                        unsigned &SrcReg, unsigned &DstReg,
                        unsigned &SubIdx) const;


   /// isLoadFromStackSlot - If the specified machine instruction is a direct
  /// load from a stack slot, return the virtual or physical register number of
  /// the destination along with the FrameIndex of the loaded stack slot.  If
  /// not, return 0.  This predicate must return 0 if the instruction has
  /// any side effects other than loading from the stack slot.
  virtual unsigned
  isLoadFromStackSlot(const MachineInstr *MI,
                      int &FrameIndex) const;


  /// isLoadFromStackSlotPostFE - Check for post-frame ptr elimination
  /// stack locations as well.  This uses a heuristic so it isn't
  /// reliable for correctness.
  virtual unsigned
  isLoadFromStackSlotPostFE(const MachineInstr *MI,
                            int &FrameIndex) const;


  /// hasLoadFromStackSlot - If the specified machine instruction has
  /// a load from a stack slot, return true along with the FrameIndex
  /// of the loaded stack slot and the machine mem operand containing
  /// the reference.  If not, return false.  Unlike
  /// isLoadFromStackSlot, this returns true for any instructions that
  /// loads from the stack.  This is just a hint, as some cases may be
  /// missed.
  virtual bool
  hasLoadFromStackSlot(const MachineInstr *MI,
                       const MachineMemOperand *&MMO,
                       int &FrameIndex) const;


  /// isStoreToStackSlot - If the specified machine instruction is a direct
  /// store to a stack slot, return the virtual or physical register number of
  /// the source reg along with the FrameIndex of the loaded stack slot.  If
  /// not, return 0.  This predicate must return 0 if the instruction has
  /// any side effects other than storing to the stack slot.
  virtual unsigned
  isStoreToStackSlot(const MachineInstr *MI,
                     int &FrameIndex) const;


  /// isStoreToStackSlotPostFE - Check for post-frame ptr elimination
  /// stack locations as well.  This uses a heuristic so it isn't
  /// reliable for correctness.
  virtual unsigned
  isStoreToStackSlotPostFE(const MachineInstr *MI,
                           int &FrameIndex) const;


  /// hasStoreToStackSlot - If the specified machine instruction has a
  /// store to a stack slot, return true along with the FrameIndex of
  /// the loaded stack slot and the machine mem operand containing the
  /// reference.  If not, return false.  Unlike isStoreToStackSlot,
  /// this returns true for any instructions that stores to the
  /// stack.  This is just a hint, as some cases may be missed.
  virtual bool
  hasStoreToStackSlot(const MachineInstr *MI,
                      const MachineMemOperand *&MMO,
                      int &FrameIndex) const;

  /// reMaterialize - Re-issue the specified 'original' instruction at the
  /// specific location targeting a new destination register.
  /// The register in Orig->getOperand(0).getReg() will be substituted by
  /// DestReg:SubIdx. Any existing subreg index is preserved or composed with
  /// SubIdx.
  virtual void
  reMaterialize(MachineBasicBlock &MBB,
                MachineBasicBlock::iterator MI,
                unsigned DestReg, unsigned SubIdx,
                const MachineInstr *Orig,
                const TargetRegisterInfo &TRI) const;

  /// duplicate - Create a duplicate of the Orig instruction in MF. This is like
  /// MachineFunction::CloneMachineInstr(), but the target may update operands
  /// that are required to be unique.
  ///
  /// The instruction must be duplicable as indicated by isNotDuplicable().
  virtual MachineInstr*
  duplicate(MachineInstr *Orig,
            MachineFunction &MF) const;

  /// convertToThreeAddress - This method must be implemented by targets that
  /// set the M_CONVERTIBLE_TO_3_ADDR flag.  When this flag is set, the target
  /// may be able to convert a two-address instruction into one or more true
  /// three-address instructions on demand.  This allows the X86 target (for
  /// example) to convert ADD and SHL instructions into LEA instructions if they
  /// would require register copies due to two-addressness.
  ///
  /// This method returns a null pointer if the transformation cannot be
  /// performed, otherwise it returns the last new instruction.
  ///
  virtual MachineInstr*
  convertToThreeAddress(MachineFunction::iterator &MFI,
                        MachineBasicBlock::iterator &MBBI,
                        LiveVariables *LV) const;

  /// commuteInstruction - If a target has any instructions that are
  /// commutable but require converting to different instructions or making
  /// non-trivial changes to commute them, this method can overloaded to do
  /// that.  The default implementation simply swaps the commutable operands.
  /// If NewMI is false, MI is modified in place and returned; otherwise, a
  /// new machine instruction is created and returned.  Do not call this
  /// method for a non-commutable instruction, but there may be some cases
  /// where this method fails and returns null.
  virtual MachineInstr*
  commuteInstruction(MachineInstr *MI,
                     bool NewMI = false) const;

  /// findCommutedOpIndices - If specified MI is commutable, return the two
  /// operand indices that would swap value. Return false if the instruction
  /// is not in a form which this routine understands.
  virtual bool
  findCommutedOpIndices(MachineInstr *MI,
                        unsigned &SrcOpIdx1,
                        unsigned &SrcOpIdx2) const;

  /// produceSameValue - Return true if two machine instructions would produce
  /// identical values. By default, this is only true when the two instructions
  /// are deemed identical except for defs. If this function is called when the
  /// IR is still in SSA form, the caller can pass the MachineRegisterInfo for
  /// aggressive checks.
  virtual bool
  produceSameValue(const MachineInstr *MI0,
                   const MachineInstr *MI1,
                   const MachineRegisterInfo *MRI = 0) const;

  /// AnalyzeBranch - Analyze the branching code at the end of MBB, returning
  /// true if it cannot be understood (e.g. it's a switch dispatch or isn't
  /// implemented for a target).  Upon success, this returns false and returns
  /// with the following information in various cases:
  ///
  /// 1. If this block ends with no branches (it just falls through to its succ)
  ///    just return false, leaving TBB/FBB null.
  /// 2. If this block ends with only an unconditional branch, it sets TBB to be
  ///    the destination block.
  /// 3. If this block ends with a conditional branch and it falls through to a
  ///    successor block, it sets TBB to be the branch destination block and a
  ///    list of operands that evaluate the condition. These operands can be
  ///    passed to other TargetInstrInfo methods to create new branches.
  /// 4. If this block ends with a conditional branch followed by an
  ///    unconditional branch, it returns the 'true' destination in TBB, the
  ///    'false' destination in FBB, and a list of operands that evaluate the
  ///    condition.  These operands can be passed to other TargetInstrInfo
  ///    methods to create new branches.
  ///
  /// Note that RemoveBranch and InsertBranch must be implemented to support
  /// cases where this method returns success.
  ///
  /// If AllowModify is true, then this routine is allowed to modify the basic
  /// block (e.g. delete instructions after the unconditional branch).
  ///
  virtual bool
  AnalyzeBranch(MachineBasicBlock &MBB,
                MachineBasicBlock *&TBB,
                MachineBasicBlock *&FBB,
                SmallVectorImpl<MachineOperand> &Cond,
                bool AllowModify = false) const
  {
    return AnalyzeBranch(MBB, TBB, FBB, Cond, AllowModify, false);
  }

  bool
  AnalyzeBranch(MachineBasicBlock &MBB,
                MachineBasicBlock *&TBB,
                MachineBasicBlock *&FBB,
                SmallVectorImpl<MachineOperand> &Cond,
                bool AllowModify = false,
                bool IgnoreDependencies = false) const;

  /// RemoveBranch - Remove the branching code at the end of the specific MBB.
  /// This is only invoked in cases where AnalyzeBranch returns success. It
  /// returns the number of instructions that were removed.
  virtual unsigned
  RemoveBranch(MachineBasicBlock &MBB) const;

  /// InsertBranch - Insert branch code into the end of the specified
  /// MachineBasicBlock.  The operands to this method are the same as those
  /// returned by AnalyzeBranch.  This is only invoked in cases where
  /// AnalyzeBranch returns success. It returns the number of instructions
  /// inserted.
  ///
  /// It is also invoked by tail merging to add unconditional branches in
  /// cases where AnalyzeBranch doesn't apply because there was no original
  /// branch to analyze.  At least this much must be implemented, else tail
  /// merging needs to be disabled.
  virtual unsigned
  InsertBranch(MachineBasicBlock &MBB,
               MachineBasicBlock *TBB,
               MachineBasicBlock *FBB,
               const SmallVectorImpl<MachineOperand> &Cond,
               DebugLoc DL) const;

  /// ReplaceTailWithBranchTo - Delete the instruction OldInst and everything
  /// after it, replacing it with an unconditional branch to NewDest. This is
  /// used by the tail merging pass.
  virtual void
  ReplaceTailWithBranchTo(MachineBasicBlock::iterator Tail,
                          MachineBasicBlock *NewDest) const;

  /// isLegalToSplitMBBAt - Return true if it's legal to split the given basic
  /// block at the specified instruction (i.e. instruction would be the start
  /// of a new basic block).
  virtual bool
  isLegalToSplitMBBAt(MachineBasicBlock &MBB,
                      MachineBasicBlock::iterator MBBI) const;

  /// isProfitableToIfCvt - Return true if it's profitable to predicate
  /// instructions with accumulated instruction latency of "NumCycles"
  /// of the specified basic block, where the probability of the instructions
  /// being executed is given by Probability, and Confidence is a measure
  /// of our confidence that it will be properly predicted.
  virtual bool
  isProfitableToIfCvt(MachineBasicBlock &MBB,
                      unsigned NumCyles,
                      unsigned ExtraPredCycles,
		      const BranchProbability &Probability) const;
                      

  /// isProfitableToIfCvt - Second variant of isProfitableToIfCvt, this one
  /// checks for the case where two basic blocks from true and false path
  /// of a if-then-else (diamond) are predicated on mutally exclusive
  /// predicates, where the probability of the true path being taken is given
  /// by Probability, and Confidence is a measure of our confidence that it
  /// will be properly predicted.
  virtual bool
  isProfitableToIfCvt(MachineBasicBlock &TMBB,
                      unsigned NumTCycles,
                      unsigned ExtraTCycles,
                      MachineBasicBlock &FMBB,
                      unsigned NumFCycles,
                      unsigned ExtraFCycles,
		      const BranchProbability &Probability) const;
                      

  /// isProfitableToDupForIfCvt - Return true if it's profitable for
  /// if-converter to duplicate instructions of specified accumulated
  /// instruction latencies in the specified MBB to enable if-conversion.
  /// The probability of the instructions being executed is given by
  /// Probability, and Confidence is a measure of our confidence that it
  /// will be properly predicted.
  virtual bool
  isProfitableToDupForIfCvt(MachineBasicBlock &MBB,
                            unsigned NumCyles,
			    const BranchProbability &Probability) const;

  /// copyPhysReg - Emit instructions to copy a pair of physical registers.
  virtual void
  copyPhysReg(MachineBasicBlock &MBB,
              MachineBasicBlock::iterator MI,
              DebugLoc DL,
              unsigned DestReg,
              unsigned SrcReg,
              bool KillSrc) const;

  /// storeRegToStackSlot - Store the specified register of the given register
  /// class to the specified stack frame index. The store instruction is to be
  /// added to the given machine basic block before the specified machine
  /// instruction. If isKill is true, the register operand is the last use and
  /// must be marked kill.
  virtual void
  storeRegToStackSlot(MachineBasicBlock &MBB,
                      MachineBasicBlock::iterator MI,
                      unsigned SrcReg,
                      bool isKill,
                      int FrameIndex,
                      const TargetRegisterClass *RC,
                      const TargetRegisterInfo *TRI) const;

  /// loadRegFromStackSlot - Load the specified register of the given register
  /// class from the specified stack frame index. The load instruction is to be
  /// added to the given machine basic block before the specified machine
  /// instruction.
  virtual void
  loadRegFromStackSlot(MachineBasicBlock &MBB,
                       MachineBasicBlock::iterator MI,
                       unsigned DestReg,
                       int FrameIndex,
                       const TargetRegisterClass *RC,
                       const TargetRegisterInfo *TRI) const;

  /// emitFrameIndexDebugValue - Emit a target-dependent form of
  /// DBG_VALUE encoding the address of a frame index.  Addresses would
  /// normally be lowered the same way as other addresses on the target,
  /// e.g. in load instructions.  For targets that do not support this
  /// the debug info is simply lost.
  /// If you add this for a target you should handle this DBG_VALUE in the
  /// target-specific AsmPrinter code as well; you will probably get invalid
  /// assembly output if you don't.
  virtual MachineInstr*
  emitFrameIndexDebugValue(MachineFunction &MF,
                           int FrameIx,
                           uint64_t Offset,
                           const MDNode *MDPtr,
                           DebugLoc dl) const;
protected:
  /// foldMemoryOperandImpl - Target-dependent implementation for
  /// foldMemoryOperand. Target-independent code in foldMemoryOperand will
  /// take care of adding a MachineMemOperand to the newly created instruction.
  virtual MachineInstr*
  foldMemoryOperandImpl(MachineFunction &MF,
                        MachineInstr* MI,
                        const SmallVectorImpl<unsigned> &Ops,
                        int FrameIndex) const;

  /// foldMemoryOperandImpl - Target-dependent implementation for
  /// foldMemoryOperand. Target-independent code in foldMemoryOperand will
  /// take care of adding a MachineMemOperand to the newly created instruction.
  virtual MachineInstr*
  foldMemoryOperandImpl(MachineFunction &MF,
                        MachineInstr* MI,
                        const SmallVectorImpl<unsigned> &Ops,
                        MachineInstr* LoadMI) const;
public:
  /// canFoldMemoryOperand - Returns true for the specified load / store if
  /// folding is possible.
  virtual bool
  canFoldMemoryOperand(const MachineInstr *MI,
                       const SmallVectorImpl<unsigned> &Ops) const;

  /// unfoldMemoryOperand - Separate a single instruction which folded a load or
  /// a store or a load and a store into two or more instruction. If this is
  /// possible, returns true as well as the new instructions by reference.
  virtual bool
  unfoldMemoryOperand(MachineFunction &MF,
                      MachineInstr *MI,
                      unsigned Reg,
                      bool UnfoldLoad,
                      bool UnfoldStore,
                      SmallVectorImpl<MachineInstr*> &NewMIs) const;

  virtual bool
  unfoldMemoryOperand(SelectionDAG &DAG, SDNode *N,
                      SmallVectorImpl<SDNode*> &NewNodes) const;

  /// getOpcodeAfterMemoryUnfold - Returns the opcode of the would be new
  /// instruction after load / store are unfolded from an instruction of the
  /// specified opcode. It returns zero if the specified unfolding is not
  /// possible. If LoadRegIndex is non-null, it is filled in with the operand
  /// index of the operand which will hold the register holding the loaded
  /// value.
  virtual unsigned
  getOpcodeAfterMemoryUnfold(unsigned Opc,
                             bool UnfoldLoad,
                             bool UnfoldStore,
                             unsigned *LoadRegIndex = 0) const;

  /// areLoadsFromSameBasePtr - This is used by the pre-regalloc scheduler
  /// to determine if two loads are loading from the same base address. It
  /// should only return true if the base pointers are the same and the
  /// only differences between the two addresses are the offset. It also returns
  /// the offsets by reference.
  virtual bool
  areLoadsFromSameBasePtr(SDNode *Node1,
                          SDNode *Node2,
                          int64_t &Offset1,
                          int64_t &Offset2) const;

  /// shouldScheduleLoadsNear - This is a used by the pre-regalloc scheduler to
  /// determine (in conjuction with areLoadsFromSameBasePtr) if two loads should
  /// be scheduled togther. On some targets if two loads are loading from
  /// addresses in the same cache line, it's better if they are scheduled
  /// together. This function takes two integers that represent the load offsets
  /// from the common base address. It returns true if it decides it's desirable
  /// to schedule the two loads together. "NumLoads" is the number of loads that
  /// have already been scheduled after Load1.
  virtual bool
  shouldScheduleLoadsNear(SDNode *Node1,
                          SDNode *Node2,
                          int64_t Offset1,
                          int64_t Offset2,
                          unsigned NumLoads) const;

  /// ReverseBranchCondition - Reverses the branch condition of the specified
  /// condition list, returning false on success and true if it cannot be
  /// reversed.
  virtual bool
  ReverseBranchCondition(SmallVectorImpl<MachineOperand> &Cond) const;

  /// insertNoop - Insert a noop into the instruction stream at the specified
  /// point.
  virtual void
  insertNoop(MachineBasicBlock &MBB,
             MachineBasicBlock::iterator MI) const;

  /// isPredicated - Returns true if the instruction is already predicated.
  ///
  virtual bool
  isPredicated(const MachineInstr *MI) const;

  /// isUnpredicatedTerminator - Returns true if the instruction is a
  /// terminator instruction that has not been predicated.
  virtual bool
  isUnpredicatedTerminator(const MachineInstr *MI) const;

  /// PredicateInstruction - Convert the instruction into a predicated
  /// instruction. It returns true if the operation was successful.
  virtual bool
  PredicateInstruction(MachineInstr *MI,
                       const SmallVectorImpl<MachineOperand> &Pred) const;

  /// SubsumesPredicate - Returns true if the first specified predicate
  /// subsumes the second, e.g. GE subsumes GT.
  virtual bool
  SubsumesPredicate(const SmallVectorImpl<MachineOperand> &Pred1,
                    const SmallVectorImpl<MachineOperand> &Pred2) const;

  /// DefinesPredicate - If the specified instruction defines any predicate
  /// or condition code register(s) used for predication, returns true as well
  /// as the definition predicate(s) by reference.
  virtual bool
  DefinesPredicate(MachineInstr *MI,
                   std::vector<MachineOperand> &Pred) const;

  /// isPredicable - Return true if the specified instruction can be predicated.
  /// By default, this returns true for every instruction with a
  /// PredicateOperand.
  virtual bool
  isPredicable(MachineInstr *MI) const;

  /// isSafeToMoveRegClassDefs - Return true if it's safe to move a machine
  /// instruction that defines the specified register class.
  virtual bool
  isSafeToMoveRegClassDefs(const TargetRegisterClass *RC) const;

  /// isSchedulingBoundary - Test if the given instruction should be
  /// considered a scheduling boundary. This primarily includes labels and
  /// terminators.
  virtual bool
  isSchedulingBoundary(const MachineInstr *MI,
                       const MachineBasicBlock *MBB,
                       const MachineFunction &MF) const;

  /// Measure the specified inline asm to determine an approximation of its
  /// length.
  virtual unsigned
  getInlineAsmLength(const char *Str,
                     const MCAsmInfo &MAI) const;

  /// CreateTargetHazardRecognizer - Allocate and return a hazard recognizer to
  /// use for this target when scheduling the machine instructions before
  /// register allocation.
  virtual ScheduleHazardRecognizer*
  CreateTargetHazardRecognizer(const TargetMachine *TM,
                               const ScheduleDAG *DAG) const;

  /// CreateTargetPostRAHazardRecognizer - Allocate and return a hazard
  /// recognizer to use for this target when scheduling the machine instructions
  /// after register allocation.
  virtual ScheduleHazardRecognizer*
  CreateTargetPostRAHazardRecognizer(const InstrItineraryData*,
                                     const ScheduleDAG *DAG) const;

  /// AnalyzeCompare - For a comparison instruction, return the source register
  /// in SrcReg and the value it compares against in CmpValue. Return true if
  /// the comparison instruction can be analyzed.
  virtual bool
  AnalyzeCompare(const MachineInstr *MI,
                 unsigned &SrcReg,
                 int &Mask,
                 int &Value) const;

  /// OptimizeCompareInstr - See if the comparison instruction can be converted
  /// into something more efficient. E.g., on ARM most instructions can set the
  /// flags register, obviating the need for a separate CMP.
  virtual bool
  OptimizeCompareInstr(MachineInstr *CmpInstr,
                       unsigned SrcReg,
                       int Mask,
                       int Value,
                       const MachineRegisterInfo *MRI) const;

  /// FoldImmediate - 'Reg' is known to be defined by a move immediate
  /// instruction, try to fold the immediate into the use instruction.
  virtual bool
  FoldImmediate(MachineInstr *UseMI,
                MachineInstr *DefMI,
                unsigned Reg,
                MachineRegisterInfo *MRI) const;

  /// getNumMicroOps - Return the number of u-operations the given machine
  /// instruction will be decoded to on the target cpu.
  virtual unsigned
  getNumMicroOps(const InstrItineraryData *ItinData,
                 const MachineInstr *MI) const;

  /// getOperandLatency - Compute and return the use operand latency of a given
  /// pair of def and use.
  /// In most cases, the static scheduling itinerary was enough to determine the
  /// operand latency. But it may not be possible for instructions with variable
  /// number of defs / uses.
  virtual int
  getOperandLatency(const InstrItineraryData *ItinData,
                    const MachineInstr *DefMI,
                    unsigned DefIdx,
                    const MachineInstr *UseMI,
                    unsigned UseIdx) const;

  virtual int
  getOperandLatency(const InstrItineraryData *ItinData,
                    SDNode *DefNode,
                    unsigned DefIdx,
                    SDNode *UseNode,
                    unsigned UseIdx) const;

  /// getInstrLatency - Compute the instruction latency of a given instruction.
  /// If the instruction has higher cost when predicated, it's returned via
  /// PredCost.
  virtual unsigned
  getInstrLatency(const InstrItineraryData *ItinData,
                  const MachineInstr *MI,
                  unsigned *PredCost = 0) const;

  virtual int
  getInstrLatency(const InstrItineraryData *ItinData,
                  SDNode *Node) const;

  /// hasHighOperandLatency - Compute operand latency between a def of 'Reg'
  /// and an use in the current loop, return true if the target considered
  /// it 'high'. This is used by optimization passes such as machine LICM to
  /// determine whether it makes sense to hoist an instruction out even in
  /// high register pressure situation.
  virtual bool
  hasHighOperandLatency(const InstrItineraryData *ItinData,
                        const MachineRegisterInfo *MRI,
                        const MachineInstr *DefMI,
                        unsigned DefIdx,
                        const MachineInstr *UseMI,
                        unsigned UseIdx) const;

  /// hasLowDefLatency - Compute operand latency of a def of 'Reg', return true
  /// if the target considered it 'low'.
  virtual bool
  hasLowDefLatency(const InstrItineraryData *ItinData,
                   const MachineInstr *DefMI,
                   unsigned DefIdx) const;

  /// Return true if the instruction is a register to register move and leave the
  /// source and dest operands in the passed parameters.
  bool
  isMoveInstr(const MachineInstr &MI,
                              unsigned int &SrcReg,
                              unsigned int &DstReg,
                              unsigned int &SrcSubIdx,
                              unsigned int &DstSubIdx) const;

  unsigned int
  getBranchInstr(const MachineOperand &op) const;

  bool
  getNextBranchInstr(MachineBasicBlock::iterator &iter,
                     MachineBasicBlock &MBB) const;

  bool
  copyRegToReg(MachineBasicBlock &MBB,
               MachineBasicBlock::iterator I,
               unsigned DestReg, unsigned SrcReg,
               const TargetRegisterClass *DestRC,
               const TargetRegisterClass *SrcRC,
               DebugLoc DL) const;

  bool
  shouldScheduleWithNormalPriority(SDNode* instruction) const;

  unsigned
  GetInstSizeInBytes(const MachineInstr *MI) const;

  RegScavenger *
  getRS() const {
    return RS;
  }

  bool
  expandPostRAPseudo(MachineBasicBlock::iterator MBBI) const;

private:
  RegScavenger *RS;

  /// Get a free GPR32 or insert spill and reload around specified instruction
  /// and return fried register
  unsigned
  getTempGPR32PostRA(MachineBasicBlock::iterator MBBI) const;
};

} // End llvm namespace

#endif // _HSAIL_INSTR_INFO_H_
