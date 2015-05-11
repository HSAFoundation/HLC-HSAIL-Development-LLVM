; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &fp64_to_sint
; HSAIL: ld_arg_align(8)_f64 {{\$d[0-9]+}}, [%in];
; HSAIL: cvt_s32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @fp64_to_sint(i32 addrspace(1)* %out, double %in) {
  %result = fptosi double %in to i32
  store i32 %result, i32 addrspace(1)* %out
  ret void
}
