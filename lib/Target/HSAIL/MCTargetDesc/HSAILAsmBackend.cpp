//===-- HSAILAsmBackend.h - HSAIL Assembler Backend -------------*- C++ -*-===//
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

HSAILAsmBackend::HSAILAsmBackend(const Target &T) {}

/// createObjectWriter - Create a new MCObjectWriter instance for use by the
/// assembler backend to emit the final object file.
MCObjectWriter *HSAILAsmBackend::createObjectWriter(raw_pwrite_stream &OS) const {
  assert(!"When do we hit this?");
  return nullptr;
}

// pulled from x86asmbackend.cpp, used in ApplyFixup
//
static unsigned getFixupKindLog2Size(unsigned Kind) {
  switch (Kind) {
  default:
    llvm_unreachable("Invalid fixup kind!");
  case FK_PCRel_1:
  case FK_Data_1:
    return 0;
  case FK_PCRel_2:
  case FK_Data_2:
    return 1;
  case FK_PCRel_4:
  // case X86::reloc_riprel_4byte:
  // case X86::reloc_riprel_4byte_movq_load:
  // case X86::reloc_signed_4byte:
  // case X86::reloc_global_offset_table:
  case FK_Data_4:
    return 2;
  case FK_PCRel_8:
  case FK_Data_8:
    return 3;
  }
}

/// applyFixup - Apply the \arg Value for given \arg Fixup into the provided
/// data fragment, at the offset specified by the fixup and following the
/// fixup kind as appropriate.
void HSAILAsmBackend::applyFixup(const MCFixup &Fixup, char *Data,
                                 unsigned DataSize, uint64_t Value,
                                 bool IsPCRel) const {
  // pulled from x86asmbackend.cpp
  unsigned Size = 1 << getFixupKindLog2Size(Fixup.getKind());

  assert(Fixup.getOffset() + Size <= DataSize && "Invalid fixup offset!");

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
bool HSAILAsmBackend::mayNeedRelaxation(const MCInst &Inst) const {
  return false;
}

/// fixupNeedsRelaxation - Target specific predicate for whether a given
/// fixup requires the associated instruction to be relaxed.
bool HSAILAsmBackend::fixupNeedsRelaxation(const MCFixup &Fixup, uint64_t Value,
                                           const MCRelaxableFragment *DF,
                                           const MCAsmLayout &Layout) const {
  assert(!"When do we hit this?");
  return false;
}

/// relaxInstruction - Relax the instruction in the given fragment to the next
/// wider instruction.
void HSAILAsmBackend::relaxInstruction(const MCInst &Inst, MCInst &Res) const {
  assert(!"When do we hit this?");
}

/// writeNopData - Write an (optimal) nop sequence of Count bytes to the given
/// output. If the target cannot generate such a sequence, it should return an
/// error.
/// \return - True on success.
bool HSAILAsmBackend::writeNopData(uint64_t Count, MCObjectWriter *OW) const {
  return true;
}

MCAsmBackend *llvm::createHSAIL32AsmBackend(const Target &T,
                                            const MCRegisterInfo &MRI,
                                            const Triple &TT,
                                            StringRef CPU) {
  return new ELFHSAIL_32AsmBackend(T);
}

MCAsmBackend *llvm::createHSAIL64AsmBackend(const Target &T,
                                            const MCRegisterInfo &MRI,
                                            const Triple &TT,
                                            StringRef CPU) {
  return new ELFHSAIL_64AsmBackend(T);
}
