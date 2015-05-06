//===-- HSAILInstPrinter.cpp - HSAIL MC Inst -> ASM -----------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
/// \file
//===----------------------------------------------------------------------===//

#include "HSAILInstPrinter.h"
#include "HSAIL.h"
#include "HSAILBrigDefs.h"
#include "HSAILInstrInfo.h"

#include "MCTargetDesc/HSAILMCTargetDesc.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstrDesc.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

HSAILInstPrinter::HSAILInstPrinter(const MCAsmInfo &MAI, const MCInstrInfo &MII,
                                   const MCRegisterInfo &MRI)
  : MCInstPrinter(MAI, MII, MRI),
    InArgScope(false) {}

void HSAILInstPrinter::printInst(const MCInst *MI, raw_ostream &OS,
                                 StringRef Annot) {

  if (MI->getOpcode() == HSAIL::ARG_SCOPE_START) {
    InArgScope = true;
    printInstruction(MI, OS);
    printAnnotation(OS, Annot);
    return;
  }

  if (MI->getOpcode() == HSAIL::ARG_SCOPE_END) {
    InArgScope = false;
    printInstruction(MI, OS);
    printAnnotation(OS, Annot);
    return;
  }

  // Indent any instructions in a call scope.
  if (InArgScope)
    OS << '\t';

  printInstruction(MI, OS);

  // Special case call because there appears to be no way to handle variable_ops
  // in the generated printer.
  if (MI->getOpcode() == HSAIL::CALL) {
    // First operand is called function, and should have been automatically
    // printed. We just need to specially handle the variable_ops.
    unsigned I = 1;

    OS << '(';

    const MCOperand *Op = &MI->getOperand(1);
    while (!Op->isImm()) {
      printOperand(MI, I++, OS);
      Op = &MI->getOperand(I);
    }

    // Return value and argument symbols are delimited with a 0 value.
    assert((Op->isImm() && Op->getImm() == 0) &&
           "Unexpected target call instruction operand list!");

    // Skip the zero.
    ++I;

    OS << ") (";

    unsigned N = MI->getNumOperands();
    while (I < N) {
      printOperand(MI, I++, OS);

      if (I < N)
        OS << ", ";
    }

    OS << ");";
  }

  printAnnotation(OS, Annot);
}

void HSAILInstPrinter::printUImmediate(uint64_t Imm, raw_ostream &O) {
  O << format("%" PRIu64, Imm);
}

void HSAILInstPrinter::printSImmediate(int64_t Imm, raw_ostream &O) {
  O << format("%" PRId64, Imm);
}

void HSAILInstPrinter::printU32(const MCInst *MI, unsigned OpNo,
                                raw_ostream &O) {
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isImm()) {
    O << format("%" PRIu32, Op.getImm());
    return;
  }

  printOperand(MI, OpNo, O);
}

void HSAILInstPrinter::printU64(const MCInst *MI, unsigned OpNo,
                                raw_ostream &O) {
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isImm()) {
    O << format("%" PRIu64, Op.getImm());
    return;
  }

  printOperand(MI, OpNo, O);
}

void HSAILInstPrinter::printS32(const MCInst *MI, unsigned OpNo,
                                raw_ostream &O) {
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isImm()) {
    O << format("%" PRId32, Op.getImm());
    return;
  }

  printOperand(MI, OpNo, O);
}

void HSAILInstPrinter::printS64(const MCInst *MI, unsigned OpNo,
                                raw_ostream &O) {
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isImm()) {
    O << format("%" PRId64, Op.getImm());
    return;
  }

  printOperand(MI, OpNo, O);
}

void HSAILInstPrinter::printF16(const MCInst *MI, unsigned OpNo,
                                raw_ostream &O) {
  llvm_unreachable("Implement me");
}

void HSAILInstPrinter::printF32(const MCInst *MI, unsigned OpNo,
                                raw_ostream &O) {
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isFPImm()) {
    O << format("0F%08" PRIx32, FloatToBits(static_cast<float>(Op.getFPImm())));
    return;
  }

  assert(!Op.isImm());

  printOperand(MI, OpNo, O);
}

void HSAILInstPrinter::printF64(const MCInst *MI, unsigned OpNo,
                                raw_ostream &O) {
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isFPImm()) {
    O << format("0D%016" PRIx64, DoubleToBits(Op.getFPImm()));
    return;
  }

  assert(!Op.isImm());

  printOperand(MI, OpNo, O);
}

void HSAILInstPrinter::printB1(const MCInst *MI, unsigned OpNo,
                               raw_ostream &O) {
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isImm()) {
    O << (Op.getImm() ? '1' : '0');
    return;
  }

  printOperand(MI, OpNo, O);
}

void HSAILInstPrinter::printB32(const MCInst *MI, unsigned OpNo,
                                raw_ostream &O) {
  printU32(MI, OpNo, O);
}

void HSAILInstPrinter::printB64(const MCInst *MI, unsigned OpNo,
                                raw_ostream &O) {
  printU64(MI, OpNo, O);
}

void HSAILInstPrinter::printU8X4(const MCInst *MI, unsigned OpNo,
                                 raw_ostream &O) {
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isImm()) {
    union Bytes {
      uint32_t I;
      uint8_t Byte[4];
    } U;

    U.I = Op.getImm();
    O << format("u8x4(%" PRIu8 ",%" PRIu8 ",%" PRIu8 ",%" PRIu8 ")", U.Byte[3],
                U.Byte[2], U.Byte[1], U.Byte[0]);
    return;
  }

  printOperand(MI, OpNo, O);
}

void HSAILInstPrinter::printU8X8(const MCInst *MI, unsigned OpNo,
                                 raw_ostream &O) {
  llvm_unreachable("Implement me");
}

void HSAILInstPrinter::printU16X2(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &O) {
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isImm()) {
    union Bytes {
      uint32_t I;
      uint16_t U16[2];
    } U;

    U.I = Op.getImm();
    O << format("u16x2(%" PRIu16 ",%" PRIu16 ")", U.U16[1], U.U16[0]);
    return;
  }

  printOperand(MI, OpNo, O);
}

void HSAILInstPrinter::printU16X4(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &O) {
  llvm_unreachable("Implement me");
}

