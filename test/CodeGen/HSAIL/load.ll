; RUN: llc < %s -march=hsail | FileCheck --check-prefix=HSAIL --check-prefix=FUNC %s

;===------------------------------------------------------------------------===;
; GLOBAL ADDRESS SPACE
;===------------------------------------------------------------------------===;

; Load an i8 value from the global address space.

define void @load_i8(i32 addrspace(1)* %out, i8 addrspace(1)* %in) {
  %1 = load i8 addrspace(1)* %in
  %2 = zext i8 %1 to i32
  store i32 %2, i32 addrspace(1)* %out
  ret void
}

define void @load_i8_sext(i32 addrspace(1)* %out, i8 addrspace(1)* %in) {
entry:
  %0 = load i8 addrspace(1)* %in
  %1 = sext i8 %0 to i32
  store i32 %1, i32 addrspace(1)* %out
  ret void
}

define void @load_v2i8(<2 x i32> addrspace(1)* %out, <2 x i8> addrspace(1)* %in) {
entry:
  %0 = load <2 x i8> addrspace(1)* %in
  %1 = zext <2 x i8> %0 to <2 x i32>
  store <2 x i32> %1, <2 x i32> addrspace(1)* %out
  ret void
}

define void @load_v2i8_sext(<2 x i32> addrspace(1)* %out, <2 x i8> addrspace(1)* %in) {
entry:
  %0 = load <2 x i8> addrspace(1)* %in
  %1 = sext <2 x i8> %0 to <2 x i32>
  store <2 x i32> %1, <2 x i32> addrspace(1)* %out
  ret void
}

define void @load_v4i8(<4 x i32> addrspace(1)* %out, <4 x i8> addrspace(1)* %in) {
entry:
  %0 = load <4 x i8> addrspace(1)* %in
  %1 = zext <4 x i8> %0 to <4 x i32>
  store <4 x i32> %1, <4 x i32> addrspace(1)* %out
  ret void
}

define void @load_v4i8_sext(<4 x i32> addrspace(1)* %out, <4 x i8> addrspace(1)* %in) {
entry:
  %0 = load <4 x i8> addrspace(1)* %in
  %1 = sext <4 x i8> %0 to <4 x i32>
  store <4 x i32> %1, <4 x i32> addrspace(1)* %out
  ret void
}

; Load an i16 value from the global address space.
define void @load_i16(i32 addrspace(1)* %out, i16 addrspace(1)* %in) {
entry:
  %0 = load i16	 addrspace(1)* %in
  %1 = zext i16 %0 to i32
  store i32 %1, i32 addrspace(1)* %out
  ret void
}

define void @load_i16_sext(i32 addrspace(1)* %out, i16 addrspace(1)* %in) {
entry:
  %0 = load i16 addrspace(1)* %in
  %1 = sext i16 %0 to i32
  store i32 %1, i32 addrspace(1)* %out
  ret void
}

define void @load_v2i16(<2 x i32> addrspace(1)* %out, <2 x i16> addrspace(1)* %in) {
entry:
  %0 = load <2 x i16> addrspace(1)* %in
  %1 = zext <2 x i16> %0 to <2 x i32>
  store <2 x i32> %1, <2 x i32> addrspace(1)* %out
  ret void
}

define void @load_v2i16_sext(<2 x i32> addrspace(1)* %out, <2 x i16> addrspace(1)* %in) {
entry:
  %0 = load <2 x i16> addrspace(1)* %in
  %1 = sext <2 x i16> %0 to <2 x i32>
  store <2 x i32> %1, <2 x i32> addrspace(1)* %out
  ret void
}

define void @load_v4i16(<4 x i32> addrspace(1)* %out, <4 x i16> addrspace(1)* %in) {
entry:
  %0 = load <4 x i16> addrspace(1)* %in
  %1 = zext <4 x i16> %0 to <4 x i32>
  store <4 x i32> %1, <4 x i32> addrspace(1)* %out
  ret void
}

define void @load_v4i16_sext(<4 x i32> addrspace(1)* %out, <4 x i16> addrspace(1)* %in) {
entry:
  %0 = load <4 x i16> addrspace(1)* %in
  %1 = sext <4 x i16> %0 to <4 x i32>
  store <4 x i32> %1, <4 x i32> addrspace(1)* %out
  ret void
}

; load an i32 value from the global address space.

define void @load_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %in) {
entry:
  %0 = load i32 addrspace(1)* %in
  store i32 %0, i32 addrspace(1)* %out
  ret void
}

; load a f32 value from the global address space.

define void @load_f32(float addrspace(1)* %out, float addrspace(1)* %in) {
entry:
  %0 = load float addrspace(1)* %in
  store float %0, float addrspace(1)* %out
  ret void
}

