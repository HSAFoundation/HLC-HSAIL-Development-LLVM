; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

;===------------------------------------------------------------------------===;
; GLOBAL ADDRESS SPACE
;===------------------------------------------------------------------------===;

; Load an i8 value from the global address space.

; FUNC-LABEL: {{^}}prog function &load_i8
; HSAIL: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL: ld_global_u8 [[VAL:\$s[0-9]+]], {{\[}}[[IN]]{{\]}};
; HSAIL: st_global_align(4)_u32 [[VAL]]
; HSAIL: ret;
define void @load_i8(i32 addrspace(1)* %out, i8 addrspace(1)* %in) {
  %tmp1 = load i8, i8 addrspace(1)* %in
  %tmp2 = zext i8 %tmp1 to i32
  store i32 %tmp2, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_i8_sext
; HSAIL: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL: ld_global_s8 [[VAL:\$s[0-9]+]], {{\[}}[[IN]]{{\]}};
; HSAIL: st_global_align(4)_u32 [[VAL]]
; HSAIL: ret;
define void @load_i8_sext(i32 addrspace(1)* %out, i8 addrspace(1)* %in) {
  %tmp0 = load i8, i8 addrspace(1)* %in
  %tmp1 = sext i8 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_v2i8
define void @load_v2i8(<2 x i32> addrspace(1)* %out, <2 x i8> addrspace(1)* %in) {
  %tmp0 = load <2 x i8>, <2 x i8> addrspace(1)* %in
  %tmp1 = zext <2 x i8> %tmp0 to <2 x i32>
  store <2 x i32> %tmp1, <2 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_v2i8_sext
define void @load_v2i8_sext(<2 x i32> addrspace(1)* %out, <2 x i8> addrspace(1)* %in) {
  %tmp0 = load <2 x i8>, <2 x i8> addrspace(1)* %in
  %tmp1 = sext <2 x i8> %tmp0 to <2 x i32>
  store <2 x i32> %tmp1, <2 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_v4i8
define void @load_v4i8(<4 x i32> addrspace(1)* %out, <4 x i8> addrspace(1)* %in) {
  %tmp0 = load <4 x i8>, <4 x i8> addrspace(1)* %in
  %tmp1 = zext <4 x i8> %tmp0 to <4 x i32>
  store <4 x i32> %tmp1, <4 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_v4i8_sext
define void @load_v4i8_sext(<4 x i32> addrspace(1)* %out, <4 x i8> addrspace(1)* %in) {
  %tmp0 = load <4 x i8>, <4 x i8> addrspace(1)* %in
  %tmp1 = sext <4 x i8> %tmp0 to <4 x i32>
  store <4 x i32> %tmp1, <4 x i32> addrspace(1)* %out
  ret void
}

; Load an i16 value from the global address space.
; FUNC-LABEL: {{^}}prog function &load_i16
; HSAIL: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL: ld_global_align(2)_u16 [[VAL:\$s[0-9]+]], {{\[}}[[IN]]{{\]}};
; HSAIL: st_global_align(4)_u32 [[VAL]]
; HSAIL: ret;
define void @load_i16(i32 addrspace(1)* %out, i16 addrspace(1)* %in) {
  %tmp0 = load i16	, i16	 addrspace(1)* %in
  %tmp1 = zext i16 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_i16_sext
; HSAIL: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL: ld_global_align(2)_s16 [[VAL:\$s[0-9]+]], {{\[}}[[IN]]{{\]}};
; HSAIL: st_global_align(4)_u32 [[VAL]]
; HSAIL: ret;
define void @load_i16_sext(i32 addrspace(1)* %out, i16 addrspace(1)* %in) {
  %tmp0 = load i16, i16 addrspace(1)* %in
  %tmp1 = sext i16 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_v2i16
define void @load_v2i16(<2 x i32> addrspace(1)* %out, <2 x i16> addrspace(1)* %in) {
  %tmp0 = load <2 x i16>, <2 x i16> addrspace(1)* %in
  %tmp1 = zext <2 x i16> %tmp0 to <2 x i32>
  store <2 x i32> %tmp1, <2 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_v2i16_sext
define void @load_v2i16_sext(<2 x i32> addrspace(1)* %out, <2 x i16> addrspace(1)* %in) {
  %tmp0 = load <2 x i16>, <2 x i16> addrspace(1)* %in
  %tmp1 = sext <2 x i16> %tmp0 to <2 x i32>
  store <2 x i32> %tmp1, <2 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_v4i16
define void @load_v4i16(<4 x i32> addrspace(1)* %out, <4 x i16> addrspace(1)* %in) {
  %tmp0 = load <4 x i16>, <4 x i16> addrspace(1)* %in
  %tmp1 = zext <4 x i16> %tmp0 to <4 x i32>
  store <4 x i32> %tmp1, <4 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_v4i16_sext
define void @load_v4i16_sext(<4 x i32> addrspace(1)* %out, <4 x i16> addrspace(1)* %in) {
  %tmp0 = load <4 x i16>, <4 x i16> addrspace(1)* %in
  %tmp1 = sext <4 x i16> %tmp0 to <4 x i32>
  store <4 x i32> %tmp1, <4 x i32> addrspace(1)* %out
  ret void
}

; load an i32 value from the global address space.

; FUNC-LABEL: {{^}}prog function &load_i32
; HSAIL: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL: ld_global_align(4)_u32 [[VAL:\$s[0-9]+]], {{\[}}[[IN]]{{\]}};
; HSAIL: st_global_align(4)_u32 [[VAL]]
; HSAIL: ret;
define void @load_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %tmp0 = load i32, i32 addrspace(1)* %in
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; load a f32 value from the global address space.

; FUNC-LABEL: {{^}}prog function &load_f32
; HSAIL: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL: ld_global_align(4)_f32 [[VAL:\$s[0-9]+]], {{\[}}[[IN]]{{\]}};
; HSAIL: st_global_align(4)_f32 [[VAL]]
; HSAIL: ret;
define void @load_f32(float addrspace(1)* %out, float addrspace(1)* %in) {
  %tmp0 = load float, float addrspace(1)* %in
  store float %tmp0, float addrspace(1)* %out
  ret void
}

; load a v2f32 value from the global address space
; FUNC-LABEL: {{^}}prog function &load_v2f32
define void @load_v2f32(<2 x float> addrspace(1)* %out, <2 x float> addrspace(1)* %in) {
  %tmp0 = load <2 x float>, <2 x float> addrspace(1)* %in
  store <2 x float> %tmp0, <2 x float> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_f64
; HSAIL: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL: ld_global_align(8)_f64 [[VAL:\$d[0-9]+]], {{\[}}[[IN]]{{\]}};
; HSAIL: st_global_align(8)_f64 [[VAL]]
; HSAIL: ret;
define void @load_f64(double addrspace(1)* %out, double addrspace(1)* %in) {
  %tmp0 = load double, double addrspace(1)* %in
  store double %tmp0, double addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_i64
; HSAIL: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL: ld_global_align(8)_u64 [[VAL:\$d[0-9]+]], {{\[}}[[IN]]{{\]}};
; HSAIL: st_global_align(8)_u64 [[VAL]]
; HSAIL: ret;
define void @load_i64(i64 addrspace(1)* %out, i64 addrspace(1)* %in) {
  %tmp0 = load i64, i64 addrspace(1)* %in
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_i64_sext
define void @load_i64_sext(i64 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %tmp0 = load i32, i32 addrspace(1)* %in
  %tmp1 = sext i32 %tmp0 to i64
  store i64 %tmp1, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_i64_zext
define void @load_i64_zext(i64 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %tmp0 = load i32, i32 addrspace(1)* %in
  %tmp1 = zext i32 %tmp0 to i64
  store i64 %tmp1, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_v8i32
define void @load_v8i32(<8 x i32> addrspace(1)* %out, <8 x i32> addrspace(1)* %in) {
  %tmp0 = load <8 x i32>, <8 x i32> addrspace(1)* %in
  store <8 x i32> %tmp0, <8 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_v16i32
define void @load_v16i32(<16 x i32> addrspace(1)* %out, <16 x i32> addrspace(1)* %in) {
  %tmp0 = load <16 x i32>, <16 x i32> addrspace(1)* %in
  store <16 x i32> %tmp0, <16 x i32> addrspace(1)* %out
  ret void
}

;===------------------------------------------------------------------------===;
; CONSTANT ADDRESS SPACE
;===------------------------------------------------------------------------===;

; Load a sign-extended i8 value
; FUNC-LABEL: {{^}}prog function &load_const_i8_sext
define void @load_const_i8_sext(i32 addrspace(1)* %out, i8 addrspace(2)* %in) {
  %tmp0 = load i8, i8 addrspace(2)* %in
  %tmp1 = sext i8 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; Load an aligned i8 value
; FUNC-LABEL: {{^}}prog function &load_const_i8_aligned
define void @load_const_i8_aligned(i32 addrspace(1)* %out, i8 addrspace(2)* %in) {
  %tmp0 = load i8, i8 addrspace(2)* %in
  %tmp1 = zext i8 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; Load an un-aligned i8 value
; FUNC-LABEL: {{^}}prog function &load_const_i8_unaligned
define void @load_const_i8_unaligned(i32 addrspace(1)* %out, i8 addrspace(2)* %in) {
  %tmp0 = getelementptr i8, i8 addrspace(2)* %in, i32 1
  %tmp1 = load i8, i8 addrspace(2)* %tmp0
  %tmp2 = zext i8 %tmp1 to i32
  store i32 %tmp2, i32 addrspace(1)* %out
  ret void
}

; Load a sign-extended i16 value
; FUNC-LABEL: {{^}}prog function &load_const_i16_sext
define void @load_const_i16_sext(i32 addrspace(1)* %out, i16 addrspace(2)* %in) {
  %tmp0 = load i16, i16 addrspace(2)* %in
  %tmp1 = sext i16 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; Load an aligned i16 value
; FUNC-LABEL: {{^}}prog function &load_const_i16_aligned
define void @load_const_i16_aligned(i32 addrspace(1)* %out, i16 addrspace(2)* %in) {
  %tmp0 = load i16, i16 addrspace(2)* %in
  %tmp1 = zext i16 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; Load an un-aligned i16 value
; FUNC-LABEL: {{^}}prog function &load_const_i16_unaligned
define void @load_const_i16_unaligned(i32 addrspace(1)* %out, i16 addrspace(2)* %in) {
  %tmp0 = getelementptr i16, i16 addrspace(2)* %in, i32 1
  %tmp1 = load i16, i16 addrspace(2)* %tmp0
  %tmp2 = zext i16 %tmp1 to i32
  store i32 %tmp2, i32 addrspace(1)* %out
  ret void
}

; Load an i32 value from the constant address space.

; FUNC-LABEL: {{^}}prog function &load_const_addrspace_i32
define void @load_const_addrspace_i32(i32 addrspace(1)* %out, i32 addrspace(2)* %in) {
  %tmp0 = load i32, i32 addrspace(2)* %in
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; Load a f32 value from the constant address space.

; FUNC-LABEL: {{^}}prog function &load_const_addrspace_f32
define void @load_const_addrspace_f32(float addrspace(1)* %out, float addrspace(2)* %in) {
  %tmp1 = load float, float addrspace(2)* %in
  store float %tmp1, float addrspace(1)* %out
  ret void
}

;===------------------------------------------------------------------------===;
; LOCAL ADDRESS SPACE
;===------------------------------------------------------------------------===;

; Load an i8 value from the local address space.
; FUNC-LABEL: {{^}}prog function &load_i8_local
; HSAIL: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL: ld_group_u8 [[VAL:\$s[0-9]+]], {{\[}}[[IN]]{{\]}};
; HSAIL: st_global_align(4)_u32 [[VAL]]
; HSAIL: ret;
define void @load_i8_local(i32 addrspace(1)* %out, i8 addrspace(3)* %in) {
  %tmp1 = load i8, i8 addrspace(3)* %in
  %tmp2 = zext i8 %tmp1 to i32
  store i32 %tmp2, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_i8_sext_local
; HSAIL: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL: ld_group_s8 [[VAL:\$s[0-9]+]], {{\[}}[[IN]]{{\]}};
; HSAIL: st_global_align(4)_u32 [[VAL]]
; HSAIL: ret;
define void @load_i8_sext_local(i32 addrspace(1)* %out, i8 addrspace(3)* %in) {
  %tmp0 = load i8, i8 addrspace(3)* %in
  %tmp1 = sext i8 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_v2i8_local
define void @load_v2i8_local(<2 x i32> addrspace(1)* %out, <2 x i8> addrspace(3)* %in) {
  %tmp0 = load <2 x i8>, <2 x i8> addrspace(3)* %in
  %tmp1 = zext <2 x i8> %tmp0 to <2 x i32>
  store <2 x i32> %tmp1, <2 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_v2i8_sext_local
define void @load_v2i8_sext_local(<2 x i32> addrspace(1)* %out, <2 x i8> addrspace(3)* %in) {
  %tmp0 = load <2 x i8>, <2 x i8> addrspace(3)* %in
  %tmp1 = sext <2 x i8> %tmp0 to <2 x i32>
  store <2 x i32> %tmp1, <2 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_v4i8_local
define void @load_v4i8_local(<4 x i32> addrspace(1)* %out, <4 x i8> addrspace(3)* %in) {
  %tmp0 = load <4 x i8>, <4 x i8> addrspace(3)* %in
  %tmp1 = zext <4 x i8> %tmp0 to <4 x i32>
  store <4 x i32> %tmp1, <4 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_v4i8_sext_local
define void @load_v4i8_sext_local(<4 x i32> addrspace(1)* %out, <4 x i8> addrspace(3)* %in) {
  %tmp0 = load <4 x i8>, <4 x i8> addrspace(3)* %in
  %tmp1 = sext <4 x i8> %tmp0 to <4 x i32>
  store <4 x i32> %tmp1, <4 x i32> addrspace(1)* %out
  ret void
}

; Load an i16 value from the local address space.
; FUNC-LABEL: {{^}}prog function &load_i16_local
; HSAIL: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL: ld_group_align(2)_u16 [[VAL:\$s[0-9]+]], {{\[}}[[IN]]{{\]}};
; HSAIL: st_global_align(4)_u32 [[VAL]]
; HSAIL: ret;
define void @load_i16_local(i32 addrspace(1)* %out, i16 addrspace(3)* %in) {
  %tmp0 = load i16	, i16	 addrspace(3)* %in
  %tmp1 = zext i16 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_i16_sext_local
; HSAIL: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL: ld_group_align(2)_s16 [[VAL:\$s[0-9]+]], {{\[}}[[IN]]{{\]}};
; HSAIL: st_global_align(4)_u32 [[VAL]]
; HSAIL: ret;
define void @load_i16_sext_local(i32 addrspace(1)* %out, i16 addrspace(3)* %in) {
  %tmp0 = load i16, i16 addrspace(3)* %in
  %tmp1 = sext i16 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_v2i16_local
define void @load_v2i16_local(<2 x i32> addrspace(1)* %out, <2 x i16> addrspace(3)* %in) {
  %tmp0 = load <2 x i16>, <2 x i16> addrspace(3)* %in
  %tmp1 = zext <2 x i16> %tmp0 to <2 x i32>
  store <2 x i32> %tmp1, <2 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_v2i16_sext_local
define void @load_v2i16_sext_local(<2 x i32> addrspace(1)* %out, <2 x i16> addrspace(3)* %in) {
  %tmp0 = load <2 x i16>, <2 x i16> addrspace(3)* %in
  %tmp1 = sext <2 x i16> %tmp0 to <2 x i32>
  store <2 x i32> %tmp1, <2 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_v4i16_local
define void @load_v4i16_local(<4 x i32> addrspace(1)* %out, <4 x i16> addrspace(3)* %in) {
  %tmp0 = load <4 x i16>, <4 x i16> addrspace(3)* %in
  %tmp1 = zext <4 x i16> %tmp0 to <4 x i32>
  store <4 x i32> %tmp1, <4 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_v4i16_sext_local
define void @load_v4i16_sext_local(<4 x i32> addrspace(1)* %out, <4 x i16> addrspace(3)* %in) {
  %tmp0 = load <4 x i16>, <4 x i16> addrspace(3)* %in
  %tmp1 = sext <4 x i16> %tmp0 to <4 x i32>
  store <4 x i32> %tmp1, <4 x i32> addrspace(1)* %out
  ret void
}

; load an i32 value from the local address space.
; FUNC-LABEL: {{^}}prog function &load_i32_local
; HSAIL: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL: ld_group_align(4)_u32 [[VAL:\$s[0-9]+]], {{\[}}[[IN]]{{\]}};
; HSAIL: st_global_align(4)_u32 [[VAL]]
; HSAIL: ret;
define void @load_i32_local(i32 addrspace(1)* %out, i32 addrspace(3)* %in) {
  %tmp0 = load i32, i32 addrspace(3)* %in
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; load a f32 value from the local address space.
; FUNC-LABEL: {{^}}prog function &load_f32_local
; HSAIL: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL: ld_group_align(4)_f32 [[VAL:\$s[0-9]+]], {{\[}}[[IN]]{{\]}};
; HSAIL: st_global_align(4)_f32 [[VAL]]
; HSAIL: ret;
define void @load_f32_local(float addrspace(1)* %out, float addrspace(3)* %in) {
  %tmp0 = load float, float addrspace(3)* %in
  store float %tmp0, float addrspace(1)* %out
  ret void
}

; load a v2f32 value from the local address space
; FUNC-LABEL: {{^}}prog function &load_v2f32_local
define void @load_v2f32_local(<2 x float> addrspace(1)* %out, <2 x float> addrspace(3)* %in) {
  %tmp0 = load <2 x float>, <2 x float> addrspace(3)* %in
  store <2 x float> %tmp0, <2 x float> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_f64_local
; HSAIL: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL: ld_group_align(8)_f64 [[VAL:\$d[0-9]+]], {{\[}}[[IN]]{{\]}};
; HSAIL: st_global_align(8)_f64 [[VAL]]
; HSAIL: ret;
define void @load_f64_local(double addrspace(1)* %out, double addrspace(3)* %in) {
  %tmp0 = load double, double addrspace(3)* %in
  store double %tmp0, double addrspace(1)* %out
  ret void
}