void HSAILInstPrinter::printU32X2(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &O) {
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isImm()) {
    union Bytes {
      uint64_t I;
      uint32_t U32[2];
    } U;

    U.I = Op.getImm();
    O << format("u32x2(%" PRIu32 ",%" PRIu32 ")", U.U32[1], U.U32[0]);
    return;
  }

  printOperand(MI, OpNo, O);
}

void HSAILInstPrinter::printS8X4(const MCInst *MI, unsigned OpNo,
                                 raw_ostream &O) {
  llvm_unreachable("Implement me");
}

void HSAILInstPrinter::printS8X8(const MCInst *MI, unsigned OpNo,
                                 raw_ostream &O) {
  llvm_unreachable("Implement me");
}

void HSAILInstPrinter::printS16X2(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &O) {
  llvm_unreachable("Implement me");
}

void HSAILInstPrinter::printS16X4(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &O) {
  llvm_unreachable("Implement me");
}

void HSAILInstPrinter::printS32X2(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &O) {
  llvm_unreachable("Implement me");
}

void HSAILInstPrinter::printF16X2(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &O) {
  llvm_unreachable("Implement me");
}

void HSAILInstPrinter::printF16X4(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &O) {
  llvm_unreachable("Implement me");
}

void HSAILInstPrinter::printAddrMode3Op(const MCInst *MI, unsigned OpNo,
                                        raw_ostream &O) {
  const MCOperand &BaseOp = MI->getOperand(OpNo);
  const MCOperand &RegOp = MI->getOperand(OpNo + 1);
  const MCOperand &OffsetOp = MI->getOperand(OpNo + 2);

  assert(RegOp.isReg() && OffsetOp.isImm());

  unsigned AddrReg = RegOp.getReg();
  int64_t Offset = OffsetOp.getImm();

  if (BaseOp.isReg()) {
    // FIXME: Why is this allowed to be a register?
    assert(BaseOp.getReg() == HSAIL::NoRegister);
  } else if (BaseOp.isExpr()) {
    O << '[' << *BaseOp.getExpr() << ']';
  } else if (BaseOp.isImm())
    O << BaseOp.getImm();
  else
    llvm_unreachable("Unexpected type for base address operand");

  // Have both register and immediate offset.
  if (AddrReg != HSAIL::NoRegister && Offset != 0) {
    O << '[' << getRegisterName(AddrReg);

    // If the offset is negative, it will be printed with the appropriate -
    // already.
    if (Offset > 0)
      O << '+';

    O << formatDec(Offset) << ']';
    return;
  }

  // Only register offset.
  if (AddrReg != HSAIL::NoRegister) {
    O << '[' << getRegisterName(AddrReg) << ']';
    return;
  }

  // Only have immediate offset.
  if (Offset != 0)
    O << '[' << formatDec(Offset) << ']';
}

void HSAILInstPrinter::printVec2Op(const MCInst *MI, unsigned OpNo,
                                   raw_ostream &O) {
  O << '(';
  printOperand(MI, OpNo + 0, O);
  O << ", ";
  printOperand(MI, OpNo + 1, O);
  O << ')';
}

void HSAILInstPrinter::printVec3Op(const MCInst *MI, unsigned OpNo,
                                   raw_ostream &O) {
  O << '(';
  printOperand(MI, OpNo + 0, O);
  O << ", ";
  printOperand(MI, OpNo + 1, O);
  O << ", ";
  printOperand(MI, OpNo + 2, O);
  O << ')';
}

void HSAILInstPrinter::printVec4Op(const MCInst *MI, unsigned OpNo,
                                   raw_ostream &O) {
  O << '(';
  printOperand(MI, OpNo + 0, O);
  O << ", ";
  printOperand(MI, OpNo + 1, O);
  O << ", ";
  printOperand(MI, OpNo + 2, O);
  O << ", ";
  printOperand(MI, OpNo + 3, O);
  O << ')';
}

void HSAILInstPrinter::printV2U32(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &O) {
  O << '(';
  printU32(MI, OpNo + 0, O);
  O << ", ";
  printU32(MI, OpNo + 1, O);
  O << ')';
}

void HSAILInstPrinter::printV2F64(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &O) {
  O << '(';
  printF64(MI, OpNo + 0, O);
  O << ", ";
  printF64(MI, OpNo + 1, O);
  O << ')';
}

void HSAILInstPrinter::printV2U64(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &O) {
  O << '(';
  printU64(MI, OpNo + 0, O);
  O << ", ";
  printU64(MI, OpNo + 1, O);
  O << ')';
}

void HSAILInstPrinter::printV2F32(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &O) {
  O << '(';
  printF32(MI, OpNo + 0, O);
  O << ", ";
  printF32(MI, OpNo + 1, O);
  O << ')';
}

void HSAILInstPrinter::printV3U32(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &O) {
  O << '(';
  printU32(MI, OpNo + 0, O);
  O << ", ";
  printU32(MI, OpNo + 1, O);
  O << ", ";
  printU32(MI, OpNo + 2, O);
  O << ')';
}

void HSAILInstPrinter::printV3F32(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &O) {
  O << '(';
  printF32(MI, OpNo + 0, O);
  O << ", ";
  printF32(MI, OpNo + 1, O);
  O << ", ";
  printF32(MI, OpNo + 2, O);
  O << ')';
}

void HSAILInstPrinter::printV3U64(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &O) {
  O << '(';
  printU64(MI, OpNo + 0, O);
  O << ", ";
  printU64(MI, OpNo + 1, O);
  O << ", ";
  printU64(MI, OpNo + 2, O);
  O << ')';
}

void HSAILInstPrinter::printV3F64(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &O) {
  O << '(';
  printF64(MI, OpNo + 0, O);
  O << ", ";
  printF64(MI, OpNo + 1, O);
  O << ", ";
  printF64(MI, OpNo + 2, O);
  O << ')';
}

void HSAILInstPrinter::printV4U32(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &O) {
  O << '(';
  printU32(MI, OpNo + 0, O);
  O << ", ";
  printU32(MI, OpNo + 1, O);
  O << ", ";
  printU32(MI, OpNo + 2, O);
  O << ", ";
  printU32(MI, OpNo + 3, O);
  O << ')';
}

