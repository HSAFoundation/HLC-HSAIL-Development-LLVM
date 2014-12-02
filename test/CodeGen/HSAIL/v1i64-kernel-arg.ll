; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &kernel_arg_i64
; HSAIL: ld_arg_align(8)_u64 {{\$d[0-9]+}}, [%a];
; HSAIL-NEXT: st_global_align(8)_u64
; HSAIL-NEXT: ret;
define void @kernel_arg_i64(i64 addrspace(1)* %out, i64 %a) nounwind {
  store i64 %a, i64 addrspace(1)* %out, align 8
  ret void
}

; FUNC-LABEL: {{^}}prog function &kernel_arg_v1i64
; HSAIL: ld_arg_align(8)_u64 {{\$d[0-9]+}}, [%a];
; HSAIL-NEXT: st_global_align(8)_u64
; HSAIL-NEXT: ret;
define void @kernel_arg_v1i64(<1 x i64> addrspace(1)* %out, <1 x i64> %a) nounwind {
  store <1 x i64> %a, <1 x i64> addrspace(1)* %out, align 8
  ret void
}
