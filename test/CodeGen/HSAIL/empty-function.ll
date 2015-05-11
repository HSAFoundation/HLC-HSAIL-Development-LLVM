; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL: {{^}}decl prog function &empty_func_void()();
; HSAIL: {{^}}decl prog function &__unnamed_1()();

; HSAIL: {{^}}decl prog function &empty_func_with_return_type(arg_f32 %ret)();
; HSAIL: {{^}}decl prog function &__unnamed_2(arg_f32 %ret)();
; HSAIL: {{^}}decl prog function &empty_func_with_struct_return_type(align(4) arg_u8 %ret[8])();
; HSAIL: {{^}}decl prog function &empty_func_with_sext_return_type(arg_s32 %ret)();
; HSAIL: {{^}}decl prog function &empty_func_with_zext_return_type(arg_u32 %ret)();
; HSAIL: {{^}}decl prog function &unreachable_func_with_return_type(arg_f32 %ret)(arg_u32 %out);

; HSAIL-LABEL: {{^}}prog function &empty_func_void()()
; HSAIL-NEXT: {
; HSAIL-NOT: ret;
; HSAIL: };
define void @empty_func_void() {
  unreachable
}


; HSAIL-NOT: decl
; HSAIL-NOT: global
; HSAIL-LABEL: {{^}}prog function &__unnamed_1()()
; HSAIL-NEXT: {
; HSAIL-NOT: ret;
; HSAIL: };
define void @0() {
  unreachable
}

; Make sure we aren't printing extra declarations before function
; bodies, or an extra copy of the function name.

; HSAIL-NOT: decl
; HSAIL-NOT: empty_kernel_void
; HSAIL-NOT: global

; HSAIL-LABEL: {{^}}prog kernel &empty_kernel_void()
; HSAIL-NEXT: {
; HSAIL-NOT: ret;
; HSAIL: };
define spir_kernel void @empty_kernel_void() {
  unreachable
}

; HSAIL-NOT: empty_func_with_return_type

; HSAIL-LABEL: {{^}}prog function &empty_func_with_return_type(arg_f32 %empty_func_with_return_type)()
; HSAIL-NEXT: {
; HSAIL-NOT: ret;
; HSAIL: };
define float @empty_func_with_return_type() {
  unreachable
}

; HSAIL-LABEL: {{^}}prog function &__unnamed_2(arg_f32 %__unnamed_2)()
; HSAIL-NEXT: {
; HSAIL-NOT: ret;
; HSAIL: };
define float @1() {
  unreachable
}

%struct.pair = type { i32, i32 }

; HSAIL-LABEL: {{^}}prog function &empty_func_with_struct_return_type(align(4) arg_u8 %empty_func_with_struct_return_type[8])()
; HSAIL-NEXT: {
; HSAIL-NOT: ret;
; HSAIL: };
define %struct.pair @empty_func_with_struct_return_type() {
  unreachable
}

; HSAIL-LABEL: {{^}}prog function &empty_func_with_sext_return_type(arg_s32 %empty_func_with_sext_return_type)()
; HSAIL-NEXT: {
; HSAIL-NOT: ret;
; HSAIL: };
define signext i8 @empty_func_with_sext_return_type() {
  unreachable
}

; HSAIL-LABEL: {{^}}prog function &empty_func_with_zext_return_type(arg_u32 %empty_func_with_zext_return_type)()
; HSAIL-NEXT: {
; HSAIL-NOT: ret;
; HSAIL: };
define zeroext i8 @empty_func_with_zext_return_type() {
  unreachable
}

; HSAIL-LABEL: {{^}}prog function &unreachable_func_with_return_type(arg_f32 %unreachable_func_with_return_type)(arg_u32 %out)
; HSAIL-NEXT: {
; HSAIL: ld_arg_align(4)_u32
; HSAIL-NEXT: st_global_align(4)_u32
; HSAIL-NEXT: };
define float @unreachable_func_with_return_type(i32 addrspace(1)* %out) {
  store i32 123, i32 addrspace(1)* %out
  unreachable
}
