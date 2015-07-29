//===------------------------------------------------------*- tablegen -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines all of the hsail-specific intrinsics.
//
//===----------------------------------------------------------------------===//

let TargetPrefix = "HSAIL", isTarget = 1 in {

// HSAIL intrinsics
def int_HSAIL_workitemid_flat : GCCBuiltin<"__hsail_workitemid_flat">,
  Intrinsic<[llvm_i32_ty], [], [IntrNoMem]
>;

def int_HSAIL_workitemid_flatabs : GCCBuiltin<"__hsail_workitemid_flatabs">,
  Intrinsic<[llvm_i32_ty], [], [IntrNoMem]
>;

def int_HSAIL_get_lane_id : GCCBuiltin<"__hsail_get_lane_id">,
  Intrinsic<[llvm_i32_ty], [], [IntrNoMem]
>;

def int_HSAIL_get_dynwave_id : GCCBuiltin<"__hsail_get_dynwave_id">,
  Intrinsic<[llvm_i32_ty], [], [IntrNoMem]
>;

def int_HSAIL_get_maxdynwave_id : GCCBuiltin<"__hsail_get_maxdynwave_id">,
  Intrinsic<[llvm_i32_ty], [], [IntrNoMem]
>;

def int_HSAIL_get_clock : GCCBuiltin<"__hsail_get_clock">,
  Intrinsic<[llvm_i64_ty], [], []
>;

def int_HSAIL_get_cu : GCCBuiltin<"__hsail_get_cu">,
  Intrinsic<[llvm_i32_ty], [], []
>;

// HSAIL Cross-Lane Intrinsics
// For OCL 2.0 1/32/64-bit built-ins
def int_HSAIL_activelaneid_u32 : GCCBuiltin<"__hsail_activelaneid_u32">,
  Intrinsic<[llvm_i32_ty], [], []
>;

def int_HSAIL_activelaneid_width_u32 :
  GCCBuiltin<"__hsail_activelaneid_wavewidth_u32">,
  Intrinsic<[llvm_i32_ty], [], []
>;

def int_HSAIL_activelanecount_u32_b1 :
  GCCBuiltin<"__hsail_activelanecount_u32_b1">,
  Intrinsic<[llvm_i32_ty], [llvm_i1_ty], []
>;

def int_HSAIL_activelanecount_width_u32_b1 :
  GCCBuiltin<"__hsail_activelanecount_wavewidth_u32_b1">,
  Intrinsic<[llvm_i32_ty], [llvm_i1_ty], []
>;

def int_HSAIL_activelanepermute_b32 :
  GCCBuiltin<"__hsail_activelanepermute_b32">,
  Intrinsic<[llvm_i32_ty],
    [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i1_ty], []
>;

def int_HSAIL_activelanepermute_width_b32 :
  GCCBuiltin<"__hsail_activelanepermute_wavewidth_b32">,
  Intrinsic<[llvm_i32_ty],
    [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i1_ty], []
>;

def int_HSAIL_activelanemask_v4_b64_b1 :
  GCCBuiltin<"__hsail_activelanemask_v4_b64_b1">,
  Intrinsic<[llvm_i64_ty, llvm_i64_ty, llvm_i64_ty, llvm_i64_ty],
    [llvm_i1_ty], []
>;

def int_HSAIL_activelanemask_v4_width_b64_b1 :
  GCCBuiltin<"__hsail_activelanemask_v4_wavewidth_b64_b1">,
  Intrinsic<[llvm_i64_ty, llvm_i64_ty, llvm_i64_ty, llvm_i64_ty],
    [llvm_i1_ty], []
>;


// For OCL 2.0 64-bit built-ins

def int_HSAIL_activelanepermute_b64 :
  GCCBuiltin< "__hsail_activelanepermute_b64">,
  Intrinsic<[llvm_i64_ty],
  [llvm_i64_ty, llvm_i32_ty, llvm_i64_ty, llvm_i1_ty], []
>;

def int_HSAIL_activelanepermute_width_b64 :
  GCCBuiltin<"__hsail_activelanepermute_wavewidth_b64">,
  Intrinsic<[llvm_i64_ty],
    [llvm_i64_ty, llvm_i32_ty, llvm_i64_ty, llvm_i1_ty], []
>;

// Intrinsics for OpenCL workitem built-ins (OCL 1.2 6.12.2)
def int_HSAIL_get_work_dim : GCCBuiltin<"__hsail_get_work_dim">,
  Intrinsic<[llvm_i32_ty], [], [IntrNoMem]
>;

def int_HSAIL_get_global_id : GCCBuiltin<"__hsail_get_global_id">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_get_group_id : GCCBuiltin<"__hsail_get_group_id">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_get_local_id : GCCBuiltin<"__hsail_get_local_id">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_workgroup_size : GCCBuiltin<"__hsail_workgroup_size">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_currentworkgroup_size :
  GCCBuiltin<"__hsail_currentworkgroup_size">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_get_global_size : GCCBuiltin<"__hsail_get_global_size">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_get_num_groups : GCCBuiltin<"__hsail_get_num_groups">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty], [IntrNoMem]
>;

