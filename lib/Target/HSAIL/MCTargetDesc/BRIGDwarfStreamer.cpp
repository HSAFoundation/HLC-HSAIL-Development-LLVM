//===-- BRIGDwarfStreamer.cpp ---------------------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "BRIGDwarfStreamer.h"

#include "RawVectorOstream.h"

#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCSectionELF.h"


using namespace llvm;

BRIGDwarfStreamer::BRIGDwarfStreamer(MCContext &Context, MCAsmBackend &TAB,
                                     RawVectorOstream &RVOS,
                                     MCCodeEmitter *Emitter)
    : MCELFStreamer(Context, TAB, RVOS, Emitter),
      dwarfStream(&RVOS) {}

RawVectorOstream *BRIGDwarfStreamer::getDwarfStream() {
  raw_ostream &Strm = getAssembler().getWriter().getStream();

  // We must ensure MC layer is writing to the same stream.
  assert(&Strm == static_cast<raw_ostream *>(dwarfStream) &&
         "MC layer doesn't write to DWARF stream");
  return dwarfStream;
}

void BRIGDwarfStreamer::InitSections(bool NoExecStack) {
  const MCSectionELF *codeSection = getContext().getELFSection(
      ".brigcode", ELF::SHT_NOBITS, 0);
  const MCSectionELF *directivesSection = getContext().getELFSection(
      ".brigdirectives", ELF::SHT_NOBITS, 0);
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
