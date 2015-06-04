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

#include "HSAILMCCodeEmitter.h"

using namespace llvm;

void HSAILMCCodeEmitter::EmitByte(unsigned char C, unsigned &CurByte,
                                  raw_ostream &OS) const {
  llvm_unreachable("When do we hit this?");
}

void HSAILMCCodeEmitter::EmitConstant(uint64_t Val, unsigned Size,
                                      unsigned &CurByte,
                                      raw_ostream &OS) const {
  llvm_unreachable("When do we hit this?");
}

void HSAILMCCodeEmitter::EmitRegModRMByte(const MCOperand &ModRMReg,
                                          unsigned RegOpcodeFld,
                                          unsigned &CurByte,
                                          raw_ostream &OS) const {
  llvm_unreachable("When do we hit this?");
}

void HSAILMCCodeEmitter::EmitSIBByte(unsigned SS, unsigned Index, unsigned Base,
                                     unsigned &CurByte, raw_ostream &OS) const {
  llvm_unreachable("When do we hit this?");
}

namespace {
class DummyMCCodeEmitter : public MCCodeEmitter {
private:
  DummyMCCodeEmitter(const DummyMCCodeEmitter &); // DO NOT IMPLEMENT
  void operator=(const DummyMCCodeEmitter &);     // DO NOT IMPLEMENT
protected:                                        // Can only create subclasses.
  DummyMCCodeEmitter();

  const MCInstrInfo &m_ii;
  const MCSubtargetInfo &m_sti;
  MCContext &m_ctx;

public:
  DummyMCCodeEmitter(const MCInstrInfo &II, const MCSubtargetInfo &STI,
                     MCContext &Ctx)
      : m_ii(II), m_sti(STI), m_ctx(Ctx) {}
  DummyMCCodeEmitter(const MCInstrInfo &II, const MCRegisterInfo &MRI,
                     const MCSubtargetInfo &STI, MCContext &Ctx)
      : m_ii(II), m_sti(STI), m_ctx(Ctx) {}

  ~DummyMCCodeEmitter() override {}

  void encodeInstruction(const MCInst &Inst, raw_ostream &OS,
                         SmallVectorImpl<MCFixup> &Fixups,
                         const MCSubtargetInfo &STI) const override {
    llvm_unreachable("DummyMCCodeEmitter::EncodeInstruction called...");
  }
};
}

MCCodeEmitter *llvm::createHSAILMCCodeEmitter(const MCInstrInfo &MCII,
                                              const MCRegisterInfo &MRI,
                                              MCContext &Ctx) {
  return new HSAILMCCodeEmitter(MCII, MRI, Ctx);
}

void HSAILMCCodeEmitter::EmitImmediate(const MCOperand &DispOp, unsigned Size,
                                       MCFixupKind FixupKind, unsigned &CurByte,
                                       raw_ostream &OS,
                                       SmallVectorImpl<MCFixup> &Fixups,
                                       int ImmOffset) const {
  llvm_unreachable("When do we hit this?");
}

void HSAILMCCodeEmitter::EmitMemModRMByte(
    const MCInst &MI, unsigned Op, unsigned RegOpcodeField, uint64_t TSFlags,
    unsigned &CurByte, raw_ostream &OS,
    SmallVectorImpl<MCFixup> &Fixups) const {
  llvm_unreachable("When do we hit this?");
}

void HSAILMCCodeEmitter::EmitSegmentOverridePrefix(uint64_t TSFlags,
                                                   unsigned &CurByte,
                                                   int MemOperand,
                                                   const MCInst &MI,
                                                   raw_ostream &OS) const {
  llvm_unreachable("When do we hit this?");
}

void HSAILMCCodeEmitter::encodeInstruction(const MCInst &MI, raw_ostream &OS,
                                           SmallVectorImpl<MCFixup> &Fixups,
                                           const MCSubtargetInfo &STI) const {
  llvm_unreachable("When do we hit this?");
}
