; XFAIL: *
; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &load_i1
; HSAIL: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL: ld_global_u8 [[VAL:\$s[0-9]+]], {{\[}}[[IN]]{{\]}};
; HSAIL: st_global_u32 [[VAL]]
; HSAIL: ret;
define void @load_i1(i32 addrspace(1)* %out, i1 addrspace(1)* %in) {
  %tmp1 = load i1 addrspace(1)* %in
  %tmp2 = zext i1 %tmp1 to i32
  store i32 %tmp2, i32 addrspace(1)* %out
  ret void
}
