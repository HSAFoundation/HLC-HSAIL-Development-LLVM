//===-- HSAIL/HSAILMCCodeEmitter.cpp - Convert HSAIL code to machine code -===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the HSAILMCCodeEmitter class.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "mccodeemitter"
#include "HSAIL.h"
#include "HSAILInstrInfo.h"
#include "HSAILFixupKinds.h"
#include "HSAILMCCodeEmitter.h"
#include "llvm/MC/MCCodeEmitter.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/raw_ostream.h"
#include <cstdio>
using namespace llvm;

void
HSAILMCCodeEmitter::EmitByte(unsigned char C,
                             unsigned &CurByte,
                             raw_ostream &OS) const
{
  assert(!"When do we hit this?");
}

void
HSAILMCCodeEmitter::EmitConstant(uint64_t Val,
                                 unsigned Size,
                                 unsigned &CurByte,
                                 raw_ostream &OS) const
{
  assert(!"When do we hit this?");
}

void
HSAILMCCodeEmitter::EmitRegModRMByte(const MCOperand &ModRMReg,
                                     unsigned RegOpcodeFld,
                                     unsigned &CurByte,
                                     raw_ostream &OS) const
{
  assert(!"When do we hit this?");
}

void
HSAILMCCodeEmitter::EmitSIBByte(unsigned SS,
                                unsigned Index,
                                unsigned Base,
                                unsigned &CurByte,
                                raw_ostream &OS) const
{
  assert(!"When do we hit this?");
}


MCCodeEmitter*
llvm::createHSAIL_32MCCodeEmitter(const Target &,
                                  TargetMachine &TM,
                                  MCContext &Ctx)
{
  return new HSAILMCCodeEmitter(TM, Ctx, false);
}

namespace {
  class DummyMCCodeEmitter: public MCCodeEmitter {
private:
    DummyMCCodeEmitter(const DummyMCCodeEmitter &);   // DO NOT IMPLEMENT
    void operator=(const DummyMCCodeEmitter &);  // DO NOT IMPLEMENT
protected: // Can only create subclasses.
    DummyMCCodeEmitter();

    const MCInstrInfo     &m_ii;
    const MCSubtargetInfo &m_sti;
    MCContext             &m_ctx;

public:
    DummyMCCodeEmitter(const MCInstrInfo &II, const MCSubtargetInfo &STI, MCContext &Ctx)
                       : m_ii(II),  m_sti(STI), m_ctx(Ctx) {}
    DummyMCCodeEmitter(const MCInstrInfo &II, const MCRegisterInfo &MRI, 
                   const MCSubtargetInfo &STI, MCContext &Ctx)
                       : m_ii(II),  m_sti(STI), m_ctx(Ctx) {}

    virtual ~DummyMCCodeEmitter() {}

    /// EncodeInstruction - Encode the given \arg Inst to bytes on the output
    /// stream \arg OS.
    virtual void EncodeInstruction(const MCInst &Inst, raw_ostream &OS,
                                   SmallVectorImpl<MCFixup> &Fixups) const
    {
      printf("DummyMCCodeEmitter::EncodeInstruction called...\n");
    }
  };
}

MCCodeEmitter* 
llvm::createHSAIL_32MCCodeEmitterForLLVM32(const MCInstrInfo &II,
                                     const MCRegisterInfo &MRI,
                                     const MCSubtargetInfo &STI,
                                     MCContext &Ctx)
{
  return new DummyMCCodeEmitter(II, STI, Ctx);
}


MCCodeEmitter* 
llvm::createHSAIL_64MCCodeEmitterForLLVM32(const MCInstrInfo &II,
                                     const MCRegisterInfo &MRI,
                                     const MCSubtargetInfo &STI,
                                     MCContext &Ctx)
{
  return new DummyMCCodeEmitter(II, STI, Ctx);
}

MCCodeEmitter*
llvm::createHSAIL_64MCCodeEmitter(const Target &,
                                  TargetMachine &TM,
                                  MCContext &Ctx)
{
  return new HSAILMCCodeEmitter(TM, Ctx, true);
}

void
HSAILMCCodeEmitter::EmitImmediate(const MCOperand &DispOp,
                                  unsigned Size,
                                  MCFixupKind FixupKind,
                                  unsigned &CurByte,
                                  raw_ostream &OS,
                                  SmallVectorImpl<MCFixup> &Fixups,
                                  int ImmOffset) const
{
  assert(!"When do we hit this?");
}

void
HSAILMCCodeEmitter::EmitMemModRMByte(const MCInst &MI,
                                     unsigned Op,
                                     unsigned RegOpcodeField,
                                     uint64_t TSFlags,
                                     unsigned &CurByte,
                                     raw_ostream &OS,
                                     SmallVectorImpl<MCFixup> &Fixups) const
{
  assert(!"When do we hit this?");
}

/// EmitVEXOpcodePrefix - AVX instructions are encoded using a opcode prefix
/// called VEX.

/*
void
HSAILMCCodeEmitter::EmitVEXOpcodePrefix(uint64_t TSFlags,
                                        unsigned &CurByte,
                                        int MemOperand,
                                        const MCInst &MI,
                                        const TargetInstrDesc &Desc,
                                        raw_ostream &OS) const
{
  assert(!"When do we hit this?");
}
*/
/// EmitSegmentOverridePrefix - Emit segment override opcode prefix as needed
void
HSAILMCCodeEmitter::EmitSegmentOverridePrefix(uint64_t TSFlags,
                                              unsigned &CurByte,
                                              int MemOperand,
                                              const MCInst &MI,
                                              raw_ostream &OS) const
{
  assert(!"When do we hit this?");
}

/*
/// EmitOpcodePrefix - Emit all instruction prefixes prior to the opcode.
/// MemOperand is the operand # of the start of a memory operand if present.  If
/// Not present, it is -1.
void
HSAILMCCodeEmitter::EmitOpcodePrefix(uint64_t TSFlags,
                                     unsigned &CurByte,
                                     int MemOperand,
                                     const MCInst &MI,
                                     const TargetInstrDesc &Desc,
                                     raw_ostream &OS) const
{
  assert(!"When do we hit this?");
}

*/
void
HSAILMCCodeEmitter::EncodeInstruction(const MCInst &MI,
                                      raw_ostream &OS,
                                      SmallVectorImpl<MCFixup> &Fixups) const
{
  assert(!"When do we hit this?");
}
