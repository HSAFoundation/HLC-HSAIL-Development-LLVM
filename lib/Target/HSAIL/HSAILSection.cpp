//===- HSAILSection.cpp -----------------------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "HSAILSection.h"

using namespace llvm;


void HSAILSection::PrintSwitchToSection(const MCAsmInfo &MAI,
                                        raw_ostream &OS,
                                        const MCExpr *Subsection) const {
  // Do nothing. There are no sections
}

HSAILSection::~HSAILSection() {

}
