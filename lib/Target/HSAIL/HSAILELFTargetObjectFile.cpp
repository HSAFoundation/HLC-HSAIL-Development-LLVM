//===-- HSAILELFObjectFile.cpp - HSAIL ELF Object Info --------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "HSAILELFTargetObjectFile.h"
using namespace llvm;

HSAIL32_DwarfTargetObjectFile::HSAIL32_DwarfTargetObjectFile(const HSAILTargetMachine &tm)
  : TM(tm) {}

HSAIL64_DwarfTargetObjectFile::HSAIL64_DwarfTargetObjectFile(const HSAILTargetMachine &tm)
  : TM(tm) {}
