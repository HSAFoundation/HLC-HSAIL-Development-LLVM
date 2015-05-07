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

HSAILELFObjectWriter::HSAILELFObjectWriter(bool IsLargeModel, uint16_t EMachine,
                                           bool HasRelocationAddend)
    : MCELFObjectTargetWriter(IsLargeModel, 0, EMachine, HasRelocationAddend) {}
