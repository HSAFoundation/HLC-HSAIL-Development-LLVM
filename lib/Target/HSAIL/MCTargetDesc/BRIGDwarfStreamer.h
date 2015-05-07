//===-- BRIGDwarfStreamer.h -------------------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef BRIG_DWARF_STREAMER
#define BRIG_DWARF_STREAMER

#include "llvm/MC/MCELFStreamer.h"

namespace llvm {

class RawVectorOstream;

class BRIGDwarfStreamer : public MCELFStreamer {
private:
  RawVectorOstream *dwarfStream;

public:
  BRIGDwarfStreamer(MCContext &Context, MCAsmBackend &TAB,
                    RawVectorOstream &RVOS, MCCodeEmitter *Emitter);

  void InitSections(bool NoExecStack) override;
  void Finish();

  RawVectorOstream *getDwarfStream();

  // support for LLVM-style RTTI operations like dyn_cast
  inline static bool classof(const BRIGDwarfStreamer *) { return true; }
  inline static bool classof(const MCStreamer *streamer) { return true; }
};

MCStreamer *createBRIGDwarfStreamer(MCContext &Context, MCAsmBackend &MAB,
                                    RawVectorOstream &RVOS, MCCodeEmitter *CE,
                                    bool RelaxAll);

} // namespace llvm

#endif
