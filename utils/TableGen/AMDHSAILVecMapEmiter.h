//===- HSAILVecMapEmiter.h - Generate an assembly writer ---------*- C++ -*-===//
//
// This tablegen backend is responsible for emitting map between 
// scalar and vector load and store instructions in HSAIL
//
// TODO_HSA: Once we have InstrMappings in llvm 
// remove this and use core llvm functionality instead
//
//===----------------------------------------------------------------------===//

#ifndef HSAIL_VEC_MAP_EMITER_H
#define HSAIL_VEC_MAP_EMITER_H

#include <map>
#include <vector>

#include "llvm/TableGen/TableGenBackend.h"

namespace llvm {
  class CodeGenInstruction;
  class RecordKeeper;
  class Record;
  
  class HSAILVecMapEmiter  {
  public:
    HSAILVecMapEmiter(RecordKeeper &R) : Records(R) 
    {
      buildVecMap();
    }

    Record *getVectorRec(Record *Src, int VecSize);

    void run(raw_ostream &o);
  
  private:
    // Build VecInstMap
    void buildVecMap();

    std::string getBaseName(Record *rec);

  private:    
    // Maps BaseOpcode into all instructions with same BaseOpcode
    // e.g ld_addr32 -> [ld_addr32, ld_v2_addr32, ld_v4_addr32]
    typedef std::map<std::string, std::vector<Record*> > VecInstMapType;
    VecInstMapType VecInstMap;

    RecordKeeper &Records;
  };
}
#endif // HSAIL_VEC_MAP_EMITER_H
