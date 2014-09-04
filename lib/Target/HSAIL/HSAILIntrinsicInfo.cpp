//===- HSAILIntrinsicInfo.cpp - HSAIL Intrinsic Information -----*- C++ -*-===//
//
// This file contains the HSAIL Implementation of the IntrinsicInfo class.
//
//===----------------------------------------------------------------------===//

#include "HSAIL.h"
#include "HSAILIntrinsicInfo.h"
#include "HSAILTargetMachine.h"
#include "llvm/DerivedTypes.h"
#include "llvm/Intrinsics.h"
#include "llvm/Module.h"
#include <cstring>
using namespace llvm;

#define GET_LLVM_INTRINSIC_FOR_GCC_BUILTIN
#include "HSAILGenIntrinsics.inc"
#undef GET_LLVM_INTRINSIC_FOR_GCC_BUILTIN

bool HSAILIntrinsicInfo::isReadImage(HSAILIntrinsic::ID intr)
{
  switch (intr) {
  default: return false;

  case HSAILIntrinsic::HSAIL_rd_imgf_1d_f32:
  case HSAILIntrinsic::HSAIL_rd_imgf_1d_s32:
  case HSAILIntrinsic::HSAIL_rd_imgf_1da_f32:
  case HSAILIntrinsic::HSAIL_rd_imgf_1da_s32:
  case HSAILIntrinsic::HSAIL_rd_imgf_2d_f32:
  case HSAILIntrinsic::HSAIL_rd_imgf_2d_s32:
  case HSAILIntrinsic::HSAIL_rd_imgf_2da_f32:
  case HSAILIntrinsic::HSAIL_rd_imgf_2da_s32:
  case HSAILIntrinsic::HSAIL_rd_imgf_3d_f32:
  case HSAILIntrinsic::HSAIL_rd_imgf_3d_s32:
  case HSAILIntrinsic::HSAIL_rd_imgi_1d_f32:
  case HSAILIntrinsic::HSAIL_rd_imgi_1d_s32:
  case HSAILIntrinsic::HSAIL_rd_imgi_1da_f32:
  case HSAILIntrinsic::HSAIL_rd_imgi_1da_s32:
  case HSAILIntrinsic::HSAIL_rd_imgi_2d_f32:
  case HSAILIntrinsic::HSAIL_rd_imgi_2d_s32:
  case HSAILIntrinsic::HSAIL_rd_imgi_2da_f32:
  case HSAILIntrinsic::HSAIL_rd_imgi_2da_s32:
  case HSAILIntrinsic::HSAIL_rd_imgi_3d_f32:
  case HSAILIntrinsic::HSAIL_rd_imgi_3d_s32:
  case HSAILIntrinsic::HSAIL_rd_imgui_1d_f32:
  case HSAILIntrinsic::HSAIL_rd_imgui_1d_s32:
  case HSAILIntrinsic::HSAIL_rd_imgui_1da_f32:
  case HSAILIntrinsic::HSAIL_rd_imgui_1da_s32:
  case HSAILIntrinsic::HSAIL_rd_imgui_2d_f32:
  case HSAILIntrinsic::HSAIL_rd_imgui_2d_s32:
  case HSAILIntrinsic::HSAIL_rd_imgui_2da_f32:
  case HSAILIntrinsic::HSAIL_rd_imgui_2da_s32:
  case HSAILIntrinsic::HSAIL_rd_imgui_3d_f32:
  case HSAILIntrinsic::HSAIL_rd_imgui_3d_s32:
  case HSAILIntrinsic::HSAIL_rd_imgf_2ddepth_f32:
  case HSAILIntrinsic::HSAIL_rd_imgf_2ddepth_s32:
  case HSAILIntrinsic::HSAIL_rd_imgf_2dadepth_f32:
  case HSAILIntrinsic::HSAIL_rd_imgf_2dadepth_s32:
    return true;
  }
}
    
