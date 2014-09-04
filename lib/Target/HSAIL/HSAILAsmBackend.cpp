//===-- HSAILAsmBackend.h - HSAIL Assembler Backend -----------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "HSAIL.h"
#include "HSAILAsmBackend.h"
using namespace llvm;

HSAILAsmBackend::HSAILAsmBackend(const ASM_BACKEND_CLASS &T) {}

// hack to enable construction of old-style HSAILAsmBackend
HSAILAsmBackend::HSAILAsmBackend(int dummy) {}

/// createObjectWriter - Create a new MCObjectWriter instance for use by the
/// assembler backend to emit the final object file.
MCObjectWriter*
HSAILAsmBackend::createObjectWriter(raw_ostream &OS) const
{
  assert(!"When do we hit this?");
  return NULL;
}

/// doesSectionRequireSymbols - Check whether the given section requires that
/// all symbols (even temporaries) have symbol table entries.
bool
HSAILAsmBackend::doesSectionRequireSymbols(const MCSection &Section) const
{
  assert(!"When do we hit this?");
  return false;
}

/// isSectionAtomizable - Check whether the given section can be split into
/// atoms.
/// \see MCAssembler::isSymbolLinkerVisible().
bool
HSAILAsmBackend::isSectionAtomizable(const MCSection &Section) const
{
  assert(!"When do we hit this?");
  return false;
}

/// isVirtualSection - Check whether the given section is "virtual", that is
/// has no actual object file contents.
bool
HSAILAsmBackend::isVirtualSection(const MCSection &Section) const
{
  assert(!"When do we hit this?");
  return false;
}

// pulled from x86asmbackend.cpp, used in ApplyFixup
//
static unsigned getFixupKindLog2Size(unsigned Kind) {
  switch (Kind) {
  default: assert(0 && "invalid fixup kind!");
  case FK_PCRel_1:
  case FK_Data_1: return 0;
  case FK_PCRel_2:
  case FK_Data_2: return 1;
  case FK_PCRel_4:
  //case X86::reloc_riprel_4byte:
  //case X86::reloc_riprel_4byte_movq_load:
  //case X86::reloc_signed_4byte:
  //case X86::reloc_global_offset_table:
  case FK_Data_4: return 2;
  case FK_PCRel_8:
  case FK_Data_8: return 3;
  }
}

/// applyFixup - Apply the \arg Value for given \arg Fixup into the provided
/// data fragment, at the offset specified by the fixup and following the
/// fixup kind as appropriate.
void
HSAILAsmBackend::applyFixup(const MCFixup &Fixup,
                            char *Data,
                            unsigned DataSize,
                            uint64_t Value) const
{
#ifdef AMD_HSAIL_DEBUG_ENHANCED_LOGGING
    errs()<<"ApplyFixup called: kind="<<Fixup.getKind()<<", offset="<<Fixup.getOffset()<<", value="<<Value<<", datasize="<<DataSize<<"\n";
#endif // AMD_HSAIL_DEBUG_ENHANCED_LOGGING

    // pulled from x86asmbackend.cpp
    //
    unsigned Size = 1 << getFixupKindLog2Size(Fixup.getKind());

    assert(Fixup.getOffset() + Size <= DataSize &&
        "Invalid fixup offset!");

    // Check that uppper bits are either all zeros or all ones.
    // Specifically ignore overflow/underflow as long as the leakage is
    // limited to the lower bits. This is to remain compatible with
    // other assemblers.
    assert(isIntN(Size * 8 + 1, Value) &&
        "Value does not fit in the Fixup field");
    for (unsigned i = 0; i != Size; ++i)
        Data[Fixup.getOffset() + i] = uint8_t(Value >> (i * 8));
}

/// mayNeedRelaxation - Check whether the given instruction may need
/// relaxation.
/// \arg Inst - The instruction to test.
/// \arg Fixups - The actual fixups this instruction encoded to, for potential
/// use by the target backend.
bool
HSAILAsmBackend::mayNeedRelaxation(const MCInst &Inst) const
{
  assert(!"When do we hit this?");
  return false;
}

  /// fixupNeedsRelaxation - Target specific predicate for whether a given
  /// fixup requires the associated instruction to be relaxed.
bool
HSAILAsmBackend::fixupNeedsRelaxation(const MCFixup &Fixup,
                                      uint64_t Value,
                                      const MCInstFragment *DF,
                                      const MCAsmLayout &Layout) const {
  assert(!"When do we hit this?");
  return false;
}

/// relaxInstruction - Relax the instruction in the given fragment to the next
/// wider instruction.
void
HSAILAsmBackend::relaxInstruction(const MCInst &Inst, MCInst &Res) const
{
  assert(!"When do we hit this?");
}

/// writeNopData - Write an (optimal) nop sequence of Count bytes to the given
/// output. If the target cannot generate such a sequence, it should return an
/// error.
/// \return - True on success.
bool
HSAILAsmBackend::writeNopData(uint64_t Count, MCObjectWriter *OW) const
{
#ifdef AMD_HSAIL_DEBUG_ENHANCED_LOGGING
  if(Count) {
    errs()<<"Emitting "<<Count<<" nops..."<<"\n";
  }
#endif // AMD_HSAIL_DEBUG_ENHANCED_LOGGING
  return true;
}

ASM_BACKEND_CLASS*
llvm::createHSAIL_32AsmBackend(const ASM_BACKEND_CLASS &T,
                               const std::string &TT) {
  return new ELFHSAIL_32AsmBackend(T, Triple(TT).getOS());
}

ASM_BACKEND_CLASS *
llvm::createHSAIL_64AsmBackend(const ASM_BACKEND_CLASS &T,
                               const std::string &TT) {
  return new ELFHSAIL_64AsmBackend(T, Triple(TT).getOS());
}

MCAsmBackend* llvm::createHSAIL_32AsmBackendForLLVM32(const Target &T, StringRef TT, StringRef CPU)
{
  HSAILAsmBackend dummy(0);
  return new ELFHSAIL_32AsmBackend(dummy, Triple(TT).getOS());
}

MCAsmBackend* llvm::createHSAIL_64AsmBackendForLLVM32(const Target &T, StringRef TT, StringRef CPU)
{
  HSAILAsmBackend dummy(0);
  return new ELFHSAIL_64AsmBackend(dummy, Triple(TT).getOS());
}

