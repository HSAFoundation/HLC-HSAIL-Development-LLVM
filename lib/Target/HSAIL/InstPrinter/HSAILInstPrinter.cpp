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
#include "MCTargetDesc/HSAILMCTargetDesc.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/Support/MathExtras.h"

using namespace llvm;

void HSAILInstPrinter::printInst(const MCInst *MI, raw_ostream &OS,
                             StringRef Annot) {
  OS.flush();
  printInstruction(MI, OS);

  printAnnotation(OS, Annot);
}

void HSAILInstPrinter::printImmediate(uint32_t Imm, raw_ostream &O) {
  O << formatHex(static_cast<uint64_t>(Imm));
}

void HSAILInstPrinter::printOperand(const MCInst *MI, unsigned OpNo,
                                     raw_ostream &O) {

  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isReg()) {
    O << getRegisterName(Op.getReg());
  } else if (Op.isImm()) {
    printImmediate(Op.getImm(), O);
  } else if (Op.isFPImm()) {
    O << Op.getFPImm();
  } else if (Op.isExpr()) {
    const MCExpr *Exp = Op.getExpr();
    Exp->print(O);
  } else {
    assert(!"unknown operand type in printOperand");
  }
}

#include "HSAILGenAsmWriter.inc"
