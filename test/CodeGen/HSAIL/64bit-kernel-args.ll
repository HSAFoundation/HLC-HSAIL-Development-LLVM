; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &f64_kernel_arg
; HSAIL-DAG: ld_arg
; HSAIL-DAG: ld_arg
; HSAIL-DAG: st_global
; HSAIL: ret;

define void @f64_kernel_arg(double addrspace(1)* %out, double  %in) {
entry:
  store double %in, double addrspace(1)* %out
  ret void
}
