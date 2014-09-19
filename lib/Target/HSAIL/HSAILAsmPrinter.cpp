//===-- HSAILAsmPrinter.cpp - HSAIL Assebly printer  ---------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
/// \file
///
/// The HSAILAsmPrinter is used to print both assembly string and also binary
/// code.  When passed an MCAsmStreamer it prints assembly and when passed
/// an MCObjectStreamer it outputs binary code.
//
//===----------------------------------------------------------------------===//
//

#include "HSAILAsmPrinter.h"
#include "HSAIL.h"
#include "HSAILSubtarget.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCSectionELF.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/Support/ELF.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Target/TargetLoweringObjectFile.h"

using namespace llvm;

static AsmPrinter *createHSAILAsmPrinterPass(TargetMachine &tm,
                                              MCStreamer &Streamer) {
  return new HSAILAsmPrinter(tm, Streamer);
}

#if 0
// FIXME: Uncomment when are using the llvm based asm printer.
extern "C" void LLVMInitializeHSAILAsmPrinter() {
  TargetRegistry::RegisterAsmPrinter(TheHSAILTarget, createHSAILAsmPrinterPass);
}

#endif

HSAILAsmPrinter::HSAILAsmPrinter(TargetMachine &TM, MCStreamer &Streamer)
    : AsmPrinter(TM, Streamer) {
}

bool HSAILAsmPrinter::runOnMachineFunction(MachineFunction &MF) {
  SetupMachineFunction(MF);

  OutStreamer.SwitchSection(getObjFileLowering().getTextSection());
  EmitFunctionBody();

  return false;
}