void HSAILInstPrinter::printV4F32(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &O) {
  O << '(';
  printF32(MI, OpNo + 0, O);
  O << ", ";
  printF32(MI, OpNo + 1, O);
  O << ", ";
  printF32(MI, OpNo + 2, O);
  O << ", ";
  printF32(MI, OpNo + 3, O);
  O << ')';
}

void HSAILInstPrinter::printV4U64(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &O) {
  O << '(';
  printU64(MI, OpNo + 0, O);
  O << ", ";
  printU64(MI, OpNo + 1, O);
  O << ", ";
  printU64(MI, OpNo + 2, O);
  O << ", ";
  printU64(MI, OpNo + 3, O);
  O << ')';
}

void HSAILInstPrinter::printV4F64(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &O) {
  O << '(';
  printF64(MI, OpNo + 0, O);
  O << ", ";
  printF64(MI, OpNo + 1, O);
  O << ", ";
  printF64(MI, OpNo + 2, O);
  O << ", ";
  printF64(MI, OpNo + 3, O);
  O << ')';
}

void HSAILInstPrinter::printFTZ(const MCInst *MI, unsigned OpNo,
                                raw_ostream &O) {
  if (MI->getOperand(OpNo).getImm())
    O << "_ftz";
}

void HSAILInstPrinter::printNoNull(const MCInst *MI, unsigned OpNo,
                                   raw_ostream &O) {
  if (MI->getOperand(OpNo).getImm())
    O << "_nonull";
}

void HSAILInstPrinter::printV4(const MCInst *MI, unsigned OpNo,
                               raw_ostream &O) {
  if (MI->getOperand(OpNo).getImm())
    O << "_v4";
}

void HSAILInstPrinter::printBrigAlignment(const MCInst *MI, unsigned OpNo,
                                          raw_ostream &O) {
  unsigned Align = MI->getOperand(OpNo).getImm();
  if (Align != 1)
    O << "_align(" << formatDec(Align) << ')';
}

static bool isNaturalAlignment(BrigType BT, unsigned Align) {
  switch (Align) {
  case 4: {
    switch (BT) {
    case BRIG_TYPE_U32:
    case BRIG_TYPE_F32:
    case BRIG_TYPE_B32:
    case BRIG_TYPE_S32:
    case BRIG_TYPE_U8X4:
    case BRIG_TYPE_S8X4:
    case BRIG_TYPE_F16X2:
    case BRIG_TYPE_S16X2:
    case BRIG_TYPE_U16X2:
      return true;
    default:
      return false;
    }
  }
  case 8: {
    switch (BT) {
    case BRIG_TYPE_U64:
    case BRIG_TYPE_B64:
    case BRIG_TYPE_F64:
    case BRIG_TYPE_S64:
    case BRIG_TYPE_F16X4:
    case BRIG_TYPE_F32X2:
    case BRIG_TYPE_ROIMG:
    case BRIG_TYPE_RWIMG:
    case BRIG_TYPE_S16X4:
    case BRIG_TYPE_S32X2:
    case BRIG_TYPE_S8X8:
    case BRIG_TYPE_SAMP:
    case BRIG_TYPE_SIG32:
    case BRIG_TYPE_SIG64:
    case BRIG_TYPE_U16X4:
    case BRIG_TYPE_U32X2:
    case BRIG_TYPE_U8X8:
    case BRIG_TYPE_WOIMG:
      return true;
    default:
      return false;
    }
  }
  case 1: {
    switch (BT) {
    case BRIG_TYPE_B1:
    case BRIG_TYPE_B8:
    case BRIG_TYPE_S8:
    case BRIG_TYPE_U8:
      return true;
    default:
      return false;
    }
  }
  case 2: {
    switch (BT) {
    case BRIG_TYPE_U16:
    case BRIG_TYPE_B16:
    case BRIG_TYPE_S16:
    case BRIG_TYPE_F16:
      return true;
    default:
      return false;
    }
  }
  case 16: {
    switch (BT) {
    case BRIG_TYPE_B128:
    case BRIG_TYPE_F16X8:
    case BRIG_TYPE_F32X4:
    case BRIG_TYPE_F64X2:
    case BRIG_TYPE_S16X8:
    case BRIG_TYPE_S32X4:
    case BRIG_TYPE_S64X2:
    case BRIG_TYPE_S8X16:
    case BRIG_TYPE_U16X8:
    case BRIG_TYPE_U32X4:
    case BRIG_TYPE_U64X2:
    case BRIG_TYPE_U8X16:
      return true;
    default:
      return false;
    }
  }
  default:
    return false;
  }
}

void HSAILInstPrinter::printArgDeclAlignment(const MCInst *MI, unsigned OpNo,
                                             raw_ostream &O) {
  unsigned Align = MI->getOperand(OpNo).getImm();

  int TypeLengthIdx =
      HSAIL::getNamedOperandIdx(MI->getOpcode(), HSAIL::OpName::TypeLength);
  BrigType BT = static_cast<BrigType>(MI->getOperand(TypeLengthIdx).getImm());

  // Don't print align declaration if it uses the alignment implied in this
  // context. This isn't necessary, but it matches what libHSAIL's disassembler
  // produces.
  if (!isNaturalAlignment(BT, Align))
    O << "align(" << formatDec(Align) << ") ";
}

void HSAILInstPrinter::printArraySize(const MCInst *MI, unsigned OpNo,
                                      raw_ostream &O) {
  int64_t Size = MI->getOperand(OpNo).getImm();
  if (Size != 0)
    O << '[' << Size << ']';
}

void HSAILInstPrinter::printEquiv(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &O) {
  unsigned Equiv = MI->getOperand(OpNo).getImm();
  if (Equiv != 0)
    O << "_equiv(" << formatDec(Equiv) << ')';
}

void HSAILInstPrinter::printBrigAllocation(const MCInst *MI, unsigned OpNo,
                                           raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_ALLOCATION_NONE:
    O << "NONE";
    break;
  case BRIG_ALLOCATION_PROGRAM:
    O << "PROGRAM";
    break;
  case BRIG_ALLOCATION_AGENT:
    O << "AGENT";
    break;
  case BRIG_ALLOCATION_AUTOMATIC:
    O << "AUTOMATIC";
    break;
  }
}

