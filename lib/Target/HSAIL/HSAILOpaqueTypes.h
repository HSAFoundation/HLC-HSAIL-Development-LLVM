//===-- HSAILOpaqueTypes.h - SPIR opaque types ------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
/// \file
///
/// \brief This file declares the API for working with SPIR opaque
/// types. This includes images and samplers among other things.
//
//===----------------------------------------------------------------------===//

#ifndef __HSAIL_OPAQUE_TYPES_H__
#define __HSAIL_OPAQUE_TYPES_H__

namespace llvm {

class Type;

enum OpaqueType {
  NotOpaque,
  I1D,
  I1DA,
  I1DB,
  I2D,
  I2DA,
  I3D,
  I2DDepth,
  I2DADepth,
  C32,
  C64,
  Sema,
  Sampler,
  Event,
  ReserveId,
  CLKEventT,
  QueueT,
  UnknownOpaque
};

OpaqueType GetOpaqueType(const Type *T);

inline bool IsImage(OpaqueType OT) {
  switch (OT) {
  default:
    return false;
  case I1D:
  case I1DA:
  case I1DB:
  case I2D:
  case I2DA:
  case I3D:
  case I2DDepth:
  case I2DADepth:
    return true;
  }
}

inline bool IsImage(const Type *T) { return IsImage(GetOpaqueType(T)); }

inline bool IsSampler(const Type *T) { return GetOpaqueType(T) == Sampler; }
} // end namespace llvm

#endif
