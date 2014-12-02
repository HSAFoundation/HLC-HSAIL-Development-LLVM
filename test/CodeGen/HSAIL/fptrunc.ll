; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &fptrunc
; HSAIL: ld_arg_align(8)_f64 {{\$d[0-9]+}}, [%in];
; HSAIL-NEXT: cvt_ftz_f32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @fptrunc(float addrspace(1)* %out, double %in) {
  %result = fptrunc double %in to float
  store float %result, float addrspace(1)* %out
  ret void
}
