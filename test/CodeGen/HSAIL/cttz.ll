; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.cttz.i32(i32, i1) #0
declare <2 x i32> @llvm.cttz.v2i32(<2 x i32>, i1) #0
declare <4 x i32> @llvm.cttz.v4i32(<4 x i32>, i1) #0

declare i64 @llvm.cttz.i64(i64, i1) #0
declare <2 x i64> @llvm.cttz.v2i64(<2 x i64>, i1) #0
declare <4 x i64> @llvm.cttz.v4i64(<4 x i64>, i1) #0

; HSAIL-LABEL: {{^}}prog function &s_cttz_i32(
; HSAIL: lastbit_u32_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @s_cttz_i32(i32 addrspace(1)* noalias %out, i32 %val) #1 {
  %cttz = call i32 @llvm.cttz.i32(i32 %val, i1 false) #0
  store i32 %cttz, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_cttz_i32(
; HSAIL: lastbit_u32_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @v_cttz_i32(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %valptr) #1 {
  %val = load i32 addrspace(1)* %valptr
  %cttz = call i32 @llvm.cttz.i32(i32 %val, i1 false) #0
  store i32 %cttz, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_cttz_v2i32(
; HSAIL: lastbit_u32_u32
; HSAIL: lastbit_u32_u32
define void @v_cttz_v2i32(<2 x i32> addrspace(1)* noalias %out, <2 x i32> addrspace(1)* noalias %valptr) #1 {
  %val = load <2 x i32> addrspace(1)* %valptr
  %cttz = call <2 x i32> @llvm.cttz.v2i32(<2 x i32> %val, i1 false) #0
  store <2 x i32> %cttz, <2 x i32> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_cttz_v4i32(
; HSAIL: lastbit_u32_u32
; HSAIL: lastbit_u32_u32
; HSAIL: lastbit_u32_u32
; HSAIL: lastbit_u32_u32
define void @v_cttz_v4i32(<4 x i32> addrspace(1)* noalias %out, <4 x i32> addrspace(1)* noalias %valptr) #1 {
  %val = load <4 x i32> addrspace(1)* %valptr
  %cttz = call <4 x i32> @llvm.cttz.v4i32(<4 x i32> %val, i1 false) #0
  store <4 x i32> %cttz, <4 x i32> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &s_cttz_i64(
; HSAIL: lastbit_u32_u64 [[CTTZ:\$s[0-9]+]], {{\$d[0-9]+}};
; HSAIL: cvt_u64_u32 [[EXT:\$d[0-9]+]], [[CTTZ]];
; HSAIL: st_global_align(8)_u64 [[EXT]]
define void @s_cttz_i64(i64 addrspace(1)* noalias %out, i64 %val) #1 {
  %cttz = call i64 @llvm.cttz.i64(i64 %val, i1 false) #0
  store i64 %cttz, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &s_cttz_i64_trunc_i32(
; HSAIL: lastbit_u32_u64 [[CTTZ:\$s[0-9]+]], {{\$d[0-9]+}};
; HSAIL-NOT: cvt
; HSAIL: st_global_align(4)_u32 [[CTTZ]]
define void @s_cttz_i64_trunc_i32(i32 addrspace(1)* noalias %out, i64 %val) #1 {
  %cttz = call i64 @llvm.cttz.i64(i64 %val, i1 false) #0
  %trunc.cttz = trunc i64 %cttz to i32
  store i32 %trunc.cttz, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_cttz_i64(
; HSAIL: lastbit_u32_u64 {{\$s[0-9]+}}, {{\$d[0-9]+}};
define void @v_cttz_i64(i64 addrspace(1)* noalias %out, i64 addrspace(1)* noalias %valptr) #1 {
  %val = load i64 addrspace(1)* %valptr
  %cttz = call i64 @llvm.cttz.i64(i64 %val, i1 false) #0
  store i64 %cttz, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_cttz_v2i64(
; HSAIL: lastbit_u32_u64
; HSAIL: lastbit_u32_u64
define void @v_cttz_v2i64(<2 x i64> addrspace(1)* noalias %out, <2 x i64> addrspace(1)* noalias %valptr) #1 {
  %val = load <2 x i64> addrspace(1)* %valptr
  %cttz = call <2 x i64> @llvm.cttz.v2i64(<2 x i64> %val, i1 false) #0
  store <2 x i64> %cttz, <2 x i64> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_cttz_v4i64(
; HSAIL: lastbit_u32_u64
; HSAIL: lastbit_u32_u64
; HSAIL: lastbit_u32_u64
; HSAIL: lastbit_u32_u64
define void @v_cttz_v4i64(<4 x i64> addrspace(1)* noalias %out, <4 x i64> addrspace(1)* noalias %valptr) #1 {
  %val = load <4 x i64> addrspace(1)* %valptr
  %cttz = call <4 x i64> @llvm.cttz.v4i64(<4 x i64> %val, i1 false) #0
  store <4 x i64> %cttz, <4 x i64> addrspace(1)* %out
  ret void
}

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
