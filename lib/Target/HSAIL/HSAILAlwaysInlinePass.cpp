//===-- HSAILAlwaysInlinePass.cpp - Promote Allocas ----------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
/// \file
/// This pass marks all internal functions as always_inline and creates
/// duplicates of all other functions a marks the duplicates as always_inline.
//
//===----------------------------------------------------------------------===//

#include "HSAIL.h"
#include "llvm/IR/Module.h"
#include "llvm/Transforms/Utils/Cloning.h"

using namespace llvm;

namespace {

class HSAILAlwaysInline : public ModulePass {

  static char ID;

public:
  HSAILAlwaysInline() : ModulePass(ID) { }
  bool runOnModule(Module &M) override;
  const char *getPassName() const override { return "AMDGPU Always Inline Pass"; }
};

} // End anonymous namespace

char HSAILAlwaysInline::ID = 0;

bool HSAILAlwaysInline::runOnModule(Module &M) {

  std::vector<Function*> FuncsToClone;
  for (Module::iterator I = M.begin(), E = M.end(); I != E; ++I) {
    Function &F = *I;
    if (!F.hasLocalLinkage() && !F.isDeclaration() && !F.use_empty())
      FuncsToClone.push_back(&F);
  }

  for (Function *F : FuncsToClone) {
    ValueToValueMapTy VMap;
    Function *NewFunc = CloneFunction(F, VMap, false);
    NewFunc->setLinkage(GlobalValue::InternalLinkage);
    F->getParent()->getFunctionList().push_back(NewFunc);
    F->replaceAllUsesWith(NewFunc);
  }

  for (Module::iterator I = M.begin(), E = M.end(); I != E; ++I) {
    Function &F = *I;
    if (F.hasLocalLinkage()) {
      F.addFnAttr(Attribute::AlwaysInline);
    }
  }
  return false;
}

ModulePass *llvm::createHSAILAlwaysInlinePass() {
  return new HSAILAlwaysInline();
}
