; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &fpext
; HSAIL: cvt_ftz_f64_f32 {{\$d[0-9]+}}, {{\$s[0-9]+}};
define void @fpext(double addrspace(1)* %out, float %in) {
  %result = fpext float %in to double
  store double %result, double addrspace(1)* %out
  ret void
}
