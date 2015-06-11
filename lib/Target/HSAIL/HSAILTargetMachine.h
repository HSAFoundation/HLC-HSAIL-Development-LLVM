//=-- HSAILTargetMachine.h - Define TargetMachine for the HSAIL ---*- C++ -*-=//
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

#include "HSAILIntrinsicInfo.h"
#include "HSAILSubtarget.h"

#include "llvm/CodeGen/Passes.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetSelectionDAGInfo.h"

namespace llvm {

class HSAILTargetMachine : public LLVMTargetMachine {
private:
  HSAILSubtarget Subtarget;
  HSAILIntrinsicInfo IntrinsicInfo;
  TargetLoweringObjectFile *TLOF;

public:
  class HSAILSelectionDAGInfo : public TargetSelectionDAGInfo {
  public:
    explicit HSAILSelectionDAGInfo(const HSAILTargetMachine &TM)
      : TargetSelectionDAGInfo(TM.getDataLayout()) {}
  };

public:
  HSAILTargetMachine(const Target &T, const Triple &TT, StringRef CPU,
                     StringRef FS, const TargetOptions &
                     Options, Reloc::Model RM, CodeModel::Model CM,
                     CodeGenOpt::Level OL);

  const HSAILIntrinsicInfo *getIntrinsicInfo() const override {
    return &IntrinsicInfo;
  }

  const HSAILSubtarget *getSubtargetImpl() const {
    return &Subtarget;
  }

  const HSAILSubtarget *getSubtargetImpl(const Function &) const override {
    return &Subtarget;
  }

  TargetLoweringObjectFile *getObjFileLowering() const override { return TLOF; }

  TargetPassConfig *createPassConfig(PassManagerBase &PM) override;

  CodeGenFileType HSAILFileType;

public:
  bool addPassesToEmitFile(
    PassManagerBase &PM, raw_pwrite_stream &Out,
    CodeGenFileType FT, bool DisableVerify = true,
    AnalysisID StartBefore = nullptr,
    AnalysisID StartAfter = nullptr,
    AnalysisID StopAfter = nullptr,
    MachineFunctionInitializer *MFInitializer = nullptr) override;
};

class HSAIL_32TargetMachine : public HSAILTargetMachine {
  HSAILSelectionDAGInfo TSInfo;

public:
  HSAIL_32TargetMachine(const Target &T, const Triple &TT, StringRef CPU,
                        StringRef FS, const TargetOptions &Options,
                        Reloc::Model RM, CodeModel::Model CM,
                        CodeGenOpt::Level OL);

  void dump(raw_ostream &O);
};

class HSAIL_64TargetMachine : public HSAILTargetMachine {
  HSAILSelectionDAGInfo TSInfo;

public:
  HSAIL_64TargetMachine(const Target &T, const Triple &TT, StringRef CPU,
                        StringRef FS, const TargetOptions &Options,
                        Reloc::Model RM, CodeModel::Model CM,
                        CodeGenOpt::Level OL);
};

class HSAILPassConfig : public TargetPassConfig {
public:
  HSAILPassConfig(HSAILTargetMachine *TM, PassManagerBase &PM)
      : TargetPassConfig(TM, PM) {}

  // Pass Pipeline Configuration
  void addIRPasses() override;
  void addPreEmitPass() override;
  bool addPreISel() override;
  bool addInstSelector() override;
  void addPreRegAlloc() override;
  void addPostRegAlloc() override;
};
} // End llvm namespace
#endif
