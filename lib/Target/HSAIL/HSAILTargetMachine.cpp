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

// Hack to prevent weird standard OS directives from being printed when the
// triple is not fully specified. e.g. on a OS X host, there is no other way to
// disable printing .macosx_version_min at the start of the module.
static std::string getTripleNoOS(StringRef Str) {
  Triple TT(Str);

  if (TT.getOS() == Triple::UnknownOS)
    return Str;

  TT.setOS(Triple::UnknownOS);
  return TT.str();
}

HSAILTargetMachine::HSAILTargetMachine(const Target &T, StringRef TT,
                                       StringRef CPU, StringRef FS,
                                       const TargetOptions &Options,
                                       Reloc::Model RM, CodeModel::Model CM,
                                       CodeGenOpt::Level OL)
    : LLVMTargetMachine(T, getTripleNoOS(TT), CPU, FS, Options, RM, CM, OL),
      Subtarget(TT, CPU, FS, *this), IntrinsicInfo(this),
      TLOF(createTLOF(Triple(getTargetTriple()))) {
  initAsmInfo();
  setAsmVerbosityDefault(true);

#if HSAIL_USE_LIBHSAIL
  // FIXME: Hack to enable command line switch to switch between
  // BRIGAsmPrinter and HSAILAsmPrinter. Override the default registered
  // AsmPrinter to use the BRIGAsmPrinter.
  if (!UseStandardAsmPrinter)
    LLVMInitializeBRIGAsmPrinter();
#endif
}

bool HSAILTargetMachine::addPassesToEmitFile(
    PassManagerBase &PM, formatted_raw_ostream &Out, CodeGenFileType FT,
    bool DisableVerify, AnalysisID StartAfter, AnalysisID StopAfter) {
  HSAILFileType = FT; // FIXME: Remove this.

  if (!UseStandardAsmPrinter) {
    // Use CGFT_ObjectFile regardless on the output format.
    // To process CGFT_AssemblyFile we will later disassemble generated BRIG.
    FT = CGFT_ObjectFile;
  }

  return LLVMTargetMachine::addPassesToEmitFile(PM, Out, FT, DisableVerify,
                                                StartAfter, StopAfter);
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
  addPass(createHSAILOptimizeMemoryOps(HSATM));
#if 0
  addPass(&DeadMachineInstructionElimID);
  if (EnableUniformOps) {
    addPass(createHSAILUniformOperations(HSATM));
  }
#endif

  return false;
}
bool HSAILPassConfig::addPreEmitPass() { return false; }
bool HSAILPassConfig::addPreRegAlloc() { return false; }
bool HSAILPassConfig::addPostRegAlloc() { return false; }

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
