//===- HSAILMCInstLower.h MachineInstr Lowering Interface -------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
/// \file
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_HSAIL_HSAILMCINSTLOWER_H
#define LLVM_LIB_TARGET_HSAIL_HSAILMCINSTLOWER_H

namespace llvm {

class HSAILAsmPrinter;
class MachineInstr;
class MCContext;
class MCInst;

class HSAILMCInstLower {
  MCContext &Ctx;
  const HSAILAsmPrinter &AP;

public:
  HSAILMCInstLower(MCContext &Ctx, const HSAILAsmPrinter &AP);

  /// \brief Lower a MachineInstr to an MCInst
  void lower(const MachineInstr *MI, MCInst &OutMI) const;
};

} // End namespace llvm

#endif
