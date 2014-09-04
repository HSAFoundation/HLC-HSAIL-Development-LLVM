#ifndef BRIG_DWARF_STREAMER
#define BRIG_DWARF_STREAMER

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/MC/MCAssembler.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCObjectStreamer.h"
#include "llvm/MC/MCObjectWriter.h"
#include "llvm/MC/MCSectionELF.h"
#include "llvm/MC/MCELFStreamer.h"
#include "RawVectorOstream.h"


namespace llvm {

class BRIGDwarfStreamer : public MCELFStreamer {
private:
  RawVectorOstream* dwarfStream;

public:
  BRIGDwarfStreamer(MCContext &Context, MCAsmBackend &TAB,
                  RawVectorOstream &RVOS, MCCodeEmitter *Emitter);

  BRIGDwarfStreamer(MCContext &Context, MCAsmBackend &TAB,
                RawVectorOstream &RVOS, MCCodeEmitter *Emitter,
                MCAssembler *Assembler);

  virtual void InitSections();
  virtual void Finish();

  RawVectorOstream* getDwarfStream();

  //support for LLVM-style RTTI operations like dyn_cast
  inline static bool classof(const BRIGDwarfStreamer* ) { return true; }
  inline static bool classof(const MCStreamer* streamer) { return true; }
};


  MCStreamer* createBRIGDwarfStreamer(MCContext &Context, MCAsmBackend &MAB,
                                      RawVectorOstream &RVOS, MCCodeEmitter *CE,
                                      bool RelaxAll, bool NoExecStack);

} // namespace llvm

#endif
