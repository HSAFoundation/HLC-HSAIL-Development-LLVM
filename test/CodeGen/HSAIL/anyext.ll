; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &anyext_i1_i32
; HSAIL : cmp_eq_b1_s32	{{\$c[0-9]+}}, {{\$s[0-9]+}}, 0;
; HSAIL : cvt_u32_b1	{{\$s[0-9]+}}, {{\$c[0-9]+}};
; HSAIL : not_b32	{{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL : and_b32	{{\$s[0-9]+}}, {{\$s[0-9]+}}, 1;
define void @anyext_i1_i32(i32 addrspace(1)* %out, i32 %cond) {
entry:
  %0 = icmp eq i32 %cond, 0
  %1 = zext i1 %0 to i8
  %2 = xor i8 %1, -1
  %3 = and i8 %2, 1
  %4 = zext i8 %3 to i32
  store i32 %4, i32 addrspace(1)* %out
  ret void
}
