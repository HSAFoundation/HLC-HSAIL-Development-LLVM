; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare void @extern.noret() #0
declare i1 @extern.i1() #0
declare i8 @extern.i8() #0
declare i16 @extern.i16() #0
declare i32 @extern.i32() #0
declare i64 @extern.i64() #0
declare void @extern.argi1(i1 %x) #0
declare void @extern.argi8(i8 %x) #0
declare void @extern.argi16(i16 %x) #0
declare void @extern.argi32(i32 %x) #0
declare void @extern.argi64(i64 %x) #0

declare void @extern.argv3i32(<3 x i32>) #0
declare void @extern.argv4i32(<4 x i32>) #0

declare void @argument.name.is.shadowed(i32 %is.shadowed) #0
declare void @argument.name.is.shadowed.vector(<2 x i32> %is.shadowed) #0

; HSAIL-LABEL{{^}}prog function &test_void_call_no_args(
; HSAIL: {
; HSAIL: call &extern.noret () ();
; HSAIL: }
define void @test_void_call_no_args() #0 {
  call void @extern.noret() #0
  ret void
}

; HSAIL-LABEL{{^}}prog function &test_call_no_args_ret_i32(
; HSAIL: {
; HSAIL: {
; HSAIL-NEXT: arg_u32 %extern.i32;
; HSAIL-NEXT: call &extern.i32 (%extern.i32) ();
; HSAIL-NEXT: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%extern.i32];
; HSAIL-NEXT: }
; HSAIL: }
define i32 @test_call_no_args_ret_i32() #0 {
  %ret = call i32 @extern.i32() #0
  ret i32 %ret
}

; HSAIL-LABEL{{^}}prog function &test_call_no_args_ret_i64(
; HSAIL: {
; HSAIL: {
; HSAIL-NEXT: arg_u64 %extern.i64;
; HSAIL-NEXT: call &extern.i64 (%extern.i64) ();
; HSAIL-NEXT: ld_arg_align(8)_u64 {{\$d[0-9]+}}, [%extern.i64];
; HSAIL-NEXT: }
; HSAIL: }
define i64 @test_call_no_args_ret_i64() #0 {
  %ret = call i64 @extern.i64() #0
  ret i64 %ret
}

; HSAIL-LABEL{{^}}prog function &test_call_no_args_ret_i1(
; HSAIL: {
; HSAIL: {
; HSAIL-NEXT: arg_u8 %extern.i1;
; HSAIL-NEXT: call &extern.i1 (%extern.i1) ();
; HSAIL-NEXT: ld_arg_u8 {{\$s[0-9]+}}, [%extern.i1];
; HSAIL-NEXT: }
; HSAIL: and_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 1;
; HSAIL: }
define i1 @test_call_no_args_ret_i1() #0 {
  %ret = call i1 @extern.i1() #0
  ret i1 %ret
}

; HSAIL-LABEL{{^}}prog function &test_call_no_args_ret_i8(
; HSAIL: {
; HSAIL: {
; HSAIL-NEXT: arg_u8 %extern.i8;
; HSAIL-NEXT: call &extern.i8 (%extern.i8) ();
; HSAIL-NEXT: ld_arg_u8 {{\$s[0-9]+}}, [%extern.i8];
; HSAIL-NEXT: }
; HSAIL: }
define i8 @test_call_no_args_ret_i8() #0 {
  %ret = call i8 @extern.i8() #0
  ret i8 %ret
}

; HSAIL-LABEL{{^}}prog function &test_call_no_args_ret_i16(
; HSAIL: {
; HSAIL: {
; HSAIL-NEXT: arg_u16 %extern.i16;
; HSAIL-NEXT: call &extern.i16 (%extern.i16) ();
; HSAIL-NEXT: ld_arg_align(2)_u16 {{\$s[0-9]+}}, [%extern.i16];
; HSAIL-NEXT: }
; HSAIL: }
define i16 @test_call_no_args_ret_i16() #0 {
  %ret = call i16 @extern.i16() #0
  ret i16 %ret
}

; HSAIL-LABEL{{^}}prog function &test_call_i32_arg(
; HSAIL: {
; HSAIL: {
; HSAIL-NEXT: arg_u32 %x;
; HSAIL-NEXT: st_arg_align(4)_u32 {{\$s[0-9]+}}, [%x];
; HSAIL-NEXT: call &extern.argi32 () (%x);
; HSAIL-NEXT: }
; HSAIL: }
define void @test_call_i32_arg(i32 %x) #0 {
  call void @extern.argi32(i32 %x) #0
  ret void
}

; HSAIL-LABEL{{^}}prog function &test_call_i64_arg(
; HSAIL: {
; HSAIL: {
; HSAIL-NEXT: arg_u64 %x;
; HSAIL-NEXT: st_arg_align(8)_u64 {{\$d[0-9]+}}, [%x];
; HSAIL-NEXT: call &extern.argi64 () (%x);
; HSAIL-NEXT: }
; HSAIL: }
define void @test_call_i64_arg(i64 %x) #0 {
  call void @extern.argi64(i64 %x) #0
  ret void
}

; HSAIL-LABEL{{^}}prog function &test_call_i8_arg(
; HSAIL: {
; HSAIL: {
; HSAIL-NEXT: arg_u8 %x;
; HSAIL-NEXT: st_arg_u8 {{\$s[0-9]+}}, [%x];
; HSAIL-NEXT: call &extern.argi8 () (%x);
; HSAIL-NEXT: }
; HSAIL: }
define void @test_call_i8_arg(i8 %x) #0 {
  call void @extern.argi8(i8 %x) #0
  ret void
}

