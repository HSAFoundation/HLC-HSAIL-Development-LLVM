#include "BRIGDwarfDebug.h"
#include "BRIGDwarfCompileUnit.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/IR/Function.h"

using namespace llvm;

namespace llvm {

BRIGDwarfDebug::BRIGDwarfDebug(BRIGAsmPrinter* Asm, Module* M):
  DwarfDebug(Asm, M), m_brigAP(Asm) {
}

BRIGDwarfDebug::~BRIGDwarfDebug() {
}

CompileUnit *BRIGDwarfDebug::createCompileUnit(unsigned int I, 
                                               unsigned int L,
                                               DIE* D) {
  assert((const void*)Asm == (const void*)m_brigAP);
  return new BRIGDwarfCompileUnit(I, D, m_brigAP, this);
}

bool BRIGDwarfDebug::shouldCoalesceDbgValue(const SmallVectorImpl<const MachineInstr*> &History, 
                                            const MachineInstr* MInsn) {
  /* disable coalescing for a while */
  return false;
}

void BRIGDwarfDebug::addBRIGFnArgumentLocation(DbgVariable *Var) {

  assert(Var->getVariable().getTag() == dwarf::DW_TAG_arg_variable &&
    "addBRIGFnArgumentLocation: variable is not a function argument");
  uint64_t argOffset;
  std::string argName = Var->getName().str();

  // query BRIGAsmPrinter instance
  bool rv = m_brigAP->getFunctionScalarArgumentOffset(argName, &argOffset);
  if (rv) {
    assert(argOffset && "invalid BRIG offset of function argument");
    // record the BRIG offset 
    Var->setDotDebugLocOffset(static_cast<unsigned int>(argOffset));
  } 
  else {
    // scalar argument with given name not found - try find vector argument
    BRIGAsmPrinter::VectorArgumentOffsets argOffsets;
    rv = m_brigAP->getFunctionVectorArgumentOffsets(argName, argOffsets);
    assert(rv && "could not find argument offset");
    //for (int i = 0, e = argOffsets.size(); i != e; i++) {
    //  errs() << "BRIGDwarfDebug: variable " << argName << 
    //    ": part " << (i + 1) << " (" << argOffsets[i].second << 
    //    " bits) is at offset " << argOffsets[i].first << "\n";
    //}
    // intentionally set argument's BRIG offset to 0 to indicate that it has multiple parts.
    Var->setDotDebugLocOffset(0);
  }
}


bool BRIGDwarfDebug::addCurrentFnArgument(const MachineFunction *MF,
                                          DbgVariable *Var, LexicalScope *Scope) {
  bool rv = DwarfDebug::addCurrentFnArgument(MF, Var, Scope);
  if (rv) {
    addBRIGFnArgumentLocation(Var);
  }
  // DwarfDebug::addCurrentFnArgument returns false in the following cases:
  //  - either if Scope is not a current function scope;
  //  - or if Var is not a function argument;
  //  - or if argument number is 0
  return rv;
}

#ifdef BRIG_DWARF_DEMANGLE_PRIVATE_VARIABLES
namespace {

// TODO_HSA(3) these literals and routines should be defined in one place in the tree.
const char OpenCLKernelPrefix[] = "__OpenCL_";
const size_t OpenCLKernelPrefixLength = sizeof(OpenCLKernelPrefix) - 1;

const char OpenCLKernelSuffix[] = "_kernel";
const size_t OpenCLKernelSuffixLength = sizeof(OpenCLKernelSuffix) - 1;

const char CLPrivateVariablePrefix[] = "_clprivate_";
const size_t CLPrivateVariablePrefixLength = sizeof(CLPrivateVariablePrefix) - 1;

const char CLGroupVariablePrefix[] = "_cllocal_";
const size_t CLGroupVariablePrefixLength = sizeof(CLGroupVariablePrefix) - 1;

static bool isOpenCLKernelName(const StringRef& kernelName) {
  //  __OpenCL_%KERNELNAME%_kernel
  return kernelName.startswith(OpenCLKernelPrefix) &&
         kernelName.endswith(OpenCLKernelSuffix) &&
         kernelName.size() > (OpenCLKernelPrefixLength + OpenCLKernelSuffixLength); 
  // __OpenCL_kernel and __OpenCL__kernel are not a valid kernel names
}

static bool isOpenCLPrivateVariable(const StringRef& kernelName, const StringRef& variableName) {
  // %KERNELNAME%_clprivate_%VARIABLENAME%
  return variableName.startswith(kernelName.str() + CLPrivateVariablePrefix) &&
         variableName.size() > kernelName.size() + CLPrivateVariablePrefixLength;
}

static bool isOpenCLGroupVariable(const StringRef& kernelName, const StringRef& variableName) {
  // %KERNELNAME%_cllocal_%VARIABLENAME%
  return variableName.startswith(kernelName.str() + CLGroupVariablePrefix) &&
         variableName.size() > kernelName.size() + CLGroupVariablePrefixLength;
}


static StringRef demangleCLKernelName(const StringRef& kernelName) {
  return kernelName.slice(OpenCLKernelPrefixLength, kernelName.size() - OpenCLKernelSuffixLength);
}

static StringRef demangleCLPrivateVariableName(const StringRef& kernelName, 
                                             const StringRef& variableName) {
  return variableName.slice(kernelName.size() + CLPrivateVariablePrefixLength, variableName.size());
}

static StringRef demangleCLGroupVariableName(const StringRef& kernelName, 
                                             const StringRef& variableName) {
  return variableName.slice(kernelName.size() + CLGroupVariablePrefixLength, variableName.size());
}

static StringRef demangleFunctionName(const StringRef& functionName) {
  if (isOpenCLKernelName(functionName)) {
    return demangleCLKernelName(functionName);
  }
  else {
    // do not know how to demangle, keep it intact
    return functionName;
  }
}

};
#endif // BRIG_DWARF_DEMANGLE_PRIVATE_VARIABLES

void BRIGDwarfDebug::collectPGVariableInfo(PGList& pgList, HSAILAS::AddressSpaces addrSpace) {
#ifdef BRIG_DWARF_DEMANGLE_PRIVATE_VARIABLES
  StringRef mangledFunctionName = Asm->MF->getFunction()->getName();
  // errs() << "collectPGVariableInfo: mangled kernel name is " << mangledFunctionName << "\n"; //  __OpenCL_%KERNELNAME%_kernel
  // demangle function/kernel name
  StringRef demangledFunctionName = demangleFunctionName(mangledFunctionName);
  // errs() << "collectPGVariableInfo: demangled kernel name is " << demangledFunctionName << "\n"; //  %KERNELNAME%
#endif // BRIG_DWARF_DEMANGLE_PRIVATE_VARIABLES

  for (PGIterator v = pgList.begin(), e = pgList.end(); v != e; v++) {
    // create an accessor to MDNode fields
    DIPGVariable DV(*v, addrSpace);
    assert(DV.Verify() && "invalid private variable");
    // obtain an offset of variable from BRIGAsmPrinter
    uint64_t VOffs = 0;
    if (addrSpace == HSAILAS::GROUP_ADDRESS && m_brigAP->getGroupVariableOffset(DV.getGlobal(), &VOffs)) {
      // variable offset in BRIG can't be 0
      assert(VOffs != 0 && "private/group variable is not in the BRIG container");
      // errs() << "BRIGDwarfDebug: found private/group variable " << DV.getName() << " at offset " << VOffs << "\n";
#ifdef BRIG_DWARF_DEMANGLE_PRIVATE_VARIABLES
      StringRef mangledVarName = DV.getName();

      if (addrSpace == HSAILAS::GROUP_ADDRESS) {
        if (isOpenCLGroupVariable(demangledFunctionName, mangledVarName)) {
          StringRef demangledName = demangleCLGroupVariableName(demangledFunctionName, mangledVarName);
          addScopeGroupVariable(demangledName.str(), VOffs);
        }
        else {
          errs() << "could not demangle group variable name " << mangledVarName << "\n";
          //assert(!"could not demangle group variable");
        }
      }
#else
      // create debug variable and add it to the list of variables for the current function
      LexicalScope *Scope = LScopes.getCurrentFunctionScope();
      DbgPGVariable *Var = new DbgPGVariable(DV);
      // assign an offset to the variable
      Var->setDotDebugLocOffset(static_cast<unsigned int>(VOffs));
      // store 
      if (addrSpace == HSAILAS::PRIVATE_ADDRESS) addScopePrivateVariable(Scope, Var);
      else if (addrSpace == HSAILAS::GROUP_ADDRESS) addScopeGroupVariable(Scope, Var);
#endif // BRIG_DWARF_DEMANGLE_PRIVATE_VARIABLES
    }
  }
}

// collectVariableInfo - Populate LexicalScope entries with variables' info.
void BRIGDwarfDebug::collectVariableInfo(const MachineFunction *MF,
                                         SmallPtrSet<const MDNode *, 16> &ProcessedVars) {
#ifdef BRIG_DWARF_DEMANGLE_PRIVATE_VARIABLES
  // clear any info about private and group variables found earlier
  // currently this assert fails because endFunction does not clear offset maps 
  // assert(CurrentFnPrivateVars.empty() && CurrentFnGroupVars.empty() && "sanity check failed");
  // TODO_HSA(3) override endFunction in BRIGDwarfDebug and put the
  // following statements there after DwarfDebug::endFunction call 
  CurrentFnPrivateVars.clear();
  CurrentFnGroupVars.clear();
  // collect private and group variables info
  collectPGVariableInfo(privateVars, HSAILAS::PRIVATE_ADDRESS);
  collectPGVariableInfo(groupVars, HSAILAS::GROUP_ADDRESS);
  // collect regular variables info 
  this->DwarfDebug::collectVariableInfo(MF, ProcessedVars);
#else
  // collect regular variables info 
  this->DwarfDebug::collectVariableInfo(MF, ProcessedVars);
  // any info about private and group variables found earlier should have been deleted
  assert(CurrentFnPrivateVars.empty() && CurrentFnGroupVars.empty() && "sanity check failed");
  // collect private and group variables info
  collectPGVariableInfo(privateVars, HSAILAS::PRIVATE_ADDRESS);
  collectPGVariableInfo(groupVars, HSAILAS::GROUP_ADDRESS);
#endif // BRIG_DWARF_DEMANGLE_PRIVATE_VARIABLES
}

DIE *BRIGDwarfDebug::constructDIEsForScopeVariables(CompileUnit *TheCU, LexicalScope *Scope,
                                                SmallVector <DIE *, 8>& Children) {
#ifdef BRIG_DWARF_DEMANGLE_PRIVATE_VARIABLES
  const SmallVector<DbgVariable *, 8> Variables = ScopeVariables.lookup(Scope);
  for (unsigned i = 0, N = Variables.size(); i < N; ++i) {
    /* TODO_HSA(3) move this logic to the more appropriate place like addScopeVariable or */
    DbgVariable* DV = Variables[i];
    if (DV) {
      StringRef varName = DV->getName();
      PGOffsetMapIterator offsetRecord = CurrentFnPrivateVars.find(varName.str());
      if (offsetRecord != CurrentFnPrivateVars.end()) {
        // assign an offset to this variable
        DV->setDotDebugLocOffset(static_cast<unsigned int>(offsetRecord->second));
      }
      else {
        // try group variables
        offsetRecord = CurrentFnGroupVars.find(varName.str());
        if (offsetRecord != CurrentFnGroupVars.end()) {
          // assign an offset to this variable
          DV->setDotDebugLocOffset(static_cast<unsigned int>(offsetRecord->second));
        }
      }
    }
    DIE *Variable = TheCU->constructVariableDIE(Variables[i], Scope->isAbstractScope());
    if (Variable) {
      Children.push_back(Variable);
    }
  }
#else
  // Construct DIEs for private and global variables for the current function.
  if (LScopes.isCurrentFunctionScope(Scope)) {
    // TODO_HSA(3) add an ability to cast CompileUnit to BRIGDwarfCompileUnit w/o RTTI
    BRIGDwarfCompileUnit *bdCU = dyn_cast_or_null<BRIGDwarfCompileUnit>(TheCU);
    assert(bdCU && "invalid compile unit");
    for(DbgPGIterator i = CurrentFnPrivateVars.begin(), e = CurrentFnPrivateVars.end(); i != e; i++) {
      DbgPGVariable *Var = *i;
      DIE *die = bdCU->constructPGVariableDIE(Var);
      assert(die && "could not construct DIE for private/group variable" );
      Children.push_back(die);
    }
    for(DbgPGIterator i = CurrentFnGroupVars.begin(), e = CurrentFnGroupVars.end(); i != e; i++) {
      DbgPGVariable *Var = *i;
      DIE *die = bdCU->constructPGVariableDIE(Var);
      assert(die && "could not construct DIE for private/group variable" );
      Children.push_back(die);
    }
    /* Private and group vars are not needed any more. */
    /* TODO_HSA(3) where do we destroy DIEs?           */
    DeleteContainerPointers(CurrentFnPrivateVars);
    DeleteContainerPointers(CurrentFnGroupVars);
  }

  // Construct DIEs for other variables 
  this->DwarfDebug::constructDIEsForScopeVariables(TheCU, Scope, Children);
#endif // BRIG_DWARF_DEMANGLE_PRIVATE_VARIABLES
  return NULL;
}

#ifdef BRIG_DWARF_DEMANGLE_PRIVATE_VARIABLES
void BRIGDwarfDebug::addScopeGroupVariable(const std::string& demangledName, uint64_t brigOffset) {
  CurrentFnGroupVars[demangledName] = brigOffset;
}

void BRIGDwarfDebug::addScopePrivateVariable(const std::string& demangledName, uint64_t brigOffset) {
  CurrentFnPrivateVars[demangledName] = brigOffset;
}

#else
void BRIGDwarfDebug::addScopeGroupVariable(LexicalScope *LS, DbgPGVariable *Var) {
  assert(LScopes.isCurrentFunctionScope(LS) && "group variable not in function scope");
  CurrentFnGroupVars.push_back(Var);
}

void BRIGDwarfDebug::addScopePrivateVariable(LexicalScope *LS, DbgPGVariable *Var) {
  assert(LScopes.isCurrentFunctionScope(LS) && "private variable not in function scope");
  CurrentFnGroupVars.push_back(Var);
}
#endif // BRIG_DWARF_DEMANGLE_PRIVATE_VARIABLES

void BRIGDwarfDebug::addPrivateVariableMDNode(const MDNode* N) {
  privateVars.push_back(N);
}

void BRIGDwarfDebug::addGroupVariableMDNode(const MDNode* N) {
  groupVars.push_back(N);
}

//===----------------------------------------------------------------------===//
// DIEString Implementation
//===----------------------------------------------------------------------===//

/// EmitValue - Emit string value.
///
void DIEString::EmitValue(AsmPrinter *AP, unsigned Form) const {
  AP->OutStreamer.EmitBytes(Str, /*addrspace*/0);
  // Emit nul terminator.
  AP->OutStreamer.EmitIntValue(0, 1, /*addrspace*/0);
}

#ifndef NDEBUG
void DIEString::print(raw_ostream &O) {
  O << "Str: \"" << Str << "\"";
}
#endif

} //namespace llvm