void HSAILInstPrinter::printBrigAluModifierMask(const MCInst *MI, unsigned OpNo,
                                                raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_ALU_FTZ:
    O << "FTZ";
    break;
  }
}

void HSAILInstPrinter::printBrigAtomicOperation(const MCInst *MI, unsigned OpNo,
                                                raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_ATOMIC_ADD:
    O << "_add";
    break;
  case BRIG_ATOMIC_AND:
    O << "_and";
    break;
  case BRIG_ATOMIC_CAS:
    O << "_cas";
    break;
  case BRIG_ATOMIC_EXCH:
    O << "_exch";
    break;
  case BRIG_ATOMIC_LD:
    O << "_ld";
    break;
  case BRIG_ATOMIC_MAX:
    O << "_max";
    break;
  case BRIG_ATOMIC_MIN:
    O << "_min";
    break;
  case BRIG_ATOMIC_OR:
    O << "_or";
    break;
  case BRIG_ATOMIC_ST:
    O << "_st";
    break;
  case BRIG_ATOMIC_SUB:
    O << "_sub";
    break;
  case BRIG_ATOMIC_WRAPDEC:
    O << "_wrapdec";
    break;
  case BRIG_ATOMIC_WRAPINC:
    O << "_wrapinc";
    break;
  case BRIG_ATOMIC_XOR:
    O << "_xor";
    break;
  case BRIG_ATOMIC_WAIT_EQ:
    O << "_wait_eq";
    break;
  case BRIG_ATOMIC_WAIT_NE:
    O << "_wait_ne";
    break;
  case BRIG_ATOMIC_WAIT_LT:
    O << "_wait_lt";
    break;
  case BRIG_ATOMIC_WAIT_GTE:
    O << "_wait_gte";
    break;
  case BRIG_ATOMIC_WAITTIMEOUT_EQ:
    O << "_waittimeout_eq";
    break;
  case BRIG_ATOMIC_WAITTIMEOUT_NE:
    O << "_waittimeout_ne";
    break;
  case BRIG_ATOMIC_WAITTIMEOUT_LT:
    O << "_waittimeout_lt";
    break;
  case BRIG_ATOMIC_WAITTIMEOUT_GTE:
    O << "_waittimeout_gte";
    break;
  }
}

void HSAILInstPrinter::printBrigCompareOperation(const MCInst *MI,
                                                 unsigned OpNo,
                                                 raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_COMPARE_EQ:
    O << "_eq";
    break;
  case BRIG_COMPARE_NE:
    O << "_ne";
    break;
  case BRIG_COMPARE_LT:
    O << "_lt";
    break;
  case BRIG_COMPARE_LE:
    O << "_le";
    break;
  case BRIG_COMPARE_GT:
    O << "_gt";
    break;
  case BRIG_COMPARE_GE:
    O << "_ge";
    break;
  case BRIG_COMPARE_EQU:
    O << "_equ";
    break;
  case BRIG_COMPARE_NEU:
    O << "_neu";
    break;
  case BRIG_COMPARE_LTU:
    O << "_ltu";
    break;
  case BRIG_COMPARE_LEU:
    O << "_leu";
    break;
  case BRIG_COMPARE_GTU:
    O << "_gtu";
    break;
  case BRIG_COMPARE_GEU:
    O << "_geu";
    break;
  case BRIG_COMPARE_NUM:
    O << "_num";
    break;
  case BRIG_COMPARE_NAN:
    O << "_nan";
    break;
  case BRIG_COMPARE_SEQ:
    O << "_seq";
    break;
  case BRIG_COMPARE_SNE:
    O << "_sne";
    break;
  case BRIG_COMPARE_SLT:
    O << "_slt";
    break;
  case BRIG_COMPARE_SLE:
    O << "_sle";
    break;
  case BRIG_COMPARE_SGT:
    O << "_sgt";
    break;
  case BRIG_COMPARE_SGE:
    O << "_sge";
    break;
  case BRIG_COMPARE_SGEU:
    O << "_sgeu";
    break;
  case BRIG_COMPARE_SEQU:
    O << "_sequ";
    break;
  case BRIG_COMPARE_SNEU:
    O << "_sneu";
    break;
  case BRIG_COMPARE_SLTU:
    O << "_sltu";
    break;
  case BRIG_COMPARE_SLEU:
    O << "_sleu";
    break;
  case BRIG_COMPARE_SNUM:
    O << "_snum";
    break;
  case BRIG_COMPARE_SNAN:
    O << "_snan";
    break;
  case BRIG_COMPARE_SGTU:
    O << "_sgtu";
    break;
  }
}

void HSAILInstPrinter::printBrigControlDirective(const MCInst *MI,
                                                 unsigned OpNo,
                                                 raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_CONTROL_ENABLEBREAKEXCEPTIONS:
    O << "enablebreakexceptions";
    break;
  case BRIG_CONTROL_ENABLEDETECTEXCEPTIONS:
    O << "enabledetectexceptions";
    break;
  case BRIG_CONTROL_MAXDYNAMICGROUPSIZE:
    O << "maxdynamicgroupsize";
    break;
  case BRIG_CONTROL_MAXFLATGRIDSIZE:
    O << "maxflatgridsize";
    break;
  case BRIG_CONTROL_MAXFLATWORKGROUPSIZE:
    O << "maxflatworkgroupsize";
    break;
  case BRIG_CONTROL_REQUIREDDIM:
    O << "requireddim";
    break;
  case BRIG_CONTROL_REQUIREDGRIDSIZE:
    O << "requiredgridsize";
    break;
  case BRIG_CONTROL_REQUIREDWORKGROUPSIZE:
    O << "requiredworkgroupsize";
    break;
  case BRIG_CONTROL_REQUIRENOPARTIALWORKGROUPS:
    O << "requirenopartialworkgroups";
    break;
  }
}

void HSAILInstPrinter::printBrigExecutableModifierMask(const MCInst *MI,
                                                       unsigned OpNo,
                                                       raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_EXECUTABLE_DEFINITION:
    O << "DEFINITION";
    break;
  }
}

