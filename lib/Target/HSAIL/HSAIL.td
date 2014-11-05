//===----- HSAIL.td - Target definition file for HSAIL ----*- tablegen -*--===//
// 
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
// 
//===----------------------------------------------------------------------===//
//
// This is a target description file for the Intel i386 architecture, refered to
// here as the "HSAIL" architecture.
//
//===----------------------------------------------------------------------===//

// Get the target-independent interfaces which we are implementing...
//
include "llvm/Target/Target.td"

//===----------------------------------------------------------------------===//
// HSAIL Subtarget features.
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// HSAIL processors supported.
//===----------------------------------------------------------------------===//

class Proc<string Name, list<SubtargetFeature> Features>
 : Processor<Name, NoItineraries, Features>;

def : Proc<"generic", []>;

//===----------------------------------------------------------------------===//
// Register File Description
//===----------------------------------------------------------------------===//

include "HSAILRegisterInfo.td"

//===----------------------------------------------------------------------===//
// Instruction Descriptions
//===----------------------------------------------------------------------===//

include "HSAILInstrInfo.td"

def HSAILInstrInfo : InstrInfo;

def BRIGAsmWriter : AsmWriter {
  field bit isMCAsmWriter = 0;
}

def HSAIL : Target {
  // Information about the instructions...
  let InstructionSet = HSAILInstrInfo;

  let AssemblyWriters = [BRIGAsmWriter];
}

