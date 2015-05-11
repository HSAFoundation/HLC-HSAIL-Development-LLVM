; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &test
; HSAIL: cmp_eq_ftz_b1_f32  {{\$c[0-9]+}}, {{\$s[0-9]+}}, 0F00000000;
; HSAIL: cmov_b32  {{\$s[0-9]+}}, {{\$c[0-9]+}}, 2, 3;
define void @test(i32 addrspace(1)* %out, float addrspace(1)* %in) {
  %tmp0 = load float, float addrspace(1)* %in
  %cmp = fcmp oeq float %tmp0, 0.000000e+00
  %value = select i1 %cmp, i32 2, i32 3
  store i32 %value, i32 addrspace(1)* %out
  ret void
}
