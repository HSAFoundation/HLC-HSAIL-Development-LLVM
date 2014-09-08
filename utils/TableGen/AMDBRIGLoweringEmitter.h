
#ifndef BRIG_LOWERING_EMITTER_H
#define BRIG_LOWERING_EMITTER_H

#include "llvm/TableGen/TableGenBackend.h"
#include <map>
#include <vector>
#include <cassert>

namespace llvm {
  class AsmWriterInst;
  class CodeGenInstruction;
  class Record;
  class RecordKeeper;
  
  class BRIGLoweringEmitter {
    RecordKeeper &Records;
    std::map<const CodeGenInstruction*, AsmWriterInst*> CGIAWIMap;
    std::map<std::string, std::vector<unsigned> > BrigOperands;
    std::vector<const CodeGenInstruction*> NumberedInstructions;
  public:
    BRIGLoweringEmitter(RecordKeeper &R) : Records (R) {}

    // run - Output the asmwriter, returning true on failure.
    void run(raw_ostream &o);

private:
    void EmitPrintInstruction(raw_ostream &o);
    void EmitGetRegisterName(raw_ostream &o);
    void EmitGetInstructionName(raw_ostream &o);
    //void EmitRegIsInRegClass(raw_ostream &O);
    //void EmitPrintAliasInstruction(raw_ostream &O);
    
    AsmWriterInst *getAsmWriterInstByID(unsigned ID) const {
      assert(ID < NumberedInstructions.size());
      std::map<const CodeGenInstruction*, AsmWriterInst*>::const_iterator I =
        CGIAWIMap.find(NumberedInstructions[ID]);
      assert(I != CGIAWIMap.end() && "Didn't find inst!");
      return I->second;
    }
    void FindUniqueOperandCommands(std::vector<std::string> &UOC,
                                   std::vector<unsigned> &InstIdxs,
                                   std::vector<unsigned> &InstOpsUsed) const;
   // bool m_genBrig;
  };
}
#endif  // BRIG_LOWERING_EMITTER_H
