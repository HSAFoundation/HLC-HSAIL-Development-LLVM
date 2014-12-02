; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &test
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: cmp_eq_b1_s32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, 0;
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 1, 2;
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @test(i32 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %1 = load i32 addrspace(1)* %in
  %2 = icmp eq i32 %1, 0
  %3 = select i1 %2, i32 1, i32 2
  store i32 %3, i32 addrspace(1)* %out
  ret void
}
