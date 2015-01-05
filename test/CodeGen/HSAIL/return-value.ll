; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL: decl prog function &return_i32(arg_u32 %ret)();
; HSAIL: decl prog function &return_v4i32(align(16) arg_u32 %ret[4])();
; HSAIL: decl prog function &return_arg_i32(arg_u32 %ret)(arg_u32 %x);

; HSAIL: decl prog function &return_vector_arg_v4i32(align(16) arg_u32 %ret[4])(align(16) arg_u32 %x[4]);
; HSAIL: decl prog function &return_vector_arg_v3i32(align(16) arg_u32 %ret[4])(align(16) arg_u32 %x[4]);

; HSAIL: decl prog function &return_struct_arg(align(4) arg_u8 %ret[8])(align(4) arg_u8 %x[8]);

; HSAIL: decl prog function &struct_global_byval_arg()(
; HSAIL-NEXT: arg_u32 %test_byval_arg,
; HSAIL-NEXT: align(4) arg_u8 %x[8]);

; HSAIL: decl prog function &struct_private_byval_arg()(
; HSAIL-NEXT: arg_u32 %test_byval_arg,
; HSAIL-NEXT: align(4) arg_u8 %x[8]);

; HSAIL: decl prog function &return_arg_array_i32(arg_u32 %ret[4])(arg_u32 %x[4]);


; HSAIL: prog function &return_i32(arg_u32 %return_i32)()
; HSAIL: st_arg_align(4)_u32 {{\$s[0-9]+}}, [%return_i32];
define i32 @return_i32() {
  ret i32 123
}

; HSAIL: prog function &return_v4i32(align(16) arg_u32 %return_v4i32[4])()
; HSAIL-DAG: st_arg_align(16)_u32 {{\$s[0-9]+}}, [%return_v4i32];
; HSAIL-DAG: st_arg_align(4)_u32 {{\$s[0-9]+}}, [%return_v4i32][4];
; HSAIL-DAG: st_arg_align(8)_u32 {{\$s[0-9]+}}, [%return_v4i32][8];
; HSAIL-DAG: st_arg_align(4)_u32 {{\$s[0-9]+}}, [%return_v4i32][12];
define <4 x i32> @return_v4i32() {
  ret <4 x i32> <i32 9, i32 34, i32 91, i32 462>
}

; HSAIL: prog function &return_arg_i32(arg_u32 %return_arg_i32)(arg_u32 %x)
; HSAIL: st_arg_align(4)_u32 {{\$s[0-9]+}}, [%return_arg_i32];
define i32 @return_arg_i32(i32 %x) {
  ret i32 %x
}

; HSAIL: prog function &return_vector_arg_v4i32(align(16) arg_u32 %return_vector_arg_v4i32[4])(align(16) arg_u32 %x[4])
define <4 x i32> @return_vector_arg_v4i32(<4 x i32> %x) {
  ret <4 x i32> %x
}

; HSAIL: prog function &return_vector_arg_v3i32(align(16) arg_u32 %return_vector_arg_v3i32[4])(align(16) arg_u32 %x[4])
define <3 x i32> @return_vector_arg_v3i32(<3 x i32> %x) {
  ret <3 x i32> %x
}

%struct.i32pair = type { i32, i32 }

; HSAIL: prog function &return_struct_arg(align(4) arg_u8 %return_struct_arg[8])(align(4) arg_u8 %x[8])
; HSAIL-DAG: st_arg_align(4)_u32 {{\$s[0-9]+}}, [%return_struct_arg][4];
; HSAIL-DAG: st_arg_align(4)_u32 {{\$s[0-9]+}}, [%return_struct_arg];
define %struct.i32pair @return_struct_arg(%struct.i32pair %x) {
  ret %struct.i32pair %x
}

; HSAIL: prog function &struct_global_byval_arg()(
; HSAIL-NEXT: arg_u32 %test_byval_arg,
; HSAIL-NEXT: align(4) arg_u8 %x[8])

; HSAIL-DAG: st_global_align(4)_u32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+4]
; HSAIL-DAG: st_global_align(4)_u32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}]
define void @struct_global_byval_arg(%struct.i32pair addrspace(1)* sret %test_byval_arg, %struct.i32pair %x) {
  store %struct.i32pair %x, %struct.i32pair addrspace(1)* %test_byval_arg
  ret void
}

; HSAIL: prog function &struct_private_byval_arg()(
; HSAIL-NEXT: arg_u32 %test_byval_arg,
; HSAIL-NEXT: align(4) arg_u8 %x[8])

; HSAIL-DAG: st_private_align(4)_u32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+4]
; HSAIL-DAG: st_private_align(4)_u32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}]
define void @struct_private_byval_arg(%struct.i32pair* sret %test_byval_arg, %struct.i32pair %x) {
  store %struct.i32pair %x, %struct.i32pair* %test_byval_arg
  ret void
}

; HSAIL: prog function &return_arg_array_i32(arg_u32 %return_arg_array_i32[4])(arg_u32 %x[4])
; HSAIL-DAG: st_arg_align(4)_u32 {{\$s[0-9]+}}, [%return_arg_array_i32];
; HSAIL-DAG: st_arg_align(4)_u32 {{\$s[0-9]+}}, [%return_arg_array_i32][4];
; HSAIL-DAG: st_arg_align(8)_u32 {{\$s[0-9]+}}, [%return_arg_array_i32][8];
; HSAIL-DAG: st_arg_align(4)_u32 {{\$s[0-9]+}}, [%return_arg_array_i32][12];
; HSAIL: ret;
define [4 x i32] @return_arg_array_i32([4 x i32] %x) {
  ret [4 x i32] %x
}
