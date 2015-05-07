//=== HSAILMCCodeEmitter.h - convert HSAIL code to machine code -*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the interface to convert HSAIL code to machine code.
//
//===----------------------------------------------------------------------===//

#ifndef HSAILMCCODEEMITTER_H
#define HSAILMCCODEEMITTER_H

#define DEBUG_TYPE "mccodeemitter"
#include "HSAIL.h"
#include "HSAILSubtarget.h"
#include "HSAILInstrInfo.h"
#include "llvm/MC/MCCodeEmitter.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
class HSAILMCCodeEmitter : public MCCodeEmitter {
  HSAILMCCodeEmitter(const HSAILMCCodeEmitter &); // DO NOT IMPLEMENT
  void operator=(const HSAILMCCodeEmitter &);     // DO NOT IMPLEMENT
  const MCInstrInfo &MCII;
  const MCRegisterInfo &MRI;
  MCContext &Ctx;

public:
  HSAILMCCodeEmitter(const MCInstrInfo &mcii, const MCRegisterInfo &mri,
                     MCContext &ctx)
      : MCII(mcii), MRI(mri), Ctx(ctx) {}

  ~HSAILMCCodeEmitter() {}

  void EmitByte(unsigned char C, unsigned &CurByte, raw_ostream &OS) const;

  void EmitConstant(uint64_t Val, unsigned Size, unsigned &CurByte,
                    raw_ostream &OS) const;

  void EmitImmediate(const MCOperand &Disp, unsigned ImmSize,
                     MCFixupKind FixupKind, unsigned &CurByte, raw_ostream &OS,
                     SmallVectorImpl<MCFixup> &Fixups, int ImmOffset = 0) const;

  void EmitRegModRMByte(const MCOperand &ModRMReg, unsigned RegOpcodeFld,
                        unsigned &CurByte, raw_ostream &OS) const;

  void EmitSIBByte(unsigned SS, unsigned Index, unsigned Base,
                   unsigned &CurByte, raw_ostream &OS) const;

  void EmitMemModRMByte(const MCInst &MI, unsigned Op, unsigned RegOpcodeField,
                        uint64_t TSFlags, unsigned &CurByte, raw_ostream &OS,
                        SmallVectorImpl<MCFixup> &Fixups) const;

  void EncodeInstruction(const MCInst &MI, raw_ostream &OS,
                         SmallVectorImpl<MCFixup> &Fixups,
                         const MCSubtargetInfo &STI) const override;
  void EmitSegmentOverridePrefix(uint64_t TSFlags, unsigned &CurByte,
                                 int MemOperand, const MCInst &MI,
                                 raw_ostream &OS) const;
};

} // end anonymous namespace

#endif
