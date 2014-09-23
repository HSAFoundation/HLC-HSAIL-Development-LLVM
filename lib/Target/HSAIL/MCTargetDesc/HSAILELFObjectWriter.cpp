//===-- HSAILELFObjectWriter.cpp - HSAIL ELF Object Writer ----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "HSAILELFObjectWriter.h"
using namespace llvm;

HSAILELFObjectWriter::HSAILELFObjectWriter(bool is64Bit,
                                           Triple::OSType OSType,
                                           uint16_t EMachine,
                                           bool HasRelocationAddend)
  : MCELFObjectTargetWriter(is64Bit, OSType, EMachine, HasRelocationAddend) {}
