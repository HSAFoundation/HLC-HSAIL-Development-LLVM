#ifndef MNEMONIC_MAPPER_EMITTER_H
#define MNEMONIC_MAPPER_EMITTER_H

#include "llvm/TableGen/TableGenBackend.h"
#include <map>
#include <vector>
#include <cassert>

namespace llvm {
  class RecordKeeper;

  class MnemonicMapperEmitter {
    RecordKeeper &Records;
  public:
    MnemonicMapperEmitter(RecordKeeper &R) : Records (R) {}

    void run(raw_ostream &o);

private:
    void EmitGetInstMnemonic(raw_ostream &o);
    void EmitGetRegisterName(raw_ostream &o);
  };
}
#endif  // MNEMONIC_MAPPER_EMITTER_H
