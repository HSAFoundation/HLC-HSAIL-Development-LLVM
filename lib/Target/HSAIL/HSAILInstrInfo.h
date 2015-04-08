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
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"

#define GET_INSTRINFO_HEADER
#include "HSAILGenInstrInfo.inc"

namespace llvm {
  class HSAILRegisterInfo;
  class HSAILSubtarget;
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

  int16_t getNamedOperandIdx(uint16_t Opcode, uint16_t NamedIndex);

  // FIXME: This is a thin wrapper around the similarly named and generated
  // getLdStVectorOpcode, which we should use directly.
  int getVectorLdStOpcode(uint16_t Opcode, unsigned vsize);
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
  const HSAILRegisterInfo RI;

public:
  explicit HSAILInstrInfo(HSAILSubtarget &st);

  ~HSAILInstrInfo();

  const HSAILRegisterInfo &getRegisterInfo() const {
    return RI;
  }

  bool isCoalescableExtInstr(const MachineInstr &MI,
                             unsigned &SrcReg, unsigned &DstReg,
                             unsigned &SubIdx) const override;

  unsigned isLoadFromStackSlot(const MachineInstr *MI,
                               int &FrameIndex) const override;

  unsigned isLoadFromStackSlotPostFE(const MachineInstr *MI,
                                     int &FrameIndex) const override;

  unsigned isStoreToStackSlot(const MachineInstr *MI,
                              int &FrameIndex) const override;

  unsigned isStoreToStackSlotPostFE(const MachineInstr *MI,
                                    int &FrameIndex) const override;

  bool AnalyzeBranch(MachineBasicBlock &MBB,
                     MachineBasicBlock *&TBB,
                     MachineBasicBlock *&FBB,
                     SmallVectorImpl<MachineOperand> &Cond,
                     bool AllowModify = false) const override;

  unsigned RemoveBranch(MachineBasicBlock &MBB) const override;

  unsigned InsertBranch(MachineBasicBlock &MBB,
                        MachineBasicBlock *TBB,
                        MachineBasicBlock *FBB,
                        const SmallVectorImpl<MachineOperand> &Cond,
                        DebugLoc DL) const override;

  void copyPhysReg(MachineBasicBlock &MBB,
                   MachineBasicBlock::iterator MI,
                   DebugLoc DL,
                   unsigned DestReg,
                   unsigned SrcReg,
                   bool KillSrc) const override;

  void storeRegToStackSlot(MachineBasicBlock &MBB,
                           MachineBasicBlock::iterator MI,
                           unsigned SrcReg,
                           bool isKill,
                           int FrameIndex,
                           const TargetRegisterClass *RC,
                           const TargetRegisterInfo *TRI) const override;

  void loadRegFromStackSlot(MachineBasicBlock &MBB,
                            MachineBasicBlock::iterator MI,
                            unsigned DestReg,
                            int FrameIndex,
                            const TargetRegisterClass *RC,
                            const TargetRegisterInfo *TRI) const override;

public:
  bool areLoadsFromSameBasePtr(SDNode *Node1,
                               SDNode *Node2,
                               int64_t &Offset1,
                               int64_t &Offset2) const override;

  bool shouldScheduleLoadsNear(SDNode *Node1,
                               SDNode *Node2,
                               int64_t Offset1,
                               int64_t Offset2,
                               unsigned NumLoads) const override;

  bool ReverseBranchCondition(
    SmallVectorImpl<MachineOperand> &Cond) const override;

  bool isSafeToMoveRegClassDefs(const TargetRegisterClass *RC) const override;

  RegScavenger *
  getRS() const {
    return RS;
  }

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

private:
  RegScavenger *RS;

  /// Get a free GPR32 or insert spill and reload around specified instruction
  /// and return fried register
  unsigned
  getTempGPR32PostRA(MachineBasicBlock::iterator MBBI) const;
};

namespace HSAIL {
  int getAtomicRetOp(uint16_t Opcode);
  int getAtomicNoRetOp(uint16_t Opcode);
}

} // End llvm namespace

#endif // _HSAIL_INSTR_INFO_H_
