//===- AMDResolveLinker.cpp - bitcode module linker ----------------------===//
//
//
// Copyright (c) 2013 Advanced Micro Devices, Inc. All rights reserved.
//
//
//===--------------------------------------------------------------------===//
//
// This files implements the bitcode module linking by resolving symbol
// referected through libraries
//
//===--------------------------------------------------------------------===//

#include "llvm/AMDResolveLinker.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Linker/Linker.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueSymbolTable.h"
#include "llvm/IR/Verifier.h"
//#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include <cassert>
#include <list>
#include <map>
#include <set>
#include <string>

using namespace llvm;

// Linking all library modules with the application module uses "selective
// extraction", in which only functions that are referenced from the
// application get extracted into the final module.
//
// The selective extraction is achieved by Reference Map (ModuleRefMap).
// A Reference Map for the application module keeps track of all functions
// that are referenced from the application but not defined in the application
// module.
//
// Reference Map is implemented by the following three functions:
// InitReferenceMap(), AddReferences(), and AddFuncReferences(). It hanles both
// extern and local functions.

// Get a callee function or an alias to a function.
static Value* GetCalledFunction(CallInst* CI) {
  Value* Callee = CI->getCalledValue();
  if (Function *F = dyn_cast<Function>(Callee)) {
    return F;
  }
  if (GlobalAlias *GAV = dyn_cast<GlobalAlias>(Callee)) {
    return GAV;
  }
  if (ConstantExpr *CE = dyn_cast<ConstantExpr>(Callee)) {
    if (CE->getOpcode() == Instruction::BitCast) {
      if (Function *F = dyn_cast<Function>(CE->getOperand(0))) {
        return F;
      }
      if (GlobalAlias *GAV = dyn_cast<GlobalAlias>(CE->getOperand(0))) {
        return GAV;
      }
    }
  }

  // Indirect call, nothinng to link.
  return 0;
}

