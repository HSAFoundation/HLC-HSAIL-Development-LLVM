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

HSAILTargetStreamer::~HSAILTargetStreamer() {}

class HSAILTargetAsmStreamer : public HSAILTargetStreamer {
public:
  HSAILTargetAsmStreamer(MCStreamer &S, formatted_raw_ostream &OS);
};

HSAILTargetAsmStreamer::HSAILTargetAsmStreamer(MCStreamer &S,
                                               formatted_raw_ostream &OS)
    : HSAILTargetStreamer(S) {}