; load a v2f32 value from the global address space
define void @load_v2f32(<2 x float> addrspace(1)* %out, <2 x float> addrspace(1)* %in) {
entry:
  %0 = load <2 x float> addrspace(1)* %in
  store <2 x float> %0, <2 x float> addrspace(1)* %out
  ret void
}

define void @load_i64(i64 addrspace(1)* %out, i64 addrspace(1)* %in) {
entry:
  %0 = load i64 addrspace(1)* %in
  store i64 %0, i64 addrspace(1)* %out
  ret void
}


define void @load_i64_sext(i64 addrspace(1)* %out, i32 addrspace(1)* %in) {
entry:
  %0 = load i32 addrspace(1)* %in
  %1 = sext i32 %0 to i64
  store i64 %1, i64 addrspace(1)* %out
  ret void
}

define void @load_i64_zext(i64 addrspace(1)* %out, i32 addrspace(1)* %in) {
entry:
  %0 = load i32 addrspace(1)* %in
  %1 = zext i32 %0 to i64
  store i64 %1, i64 addrspace(1)* %out
  ret void
}

; XXX: We should be using DWORDX4 instructions on SI.
define void @load_v8i32(<8 x i32> addrspace(1)* %out, <8 x i32> addrspace(1)* %in) {
entry:
  %0 = load <8 x i32> addrspace(1)* %in
  store <8 x i32> %0, <8 x i32> addrspace(1)* %out
  ret void
}

; XXX: We should be using DWORDX4 instructions on SI.
define void @load_v16i32(<16 x i32> addrspace(1)* %out, <16 x i32> addrspace(1)* %in) {
entry:
  %0 = load <16 x i32> addrspace(1)* %in
  store <16 x i32> %0, <16 x i32> addrspace(1)* %out
  ret void
}

;===------------------------------------------------------------------------===;
; CONSTANT ADDRESS SPACE
;===------------------------------------------------------------------------===;

; Load a sign-extended i8 value
define void @load_const_i8_sext(i32 addrspace(1)* %out, i8 addrspace(2)* %in) {
entry:
  %0 = load i8 addrspace(2)* %in
  %1 = sext i8 %0 to i32
  store i32 %1, i32 addrspace(1)* %out
  ret void
}

; Load an aligned i8 value
define void @load_const_i8_aligned(i32 addrspace(1)* %out, i8 addrspace(2)* %in) {
entry:
  %0 = load i8 addrspace(2)* %in
  %1 = zext i8 %0 to i32
  store i32 %1, i32 addrspace(1)* %out
  ret void
}

; Load an un-aligned i8 value
define void @load_const_i8_unaligned(i32 addrspace(1)* %out, i8 addrspace(2)* %in) {
entry:
  %0 = getelementptr i8 addrspace(2)* %in, i32 1
  %1 = load i8 addrspace(2)* %0
  %2 = zext i8 %1 to i32
  store i32 %2, i32 addrspace(1)* %out
  ret void
}

; Load a sign-extended i16 value
define void @load_const_i16_sext(i32 addrspace(1)* %out, i16 addrspace(2)* %in) {
entry:
  %0 = load i16 addrspace(2)* %in
  %1 = sext i16 %0 to i32
  store i32 %1, i32 addrspace(1)* %out
  ret void
}

; Load an aligned i16 value
define void @load_const_i16_aligned(i32 addrspace(1)* %out, i16 addrspace(2)* %in) {
entry:
  %0 = load i16 addrspace(2)* %in
  %1 = zext i16 %0 to i32
  store i32 %1, i32 addrspace(1)* %out
  ret void
}

; Load an un-aligned i16 value
define void @load_const_i16_unaligned(i32 addrspace(1)* %out, i16 addrspace(2)* %in) {
entry:
  %0 = getelementptr i16 addrspace(2)* %in, i32 1
  %1 = load i16 addrspace(2)* %0
  %2 = zext i16 %1 to i32
  store i32 %2, i32 addrspace(1)* %out
  ret void
}

; Load an i32 value from the constant address space.

define void @load_const_addrspace_i32(i32 addrspace(1)* %out, i32 addrspace(2)* %in) {
entry:
  %0 = load i32 addrspace(2)* %in
  store i32 %0, i32 addrspace(1)* %out
  ret void
}

; Load a f32 value from the constant address space.

define void @load_const_addrspace_f32(float addrspace(1)* %out, float addrspace(2)* %in) {
  %1 = load float addrspace(2)* %in
  store float %1, float addrspace(1)* %out
  ret void
}

;===------------------------------------------------------------------------===;
; LOCAL ADDRESS SPACE
;===------------------------------------------------------------------------===;

