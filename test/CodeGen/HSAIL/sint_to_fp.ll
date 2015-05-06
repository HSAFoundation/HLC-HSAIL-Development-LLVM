; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &s_sint_to_fp_i32_to_f32(
; HSAIL: cvt_f32_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @s_sint_to_fp_i32_to_f32(float addrspace(1)* %out, i32 %in) {
  %result = sitofp i32 %in to float
  store float %result, float addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &sint_to_fp_v2i32(
; HSAIL: cvt_f32_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_f32_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @sint_to_fp_v2i32(<2 x float> addrspace(1)* %out, <2 x i32> %in) {
  %result = sitofp <2 x i32> %in to <2 x float>
  store <2 x float> %result, <2 x float> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &sint_to_fp_v4i32(
; HSAIL: cvt_f32_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_f32_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_f32_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_f32_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @sint_to_fp_v4i32(<4 x float> addrspace(1)* %out, <4 x i32> addrspace(1)* %in) {
  %value = load <4 x i32> addrspace(1) * %in
  %result = sitofp <4 x i32> %value to <4 x float>
  store <4 x float> %result, <4 x float> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &sint_to_fp_i1_f32(
; HSAIL: cmp_eq_b1_s32 [[CMP:\$c[0-9]+]]
; HSAIL: cmov_b32 [[RESULT:\$s[0-9]+]], [[CMP]], 3212836864, 0;
; HSAIL: st_global_align(4)_u32 [[RESULT]]
define void @sint_to_fp_i1_f32(float addrspace(1)* %out, i32 %in) {
  %cmp = icmp eq i32 %in, 0
  %fp = sitofp i1 %cmp to float
  store float %fp, float addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &sint_to_fp_i32_to_f64(
; HSAIL: cvt_f64_s32 {{\$d[0-9]+}}, {{\$s[0-9]+}};
define void @sint_to_fp_i32_to_f64(double addrspace(1)* %out, i32 %in) {
  %result = sitofp i32 %in to double
  store double %result, double addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &sint_to_fp_i1_f64(
; HSAIL: cmp_eq_b1_s32 [[CMP:\$c[0-9]+]]
; HSAIL: cmov_b64 [[RESULT:\$d[0-9]+]], [[CMP]], 13830554455654793216, 0;
; HSAIL: st_global_align(8)_u64 [[RESULT]]
define void @sint_to_fp_i1_f64(double addrspace(1)* %out, i32 %in) {
  %cmp = icmp eq i32 %in, 0
  %fp = sitofp i1 %cmp to double
  store double %fp, double addrspace(1)* %out, align 8
  ret void
}

; HSAIL-LABEL: {{^}}prog function &s_sint_to_fp_i64_to_f64(
; HSAIL: cvt_f64_s64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @s_sint_to_fp_i64_to_f64(double addrspace(1)* %out, i64 %in) {
  %result = sitofp i64 %in to double
  store double %result, double addrspace(1)* %out
  ret void
}
