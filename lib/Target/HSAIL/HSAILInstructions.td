//===------------------------------------------------------*- tablegen -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

////////////////////////////////////////////////////////////////////////////////
// All basic int and fp arithmetic instructions, shifts, bit manipulation,
// moves, cmoves and multimedia like unpack.
// If we have full support of multimedia we would need to extract latter into a
// separate file.
include "HSAILArithmetic.td"

////////////////////////////////////////////////////////////////////////////////
// All comparisons and testing, including class_f32|64
include "HSAILComparisons.td"

////////////////////////////////////////////////////////////////////////////////
// All atomic operations
include "HSAILAtomics.td"

////////////////////////////////////////////////////////////////////////////////
// Special HSAIL operations like NDRange queries, barriers, syncs etc
include "HSAILSpecial.td"

////////////////////////////////////////////////////////////////////////////////
// All control transfer instructions including call, ret and branches
include "HSAILControlFlow.td"

////////////////////////////////////////////////////////////////////////////////
// All conversions including bitcasts resulting in plain moves
include "HSAILConversions.td"

////////////////////////////////////////////////////////////////////////////////
// All loads and stores including kernarg and arg operations, argscopes and
// params. Image and sampler parameter manipulation operations are also here.
// stof and ftos operations are here as well.
include "HSAILLoadStore.td"

////////////////////////////////////////////////////////////////////////////////
// All image operations except image parameters handling
include "HSAILImages.td"

////////////////////////////////////////////////////////////////////////////////
// Fused opcodes folding a complex dag into a single instruction or a short
// instruction sequence, like fma or rsqrt.
// This file is for optimization purposes. Its inclusion is not required for
// valid code generation. For example, rsqrt is defined twice - first time in
// the HSAILArithmetic.td to be used with intrinsic expansion and second time
// here, but with a pattern folding div and sqrt into a single instruction.
// For that reason HSAILFusion.td is always last, so no other pattern would
// accidentally refer any of its opcodes.
include "HSAILFusion.td"
