; RUN: llc -march=hsail -filetype=asm < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &test
; HSAIL: cvt_f64_u32  {{\$d[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_ftz_f32_f64  {{\$s[0-9]+}}, {{\$d[0-9]+}};
define void @test(float addrspace(1)* %out, i8 addrspace(1)* %in) {
  %tmp1 = load i8 addrspace(1)* %in
  %tmp2 = uitofp i8 %tmp1 to double
  %tmp3 = fptrunc double %tmp2 to float
  store float %tmp3, float addrspace(1)* %out
  ret void
}