void HSAILInstPrinter::printBrigImageChannelOrder(const MCInst *MI,
                                                  unsigned OpNo,
                                                  raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_CHANNEL_ORDER_A:
    O << "a";
    break;
  case BRIG_CHANNEL_ORDER_R:
    O << "r";
    break;
  case BRIG_CHANNEL_ORDER_RX:
    O << "rx";
    break;
  case BRIG_CHANNEL_ORDER_RG:
    O << "rg";
    break;
  case BRIG_CHANNEL_ORDER_RGX:
    O << "rgx";
    break;
  case BRIG_CHANNEL_ORDER_RA:
    O << "ra";
    break;
  case BRIG_CHANNEL_ORDER_RGB:
    O << "rgb";
    break;
  case BRIG_CHANNEL_ORDER_RGBX:
    O << "rgbx";
    break;
  case BRIG_CHANNEL_ORDER_RGBA:
    O << "rgba";
    break;
  case BRIG_CHANNEL_ORDER_BGRA:
    O << "bgra";
    break;
  case BRIG_CHANNEL_ORDER_ARGB:
    O << "argb";
    break;
  case BRIG_CHANNEL_ORDER_ABGR:
    O << "abgr";
    break;
  case BRIG_CHANNEL_ORDER_SRGB:
    O << "srgb";
    break;
  case BRIG_CHANNEL_ORDER_SRGBX:
    O << "srgbx";
    break;
  case BRIG_CHANNEL_ORDER_SRGBA:
    O << "srgba";
    break;
  case BRIG_CHANNEL_ORDER_SBGRA:
    O << "sbgra";
    break;
  case BRIG_CHANNEL_ORDER_INTENSITY:
    O << "intensity";
    break;
  case BRIG_CHANNEL_ORDER_LUMINANCE:
    O << "luminance";
    break;
  case BRIG_CHANNEL_ORDER_DEPTH:
    O << "depth";
    break;
  case BRIG_CHANNEL_ORDER_DEPTH_STENCIL:
    O << "depth_stencil";
    break;
  }
}

void HSAILInstPrinter::printBrigImageChannelType(const MCInst *MI,
                                                 unsigned OpNo,
                                                 raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_CHANNEL_TYPE_SNORM_INT8:
    O << "snorm_int8";
    break;
  case BRIG_CHANNEL_TYPE_SNORM_INT16:
    O << "snorm_int16";
    break;
  case BRIG_CHANNEL_TYPE_UNORM_INT8:
    O << "unorm_int8";
    break;
  case BRIG_CHANNEL_TYPE_UNORM_INT16:
    O << "unorm_int16";
    break;
  case BRIG_CHANNEL_TYPE_UNORM_INT24:
    O << "unorm_int24";
    break;
  case BRIG_CHANNEL_TYPE_UNORM_SHORT_555:
    O << "unorm_short_555";
    break;
  case BRIG_CHANNEL_TYPE_UNORM_SHORT_565:
    O << "unorm_short_565";
    break;
  case BRIG_CHANNEL_TYPE_UNORM_INT_101010:
    O << "unorm_int_101010";
    break;
  case BRIG_CHANNEL_TYPE_SIGNED_INT8:
    O << "signed_int8";
    break;
  case BRIG_CHANNEL_TYPE_SIGNED_INT16:
    O << "signed_int16";
    break;
  case BRIG_CHANNEL_TYPE_SIGNED_INT32:
    O << "signed_int32";
    break;
  case BRIG_CHANNEL_TYPE_UNSIGNED_INT8:
    O << "unsigned_int8";
    break;
  case BRIG_CHANNEL_TYPE_UNSIGNED_INT16:
    O << "unsigned_int16";
    break;
  case BRIG_CHANNEL_TYPE_UNSIGNED_INT32:
    O << "unsigned_int32";
    break;
  case BRIG_CHANNEL_TYPE_HALF_FLOAT:
    O << "half_float";
    break;
  case BRIG_CHANNEL_TYPE_FLOAT:
    O << "float";
    break;
  }
}

void HSAILInstPrinter::printBrigImageGeometry(const MCInst *MI, unsigned OpNo,
                                              raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_GEOMETRY_1D:
    O << "_1d";
    break;
  case BRIG_GEOMETRY_2D:
    O << "_2d";
    break;
  case BRIG_GEOMETRY_3D:
    O << "_3d";
    break;
  case BRIG_GEOMETRY_1DA:
    O << "_1da";
    break;
  case BRIG_GEOMETRY_2DA:
    O << "_2da";
    break;
  case BRIG_GEOMETRY_1DB:
    O << "_1db";
    break;
  case BRIG_GEOMETRY_2DDEPTH:
    O << "_2ddepth";
    break;
  case BRIG_GEOMETRY_2DADEPTH:
    O << "_2dadepth";
    break;
  case BRIG_GEOMETRY_UNKNOWN:
    O << "_unknown";
    break;
  }
}

void HSAILInstPrinter::printBrigImageQuery(const MCInst *MI, unsigned OpNo,
                                           raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_IMAGE_QUERY_WIDTH:
    O << "width";
    break;
  case BRIG_IMAGE_QUERY_HEIGHT:
    O << "height";
    break;
  case BRIG_IMAGE_QUERY_DEPTH:
    O << "depth";
    break;
  case BRIG_IMAGE_QUERY_ARRAY:
    O << "array";
    break;
  case BRIG_IMAGE_QUERY_CHANNELORDER:
    O << "channelorder";
    break;
  case BRIG_IMAGE_QUERY_CHANNELTYPE:
    O << "channeltype";
    break;
  }
}

void HSAILInstPrinter::printBrigLinkage(const MCInst *MI, unsigned OpNo,
                                        raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_LINKAGE_NONE:
    O << "NONE";
    break;
  case BRIG_LINKAGE_PROGRAM:
    O << "PROGRAM";
    break;
  case BRIG_LINKAGE_MODULE:
    O << "MODULE";
    break;
  case BRIG_LINKAGE_FUNCTION:
    O << "FUNCTION";
    break;
  case BRIG_LINKAGE_ARG:
    O << "ARG";
    break;
  }
}

