//===- IntrinsicsHSAIL.td - Defines HSAIL intrinsics -------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines all of the HSAIL-specific intrinsics.
//
//===----------------------------------------------------------------------===//

def llvm_hsail_group_ptr_ty : LLVMQualPointerType<llvm_i8_ty, 3>;
def llvm_hsail_flat_ptr_ty : LLVMQualPointerType<llvm_i8_ty, 4>;
def llvm_hsail_kernarg_ptr_ty : LLVMQualPointerType<llvm_i8_ty, 7>;

let TargetPrefix = "hsail" in {

class InstModIntrin_1Op :  Intrinsic<
  [llvm_anyfloat_ty],
  [llvm_i1_ty, // ftz
  llvm_i32_ty, // round
  LLVMMatchType<0>],
  [IntrNoMem]
>;

class InstModIntrin_NoRound_1Op :  Intrinsic<
  [llvm_anyfloat_ty],
  [llvm_i1_ty, // ftz
  LLVMMatchType<0>],
  [IntrNoMem]
>;

class InstModIntrin_2Op :  Intrinsic<
  [llvm_anyfloat_ty],
  [llvm_i1_ty, // ftz
  llvm_i32_ty, // round
  LLVMMatchType<0>,
  LLVMMatchType<0>],
  [IntrNoMem]
>;

class InstModIntrin_NoRound_2Op :  Intrinsic<
  [llvm_anyfloat_ty],
  [llvm_i1_ty, // ftz
  LLVMMatchType<0>,
  LLVMMatchType<0>],
  [IntrNoMem]
>;

class InstModIntrin_3Op :  Intrinsic<
  [llvm_anyfloat_ty],
  [llvm_i1_ty, // ftz
  llvm_i32_ty, // round
  LLVMMatchType<0>,
  LLVMMatchType<0>,
  LLVMMatchType<0>],
  [IntrNoMem]
>;

// 5.2 Integer Arithmetic Instructions
def int_hsail_smulhi : Intrinsic<
  [llvm_anyint_ty], [LLVMMatchType<0>, LLVMMatchType<0>], [IntrNoMem]
>;

def int_hsail_umulhi : Intrinsic<
  [llvm_anyint_ty], [LLVMMatchType<0>, LLVMMatchType<0>], [IntrNoMem]
>;

// 5.4 24-Bit Integer Optimization Instructions
def int_hsail_smad24 : GCCBuiltin<"__builtin_hsail_smad24">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
            [IntrNoMem]>;

def int_hsail_umad24 : GCCBuiltin<"__builtin_hsail_umad24">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
            [IntrNoMem]>;

def int_hsail_smad24hi : GCCBuiltin<"__builtin_hsail_smad24hi">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
            [IntrNoMem]>;

def int_hsail_umad24hi : GCCBuiltin<"__builtin_hsail_umad24hi">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
            [IntrNoMem]>;

def int_hsail_smul24 : GCCBuiltin<"__builtin_hsail_smul24">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty], [IntrNoMem]>;

def int_hsail_umul24 : GCCBuiltin<"__builtin_hsail_umul24">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty], [IntrNoMem]>;

def int_hsail_smul24hi : GCCBuiltin<"__builtin_hsail_smul24hi">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty], [IntrNoMem]>;

def int_hsail_umul24hi : GCCBuiltin<"__builtin_hsail_umul24hi">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty], [IntrNoMem]>;

// 5.7 Bit String Instructions
def int_hsail_sbitextract : Intrinsic<[llvm_anyint_ty],
  [LLVMMatchType<0>, llvm_i32_ty, llvm_i32_ty],
  [IntrNoMem]
>;

def int_hsail_ubitextract : Intrinsic<[llvm_anyint_ty],
  [LLVMMatchType<0>, llvm_i32_ty, llvm_i32_ty],
  [IntrNoMem]
>;

def int_hsail_sbitinsert : Intrinsic<[llvm_anyint_ty],
  [LLVMMatchType<0>, LLVMMatchType<0>, llvm_i32_ty, llvm_i32_ty],
  [IntrNoMem]
>;

def int_hsail_ubitinsert : Intrinsic<[llvm_anyint_ty],
  [LLVMMatchType<0>, LLVMMatchType<0>, llvm_i32_ty, llvm_i32_ty],
  [IntrNoMem]
>;

def int_hsail_bitmask :  Intrinsic<[llvm_anyint_ty],
  [llvm_i32_ty, llvm_i32_ty],
  [IntrNoMem]
