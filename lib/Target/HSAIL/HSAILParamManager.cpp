//=== HSAILParamManager.cpp - kernel/function arguments ---------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the HSAILParamManager class.
//
//===----------------------------------------------------------------------===//

#include "HSAIL.h"
#include "HSAILParamManager.h"
#include "HSAILOpaqueTypes.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/Twine.h"
#include "llvm/IR/Mangler.h"
#include <sstream>

using namespace llvm;

HSAILParamManager::~HSAILParamManager() {
  // Special handling for teardown of ParamNames
  for (names_iterator I = ParamNames.begin(), E = ParamNames.end(); I != E;
       ++I) {
    // Delete malloc'ed name strings
    free(I->second);
  }
  ParamNames.clear();
}

unsigned HSAILParamManager::addParam(HSAILParamType ParamType, Type *Ty,
                                     const StringRef ParamName) {
  HSAILParam Param;
  Param.Type = ParamType;
  Param.Arg = nullptr;
  SmallVector<unsigned, 4> *ParamList = 0;
  const char *DefName = 0;

  std::string Name;

  switch (ParamType) {
  case HSAIL_PARAM_TYPE_KERNARG:
  case HSAIL_PARAM_TYPE_ARGUMENT:
    ParamList = &ArgumentParams;
    DefName = "__arg_p";
    break;
  case HSAIL_PARAM_TYPE_RETURN:
    ParamList = &ReturnParams;
    DefName = "__ret_";
    break;
  case HSAIL_PARAM_TYPE_CALL_PARAM:
    ParamList = &CallArgParams;
    DefName = "__param_";
    break;
  case HSAIL_PARAM_TYPE_CALL_RET:
    ParamList = &CallRetParams;
    DefName = "__ret_";
    break;
  }

  if (ParamName.empty()) {
    Name = DefName;
    Name += utostr(ParamList->size());
  } else {
    Name = ParamName;
  }

  unsigned prev_offset = 0;
  unsigned prev_size = 0;
  if (ParamList->size() > 0) {
    unsigned prev_param = (*ParamList)[ParamList->size() - 1];
    prev_offset = getParamOffset(prev_param);
    prev_size = getParamSize(prev_param);
  }
  if (prev_offset == UINT_MAX || GetOpaqueType(Ty)) {
    Param.Offset = UINT_MAX;
  } else {
    unsigned alignment = DL->getABITypeAlignment(Ty);
    // W/a for RT alignment of vectors to element size:
    if (ParamType == HSAIL_PARAM_TYPE_KERNARG && Ty->isVectorTy())
      alignment = DL->getABITypeAlignment(Ty->getVectorElementType());
    assert(alignment != 0);
    Param.Offset = (prev_offset + prev_size + alignment - 1) & ~(alignment - 1);
  }

  unsigned Index = AllParams.size();
  AllParams[Index] = Param;
  ParamList->push_back(Index);

  addParamName(Name, Index);
  addParamType(Ty, Index);

  return Index;
}

unsigned HSAILParamManager::addArgumentParam(unsigned AS, const Argument &Arg,
                                             const StringRef ParamName) {
  unsigned Param =
      addParam((AS == HSAILAS::ARG_ADDRESS) ? HSAIL_PARAM_TYPE_ARGUMENT
                                            : HSAIL_PARAM_TYPE_KERNARG,
               Arg.getType(), ParamName);
  AllParams.find(Param)->second.Arg = &Arg;
  return Param;
}

unsigned HSAILParamManager::addReturnParam(Type *Ty,
                                           const StringRef ParamName) {
  return addParam(HSAIL_PARAM_TYPE_RETURN, Ty, ParamName);
}

unsigned HSAILParamManager::addCallArgParam(Type *Ty,
                                            const StringRef ParamName) {
  return addParam(HSAIL_PARAM_TYPE_CALL_PARAM, Ty, ParamName);
}

unsigned HSAILParamManager::addCallRetParam(Type *Ty,
                                            const StringRef ParamName) {
  return addParam(HSAIL_PARAM_TYPE_CALL_RET, Ty, ParamName);
}

void HSAILParamManager::addParamName(std::string Name, unsigned Index) {
  // malloc arg name string so that it persists through compilation
  char *name = (char *)malloc(Name.length() + 1);
  strcpy(name, Name.c_str());
  ParamNames[Index] = name;
}

void HSAILParamManager::addParamType(Type *pTy, unsigned Index) {
  ParamTypes[Index] = pTy;
}

unsigned HSAILParamManager::getParamByOffset(unsigned &Offset) const {
  unsigned param_no = ArgumentParams.size();
  for (unsigned i = 0; i < param_no; i++) {
    unsigned param = ArgumentParams[i];
    unsigned o = getParamOffset(param);
    if (o == UINT_MAX)
      break;
    if ((o <= Offset) && ((o + getParamSize(param)) > Offset)) {
      // Parameter found and addressing is in bound.
      Offset -= o;
      return param;
    }
  }
  return UINT_MAX;
}

/// returns a unique argument name for flattened vector component.
std::string HSAILParamManager::mangleArg(Mangler *Mang,
                                         const StringRef argName) {
  if (argName.empty())
    return "";

  std::string NameStrStorage;

  {
    raw_string_ostream NameStr(NameStrStorage);
    Mang->getNameWithPrefix(NameStr, argName);
  }

  return std::move(NameStrStorage);
}