void HSAILInstPrinter::printBrigMachineModel(const MCInst *MI, unsigned OpNo,
                                             raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_MACHINE_SMALL:
    O << "$small";
    break;
  case BRIG_MACHINE_LARGE:
    O << "$large";
    break;
  }
}

void HSAILInstPrinter::printBrigMemoryModifierMask(const MCInst *MI,
                                                   unsigned OpNo,
                                                   raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_MEMORY_CONST:
    O << "CONST";
    break;
  }
}

void HSAILInstPrinter::printBrigMemoryOrder(const MCInst *MI, unsigned OpNo,
                                            raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_MEMORY_ORDER_NONE:
    O << "_";
    break;
  case BRIG_MEMORY_ORDER_RELAXED:
    O << "_rlx";
    break;
  case BRIG_MEMORY_ORDER_SC_ACQUIRE:
    O << "_scacq";
    break;
  case BRIG_MEMORY_ORDER_SC_RELEASE:
    O << "_screl";
    break;
  case BRIG_MEMORY_ORDER_SC_ACQUIRE_RELEASE:
    O << "_scar";
    break;
  }
}

void HSAILInstPrinter::printBrigMemoryScope(const MCInst *MI, unsigned OpNo,
                                            raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_MEMORY_SCOPE_WAVEFRONT:
    O << "_wave";
    break;
  case BRIG_MEMORY_SCOPE_WORKGROUP:
    O << "_wg";
    break;
  case BRIG_MEMORY_SCOPE_AGENT:
    O << "_agent";
    break;
  case BRIG_MEMORY_SCOPE_SYSTEM:
    O << "_system";
    break;
  }
}

void HSAILInstPrinter::printBrigPack(const MCInst *MI, unsigned OpNo,
                                     raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_PACK_NONE:
    O << "_";
    break;
  case BRIG_PACK_PP:
    O << "_pp";
    break;
  case BRIG_PACK_PS:
    O << "_ps";
    break;
  case BRIG_PACK_SP:
    O << "_sp";
    break;
  case BRIG_PACK_SS:
    O << "_ss";
    break;
  case BRIG_PACK_S:
    O << "_s";
    break;
  case BRIG_PACK_P:
    O << "_p";
    break;
  case BRIG_PACK_PPSAT:
    O << "_pp_sat";
    break;
  case BRIG_PACK_PSSAT:
    O << "_ps_sat";
    break;
  case BRIG_PACK_SPSAT:
    O << "_sp_sat";
    break;
  case BRIG_PACK_SSSAT:
    O << "_ss_sat";
    break;
  case BRIG_PACK_SSAT:
    O << "_s_sat";
    break;
  case BRIG_PACK_PSAT:
    O << "_p_sat";
    break;
  }
}

void HSAILInstPrinter::printBrigProfile(const MCInst *MI, unsigned OpNo,
                                        raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_PROFILE_BASE:
    O << "$base";
    break;
  case BRIG_PROFILE_FULL:
    O << "$full";
    break;
  }
}

void HSAILInstPrinter::printBrigRound(const MCInst *MI, unsigned OpNo,
                                      raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_ROUND_NONE:
    break;
  case BRIG_ROUND_FLOAT_DEFAULT:
    break;
  case BRIG_ROUND_FLOAT_NEAR_EVEN:
    O << "_near";
    break;
  case BRIG_ROUND_FLOAT_ZERO:
    O << "_zero";
    break;
  case BRIG_ROUND_FLOAT_PLUS_INFINITY:
    O << "_up";
    break;
  case BRIG_ROUND_FLOAT_MINUS_INFINITY:
    O << "_down";
    break;
  case BRIG_ROUND_INTEGER_NEAR_EVEN:
    O << "_neari";
    break;
  case BRIG_ROUND_INTEGER_ZERO:
    // This is the default for integer ops, omit it.
    // O << "_zeroi";
    break;
  case BRIG_ROUND_INTEGER_PLUS_INFINITY:
    O << "_upi";
    break;
  case BRIG_ROUND_INTEGER_MINUS_INFINITY:
    O << "_downi";
    break;
  case BRIG_ROUND_INTEGER_NEAR_EVEN_SAT:
    O << "_neari_sat";
    break;
  case BRIG_ROUND_INTEGER_ZERO_SAT:
    O << "_zeroi_sat";
    break;
  case BRIG_ROUND_INTEGER_PLUS_INFINITY_SAT:
    O << "_upi_sat";
    break;
  case BRIG_ROUND_INTEGER_MINUS_INFINITY_SAT:
    O << "_downi_sat";
    break;
  case BRIG_ROUND_INTEGER_SIGNALING_NEAR_EVEN:
    O << "_sneari";
    break;
  case BRIG_ROUND_INTEGER_SIGNALING_ZERO:
    O << "_szeroi";
    break;
  case BRIG_ROUND_INTEGER_SIGNALING_PLUS_INFINITY:
    O << "_supi";
    break;
  case BRIG_ROUND_INTEGER_SIGNALING_MINUS_INFINITY:
    O << "_sdowni";
    break;
  case BRIG_ROUND_INTEGER_SIGNALING_NEAR_EVEN_SAT:
    O << "_sneari_sat";
    break;
  case BRIG_ROUND_INTEGER_SIGNALING_ZERO_SAT:
    O << "_szeroi_sat";
    break;
  case BRIG_ROUND_INTEGER_SIGNALING_PLUS_INFINITY_SAT:
    O << "_supi_sat";
    break;
  case BRIG_ROUND_INTEGER_SIGNALING_MINUS_INFINITY_SAT:
    O << "_sdowni_sat";
    break;
  }
}

void HSAILInstPrinter::printBrigSamplerAddressing(const MCInst *MI,
                                                  unsigned OpNo,
                                                  raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_ADDRESSING_UNDEFINED:
    O << "UNDEFINED";
    break;
  case BRIG_ADDRESSING_CLAMP_TO_EDGE:
    O << "CLAMP_TO_EDGE";
    break;
  case BRIG_ADDRESSING_CLAMP_TO_BORDER:
    O << "CLAMP_TO_BORDER";
    break;
  case BRIG_ADDRESSING_REPEAT:
    O << "REPEAT";
    break;
  case BRIG_ADDRESSING_MIRRORED_REPEAT:
    O << "MIRRORED_REPEAT";
    break;
  }
}

