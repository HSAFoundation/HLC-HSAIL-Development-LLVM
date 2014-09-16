; RUN: llc < %s -march=hsail | FileCheck --check-prefix=HSAIL --check-prefix=FUNC %s

;===------------------------------------------------------------------------===;
; Global Address Space
;===------------------------------------------------------------------------===;

define void @store_i1(i1 addrspace(1)* %out) {
entry:
  store i1 true, i1 addrspace(1)* %out
  ret void
}

define void @store_i8(i8 addrspace(1)* %out, i8 %in) {
entry:
  store i8 %in, i8 addrspace(1)* %out
  ret void
}

define void @store_i16(i16 addrspace(1)* %out, i16 %in) {
entry:
  store i16 %in, i16 addrspace(1)* %out
  ret void
}

define void @store_v2i8(<2 x i8> addrspace(1)* %out, <2 x i32> %in) {
entry:
  %0 = trunc <2 x i32> %in to <2 x i8>
  store <2 x i8> %0, <2 x i8> addrspace(1)* %out
  ret void
}


define void @store_v2i16(<2 x i16> addrspace(1)* %out, <2 x i32> %in) {
entry:
  %0 = trunc <2 x i32> %in to <2 x i16>
  store <2 x i16> %0, <2 x i16> addrspace(1)* %out
  ret void
}

define void @store_v4i8(<4 x i8> addrspace(1)* %out, <4 x i32> %in) {
entry:
  %0 = trunc <4 x i32> %in to <4 x i8>
  store <4 x i8> %0, <4 x i8> addrspace(1)* %out
  ret void
}

; floating-point store

define void @store_f32(float addrspace(1)* %out, float %in) {
  store float %in, float addrspace(1)* %out
  ret void
}

define void @store_v4i16(<4 x i16> addrspace(1)* %out, <4 x i32> %in) {
entry:
  %0 = trunc <4 x i32> %in to <4 x i16>
  store <4 x i16> %0, <4 x i16> addrspace(1)* %out
  ret void
}

; vec2 floating-point stores

define void @store_v2f32(<2 x float> addrspace(1)* %out, float %a, float %b) {
entry:
  %0 = insertelement <2 x float> <float 0.0, float 0.0>, float %a, i32 0
  %1 = insertelement <2 x float> %0, float %b, i32 1
  store <2 x float> %1, <2 x float> addrspace(1)* %out
  ret void
}

define void @store_v4i32(<4 x i32> addrspace(1)* %out, <4 x i32> %in) {
entry:
  store <4 x i32> %in, <4 x i32> addrspace(1)* %out
  ret void
}

define void @store_i64_i8(i8 addrspace(1)* %out, i64 %in) {
entry:
  %0 = trunc i64 %in to i8
  store i8 %0, i8 addrspace(1)* %out
  ret void
}

define void @store_i64_i16(i16 addrspace(1)* %out, i64 %in) {
entry:
  %0 = trunc i64 %in to i16
  store i16 %0, i16 addrspace(1)* %out
  ret void
}

;===------------------------------------------------------------------------===;
; Local Address Space
;===------------------------------------------------------------------------===;

define void @store_local_i1(i1 addrspace(3)* %out) {
entry:
  store i1 true, i1 addrspace(3)* %out
  ret void
}

define void @store_local_i8(i8 addrspace(3)* %out, i8 %in) {
  store i8 %in, i8 addrspace(3)* %out
  ret void
}

define void @store_local_i16(i16 addrspace(3)* %out, i16 %in) {
  store i16 %in, i16 addrspace(3)* %out
  ret void
}

define void @store_local_v2i16(<2 x i16> addrspace(3)* %out, <2 x i16> %in) {
entry:
  store <2 x i16> %in, <2 x i16> addrspace(3)* %out
  ret void
}

define void @store_local_v4i8(<4 x i8> addrspace(3)* %out, <4 x i8> %in) {
entry:
  store <4 x i8> %in, <4 x i8> addrspace(3)* %out
  ret void
}

define void @store_local_v2i32(<2 x i32> addrspace(3)* %out, <2 x i32> %in) {
entry:
  store <2 x i32> %in, <2 x i32> addrspace(3)* %out
  ret void
}

define void @store_local_v4i32(<4 x i32> addrspace(3)* %out, <4 x i32> %in) {
entry:
  store <4 x i32> %in, <4 x i32> addrspace(3)* %out
  ret void
}

define void @store_local_i64_i8(i8 addrspace(3)* %out, i64 %in) {
entry:
  %0 = trunc i64 %in to i8
  store i8 %0, i8 addrspace(3)* %out
  ret void
}

define void @store_local_i64_i16(i16 addrspace(3)* %out, i64 %in) {
entry:
  %0 = trunc i64 %in to i16
  store i16 %0, i16 addrspace(3)* %out
  ret void
}

; The stores in this function are combined by the optimizer to create a
; 64-bit store with 32-bit alignment.  This is legal for SI and the legalizer
; should not try to split the 64-bit store back into 2 32-bit stores.
;
; be two 32-bit stores.

define void @vecload2(i32 addrspace(1)* nocapture %out, i32 addrspace(2)* nocapture %mem) #0 {
entry:
  %0 = load i32 addrspace(2)* %mem, align 4
  %arrayidx1.i = getelementptr inbounds i32 addrspace(2)* %mem, i64 1
  %1 = load i32 addrspace(2)* %arrayidx1.i, align 4
  store i32 %0, i32 addrspace(1)* %out, align 4
  %arrayidx1 = getelementptr inbounds i32 addrspace(1)* %out, i64 1
  store i32 %1, i32 addrspace(1)* %arrayidx1, align 4
  ret void
}

attributes #0 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "unsafe-fp-math"="false" "use-soft-float"="false" }

; When i128 was a legal type this program generated cannot select errors:

define void @i128-const-store(i32 addrspace(1)* %out) {
entry:
  store i32 1, i32 addrspace(1)* %out, align 4
  %arrayidx2 = getelementptr inbounds i32 addrspace(1)* %out, i64 1
  store i32 1, i32 addrspace(1)* %arrayidx2, align 4
  %arrayidx4 = getelementptr inbounds i32 addrspace(1)* %out, i64 2
  store i32 2, i32 addrspace(1)* %arrayidx4, align 4
  %arrayidx6 = getelementptr inbounds i32 addrspace(1)* %out, i64 3
  store i32 2, i32 addrspace(1)* %arrayidx6, align 4
  ret void
}
