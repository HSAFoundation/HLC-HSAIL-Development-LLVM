//===-- HSAILELFObjectFile.h - HSAIL ELF Object Info ------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef _HSAIL_ELF_OBJECT_FILE_H_
#define _HSAIL_ELF_OBJECT_FILE_H_

#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetLoweringObjectFile.h"

namespace llvm {
class HSAILTargetMachine;

class HSAIL32_DwarfTargetObjectFile : public TargetLoweringObjectFileELF {
  const HSAILTargetMachine &TM;
public:
  HSAIL32_DwarfTargetObjectFile(const HSAILTargetMachine &tm);

  /// getExplicitSectionGlobal - Targets should implement this method to assign
  /// a section to globals with an explicit section specfied.  The
  /// implementation of this method can assume that GV->hasSection() is true.
  virtual const MCSection*
  getExplicitSectionGlobal(const GlobalValue *GV,
                           SectionKind Kind,
                           Mangler *Mang,
                           const TargetMachine &TM) const;

  /// getSpecialCasedSectionGlobals - Allow the target to completely override
  /// section assignment of a global.
  virtual const MCSection*
  getSpecialCasedSectionGlobals(const GlobalValue *GV,
                                Mangler *Mang,
                                SectionKind Kind) const;

  /// getExprForDwarfGlobalReference - Return an MCExpr to use for a reference
  /// to the specified global variable from exception handling information.
  ///
  virtual const MCExpr*
  getExprForDwarfGlobalReference(const GlobalValue *GV,
                                 Mangler *Mang,
                                 MachineModuleInfo *MMI,
                                 unsigned Encoding,
                                 MCStreamer &Streamer) const;

  const MCExpr*
  getExprForDwarfReference(const MCSymbol *Sym,
                           Mangler *Mang,
                           MachineModuleInfo *MMI,
                           unsigned Encoding,
                           MCStreamer &Streamer) const;

  virtual unsigned
  getPersonalityEncoding() const;

  virtual unsigned
  getLSDAEncoding() const;

  virtual unsigned
  getFDEEncoding() const;

  virtual unsigned
  getTTypeEncoding() const;
#if 0
  virtual const MCSection*
  SelectSectionForGlobal(const GlobalValue *GV,
                         SectionKind Kind,
                         Mangler *Mang,
                         const TargetMachine &TM) const;
#endif
};

class HSAIL64_DwarfTargetObjectFile : public TargetLoweringObjectFileELF {
  const HSAILTargetMachine &TM;
public:
  HSAIL64_DwarfTargetObjectFile(const HSAILTargetMachine &tm);

  /// getExplicitSectionGlobal - Targets should implement this method to assign
  /// a section to globals with an explicit section specfied.  The
  /// implementation of this method can assume that GV->hasSection() is true.
  virtual const MCSection*
  getExplicitSectionGlobal(const GlobalValue *GV,
                           SectionKind Kind,
                           Mangler *Mang,
                           const TargetMachine &TM) const;

  /// getSpecialCasedSectionGlobals - Allow the target to completely override
  /// section assignment of a global.
  virtual const MCSection*
  getSpecialCasedSectionGlobals(const GlobalValue *GV,
                                Mangler *Mang,
                                SectionKind Kind) const;

  /// getExprForDwarfGlobalReference - Return an MCExpr to use for a reference
  /// to the specified global variable from exception handling information.
  ///
  virtual const MCExpr*
  getExprForDwarfGlobalReference(const GlobalValue *GV,
                                 Mangler *Mang,
                                 MachineModuleInfo *MMI,
                                 unsigned Encoding,
                                 MCStreamer &Streamer) const;

  const MCExpr*
  getExprForDwarfReference(const MCSymbol *Sym,
                           Mangler *Mang,
                           MachineModuleInfo *MMI,
                           unsigned Encoding,
                           MCStreamer &Streamer) const;

  virtual unsigned
  getPersonalityEncoding() const;

  virtual unsigned
  getLSDAEncoding() const;

  virtual unsigned
  getFDEEncoding() const;

  virtual unsigned
  getTTypeEncoding() const;

#if 0
  virtual const MCSection*
  SelectSectionForGlobal(const GlobalValue *GV,
                         SectionKind Kind,
                         Mangler *Mang,
                         const TargetMachine &TM) const;
#endif
};

} // end namespace llvm

#endif // _HSAIL_ELF_OBJECT_FILE_H_