void HSAILInstPrinter::printBrigSamplerCoordNormalization(const MCInst *MI,
                                                          unsigned OpNo,
                                                          raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_COORD_UNNORMALIZED:
    O << "unnormalized";
    break;
  case BRIG_COORD_NORMALIZED:
    O << "normalized";
    break;
  }
}

void HSAILInstPrinter::printBrigSamplerFilter(const MCInst *MI, unsigned OpNo,
                                              raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_FILTER_NEAREST:
    O << "nearest";
    break;
  case BRIG_FILTER_LINEAR:
    O << "linear";
    break;
  }
}

void HSAILInstPrinter::printBrigSamplerQuery(const MCInst *MI, unsigned OpNo,
                                             raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_SAMPLER_QUERY_ADDRESSING:
    O << "addressing";
    break;
  case BRIG_SAMPLER_QUERY_COORD:
    O << "coord";
    break;
  case BRIG_SAMPLER_QUERY_FILTER:
    O << "filter";
    break;
  }
}

void HSAILInstPrinter::printBrigSegCvtModifierMask(const MCInst *MI,
                                                   unsigned OpNo,
                                                   raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_SEG_CVT_NONULL:
    O << "_nonull";
    break;
  }
}

void HSAILInstPrinter::printBrigSegment(const MCInst *MI, unsigned OpNo,
                                        raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case HSAILAS::FLAT_ADDRESS:
    // Assumed default.
    break;
  case HSAILAS::GLOBAL_ADDRESS:
    O << "_global";
    break;
  case HSAILAS::READONLY_ADDRESS:
    O << "_readonly";
    break;
  case HSAILAS::KERNARG_ADDRESS:
    O << "_kernarg";
    break;
  case HSAILAS::GROUP_ADDRESS:
    O << "_group";
    break;
  case HSAILAS::PRIVATE_ADDRESS:
    O << "_private";
    break;
  case HSAILAS::SPILL_ADDRESS:
    O << "_spill";
    break;
  case HSAILAS::ARG_ADDRESS:
    O << "_arg";
    break;
  case HSAILAS::REGION_ADDRESS: {
    // For now, the only non-flat implied segment appears to be region.
    const MCInstrDesc &Desc = MII.get(MI->getOpcode());
    if (Desc.TSFlags & HSAILInstrFlags::HasDefaultSegment)
      break;

    O << "_region";
    break;
  }
  default:
    llvm_unreachable("bad segment value");
  }

#if 0
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_SEGMENT_GLOBAL:
    O << "_global";
    break;
  case BRIG_SEGMENT_READONLY:
    O << "_readonly";
    break;
  case BRIG_SEGMENT_KERNARG:
    O << "_kernarg";
    break;
  case BRIG_SEGMENT_GROUP:
    O << "_group";
    break;
  case BRIG_SEGMENT_PRIVATE:
    O << "_private";
    break;
  case BRIG_SEGMENT_SPILL:
    O << "_spill";
    break;
  case BRIG_SEGMENT_ARG:
    O << "_arg";
    break;
  case BRIG_SEGMENT_AMD_GCN:
    O << "_region";
    break;
  default:
    llvm_unreachable("bad segment value");
  }
#endif
}

void HSAILInstPrinter::printBrigType(const MCInst *MI, unsigned OpNo,
                                     raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_TYPE_U8:
    O << "_u8";
    break;
  case BRIG_TYPE_U16:
    O << "_u16";
    break;
  case BRIG_TYPE_U32:
    O << "_u32";
    break;
  case BRIG_TYPE_U64:
    O << "_u64";
    break;
  case BRIG_TYPE_S8:
    O << "_s8";
    break;
  case BRIG_TYPE_S16:
    O << "_s16";
    break;
  case BRIG_TYPE_S32:
    O << "_s32";
    break;
  case BRIG_TYPE_S64:
    O << "_s64";
    break;
  case BRIG_TYPE_F16:
    O << "_f16";
    break;
  case BRIG_TYPE_F32:
    O << "_f32";
    break;
  case BRIG_TYPE_F64:
    O << "_f64";
    break;
  case BRIG_TYPE_B1:
    O << "_b1";
    break;
  case BRIG_TYPE_B8:
    O << "_b8";
    break;
  case BRIG_TYPE_B16:
    O << "_b16";
    break;
  case BRIG_TYPE_B32:
    O << "_b32";
    break;
  case BRIG_TYPE_B64:
    O << "_b64";
    break;
  case BRIG_TYPE_B128:
    O << "_b128";
    break;
  case BRIG_TYPE_SAMP:
    O << "_samp";
    break;
  case BRIG_TYPE_ROIMG:
    O << "_roimg";
    break;
  case BRIG_TYPE_WOIMG:
    O << "_woimg";
    break;
  case BRIG_TYPE_RWIMG:
    O << "_rwimg";
    break;
  case BRIG_TYPE_SIG32:
    O << "_sig32";
    break;
  case BRIG_TYPE_SIG64:
    O << "_sig64";
    break;
  case BRIG_TYPE_U8X4:
    O << "_u8x4";
    break;
  case BRIG_TYPE_U8X8:
    O << "_u8x8";
    break;
  case BRIG_TYPE_U8X16:
    O << "_u8x16";
    break;
  case BRIG_TYPE_U16X2:
    O << "_u16x2";
    break;
  case BRIG_TYPE_U16X4:
    O << "_u16x4";
    break;
  case BRIG_TYPE_U16X8:
    O << "_u16x8";
    break;
  case BRIG_TYPE_U32X2:
    O << "_u32x2";
    break;
  case BRIG_TYPE_U32X4:
    O << "_u32x4";
    break;
  case BRIG_TYPE_U64X2:
    O << "_u64x2";
    break;
  case BRIG_TYPE_S8X4:
    O << "_s8x4";
    break;
  case BRIG_TYPE_S8X8:
    O << "_s8x8";
    break;
  case BRIG_TYPE_S8X16:
    O << "_s8x16";
    break;
  case BRIG_TYPE_S16X2:
    O << "_s16x2";
    break;
  case BRIG_TYPE_S16X4:
    O << "_s16x4";
    break;
  case BRIG_TYPE_S16X8:
    O << "_s16x8";
    break;
  case BRIG_TYPE_S32X2:
    O << "_s32x2";
    break;
  case BRIG_TYPE_S32X4:
    O << "_s32x4";
    break;
  case BRIG_TYPE_S64X2:
    O << "_s64x2";
    break;
  case BRIG_TYPE_F16X2:
    O << "_f16x2";
    break;
  case BRIG_TYPE_F16X4:
    O << "_f16x4";
    break;
  case BRIG_TYPE_F16X8:
    O << "_f16x8";
    break;
  case BRIG_TYPE_F32X2:
    O << "_f32x2";
    break;
  case BRIG_TYPE_F32X4:
    O << "_f32x4";
    break;
  case BRIG_TYPE_F64X2:
    O << "_f64x2";
    break;
  }
}