// Intrinsics for OpenCL math built-ins (OCL 1.2 6.12.2)
def int_HSAIL_copysign_f32 : GCCBuiltin<"__hsail_copysign_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty, llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_copysign_f64 : GCCBuiltin<"__hsail_copysign_f64">,
  Intrinsic<[llvm_double_ty], [llvm_double_ty, llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_ncos_f32 : GCCBuiltin<"__hsail_ncos_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_nexp2_f32 : GCCBuiltin<"__hsail_nexp2_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_abs_f32 : GCCBuiltin<"__hsail_abs_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_abs_f64 : GCCBuiltin<"__hsail_abs_f64">,
  Intrinsic<[llvm_double_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_fma_f32 : GCCBuiltin<"__hsail_fma_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty, llvm_float_ty, llvm_float_ty], [IntrNoMem]
>;
def int_HSAIL_fma_f64 : GCCBuiltin<"__hsail_fma_f64">,
  Intrinsic<[llvm_double_ty], [llvm_double_ty, llvm_double_ty, llvm_double_ty], [IntrNoMem]>;

def int_HSAIL_nfma_f32 : GCCBuiltin<"__hsail_nfma_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty, llvm_float_ty, llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_nfma_f64 : GCCBuiltin<"__hsail_nfma_f64">,
  Intrinsic<[llvm_double_ty], [llvm_double_ty, llvm_double_ty, llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_nlog2_f32 : GCCBuiltin<"__hsail_nlog2_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_nsin_f32 : GCCBuiltin<"__hsail_nsin_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_nsqrt_f32 : GCCBuiltin<"__hsail_nsqrt_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_nsqrt_f64 : GCCBuiltin<"__hsail_nsqrt_f64">,
  Intrinsic<[llvm_double_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_sqrt_ftz_f32 : GCCBuiltin<"__hsail_sqrt_ftz_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_sqrt_f64 : GCCBuiltin<"__hsail_sqrt_f64">,
  Intrinsic<[llvm_double_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_nrsqrt_f32 : GCCBuiltin<"__hsail_nrsqrt_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_nrsqrt_f64 : GCCBuiltin<"__hsail_nrsqrt_f64">,
  Intrinsic<[llvm_double_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_nrcp_f32 : GCCBuiltin<"__hsail_nrcp_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_nrcp_f64 : GCCBuiltin<"__hsail_nrcp_f64">,
  Intrinsic<[llvm_double_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_ceil_f32 : GCCBuiltin<"__hsail_ceil_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_ceil_f64 : GCCBuiltin<"__hsail_ceil_f64">,
  Intrinsic<[llvm_double_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_floor_f32 : GCCBuiltin<"__hsail_floor_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_floor_f64 : GCCBuiltin<"__hsail_floor_f64">,
  Intrinsic<[llvm_double_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_rnd_f32 : GCCBuiltin<"__hsail_round_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_rnd_f64 : GCCBuiltin<"__hsail_round_f64">,
  Intrinsic<[llvm_double_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_trunc_f32 : GCCBuiltin<"__hsail_trunc_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_trunc_f64 : GCCBuiltin<"__hsail_trunc_f64">,
  Intrinsic<[llvm_double_ty], [llvm_double_ty], [IntrNoMem]
>;

// Intrinsics for OpenCL integer built-ins (OCL 1.2 6.12.3)
def int_HSAIL_max_u32 : GCCBuiltin<"__hsail_max_u32">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_max_s32 : GCCBuiltin<"__hsail_max_s32">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_max_u64 : GCCBuiltin<"__hsail_max_u64">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], [IntrNoMem]
>;

def int_HSAIL_max_s64 : GCCBuiltin<"__hsail_max_s64">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], [IntrNoMem]
>;

def int_HSAIL_max_f32 : GCCBuiltin<"__hsail_max_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty, llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_max_f64 : GCCBuiltin<"__hsail_max_f64">,
  Intrinsic<[llvm_double_ty], [llvm_double_ty, llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_gcn_max_f32 : GCCBuiltin<"__gcn_max_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty, llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_gcn_max_f64 : GCCBuiltin<"__gcn_max_f64">,
  Intrinsic<[llvm_double_ty], [llvm_double_ty, llvm_double_ty], [IntrNoMem]
>;

// FIXME: min / max intrinsics should be removed.
def int_HSAIL_min_u32 : GCCBuiltin<"__hsail_min_u32">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_min_s32 : GCCBuiltin<"__hsail_min_s32">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_min_u64 : GCCBuiltin<"__hsail_min_u64">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], [IntrNoMem]
>;

def int_HSAIL_min_s64 : GCCBuiltin<"__hsail_min_s64">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], [IntrNoMem]
>;

def int_HSAIL_min_f32 : GCCBuiltin<"__hsail_min_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty, llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_min_f64 : GCCBuiltin<"__hsail_min_f64">,
  Intrinsic<[llvm_double_ty], [llvm_double_ty, llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_gcn_min_f32 : GCCBuiltin<"__gcn_min_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty, llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_gcn_min_f64 : GCCBuiltin<"__gcn_min_f64">,
  Intrinsic<[llvm_double_ty], [llvm_double_ty, llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_div_f32 : GCCBuiltin<"__hsail_div_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty, llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_div_ftz_f32 : GCCBuiltin<"__hsail_div_ftz_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty, llvm_float_ty], [IntrNoMem]
>;

// Intrinsics for OpenCL relational built-ins (OCL 1.2 6.12.6)
def int_HSAIL_class_f32 : GCCBuiltin<"__hsail_class_f32">,
  Intrinsic<[llvm_i32_ty], [llvm_float_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_class_f64 : GCCBuiltin<"__hsail_class_f64">,
  Intrinsic<[llvm_i32_ty], [llvm_double_ty, llvm_i32_ty], [IntrNoMem]
>;

// Intrinsics for OpenCL synchronization built-ins (OCL 1.2 6.12.8)
def int_HSAIL_barrier : GCCBuiltin<"__hsail_barrier">,
  Intrinsic<[], [], []
>;

def int_HSAIL_wavebarrier : GCCBuiltin<"__hsail_wavebarrier">,
  Intrinsic<[], [], []
>;

def int_HSAIL_memfence : GCCBuiltin<"__hsail_memfence">,
  Intrinsic<[], [llvm_i32_ty, llvm_i32_ty], []
>;

def int_HSAIL_imagefence : GCCBuiltin<"__hsail_imagefence">,
  Intrinsic<[], [], []
>;

// Instrinsics for explicit conversions
// float to int
def int_HSAIL_cvt_s32_neari_f32 : GCCBuiltin<"__cvt_s32_rte_f32">,
  Intrinsic<[llvm_i32_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_s32_downi_f32 : GCCBuiltin<"__cvt_s32_rtn_f32">,
  Intrinsic<[llvm_i32_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_s32_upi_f32   : GCCBuiltin<"__cvt_s32_rtp_f32">,
  Intrinsic<[llvm_i32_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_s32_zeroi_f32 : GCCBuiltin<"__cvt_s32_rtz_f32">,
  Intrinsic<[llvm_i32_ty], [llvm_float_ty], [IntrNoMem]
>;


// float to unsigned int
def int_HSAIL_cvt_u32_neari_f32 : GCCBuiltin<"__cvt_u32_rte_f32">,
  Intrinsic<[llvm_i32_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_u32_downi_f32 : GCCBuiltin<"__cvt_u32_rtn_f32">,
  Intrinsic<[llvm_i32_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_u32_upi_f32   : GCCBuiltin<"__cvt_u32_rtp_f32">,
  Intrinsic<[llvm_i32_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_u32_zeroi_f32 : GCCBuiltin<"__cvt_u32_rtz_f32">,
  Intrinsic<[llvm_i32_ty], [llvm_float_ty], [IntrNoMem]
>;


// float to long
def int_HSAIL_cvt_s64_neari_f32 : GCCBuiltin<"__cvt_s64_rte_f32">,
  Intrinsic<[llvm_i64_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_s64_downi_f32 : GCCBuiltin<"__cvt_s64_rtn_f32">,
  Intrinsic<[llvm_i64_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_s64_upi_f32   : GCCBuiltin<"__cvt_s64_rtp_f32">,
  Intrinsic<[llvm_i64_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_s64_zeroi_f32 : GCCBuiltin<"__cvt_s64_rtz_f32">,
  Intrinsic<[llvm_i64_ty], [llvm_float_ty], [IntrNoMem]
>;


// float to unsigned long
def int_HSAIL_cvt_u64_neari_f32 : GCCBuiltin<"__cvt_u64_rte_f32">,
  Intrinsic<[llvm_i64_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_u64_downi_f32 : GCCBuiltin<"__cvt_u64_rtn_f32">,
  Intrinsic<[llvm_i64_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_u64_upi_f32   : GCCBuiltin<"__cvt_u64_rtp_f32">,
  Intrinsic<[llvm_i64_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_u64_zeroi_f32 : GCCBuiltin<"__cvt_u64_rtz_f32">,
  Intrinsic<[llvm_i64_ty], [llvm_float_ty], [IntrNoMem]
>;


// double to int
def int_HSAIL_cvt_s32_neari_f64 : GCCBuiltin<"__cvt_s32_rte_f64">,
  Intrinsic<[llvm_i32_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_s32_downi_f64 : GCCBuiltin<"__cvt_s32_rtn_f64">,
  Intrinsic<[llvm_i32_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_s32_upi_f64   : GCCBuiltin<"__cvt_s32_rtp_f64">,
  Intrinsic<[llvm_i32_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_s32_zeroi_f64 : GCCBuiltin<"__cvt_s32_rtz_f64">,
  Intrinsic<[llvm_i32_ty], [llvm_double_ty], [IntrNoMem]
>;


// double to unsigned int
def int_HSAIL_cvt_u32_neari_f64 : GCCBuiltin<"__cvt_u32_rte_f64">,
  Intrinsic<[llvm_i32_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_u32_downi_f64 : GCCBuiltin<"__cvt_u32_rtn_f64">,
  Intrinsic<[llvm_i32_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_u32_upi_f64   : GCCBuiltin<"__cvt_u32_rtp_f64">,
  Intrinsic<[llvm_i32_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_u32_zeroi_f64 : GCCBuiltin<"__cvt_u32_rtz_f64">,
  Intrinsic<[llvm_i32_ty], [llvm_double_ty], [IntrNoMem]
>;


// double to long
def int_HSAIL_cvt_s64_neari_f64 : GCCBuiltin<"__cvt_s64_rte_f64">,
  Intrinsic<[llvm_i64_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_s64_downi_f64 : GCCBuiltin<"__cvt_s64_rtn_f64">,
  Intrinsic<[llvm_i64_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_s64_upi_f64   : GCCBuiltin<"__cvt_s64_rtp_f64">,
  Intrinsic<[llvm_i64_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_s64_zeroi_f64 : GCCBuiltin<"__cvt_s64_rtz_f64">,
  Intrinsic<[llvm_i64_ty], [llvm_double_ty], [IntrNoMem]
>;


// double to unsigned long
def int_HSAIL_cvt_u64_neari_f64 : GCCBuiltin<"__cvt_u64_rte_f64">,
  Intrinsic<[llvm_i64_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_u64_downi_f64 : GCCBuiltin<"__cvt_u64_rtn_f64">,
  Intrinsic<[llvm_i64_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_u64_upi_f64   : GCCBuiltin<"__cvt_u64_rtp_f64">,
  Intrinsic<[llvm_i64_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_u64_zeroi_f64 : GCCBuiltin<"__cvt_u64_rtz_f64">,
  Intrinsic<[llvm_i64_ty], [llvm_double_ty], [IntrNoMem]
>;


// int to float
def int_HSAIL_cvt_f32_down_i32  : GCCBuiltin<"__cvt_f32_rtn_i32">,
  Intrinsic<[llvm_float_ty], [llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_f32_up_i32    : GCCBuiltin<"__cvt_f32_rtp_i32">,
  Intrinsic<[llvm_float_ty], [llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_f32_zero_i32  : GCCBuiltin<"__cvt_f32_rtz_i32">,
  Intrinsic<[llvm_float_ty], [llvm_i32_ty], [IntrNoMem]
>;


// unsigned int to float
def int_HSAIL_cvt_f32_down_u32  : GCCBuiltin<"__cvt_f32_rtn_u32">,
  Intrinsic<[llvm_float_ty], [llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_f32_up_u32    : GCCBuiltin<"__cvt_f32_rtp_u32">,
  Intrinsic<[llvm_float_ty], [llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_f32_zero_u32  : GCCBuiltin<"__cvt_f32_rtz_u32">,
  Intrinsic<[llvm_float_ty], [llvm_i32_ty], [IntrNoMem]
>;


// long to float
def int_HSAIL_cvt_f32_down_i64 : GCCBuiltin<"__cvt_f32_rtn_i64">,
  Intrinsic<[llvm_float_ty], [llvm_i64_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_f32_up_i64   : GCCBuiltin<"__cvt_f32_rtp_i64">,
  Intrinsic<[llvm_float_ty], [llvm_i64_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_f32_zero_i64 : GCCBuiltin<"__cvt_f32_rtz_i64">,
  Intrinsic<[llvm_float_ty], [llvm_i64_ty], [IntrNoMem]
>;


// unsigned long to float
def int_HSAIL_cvt_f32_down_u64 : GCCBuiltin<"__cvt_f32_rtn_u64">,
  Intrinsic<[llvm_float_ty], [llvm_i64_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_f32_up_u64   : GCCBuiltin<"__cvt_f32_rtp_u64">,
  Intrinsic<[llvm_float_ty], [llvm_i64_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_f32_zero_u64 : GCCBuiltin<"__cvt_f32_rtz_u64">,
  Intrinsic<[llvm_float_ty], [llvm_i64_ty], [IntrNoMem]
>;


// long to double
def int_HSAIL_cvt_f64_down_i64 : GCCBuiltin<"__cvt_f64_rtn_i64">,
  Intrinsic<[llvm_double_ty], [llvm_i64_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_f64_up_i64 : GCCBuiltin<"__cvt_f64_rtp_i64">,
  Intrinsic<[llvm_double_ty], [llvm_i64_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_f64_zero_i64 : GCCBuiltin<"__cvt_f64_rtz_i64">,
  Intrinsic<[llvm_double_ty], [llvm_i64_ty], [IntrNoMem]
>;


// unsigned long to double
def int_HSAIL_cvt_f64_down_u64 : GCCBuiltin<"__cvt_f64_rtn_u64">,
  Intrinsic<[llvm_double_ty], [llvm_i64_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_f64_up_u64 : GCCBuiltin<"__cvt_f64_rtp_u64">,
  Intrinsic<[llvm_double_ty], [llvm_i64_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_f64_zero_u64 : GCCBuiltin<"__cvt_f64_rtz_u64">,
  Intrinsic<[llvm_double_ty], [llvm_i64_ty], [IntrNoMem]
>;


// double to float
def int_HSAIL_cvt_f32_down_f64 : GCCBuiltin<"__cvt_f32_rtn_f64">,
  Intrinsic<[llvm_float_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_f32_up_f64   : GCCBuiltin<"__cvt_f32_rtp_f64">,
  Intrinsic<[llvm_float_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_f32_zero_f64 : GCCBuiltin<"__cvt_f32_rtz_f64">,
  Intrinsic<[llvm_float_ty], [llvm_double_ty], [IntrNoMem]
>;


// half to float
def int_HSAIL_cvt_f32_f16 : GCCBuiltin<"__cvt_f32_f16">,
  Intrinsic<[llvm_float_ty], [llvm_i32_ty], [IntrNoMem]
>;


// float to half
def int_HSAIL_cvt_zero_f16_f32 : GCCBuiltin<"__cvt_f16_rtz_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_near_f16_f32  : GCCBuiltin<"__cvt_f16_rte_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_down_f16_f32 : GCCBuiltin<"__cvt_f16_rtn_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_up_f16_f32 : GCCBuiltin<"__cvt_f16_rtp_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty], [IntrNoMem]
>;

// double to half
def int_HSAIL_cvt_zero_f16_f64 : GCCBuiltin<"__cvt_f16_rtz_f64">,
  Intrinsic<[llvm_float_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_near_f16_f64 : GCCBuiltin<"__cvt_f16_rte_f64">,
  Intrinsic<[llvm_float_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_down_f16_f64 : GCCBuiltin<"__cvt_f16_rtn_f64">,
  Intrinsic<[llvm_float_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_cvt_up_f16_f64 : GCCBuiltin<"__cvt_f16_rtp_f64">,
  Intrinsic<[llvm_float_ty], [llvm_double_ty], [IntrNoMem]
>;

// Misc intrinsics used by OpenCL built-ins
def int_HSAIL_bitselect_u32 : GCCBuiltin<"__hsail_bitselect_u32">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_bitselect_u64 : GCCBuiltin<"__hsail_bitselect_u64">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty, llvm_i64_ty], [IntrNoMem]
>;

// Media-ops intrinsics
def int_HSAIL_bitalign_b32  : GCCBuiltin<"__hsail_bitalign_b32">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_bytealign_b32 : GCCBuiltin<"__hsail_bytealign_b32">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_packcvt_u8x4_f32 : GCCBuiltin<"__hsail_packcvt_u8x4_f32">,
  Intrinsic<[llvm_i32_ty], [llvm_float_ty, llvm_float_ty,
                            llvm_float_ty, llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_lerp_u8x4 : GCCBuiltin<"__hsail_lerp_u8x4">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_sad_u32_u8x4 : GCCBuiltin<"__hsail_sad_u32_u8x4">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_sadhi_u16x2_u8x4 : GCCBuiltin<"__hsail_sadhi_u16x2_u8x4">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_unpackcvt_f32_u8x4 : GCCBuiltin<"__hsail_unpackcvt_f32_u8x4">,
  Intrinsic<[llvm_float_ty], [llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

// Media Ops2

def int_HSAIL_msad: GCCBuiltin<"__hsail_msad">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_sadw: GCCBuiltin<"__hsail_sadw">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_sadd: GCCBuiltin<"__hsail_sadd">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_umin3: GCCBuiltin<"__hsail_umin3">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_fmin3: GCCBuiltin<"__hsail_f32_min3">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty, llvm_float_ty, llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_imin3: GCCBuiltin<"__hsail_imin3">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_umax3: GCCBuiltin<"__hsail_umax3">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_fmax3: GCCBuiltin<"__hsail_f32_max3">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty, llvm_float_ty, llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_imax3: GCCBuiltin<"__hsail_imax3">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_umed3: GCCBuiltin<"__hsail_umedian3">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_fmed3: GCCBuiltin<"__hsail_f32_median3">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty, llvm_float_ty,  llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_imed3: GCCBuiltin<"__hsail_imedian3">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_qsad: GCCBuiltin<"__hsail_qsad">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty, llvm_i64_ty], [IntrNoMem]
>;

def int_HSAIL_mqsad: GCCBuiltin<"__hsail_mqsad">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i32_ty, llvm_i64_ty], [IntrNoMem]
>;

def int_HSAIL_bfe: GCCBuiltin<"__hsail_bfe">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_ibfe: GCCBuiltin<"__hsail_ibfe">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_bfm: GCCBuiltin<"__hsail_bfm">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_ftz_f32 : GCCBuiltin<"__hsail_ftz_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_mul_ftz_f32 : GCCBuiltin<"__hsail_mul_ftz_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_firstbit_u32 : GCCBuiltin<"__hsail_firstbit_u32">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_lastbit_u32 : GCCBuiltin<"__hsail_lastbit_u32">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_fract_f32 : GCCBuiltin<"__hsail_fraction_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty], [IntrNoMem]
>;

def int_HSAIL_fract_f64 : GCCBuiltin<"__hsail_fraction_f64">,
  Intrinsic<[llvm_double_ty], [llvm_double_ty], [IntrNoMem]
>;

def int_HSAIL_mad_u32 : GCCBuiltin<"__hsail_mad_u32">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_mad_u64 : GCCBuiltin<"__hsail_mad_u64">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty, llvm_i64_ty], [IntrNoMem]
>;

def int_HSAIL_mulhi_s32 : GCCBuiltin<"__hsail_mulhi_s32">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_mulhi_u32 : GCCBuiltin<"__hsail_mulhi_u32">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_mulhi_s64 : GCCBuiltin<"__hsail_mulhi_s64">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], [IntrNoMem]
>;

def int_HSAIL_mulhi_u64 : GCCBuiltin<"__hsail_mulhi_u64">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], [IntrNoMem]
>;

def int_HSAIL_mad24_s32 : GCCBuiltin<"__hsail_mad24_s32">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_mad24_u32 : GCCBuiltin<"__hsail_mad24_u32">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_mul24_s32 : GCCBuiltin<"__hsail_mul24_s32">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_mul24_u32 : GCCBuiltin<"__hsail_mul24_u32">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_popcount_u32_b32 : GCCBuiltin<"__hsail_popcount_u32_b32">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_gcn_fldexp_f32  : GCCBuiltin<"__gcn_fldexp_f32">,
  Intrinsic<[llvm_float_ty], [llvm_float_ty, llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_gcn_fldexp_f64  : GCCBuiltin<"__gcn_fldexp_f64">,
  Intrinsic<[llvm_double_ty], [llvm_double_ty, llvm_i32_ty], [IntrNoMem]
>;

// atomic counter32
// TODO: IntrReadWriteArgMem?
def int_HSAIL_gcn_atomic_append_u32 : GCCBuiltin<"__gcn_atomic_append_u32">,
  Intrinsic<[llvm_i32_ty], [llvm_ptr_ty], []
>;

def int_HSAIL_gcn_atomic_consume_u32 : GCCBuiltin<"__gcn_atomic_consume_u32">,
  Intrinsic<[llvm_i32_ty], [llvm_ptr_ty], []
>;

// Image intrinsics

// Image read instrinsics
let TargetPrefix = "HSAIL", isTarget = 1 in {
  // Read image intrinsic classes
  class ReadImage1DIntr<string name, LLVMType DestType, LLVMType CoordType> :
    GCCBuiltin<name>,
    Intrinsic<[DestType, DestType, DestType, DestType],
              [llvm_ptr_ty, llvm_ptr_ty, CoordType],
              [IntrReadArgMem, NoCapture<4>, NoCapture<5>]
  >;

  class ReadImage2DIntr<string name, LLVMType DestType, LLVMType CoordType> :
    GCCBuiltin<name>,
    Intrinsic<[DestType, DestType, DestType, DestType],
              [llvm_ptr_ty, llvm_ptr_ty, CoordType, CoordType],
              [IntrReadArgMem, NoCapture<4>, NoCapture<5>]
  >;

  class ReadImage3DIntr<string name, LLVMType DestType, LLVMType CoordType> :
    GCCBuiltin<name>,
    Intrinsic<[DestType, DestType, DestType, DestType],
              [llvm_ptr_ty, llvm_ptr_ty, CoordType, CoordType, CoordType],
              [IntrReadArgMem, NoCapture<4>, NoCapture<5>]
   >;

  // OpenCL 2.0 image 2D Depth
  class ReadImage2DDepthIntr<string name, LLVMType DestType, LLVMType CoordType> :
    GCCBuiltin<name>,
      Intrinsic<[DestType],
                [llvm_ptr_ty, llvm_ptr_ty, CoordType, CoordType],
                [IntrReadArgMem, NoCapture<1>, NoCapture<2>]
  >;

  // OpenCL 2.0 image 2D Array Depth
  class ReadImage2DArrayDepthIntr<string name, LLVMType DestType, LLVMType CoordType> :
    GCCBuiltin<name>,
    Intrinsic<[DestType],
              [llvm_ptr_ty, llvm_ptr_ty, CoordType, CoordType, CoordType],
              [IntrReadArgMem, NoCapture<1>, NoCapture<2>]
  >;

  // Load Image intrinsic classes
  class LoadImage1DIntr<string name, LLVMType DestType, LLVMType CoordType> :
    GCCBuiltin<name>,
    Intrinsic<[DestType, DestType, DestType, DestType],
              [llvm_ptr_ty, CoordType],
              [IntrReadArgMem, NoCapture<4>]
  >;

  class LoadImage2DIntr<string name, LLVMType DestType, LLVMType CoordType> :
    GCCBuiltin<name>,
    Intrinsic<[DestType, DestType, DestType, DestType],
              [llvm_ptr_ty, CoordType, CoordType],
              [IntrReadArgMem, NoCapture<4>]
  >;

  class LoadImage3DIntr<string name, LLVMType DestType, LLVMType CoordType> :
    GCCBuiltin<name>,
    Intrinsic<[DestType, DestType, DestType, DestType],
              [llvm_ptr_ty, CoordType, CoordType, CoordType],
              [IntrReadArgMem, NoCapture<4>]
  >;

  class LoadImage2DDepthIntr<string name, LLVMType DestType, LLVMType CoordType> :
    GCCBuiltin<name>,
    Intrinsic<[DestType],
              [llvm_ptr_ty, CoordType, CoordType],
              [IntrReadArgMem, NoCapture<1>]
  >;

  class LoadImage2DArrayDepthIntr<string name, LLVMType DestType, LLVMType CoordType> :
    GCCBuiltin<name>,
    Intrinsic<[DestType],
              [llvm_ptr_ty, CoordType, CoordType, CoordType],
              [IntrReadArgMem, NoCapture<1>]
  >;

  // Store image intrinsic classes
  class StoreImage1dInt :
    Intrinsic<[], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty,
                  llvm_ptr_ty, llvm_i32_ty], []
  >;

  class StoreImage1dFloat :
    Intrinsic<[], [llvm_float_ty, llvm_float_ty, llvm_float_ty,
                   llvm_float_ty, llvm_ptr_ty, llvm_i32_ty], []
  >;

  class StoreImage2dInt :
    Intrinsic<[], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty,
                   llvm_ptr_ty, llvm_i32_ty, llvm_i32_ty], []
  >;

  class StoreImage2dFloat :
    Intrinsic<[], [llvm_float_ty, llvm_float_ty, llvm_float_ty,
                   llvm_float_ty, llvm_ptr_ty, llvm_i32_ty,
                   llvm_i32_ty], []
  >;

  class StoreImage3dInt :
    Intrinsic<[], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty,
    llvm_ptr_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], []
  >;

  class StoreImage3dFloat :
    Intrinsic<[], [llvm_float_ty, llvm_float_ty, llvm_float_ty,
                   llvm_float_ty, llvm_ptr_ty, llvm_i32_ty,
                   llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], []
  >;

  class StoreImage2dDepthFloat :
    Intrinsic<[], [llvm_float_ty, llvm_ptr_ty,
                   llvm_i32_ty, llvm_i32_ty], []
  >;

  class StoreImage2dArrayDepthFloat :
    Intrinsic<[], [llvm_float_ty, llvm_ptr_ty, llvm_i32_ty,
                   llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], []
  >;
}

// read image 1d
def int_HSAIL_rd_imgf_1d_s32 :
    ReadImage1DIntr<"__hsail_rdimagef_1d_s32", llvm_float_ty, llvm_i32_ty>;
def int_HSAIL_rd_imgf_1d_f32 :
    ReadImage1DIntr<"__hsail_rdimagef_1d_f32", llvm_float_ty, llvm_float_ty>;
def int_HSAIL_rd_imgi_1d_s32 :
    ReadImage1DIntr<"__hsail_rdimagei_1d_s32", llvm_i32_ty, llvm_i32_ty>;
def int_HSAIL_rd_imgi_1d_f32 :
    ReadImage1DIntr<"__hsail_rdimagei_1d_f32", llvm_i32_ty, llvm_float_ty>;
def int_HSAIL_rd_imgui_1d_s32 :
    ReadImage1DIntr<"__hsail_rdimageui_1d_s32", llvm_i32_ty, llvm_i32_ty>;
def int_HSAIL_rd_imgui_1d_f32 :
    ReadImage1DIntr<"__hsail_rdimageui_1d_f32", llvm_i32_ty, llvm_float_ty>;

// read image 1d array
def int_HSAIL_rd_imgf_1da_s32 :
    ReadImage2DIntr<"__hsail_rdimagef_1da_s32", llvm_float_ty, llvm_i32_ty>;
def int_HSAIL_rd_imgf_1da_f32 :
    ReadImage2DIntr<"__hsail_rdimagef_1da_f32", llvm_float_ty, llvm_float_ty>;
def int_HSAIL_rd_imgi_1da_s32 :
    ReadImage2DIntr<"__hsail_rdimagei_1da_s32", llvm_i32_ty, llvm_i32_ty>;
def int_HSAIL_rd_imgi_1da_f32 :
    ReadImage2DIntr<"__hsail_rdimagei_1da_f32", llvm_i32_ty, llvm_float_ty>;
def int_HSAIL_rd_imgui_1da_s32 :
    ReadImage2DIntr<"__hsail_rdimageui_1da_s32", llvm_i32_ty, llvm_i32_ty>;
def int_HSAIL_rd_imgui_1da_f32 :
    ReadImage2DIntr<"__hsail_rdimageui_1da_f32", llvm_i32_ty, llvm_float_ty>;

// read image 2d
def int_HSAIL_rd_imgf_2d_s32 :
    ReadImage2DIntr<"__hsail_rdimagef_2d_s32", llvm_float_ty, llvm_i32_ty>;
def int_HSAIL_rd_imgf_2d_f32 :
    ReadImage2DIntr<"__hsail_rdimagef_2d_f32", llvm_float_ty, llvm_float_ty>;
def int_HSAIL_rd_imgi_2d_s32 :
    ReadImage2DIntr<"__hsail_rdimagei_2d_s32", llvm_i32_ty, llvm_i32_ty>;
def int_HSAIL_rd_imgi_2d_f32 :
    ReadImage2DIntr<"__hsail_rdimagei_2d_f32", llvm_i32_ty, llvm_float_ty>;
def int_HSAIL_rd_imgui_2d_s32 :
    ReadImage2DIntr<"__hsail_rdimageui_2d_s32", llvm_i32_ty, llvm_i32_ty>;
def int_HSAIL_rd_imgui_2d_f32 :
    ReadImage2DIntr<"__hsail_rdimageui_2d_f32", llvm_i32_ty, llvm_float_ty>;

// read image 2d array
def int_HSAIL_rd_imgf_2da_s32 :
    ReadImage3DIntr<"__hsail_rdimagef_2da_s32", llvm_float_ty, llvm_i32_ty>;
def int_HSAIL_rd_imgf_2da_f32 :
    ReadImage3DIntr<"__hsail_rdimagef_2da_f32", llvm_float_ty, llvm_float_ty>;
def int_HSAIL_rd_imgi_2da_s32 :
    ReadImage3DIntr<"__hsail_rdimagei_2da_s32", llvm_i32_ty, llvm_i32_ty>;
def int_HSAIL_rd_imgi_2da_f32 :
    ReadImage3DIntr<"__hsail_rdimagei_2da_f32", llvm_i32_ty, llvm_float_ty>;
def int_HSAIL_rd_imgui_2da_s32 :
    ReadImage3DIntr<"__hsail_rdimageui_2da_s32", llvm_i32_ty, llvm_i32_ty>;
def int_HSAIL_rd_imgui_2da_f32 :
    ReadImage3DIntr<"__hsail_rdimageui_2da_f32", llvm_i32_ty, llvm_float_ty>;

// read image 3d
def int_HSAIL_rd_imgf_3d_s32 :
    ReadImage3DIntr<"__hsail_rdimagef_3d_s32", llvm_float_ty, llvm_i32_ty>;
def int_HSAIL_rd_imgf_3d_f32 :
    ReadImage3DIntr<"__hsail_rdimagef_3d_f32", llvm_float_ty, llvm_float_ty>;
def int_HSAIL_rd_imgi_3d_s32 :
    ReadImage3DIntr<"__hsail_rdimagei_3d_s32", llvm_i32_ty, llvm_i32_ty>;
def int_HSAIL_rd_imgi_3d_f32 :
    ReadImage3DIntr<"__hsail_rdimagei_3d_f32", llvm_i32_ty, llvm_float_ty>;
def int_HSAIL_rd_imgui_3d_s32 :
    ReadImage3DIntr<"__hsail_rdimageui_3d_s32", llvm_i32_ty, llvm_i32_ty>;
def int_HSAIL_rd_imgui_3d_f32 :
    ReadImage3DIntr<"__hsail_rdimageui_3d_f32", llvm_i32_ty, llvm_float_ty>;

// OpenCL 2.0 read image 2ddepth
def int_HSAIL_rd_imgf_2ddepth_s32 :
    ReadImage2DDepthIntr<"__hsail_rdimagef_2ddepth_s32", llvm_float_ty, llvm_i32_ty>;
def int_HSAIL_rd_imgf_2ddepth_f32 :
    ReadImage2DDepthIntr<"__hsail_rdimagef_2ddepth_f32", llvm_float_ty, llvm_float_ty>;

// OpenCL 2.0 read image 2dadepth
def int_HSAIL_rd_imgf_2dadepth_s32 :
    ReadImage2DArrayDepthIntr<"__hsail_rdimagef_2dadepth_s32", llvm_float_ty, llvm_i32_ty>;
def int_HSAIL_rd_imgf_2dadepth_f32 :
    ReadImage2DArrayDepthIntr<"__hsail_rdimagef_2dadepth_f32", llvm_float_ty, llvm_float_ty>;

// Load image intrinsics

// load image 1d
def int_HSAIL_ld_imgf_1d_u32 :
    LoadImage1DIntr<"__hsail_ldimagef_1d_u32", llvm_float_ty, llvm_i32_ty>;
def int_HSAIL_ld_imgi_1d_u32 :
    LoadImage1DIntr<"__hsail_ldimagei_1d_u32", llvm_i32_ty, llvm_i32_ty>;
def int_HSAIL_ld_imgui_1d_u32 :
    LoadImage1DIntr<"__hsail_ldimageui_1d_u32", llvm_i32_ty, llvm_i32_ty>;

// load image 1d buffer
def int_HSAIL_ld_imgf_1db_u32 :
    LoadImage1DIntr<"__hsail_ldimagef_1db_u32", llvm_float_ty, llvm_i32_ty>;
def int_HSAIL_ld_imgi_1db_u32 :
    LoadImage1DIntr<"__hsail_ldimagei_1db_u32", llvm_i32_ty, llvm_i32_ty>;
def int_HSAIL_ld_imgui_1db_u32 :
    LoadImage1DIntr<"__hsail_ldimageui_1db_u32", llvm_i32_ty, llvm_i32_ty>;

// load image 1d array
def int_HSAIL_ld_imgf_1da_u32 :
    LoadImage2DIntr<"__hsail_ldimagef_1da_u32", llvm_float_ty, llvm_i32_ty>;
def int_HSAIL_ld_imgi_1da_u32 :
    LoadImage2DIntr<"__hsail_ldimagei_1da_u32", llvm_i32_ty, llvm_i32_ty>;
def int_HSAIL_ld_imgui_1da_u32 :
    LoadImage2DIntr<"__hsail_ldimageui_1da_u32", llvm_i32_ty, llvm_i32_ty>;

// load image 2d
def int_HSAIL_ld_imgf_2d_u32 :
    LoadImage2DIntr<"__hsail_ldimagef_2d_u32", llvm_float_ty, llvm_i32_ty>;
def int_HSAIL_ld_imgi_2d_u32 :
    LoadImage2DIntr<"__hsail_ldimagei_2d_u32", llvm_i32_ty, llvm_i32_ty>;
def int_HSAIL_ld_imgui_2d_u32 :
    LoadImage2DIntr<"__hsail_ldimageui_2d_u32", llvm_i32_ty, llvm_i32_ty>;

// load image 1d array
def int_HSAIL_ld_imgf_2da_u32 :
    LoadImage3DIntr<"__hsail_ldimagef_2da_u32", llvm_float_ty, llvm_i32_ty>;
def int_HSAIL_ld_imgi_2da_u32 :
    LoadImage3DIntr<"__hsail_ldimagei_2da_u32", llvm_i32_ty, llvm_i32_ty>;
def int_HSAIL_ld_imgui_2da_u32 :
    LoadImage3DIntr<"__hsail_ldimageui_2da_u32", llvm_i32_ty, llvm_i32_ty>;

// load image 3d
def int_HSAIL_ld_imgf_3d_u32 :
    LoadImage3DIntr<"__hsail_ldimagef_3d_u32", llvm_float_ty, llvm_i32_ty>;
def int_HSAIL_ld_imgi_3d_u32 :
    LoadImage3DIntr<"__hsail_ldimagei_3d_u32", llvm_i32_ty, llvm_i32_ty>;
def int_HSAIL_ld_imgui_3d_u32 :
    LoadImage3DIntr<"__hsail_ldimageui_3d_u32", llvm_i32_ty, llvm_i32_ty>;

// OpenCL 2.0 load image 2d depth
def int_HSAIL_ld_imgf_2ddepth_u32 :
    LoadImage2DDepthIntr<"__hsail_ldimagef_2ddepth_u32", llvm_float_ty, llvm_i32_ty>;

// OpenCL 2.0 load image 2dadepth
def int_HSAIL_ld_imgf_2dadepth_u32 :
    LoadImage2DArrayDepthIntr<"__hsail_ldimagef_2dadepth_u32", llvm_float_ty, llvm_i32_ty>;


// Image store intrinsics
// store image 1d
def int_HSAIL_stimagef_1d_i32 : GCCBuiltin<"__hsail_stimagef_1d_i32">,
        StoreImage1dFloat;
def int_HSAIL_stimagei_1d_i32 : GCCBuiltin<"__hsail_stimagei_1d_i32">,
        StoreImage1dInt;
def int_HSAIL_stimageui_1d_i32 : GCCBuiltin<"__hsail_stimageui_1d_i32">,
        StoreImage1dInt;

// store image 1d array
def int_HSAIL_stimagef_1da_i32 : GCCBuiltin<"__hsail_stimagef_1da_i32">,
        StoreImage2dFloat;
def int_HSAIL_stimagei_1da_i32 : GCCBuiltin<"__hsail_stimagei_1da_i32">,
        StoreImage2dInt;
def int_HSAIL_stimageui_1da_i32 : GCCBuiltin<"__hsail_stimageui_1da_i32">,
        StoreImage2dInt;

// store image 1d buffer
def int_HSAIL_stimagef_1db_i32 : GCCBuiltin<"__hsail_stimagef_1db_i32">,
        StoreImage1dFloat;
def int_HSAIL_stimagei_1db_i32 : GCCBuiltin<"__hsail_stimagei_1db_i32">,
        StoreImage1dInt;
def int_HSAIL_stimageui_1db_i32 : GCCBuiltin<"__hsail_stimageui_1db_i32">,
        StoreImage1dInt;

// store image 2d
def int_HSAIL_stimagef_2d_i32 : GCCBuiltin<"__hsail_stimagef_2d_i32">,
        StoreImage2dFloat;
def int_HSAIL_stimagei_2d_i32 : GCCBuiltin<"__hsail_stimagei_2d_i32">,
        StoreImage2dInt;
def int_HSAIL_stimageui_2d_i32 : GCCBuiltin<"__hsail_stimageui_2d_i32">,
        StoreImage2dInt;

// store image 2d array
def int_HSAIL_stimagef_2da_i32 : GCCBuiltin<"__hsail_stimagef_2da_i32">,
        StoreImage3dFloat;
def int_HSAIL_stimagei_2da_i32 : GCCBuiltin<"__hsail_stimagei_2da_i32">,
        StoreImage3dInt;
def int_HSAIL_stimageui_2da_i32 : GCCBuiltin<"__hsail_stimageui_2da_i32">,
        StoreImage3dInt;

// store image 3d
def int_HSAIL_stimagef_3d_i32 : GCCBuiltin<"__hsail_stimagef_3d_i32">,
        StoreImage3dFloat;
def int_HSAIL_stimagei_3d_i32 : GCCBuiltin<"__hsail_stimagei_3d_i32">,
        StoreImage3dInt;
def int_HSAIL_stimageui_3d_i32 : GCCBuiltin<"__hsail_stimageui_3d_i32">,
        StoreImage3dInt;

// store image 2d depth
def int_HSAIL_stimagef_2ddepth_i32 : GCCBuiltin<"__hsail_stimagef_2ddepth_i32">,
        StoreImage2dDepthFloat;

// store image 2d array depth
def int_HSAIL_stimagef_2dadepth_i32 : GCCBuiltin<"__hsail_stimagef_2dadepth_i32">,
        StoreImage2dArrayDepthFloat;

// Image query
def int_HSAIL_query_width_1d  : GCCBuiltin<"__hsail_query_width_1d">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_width_1db : GCCBuiltin<"__hsail_query_width_1db">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_width_1da : GCCBuiltin<"__hsail_query_width_1da">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_width_2d  : GCCBuiltin<"__hsail_query_width_2d">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_width_2da : GCCBuiltin<"__hsail_query_width_2da">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_width_3d  : GCCBuiltin<"__hsail_query_width_3d">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_width_2ddepth : GCCBuiltin<"__hsail_query_width_2ddepth">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_width_2dadepth : GCCBuiltin<"__hsail_query_width_2dadepth">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_height_2d  : GCCBuiltin<"__hsail_query_height_2d">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_height_2da : GCCBuiltin<"__hsail_query_height_2da">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_height_3d  : GCCBuiltin<"__hsail_query_height_3d">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_height_2ddepth : GCCBuiltin<"__hsail_query_height_2ddepth">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_height_2dadepth : GCCBuiltin<"__hsail_query_height_2dadepth">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_depth_3d  : GCCBuiltin<"__hsail_depth_3d">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_format_1d  : GCCBuiltin<"__hsail_query_format_1d">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_format_1db : GCCBuiltin<"__hsail_query_format_1db">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_format_1da : GCCBuiltin<"__hsail_query_format_1da">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_format_2d  : GCCBuiltin<"__hsail_query_format_2d">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_format_2da : GCCBuiltin<"__hsail_query_format_2da">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_format_3d  : GCCBuiltin<"__hsail_query_format_3d">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_order_1d  : GCCBuiltin<"__hsail_query_order_1d">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_order_1db : GCCBuiltin<"__hsail_query_order_1db">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_order_1da : GCCBuiltin<"__hsail_query_order_1da">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_order_2d  : GCCBuiltin<"__hsail_query_order_2d">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_order_2da : GCCBuiltin<"__hsail_query_order_2da">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_order_3d  : GCCBuiltin<"__hsail_query_order_3d">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_array_1da : GCCBuiltin<"__hsail_query_array_1da">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_array_2da : GCCBuiltin<"__hsail_query_array_2da">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_array_2dadepth : GCCBuiltin<"__hsail_query_array_2dadepth">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_channelorder_2ddepth : GCCBuiltin<"__hsail_query_channelorder_2ddepth">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_channelorder_2dadepth : GCCBuiltin<"__hsail_query_channelorder_2dadepth">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_channeltype_2ddepth : GCCBuiltin<"__hsail_query_channeltype_2ddepth">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_query_channeltype_2dadepth : GCCBuiltin<"__hsail_query_channeltype_2dadepth">,
  Intrinsic<[llvm_anyint_ty], [LLVMMatchType<0>], []
>;

def int_HSAIL_segmentp_global : GCCBuiltin<"__hsail_segmentp_global">,
  Intrinsic<[llvm_i1_ty], [llvm_anyptr_ty], [IntrNoMem]
>;

def int_HSAIL_segmentp_local : GCCBuiltin<"__hsail_segmentp_local">,
  Intrinsic<[llvm_i1_ty], [llvm_anyptr_ty], [IntrNoMem]
>;

def int_HSAIL_segmentp_private : GCCBuiltin<"__hsail_segmentp_private">,
  Intrinsic<[llvm_i1_ty], [llvm_anyptr_ty], [IntrNoMem]
>;

def int_HSAIL_nullptr_flat : GCCBuiltin<"__hsail_nullptr_flat">,
  Intrinsic<[llvm_anyptr_ty], [], [IntrNoMem]
>;

// FIXME: Should this be removed? It produces the same output as for flat.
def int_HSAIL_nullptr_global : GCCBuiltin<"__hsail_nullptr_global">,
  Intrinsic<[llvm_anyptr_ty],[], [IntrNoMem]
>;

def int_HSAIL_nullptr_group : GCCBuiltin<"__hsail_nullptr_group">,
  Intrinsic<[llvm_i32_ty], [], [IntrNoMem]
>;

def int_HSAIL_nullptr_private : GCCBuiltin<"__hsail_nullptr_private">,
  Intrinsic<[llvm_i32_ty], [], [IntrNoMem]
>;

// FIXME: Should this be removed? It produces the same output as for flat.
def int_HSAIL_nullptr_readonly : GCCBuiltin<"__hsail_nullptr_readonly">,
  Intrinsic<[llvm_anyptr_ty], [], [IntrNoMem]
>;

def int_HSAIL_nullptr_kernarg : GCCBuiltin<"__hsail_nullptr_kernarg">,
  Intrinsic<[llvm_anyptr_ty], [], [IntrNoMem]
>;

// ld_kernarg instructions have no side effects and can be CSE'd or
// even deleted if dead.
def int_HSAIL_ld_kernarg_u32 : GCCBuiltin<"__hsail_ld_kernarg_u32">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty], [IntrNoMem]
>;

def int_HSAIL_ld_kernarg_u64 : GCCBuiltin<"__hsail_ld_kernarg_u64">,
  Intrinsic<[llvm_i64_ty], [llvm_i32_ty], [IntrNoMem]
>;

}
