//===-- HSAILMCTargetDesc.h - HSAIL Target Descriptions ---------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
/// \file
/// \brief Provides HSAIL specific target descriptions.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_HSAIL_MCTARGETDESC_HSAILMCTARGETDESC_H
#define LLVM_LIB_TARGET_HSAIL_MCTARGETDESC_HSAILMCTARGETDESC_H

#include "llvm/ADT/StringRef.h"

namespace llvm {
class MCAsmBackend;
class MCCodeEmitter;
class MCContext;
class MCInstrInfo;
class MCObjectWriter;
class MCRegisterInfo;
class MCSubtargetInfo;
class Target;
class raw_ostream;

extern Target TheHSAIL_32Target, TheHSAIL_64Target;

MCCodeEmitter *createHSAIL_32MCCodeEmitterForLLVM32(const MCInstrInfo &II,
                                                    const MCRegisterInfo &MRI,
                                                    const MCSubtargetInfo &STI,
                                                    MCContext &Ctx);

MCCodeEmitter *createHSAIL_64MCCodeEmitterForLLVM32(const MCInstrInfo &II,
                                                    const MCRegisterInfo &MRI,
                                                    const MCSubtargetInfo &STI,
                                                    MCContext &Ctx);

MCAsmBackend *createHSAIL_32AsmBackendForLLVM32(const Target &T,
                                                const MCRegisterInfo &MRI,
                                                StringRef TT, StringRef CPU);

MCAsmBackend *createHSAIL_64AsmBackendForLLVM32(const Target &T,
                                                const MCRegisterInfo &MRI,
                                                StringRef TT, StringRef CPU);

} // End llvm namespace

#define GET_REGINFO_ENUM
#include "HSAILGenRegisterInfo.inc"

#define GET_INSTRINFO_ENUM
#include "HSAILGenInstrInfo.inc"

#define GET_SUBTARGETINFO_ENUM
#include "HSAILGenSubtargetInfo.inc"

#endif
