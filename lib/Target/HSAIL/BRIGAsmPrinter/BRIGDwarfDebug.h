//===-- BRIGDwarfDebug.h ----------------------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef BRIG_DWARF_DEBUG_HEADER
#define BRIG_DWARF_DEBUG_HEADER

#define BRIG_DWARF_DEMANGLE_PRIVATE_VARIABLES

#include "../lib/CodeGen/AsmPrinter/DwarfDebug.h"
#include "llvm/CodeGen/LexicalScopes.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/IR/DebugInfo.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/GlobalVariable.h"
#include "BRIGAsmPrinter.h"

namespace llvm {

// class that provides access to the fields of metadata node describing BRIG
// private or global variables
class DIPGVariable : public DIGlobalVariable {
public:
  const HSAILAS::AddressSpaces addrSpace;

  explicit DIPGVariable(const MDNode *N, HSAILAS::AddressSpaces addressSpace)
      : DIGlobalVariable(N), addrSpace(addressSpace) {}

  bool Verify() const {
    if (DIGlobalVariable::Verify()) {
      const GlobalVariable *GV = getGlobal();
      /* address spaces should be the same */
      return GV && GV->getType() &&
             GV->getType()->getAddressSpace() ==
                 static_cast<unsigned int>(addrSpace);
    }
    return false;
  }
};

class DbgPGVariable {
  DIPGVariable Var;           // Variable Descriptor.
  DIE *TheDIE;                // Variable DIE.
  unsigned DotDebugLocOffset; // Offset in DotDebugLocEntries.

public:
  DbgPGVariable(DIPGVariable V) : Var(V), TheDIE(0), DotDebugLocOffset(~0U) {}

  // Accessors.
  DIPGVariable getPGVariable() const { return Var; }
  void setDIE(DIE *D) { TheDIE = D; }
  DIE *getDIE() const { return TheDIE; }
  void setDotDebugLocOffset(unsigned O) { DotDebugLocOffset = O; }
  unsigned getDotDebugLocOffset() const { return DotDebugLocOffset; }
  StringRef getName() const { return Var.getName(); }

  // Translate tag to proper Dwarf tag.
  unsigned getTag() const { return dwarf::DW_TAG_variable; }

  DITypeRef getType() const { return Var.getType(); }
};

class LLVM_LIBRARY_VISIBILITY BRIGDwarfDebug : public DwarfDebug {
private:
  BRIGAsmPrinter *m_brigAP;

  friend class BRIGAsmPrinter;
  // allow construction of BRIGDwarfDebug only in BRIGAsmPrinter
  BRIGDwarfDebug(BRIGAsmPrinter *Asm, Module *M);

protected:
  /// createCompileUnitInstance - Returns target-specific instance of
  /// CompileUnit
  virtual DICompileUnit *createCompileUnit(unsigned int I, unsigned int L,
                                           DIE *D);

  /// shouldCoalesceDbgValue - Returns true if MInst should be coalesced with
  /// History
  virtual bool
  shouldCoalesceDbgValue(const SmallVectorImpl<const MachineInstr *> &History,
                         const MachineInstr *MInsn);

  /// addCurrentFnArgument - If Var is an current function argument that add
  /// it in CurrentFnArguments list.
  virtual bool addCurrentFnArgument(const MachineFunction *MF, DbgVariable *Var,
                                    LexicalScope *Scope);

  /// recordDebugLocsForVariable - records debug locations for variable
  virtual void recordDebugLocsForVariable(
      const SmallVectorImpl<const MachineInstr *> &History, DbgVariable *RegVar,
      LexicalScope *Scope);

  /// collectVariableInfo - Populate LexicalScope entries with variables' info.
  virtual void
  collectVariableInfo(const MachineFunction *MF,
                      SmallPtrSet<const MDNode *, 16> &ProcessedVars);

  /// Construct DIEs for current scope variables (including private and group
  /// variables)
  virtual DIE *constructDIEsForScopeVariables(DICompileUnit *TheCU,
                                              LexicalScope *Scope,
                                              SmallVector<DIE *, 8> &Children);

private:
  /// addBRIGArgumentLocation - adds the BRIG offset as the debug location
  /// for the given function argument.
  void addBRIGFnArgumentLocation(DbgVariable *Var);

  typedef SmallVector<const MDNode *, 256> PGList;
  typedef PGList::const_iterator PGIterator;
  PGList privateVars;
  PGList groupVars;

#ifdef BRIG_DWARF_DEMANGLE_PRIVATE_VARIABLES
  typedef std::map<std::string, uint64_t> PGOffsetMap;
  typedef PGOffsetMap::const_iterator PGOffsetMapIterator;
  PGOffsetMap CurrentFnPrivateVars;
  PGOffsetMap CurrentFnGroupVars;
#else
  typedef SmallVector<DbgPGVariable *, 8> DbgPGList;
  typedef DbgPGList::const_iterator DbgPGIterator;
  DbgPGList CurrentFnPrivateVars;
  DbgPGList CurrentFnGroupVars;
#endif // BRIG_DWARF_DEMANGLE_PRIVATE_VARIABLES

  /// collect private or global variables for the current function
  /// and stores them in the given container
  void collectPGVariableInfo(PGList &pgList, HSAILAS::AddressSpaces addrSpace);

#ifdef BRIG_DWARF_DEMANGLE_PRIVATE_VARIABLES
  void addScopeGroupVariable(const std::string &demangledName,
                             uint64_t brigOffset);
  void addScopePrivateVariable(const std::string &demangledName,
                               uint64_t brigOffset);
#else
  void addScopeGroupVariable(LexicalScope *LS, DbgPGVariable *Var);
  void addScopePrivateVariable(LexicalScope *LS, DbgPGVariable *Var);
#endif // BRIG_DWARF_DEMANGLE_PRIVATE_VARIABLES

public:
  virtual ~BRIGDwarfDebug();

  /// addPrivateVariableMDNode - callback function for BRIGDwarfCompileUnit
  /// this function notifies BRIGDwarfDebug instance about private variable
  /// found in the module's metadata
  void addPrivateVariableMDNode(const MDNode *N);

  /// addGroupVariableMDNode - callback function for BRIGDwarfCompileUnit that
  /// notifies
  /// this function notifies BRIGDwarfDebug instance about group variable
  /// found in the module's metadata
  void addGroupVariableMDNode(const MDNode *N);

}; // class BRIGDwarfDebug
} // namespace llvm

#endif // BRIG_DWARF_DEBUG_HEADER
