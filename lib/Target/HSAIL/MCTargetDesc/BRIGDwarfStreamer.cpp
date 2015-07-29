//===-- BRIGDwarfStreamer.cpp ---------------------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "BRIGDwarfStreamer.h"

using namespace llvm;

BRIGDwarfStreamer::BRIGDwarfStreamer(MCContext &Context, MCAsmBackend &TAB,
                                     RawVectorOstream &RVOS,
                                     MCCodeEmitter *Emitter)
    : MCELFStreamer(Context, TAB, RVOS, Emitter), dwarfStream(&RVOS) {}

BRIGDwarfStreamer::BRIGDwarfStreamer(MCContext &Context, MCAsmBackend &TAB,
                                     RawVectorOstream &RVOS,
                                     MCCodeEmitter *Emitter,
                                     MCAssembler *Assembler)
    : MCELFStreamer(Context, TAB, RVOS, Emitter, Assembler),
      dwarfStream(&RVOS) {}

RawVectorOstream *BRIGDwarfStreamer::getDwarfStream() {
  raw_ostream *strm = &(getAssembler().getWriter().getStream());
  // we must ensure MC layer is writing to the same stream
  assert(strm == static_cast<raw_ostream *>(dwarfStream) &&
         "MC layer doesn't write to DWARF stream");
  return dwarfStream;
}

void BRIGDwarfStreamer::InitSections(bool NoExecStack) {
  const MCSectionELF *codeSection = getContext().getELFSection(
      ".brigcode", ELF::SHT_NOBITS, 0, SectionKind::getText());
  const MCSectionELF *directivesSection = getContext().getELFSection(
      ".brigdirectives", ELF::SHT_NOBITS, 0, SectionKind::getDataRel());
  SwitchSection(codeSection);
  SwitchSection(directivesSection);
  SwitchSection(codeSection);
}

#if 0
MCStreamer::MCStreamerKind BRIGDwarfStreamer::getStreamerKind() const {
  return MCStreamer::BRIGDwarfStreamer;
}
#endif

void BRIGDwarfStreamer::Finish() {
  MCELFStreamer::Finish();
  // flush all DWARF data captured
  dwarfStream->flush();
  // stop writing to another stream, if any provided
  dwarfStream->releaseStream();
}

MCStreamer *llvm::createBRIGDwarfStreamer(MCContext &Context, MCAsmBackend &MAB,
                                          RawVectorOstream &RVOS,
                                          MCCodeEmitter *CE, bool RelaxAll) {
  BRIGDwarfStreamer *S = new BRIGDwarfStreamer(Context, MAB, RVOS, CE);
  if (RelaxAll)
    S->getAssembler().setRelaxAll(true);
  return S;
}
