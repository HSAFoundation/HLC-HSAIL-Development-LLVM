; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &fconst_f64
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: add_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 0D4014000000000000;
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @fconst_f64(double addrspace(1)* %out, double addrspace(1)* %in) {
   %r1 = load double addrspace(1)* %in
   %r2 = fadd double %r1, 5.000000e+00
   store double %r2, double addrspace(1)* %out
   ret void
}
