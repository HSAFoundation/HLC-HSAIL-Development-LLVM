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

//===----------------------------------------------------------------------===//
// Custom Operands
//===----------------------------------------------------------------------===//
include "HSAILOperands.td"

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

//===--------------------------------------------------------------------===//
// Instruction Pattern support - This Must be the last include in the file
// as it requires items defined in other files
//===--------------------------------------------------------------------===//
include "HSAILInstrPatterns.td"
