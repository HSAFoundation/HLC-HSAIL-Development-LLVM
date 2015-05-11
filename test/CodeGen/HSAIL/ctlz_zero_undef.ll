; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.ctlz.i32(i32, i1) #0
declare <2 x i32> @llvm.ctlz.v2i32(<2 x i32>, i1) #0
declare <4 x i32> @llvm.ctlz.v4i32(<4 x i32>, i1) #0

declare i64 @llvm.ctlz.i64(i64, i1) #0
declare <2 x i64> @llvm.ctlz.v2i64(<2 x i64>, i1) #0
declare <4 x i64> @llvm.ctlz.v4i64(<4 x i64>, i1) #0


; HSAIL-LABEL: {{^}}prog function &s_ctlz_zero_undef_i32(
; HSAIL: firstbit_u32_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @s_ctlz_zero_undef_i32(i32 addrspace(1)* noalias %out, i32 %val) #1 {
  %ctlz = call i32 @llvm.ctlz.i32(i32 %val, i1 true) #0
  store i32 %ctlz, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_ctlz_zero_undef_i32(
; HSAIL: firstbit_u32_u32
define void @v_ctlz_zero_undef_i32(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %valptr) #1 {
  %val = load i32, i32 addrspace(1)* %valptr
  %ctlz = call i32 @llvm.ctlz.i32(i32 %val, i1 true) #0
  store i32 %ctlz, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_ctlz_zero_undef_v2i32(
; HSAIL: firstbit_u32_u32
; HSAIL: firstbit_u32_u32
define void @v_ctlz_zero_undef_v2i32(<2 x i32> addrspace(1)* noalias %out, <2 x i32> addrspace(1)* noalias %valptr) #1 {
  %val = load <2 x i32>, <2 x i32> addrspace(1)* %valptr
  %ctlz = call <2 x i32> @llvm.ctlz.v2i32(<2 x i32> %val, i1 true) #0
  store <2 x i32> %ctlz, <2 x i32> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_ctlz_zero_undef_v4i32(
; HSAIL: firstbit_u32_u32
; HSAIL: firstbit_u32_u32
; HSAIL: firstbit_u32_u32
; HSAIL: firstbit_u32_u32
define void @v_ctlz_zero_undef_v4i32(<4 x i32> addrspace(1)* noalias %out, <4 x i32> addrspace(1)* noalias %valptr) #1 {
  %val = load <4 x i32>, <4 x i32> addrspace(1)* %valptr
  %ctlz = call <4 x i32> @llvm.ctlz.v4i32(<4 x i32> %val, i1 true) #0
  store <4 x i32> %ctlz, <4 x i32> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &s_ctlz_zero_undef_i64(
; HSAIL: firstbit_u32_u64 [[CTLZ:\$s[0-9]+]], {{\$d[0-9]+}};
; HSAIL: cvt_u64_u32 [[EXT:\$d[0-9]+]], [[CTLZ]];
; HSAIL: st_global_align(8)_u64 [[EXT]]
define void @s_ctlz_zero_undef_i64(i64 addrspace(1)* noalias %out, i64 %val) #1 {
  %ctlz = call i64 @llvm.ctlz.i64(i64 %val, i1 true) #0
  store i64 %ctlz, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &s_ctlz_zero_undef_i64_trunc_i32(
; HSAIL: firstbit_u32_u64 [[CTLZ:\$s[0-9]+]], {{\$d[0-9]+}};
; HSAIL-NOT: cvt
; HSAIL: st_global_align(4)_u32 [[CTLZ]]
define void @s_ctlz_zero_undef_i64_trunc_i32(i32 addrspace(1)* noalias %out, i64 %val) #1 {
  %ctlz = call i64 @llvm.ctlz.i64(i64 %val, i1 true) #0
  %ctlz.trunc = trunc i64 %ctlz to i32
  store i32 %ctlz.trunc, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_ctlz_zero_undef_i64(
; HSAIL: firstbit_u32_u64
define void @v_ctlz_zero_undef_i64(i64 addrspace(1)* noalias %out, i64 addrspace(1)* noalias %valptr) #1 {
  %val = load i64, i64 addrspace(1)* %valptr
  %ctlz = call i64 @llvm.ctlz.i64(i64 %val, i1 true) #0
  store i64 %ctlz, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_ctlz_zero_undef_v2i64(
; HSAIL: firstbit_u32_u64
; HSAIL: firstbit_u32_u64
define void @v_ctlz_zero_undef_v2i64(<2 x i64> addrspace(1)* noalias %out, <2 x i64> addrspace(1)* noalias %valptr) #1 {
  %val = load <2 x i64>, <2 x i64> addrspace(1)* %valptr
  %ctlz = call <2 x i64> @llvm.ctlz.v2i64(<2 x i64> %val, i1 true) #0
  store <2 x i64> %ctlz, <2 x i64> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_ctlz_zero_undef_v4i64(
; HSAIL: firstbit_u32_u64
; HSAIL: firstbit_u32_u64
; HSAIL: firstbit_u32_u64
; HSAIL: firstbit_u32_u64
define void @v_ctlz_zero_undef_v4i64(<4 x i64> addrspace(1)* noalias %out, <4 x i64> addrspace(1)* noalias %valptr) #1 {
  %val = load <4 x i64>, <4 x i64> addrspace(1)* %valptr
  %ctlz = call <4 x i64> @llvm.ctlz.v4i64(<4 x i64> %val, i1 true) #0
  store <4 x i64> %ctlz, <4 x i64> addrspace(1)* %out
  ret void
}

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
