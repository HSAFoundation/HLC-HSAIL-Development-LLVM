//===-- HSAILMCTargetDesc.cpp - HSAIL Target Descriptions ----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
/// \file
/// \brief This file provides HSAIL specific target descriptions.
//
//===----------------------------------------------------------------------===//

#include "HSAILMCTargetDesc.h"
#include "HSAILMCAsmInfo.h"
#include "HSAILMCCodeEmitter.h"
#include "InstPrinter/HSAILInstPrinter.h"
#include "llvm/MC/MCCodeGenInfo.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/TargetRegistry.h"

#include "HSAILTargetStreamer.h"

#include "BRIGDwarfStreamer.h"
#include "RawVectorOstream.h"

using namespace llvm;

#define GET_INSTRINFO_MC_DESC
#include "HSAILGenInstrInfo.inc"

#define GET_SUBTARGETINFO_MC_DESC
#include "HSAILGenSubtargetInfo.inc"

#define GET_REGINFO_MC_DESC
#include "HSAILGenRegisterInfo.inc"

// MC related code probably should be in MCTargetDesc subdir
static MCCodeGenInfo *createHSAILMCCodeGenInfo(const Triple &TT, Reloc::Model RM,
                                               CodeModel::Model CM,
                                               CodeGenOpt::Level OL) {
  MCCodeGenInfo *X = new MCCodeGenInfo();
  X->initMCCodeGenInfo(RM, CM, OL);
  return X;
}

static MCInstrInfo *createHSAILMCInstrInfo() {
  MCInstrInfo *X = new MCInstrInfo();
  InitHSAILMCInstrInfo(X);
  return X;
}

static MCRegisterInfo *createHSAILMCRegisterInfo(const Triple &TT) {
  MCRegisterInfo *X = new MCRegisterInfo();
  InitHSAILMCRegisterInfo(X, 0);
  return X;
}

static MCSubtargetInfo *createHSAILMCSubtargetInfo(const Triple &TT, StringRef CPU,
                                                   StringRef FS) {
  return createHSAILMCSubtargetInfoImpl(TT, CPU, FS);
}

#if 1
static MCStreamer *createBRIGStreamer(const Triple &T, MCContext &Ctx,
                                      MCAsmBackend &TAB,
                                      raw_pwrite_stream &OS,
                                      MCCodeEmitter *Emitter,
                                      bool RelaxAll) {
  // pass 0 instead of &_OS, if you do not want DWARF data to be forwarded to
  // the provided stream
  // this stream will be deleted in the destructor of BRIGAsmPrinter
  RawVectorOstream *RVOS = new RawVectorOstream(&OS);

  return createBRIGDwarfStreamer(Ctx, TAB, *RVOS, Emitter, RelaxAll);
}
#else
static MCStreamer *createBRIGStreamer(MCStreamer &S,
                                      const MCSubtargetInfo &STI) {
  // pass 0 instead of &_OS, if you do not want DWARF data to be forwarded to
  // the provided stream
  // this stream will be deleted in the destructor of BRIGAsmPrinter
  RawVectorOstream *RVOS = new RawVectorOstream(&OS);

  return createBRIGDwarfStreamer(Ctx, TAB, *RVOS, Emitter, RelaxAll);
}

#endif


MCTargetStreamer *
createHSAILObjectTargetStreamer(MCStreamer &S, const MCSubtargetInfo &STI) {
  return new HSAILTargetStreamer(S);
}

static MCInstPrinter *createHSAILMCInstPrinter(const Triple &TT,
                                               unsigned SyntaxVariant,
                                               const MCAsmInfo &MAI,
                                               const MCInstrInfo &MII,
                                               const MCRegisterInfo &MRI) {
  return new HSAILInstPrinter(MAI, MII, MRI);
}

extern "C" void LLVMInitializeHSAILTargetMC() {
  for (Target *T : { &TheHSAIL_32Target, &TheHSAIL_64Target }) {
    RegisterMCAsmInfo<HSAILELFMCAsmInfo> X(*T);

    TargetRegistry::RegisterMCCodeGenInfo(*T, createHSAILMCCodeGenInfo);
    TargetRegistry::RegisterMCInstrInfo(*T, createHSAILMCInstrInfo);
    TargetRegistry::RegisterMCRegInfo(*T, createHSAILMCRegisterInfo);
    TargetRegistry::RegisterMCSubtargetInfo(*T, createHSAILMCSubtargetInfo);
    TargetRegistry::RegisterMCInstPrinter(*T, createHSAILMCInstPrinter);
    TargetRegistry::RegisterMCCodeEmitter(*T, createHSAILMCCodeEmitter);
    TargetRegistry::RegisterELFStreamer(*T, createBRIGStreamer);
//    TargetRegistry::RegisterObjectTargetStreamer(*T, createHSAILObjectTargetStreamer);
  }

  TargetRegistry::RegisterMCAsmBackend(TheHSAIL_32Target,
                                       createHSAIL32AsmBackend);
  TargetRegistry::RegisterMCAsmBackend(TheHSAIL_64Target,
                                       createHSAIL64AsmBackend);
}