namespace llvm {

// Scan the source module for all external references.
void ReferenceMapBuilder::InitReferenceMap() {
//  DEBUG(dbgs() << "InitReferenceMap:\n");
  for (Module::iterator SF = _SrcM->begin(), E = _SrcM->end(); SF != E; ++SF) {
    Function *F = SF;
    if (!F || !F->hasName())
      continue;

    // All no-body functions should be library functions. Initialize ExternFuncs
    // with all those functions.
    //
    // Weak functions are also treated as no-body functions.
    if (!F->hasLocalLinkage() &&
        (F->isDeclaration() || F->isWeakForLinker())) {
      _InExternFuncs[F->getName()] = true;
      _ExternFuncs.push_back(F->getName());
//      DEBUG(dbgs() << "Added " << F->getName() << "\n");
    }
  }
}

void ReferenceMapBuilder::AddForcedReferences(const char* forcedRefs[],
                                              size_t numRefs) {
  for (size_t i = 0; i < numRefs; ++i) {
    _InExternFuncs[forcedRefs[i]] = true;
    _ExternFuncs.push_back(forcedRefs[i]);
    //DEBUG(dbgs() << "Added " << forcedRefs[i] << "\n");
  }
}

void ReferenceMapBuilder::AddFuncReference(unsigned LibIdx, Function *F) {
  _LibMs[LibIdx]->materialize(F);
  if (!F->hasLocalLinkage()) {
    _ModuleRefMaps[LibIdx][F] = true;
    //DEBUG(dbgs() << "added ref map: " << F->getName() <<"\n");
    if (!_InExternFuncs.lookup(F->getName())) {
      _InExternFuncs[F->getName()] = true;
      _ExternFuncs.insert(_ExternFuncs.end(), 1, F->getName());
      //DEBUG(dbgs() << "added called external func " << F->getName() << "\n");
    }
  } else if (/* F->hasLocalLinkage() && */ !_ModuleRefMaps[LibIdx][F]) {
    _ModuleRefMaps[LibIdx][F] = true;
    //DEBUG(dbgs() << "check internal func";
//      WriteAsOperand(dbgs(), F, 0, _LibMs[LibIdx]); dbgs() << "\n");
    _UnscannedFuncs.push_back(IdxFuncPair(LibIdx, F));
  }
}

// ScanUnscannedFuncs() visits the bodies of all functions on the
// _UnscannedFuncs worklist. It adds any extern function in _ExternFuncs.
// For any local function, it adds it to the _UnscannedFuncs() worklist,
// so that it will get visited in later iterations.
void ReferenceMapBuilder::ScanUnscannedFuncs()
{
  while (!_UnscannedFuncs.empty()) {
    unsigned LibIdx = _UnscannedFuncs.back().first;
    Function *SF = _UnscannedFuncs.back().second;
    _UnscannedFuncs.pop_back();
    //DEBUG(dbgs() << "Begin scannning ";
//      WriteAsOperand(dbgs(), SF, 0, _LibMs[LibIdx]); dbgs() << "\n");
    // Add this function's direct extern reference into ExternFuncs if it is
    // not in ExternFuncs yet. For a local reference, invoke itself to visit
    // that local function body if it has not been visited. ModuleRefMap
    // tells which local functions have been visited already.
    for (Function::iterator BB = SF->begin(), BE = SF->end(); BB != BE; ++BB) {
      for (BasicBlock::iterator I = BB->begin(), E = BB->end(); I != E; ++I) {
        CallInst* CI = dyn_cast<CallInst>(&*I);
        if (!CI) continue;

        Value* Callee = GetCalledFunction(CI);
        if (!Callee) continue;

        //DEBUG(dbgs() << "calls ";
//          WriteAsOperand(dbgs(), Callee, 0, _LibMs[LibIdx]); dbgs() << "\n");

        Function *F;
        if (GlobalAlias *GAV = dyn_cast<GlobalAlias>(Callee)) {
          assert(GAV && "invoke non-func/non-alias");
          _ModuleRefMaps[LibIdx][GAV] = true;
          if (!GAV->hasLocalLinkage()) {
            if (!_InExternFuncs.lookup(GAV->getName())) {
              _InExternFuncs[GAV->getName()] = true;
              _ExternFuncs.insert(_ExternFuncs.end(), 1, GAV->getName());
              //DEBUG(dbgs() << "added called external alias " << GAV->getName() << "\n");
            }
          }

          GlobalValue *AV = const_cast<GlobalValue*>(dyn_cast<GlobalValue>(GAV->getAliasee()));
          F = dyn_cast<Function>(AV);
        } else {
          F = dyn_cast<Function>(Callee);
        }
        assert (F && "Should invoke either a func or an alias to a func");
        AddFuncReference(LibIdx, F);
      }
    }
    //DEBUG(dbgs() << "End scannning ";
//      WriteAsOperand(dbgs(), SF, 0, _LibMs[LibIdx]); dbgs() << "\n");
  }
}

void ReferenceMapBuilder::AddReferences() {
  // The following loop iterates over the ExternFuncs list and in each
  // iteration, a function body is visited and every new extern function,
  // if any, is added into the end of ExternFuncs (insertion does not
  // invalidates std::list's iterator) so that the new function will be
  // visited later.
  //DEBUG(dbgs() << "\nEnter AddReferences\n");
  for (std::list<std::string>::iterator it = _ExternFuncs.begin(),
    IE = _ExternFuncs.end(); it != IE; ++it) {
    std::string FName = *it;

    // In case there're multiple definitions to FName, only the first strong
    // definition needs to be scanned (scan its function body). The libraries
    // following this strong definition does not need to scan another function
    // body if FName is defined again; but they do need to add FName to their
    // reference map if FName is referenced. For this reason, we keep looping
    // over all iterations and guard body-scanning with ScanFuncBody.
    GlobalValue* FuncDef = NULL;
    unsigned FuncDefLibIdx = 0;
    //DEBUG(dbgs() << "check " << FName << "\n");

    // Search library in order
    for (unsigned i = 0; i < _LibMs.size(); i++) {
      //DEBUG(dbgs() << "check lib " << i << "\n");
      Module* Src = _LibMs[i];
      ValueSymbolTable &SrcSymTab = Src->getValueSymbolTable();
      GlobalValue *SGV = cast_or_null<GlobalValue>(SrcSymTab.lookup(FName));
      if (!SGV) continue;

      // If SGV has local linkage, it is not the same as FName, skip it.
      if (SGV->hasLocalLinkage()) continue;

      // Found a declaration or definition for extern FName.
      _ModuleRefMaps[i][SGV] = true;
      //DEBUG(dbgs() << "added ref map: lib " << i << " : ";
//        WriteAsOperand(dbgs(), SGV, 0, Src); dbgs() << "\n");

      Function* SF = 0;
      if (isa<GlobalAlias>(SGV)) {
        // Don't allow multiple defs to any one alias
        // (like Lib1:x = y; Lib2:x = z),
        // nor an alias def and a normal def (like Lib1: x {}; Lib2:x=z).
        // If this happens, linking may have a undefined behavior and LLVM may
        // give an error message.
        assert((!FuncDef || FuncDef->isWeakForLinker() ||
                SGV->isWeakForLinker())
               && "Redefinition of alias");
      } else if ((SF = dyn_cast<Function>(SGV))) {
        if (!SF->isDeclaration() || SF->isMaterializable()) {
          // check that it never happens that a strong function definition
          // re-defines a strong alias definition.
          assert(!(FuncDef && isa<GlobalAlias>(FuncDef) &&
                  !FuncDef->isWeakForLinker() && !SF->isWeakForLinker())
                 && "Redefinition of alias");
        } else {
          continue;
        }
      } else {
        assert ( false && "Unknown global references");
        continue;
      }
      // use the first strong definition as the definition
      if (!FuncDef
        || (FuncDef->isWeakForLinker() && !SGV->isWeakForLinker())) {
        FuncDef = SGV;
        FuncDefLibIdx = i;
      }
    }

    //assert(FuncDef && "Function definition not found");
    if (!FuncDef) continue;
    if (GlobalAlias *GAV = dyn_cast<GlobalAlias>(FuncDef)) {
//      GlobalValue *AV = const_cast<GlobalValue*>(GAV->getAliasedGlobal());
      GlobalValue *AV = const_cast<GlobalValue*>(dyn_cast<GlobalValue>(GAV->getAliasee()));
      // SF = Src->getFunction(AV->getName());
      Function *F = dyn_cast<Function>(AV);
      AddFuncReference(FuncDefLibIdx, F);
    } else {
      // scan the body of the function definition found for functions
      // referenced by the function definition
      Function *F = dyn_cast<Function>(FuncDef);
      _LibMs[FuncDefLibIdx]->materialize(F);
      _UnscannedFuncs.push_back(IdxFuncPair(FuncDefLibIdx, F));
    }
    ScanUnscannedFuncs();
  }

#if 0
  DEBUG(
    /* Need to include llvm/Assembly/Writer.h */
    dbgs() << "\n Begin of Reference Map" << "\n\n";
    for (unsigned int i=0; i < _LibMs.size(); i++) {
      dbgs() << "\n   Reference Map for " << i << "\n\n";
      for (std::map<const Value*, bool>::iterator
        I = _ModuleRefMaps[i].begin(), IE = _ModuleRefMaps[i].end();
        I != IE; ++I) {
        const Value* V = I->first;
        if (I->second) {
          WriteAsOperand(dbgs(), V, 0, _LibMs[i]);
          dbgs() <<"\n";
        }
      }
    }
    dbgs() << "\n End of Reference Map" << "\n\n";
  );
#endif
}

static void UnlinkGlobals(Module* M,
                          std::set<GlobalVariable*> AliveGlobals) {
  std::vector<GlobalVariable*> DeadGlobals;
//  DEBUG(dbgs() << "\nUnlinkGlobals:\n");
  for (Module::global_iterator I = M->global_begin(), E = M->global_end();
       I != E; ++I) {
    GlobalVariable* GVar = I;
    //DEBUG(WriteAsOperand(dbgs(), GVar, true, M);
      //dbgs() << " use_empty = " << GVar->use_empty();
      //dbgs() << " AliveGlobals.count = " << AliveGlobals.count(GVar) << "\n");

    bool spurious = true;
    // The following check is necessary to remove spurious use of global array

    if (!GVar->use_empty()) {
      for (GlobalVariable::use_iterator UI = GVar->use_begin(), UE =
        GVar->use_end(); UI != UE; ++UI) {
        if (Constant * con = dyn_cast<Constant>(*UI)) {
          //DEBUG(dbgs() << "    Constant user: " << *con << " use_empty=" << con->use_empty() << "\n");
          if (!con->use_empty()) {
            spurious = false;
          }
        } else {
          spurious = false;
          //DEBUG(dbgs() << "    Other user: " << **UI << "\n");
        }
      }
    }

    if (spurious && (AliveGlobals.count(GVar) == 0)) {
      DeadGlobals.push_back(GVar);
    }
  }

  for (int i=0, e = (int) DeadGlobals.size(); i < e; i++) {
    //DEBUG(WriteAsOperand(dbgs(), DeadGlobals[i], true, M);
      //dbgs() << " deleted\n");
    M->getGlobalList().erase(DeadGlobals[i]);
  }
}

/// Link Src module to Dst with result in Dst using optional ModuleRefMap.
/// Returns true on error.
bool linkWithModule(Module* Dst, llvm::Module* Src,
                    std::map<const llvm::Value*, bool> *ModuleRefMap,
                    std::string *ErrorMsg) {
  if (Linker::LinkModules(Dst, Src, ModuleRefMap)) {
    return true;
  }

  return false;
}

/// resolveLink - This function links an input module with the libraries
/// by resolving undefined symbols from these libraries.
/// Input module is modified to contain the linking result. If an error
/// occurs, true is returned and ErrorMsg (if not null) is set to indicate
/// the problem. Upon failure, the destination module could be in a modified
/// state, and shouldn't be relied on to be consistent.
/// Unresolved symbols may remain upon successful link.
bool resolveLink(llvm::Module* input, std::vector<llvm::Module*> &libs,
                 std::map<const llvm::Value*, bool> *ModuleRefMap,
                 std::string *ErrorMsg)
{
  // A quick workaround to unlink useless globals from libraries.
  std::set<llvm::GlobalVariable*> AliveGlobals;
  for (Module::global_iterator I = input->global_begin(),
      E = input->global_end(); I != E; ++I) {
    llvm::GlobalVariable* GVar = I;
    AliveGlobals.insert(GVar);
  }

  // Link libraries to get every functions that are referenced.
  for (unsigned int i=0; i < libs.size(); i++) {
    llvm::Module* Library = libs[i];
#ifndef ANDROID
    if (linkWithModule(input, Library, ModuleRefMap ? &ModuleRefMap[i]
                                                    : nullptr, ErrorMsg)) {
#else
    if (linkWithModule(input, Library, ModuleRefMap ? &ModuleRefMap[i]
                                                    : NULL, ErrorMsg)) {
#endif
      return true;
    }

    delete Library;
    libs[i] = 0;
  }

  // Now, unlink those useless globals linked in from libraries.
  //UnlinkGlobals(input, AliveGlobals);
  //AliveGlobals.clear();

  return false;
}

/// resolveLink - This function links an input module with the libraries
/// by resolving undefined symbols from these libraries.
/// Input module is modified to contain the linking result. If an error
/// occurs, true is returned and ErrorMsg (if not null) is set to indicate
/// the problem. Upon failure, the destination module could be in a modified
/// state, and shouldn't be relied on to be consistent.
/// Unresolved symbols may remain upon successful link.
bool resolveLink(llvm::Module* input, std::vector<llvm::Module*> &libs,
                 std::string *ErrorMsg)
{
  ReferenceMapBuilder RefMapBuilder(input, libs);
  RefMapBuilder.Build();

  return resolveLink(input, libs, RefMapBuilder.getModuleRefMaps(), ErrorMsg);
}
} // namespace llvm