; HSAIL-LABEL{{^}}prog function &test_call_i16_arg(
; HSAIL: {
; HSAIL: {
; HSAIL-NEXT: arg_u16 %x;
; HSAIL-NEXT: st_arg_align(2)_u16 {{\$s[0-9]+}}, [%x];
; HSAIL-NEXT: call &extern.argi16 () (%x);
; HSAIL-NEXT: }
; HSAIL: }
define void @test_call_i16_arg(i16 %x) #0 {
  call void @extern.argi16(i16 %x) #0
  ret void
}

; HSAIL-LABEL{{^}}prog function &test_call_i1_arg(
; HSAIL: {
; HSAIL: and_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 1;
; HSAIL: {
; HSAIL-NEXT: arg_u8 %x;
; HSAIL-NEXT: st_arg_u8 {{\$s[0-9]+}}, [%x];
; HSAIL-NEXT: call &extern.argi1 () (%x);
; HSAIL-NEXT: }
; HSAIL: }
define void @test_call_i1_arg(i1 %x) #0 {
  call void @extern.argi1(i1 %x) #0
  ret void
}

; HSAIL-LABEL{{^}}prog function &test_call_v4i32_arg(
; HSAIL: {
; HSAIL: ld_arg_align(16)_u32 [[LDELT0:\$s[0-9]+]], [%x];
; HSAIL: ld_arg_align(4)_u32 [[LDELT1:\$s[0-9]+]], [%x][4];
; HSAIL: ld_arg_align(8)_u32 [[LDELT2:\$s[0-9]+]], [%x][8];
; HSAIL: ld_arg_align(4)_u32 [[LDELT3:\$s[0-9]+]], [%x][12];
; HSAIL-NEXT: {
; HSAIL-NEXT: align(16) arg_u32 %__param_p0[4];
; HSAIL-NEXT: st_arg_align(16)_u32 [[LDELT0]], [%__param_p0];
; HSAIL-NEXT: st_arg_align(4)_u32 [[LDELT1]], [%__param_p0][4];
; HSAIL-NEXT: st_arg_align(8)_u32 [[LDELT2]], [%__param_p0][8];
; HSAIL-NEXT: st_arg_align(4)_u32 [[LDELT3]], [%__param_p0][12];
; HSAIL-NEXT: call &extern.argv4i32 () (%__param_p0);
; HSAIL-NEXT: }
; HSAIL: }
define void @test_call_v4i32_arg(<4 x i32> %x) #0 {
  call void @extern.argv4i32(<4 x i32> %x) #0
  ret void
}

; HSAIL-LABEL{{^}}prog function &test_call_v3i32_arg(
; HSAIL: {
; HSAIL: ld_arg_align(16)_u32 [[LDELT0:\$s[0-9]+]], [%x];
; HSAIL: ld_arg_align(4)_u32 [[LDELT1:\$s[0-9]+]], [%x][4];
; HSAIL: ld_arg_align(8)_u32 [[LDELT2:\$s[0-9]+]], [%x][8];
; HSAIL-NEXT: {
; HSAIL-NEXT: align(16) arg_u32 %__param_p0[4];
; HSAIL-NEXT: st_arg_align(16)_u32 [[LDELT0]], [%__param_p0];
; HSAIL-NEXT: st_arg_align(4)_u32 [[LDELT1]], [%__param_p0][4];
; HSAIL-NEXT: st_arg_align(8)_u32 [[LDELT2]], [%__param_p0][8];
; HSAIL-NEXT: call &extern.argv3i32 () (%__param_p0);
; HSAIL-NEXT: }
; HSAIL: }
define void @test_call_v3i32_arg(<3 x i32> %x) #0 {
  call void @extern.argv3i32(<3 x i32> %x) #0
  ret void
}

; HSAIL-LABEL{{^}}prog function &test_call_shadow_argument_name()(arg_u32 %is.shadowed)
; HSAIL: {
; HSAIL: ld_arg_align(4)_u32 [[LDARG:\$s[0-9]+]], [%is.shadowed];
; HSAIL-NEXT: {
; HSAIL-NEXT: arg_u32 %is.shadowed;
; HSAIL-NEXT: st_arg_align(4)_u32 [[LDARG]], [%is.shadowed];
; HSAIL-NEXT: call &argument.name.is.shadowed () (%is.shadowed);
; HSAIL-NEXT: }
; HSAIL: }
define void @test_call_shadow_argument_name(i32 %is.shadowed) #0 {
  call void @argument.name.is.shadowed(i32 %is.shadowed) #0
  ret void
}

; HSAIL-LABEL{{^}}prog function &test_call_shadow_argument_name_vector()(arg_u32 %is.shadowed[2])
; HSAIL: {
; HSAIL: ld_arg_align(8)_u32 [[LDELT0:\$s[0-9]+]], [%is.shadowed];
; HSAIL: ld_arg_align(4)_u32 [[LDELT1:\$s[0-9]+]], [%is.shadowed][4];
; HSAIL-NEXT: {
; HSAIL-NEXT: align(8) arg_u32 %is.shadowed[2];
; HSAIL-NEXT: st_arg_align(8)_u32 [[LDELT0]], [%is.shadowed];
; HSAIL-NEXT: st_arg_align(4)_u32 [[LDELT1]], [%is.shadowed][4];
; HSAIL-NEXT: call &argument.name.is.shadowed.vector () (%is.shadowed);
; HSAIL-NEXT: }
; HSAIL: }
define void @test_call_shadow_argument_name_vector(<2 x i32> %is.shadowed) #0 {
  call void @argument.name.is.shadowed.vector(<2 x i32> %is.shadowed) #0
  ret void
}

attributes #0 = { nounwind }
