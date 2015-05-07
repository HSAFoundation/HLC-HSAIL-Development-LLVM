//===-- HSAILAsmBackend.h - HSAIL Assembler Backend -------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#ifndef _HSAIL_ASM_BACKEND_H_
#define _HSAIL_ASM_BACKEND_H_

#include "HSAILELFObjectWriter.h"
#include "llvm/MC/MCAsmBackend.h"
#include "llvm/MC/MCSectionELF.h"

using namespace llvm;

namespace {
class HSAILAsmBackend : public MCAsmBackend {
public:
  HSAILAsmBackend(const Target &T);

  unsigned getNumFixupKinds() const override {
    assert(!"When do we hit this?");
    return 0;
  }

  MCObjectWriter *createObjectWriter(raw_pwrite_stream &OS) const override;

  void applyFixup(const MCFixup &Fixup, char *Data, unsigned DataSize,
                  uint64_t Value, bool IsPCRel) const override;

  bool mayNeedRelaxation(const MCInst &Inst) const override;

  bool fixupNeedsRelaxation(const MCFixup &Fixup, uint64_t Value,
                            const MCRelaxableFragment *DF,
                            const MCAsmLayout &Layout) const override;

  void relaxInstruction(const MCInst &Inst, MCInst &Res) const override;

  bool writeNopData(uint64_t Count, MCObjectWriter *OW) const override;
};

class ELFHSAILAsmBackend : public HSAILAsmBackend {
public:
  ELFHSAILAsmBackend(const Target &T) : HSAILAsmBackend(T) {}
};

class ELFHSAIL_32AsmBackend : public ELFHSAILAsmBackend {
public:
  ELFHSAIL_32AsmBackend(const Target &T) : ELFHSAILAsmBackend(T) {}

  MCObjectWriter *createObjectWriter(raw_pwrite_stream &OS) const override {
    return createELFObjectWriter(
        new HSAILELFObjectWriter(false, ELF::EM_HSAIL, false), OS,
        /*IsLittleEndian*/ true);
  }
};

class ELFHSAIL_64AsmBackend : public ELFHSAILAsmBackend {
public:
  ELFHSAIL_64AsmBackend(const Target &T) : ELFHSAILAsmBackend(T) {}

  MCObjectWriter *createObjectWriter(raw_pwrite_stream &OS) const override {
    return createELFObjectWriter(
        new HSAILELFObjectWriter(true, ELF::EM_HSAIL_64, false), OS,
        /*IsLittleEndian*/ true);
  }
};
} // end anonymous namespace

#endif // _HSAIL_ASM_BACKEND_H_
