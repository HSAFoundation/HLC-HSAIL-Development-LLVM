//===- HSAILTargetStreamer.cpp ----------------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the HSAILTargetStreamer class.
//
//===----------------------------------------------------------------------===//
#include "HSAILTargetStreamer.h"

using namespace llvm;

HSAILTargetStreamer::HSAILTargetStreamer(MCStreamer &S) : MCTargetStreamer(S) {}

HSAILTargetAsmStreamer::HSAILTargetAsmStreamer(MCStreamer &S)
  : HSAILTargetStreamer(S) {}


