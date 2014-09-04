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
#include "llvm/MC/MCAssembler.h"
#include "llvm/MC/MCELFObjectWriter.h"
#include "llvm/MC/MCFixupKindInfo.h"
#include "llvm/MC/MCSectionELF.h"
#include "llvm/Support/ELF.h"
//#if LLVM_VERSION >= 3316
#include "llvm/MC/MCAsmBackend.h"
#define ASM_BACKEND_CLASS MCAsmBackend

#include "llvm/Support/TargetRegistry.h"

//#else
//#include "llvm/Target/TargetAsmBackend.h"
//#define ASM_BACKEND_CLASS TargetAsmBackend
//#include "llvm/Target/TargetRegistry.h"
//#endif

using namespace llvm;

namespace {
class HSAILAsmBackend : public ASM_BACKEND_CLASS {
public:
  HSAILAsmBackend(const ASM_BACKEND_CLASS &T);

  //dirty hack to enable construction of old-style backend in LLVM3.0 environment
  HSAILAsmBackend(int dummy);

  unsigned
  getNumFixupKinds() const
  {
    assert(!"When do we hit this?");
    return 0;
  }

  /// createObjectWriter - Create a new MCObjectWriter instance for use by the
  /// assembler backend to emit the final object file.
  virtual MCObjectWriter*
  createObjectWriter(raw_ostream &OS) const;

  /// doesSectionRequireSymbols - Check whether the given section requires that
  /// all symbols (even temporaries) have symbol table entries.
  virtual bool
  doesSectionRequireSymbols(const MCSection &Section) const;

  /// isSectionAtomizable - Check whether the given section can be split into
  /// atoms.
  ///
  /// \see MCAssembler::isSymbolLinkerVisible().
  virtual bool
  isSectionAtomizable(const MCSection &Section) const;

  /// isVirtualSection - Check whether the given section is "virtual", that is
  /// has no actual object file contents.
  virtual bool
  isVirtualSection(const MCSection &Section) const;

  /// applyFixup - Apply the \arg Value for given \arg Fixup into the provided
  /// data fragment, at the offset specified by the fixup and following the
  /// fixup kind as appropriate.
  virtual void applyFixup(const MCFixup &Fixup,
                          char *Data,
                          unsigned DataSize,
                          uint64_t Value) const;

  /// mayNeedRelaxation - Check whether the given instruction may need
  /// relaxation.
  ///
  /// \arg Inst - The instruction to test.
  /// \arg Fixups - The actual fixups this instruction encoded to, for potential
  /// use by the target backend.
  virtual bool
  mayNeedRelaxation(const MCInst &Inst) const;

  /// fixupNeedsRelaxation - Target specific predicate for whether a given
  /// fixup requires the associated instruction to be relaxed.
  virtual bool fixupNeedsRelaxation(const MCFixup &Fixup,
                                    uint64_t Value,
                                    const MCInstFragment *DF,
                                    const MCAsmLayout &Layout) const;

  /// relaxInstruction - Relax the instruction in the given fragment to the next
  /// wider instruction.
  virtual void
  relaxInstruction(const MCInst &Inst, MCInst &Res) const;


  /// writeNopData - Write an (optimal) nop sequence of Count bytes to the given
  /// output. If the target cannot generate such a sequence, it should return an
  /// error.
  ///
  /// \return - True on success.
  virtual bool
  writeNopData(uint64_t Count, MCObjectWriter *OW) const;
};

class ELFHSAILAsmBackend : public HSAILAsmBackend {
public:
  Triple::OSType OSType;
  ELFHSAILAsmBackend(const ASM_BACKEND_CLASS &T, Triple::OSType _OSType)
    : HSAILAsmBackend(T), OSType(_OSType) {
    HasReliableSymbolDifference = true;
  }

  virtual bool doesSectionRequireSymbols(const MCSection &Section) const {
    const MCSectionELF &ES = static_cast<const MCSectionELF&>(Section);
    return ES.getFlags() & ELF::SHF_MERGE;
  }
};

class ELFHSAIL_32AsmBackend : public ELFHSAILAsmBackend {
public:
  ELFHSAIL_32AsmBackend(const ASM_BACKEND_CLASS &T, Triple::OSType OSType)
    : ELFHSAILAsmBackend(T, OSType) {}

  MCObjectWriter *createObjectWriter(raw_ostream &OS) const {
    return createELFObjectWriter(new HSAILELFObjectWriter(false, OSType,
                                                        ELF::EM_HSAIL, false),
                                 OS, /*IsLittleEndian*/ true);
  }
};

class ELFHSAIL_64AsmBackend : public ELFHSAILAsmBackend {
public:
  ELFHSAIL_64AsmBackend(const ASM_BACKEND_CLASS &T, Triple::OSType OSType)
    : ELFHSAILAsmBackend(T, OSType) {}

  MCObjectWriter *createObjectWriter(raw_ostream &OS) const {
    return createELFObjectWriter(new HSAILELFObjectWriter(true, OSType,
                                                        ELF::EM_HSAIL_64, false),
                                 OS, /*IsLittleEndian*/ true);
  }
};
} // end anonymous namespace

#endif // _HSAIL_ASM_BACKEND_H_
