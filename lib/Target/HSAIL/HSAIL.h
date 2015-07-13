//===-- HSAIL.h - Top-level interface for HSAIL representation --*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the entry points for global functions defined in the x86
// target library, as used by the LLVM JIT.
//
//===----------------------------------------------------------------------===//

#ifndef TARGET_HSAIL_H
#define TARGET_HSAIL_H

#include "llvm/Support/DataTypes.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/MC/MCAsmBackend.h"
#include "llvm/MC/MCInstrDesc.h"

#include "MCTargetDesc/HSAILMCTargetDesc.h"

#define HSAIL_MAJOR_VERSION 3
#define HSAIL_MINOR_VERSION 1
#define HSAIL_REVISION_NUMBER 104
#define HSAIL_20_REVISION_NUMBER 88
#define ARENA_SEGMENT_RESERVED_UAVS 12
#define DEFAULT_ARENA_UAV_ID 8
#define DEFAULT_RAW_UAV_ID 7
#define GLOBAL_RETURN_RAW_UAV_ID 11
#define HW_MAX_NUM_CB 8
#define MAX_NUM_UNIQUE_UAVS 8

// The next two values can never be zero, as zero is the ID that is
// used to assert against.
#define DEFAULT_LDS_ID 1
#define DEFAULT_GDS_ID 1
#define DEFAULT_SCRATCH_ID 1
#define DEFAULT_VEC_SLOTS 8

#define OCL_DEVICE_ALL 0xFFFFF

const unsigned int RESERVED_FUNCS = 1024;

namespace llvm {

class FunctionPass;
class HSAILTargetMachine;
class LoopPass;
class ModulePass;
class Target;


ModulePass *createHSAILLowerSPIRSamplersPass();

///
///
FunctionPass *createHSAILControlDependencyAnalysis();

///
///
FunctionPass *createHSAILUniformOperations(const HSAILTargetMachine &TM);

///
///
FunctionPass *createHSAILOptimizeMemoryOps(const HSAILTargetMachine &TM);

///
///
FunctionPass *createHSAILPropagateImageOperandsPass();

///
///
ModulePass *createHSAILSyntaxCleanupPass();

/// Insert kernel index metadata for device enqueue.
ModulePass *createHSAILInsertKernelIndexMetadataPass();

/// Optimize and lower AddrSpaceCast
FunctionPass *createHSAILAddrSpaceCastPass();

ModulePass *createHSAILProducePrintfMetadataPass();
FunctionPass *createHSAILConsumePrintfMetadataPass(HSAILTargetMachine &TM);

ModulePass *createHSAILNullPtrInsertionPass();

/// createHSAILEarlyCFGOpts - HSAIL specific control flow optimizations
LoopPass *createHSAILEarlyCFGOpts();

/// createHSAILISelDag - This pass converts a legalized DAG into a
/// HSAIL-specific DAG, ready for instruction scheduling.
FunctionPass *createHSAILISelDag(TargetMachine &TM);

/// createGlobalBaseRegPass - This pass initializes a global base
/// register for PIC on x86-32.
FunctionPass *createGlobalBaseRegPass();

/// createHSAILFloatingPointStackifierPass - This function returns a pass which
/// converts floating point register references and pseudo instructions into
/// floating point stack references and physical instructions.
///
FunctionPass *createHSAILFloatingPointStackifierPass();

/// createSSEDomainFixPass - This pass twiddles SSE opcodes to prevent domain
/// crossings.
FunctionPass *createSSEDomainFixPass();

/// createHSAILEmitCodeToMemory - Returns a pass that converts a register
/// allocated function into raw machine code in a dynamically
/// allocated chunk of memory.
FunctionPass *createEmitHSAILCodeToMemory();

/// createHSAILMaxStackAlignmentHeuristicPass - This function returns a pass
/// which determines whether the frame pointer register should be
/// reserved in case dynamic stack alignment is later required.
///
FunctionPass *createHSAILMaxStackAlignmentHeuristicPass();

FunctionPass *createHSAILFuncArgScopeEmitter(TargetMachine &tm,
                                             CodeGenOpt::Level OL);

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

// Enum for memory operand decoding
namespace HSAILADDRESS {
enum { BASE = 0, REG = 1, OFFSET = 2, ADDRESS_NUM_OPS };
}

// Target architectures to optimize for
enum OptimizeForTargetArch {
  GENERIC, // No target specific flavor
  SI       // Optimize fot Southern Islands family
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
