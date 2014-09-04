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
#define DEFAULT_LDS_ID     1
#define DEFAULT_GDS_ID     1
#define DEFAULT_SCRATCH_ID 1
#define DEFAULT_VEC_SLOTS  8

#define OCL_DEVICE_ALL          0xFFFFF

const unsigned int RESERVED_FUNCS = 1024;

#include "HSAILDeviceInfo.h"

namespace llvm {

class FunctionPass;
class LoopPass;
class MCCodeEmitter;
class MCContext;
class MCObjectWriter;
class MCSubtargetInfo;
class MCContext;
class MCInstrInfo;
class MCRegisterInfo;
class MCStreamer;
class MachineCodeEmitter;
class Target;
class TargetAsmBackend;
class HSAILTargetMachine;
class formatted_raw_ostream;
class raw_ostream;
class ModulePass;

ModulePass*
createHSAILLowerSPIRSamplersPass();

///
///
FunctionPass *
createHSAILControlDependencyAnalysis();

///
///
FunctionPass *
createHSAILUniformOperations(const HSAILTargetMachine &TM);

///
///
FunctionPass *
createHSAILOptimizeMemoryOps(const HSAILTargetMachine &TM);

FunctionPass *
createHSAILResizeLocalPointer(const HSAILTargetMachine &TM);

///
///
FunctionPass*
createHSAILPropagateImageOperandsPass();

///
///
ModulePass *
createHSAILSyntaxCleanupPass();

/// Insert OpenCL global offsets as HSAIL kernargs
ModulePass* createHSAILGlobalOffsetInsertionPass(HSAILTargetMachine &TM);

/// Insert kernel index metadata for device enqueue.
ModulePass* createHSAILInsertKernelIndexMetadataPass();

/// Optimize and lower AddrSpaceCast
FunctionPass *createHSAILAddrSpaceCastPass();

ModulePass *createHSAILPrintfRuntimeBindingKernArg(HSAILTargetMachine &TM);
FunctionPass *createHSAILPrintfRuntimeBindingMetadata(HSAILTargetMachine &TM);

ModulePass *createHSAILNullPtrInsertionPass();

/// createHSAILEarlyCFGOpts - HSAIL specific control flow optimizations
LoopPass *
createHSAILEarlyCFGOpts();

/// createHSAILISelDag - This pass converts a legalized DAG into a
/// HSAIL-specific DAG, ready for instruction scheduling.
FunctionPass*
createHSAILISelDag(HSAILTargetMachine &TM,
                   CodeGenOpt::Level OptLevel);

/// createGlobalBaseRegPass - This pass initializes a global base
/// register for PIC on x86-32.
FunctionPass*
createGlobalBaseRegPass();

/// createHSAILFloatingPointStackifierPass - This function returns a pass which
/// converts floating point register references and pseudo instructions into
/// floating point stack references and physical instructions.
///
FunctionPass*
createHSAILFloatingPointStackifierPass();

/// createSSEDomainFixPass - This pass twiddles SSE opcodes to prevent domain
/// crossings.
FunctionPass*
createSSEDomainFixPass();

MCCodeEmitter*
createHSAIL_32MCCodeEmitter(const Target &T,
                            TargetMachine &TM,
                            MCContext &Ctx);

MCStreamer* createHSAILMCStreamer(const Target &T, StringRef TT, MCContext &Ctx, MCAsmBackend &TAB,
                                  raw_ostream &_OS, MCCodeEmitter *_Emitter,
                                  bool RelaxAll, bool NoExecStack);

MCCodeEmitter*
createHSAIL_64MCCodeEmitter(const Target &T,
                            TargetMachine &TM,
                            MCContext &Ctx);

MCCodeEmitter* createHSAIL_32MCCodeEmitterForLLVM32(const MCInstrInfo &II, 
		                 const MCRegisterInfo &MRI,
                                 const MCSubtargetInfo &STI, MCContext &Ctx);
MCCodeEmitter* createHSAIL_64MCCodeEmitterForLLVM32(const MCInstrInfo &II, 
		                 const MCRegisterInfo &MRI,
                                 const MCSubtargetInfo &STI, MCContext &Ctx);

MCAsmBackend* createHSAIL_32AsmBackendForLLVM32(const Target &T, StringRef TT, StringRef CPU);
MCAsmBackend* createHSAIL_64AsmBackendForLLVM32(const Target &T, StringRef TT, StringRef CPU);

MCAsmBackend*
createHSAIL_32AsmBackend(const MCAsmBackend &T, const std::string &s);

MCAsmBackend*
createHSAIL_64AsmBackend(const MCAsmBackend &T, const std::string &s);

/// createHSAILEmitCodeToMemory - Returns a pass that converts a register
/// allocated function into raw machine code in a dynamically
/// allocated chunk of memory.
FunctionPass*
createEmitHSAILCodeToMemory();

/// createHSAILMaxStackAlignmentHeuristicPass - This function returns a pass
/// which determines whether the frame pointer register should be
/// reserved in case dynamic stack alignment is later required.
///
FunctionPass*
createHSAILMaxStackAlignmentHeuristicPass();

FunctionPass *
createHSAILFuncArgScopeEmitter(TargetMachine &tm, CodeGenOpt::Level OL);

extern Target TheHSAIL_32Target, TheHSAIL_64Target;

} // End llvm namespace

/*
// Defines symbolic names for HSAIL registers.  This defines a mapping from
// register name to register number.
//
#include "HSAILGenRegisterNames.inc"

// Defines symbolic names for the HSAIL instructions.
//
#include "HSAILGenInstrNames.inc"
*/

#define GET_REGINFO_ENUM
#include "HSAILGenRegisterInfo.inc"
#define GET_INSTRINFO_ENUM
#include "HSAILGenInstrInfo.inc"

namespace llvm {
  namespace HSAILAS {

    enum AddressSpaces {
      PRIVATE_ADDRESS  = 0,
      GLOBAL_ADDRESS   = 1,
      CONSTANT_ADDRESS = 2, // TODO_HSA: rename to READONLY_ADDRESS
      GROUP_ADDRESS    = 3,
      FLAT_ADDRESS     = 4,
      REGION_ADDRESS   = 5,
      SPILL_ADDRESS    = 6,
      KERNARG_ADDRESS  = 7,
      ARG_ADDRESS      = 8,
      ADDRESS_NONE     = 9
     };
  }

  // Target flags from tablegen
  // See HSAILInstFormats.td
  namespace HSAILTSFLAGS {
    enum {
      HAS_ADDRESS = 0,
      ADDRESS_OP_NUM0 = 1,
      ADDRESS_OP_NUM1 = 2,
      ADDRESS_OP_NUM2 = 3,
      IS_LOAD         = 4,
      IS_STORE        = 5,
      IS_CONV = 6
    };
  }

  // Enum for memory operand decoding
  namespace HSAILADDRESS {
    enum {
      BASE = 0,
      REG = 1,
      OFFSET = 2,
      ADDRESS_NUM_OPS
    };
  }

  // Target architectures to optimize for
  enum OptimizeForTargetArch {
    GENERIC, // No target specific flavor
    SI       // Optimize fot Southern Islands family
  };
}

#define IMAGE_ARG_BIAS  (1 << 16)

#endif
