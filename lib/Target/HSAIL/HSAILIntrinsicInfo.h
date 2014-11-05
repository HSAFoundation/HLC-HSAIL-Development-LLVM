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

#ifndef _HSAIL_INTRINSIC_INFO_H_
#define _HSAIL_INTRINSIC_INFO_H_

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
    , num_HSAIL_intrinsics
  };
}

//---------------------------------------------------------------------------
///
/// HSAILIntrinsicInfo - Interface to description of machine intrinsic set
///
class HSAILIntrinsicInfo : public TargetIntrinsicInfo {
public:
  HSAILIntrinsicInfo(HSAILTargetMachine *tm);

  /// Return the name of a target intrinsic, e.g. "llvm.bfin.ssync".
  /// The Tys and numTys parameters are for intrinsics with overloaded types
  /// (e.g., those using iAny or fAny). For a declaration for an overloaded
  /// intrinsic, Tys should point to an array of numTys pointers to Type,
  /// and must provide exactly one type for each overloaded type in the
  /// intrinsic.
  virtual std::string
  getName(unsigned IID,  Type **Tys = 0, unsigned int numTys = 0) const;

  /// Look up target intrinsic by name. Return intrinsic ID or 0 for unknown
  /// names.
  virtual unsigned
  lookupName(const char *Name, unsigned Len) const;

  /// Returns true if the intrinsic can be overloaded.
  virtual bool
  isOverloaded(unsigned IID) const;

  /// Create or insert an LLVM Function declaration for an intrinsic,
  /// and return it. The Tys and numTys are for intrinsics with overloaded
  /// types. See above for more information.

  virtual Function*
  getDeclaration(Module *M,
                 unsigned ID,
                 Type ** Tys = 0,
                 unsigned int numTys = 0) const;

  static bool isReadImage(llvm::HSAILIntrinsic::ID intr);
  static bool isLoadImage(llvm::HSAILIntrinsic::ID intr);
  static bool isCrossLane(llvm::HSAILIntrinsic::ID intr);

};

} // End llvm namespace

#endif
