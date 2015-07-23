//===- HSAILTargetStreamer.h -------------------------------------*- C++-*-===//
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

#ifndef LLVM_LIB_TARGET_HSAIL_MCTARGETDESC_HSAILTARGETSTREAMER_H
#define LLVM_LIB_TARGET_HSAIL_MCTARGETDESC_HSAILTARGETSTREAMER_H

#include "llvm/MC/MCStreamer.h"

namespace llvm {

class HSAILTargetStreamer : public MCTargetStreamer {
public:
  HSAILTargetStreamer(MCStreamer &S);
};


class HSAILTargetAsmStreamer : public HSAILTargetStreamer {
public:
  HSAILTargetAsmStreamer(MCStreamer &S);
};

}

#endif
