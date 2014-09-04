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

def Feature64BitPtr : SubtargetFeature<"64BitPtr",
  "mIs64bit",
  "false",
  "Specify if 64bit addressing should be used.">;

def FeatureMetadata30 : SubtargetFeature<"metadata30",
  "mMetadata30",
  "true",
  "Enable generation of version 3.0 of the metadata spec">;

def FeatureImages : SubtargetFeature<"images",
  "CapsOverride[HSAILDeviceInfo::Images]",
  "true",
  "Enable image functions">;

def FeatureDebug : SubtargetFeature<"debug",
  "CapsOverride[HSAILDeviceInfo::Debug]",
  "true",
  "Debug mode is enabled, so disable hardware accelerated address spaces.">;
  
//===----------------------------------------------------------------------===//
// HSAIL processors supported.
//===----------------------------------------------------------------------===//

class Proc<string Name, list<SubtargetFeature> Features>
 : Processor<Name, NoItineraries, Features>;

def : Proc<"generic", [FeatureDebug, FeatureImages]>;

//===----------------------------------------------------------------------===//
// Register File Description
//===----------------------------------------------------------------------===//

include "HSAILRegisterInfo.td"

//===----------------------------------------------------------------------===//
// Instruction Descriptions
//===----------------------------------------------------------------------===//

include "HSAILInstrInfo.td"

def HSAILInstrInfo : InstrInfo;

def HSAIL : Target {
  // Information about the instructions...
  let InstructionSet = HSAILInstrInfo;
}

