//===- HSAILParamManager.h - kernel/function arguments -----------*- C++ -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the HSAILParamManager class, which manages all defined .param
// variables for a particular function.
//
//===----------------------------------------------------------------------===//

#ifndef HSAIL_PARAM_MANAGER_H
#define HSAIL_PARAM_MANAGER_H

#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Target/Mangler.h"
#include "llvm/IR/Type.h"

namespace llvm {

/// HSAILParamManager - This class manages all parameter variables defined for a
/// particular function.
class HSAILParamManager {
private:

  /// HSAILParamType - Type of a kernarg/arg/call param variable
  enum HSAILParamType {
    HSAIL_PARAM_TYPE_ARGUMENT,
    HSAIL_PARAM_TYPE_RETURN,
    HSAIL_PARAM_TYPE_CALL_PARAM,
    HSAIL_PARAM_TYPE_CALL_RET
  };

  /// HSAILParam - Definition of a HSAIL kernarg/arg variable
  struct HSAILParam {
    HSAILParamType  Type;
    unsigned      Size;
  };

  DenseMap<unsigned, HSAILParam> AllParams;
  DenseMap<unsigned, char*> ParamNames;
  DenseMap<unsigned, const Type *> ParamTypes;
  SmallVector<unsigned, 4> ArgumentParams;
  SmallVector<unsigned, 4> ReturnParams;
  SmallVector<unsigned, 4> CallArgParams;
  SmallVector<unsigned, 4> CallRetParams;

  unsigned addParam(HSAILParamType Type, unsigned Size,
    const StringRef ParamName);

public:

  typedef DenseMap<unsigned, char*>::const_iterator names_iterator;
  typedef SmallVector<unsigned, 4>::const_iterator param_iterator;

  HSAILParamManager();
  ~HSAILParamManager();

  param_iterator arg_begin() const { return ArgumentParams.begin(); }
  param_iterator arg_end() const { return ArgumentParams.end(); }
  param_iterator ret_begin() const { return ReturnParams.begin(); }
  param_iterator ret_end() const { return ReturnParams.end(); }
  param_iterator call_arg_begin() const { return CallArgParams.begin(); }
  param_iterator call_arg_end() const { return CallArgParams.end(); }
  param_iterator call_ret_begin() const { return CallRetParams.begin(); }
  param_iterator call_ret_end() const { return CallRetParams.end(); }

  /// addArgumentParam - Returns a new variable used as an argument.
  unsigned addArgumentParam(unsigned Size, const StringRef ParamName);

  /// addReturnParam - Returns a new variable used as a return argument.
  unsigned addReturnParam(unsigned Size, const StringRef ParamName);

  /// addCallArgParam - Returns a new variable used as a call actual argument.
  unsigned addCallArgParam(unsigned Size, const StringRef ParamName);

  /// addCallRetParam - Returns a new variable used as a call actual return
  /// argument.
  unsigned addCallRetParam(unsigned Size, const StringRef ParamName);

  /// addParamName - Saves a persistent copy of Param Name
  void addParamName(std::string Name, unsigned Index);

  /// addParamType - Saves the type of the parameter
  void addParamType(const Type * pTy, unsigned Index);

  /// getParamName - Returns the name of the parameter as a string.
  const char* getParamName(unsigned Param) const {
    assert(AllParams.count(Param) == 1 && "Param has not been defined!");
    return ParamNames.find(Param)->second;
  }

  /// getParamType - Returns the type of the parameter
  const Type * getParamType(unsigned Param) const {
    assert(AllParams.count(Param) == 1 && "Param has not been defined!");
    return ParamTypes.find(Param)->second;
  }

  /// getParamSize - Returns the size of the parameter in bits.
  unsigned getParamSize(unsigned Param) const {
    assert(AllParams.count(Param) == 1 && "Param has not been defined!");
    return AllParams.find(Param)->second.Size;
  }

  /// returns a unique argument name.
  static std::string mangleArg(Mangler *Mang, const StringRef argName);

};

}

#endif

