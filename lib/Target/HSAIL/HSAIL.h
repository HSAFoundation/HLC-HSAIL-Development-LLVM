//===-- HSAIL.h - Top-level interface for HSAIL representation --*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_HSAIL_HSAIL_H
#define LLVM_LIB_TARGET_HSAIL_HSAIL_H

#include "llvm/Support/DataTypes.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/MC/MCAsmBackend.h"
#include "llvm/MC/MCInstrDesc.h"

#include "MCTargetDesc/HSAILMCTargetDesc.h"

namespace llvm {

class FunctionPass;
class HSAILTargetMachine;
class LoopPass;
class ModulePass;
class Target;

/// Insert kernel index metadata for device enqueue.
ModulePass *createHSAILInsertKernelIndexMetadataPass();

/// This pass converts a legalized DAG into a HSAIL-specific DAG, ready for
/// instruction scheduling.
FunctionPass *createHSAILISelDag(TargetMachine &TM);

ModulePass *createHSAILAlwaysInlinePass();

extern Target TheHSAIL_32Target, TheHSAIL_64Target;

} // End llvm namespace

namespace llvm {
namespace HSAILAS {

enum AddressSpaces {
  PRIVATE_ADDRESS = 0,
  GLOBAL_ADDRESS = 1,
  READONLY_ADDRESS = 2,
  GROUP_ADDRESS = 3,
  FLAT_ADDRESS = 4,
  REGION_ADDRESS = 5,
  SPILL_ADDRESS = 6,
  KERNARG_ADDRESS = 7,
  ARG_ADDRESS = 8,
  ADDRESS_NONE = 9
};
}

// Target flags from tablegen
// See HSAILInstFormats.td
namespace HSAILInstrFlags {
enum {
  // Instruction kind.
  InstAddr = 1 << 3,
  InstAtomic = 1 << 4,
  InstBasic = 1 << 5,
  InstBr = 1 << 6,
  InstCmp = 1 << 7,
  InstCvt = 1 << 8,
  InstImage = 1 << 9,
  InstLane = 1 << 10,
  InstMem = 1 << 11,
  InstMemFence = 1 << 12,
  InstMod = 1 << 13,
  InstQueryImage = 1 << 14,
  InstQuerySampler = 1 << 15,
  InstQueue = 1 << 16,
  InstSeg = 1 << 17,
  InstSegCvt = 1 << 18,
  InstSignal = 1 << 19,
  InstSourceType = 1 << 20,

  // Others.
  IS_CONV = 1 << 23,
  IS_IMAGEINST = 1 << 24,

  // Default modifier attributes. Used for marking default values of a
  // modifier for an instruction to skip printing it.
  RoundAttrLo = 1 << 25, // 2 bits
  RoundAttrHi = 1 << 26,
  RoundAttr = RoundAttrLo | RoundAttrHi,

  WidthAttrLo = 1 << 27, // 2 bits
  WidthAttrHi = 1 << 28,
  WidthAttr = WidthAttrLo | WidthAttrHi,

  HasDefaultSegment = 1 << 29,

  InstBrigOpcodeLo = UINT64_C(1) << 48,
  InstBrigOpcode = UINT64_C(0xffff) << 48
};
}

namespace HSAILWidthAttrFlags {
enum {
  WidthAttrNone = 0,
  WidthAttrAll = 1,
  WidthAttrWaveSize = 2,
  WidthAttrOne = 3
};
}

/// Enum for memory operand decoding
namespace HSAILADDRESS {
enum { BASE = 0, REG = 1, OFFSET = 2, ADDRESS_NUM_OPS };
}

/// Target architectures to optimize for
enum OptimizeForTargetArch {
  GENERIC, ///< No target specific flavor
  SI       ///< Optimize fot Southern Islands family
};

namespace HSAIL {
enum OperandType {
  /// Operand with register or immediate.
  OPERAND_REG_IMM = llvm::MCOI::OPERAND_FIRST_TARGET
};
}
}

#define IMAGE_ARG_BIAS (1 << 16)

#endif
