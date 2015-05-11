; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &test
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: cmp_eq_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, 0F00000000;
; HSAIL-NEXT: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 1065353216, 1073741824;
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @test(float addrspace(1)* %out, float addrspace(1)* %in) {
  %1 = load float, float addrspace(1)* %in
  %2 = fcmp oeq float %1, 0.0
  %3 = select i1 %2, float 1.0, float 2.0
  store float %3, float addrspace(1)* %out
  ret void
}
