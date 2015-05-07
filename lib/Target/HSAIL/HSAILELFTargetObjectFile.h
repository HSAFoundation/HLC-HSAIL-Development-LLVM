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

#include "HSAILSection.h"

#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"

namespace llvm {

class HSAILTargetObjectFile : public TargetLoweringObjectFileELF {
public:
  HSAILTargetObjectFile();
  void Initialize(MCContext &ctx, const TargetMachine &TM) override;

  const MCSection *getSectionForConstant(SectionKind Kind,
                                         const Constant *C) const override {
    return ReadOnlySection;
  }

  const MCSection *
  getExplicitSectionGlobal(const GlobalValue *GV,
                           SectionKind Kind, Mangler &Mang,
                           const TargetMachine &TM) const override {
    return DataSection;
  }

  const MCSection *
  SelectSectionForGlobal(const GlobalValue *GV,
                         SectionKind Kind, Mangler &Mang,
                         const TargetMachine &TM) const override {
    return getDataSection();
  }
};

// FIXME: Do we really need both of these?
class BRIG32_DwarfTargetObjectFile : public TargetLoweringObjectFileELF {
public:
  BRIG32_DwarfTargetObjectFile(){};
  virtual ~BRIG32_DwarfTargetObjectFile();
};

class BRIG64_DwarfTargetObjectFile : public TargetLoweringObjectFileELF {
public:
  BRIG64_DwarfTargetObjectFile(){};
  virtual ~BRIG64_DwarfTargetObjectFile();
};

} // end namespace llvm

#endif // _HSAIL_ELF_OBJECT_FILE_H_
