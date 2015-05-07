//===----- HSAIL.td - Target definition file for HSAIL ----*- tablegen -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

include "llvm/Target/Target.td"

//===----------------------------------------------------------------------===//
// HSAIL Subtarget features.
//===----------------------------------------------------------------------===//

def FeatureImages : SubtargetFeature<"images",
        "HasImages",
        "true",
        "Enable image precision operations">;

def FeatureGCN : SubtargetFeature<"gcn",
        "IsGCN",
        "true",
        "Enable AMD GCN extensions">;

//===----------------------------------------------------------------------===//
// HSAIL processors supported.
//===----------------------------------------------------------------------===//

class Proc<string Name, list<SubtargetFeature> Features>
 : Processor<Name, NoItineraries, Features>;

def : Proc<"generic", []>;
def : Proc<"kaveri", [FeatureImages, FeatureGCN]>;

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
  let InstructionSet = HSAILInstrInfo;

  let AssemblyWriters = [BRIGAsmWriter];
}