; Load an i8 value from the local address space.
define void @load_i8_local(i32 addrspace(1)* %out, i8 addrspace(3)* %in) {
  %1 = load i8 addrspace(3)* %in
  %2 = zext i8 %1 to i32
  store i32 %2, i32 addrspace(1)* %out
  ret void
}

define void @load_i8_sext_local(i32 addrspace(1)* %out, i8 addrspace(3)* %in) {
entry:
  %0 = load i8 addrspace(3)* %in
  %1 = sext i8 %0 to i32
  store i32 %1, i32 addrspace(1)* %out
  ret void
}

define void @load_v2i8_local(<2 x i32> addrspace(1)* %out, <2 x i8> addrspace(3)* %in) {
entry:
  %0 = load <2 x i8> addrspace(3)* %in
  %1 = zext <2 x i8> %0 to <2 x i32>
  store <2 x i32> %1, <2 x i32> addrspace(1)* %out
  ret void
}

define void @load_v2i8_sext_local(<2 x i32> addrspace(1)* %out, <2 x i8> addrspace(3)* %in) {
entry:
  %0 = load <2 x i8> addrspace(3)* %in
  %1 = sext <2 x i8> %0 to <2 x i32>
  store <2 x i32> %1, <2 x i32> addrspace(1)* %out
  ret void
}

define void @load_v4i8_local(<4 x i32> addrspace(1)* %out, <4 x i8> addrspace(3)* %in) {
entry:
  %0 = load <4 x i8> addrspace(3)* %in
  %1 = zext <4 x i8> %0 to <4 x i32>
  store <4 x i32> %1, <4 x i32> addrspace(1)* %out
  ret void
}

define void @load_v4i8_sext_local(<4 x i32> addrspace(1)* %out, <4 x i8> addrspace(3)* %in) {
entry:
  %0 = load <4 x i8> addrspace(3)* %in
  %1 = sext <4 x i8> %0 to <4 x i32>
  store <4 x i32> %1, <4 x i32> addrspace(1)* %out
  ret void
}

; Load an i16 value from the local address space.
define void @load_i16_local(i32 addrspace(1)* %out, i16 addrspace(3)* %in) {
entry:
  %0 = load i16	 addrspace(3)* %in
  %1 = zext i16 %0 to i32
  store i32 %1, i32 addrspace(1)* %out
  ret void
}

define void @load_i16_sext_local(i32 addrspace(1)* %out, i16 addrspace(3)* %in) {
entry:
  %0 = load i16 addrspace(3)* %in
  %1 = sext i16 %0 to i32
  store i32 %1, i32 addrspace(1)* %out
  ret void
}

define void @load_v2i16_local(<2 x i32> addrspace(1)* %out, <2 x i16> addrspace(3)* %in) {
entry:
  %0 = load <2 x i16> addrspace(3)* %in
  %1 = zext <2 x i16> %0 to <2 x i32>
  store <2 x i32> %1, <2 x i32> addrspace(1)* %out
  ret void
}

define void @load_v2i16_sext_local(<2 x i32> addrspace(1)* %out, <2 x i16> addrspace(3)* %in) {
entry:
  %0 = load <2 x i16> addrspace(3)* %in
  %1 = sext <2 x i16> %0 to <2 x i32>
  store <2 x i32> %1, <2 x i32> addrspace(1)* %out
  ret void
}

define void @load_v4i16_local(<4 x i32> addrspace(1)* %out, <4 x i16> addrspace(3)* %in) {
entry:
  %0 = load <4 x i16> addrspace(3)* %in
  %1 = zext <4 x i16> %0 to <4 x i32>
  store <4 x i32> %1, <4 x i32> addrspace(1)* %out
  ret void
}

define void @load_v4i16_sext_local(<4 x i32> addrspace(1)* %out, <4 x i16> addrspace(3)* %in) {
entry:
  %0 = load <4 x i16> addrspace(3)* %in
  %1 = sext <4 x i16> %0 to <4 x i32>
  store <4 x i32> %1, <4 x i32> addrspace(1)* %out
  ret void
}

; load an i32 value from the local address space.
define void @load_i32_local(i32 addrspace(1)* %out, i32 addrspace(3)* %in) {
entry:
  %0 = load i32 addrspace(3)* %in
  store i32 %0, i32 addrspace(1)* %out
  ret void
}

; load a f32 value from the local address space.
define void @load_f32_local(float addrspace(1)* %out, float addrspace(3)* %in) {
entry:
  %0 = load float addrspace(3)* %in
  store float %0, float addrspace(1)* %out
  ret void
}

; load a v2f32 value from the local address space
define void @load_v2f32_local(<2 x float> addrspace(1)* %out, <2 x float> addrspace(3)* %in) {
entry:
  %0 = load <2 x float> addrspace(3)* %in
  store <2 x float> %0, <2 x float> addrspace(1)* %out
  ret void
}