>;

def int_hsail_bitrev : Intrinsic<[llvm_anyint_ty],
  [LLVMMatchType<0>],
  [IntrNoMem]
>;

def int_hsail_bitselect : Intrinsic<[llvm_anyint_ty],
  [LLVMMatchType<0>, LLVMMatchType<0>, LLVMMatchType<0>],
  [IntrNoMem]
>;

def int_hsail_sfirstbit : Intrinsic<[llvm_i32_ty],
  [llvm_anyint_ty],
  [IntrNoMem]
>;

def int_hsail_ufirstbit : Intrinsic<[llvm_i32_ty],
  [llvm_anyint_ty],
  [IntrNoMem]
>;

def int_hsail_lastbit : Intrinsic<[llvm_i32_ty],
  [llvm_anyint_ty],
  [IntrNoMem]
>;


// 5.11 Floating-Point Arithmetic Instructions

def int_hsail_fadd : InstModIntrin_2Op;

// llvm.ceil should be preferred
def int_hsail_fceil : InstModIntrin_NoRound_1Op;

def int_hsail_fdiv : InstModIntrin_2Op;

// llvm.floor should be preferred
def int_hsail_ffloor : InstModIntrin_NoRound_1Op;

// llvm.fma should be preferred
def int_hsail_ffma : InstModIntrin_3Op;

// llvm.fract should be preferred
def int_hsail_ffract : InstModIntrin_NoRound_1Op;

// llvm.maxnum should be preferred
def int_hsail_fmax : InstModIntrin_NoRound_2Op;

// llvm.minnum should be preferred
def int_hsail_fmin : InstModIntrin_NoRound_2Op;

def int_hsail_fmul : InstModIntrin_2Op;

// llvm.rint should be preferred
def int_hsail_frint : InstModIntrin_NoRound_1Op;

def int_hsail_fsqrt : InstModIntrin_1Op;
def int_hsail_fsub : InstModIntrin_2Op;

// llvm.trunc should be preferred
def int_hsail_ftrunc : InstModIntrin_NoRound_1Op;


// 5.12 Floating-Point Optimization Instruction

// fmul + fadd or llvm.fmuladd should be preferred
def int_hsail_fmad : InstModIntrin_3Op;

// 5.13 Floating-Point Bit Instructions

def int_hsail_class : Intrinsic<
  [llvm_i1_ty], [llvm_anyfloat_ty, llvm_i32_ty], [IntrNoMem]
>;

// 5.14 Native Floating-Point Instructions
def int_hsail_ncos : Intrinsic<
  [llvm_anyfloat_ty], [LLVMMatchType<0>], [IntrNoMem]
>;

def int_hsail_nexp2 : Intrinsic<
  [llvm_anyfloat_ty], [LLVMMatchType<0>], [IntrNoMem]
>;

def int_hsail_nfma : Intrinsic<
  [llvm_anyfloat_ty],
  [LLVMMatchType<0>, LLVMMatchType<0>, LLVMMatchType<0>],
  [IntrNoMem]
>;

def int_hsail_nlog2 : Intrinsic<
  [llvm_anyfloat_ty], [LLVMMatchType<0>], [IntrNoMem]
>;

def int_hsail_nrcp : Intrinsic<
  [llvm_anyfloat_ty], [LLVMMatchType<0>], [IntrNoMem]
>;

// Prefer llvm.sqrt
def int_hsail_nrsqrt : Intrinsic<
  [llvm_anyfloat_ty], [LLVMMatchType<0>], [IntrNoMem]
>;

def int_hsail_nsin : Intrinsic<
  [llvm_anyfloat_ty], [LLVMMatchType<0>], [IntrNoMem]
>;

// Prefer llvm.sqrt
def int_hsail_nsqrt : Intrinsic<
  [llvm_anyfloat_ty], [LLVMMatchType<0>], [IntrNoMem]
>;

