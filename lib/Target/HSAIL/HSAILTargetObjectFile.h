//===-- HSAILELFObjectFile.h - HSAIL ELF Object Info ------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_HSAIL_HSAILELFTARGETOBJECTFILE_H
#define LLVM_LIB_TARGET_HSAIL_HSAILELFTARGETOBJECTFILE_H

#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"

namespace llvm {

class HSAILTargetObjectFile : public TargetLoweringObjectFile {
public:
  HSAILTargetObjectFile();
  void Initialize(MCContext &ctx, const TargetMachine &TM) override;

  MCSection *getSectionForConstant(const DataLayout &DL,
                                   SectionKind Kind,
                                   const Constant *C) const override {
    return ReadOnlySection;
  }

  MCSection *getExplicitSectionGlobal(const GlobalValue *GV,
                                      SectionKind Kind, Mangler &Mang,
                                      const TargetMachine &TM) const override {
    return DataSection;
  }

  MCSection *SelectSectionForGlobal(const GlobalValue *GV,
                                    SectionKind Kind, Mangler &Mang,
                                    const TargetMachine &TM) const override {
    return getDataSection();
  }
};

// FIXME: Do we really need both of these?
class BRIG32_DwarfTargetObjectFile : public TargetLoweringObjectFile {
public:
  BRIG32_DwarfTargetObjectFile(){};
  virtual ~BRIG32_DwarfTargetObjectFile();
};

class BRIG64_DwarfTargetObjectFile : public TargetLoweringObjectFile {
public:
  BRIG64_DwarfTargetObjectFile(){};
  virtual ~BRIG64_DwarfTargetObjectFile();
};

} // end namespace llvm

#endif
