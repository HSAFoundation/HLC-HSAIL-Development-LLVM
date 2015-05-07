//===-- HSAILOpaqueTypes.cpp - SPIR opaque types --------------------------===//
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
/// \brief This file implements the API for working with SPIR opaque
/// types. This includes images and samplers among other things.
//
//===----------------------------------------------------------------------===//

#include "HSAILOpaqueTypes.h"

#include <llvm/IR/DerivedTypes.h>
#include <llvm/ADT/StringSwitch.h>

using namespace llvm;

/// \brief Check for an opaque type.
OpaqueType llvm::GetOpaqueType(const Type *T) {
  // Handle the degenerate case first.
  if (!T)
    return NotOpaque;

  const StructType *ST = dyn_cast<StructType>(T);

  // If the type is not a struct, check if it is a pointer and try to
  // extract a struct from there.
  if (!ST) {
    const PointerType *PT = dyn_cast<PointerType>(T);

    // Not a struct, not a pointer. It can't be opaque.
    if (!PT)
      return NotOpaque;

    const Type *CT = PT->getElementType();
    ST = dyn_cast<StructType>(CT);
  }

  if (!ST || !ST->isOpaque())
    return NotOpaque;

  return StringSwitch<OpaqueType>(ST->getName())
      .Cases("opencl.image1d_t", "struct._image1d_t", I1D)
      .Cases("opencl.image1d_array_t", "struct._image1d_array_t", I1DA)
      .Cases("opencl.image1d_buffer_t", "struct._image1d_buffer_t", I1DB)
      .Cases("opencl.image2d_t", "struct._image2d_t", I2D)
      .Cases("opencl.image2d_array_t", "struct._image2d_array_t", I2DA)
      .Cases("opencl.image3d_t", "struct._image3d_t", I3D)
      .Cases("opencl.image2d_depth_t", "struct._image2d_depth_t", I2DDepth)
      .Cases("opencl.image2d_array_depth_t", "struct._image2d_array_depth_t",
             I2DADepth)
      // There is no opaque sampler type in SPIR. The i32 in SPIR is
      // lowered to the EDG-stype opaque sampler type.
      .Case("struct._sampler_t", Sampler)
      .Cases("opencl.event_t", "struct._event_t", Event)
      .Case("struct._counter32_t", C32)
      .Case("struct._counter64_t", C64)
      .Case("struct._sema_t", Sema)
      .Case("opencl.reserve_id_t", ReserveId)
      .Case("opencl.clk_event_t", CLKEventT)
      .Case("opencl.queue_t", QueueT)
      .Default(UnknownOpaque);
}