bool HSAILIntrinsicInfo::isLoadImage(HSAILIntrinsic::ID intr)
{
  switch (intr) {
  default: return false;

  case HSAILIntrinsic::HSAIL_ld_imgf_1d_u32:
  case HSAILIntrinsic::HSAIL_ld_imgf_1da_u32:
  case HSAILIntrinsic::HSAIL_ld_imgf_1db_u32:
  case HSAILIntrinsic::HSAIL_ld_imgf_2d_u32:
  case HSAILIntrinsic::HSAIL_ld_imgf_2da_u32:
  case HSAILIntrinsic::HSAIL_ld_imgf_3d_u32:
  case HSAILIntrinsic::HSAIL_ld_imgi_1d_u32:
  case HSAILIntrinsic::HSAIL_ld_imgi_1da_u32:
  case HSAILIntrinsic::HSAIL_ld_imgi_1db_u32:
  case HSAILIntrinsic::HSAIL_ld_imgi_2d_u32:
  case HSAILIntrinsic::HSAIL_ld_imgi_2da_u32:
  case HSAILIntrinsic::HSAIL_ld_imgi_3d_u32:
  case HSAILIntrinsic::HSAIL_ld_imgui_1d_u32:
  case HSAILIntrinsic::HSAIL_ld_imgui_1da_u32:
  case HSAILIntrinsic::HSAIL_ld_imgui_1db_u32:
  case HSAILIntrinsic::HSAIL_ld_imgui_2d_u32:
  case HSAILIntrinsic::HSAIL_ld_imgui_2da_u32:
  case HSAILIntrinsic::HSAIL_ld_imgui_3d_u32:
  case HSAILIntrinsic::HSAIL_ld_imgf_2ddepth_u32:
  case HSAILIntrinsic::HSAIL_ld_imgf_2dadepth_u32:
    return true;
  }
}

bool HSAILIntrinsicInfo::isCrossLane(HSAILIntrinsic::ID intr)
{
  switch (intr) {
    default: return false;
    case HSAILIntrinsic::HSAIL_activelanemask_v4_b64_b1:
    case HSAILIntrinsic::HSAIL_activelanemask_v4_width_b64_b1:
	return true;
  }
}

HSAILIntrinsicInfo::HSAILIntrinsicInfo(HSAILTargetMachine *tm)
  : TargetIntrinsicInfo(), mTM(tm) {}

std::string
HSAILIntrinsicInfo::getName(unsigned int IntrID,
                            Type **Tys,
                            unsigned int numTys) const
{
  static const char* const names[] = {
#define GET_INTRINSIC_NAME_TABLE
#include "HSAILGenIntrinsics.inc"
#undef GET_INTRINSIC_NAME_TABLE
  };

  if (IntrID < Intrinsic::num_intrinsics) {
    return 0;
  }
  assert(IntrID < HSAILIntrinsic::num_HSAIL_intrinsics
         && "Invalid intrinsic ID");

  std::string Result(names[IntrID - Intrinsic::num_intrinsics]);
  return Result;
}

unsigned int
HSAILIntrinsicInfo::lookupName(const char *Name,
                               unsigned int Len) const
{
#define GET_FUNCTION_RECOGNIZER
#include "HSAILGenIntrinsics.inc"
#undef GET_FUNCTION_RECOGNIZER
  HSAILIntrinsic::ID IntrinsicID;
  // Translate "__atom_*" intrinsic name to "__atomic_*" so we don't need to
  // support both flavors. The "__atom_*" variants come from OCL 1.0 32-bit 
  // atomics and OCL Extension 1.2 64-bit atomics.
  if (strncmp(Name, "__atom_", 7) == 0) {
    // Translate "__atom_" to "__atomic_"
    std::string atomicName = Name;
    atomicName.insert(6, "ic");
    IntrinsicID = getIntrinsicForGCCBuiltin("HSAIL", atomicName.c_str());
  } else {
    IntrinsicID = getIntrinsicForGCCBuiltin("HSAIL", Name);
  }

  //  errs() << "InstrinsicID: " << Name << "\t" << IntrinsicID << "\n";

  if (IntrinsicID != (HSAILIntrinsic::ID)Intrinsic::not_intrinsic) {
    return IntrinsicID;
  }
  return 0;
}

bool
HSAILIntrinsicInfo::isOverloaded(unsigned IntrID) const {
  if (!IntrID)
    return false;

  unsigned id = IntrID - Intrinsic::num_intrinsics + 1;
#define GET_INTRINSIC_OVERLOAD_TABLE
#include "HSAILGenIntrinsics.inc"
#undef GET_INTRINSIC_OVERLOAD_TABLE
}

Function*
HSAILIntrinsicInfo::getDeclaration(Module *M,
                                   unsigned IntrID,
                                   Type ** Tys,
                                   unsigned int numTys) const
{
  llvm_unreachable("Not implemented");

  return NULL;
}
