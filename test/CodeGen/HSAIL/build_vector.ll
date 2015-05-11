; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &build_vector2
; HSAIL: ld_arg_align(4)_u32 [[PTR:\$s[0-9]+]]
; HSAIL-DAG: st_global_align(4)_u32 6, {{\[}}[[PTR]]+4];
; HSAIL-DAG: st_global_align(8)_u32 5, {{\[}}[[PTR]]{{\]}};
; HSAIL: ret;
define void @build_vector2 (<2 x i32> addrspace(1)* %out) {
entry:
  store <2 x i32> <i32 5, i32 6>, <2 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &build_vector4
; HSAIL: ld_arg_align(4)_u32 [[PTR:\$s[0-9]+]]
; HSAIL-DAG: st_global_align(4)_u32 8, {{\[}}[[PTR]]+12];
; HSAIL-DAG: st_global_align(8)_u32 7, {{\[}}[[PTR]]+8];
; HSAIL-DAG: st_global_align(4)_u32 6, {{\[}}[[PTR]]+4];
; HSAIL-DAG: st_global_align(16)_u32 5, {{\[}}[[PTR]]{{\]}};
; HSAIL: ret
define void @build_vector4 (<4 x i32> addrspace(1)* %out) {
entry:
  store <4 x i32> <i32 5, i32 6, i32 7, i32 8>, <4 x i32> addrspace(1)* %out
  ret void
}
