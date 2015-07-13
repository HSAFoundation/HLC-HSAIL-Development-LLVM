//===------------ HSAILIntrinsicInfo.h - HSAILIntrinsic Info ----*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file describes the target intrinsic instructions to the code generator.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_HSAIL_HSAILINTRINSICINFO_H
#define LLVM_LIB_TARGET_HSAIL_HSAILINTRINSICINFO_H

#include "llvm/IR/Intrinsics.h"
#include "llvm/Target/TargetIntrinsicInfo.h"

namespace llvm {

class Function;
class Module;
class Type;

class HSAILTargetMachine;

namespace HSAILIntrinsic {
enum ID {
  last_non_HSAIL_intrinsic = Intrinsic::num_intrinsics - 1,
#define GET_INTRINSIC_ENUM_VALUES
#include "HSAILGenIntrinsics.inc"
#undef GET_INTRINSIC_ENUM_VALUES
  ,
  num_HSAIL_intrinsics
};
}

//---------------------------------------------------------------------------
///
/// HSAILIntrinsicInfo - Interface to description of machine intrinsic set
///
class HSAILIntrinsicInfo : public TargetIntrinsicInfo {
public:
  HSAILIntrinsicInfo(HSAILTargetMachine *tm);

  std::string getName(unsigned IID, Type **Tys = nullptr,
                      unsigned numTys = 0) const override;

  unsigned lookupName(const char *Name, unsigned Len) const override;

  bool isOverloaded(unsigned IID) const override;

  Function *getDeclaration(Module *M, unsigned ID, Type **Tys = nullptr,
                           unsigned numTys = 0) const override;

  static bool isReadImage(llvm::HSAILIntrinsic::ID intr);
  static bool isLoadImage(llvm::HSAILIntrinsic::ID intr);
};

} // End llvm namespace

#endif
