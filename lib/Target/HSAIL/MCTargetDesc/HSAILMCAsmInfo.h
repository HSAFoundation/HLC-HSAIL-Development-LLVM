//===-- HSAILMCAsmInfo.h - HSAIL asm properties -----------------*- C++ -*--==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declaration of the HSAILMCAsmInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_HSAIL_MCTARGETDESC_HSAILMCASMINFO_H
#define LLVM_LIB_TARGET_HSAIL_MCTARGETDESC_HSAILMCASMINFO_H

#include "llvm/MC/MCAsmInfo.h"

namespace llvm {
class Triple;

struct HSAILELFMCAsmInfo : public MCAsmInfo {
  explicit HSAILELFMCAsmInfo(const Triple &TT);
  MCSection *getNonexecutableStackSection(MCContext &Ctx) const override;

  bool isValidUnquotedName(StringRef Name) const override;
};
} // namespace llvm

#endif
