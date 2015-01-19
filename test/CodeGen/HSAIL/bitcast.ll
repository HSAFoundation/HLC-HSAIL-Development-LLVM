; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

define void @i8ptr_v16i8ptr(<16 x i8> addrspace(1)* %out, i8 addrspace(1)* %in) #0 {
  %tmp0 = bitcast i8 addrspace(1)* %in to <16 x i8> addrspace(1)*
  %tmp1 = load <16 x i8> addrspace(1)* %tmp0
  store <16 x i8> %tmp1, <16 x i8> addrspace(1)* %out
  ret void
}

define void @f32_to_v2i16(<2 x i16> addrspace(1)* %out, float addrspace(1)* %in) #0 {
  %load = load float addrspace(1)* %in, align 4
  %bc = bitcast float %load to <2 x i16>
  store <2 x i16> %bc, <2 x i16> addrspace(1)* %out, align 4
  ret void
}

define void @v2i16_to_f32(float addrspace(1)* %out, <2 x i16> addrspace(1)* %in) #0 {
  %load = load <2 x i16> addrspace(1)* %in, align 4
  %bc = bitcast <2 x i16> %load to float
  store float %bc, float addrspace(1)* %out, align 4
  ret void
}

define void @v4i8_to_i32(i32 addrspace(1)* %out, <4 x i8> addrspace(1)* %in) #0 {
  %load = load <4 x i8> addrspace(1)* %in, align 4
  %bc = bitcast <4 x i8> %load to i32
  store i32 %bc, i32 addrspace(1)* %out, align 4
  ret void
}

define void @i32_to_v4i8(<4 x i8> addrspace(1)* %out, i32 addrspace(1)* %in) #0 {
  %load = load i32 addrspace(1)* %in, align 4
  %bc = bitcast i32 %load to <4 x i8>
  store <4 x i8> %bc, <4 x i8> addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &bitcast_v2i32_to_f64(
define void @bitcast_v2i32_to_f64(double addrspace(1)* %out, <2 x i32> addrspace(1)* %in) #0 {
  %val = load <2 x i32> addrspace(1)* %in, align 8
  %add = add <2 x i32> %val, <i32 4, i32 9>
  %bc = bitcast <2 x i32> %add to double
  store double %bc, double addrspace(1)* %out, align 8
  ret void
}

; HSAIL-LABEL: {{^}}prog function &bitcast_f64_to_v2i32(
define void @bitcast_f64_to_v2i32(<2 x i32> addrspace(1)* %out, double addrspace(1)* %in) #0 {
  %val = load double addrspace(1)* %in, align 8
  %add = fadd double %val, 4.0
  %bc = bitcast double %add to <2 x i32>
  store <2 x i32> %bc, <2 x i32> addrspace(1)* %out, align 8
  ret void
}

; HSAIL-LABEL: {{^}}prog function &bitcast_i64_to_f64(
; HSAIL: add_u64 [[RESULT:\$d[0-9]+]],
; HSAIL: st_global_align(8)_u64 [[RESULT]]
define void @bitcast_i64_to_f64(double addrspace(1)* %out, i64 addrspace(1)* %in) #0 {
  %val = load i64 addrspace(1)* %in, align 8
  %add = add i64 %val, 12345
  %bc = bitcast i64 %add to double
  store double %bc, double addrspace(1)* %out, align 8
  ret void
}

; HSAIL-LABEL: {{^}}prog function &bitcast_f64_to_i64(
; HSAIL: add_f64 [[RESULT:\$d[0-9]+]],
; HSAIL: st_global_align(8)_f64 [[RESULT]]
define void @bitcast_f64_to_i64(i64 addrspace(1)* %out, double addrspace(1)* %in) #0 {
  %val = load double addrspace(1)* %in, align 8
  %add = fadd double %val, 4.0
  %bc = bitcast double %add to i64
  store i64 %bc, i64 addrspace(1)* %out, align 8
  ret void
}

; HSAIL-LABEL: {{^}}prog function &bitcast_i32_to_f32(
; HSAIL: add_u32 [[RESULT:\$s[0-9]+]],
; HSAIL: st_global_align(4)_u32 [[RESULT]]
define void @bitcast_i32_to_f32(float addrspace(1)* %out, i32 addrspace(1)* %in) #0 {
  %val = load i32 addrspace(1)* %in, align 4
  %add = add i32 %val, 12345
  %bc = bitcast i32 %add to float
  store float %bc, float addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &bitcast_f32_to_i32(
; HSAIL: add_ftz_f32 [[RESULT:\$s[0-9]+]],
; HSAIL: st_global_align(4)_f32 [[RESULT]]
define void @bitcast_f32_to_i32(i32 addrspace(1)* %out, float addrspace(1)* %in) #0 {
  %val = load float addrspace(1)* %in, align 4
  %add = fadd float %val, 4.0
  %bc = bitcast float %add to i32
  store i32 %bc, i32 addrspace(1)* %out, align 4
  ret void
}

attributes #0 = { nounwind }
