//===-- HSAILELFObjectFile.cpp - HSAIL ELF Object Info --------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "HSAILELFTargetObjectFile.h"
using namespace llvm;

HSAIL32_DwarfTargetObjectFile::HSAIL32_DwarfTargetObjectFile(const HSAILTargetMachine &tm)
  : TM(tm) {}

/// getExplicitSectionGlobal - Targets should implement this method to assign
/// a section to globals with an explicit section specfied.  The
/// implementation of this method can assume that GV->hasSection() is true.
const MCSection*
HSAIL32_DwarfTargetObjectFile::getExplicitSectionGlobal(const GlobalValue *GV,
                                                SectionKind Kind,
                                                Mangler *Mang,
                                                const TargetMachine &TM) const
{
  assert(!"When do we hit this?");
  return NULL;
}

/// getSpecialCasedSectionGlobals - Allow the target to completely override
/// section assignment of a global.
const MCSection*
HSAIL32_DwarfTargetObjectFile::getSpecialCasedSectionGlobals(const GlobalValue *GV,
                                                     Mangler *Mang,
                                                     SectionKind Kind) const
{
  assert(!"When do we hit this?");
  return NULL;
}

/// getExprForDwarfGlobalReference - Return an MCExpr to use for a reference
/// to the specified global variable from exception handling information.
///
const MCExpr*
HSAIL32_DwarfTargetObjectFile::getExprForDwarfGlobalReference(const GlobalValue *GV,
                                                      Mangler *Mang,
                                                      MachineModuleInfo *MMI,
                                                      unsigned Encoding,
                                                      MCStreamer &Streamer) const
{
  assert(!"When do we hit this?");
  return NULL;
}

const MCExpr*
HSAIL32_DwarfTargetObjectFile::getExprForDwarfReference(const MCSymbol *Sym,
                                                Mangler *Mang,
                                                MachineModuleInfo *MMI,
                                                unsigned Encoding,
                                                MCStreamer &Streamer) const
{
  assert(!"When do we hit this?");
  return NULL;
}

unsigned
HSAIL32_DwarfTargetObjectFile::getPersonalityEncoding() const
{
  assert(!"When do we hit this?");
  return 0;
}

unsigned
HSAIL32_DwarfTargetObjectFile::getLSDAEncoding() const
{
  assert(!"When do we hit this?");
  return 0;
}

unsigned
HSAIL32_DwarfTargetObjectFile::getFDEEncoding() const
{
  assert(!"When do we hit this?");
  return 0;
}

unsigned
HSAIL32_DwarfTargetObjectFile::getTTypeEncoding() const
{
  assert(!"When do we hit this?");
  return 0;
}
#if 0
const MCSection*
HSAIL32_DwarfTargetObjectFile::SelectSectionForGlobal(const GlobalValue *GV,
                                              SectionKind Kind,
                                              Mangler *Mang,
                                              const TargetMachine &TM) const
{
  assert(!"When do we hit this?");
  return NULL;
}
#endif
HSAIL64_DwarfTargetObjectFile::HSAIL64_DwarfTargetObjectFile(const HSAILTargetMachine &tm)
  : TM(tm) {}

/// getExplicitSectionGlobal - Targets should implement this method to assign
/// a section to globals with an explicit section specfied.  The
/// implementation of this method can assume that GV->hasSection() is true.
const MCSection*
HSAIL64_DwarfTargetObjectFile::getExplicitSectionGlobal(const GlobalValue *GV,
                                                SectionKind Kind,
                                                Mangler *Mang,
                                                const TargetMachine &TM) const
{
  assert(!"When do we hit this?");
  return NULL;
}

/// getSpecialCasedSectionGlobals - Allow the target to completely override
/// section assignment of a global.
const MCSection*
HSAIL64_DwarfTargetObjectFile::getSpecialCasedSectionGlobals(const GlobalValue *GV,
                                                     Mangler *Mang,
                                                     SectionKind Kind) const
{
  assert(!"When do we hit this?");
  return NULL;
}

/// getExprForDwarfGlobalReference - Return an MCExpr to use for a reference
/// to the specified global variable from exception handling information.
///
const MCExpr*
HSAIL64_DwarfTargetObjectFile::getExprForDwarfGlobalReference(const GlobalValue *GV,
                                                      Mangler *Mang,
                                                      MachineModuleInfo *MMI,
                                                      unsigned Encoding,
                                                      MCStreamer &Streamer) const
{
  assert(!"When do we hit this?");
  return NULL;
}

const MCExpr*
HSAIL64_DwarfTargetObjectFile::getExprForDwarfReference(const MCSymbol *Sym,
                                                Mangler *Mang,
                                                MachineModuleInfo *MMI,
                                                unsigned Encoding,
                                                MCStreamer &Streamer) const
{
  assert(!"When do we hit this?");
  return NULL;
}

unsigned
HSAIL64_DwarfTargetObjectFile::getPersonalityEncoding() const
{
  assert(!"When do we hit this?");
  return 0;
}

unsigned
HSAIL64_DwarfTargetObjectFile::getLSDAEncoding() const
{
  assert(!"When do we hit this?");
  return 0;
}

unsigned
HSAIL64_DwarfTargetObjectFile::getFDEEncoding() const
{
  assert(!"When do we hit this?");
  return 0;
}

unsigned
HSAIL64_DwarfTargetObjectFile::getTTypeEncoding() const
{
  assert(!"When do we hit this?");
  return 0;
}

// TODO_HSA: Removed for 64-bit instr selection, revisit this item. 
#if 0
const MCSection*
HSAIL64_DwarfTargetObjectFile::SelectSectionForGlobal(const GlobalValue *GV,
                                              SectionKind Kind,
                                              Mangler *Mang,
                                              const TargetMachine &TM) const
{
  assert(!"When do we hit this?");
  return NULL;
}
#endif
