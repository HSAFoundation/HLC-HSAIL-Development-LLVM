; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &uint_to_fp_i32_to_f32
; HSAIL: cvt_f32_u32  {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @uint_to_fp_i32_to_f32(float addrspace(1)* %out, i32 %in) {
  %result = uitofp i32 %in to float
  store float %result, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &uint_to_fp_v2i32_to_v2f32
; HSAIL: cvt_f32_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_f32_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @uint_to_fp_v2i32_to_v2f32(<2 x float> addrspace(1)* %out, <2 x i32> %in) {
  %result = uitofp <2 x i32> %in to <2 x float>
  store <2 x float> %result, <2 x float> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &uint_to_fp_v4i32_to_v4f32
; HSAIL: cvt_f32_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_f32_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_f32_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_f32_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @uint_to_fp_v4i32_to_v4f32(<4 x float> addrspace(1)* %out, <4 x i32> addrspace(1)* %in) {
  %value = load <4 x i32> addrspace(1) * %in
  %result = uitofp <4 x i32> %value to <4 x float>
  store <4 x float> %result, <4 x float> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &uint_to_fp_i64_to_f32
; HSAIL: cvt_f32_u64 {{\$s[0-9]+}}, {{\$d[0-9]+}};
define void @uint_to_fp_i64_to_f32(float addrspace(1)* %out, i64 %in) {
  %tmp0 = uitofp i64 %in to float
  store float %tmp0, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &uint_to_fp_i1_to_f32
; HSAIL: cmp_eq_b1_s32 [[CMP:\$c[0-9]+]], {{\$s[0-9]+}}, 0;
; HSAIL: cmov_b32 [[RESULT:\$s[0-9]+]], [[CMP]], 1065353216, 0;
; HSAIL: st_global_align(4)_u32 [[RESULT]]
define void @uint_to_fp_i1_to_f32(float addrspace(1)* %out, i32 %in) {
  %cmp = icmp eq i32 %in, 0
  %fp = uitofp i1 %cmp to float
  store float %fp, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &uint_to_fp_i32_to_f64
; HSAIL: cvt_f64_u32  {{\$d[0-9]+}}, {{\$s[0-9]+}};
define void @uint_to_fp_i32_to_f64(double addrspace(1)* %out, i32 %in) {
  %result = uitofp i32 %in to double
  store double %result, double addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &uint_to_fp_v2i32_to_v2f64
; HSAIL: cvt_f64_u32 {{\$d[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_f64_u32 {{\$d[0-9]+}}, {{\$s[0-9]+}};
define void @uint_to_fp_v2i32_to_v2f64(<2 x double> addrspace(1)* %out, <2 x i32> %in) {
  %result = uitofp <2 x i32> %in to <2 x double>
  store <2 x double> %result, <2 x double> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &uint_to_fp_v4i32_to_v4f64
; HSAIL: cvt_f64_u32 {{\$d[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_f64_u32 {{\$d[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_f64_u32 {{\$d[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_f64_u32 {{\$d[0-9]+}}, {{\$s[0-9]+}};
define void @uint_to_fp_v4i32_to_v4f64(<4 x double> addrspace(1)* %out, <4 x i32> addrspace(1)* %in) {
  %value = load <4 x i32> addrspace(1) * %in
  %result = uitofp <4 x i32> %value to <4 x double>
  store <4 x double> %result, <4 x double> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &uint_to_fp_i64_to_f64
; HSAIL: cvt_f64_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @uint_to_fp_i64_to_f64(double addrspace(1)* %out, i64 %in) {
  %tmp0 = uitofp i64 %in to double
  store double %tmp0, double addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &uint_to_fp_i1_to_f64
; HSAIL: cmp_eq_b1_s32 [[CMP:\$c[0-9]+]], {{\$s[0-9]+}}, 0;
; HSAIL: cmov_b64 [[RESULT:\$d[0-9]+]], [[CMP]], 4607182418800017408, 0;
; HSAIL: st_global_align(8)_u64 [[RESULT]]
define void @uint_to_fp_i1_to_f64(double addrspace(1)* %out, i32 %in) {
  %cmp = icmp eq i32 %in, 0
  %fp = uitofp i1 %cmp to double
  store double %fp, double addrspace(1)* %out
  ret void
}
