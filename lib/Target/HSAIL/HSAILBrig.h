//===-- HSAILBrig.h - Definitions for BRIG files --------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the HSAIL specific subclass of TargetMachine.
//
//===----------------------------------------------------------------------===//

#ifndef HSAILBRIG_H_
#define HSAILBRIG_H_

namespace Brig {

typedef uint16_t BrigType16_t;

enum BrigSegment {
  BRIG_SEGMENT_FLAT   = 1,
  BRIG_SEGMENT_GLOBAL = 2,
  BRIG_SEGMENT_GROUP  = 5,
};

}

#endif //HSAILBRIG_H_
