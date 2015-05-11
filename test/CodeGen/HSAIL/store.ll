; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

;===------------------------------------------------------------------------===;
; Global Address Space
;===------------------------------------------------------------------------===;

; FUNC-LABEL: {{^}}prog function &store_i1_const
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL: st_global_u8 255, {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_i1_const(i1 addrspace(1)* %out) {
  store i1 true, i1 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_i1_cmp
; HSAIL-DAG: cmp_eq_b1_s32 [[COND:\$c[0-9]+]], {{\$s[0-9]+}}, 1234
; HSAIL-DAG: cmov_b32 [[REG:\$s[0-9]+]], [[COND]], 4294967295, 0;
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL: st_global_u8 [[REG]], {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_i1_cmp(i1 addrspace(1)* %out, i32 %a) {
  %cmp = icmp eq i32 %a, 1234
  store i1 %cmp, i1 addrspace(1)* %out
  ret void
}

; FIXME: This should be using ld_arg_u8
; FUNC-LABEL: {{^}}prog function &store_i1_arg
; HSAIL-DAG: ld_arg_u8 [[ARG:\$s[0-9]+]], [%arg];
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL-DAG: and_b32 [[REG:\$s[0-9]+]], [[ARG]], 1;
; HSAIL: st_global_u8 [[REG]], {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_i1_arg(i1 addrspace(1)* %out, i1 %arg) {
  store i1 %arg, i1 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_i8
; HSAIL-DAG: ld_arg_u8 [[IN:\$s[0-9]+]], [%in];
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL: st_global_u8 [[IN]], {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_i8(i8 addrspace(1)* %out, i8 %in) {
  store i8 %in, i8 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_i16
; HSAIL-DAG: ld_arg_align(2)_u16 [[IN:\$s[0-9]+]], [%in];
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL: st_global_align(2)_u16 [[IN]], {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_i16(i16 addrspace(1)* %out, i16 %in) {
  store i16 %in, i16 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_i32
; HSAIL-DAG: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL: st_global_align(4)_u32 [[IN]], {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_i32(i32 addrspace(1)* %out, i32 %in) {
  store i32 %in, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_imm_neg1_i32(
; HSAIL: st_global_align(4)_u32 4294967295, {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_imm_neg1_i32(i32 addrspace(1)* %out) {
  store i32 -1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_v2i8
define void @store_v2i8(<2 x i8> addrspace(1)* %out, <2 x i32> %in) {
  %tmp0 = trunc <2 x i32> %in to <2 x i8>
  store <2 x i8> %tmp0, <2 x i8> addrspace(1)* %out
  ret void
}


; FUNC-LABEL: {{^}}prog function &store_v2i16
define void @store_v2i16(<2 x i16> addrspace(1)* %out, <2 x i32> %in) {
  %tmp0 = trunc <2 x i32> %in to <2 x i16>
  store <2 x i16> %tmp0, <2 x i16> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_v4i8
define void @store_v4i8(<4 x i8> addrspace(1)* %out, <4 x i32> %in) {
  %tmp0 = trunc <4 x i32> %in to <4 x i8>
  store <4 x i8> %tmp0, <4 x i8> addrspace(1)* %out
  ret void
}


; FUNC-LABEL: {{^}}prog function &store_v4i16
define void @store_v4i16(<4 x i16> addrspace(1)* %out, <4 x i32> %in) {
  %tmp0 = trunc <4 x i32> %in to <4 x i16>
  store <4 x i16> %tmp0, <4 x i16> addrspace(1)* %out
  ret void
}

; floating-point store

; FUNC-LABEL: {{^}}prog function &store_f32(
; HSAIL-DAG: ld_arg_align(4)_f32 [[IN:\$s[0-9]+]], [%in];
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL: st_global_align(4)_f32 [[IN]], {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_f32(float addrspace(1)* %out, float %in) {
  store float %in, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_f32_imm(
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL: st_global_align(4)_u32 3212836864, {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_f32_imm(float addrspace(1)* %out) {
  store float -1.0, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_f64
; HSAIL-DAG: ld_arg_align(8)_f64 [[IN:\$d[0-9]+]], [%in];
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL: st_global_align(8)_f64 [[IN]], {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_f64(double addrspace(1)* %out, double %in) {
  store double %in, double addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_v2f32
define void @store_v2f32(<2 x float> addrspace(1)* %out, float %a, float %b) {
  %tmp0 = insertelement <2 x float> zeroinitializer, float %a, i32 0
  %tmp1 = insertelement <2 x float> %tmp0, float %b, i32 1
  store <2 x float> %tmp1, <2 x float> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_v4f32
define void @store_v4f32(<4 x float> addrspace(1)* %out, float %a, float %b, float %c, float %d) {
  %tmp0 = insertelement <4 x float> zeroinitializer, float %a, i32 0
  %tmp1 = insertelement <4 x float> %tmp0, float %b, i32 1
  %tmp2 = insertelement <4 x float> %tmp1, float %c, i32 2
  %tmp3 = insertelement <4 x float> %tmp2, float %d, i32 3
  store <4 x float> %tmp3, <4 x float> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_v2f64
define void @store_v2f64(<2 x double> addrspace(1)* %out, double %a, double %b) {
  %tmp0 = insertelement <2 x double> zeroinitializer, double %a, i32 0
  %tmp1 = insertelement <2 x double> %tmp0, double %b, i32 1
  store <2 x double> %tmp1, <2 x double> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_v4f64
define void @store_v4f64(<4 x double> addrspace(1)* %out, double %a, double %b, double %c, double %d) {
  %tmp0 = insertelement <4 x double> zeroinitializer, double %a, i32 0
  %tmp1 = insertelement <4 x double> %tmp0, double %b, i32 1
  %tmp2 = insertelement <4 x double> %tmp1, double %c, i32 2
  %tmp3 = insertelement <4 x double> %tmp2, double %d, i32 3
  store <4 x double> %tmp3, <4 x double> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_v4i32
define void @store_v4i32(<4 x i32> addrspace(1)* %out, <4 x i32> %in) {
  store <4 x i32> %in, <4 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_i64_i8
define void @store_i64_i8(i8 addrspace(1)* %out, i64 %in) {
  %tmp0 = trunc i64 %in to i8
  store i8 %tmp0, i8 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_i64_i16
define void @store_i64_i16(i16 addrspace(1)* %out, i64 %in) {
  %tmp0 = trunc i64 %in to i16
  store i16 %tmp0, i16 addrspace(1)* %out
  ret void
}

;===------------------------------------------------------------------------===;
; Local Address Space
;===------------------------------------------------------------------------===;

; FUNC-LABEL: {{^}}prog function &store_local_i1
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL: st_group_u8 255, {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_local_i1(i1 addrspace(3)* %out) {
  store i1 true, i1 addrspace(3)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_local_i8
; HSAIL-DAG: ld_arg_u8 [[IN:\$s[0-9]+]], [%in];
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL: st_group_u8 [[IN]], {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_local_i8(i8 addrspace(3)* %out, i8 %in) {
  store i8 %in, i8 addrspace(3)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_local_i16
; HSAIL-DAG: ld_arg_align(2)_u16 [[IN:\$s[0-9]+]], [%in];
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL: st_group_align(2)_u16 [[IN]], {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_local_i16(i16 addrspace(3)* %out, i16 %in) {
  store i16 %in, i16 addrspace(3)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_local_i32
; HSAIL-DAG: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL: st_group_align(4)_u32 [[IN]], {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_local_i32(i32 addrspace(3)* %out, i32 %in) {
  store i32 %in, i32 addrspace(3)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_local_v2i16
define void @store_local_v2i16(<2 x i16> addrspace(3)* %out, <2 x i16> %in) {
  store <2 x i16> %in, <2 x i16> addrspace(3)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_local_v4i8
define void @store_local_v4i8(<4 x i8> addrspace(3)* %out, <4 x i8> %in) {
  store <4 x i8> %in, <4 x i8> addrspace(3)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_local_v2i32
define void @store_local_v2i32(<2 x i32> addrspace(3)* %out, <2 x i32> %in) {
  store <2 x i32> %in, <2 x i32> addrspace(3)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_local_v4i32
define void @store_local_v4i32(<4 x i32> addrspace(3)* %out, <4 x i32> %in) {
  store <4 x i32> %in, <4 x i32> addrspace(3)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_local_i64_i8
define void @store_local_i64_i8(i8 addrspace(3)* %out, i64 %in) {
  %tmp0 = trunc i64 %in to i8
  store i8 %tmp0, i8 addrspace(3)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_local_i64_i16
define void @store_local_i64_i16(i16 addrspace(3)* %out, i64 %in) {
  %tmp0 = trunc i64 %in to i16
  store i16 %tmp0, i16 addrspace(3)* %out
  ret void
}

;===------------------------------------------------------------------------===;
; Private Address Space
;===------------------------------------------------------------------------===;

; FUNC-LABEL: {{^}}prog function &store_private_i1
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL: st_private_u8 255, {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_private_i1(i1* %out) {
  store i1 true, i1* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_private_i8
; HSAIL-DAG: ld_arg_u8 [[IN:\$s[0-9]+]], [%in];
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL: st_private_u8 [[IN]], {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_private_i8(i8* %out, i8 %in) {
  store i8 %in, i8* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_private_i16
; HSAIL-DAG: ld_arg_align(2)_u16 [[IN:\$s[0-9]+]], [%in];
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL: st_private_align(2)_u16 [[IN]], {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_private_i16(i16* %out, i16 %in) {
  store i16 %in, i16* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_private_i32
; HSAIL-DAG: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL: st_private_align(4)_u32 [[IN]], {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_private_i32(i32* %out, i32 %in) {
  store i32 %in, i32* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_private_v2i16
define void @store_private_v2i16(<2 x i16>* %out, <2 x i16> %in) {
  store <2 x i16> %in, <2 x i16>* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_private_v4i8
define void @store_private_v4i8(<4 x i8>* %out, <4 x i8> %in) {
  store <4 x i8> %in, <4 x i8>* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_private_v2i32
define void @store_private_v2i32(<2 x i32>* %out, <2 x i32> %in) {
  store <2 x i32> %in, <2 x i32>* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_private_v4i32
define void @store_private_v4i32(<4 x i32>* %out, <4 x i32> %in) {
  store <4 x i32> %in, <4 x i32>* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_private_i64_i8
define void @store_private_i64_i8(i8* %out, i64 %in) {
  %tmp0 = trunc i64 %in to i8
  store i8 %tmp0, i8* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_private_i64_i16
define void @store_private_i64_i16(i16* %out, i64 %in) {
  %tmp0 = trunc i64 %in to i16
  store i16 %tmp0, i16* %out
  ret void
}

;===------------------------------------------------------------------------===;
; Flat Address Space
;===------------------------------------------------------------------------===;

; FUNC-LABEL: {{^}}prog function &store_flat_i1
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL: st_u8 255, {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_flat_i1(i1 addrspace(4)* %out) {
  store i1 true, i1 addrspace(4)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_flat_i8
; HSAIL-DAG: ld_arg_u8 [[IN:\$s[0-9]+]], [%in];
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL: st_u8 [[IN]], {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_flat_i8(i8 addrspace(4)* %out, i8 %in) {
  store i8 %in, i8 addrspace(4)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_flat_i16
; HSAIL-DAG: ld_arg_align(2)_u16 [[IN:\$s[0-9]+]], [%in];
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL: st_align(2)_u16 [[IN]], {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_flat_i16(i16 addrspace(4)* %out, i16 %in) {
  store i16 %in, i16 addrspace(4)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_flat_i32
; HSAIL-DAG: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL: st_align(4)_u32 [[IN]], {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_flat_i32(i32 addrspace(4)* %out, i32 %in) {
  store i32 %in, i32 addrspace(4)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_flat_v2i16
define void @store_flat_v2i16(<2 x i16> addrspace(4)* %out, <2 x i16> %in) {
  store <2 x i16> %in, <2 x i16> addrspace(4)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_flat_v4i8
define void @store_flat_v4i8(<4 x i8> addrspace(4)* %out, <4 x i8> %in) {
  store <4 x i8> %in, <4 x i8> addrspace(4)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_flat_v2i32
define void @store_flat_v2i32(<2 x i32> addrspace(4)* %out, <2 x i32> %in) {
  store <2 x i32> %in, <2 x i32> addrspace(4)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_flat_v4i32
define void @store_flat_v4i32(<4 x i32> addrspace(4)* %out, <4 x i32> %in) {
  store <4 x i32> %in, <4 x i32> addrspace(4)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_flat_i64_i8
define void @store_flat_i64_i8(i8 addrspace(4)* %out, i64 %in) {
  %tmp0 = trunc i64 %in to i8
  store i8 %tmp0, i8 addrspace(4)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_flat_i64_i16
define void @store_flat_i64_i16(i16 addrspace(4)* %out, i64 %in) {
  %tmp0 = trunc i64 %in to i16
  store i16 %tmp0, i16 addrspace(4)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_flat_f32
; HSAIL-DAG: ld_arg_align(4)_f32 [[IN:\$s[0-9]+]], [%in];
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL: st_align(4)_f32 [[IN]], {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_flat_f32(float addrspace(4)* %out, float %in) {
  store float %in, float addrspace(4)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &store_flat_f64
; HSAIL-DAG: ld_arg_align(8)_f64 [[IN:\$d[0-9]+]], [%in];
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL: st_align(8)_f64 [[IN]], {{\[}}[[OUT]]{{\]}}
; HSAIL: ret;
define void @store_flat_f64(double addrspace(4)* %out, double %in) {
  store double %in, double addrspace(4)* %out
  ret void
}

; The stores in this function are combined by the optimizer to create a
; 64-bit store with 32-bit alignment.  This is legal for SI and the legalizer
; should not try to split the 64-bit store back into 2 32-bit stores.
;
; be two 32-bit stores.

; FUNC-LABEL: {{^}}prog function &vecload2
define void @vecload2(i32 addrspace(1)* nocapture %out, i32 addrspace(2)* nocapture %mem) #0 {
  %tmp0 = load i32, i32 addrspace(2)* %mem, align 4
  %arrayidx1.i = getelementptr inbounds i32, i32 addrspace(2)* %mem, i64 1
  %tmp1 = load i32, i32 addrspace(2)* %arrayidx1.i, align 4
  store i32 %tmp0, i32 addrspace(1)* %out, align 4
  %arrayidx1 = getelementptr inbounds i32, i32 addrspace(1)* %out, i64 1
  store i32 %tmp1, i32 addrspace(1)* %arrayidx1, align 4
  ret void
}

; When i128 was a legal type this program generated cannot select errors:
; FUNC-LABEL: {{^}}prog function &i128_const_store
define void @i128_const_store(i32 addrspace(1)* %out) {
  store i32 1, i32 addrspace(1)* %out, align 4
  %arrayidx2 = getelementptr inbounds i32, i32 addrspace(1)* %out, i64 1
  store i32 1, i32 addrspace(1)* %arrayidx2, align 4
  %arrayidx4 = getelementptr inbounds i32, i32 addrspace(1)* %out, i64 2
  store i32 2, i32 addrspace(1)* %arrayidx4, align 4
  %arrayidx6 = getelementptr inbounds i32, i32 addrspace(1)* %out, i64 3
  store i32 2, i32 addrspace(1)* %arrayidx6, align 4
  ret void
}

attributes #0 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "unsafe-fp-math"="false" "use-soft-float"="false" }
