; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &global_truncstore_i32_to_i1(
; HSAIL: ld_arg_align(4)_u32 [[VAL:\$s[0-9]+]]
; HSAIL: and_b32 [[AND:\$s[0-9]+]], [[VAL]], 1;
; HSAIL: st_global_u8 [[AND]]
define void @global_truncstore_i32_to_i1(i1 addrspace(1)* %out, i32 %val) nounwind {
  %trunc = trunc i32 %val to i1
  store i1 %trunc, i1 addrspace(1)* %out, align 1
  ret void
}

; SI-LABEL: {{^}}prog function &global_truncstore_i64_to_i1(
; HSAIL: ld_arg_align(8)_u64 [[VAL:\$d[0-9]+]]
; HSAIL: and_b64 [[AND:\$d[0-9]+]], [[VAL]], 1;
; HSAIL: cvt_b1_u64 [[CVT0:\$c[0-9]+]], [[AND]];
; HSAIL: cvt_s32_b1 [[CVT1:\$s[0-9]+]], [[CVT0]];
; HSAIL: st_global_u8 [[CVT1]]
define void @global_truncstore_i64_to_i1(i1 addrspace(1)* %out, i64 %val) nounwind {
  %trunc = trunc i64 %val to i1
  store i1 %trunc, i1 addrspace(1)* %out, align 1
  ret void
}

; SI-LABEL: {{^}}prog function &global_truncstore_i16_to_i1(
; HSAIL: ld_arg_align(2)_u16 [[VAL:\$s[0-9]+]]
; HSAIL: and_b32 [[AND:\$s[0-9]+]], [[VAL]], 1;
; HSAIL: st_global_u8 [[AND]]
define void @global_truncstore_i16_to_i1(i1 addrspace(1)* %out, i16 %val) nounwind {
  %trunc = trunc i16 %val to i1
  store i1 %trunc, i1 addrspace(1)* %out, align 1
  ret void
}
