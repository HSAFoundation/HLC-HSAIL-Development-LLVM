//===- HSAILSection.h - HSAIL-specific section representation -*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file declares the HSAILSection class.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_HSAIL_HSAILSECTION_H
#define LLVM_LIB_TARGET_HSAIL_HSAILSECTION_H

#include "llvm/MC/MCSection.h"

namespace llvm {

// HSAIL does not have sections. Override this so we don't get unwanted .text
// labels emitted.
class HSAILSection : public MCSection {
public:
  HSAILSection(SectionVariant V, SectionKind K) : MCSection(V, K, nullptr) {}
  virtual ~HSAILSection();

  void PrintSwitchToSection(const MCAsmInfo &MAI,
                            raw_ostream &OS,
                            const MCExpr *Subsection) const override;

  bool UseCodeAlign() const override {
    return false;
  }

  bool isVirtualSection() const override {
    return false;
  }
};

} // end namespace llvm

#endif
