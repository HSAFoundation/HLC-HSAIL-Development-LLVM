//===-- HSAILUtil.cpp -----------------------------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This is just to split getNamedOperandIdx out from the rest of the target
// library to avoid the HSAILAsmPrinter library depending on it.

#include "llvm/Support/Compiler.h"
#include "llvm/Support/DataTypes.h"
#include "../MCTargetDesc/HSAILMCTargetDesc.h"

#define GET_INSTRINFO_NAMED_OPS
#include "HSAILGenInstrInfo.inc"
