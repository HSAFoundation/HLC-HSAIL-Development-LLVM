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
#include "llvm/ADT/SmallString.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/Twine.h"
#include "llvm/Target/Mangler.h"
#include <sstream>

using namespace llvm;

HSAILParamManager::HSAILParamManager() {
}

HSAILParamManager::~HSAILParamManager() {
  // Special handling for teardown of ParamNames
  for (names_iterator I = ParamNames.begin(), E = ParamNames.end(); 
    I != E; ++I) {
    // Delete malloc'ed name strings
    free(I->second);
  }
  ParamNames.clear();
}

unsigned HSAILParamManager::addParam(HSAILParamType Type, unsigned Size, const StringRef ParamName) {
  HSAILParam Param;
  Param.Type = Type;
  Param.Size = Size;
#ifndef ANDROID
  SmallVector<unsigned, 4>* ParamList = nullptr;
  const char* DefName = nullptr;
#else
  SmallVector<unsigned, 4>* ParamList = 0;
  const char* DefName = 0;
#endif

  std::string Name;

  switch (Type) {
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

  default:
    llvm_unreachable("Unknown HSAIL parameter type");
  }

  if (ParamName.empty()) {
    Name = DefName;
    Name += utostr(ParamList->size());
  } else {
    Name = ParamName;
  }

  unsigned Index = AllParams.size();
  AllParams[Index] = Param;
  ParamList->push_back(Index);

  addParamName(Name, Index);

  return Index;
}

unsigned HSAILParamManager::addArgumentParam(unsigned Size, const StringRef ParamName) {
  return addParam(HSAIL_PARAM_TYPE_ARGUMENT, Size, ParamName);
}

unsigned HSAILParamManager::addReturnParam(unsigned Size, const StringRef ParamName) {
  return addParam(HSAIL_PARAM_TYPE_RETURN, Size, ParamName);
}

unsigned HSAILParamManager::addCallArgParam(unsigned Size, const StringRef ParamName) {
  return addParam(HSAIL_PARAM_TYPE_CALL_PARAM, Size, ParamName);
}

unsigned HSAILParamManager::addCallRetParam(unsigned Size, const StringRef ParamName) {
  return addParam(HSAIL_PARAM_TYPE_CALL_RET, Size, ParamName);
}

void HSAILParamManager::addParamName(std::string Name, unsigned Index) {
  // malloc arg name string so that it persists through compilation
  char* name = (char*)malloc(Name.length()+1);
  strcpy(name, Name.c_str());
  ParamNames[Index] = name;
}

void HSAILParamManager::addParamType(const Type * pTy, unsigned Index) {
  ParamTypes[Index] = pTy;
}

/// returns a unique argument name for flattened vector component.
std::string HSAILParamManager::mangleArg(Mangler *Mang,
                                         const StringRef argName) {
  if (argName.empty()) return argName;
  SmallString<256> NameStr;
  Mang->getNameWithPrefix(NameStr, argName);
  return NameStr.str();
}