// 5.15 Multimedia Instructions
def int_hsail_bitalign : GCCBuiltin<"__builtin_hsail_bitalign">,
  Intrinsic<[llvm_i32_ty],
            [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
            [IntrNoMem]
>;

def int_hsail_bytealign : GCCBuiltin<"__builtin_hsail_bytealign">,
  Intrinsic<[llvm_i32_ty],
            [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
            [IntrNoMem]
>;

def int_hsail_lerp : GCCBuiltin<"__builtin_hsail_lerp">,
  Intrinsic<[llvm_i32_ty],
            [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
            [IntrNoMem]
>;

def int_hsail_packcvt : GCCBuiltin<"__builtin_hsail_packcvt">,
  Intrinsic<[llvm_i32_ty],
            [llvm_float_ty, llvm_float_ty,
            llvm_float_ty, llvm_float_ty],
            [IntrNoMem]
>;

def int_hsail_unpackcvt : GCCBuiltin<"__builtin_hsail_unpackcvt">,
  Intrinsic<[llvm_float_ty], [llvm_i32_ty, llvm_i32_ty], [IntrNoMem]>;

def int_hsail_sad_u32_u32 :
  GCCBuiltin<"__builtin_hsail_sad_u32_u32">,
  Intrinsic<[llvm_i32_ty],
            [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
            [IntrNoMem]
>;

def int_hsail_sad_u32_u16x2 :
  GCCBuiltin<"__builtin_hsail_sad_u32_u16x2">,
  Intrinsic<[llvm_i32_ty],
            [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
            [IntrNoMem]
>;

def int_hsail_sad_u32_u8x4 :
  GCCBuiltin<"__builtin_hsail_sad_u32_u8x4">,
  Intrinsic<[llvm_i32_ty],
            [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
            [IntrNoMem]
>;

def int_hsail_sadhi : GCCBuiltin<"__builtin_hsail_sadhi">,
  Intrinsic<[llvm_i32_ty],
            [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
            [IntrNoMem]
>;

// 5.16 Segment Checking (segmentp) Instruction
def int_hsail_segmentp : GCCBuiltin<"__builtin_hsail_segmentp">,
  Intrinsic<
    [llvm_i1_ty],
    [llvm_i32_ty, llvm_i1_ty, llvm_hsail_flat_ptr_ty],
    [IntrNoMem]>;

// 6.9 Memory Fence (memfence) Instruction
def int_hsail_memfence : GCCBuiltin<"__builtin_hsail_memfence">,
  Intrinsic<[], [llvm_i32_ty, llvm_i32_ty], []>;

// 7.6 Image Fence (imagefence) Instruction;
// FIXME: Probably doesn't really need noduplicate or convergent
def int_hsail_imagefence : GCCBuiltin<"__builtin_hsail_imagefence">,
  Intrinsic<[], [], []>;

// 9.1 Barrier Instructions
def int_hsail_barrier : GCCBuiltin<"__builtin_hsail_barrier">,
  Intrinsic<[], [llvm_i32_ty], [IntrNoDuplicate, IntrConvergent]>;

def int_hsail_wavebarrier : GCCBuiltin<"__builtin_hsail_wavebarrier">,
  Intrinsic<[], [], [IntrNoDuplicate, IntrConvergent]>;


// 9.4 Cross-Lane Instructions
def int_hsail_activelanecount :
  GCCBuiltin<"__builtin_hsail_activelanecount">,
  Intrinsic<
    [llvm_i32_ty],
    [llvm_i32_ty, llvm_i1_ty],
    [IntrReadMem, IntrConvergent] // XXX - IntrReadMem?
>;

def int_hsail_activelaneid :
  GCCBuiltin<"__builtin_hsail_activelaneid">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty], [IntrReadMem]>;

def int_hsail_activelanemask : Intrinsic<
  [llvm_i64_ty, llvm_i64_ty, llvm_i64_ty, llvm_i64_ty],
  [llvm_i32_ty,  // width
  llvm_i1_ty],   // src
  [IntrReadMem, IntrConvergent]
>;

def int_hsail_activelanepermute : Intrinsic<
  [llvm_anyint_ty],
  [llvm_i32_ty,      // width
   LLVMMatchType<0>, // src
   llvm_i32_ty,      // laneId
   LLVMMatchType<0>, // identity
   llvm_i1_ty],      // useIdentity
   [IntrConvergent]
>;

// 11.1 Kernel Dispatch Packet Instructions
def int_hsail_currentworkgroupsize :
  GCCBuiltin<"__builtin_hsail_currentworkgroupsize">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty], [IntrNoMem]>;

def int_hsail_currentworkitemflatid :
  GCCBuiltin<"__builtin_hsail_currentworkitemflatid">,
  Intrinsic<[llvm_i32_ty], [], [IntrNoMem]>;

def int_hsail_dim : GCCBuiltin<"__builtin_hsail_dim">,
  Intrinsic<[llvm_i32_ty], [], [IntrNoMem]>;

def int_hsail_gridgroups : GCCBuiltin<"__builtin_hsail_gridgroups">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty], [IntrNoMem]>;

def int_hsail_gridsize :
  Intrinsic<[llvm_anyint_ty], [llvm_i32_ty], [IntrNoMem]>;

// int_hsail_packetcompletionsig
def int_hsail_packetid : GCCBuiltin<"__builtin_hsail_packetid">,
  Intrinsic<[llvm_i64_ty], [], [IntrNoMem]>;

def int_hsail_workgroupid : GCCBuiltin<"__builtin_hsail_workgroupid">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty], [IntrNoMem]>;

def int_hsail_workgroupsize :
  GCCBuiltin<"__builtin_hsail_workgroupsize">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty], [IntrNoMem]>;

def int_hsail_workitemabsid :
  Intrinsic<[llvm_anyint_ty], [llvm_i32_ty], [IntrNoMem]>;

def int_hsail_workitemflatabsid :
  Intrinsic<[llvm_anyint_ty], [], [IntrNoMem]>;

def int_hsail_workitemflatid :
  GCCBuiltin<"__builtin_hsail_workitemflatid">,
  Intrinsic<[llvm_i32_ty], [], [IntrNoMem]>;

def int_hsail_workitemid : GCCBuiltin<"__builtin_hsail_workitemid">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty], [IntrNoMem]>;

// 11.4 Miscellaneous Instructions
def int_hsail_clock : GCCBuiltin<"__builtin_hsail_clock">,
  Intrinsic<[llvm_i64_ty], [], []>;

def int_hsail_cuid : GCCBuiltin<"__builtin_hsail_cuid">,
  Intrinsic<[llvm_i32_ty], [], [IntrNoMem]>;

// debugtrap

def int_hsail_groupbaseptr :
  GCCBuiltin<"__builtin_hsail_groupbaseptr">,
  Intrinsic<[llvm_hsail_group_ptr_ty], [], [IntrNoMem]>;

def int_hsail_kernargbaseptr :
  GCCBuiltin<"__builtin_hsail_kernargbaseptr">,
  Intrinsic<[llvm_hsail_kernarg_ptr_ty], [], [IntrNoMem]>;

def int_hsail_laneid : GCCBuiltin<"__builtin_hsail_laneid">,
  Intrinsic<[llvm_i32_ty], [], [IntrNoMem]>;

def int_hsail_maxcuid : GCCBuiltin<"__builtin_hsail_maxcuid">,
  Intrinsic<[llvm_i32_ty], [], [IntrNoMem]>;

def int_hsail_maxwaveid : GCCBuiltin<"__builtin_hsail_maxwaveid">,
  Intrinsic<[llvm_i32_ty], [], [IntrNoMem]>;

// nop
// nullptr

def int_hsail_waveid : GCCBuiltin<"__builtin_hsail_waveid">,
  Intrinsic<[llvm_i32_ty], [], [IntrNoMem]>;


// GCN extensions
def int_hsail_gcn_fldexp : Intrinsic<
  [llvm_anyfloat_ty], [LLVMMatchType<0>, LLVMMatchType<0>], [IntrNoMem]
>;

def int_hsail_gcn_bfm : GCCBuiltin<"__builtin_hsail_gcn_bfm">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty], [IntrNoMem]>;

def int_hsail_gcn_msad : GCCBuiltin<"__builtin_hsail_gcn_msad">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
            [IntrNoMem]>;

def int_hsail_gcn_qsad : GCCBuiltin<"__builtin_hsail_gcn_qsad">,
  Intrinsic<[llvm_i64_ty],
            [llvm_i64_ty, llvm_i64_ty, llvm_i64_ty], [IntrNoMem]>;

def int_hsail_gcn_mqsad: GCCBuiltin<"__builtin_hsail_gcn_mqsad">,
  Intrinsic<[llvm_i64_ty],
            [llvm_i64_ty, llvm_i32_ty, llvm_i64_ty], [IntrNoMem]>;

// def int_hsail_gcn_mqsad4

def int_hsail_gcn_sadw : GCCBuiltin<"__builtin_hsail_gcn_sadw">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
            [IntrNoMem]>;

def int_hsail_gcn_sadd : GCCBuiltin<"__builtin_hsail_gcn_sadd">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
            [IntrNoMem]>;

// def int_hsail_gcn_consume
// def int_hsail_gcn_append

} // End TargetPrefix = "hsail"
