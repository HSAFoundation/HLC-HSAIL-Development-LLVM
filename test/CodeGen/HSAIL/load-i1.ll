; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &zextload_i1_to_i32
; HSAIL: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL: ld_global_u8 [[VAL:\$s[0-9]+]], {{\[}}[[IN]]{{\]}};
; HSAIL: st_global_align(4)_u32 [[VAL]]
; HSAIL: ret;
define void @zextload_i1_to_i32(i32 addrspace(1)* %out, i1 addrspace(1)* %in) {
  %tmp1 = load i1 addrspace(1)* %in, align 1
  %tmp2 = zext i1 %tmp1 to i32
  store i32 %tmp2, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &zextload_i1_to_i64
; HSAIL: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL: ld_global_u8 [[VAL:\$s[0-9]+]], {{\[}}[[IN]]{{\]}};
; HSAIL: cvt_u64_u32 [[RESULT:\$d[0-9]+]], [[VAL]]
; HSAIL: st_global_align(8)_u64 [[RESULT]]
; HSAIL: ret;
define void @zextload_i1_to_i64(i64 addrspace(1)* %out, i1 addrspace(1)* %in) {
  %tmp1 = load i1 addrspace(1)* %in, align 1
  %tmp2 = zext i1 %tmp1 to i64
  store i64 %tmp2, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &sextload_i1_to_i32
; HSAIL: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL: ld_global_u8 [[VAL:\$s[0-9]+]], {{\[}}[[IN]]{{\]}};
; HSAIL: shl_u32 [[TMP0:\$s[0-9]+]], [[VAL]], 31;
; HSAIL: shr_s32 [[TMP1:\$s[0-9]+]], [[TMP0]], 31;
; HSAIL: st_global_align(4)_u32 [[TMP1]]
; HSAIL: ret;
define void @sextload_i1_to_i32(i32 addrspace(1)* %out, i1 addrspace(1)* %in) {
  %tmp1 = load i1 addrspace(1)* %in, align 1
  %tmp2 = sext i1 %tmp1 to i32
  store i32 %tmp2, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &sextload_i1_to_i64
; HSAIL: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL: ld_global_u8 [[VAL:\$s[0-9]+]], {{\[}}[[IN]]{{\]}};
; HSAIL: cvt_u64_u32 [[CVT:\$d[0-9]+]], [[VAL]]
; HSAIL: shl_u64 [[TMP0:\$d[0-9]+]], [[CVT]], 63;
; HSAIL: shr_s64 [[RESULT:\$d[0-9]+]], [[TMP0]], 63;
; HSAIL: st_global_align(8)_u64 [[RESULT]]
; HSAIL: ret;
define void @sextload_i1_to_i64(i64 addrspace(1)* %out, i1 addrspace(1)* %in) {
  %tmp1 = load i1 addrspace(1)* %in, align 1
  %tmp2 = sext i1 %tmp1 to i64
  store i64 %tmp2, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &load_i1(
; HSAIL: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL: ld_global_u8 [[VAL:\$s[0-9]+]], {{\[}}[[IN]]{{\]}};
; HSAIL: st_global_u8 [[VAL]]
; HSAIL: ret;
define void @load_i1(i1 addrspace(1)* %out, i1 addrspace(1)* %in) {
  %tmp1 = load i1 addrspace(1)* %in, align 1
  store i1 %tmp1, i1 addrspace(1)* %out
  ret void
}