void HSAILInstPrinter::printBrigVariableModifierMask(const MCInst *MI,
                                                     unsigned OpNo,
                                                     raw_ostream &O) {
  switch (MI->getOperand(OpNo).getImm()) {
  case BRIG_VARIABLE_DEFINITION:
    O << "DEFINITION";
    break;
  case BRIG_VARIABLE_CONST:
    O << "CONST";
    break;
  }
}

static void printBrigWidthImpl(raw_ostream &O, unsigned Width) {
  switch (Width) {
  case BRIG_WIDTH_NONE:
    O << "_width(NONE)";
    break;
  case BRIG_WIDTH_1:
    O << "_width(1)";
    break;
  case BRIG_WIDTH_2:
    O << "_width(2)";
    break;
  case BRIG_WIDTH_4:
    O << "_width(4)";
    break;
  case BRIG_WIDTH_8:
    O << "_width(8)";
    break;
  case BRIG_WIDTH_16:
    O << "_width(16)";
    break;
  case BRIG_WIDTH_32:
    O << "_width(32)";
    break;
  case BRIG_WIDTH_64:
    O << "_width(64)";
    break;
  case BRIG_WIDTH_128:
    O << "_width(128)";
    break;
  case BRIG_WIDTH_256:
    O << "_width(256)";
    break;
  case BRIG_WIDTH_512:
    O << "_width(512)";
    break;
  case BRIG_WIDTH_1024:
    O << "_width(1024)";
    break;
  case BRIG_WIDTH_2048:
    O << "_width(2048)";
    break;
  case BRIG_WIDTH_4096:
    O << "_width(4096)";
    break;
  case BRIG_WIDTH_8192:
    O << "_width(8192)";
    break;
  case BRIG_WIDTH_16384:
    O << "_width(16384)";
    break;
  case BRIG_WIDTH_32768:
    O << "_width(32768)";
    break;
  case BRIG_WIDTH_65536:
    O << "_width(65536)";
    break;
  case BRIG_WIDTH_131072:
    O << "_width(131072)";
    break;
  case BRIG_WIDTH_262144:
    O << "_width(262144)";
    break;
  case BRIG_WIDTH_524288:
    O << "_width(524288)";
    break;
  case BRIG_WIDTH_1048576:
    O << "_width(1048576)";
    break;
  case BRIG_WIDTH_2097152:
    O << "_width(2097152)";
    break;
  case BRIG_WIDTH_4194304:
    O << "_width(4194304)";
    break;
  case BRIG_WIDTH_8388608:
    O << "_width(8388608)";
    break;
  case BRIG_WIDTH_16777216:
    O << "_width(16777216)";
    break;
  case BRIG_WIDTH_33554432:
    O << "_width(33554432)";
    break;
  case BRIG_WIDTH_67108864:
    O << "_width(67108864)";
    break;
  case BRIG_WIDTH_134217728:
    O << "_width(134217728)";
    break;
  case BRIG_WIDTH_268435456:
    O << "_width(268435456)";
    break;
  case BRIG_WIDTH_536870912:
    O << "_width(536870912)";
    break;
  case BRIG_WIDTH_1073741824:
    O << "_width(1073741824)";
    break;
  case BRIG_WIDTH_2147483648:
    O << "_width(2147483648)";
    break;
  case BRIG_WIDTH_WAVESIZE:
    O << "_width(WAVESIZE)";
    break;
  case BRIG_WIDTH_ALL:
    O << "_width(all)";
    break;
  }
}

void HSAILInstPrinter::printBrigWidth(const MCInst *MI, unsigned OpNo,
                                      raw_ostream &O) {
  unsigned Width = MI->getOperand(OpNo).getImm();

  const MCInstrDesc &Desc = MII.get(MI->getOpcode());
  uint32_t DefaultWidth = (Desc.TSFlags & HSAILInstrFlags::WidthAttr) >>
                          Log2_32(HSAILInstrFlags::WidthAttrLo);

  // Don't print the width modifier if it is the default for the instruction.
  switch (DefaultWidth) {
  case HSAILWidthAttrFlags::WidthAttrOne:
    if (Width != BRIG_WIDTH_1)
      printBrigWidthImpl(O, Width);
    return;

  case HSAILWidthAttrFlags::WidthAttrAll:
    if (Width != BRIG_WIDTH_ALL)
      printBrigWidthImpl(O, Width);
    return;

  case HSAILWidthAttrFlags::WidthAttrWaveSize:
    if (Width != BRIG_WIDTH_WAVESIZE)
      printBrigWidthImpl(O, Width);
    return;

  case HSAILWidthAttrFlags::WidthAttrNone:
    printBrigWidthImpl(O, Width);
    return;
  }
}

void HSAILInstPrinter::printOperand(const MCInst *MI, unsigned OpNo,
                                    raw_ostream &O) {
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isReg()) {
    O << getRegisterName(Op.getReg());
  } else if (Op.isExpr()) {
    const MCExpr *Exp = Op.getExpr();
    Exp->print(O);
  } else if (Op.isImm() || Op.isFPImm()) {
    llvm_unreachable("Immediate should have been handled by special printer");
  } else {
    llvm_unreachable("unknown operand type in printOperand");
  }
}

#include "HSAILGenAsmWriter.inc"
