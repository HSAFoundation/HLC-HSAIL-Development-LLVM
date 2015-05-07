//===-- BRIGDwarfCompileUnit.h ----------------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef BRIG_DWARF_COMPILE_UNIT_HEADER
#define BRIG_DWARF_COMPILE_UNIT_HEADER

#include "../lib/CodeGen/AsmPrinter/DwarfCompileUnit.h"
#include "BRIGDwarfDebug.h"
#include "BRIGAsmPrinter.h"

namespace llvm {

class LLVM_LIBRARY_VISIBILITY BRIGDwarfCompileUnit : public CompileUnit {
protected:
  BRIGAsmPrinter *m_brigAP;
  BRIGDwarfDebug *m_brigDD;

  virtual void addGVLabelToBlock(DIEBlock *block, const DIGlobalVariable *GV);
  virtual void addDebugLocOffset(const DbgVariable *Var, DIE *VariableDie,
                                 unsigned int Offset);

public:
  BRIGDwarfCompileUnit(unsigned UID, DIE *D, DICompileUnit CU,
                       BRIGAsmPrinter *A, BRIGDwarfDebug *DW);
  virtual ~BRIGDwarfCompileUnit();

  virtual void addVariableAddress(DbgVariable *&DV, DIE *Die,
                                  MachineLocation Location);

  virtual void addString(DIE *Die, unsigned Attribute, const StringRef Str);

  virtual void addLabel(DIE *Die, unsigned Attribute, unsigned Form,
                        const MCSymbol *Label);

  virtual void addDelta(DIE *Die, unsigned Attribute, unsigned Form,
                        const MCSymbol *Hi, const MCSymbol *Lo);

  virtual void addBRIGDirectiveOffset(DIE *Die, unsigned Attribute,
                                      unsigned Form, uint64_t Integer);

  virtual void createGlobalVariableDIE(const MDNode *N);

  DIE *constructPGVariableDIE(DbgPGVariable *Var);

  static inline bool classof(const BRIGDwarfCompileUnit *BDCU) { return true; }

  static inline bool classof(const CompileUnit *CU) { return true; }

}; // class BRIGDwarfCompileUnit
} // namespace llvm

#endif // BRIG_DWARF_COMPILE_UNIT_HEADER
