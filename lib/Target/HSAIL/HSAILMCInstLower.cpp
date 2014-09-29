//===- HSAILMCInstLower.cpp - Lower HSAIL MachineInstr to an MCInst ------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
/// \file
/// \brief Code to lower HSAIL MachineInstrs to their corresponding MCInst.
//
//===----------------------------------------------------------------------===//
//

#include "HSAILMCInstLower.h"
#include "HSAILAsmPrinter.h"
#include "HSAILTargetMachine.h"
#include "InstPrinter/HSAILInstPrinter.h"
#include "llvm/CodeGen/MachineBasicBlock.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/MC/MCCodeEmitter.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCObjectStreamer.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/Format.h"
#include <algorithm>

using namespace llvm;

HSAILMCInstLower::HSAILMCInstLower(MCContext &ctx, const HSAILSubtarget &st):
  Ctx(ctx)
{ }

void HSAILMCInstLower::lower(const MachineInstr *MI, MCInst &OutMI) const {

  OutMI.setOpcode(MI->getOpcode());

  for (const MachineOperand &MO : MI->explicit_operands()) {
    MCOperand MCOp;
    switch (MO.getType()) {
    default:
      llvm_unreachable("unknown operand type");
    case MachineOperand::MO_FPImmediate: {
      const APFloat &FloatValue = MO.getFPImm()->getValueAPF();

      if (&FloatValue.getSemantics() == &APFloat::IEEEsingle)
        MCOp = MCOperand::CreateFPImm(FloatValue.convertToFloat());
      else if (&FloatValue.getSemantics() == &APFloat::IEEEdouble)
        MCOp = MCOperand::CreateFPImm(FloatValue.convertToDouble());
      else
        llvm_unreachable("Unhandled floating point type");
      break;
    }
    case MachineOperand::MO_Immediate:
      MCOp = MCOperand::CreateImm(MO.getImm());
      break;
    case MachineOperand::MO_Register:
      MCOp = MCOperand::CreateReg(MO.getReg());
      break;
    case MachineOperand::MO_MachineBasicBlock:
      MCOp = MCOperand::CreateExpr(MCSymbolRefExpr::Create(
                                   MO.getMBB()->getSymbol(), Ctx));
      break;
    case MachineOperand::MO_GlobalAddress: {
      const GlobalValue *GV = MO.getGlobal();
      MCSymbol *Sym = Ctx.GetOrCreateSymbol(StringRef(GV->getName()));
      MCOp = MCOperand::CreateExpr(MCSymbolRefExpr::Create(Sym, Ctx));
      break;
    }
    case MachineOperand::MO_ExternalSymbol: {
      MCSymbol *Sym = Ctx.GetOrCreateSymbol(StringRef(MO.getSymbolName()));
      MCOp = MCOperand::CreateExpr(MCSymbolRefExpr::Create(Sym, Ctx));
      break;
    }
    case MachineOperand::MO_TargetIndex: {
      llvm_unreachable("Don't know how to lower target index");
      break;
    }
    }
    OutMI.addOperand(MCOp);
  }
}

void HSAILAsmPrinter::EmitInstruction(const MachineInstr *MI) {
  HSAILMCInstLower MCInstLowering(OutContext,
                               MF->getTarget().getSubtarget<HSAILSubtarget>());

  MCInst TmpInst;
  MCInstLowering.lower(MI, TmpInst);
  EmitToStreamer(OutStreamer, TmpInst);
}
