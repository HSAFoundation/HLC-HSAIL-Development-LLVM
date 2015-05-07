//===-- HSAILELFTargetObjectFile.cpp ----------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "HSAILELFTargetObjectFile.h"

using namespace llvm;


HSAILTargetObjectFile::HSAILTargetObjectFile() {
  TextSection = nullptr;
  DataSection = nullptr;
  BSSSection = nullptr;
  ReadOnlySection = nullptr;

  StaticCtorSection = nullptr;
  StaticDtorSection = nullptr;
  LSDASection = nullptr;
  EHFrameSection = nullptr;
  DwarfAbbrevSection = nullptr;
  DwarfInfoSection = nullptr;
  DwarfLineSection = nullptr;
  DwarfFrameSection = nullptr;
  DwarfPubTypesSection = nullptr;
  DwarfDebugInlineSection = nullptr;
  DwarfStrSection = nullptr;
  DwarfLocSection = nullptr;
  DwarfARangesSection = nullptr;
  DwarfRangesSection = nullptr;
}

void HSAILTargetObjectFile::Initialize(MCContext &ctx,
                                       const TargetMachine &TM) {
  TargetLoweringObjectFile::Initialize(ctx, TM);

  TextSection = new HSAILSection(MCSection::SV_ELF, SectionKind::getText());
  DataSection =
    new HSAILSection(MCSection::SV_ELF, SectionKind::getDataRel());
  BSSSection = new HSAILSection(MCSection::SV_ELF, SectionKind::getBSS());
  ReadOnlySection =
    new HSAILSection(MCSection::SV_ELF, SectionKind::getReadOnly());

  StaticCtorSection =
    new HSAILSection(MCSection::SV_ELF, SectionKind::getMetadata());
  StaticDtorSection =
    new HSAILSection(MCSection::SV_ELF, SectionKind::getMetadata());
  LSDASection =
    new HSAILSection(MCSection::SV_ELF, SectionKind::getMetadata());
  EHFrameSection =
    new HSAILSection(MCSection::SV_ELF, SectionKind::getMetadata());
  DwarfAbbrevSection =
    new HSAILSection(MCSection::SV_ELF, SectionKind::getMetadata());
  DwarfInfoSection =
    new HSAILSection(MCSection::SV_ELF, SectionKind::getMetadata());
  DwarfLineSection =
    new HSAILSection(MCSection::SV_ELF, SectionKind::getMetadata());
  DwarfFrameSection =
    new HSAILSection(MCSection::SV_ELF, SectionKind::getMetadata());
  DwarfPubTypesSection =
    new HSAILSection(MCSection::SV_ELF, SectionKind::getMetadata());
  DwarfDebugInlineSection =
    new HSAILSection(MCSection::SV_ELF, SectionKind::getMetadata());
  DwarfStrSection =
    new HSAILSection(MCSection::SV_ELF, SectionKind::getMetadata());
  DwarfLocSection =
    new HSAILSection(MCSection::SV_ELF, SectionKind::getMetadata());
  DwarfARangesSection =
    new HSAILSection(MCSection::SV_ELF, SectionKind::getMetadata());
  DwarfRangesSection =
    new HSAILSection(MCSection::SV_ELF, SectionKind::getMetadata());
}

BRIG32_DwarfTargetObjectFile::~BRIG32_DwarfTargetObjectFile() {

}

BRIG64_DwarfTargetObjectFile::~BRIG64_DwarfTargetObjectFile() {

}
