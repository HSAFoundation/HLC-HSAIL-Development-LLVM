; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &trunc_i64_to_i32_store(
; HSAIL: ld_arg_align(8)_u64 [[ARG:\$d[0-9]]], [%in];
; HSAIL: cvt_u32_u64 [[RESULT:\$s[0-9]+]], [[ARG]];
; HSAIL: st_global_align(4)_u32 [[RESULT]]
define void @trunc_i64_to_i32_store(i32 addrspace(1)* %out, i64 %in) {
  %result = trunc i64 %in to i32
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &trunc_load_shl_i64(
; HSAIL: ld_arg_align(8)_u64 [[ARG:\$d[0-9]]], [%a];
; HSAIL: shl_u64 [[SHL:\$d[0-9]+]], [[ARG]], 2;
; HSAIL: cvt_u32_u64 [[RESULT:\$s[0-9]+]], [[SHL]];
; HSAIL: st_global_align(4)_u32 [[RESULT]]
define void @trunc_load_shl_i64(i32 addrspace(1)* %out, i64 %a) {
  %b = shl i64 %a, 2
  %result = trunc i64 %b to i32
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &trunc_shl_i64(
define void @trunc_shl_i64(i64 addrspace(1)* %out2, i32 addrspace(1)* %out, i64 %a) {
  %aa = add i64 %a, 234 ; Prevent shrinking store.
  %b = shl i64 %aa, 2
  %result = trunc i64 %b to i32
  store i32 %result, i32 addrspace(1)* %out, align 4
  store i64 %b, i64 addrspace(1)* %out2, align 8 ; Prevent reducing ops to 32-bits
  ret void
}

; HSAIL-LABEL: {{^}}prog function &trunc_i32_to_i1(
define void @trunc_i32_to_i1(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) {
  %a = load i32, i32 addrspace(1)* %ptr, align 4
  %trunc = trunc i32 %a to i1
  %result = select i1 %trunc, i32 1, i32 0
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &sgpr_trunc_i32_to_i1(
; HSAIL: ld_arg_align(4)_u32 [[ARG:\$s[0-9]]], [%a];
; HSAIL: and_b32 [[AND:\$s[0-9]+]], [[ARG]], 1;
; HSAIL: cvt_b1_u32 [[CVT:\$c[0-9]+]], [[AND]];
; HSAIL: cmov_b32 {{\$s[0-9]+}}, [[CVT]]
define void @sgpr_trunc_i32_to_i1(i32 addrspace(1)* %out, i32 %a) {
  %trunc = trunc i32 %a to i1
  %result = select i1 %trunc, i32 1, i32 0
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &sgpr_trunc_i64_to_i1(
; HSAIL: ld_arg_align(8)_u64 [[ARG:\$d[0-9]]], [%a];
; HSAIL: and_b64 [[AND:\$d[0-9]+]], [[ARG]], 1;
; HSAIL: cvt_b1_u64 [[CVT:\$c[0-9]+]], [[AND]];
; HSAIL: cmov_b32 {{\$s[0-9]+}}, [[CVT]]
define void @sgpr_trunc_i64_to_i1(i32 addrspace(1)* %out, i64 %a) {
  %trunc = trunc i64 %a to i1
  %result = select i1 %trunc, i32 1, i32 0
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}
