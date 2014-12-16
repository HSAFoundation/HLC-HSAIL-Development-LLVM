#define DEBUG_TYPE "amdfunctionlinkage"
#include "llvm/Transforms/IPO.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Analysis/AMDKernelSymbols.h"
#include <set>

using namespace llvm;

STATISTIC(NumFunctions, "Number of functions marked as InternalLinkage");
STATISTIC(NumGlobals,  "Number of globals marked as InternalLinkage");
STATISTIC(NumGlobalAliases,  "Number of global aliases marked as InternalLinkage");

namespace {
  struct AMDSymbolLinkage : public ModulePass {
    std::set<std::string>* requestedFunctions;
    static char ID; // Pass identification, replacement for typeid
    AMDSymbolLinkage(bool isWhole=false,
		       std::set<std::string>* reqFuns = NULL)
      : ModulePass(ID), requestedFunctions(reqFuns), wholeProgram(isWhole) {
      initializeAMDSymbolLinkagePass(*PassRegistry::getPassRegistry());
    }

    virtual ~AMDSymbolLinkage() { delete requestedFunctions; }

    // run - Do the AMDSymbolLinkage pass on the specified module.
    bool runOnModule(Module &M);

    void getAnalysisUsage(AnalysisUsage &AU) const {
      AU.addRequired<KernelSymbols>();
      AU.setPreservesAll();
    }

  private:
    bool wholeProgram;  // Tell if this Module is the whole program
  };
}

char AMDSymbolLinkage::ID = 0;
INITIALIZE_PASS_BEGIN(AMDSymbolLinkage, "amdfunctionlinkage", "Mark non-kernel functions with InternalLinkage", false, false)
INITIALIZE_AG_DEPENDENCY(KernelSymbols)
INITIALIZE_PASS_END(AMDSymbolLinkage, "amdfunctionlinkage", "Mark non-kernel functions with InternalLinkage", false, false)

ModulePass *
llvm::createAMDSymbolLinkagePass(bool isWhole,
				   std::set<std::string> *reqFuns) {
  return new AMDSymbolLinkage(isWhole, reqFuns);
}

bool AMDSymbolLinkage::runOnModule(Module &M) {
  bool Changed = false;

  // For now, only do it under the whole_program mode
  if (!wholeProgram)
    return Changed;

  const KernelSymbols &OCLS = getAnalysis<KernelSymbols>();
  for (Module::iterator I = M.begin(), E = M.end(); I != E; ++I) {
    Function *F = (Function *)I;

    // Functions without body are ignored.
    if (!F || F->isDeclaration())
      continue;

    // Skip reserved and kernel functions.
    if (OCLS.isKnown(F) ||
	      (requestedFunctions != NULL &&
         requestedFunctions->find(F->getName()) != requestedFunctions->end()))
      continue;

    DEBUG(errs() << "<AMDSymbolLinkage> " << F->getName()
                 << " : non-kernel function, set to InternalLinkage\n");
    NumFunctions++;
    F->setLinkage(GlobalValue::InternalLinkage);
    Changed = true;
  }

  for (Module::global_iterator I = M.global_begin(), E = M.global_end();
       I != E; ++I) {
    if (OCLS.isReserved(I))
      continue;

    DEBUG(errs() << "<AMDSymbolLinkage> " << I->getName()
                 << " : non-reserved global, set to InternalLinkage\n");
    NumGlobals++;
    I->setLinkage(GlobalValue::InternalLinkage);
    Changed = true;
  }

  for (Module::alias_iterator I = M.alias_begin(), E = M.alias_end();
       I != E; ++I) {
    if (OCLS.isKnown(I))
      continue;

    DEBUG(errs() << "<AMDSymbolLinkage> " << I->getName()
                 << " : non-reserved/kernel alias, set to InternalLinkage\n");
    NumGlobalAliases++;
    I->setLinkage(GlobalValue::InternalLinkage);
    Changed = true;
  }

  return Changed;
}
