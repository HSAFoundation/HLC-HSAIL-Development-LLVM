; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &v4i32_kernel_arg
; HSAIL-DAG: ld_arg
; HSAIL-DAG: ld_arg
; HSAIL-DAG: ld_arg
; HSAIL-DAG: ld_arg
; HSAIL-DAG: ld_arg
; HSAIL-DAG: st_global
; HSAIL-DAG: st_global
; HSAIL-DAG: st_global
; HSAIL-DAG: st_global
; HSAIL: ret;
define void @v4i32_kernel_arg(<4 x i32> addrspace(1)* %out, <4 x i32>  %in) {
entry:
  store <4 x i32> %in, <4 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &v4f32_kernel_args
; HSAIL-DAG: ld_arg
; HSAIL-DAG: ld_arg
; HSAIL-DAG: ld_arg
; HSAIL-DAG: ld_arg
; HSAIL-DAG: ld_arg
; HSAIL-DAG: st_global
; HSAIL-DAG: st_global
; HSAIL-DAG: st_global
; HSAIL-DAG: st_global
; HSAIL: ret;
define void @v4f32_kernel_args(<4 x float> addrspace(1)* %out, <4 x float>  %in) {
entry:
  store <4 x float> %in, <4 x float> addrspace(1)* %out
  ret void
}
