//===- AMDResolveLinker.h - bitcode module linker -------------------------===//
//
// Copyright (c) 2013 Advanced Micro Devices, Inc. All rights reserved.
//
//===----------------------------------------------------------------------===//
//
// This files implements the bitcode module linking by resolving symbol
// referected through libraries
//
//===----------------------------------------------------------------------===//

#ifndef _AMD_RESOLVE_LINKER_HPP_
#define _AMD_RESOLVE_LINKER_HPP_
#include "llvm/ADT/StringMap.h"
#include "llvm/IR/Module.h"
#include <list>
#include <map>
#include <vector>

namespace llvm {
/*
  Linking all library modules with the application module uses "selective
  extraction", in which only functions that are referenced from the
  application get extracted into the final module.

  The selective extraction is achieved by Reference Map (ModuleRefMap).
  A Reference Map for the application module keeps track of all functions that
  are referenced from the application but not defined in the application module.

  It handles both extern and local functions.
  The standard linker links one library at a time when there are more than
  one libraries to link. Here we use a different approach in which it first
  calculates which functions should be linked in from each library, then does
  the actual linking.

  For example, assume there are two libraries A and B, where A defines
  function f, which references function g; and B defines function g, which
  references function k. Both A and B defines function k (f, g, k are all
  externs). A is linked first, and is followed by B.

  Apps       A         B
  ------    -----     ------
  use f    def f     def g
  use g     use k
  def k     def k

  This approach will extract f and k from A, and g from B.

  To calculate which functions should be extracted from which library, it
  starts from directly-referenced extern functions from the application module,
  and calculates their transitive closure.
*/
class ReferenceMapBuilder {
  typedef std::pair<unsigned, Function*> IdxFuncPair;

public:
  ReferenceMapBuilder(Module *SrcM, std::vector<Module*>& LibMs)
    : _SrcM(SrcM), _LibMs(LibMs), _ExternFuncs(), _InExternFuncs(),
      _UnscannedFuncs()
  {
    _ModuleRefMaps = new std::map<const Value*, bool>[LibMs.size()];
  }

  ~ReferenceMapBuilder() {
    delete[] _ModuleRefMaps;
  }

  std::map<const Value*, bool>* getModuleRefMaps() {
    return _ModuleRefMaps;
  }

  const std::list<std::string>& getExternFunctions() const {
    return _ExternFuncs;
  }

  // Add a list of functions which will be forcingly referenced.
  void AddForcedReferences(const char* forcedRefs[], size_t numRefs);

  void InitReferenceMap();

  void AddReferences();

  bool isInExternFuncs(const char* f) const {
    return _InExternFuncs.lookup(f) ? true : false;
  }

  // Main entry pointer. Build the reference maps.
  void Build() {
    InitReferenceMap();
    AddReferences();
  }

private:
  void AddFuncReference(unsigned LibIdx, Function *F);
  void ScanUnscannedFuncs();

private:
  Module *_SrcM;
  std::vector<Module*>& _LibMs;
  // _ModuleRefMaps[0:num-of-libs-1]
  // _ModuleRefMaps[i]: tells which functions in _LibMs[i] should be in the
  // final module. It includes both extern and local functions.
  std::map<const Value*, bool> *_ModuleRefMaps;
  // list of extern library functions directly or indirectly referenced by the
  // application.
  std::list<std::string> _ExternFuncs;
  // a helper map that simply returns true if an extern function
  // is in _ExternFuncs.
  //std::map<const std::string, bool> _InExternFuncs;
  StringMap<bool> _InExternFuncs;
  // worklist for functions whose body needs to be scanned
  std::vector<IdxFuncPair> _UnscannedFuncs;
};

/// Link Src module to Dst with result in Dst using optional ModuleRefMap.
/// Returns true on error.
bool linkWithModule(Module* Dst, llvm::Module* Src,
                    std::map<const llvm::Value*, bool> *ModuleRefMap,
                    std::string *ErrorMsg);

/// resolveLink - This function links an input module with the libraries
/// by resolving undefined symbols from these libraries.
/// Input module is modified to contain the linking result. If an error
/// occurs, true is returned and ErrorMsg (if not null) is set to indicate
/// the problem. Upon failure, the destination module could be in a modified
/// state, and shouldn't be relied on to be consistent.
/// Unresolved symbols may remain upon successful link.
bool resolveLink(llvm::Module* input, std::vector<llvm::Module*> &libs,
                 std::map<const llvm::Value*, bool> *ModuleRefMap,
                 std::string *ErrorMsg);

/// resolveLink - This function links an input module with the libraries
/// by resolving undefined symbols from these libraries.
/// Input module is modified to contain the linking result. If an error
/// occurs, true is returned and ErrorMsg (if not null) is set to indicate
/// the problem. Upon failure, the destination module could be in a modified
/// state, and shouldn't be relied on to be consistent.
/// Unresolved symbols may remain upon successful link.
bool resolveLink(llvm::Module* input, std::vector<llvm::Module*> &libs,
                 std::string *ErrorMsg);
}; // namespace llvm
#endif // _AMD_RESOLVE_LINKER_HPP_
