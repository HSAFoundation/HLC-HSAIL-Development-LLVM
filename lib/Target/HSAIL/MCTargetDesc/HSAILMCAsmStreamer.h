//===-- HSAILMCAsmStreamer.h ------------------------------------*- C++ -*--==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_HSAIL_MCTARGETDESC_HSAILMCASMSTREAMER_H
#define LLVM_LIB_TARGET_HSAIL_MCTARGETDESC_HSAILMCASMSTREAMER_H

#include "llvm/MC/MCStreamer.h"

namespace llvm {

MCStreamer *createHSAILMCAsmStreamer(
  MCContext &Context,
  std::unique_ptr<formatted_raw_ostream> OS,
  bool IsVerboseAsm, bool UseDwarfDirectory,
  MCInstPrinter *IP, MCCodeEmitter *CE,
  MCAsmBackend *MAB, bool ShowInst);

}

#endif
