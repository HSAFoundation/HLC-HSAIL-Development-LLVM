//===-- HSAILTargetMachine.cpp - Define TargetMachine for the HSAIL -------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the HSAIL specific subclass of TargetMachine.
//
//===----------------------------------------------------------------------===//

#include "HSAILTargetMachine.h"
#include "HSAILELFTargetObjectFile.h"

#include "llvm/CodeGen/Passes.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Transforms/IPO.h"
#include "llvm/Transforms/Scalar.h"

using namespace llvm;

#if HSAIL_USE_LIBHSAIL
static cl::opt<bool> UseStandardAsmPrinter(
    "hsail-asmprinter",
    cl::desc("Use standard LLVM AsmPrinter instead of BRIGAsmPrinter"),
    cl::init(false));
#else
static const bool UseStandardAsmPrinter = true;
#endif

extern "C" void LLVMInitializeHSAILTarget() {
  // Register the target.
  RegisterTargetMachine<HSAIL_32TargetMachine> X(TheHSAIL_32Target);
  RegisterTargetMachine<HSAIL_64TargetMachine> Y(TheHSAIL_64Target);
}

extern "C" void LLVMInitializeBRIGAsmPrinter();

static TargetLoweringObjectFile *createTLOF(const Triple &TT) {
  if (UseStandardAsmPrinter)
    return new HSAILTargetObjectFile();

  if (TT.getArch() == Triple::hsail64)
    return new BRIG64_DwarfTargetObjectFile();
  return new BRIG32_DwarfTargetObjectFile();
}

static StringRef computeDataLayout(const Triple &T) {
  if (T.getArch() == Triple::hsail64) {
    return "e-p:32:32-p1:64:64-p2:64:64-p3:32:32-p4:64:64-p5:32:32"
           "-p6:32:32-p7:64:64-p8:32:32-p9:64:64-i1:8:8-i8:8:8"
           "-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-f80:32:32"
           "-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64"
           "-v96:128:128-v128:128:128-v192:256:256-v256:256:256"
           "-v512:512:512-v1024:1024:1024-v2048:2048:2048"
           "-n32:64";
  }

  return "e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16"
         "-i32:32:32-i64:64:64-f32:32:32-f64:64:64-f80:32:32"
         "-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64"
         "-v96:128:128-v128:128:128-v192:256:256-v256:256:256"
         "-v512:512:512-v1024:1024:1024-v2048:2048:2048"
         "-n32:64";
}

// Hack to prevent weird standard OS directives from being printed when the
// triple is not fully specified. e.g. on a OS X host, there is no other way to
// disable printing .macosx_version_min at the start of the module.
LLVM_READONLY
static Triple getTripleNoOS(StringRef Str) {
  Triple TT(Str);
  if (TT.getOS() != Triple::UnknownOS)
    TT.setOS(Triple::UnknownOS);

  return TT;
}

HSAILTargetMachine::HSAILTargetMachine(const Target &T, StringRef TT,
                                       StringRef CPU, StringRef FS,
                                       const TargetOptions &Options,
                                       Reloc::Model RM, CodeModel::Model CM,
                                       CodeGenOpt::Level OL)
  : LLVMTargetMachine(T, computeDataLayout(getTripleNoOS(TT)),
                      getTripleNoOS(TT).str(), CPU, FS, Options, RM, CM, OL),
      Subtarget(TT, CPU, FS, *this), IntrinsicInfo(this),
      TLOF(createTLOF(Triple(getTargetTriple()))) {
  initAsmInfo();

#if HSAIL_USE_LIBHSAIL
  // FIXME: Hack to enable command line switch to switch between
  // BRIGAsmPrinter and HSAILAsmPrinter. Override the default registered
  // AsmPrinter to use the BRIGAsmPrinter.
  if (!UseStandardAsmPrinter)
    LLVMInitializeBRIGAsmPrinter();
#endif
}

