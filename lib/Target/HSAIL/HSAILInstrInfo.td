//==- HSAILInstrInfo.td - Main HSAIL Instruction Definition -*- tablegen -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file describes the HSAIL instruction set, defining the instructions, and
// properties of the instructions which are needed for code generation, machine
// code emission, and analysis.
//
//===----------------------------------------------------------------------===//

//
// TODO_HSA: llc option -enable-experimental should be cleaned from llc itself
//           and this file as soon as all features are supported.
//
def EnableExperimental : Predicate<"llvm::EnableExperimentalFeatures">;
def In32BitMode  : Predicate<"!Subtarget->is64Bit()">;
def In64BitMode  : Predicate<"Subtarget->is64Bit()">;
def EnableOpt    : Predicate<"CodeGenOpt::None != TM.getOptLevel()">;

// Predicate defs
def HSAILisKernel         : Predicate<"isKernelFunc()">;
def HSAILisNotKernel      : Predicate<"!isKernelFunc()">;


// Mark the default value for a width modifier. This only effects how
// the instruction is printed in the non-BRIG path.
class WidthAttrValues_ {
  bits<2> NONE = 0;
  bits<2> ALL = 1;
  bits<2> WAVESIZE = 2;
  bits<2> ONE = 3;
}

def WidthAttrValues : WidthAttrValues_;


class AtomicNoRet <string noRetOp, bit isRet> {
  string NoRetOp = noRetOp;
  bit IsRet = isRet;
}

// Maps an atomic opcode to its version with a return value.
def getAtomicRetOp : InstrMapping {
  let FilterClass = "AtomicNoRet";
  let RowFields = ["NoRetOp"];
  let ColFields = ["IsRet"];
  let KeyCol = ["0"];
  let ValueCols = [["1"]];
}

// Maps an atomic opcode to its returnless version.
def getAtomicNoRetOp : InstrMapping {
  let FilterClass = "AtomicNoRet";
  let RowFields = ["NoRetOp"];
  let ColFields = ["IsRet"];
  let KeyCol = ["1"];
  let ValueCols = [["0"]];
}

//===----------------------------------------------------------------------===//
// Custom Operands
//===----------------------------------------------------------------------===//
include "HSAILOperands.td"
include "HSAILEnums.td"

//===----------------------------------------------------------------------===//
// Custom Selection DAG Type Profiles
//===----------------------------------------------------------------------===//
include "HSAILProfiles.td"

//===----------------------------------------------------------------------===//
// Custom Selection DAG Nodes
//===----------------------------------------------------------------------===//
include "HSAILNodes.td"

//===----------------------------------------------------------------------===//
// Custom Pattern DAG Nodes
//===----------------------------------------------------------------------===//
include "HSAILPatterns.td"

//===----------------------------------------------------------------------===//
// Instruction format classes
//===----------------------------------------------------------------------===//
include "HSAILInstrFormats.td"

//===----------------------------------------------------------------------===//
// Intrinsics support
//===----------------------------------------------------------------------===//
include "HSAILIntrinsics.td"

//===----------------------------------------------------------------------===//
// Instructions support
//===----------------------------------------------------------------------===//
include "HSAILInstructions.td"
