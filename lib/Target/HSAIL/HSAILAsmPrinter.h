//===-- HSAILAsmPrinter.h - Print HSAIL assembly code -----------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
/// \file
/// \brief HSAIL Assembly printer class.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_HSAIL_HSAILASMPRINTER_H
#define LLVM_LIB_TARGET_HSAIL_HSAILASMPRINTER_H

#include "llvm/CodeGen/AsmPrinter.h"
#include <vector>

namespace llvm {

class HSAILAsmPrinter : public AsmPrinter {
public:
  explicit HSAILAsmPrinter(TargetMachine &TM, MCStreamer &Streamer);

  bool runOnMachineFunction(MachineFunction &MF) override;

  const char *getPassName() const override {
    return "HSAIL Assembly Printer";
  }

  /// Implemented in HSAILMCInstLower.cpp
  void EmitInstruction(const MachineInstr *MI) override;
};

} // End anonymous llvm

#endif