bool HSAILTargetMachine::addPassesToEmitFile(
    PassManagerBase &PM, raw_pwrite_stream &Out, CodeGenFileType FT,
    bool DisableVerify, AnalysisID StartAfter, AnalysisID StopAfter,
    MachineFunctionInitializer *MFInitializer) {
  HSAILFileType = FT; // FIXME: Remove this.

  if (!UseStandardAsmPrinter) {
    // Use CGFT_ObjectFile regardless on the output format.
    // To process CGFT_AssemblyFile we will later disassemble generated BRIG.
    FT = CGFT_ObjectFile;
  }

  return LLVMTargetMachine::addPassesToEmitFile(PM, Out, FT, DisableVerify,
                                                StartAfter, StopAfter,
                                                MFInitializer);
}

TargetPassConfig *HSAILTargetMachine::createPassConfig(PassManagerBase &PM) {
  return new HSAILPassConfig(this, PM);
}

void HSAILPassConfig::addIRPasses() {
  addPass(createHSAILAlwaysInlinePass());
  addPass(createAlwaysInlinerPass());

  // AddrSpaceCast optimization and lowering. Add dead code elimination
  // to eliminate dead instructions (AddrSpaceCast, etc.).
  TargetPassConfig::addIRPasses();
}

bool HSAILPassConfig::addPreISel() {
  addPass(createLCSSAPass()); // Required by early CFG opts

  return true;
}

bool HSAILPassConfig::addInstSelector() {
  HSAILTargetMachine &HSATM = getTM<HSAILTargetMachine>();
  // return
  // HSAILTargetMachine::addInstSelector(*PM,HSATM.Options,HSATM.getOptLevel());
  // mOptLevel = OptLevel;
  // Install an instruction selector.

  addPass(createHSAILISelDag(HSATM));

#if 0
  addPass(&DeadMachineInstructionElimID);
  if (EnableUniformOps) {
    addPass(createHSAILUniformOperations(HSATM));
  }
#endif

  return false;
}
void HSAILPassConfig::addPreEmitPass() { }
void HSAILPassConfig::addPreRegAlloc() { }
void HSAILPassConfig::addPostRegAlloc() { }

//===----------------------------------------------------------------------===//
// HSAIL_32Machine functions
//===----------------------------------------------------------------------===//
HSAIL_32TargetMachine::HSAIL_32TargetMachine(const Target &T, StringRef TT,
                                             StringRef CPU, StringRef FS,
                                             const TargetOptions &Options,
                                             Reloc::Model RM,
                                             CodeModel::Model CM,
                                             CodeGenOpt::Level OL)
    : HSAILTargetMachine(T, TT, CPU, FS, Options, RM, CM, OL), TSInfo(*this) {
  Triple TheTriple(TT);

  // Check for mismatch in target triple settings and data layout. Note the
  // target
  // triple comes from the module (unless overridden on command line). It's just
  // a
  // warning, but users should know if they're specifying --march=hsail-64 on a
  // 32-bit module or --march=hsail on a 64-bit module.
  if (TheTriple.getArch() == Triple::hsail64) {
    errs()
        << "warning: target triple '" << TT
        << "' does not match target 'hsail', expecting hsail-pc-amdopencl.\n";
  }
}

//===----------------------------------------------------------------------===//
// HSAIL_64Machine functions
//===----------------------------------------------------------------------===//
HSAIL_64TargetMachine::HSAIL_64TargetMachine(const Target &T, StringRef TT,
                                             StringRef CPU, StringRef FS,
                                             const TargetOptions &Options,
                                             Reloc::Model RM,
                                             CodeModel::Model CM,
                                             CodeGenOpt::Level OL)
    : HSAILTargetMachine(T, TT, CPU, FS, Options, RM, CM, OL), TSInfo(*this) {
  Triple TheTriple(TT);

  // Check for mismatch in target triple settings and data layout. Note the
  // target
  // triple comes from the module (unless overridden on command line). It's just
  // a
  // warning, but users should know if they're specifying --march=hsail-64 on a
  // 32-bit module.
  if (TheTriple.getArch() == Triple::hsail) {
    errs() << "warning: target triple '" << TT << "' does not match target "
                                                  "'hsail-64', expecting "
                                                  "hsail64-pc-amdopencl.\n";
  }
}
