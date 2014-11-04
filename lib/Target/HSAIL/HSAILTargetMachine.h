//=-- HSAILMachine.h - Define TargetMachine for the HSAIL ---*- C++ -*-=//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file declares the HSAIL specific subclass of TargetMachine.
//
//===----------------------------------------------------------------------===//

#ifndef _HSAIL_TARGET_MACHINE_H_
#define _HSAIL_TARGET_MACHINE_H_

#include "HSAIL.h"
#include "HSAILFrameLowering.h"
#include "HSAILInstrInfo.h"
#include "HSAILIntrinsicInfo.h"
#include "HSAILISelLowering.h"
#include "HSAILSubtarget.h"

#include "llvm/CodeGen/Passes.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/Target/TargetFrameLowering.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetSelectionDAGInfo.h"

namespace llvm {

class formatted_raw_ostream;

class HSAILTargetMachine : public LLVMTargetMachine {
public:
  HSAILSubtarget      Subtarget;
  Reloc::Model      DefRelocModel; // Reloc model before it's overridden.
  HSAILIntrinsicInfo IntrinsicInfo;
  bool mDebugMode;
  
  class HSAILSelectionDAGInfo : public TargetSelectionDAGInfo {
    /// Subtarget - Keep a pointer to the HSAILSubtarget around so that we can
    /// make the right decision when generating code for different targets.
    const HSAILSubtarget *Subtarget;

    const HSAILTargetLowering &TLI;

  public:
    explicit HSAILSelectionDAGInfo(const HSAILTargetMachine &TM) :
      TargetSelectionDAGInfo(TM.getSubtarget<HSAILSubtarget>().getDataLayout()),
      Subtarget(&TM.getSubtarget<HSAILSubtarget>()),
      TLI(*TM.getSubtarget<HSAILSubtarget>().getTargetLowering()) {}
  };

public:

  //  HSAILTargetMachine(const Target &T,
  //                   const std::string &TT,
  //                   const std::string &FS,
  //                   bool is64Bit);

 HSAILTargetMachine(const Target &T, StringRef TT, StringRef CPU, StringRef FS,
    const TargetOptions &Options, Reloc::Model RM, CodeModel::Model CM,CodeGenOpt::Level OL, bool is64bitTarget);

  virtual const HSAILIntrinsicInfo*
  getIntrinsicInfo() const { return &IntrinsicInfo; }

  virtual const HSAILSubtarget*
  getSubtargetImpl() const { return &Subtarget; }

  virtual const HSAILSelectionDAGInfo*
  getSelectionDAGInfo() const {
    llvm_unreachable("getSelectionDAGInfo not implemented");
  }

  virtual TargetPassConfig *createPassConfig(PassManagerBase &PM);

  CodeGenFileType HSAILFileType;

public:
  /// addPassesToEmitFile - Add passes to the specified pass manager to get the
  /// specified file emitted.  Typically this will involve several steps of code
  /// generation.
  virtual bool addPassesToEmitFile(PassManagerBase &PM,
                                   formatted_raw_ostream &Out,
                                   CodeGenFileType FT,
                                   bool DisableVerify = true,
                                   AnalysisID StartAfter = 0,
                                   AnalysisID StopAfter = 0);
};

/// HSAIL_32TargetMachine - HSAIL 32-bit target machine.
class HSAIL_32TargetMachine : public HSAILTargetMachine {
  const DataLayout    DLInfo; // Calculates type size & alignment
  HSAILSelectionDAGInfo TSInfo;
public:
  HSAIL_32TargetMachine(const Target &T,
			StringRef TT, StringRef CPU, 
			StringRef FS,const TargetOptions &Options,
			Reloc::Model RM, 
			CodeModel::Model CM,CodeGenOpt::Level OL);


  // Interfaces to the major aspects of target machine information:
  // -- Instruction opcode and operand information
  // -- Pipelines and scheduling information
  // -- Stack frame information
  // -- Selection DAG lowering information

  virtual const DataLayout*
  getDataLayout() const { return &DLInfo; }

  virtual const HSAILSelectionDAGInfo*
  getSelectionDAGInfo() const { return &TSInfo; }

  void dump(raw_ostream &O);
  void setDebug(bool debugMode);
  bool getDebug() const;
};

/// HSAIL_64TargetMachine - HSAIL 64-bit target machine.
///
class HSAIL_64TargetMachine : public HSAILTargetMachine {
  const DataLayout  DLInfo; // Calculates type size & alignment
  HSAILSelectionDAGInfo TSInfo;
public:
  HSAIL_64TargetMachine(const Target &T,
			StringRef TT, StringRef CPU, 
			StringRef FS,const TargetOptions &Options,
			Reloc::Model RM, 
			CodeModel::Model CM,CodeGenOpt::Level OL);

  // Interfaces to the major aspects of target machine information:
  // -- Instruction opcode and operand information
  // -- Pipelines and scheduling information
  // -- Stack frame information
  // -- Selection DAG lowering information
  virtual const DataLayout*
  getDataLayout() const
  {
    return &DLInfo;
  }

  virtual const HSAILSelectionDAGInfo*
  getSelectionDAGInfo() const
  {
    return &TSInfo;
  }

};

} // End llvm namespace

namespace llvm {
class HSAILPassConfig : public TargetPassConfig {
public:
  HSAILPassConfig(HSAILTargetMachine *TM, PassManagerBase &PM)
    : TargetPassConfig(TM, PM)
  {
  }

  HSAILTargetMachine &getHSAILTargetMachine() const {
    return getTM<HSAILTargetMachine>();
  }

  const HSAILSubtarget &getHSAILSubtarget() const {
    return *getHSAILTargetMachine().getSubtargetImpl();
  }

  // Pass Pipeline Configuration
  virtual void addIRPasses() override;
  virtual bool addPreEmitPass();
  virtual bool addPreISel();
  virtual bool addInstSelector();
  virtual bool addPreRegAlloc();
  virtual bool addPostRegAlloc();

};
} // End llvm namespace
#endif
