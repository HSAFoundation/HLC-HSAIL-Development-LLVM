; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL: decl prog function &return_i32(arg_u32 %ret)();
; HSAIL: decl prog function &return_v4i32(align(16) arg_u32 %ret[4])();

; HSAIL: decl prog function &return_arg_i1(arg_u8 %ret)(arg_u8 %x);
; HSAIL: decl prog function &return_sext_arg_i1(arg_s32 %ret)(arg_u8 %x);
; HSAIL: decl prog function &return_zext_arg_i1(arg_u32 %ret)(arg_u8 %x);

; HSAIL: decl prog function &return_arg_i8(arg_u8 %ret)(arg_u8 %x);
; HSAIL: decl prog function &return_sext_arg_i8(arg_s32 %ret)(arg_u8 %x);
; HSAIL: decl prog function &return_zext_arg_i8(arg_u32 %ret)(arg_u8 %x);
; HSAIL: decl prog function &return_arg_i16(arg_u16 %ret)(arg_u16 %x);
; HSAIL: decl prog function &return_sext_arg_i16(arg_s32 %ret)(arg_u16 %x);
; HSAIL: decl prog function &return_zext_arg_i16(arg_u32 %ret)(arg_u16 %x);
; HSAIL: decl prog function &return_arg_i32(arg_u32 %ret)(arg_u32 %x);


; HSAIL: decl prog function &return_vector_arg_v1i32(arg_u32 %ret[1])(arg_u32 %x[1]);
; HSAIL: decl prog function &return_vector_arg_v2i32(align(8) arg_u32 %ret[2])(align(8) arg_u32 %x[2]);
; HSAIL: decl prog function &return_vector_arg_v3i32(align(16) arg_u32 %ret[4])(align(16) arg_u32 %x[4]);
; HSAIL: decl prog function &return_vector_arg_v4i32(align(16) arg_u32 %ret[4])(align(16) arg_u32 %x[4]);
; HSAIL: decl prog function &return_vector_arg_v8i32(align(32) arg_u32 %ret[8])(align(32) arg_u32 %x[8]);
; HSAIL: decl prog function &return_vector_arg_v16i32(align(64) arg_u32 %ret[16])(align(64) arg_u32 %x[16]);

; HSAIL: decl prog function &return_arg_i64(arg_u64 %ret)(arg_u64 %x);
; HSAIL: decl prog function &return_vector_arg_v1i64(arg_u64 %ret[1])(arg_u64 %x[1]);
; HSAIL: decl prog function &return_vector_arg_v2i64(align(16) arg_u64 %ret[2])(align(16) arg_u64 %x[2]);
; HSAIL: decl prog function &return_vector_arg_v3i64(align(32) arg_u64 %ret[4])(align(32) arg_u64 %x[4]);
; HSAIL: decl prog function &return_vector_arg_v4i64(align(32) arg_u64 %ret[4])(align(32) arg_u64 %x[4]);
; HSAIL: decl prog function &return_vector_arg_v8i64(align(64) arg_u64 %ret[8])(align(64) arg_u64 %x[8]);
; HSAIL: decl prog function &return_vector_arg_v16i64(align(128) arg_u64 %ret[16])(align(128) arg_u64 %x[16]);

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

; HSAIL-LABEL: prog function &return_arg_i1(arg_u8 %return_arg_i1)(arg_u8 %x)
; HSAIL: ld_arg_u8 [[LDI1:\$s[0-9]+]], [%x];
; HSAIL: and_b32 [[RESULT:\$s[0-9]+]], [[LDI1]], 1;
; HSAIL: st_arg_u8 [[RESULT]], [%return_arg_i1];
define i1 @return_arg_i1(i1 %x) {
  ret i1 %x
}

; HSAIL-LABEL: prog function &return_sext_arg_i1(arg_s32 %return_sext_arg_i1)(arg_u8 %x)
; HSAIL: ld_arg_u8 [[LDI1:\$s[0-9]+]], [%x];
; HSAIL: shl_u32 [[EXT0:\$s[0-9]+]], [[LDI1]], 31;
; HSAIL: shr_s32 [[RESULT:\$s[0-9]+]], [[EXT0]], 31;
; HSAIL: st_arg_u32 [[RESULT]], [%return_sext_arg_i1];
define signext i1 @return_sext_arg_i1(i1 %x) {
  ret i1 %x
}

; HSAIL-LABEL: prog function &return_zext_arg_i1(arg_u32 %return_zext_arg_i1)(arg_u8 %x)
; HSAIL: ld_arg_u8 [[LDI1:\$s[0-9]+]], [%x];
; HSAIL: and_b32 [[RESULT:\$s[0-9]+]], [[LDI1]], 1;
; HSAIL: st_arg_u32 [[RESULT]], [%return_zext_arg_i1];
define zeroext i1 @return_zext_arg_i1(i1 %x) {
  ret i1 %x
}

; HSAIL-LABEL: prog function &return_arg_i8(arg_u8 %return_arg_i8)(arg_u8 %x)
; HSAIL: st_arg_u8 {{\$s[0-9]+}}, [%return_arg_i8];
define i8 @return_arg_i8(i8 %x) {
  ret i8 %x
}

; HSAIL-LABEL: prog function &return_sext_arg_i8(arg_s32 %return_sext_arg_i8)(arg_u8 %x)
; HSAIL: st_arg_u8 {{\$s[0-9]+}}, [%return_sext_arg_i8];
define signext i8 @return_sext_arg_i8(i8 %x) {
  ret i8 %x
}

; HSAIL: prog function &return_zext_arg_i8(arg_u32 %return_zext_arg_i8)(arg_u8 %x)
; HSAIL: st_arg_u8 {{\$s[0-9]+}}, [%return_zext_arg_i8];
define zeroext i8 @return_zext_arg_i8(i8 %x) {
  ret i8 %x
}

; HSAIL: prog function &return_arg_i16(arg_u16 %return_arg_i16)(arg_u16 %x)
; HSAIL: st_arg_align(2)_u16 {{\$s[0-9]+}}, [%return_arg_i16];
define i16 @return_arg_i16(i16 %x) {
  ret i16 %x
}

; HSAIL: prog function &return_sext_arg_i16(arg_s32 %return_sext_arg_i16)(arg_u16 %x)
; HSAIL: st_arg_align(2)_u16 {{\$s[0-9]+}}, [%return_sext_arg_i16];
define signext i16 @return_sext_arg_i16(i16 %x) {
  ret i16 %x
}

; HSAIL: prog function &return_zext_arg_i16(arg_u32 %return_zext_arg_i16)(arg_u16 %x)
; HSAIL: st_arg_align(2)_u16 {{\$s[0-9]+}}, [%return_zext_arg_i16];
define zeroext i16 @return_zext_arg_i16(i16 %x) {
  ret i16 %x
}

; HSAIL: prog function &return_arg_i32(arg_u32 %return_arg_i32)(arg_u32 %x)
; HSAIL: st_arg_align(4)_u32 {{\$s[0-9]+}}, [%return_arg_i32];
define i32 @return_arg_i32(i32 %x) {
  ret i32 %x
}

; HSAIL: prog function &return_vector_arg_v1i32(arg_u32 %return_vector_arg_v1i32[1])(arg_u32 %x[1])
define <1 x i32> @return_vector_arg_v1i32(<1 x i32> %x) {
  ret <1 x i32> %x
}

; HSAIL: prog function &return_vector_arg_v2i32(align(8) arg_u32 %return_vector_arg_v2i32[2])(align(8) arg_u32 %x[2])
; HSAIL: st_arg_align(8)_u32 {{\$s[0-9]+}}, [%return_vector_arg_v2i32];
; HSAIL: st_arg_align(4)_u32 {{\$s[0-9]+}}, [%return_vector_arg_v2i32][4];
define <2 x i32> @return_vector_arg_v2i32(<2 x i32> %x) {
  ret <2 x i32> %x
}

; HSAIL: prog function &return_vector_arg_v3i32(align(16) arg_u32 %return_vector_arg_v3i32[4])(align(16) arg_u32 %x[4])
; HSAIL: st_arg_align(16)_u32 {{\$s[0-9]+}}, [%return_vector_arg_v3i32];
; HSAIL: st_arg_align(4)_u32 {{\$s[0-9]+}}, [%return_vector_arg_v3i32][4];
; HSAIL: st_arg_align(8)_u32 {{\$s[0-9]+}}, [%return_vector_arg_v3i32][8];
; HSAIL-NOT: st
; HSAIL: ret;
define <3 x i32> @return_vector_arg_v3i32(<3 x i32> %x) {
  ret <3 x i32> %x
}

; HSAIL: prog function &return_vector_arg_v4i32(align(16) arg_u32 %return_vector_arg_v4i32[4])(align(16) arg_u32 %x[4])
; HSAIL: st_arg_align(16)_u32 {{\$s[0-9]+}}, [%return_vector_arg_v4i32];
; HSAIL: st_arg_align(4)_u32 {{\$s[0-9]+}}, [%return_vector_arg_v4i32][4];
; HSAIL: st_arg_align(8)_u32 {{\$s[0-9]+}}, [%return_vector_arg_v4i32][8];
; HSAIL: st_arg_align(4)_u32 {{\$s[0-9]+}}, [%return_vector_arg_v4i32][12];
; HSAIL: ret;
define <4 x i32> @return_vector_arg_v4i32(<4 x i32> %x) {
  ret <4 x i32> %x
}

; HSAIL: prog function &return_vector_arg_v8i32(align(32) arg_u32 %return_vector_arg_v8i32[8])(align(32) arg_u32 %x[8])
define <8 x i32> @return_vector_arg_v8i32(<8 x i32> %x) {
  ret <8 x i32> %x
}

; HSAIL: prog function &return_vector_arg_v16i32(align(64) arg_u32 %return_vector_arg_v16i32[16])(align(64) arg_u32 %x[16])
define <16 x i32> @return_vector_arg_v16i32(<16 x i32> %x) {
  ret <16 x i32> %x
}

; HSAIL: prog function &return_arg_i64(arg_u64 %return_arg_i64)(arg_u64 %x)
; HSAIL: st_arg_align(8)_u64 {{\$d[0-9]+}}, [%return_arg_i64];
define i64 @return_arg_i64(i64 %x) {
  ret i64 %x
}

; HSAIL: prog function &return_vector_arg_v1i64(arg_u64 %return_vector_arg_v1i64[1])(arg_u64 %x[1])
define <1 x i64> @return_vector_arg_v1i64(<1 x i64> %x) {
  ret <1 x i64> %x
}

; HSAIL: prog function &return_vector_arg_v2i64(align(16) arg_u64 %return_vector_arg_v2i64[2])(align(16) arg_u64 %x[2])
; HSAIL: st_arg_align(16)_u64 {{\$d[0-9]+}}, [%return_vector_arg_v2i64];
; HSAIL: st_arg_align(8)_u64 {{\$d[0-9]+}}, [%return_vector_arg_v2i64][8];
define <2 x i64> @return_vector_arg_v2i64(<2 x i64> %x) {
  ret <2 x i64> %x
}

; HSAIL: prog function &return_vector_arg_v3i64(align(32) arg_u64 %return_vector_arg_v3i64[4])(align(32) arg_u64 %x[4])
; HSAIL: st_arg_align(32)_u64 {{\$d[0-9]+}}, [%return_vector_arg_v3i64];
; HSAIL: st_arg_align(8)_u64 {{\$d[0-9]+}}, [%return_vector_arg_v3i64][8];
; HSAIL: st_arg_align(16)_u64 {{\$d[0-9]+}}, [%return_vector_arg_v3i64][16];
; HSAIL-NOT: st
; HSAIL: ret;
define <3 x i64> @return_vector_arg_v3i64(<3 x i64> %x) {
  ret <3 x i64> %x
}

; HSAIL: prog function &return_vector_arg_v4i64(align(32) arg_u64 %return_vector_arg_v4i64[4])(align(32) arg_u64 %x[4])
; HSAIL: st_arg_align(32)_u64 {{\$d[0-9]+}}, [%return_vector_arg_v4i64];
; HSAIL: st_arg_align(8)_u64 {{\$d[0-9]+}}, [%return_vector_arg_v4i64][8];
; HSAIL: st_arg_align(16)_u64 {{\$d[0-9]+}}, [%return_vector_arg_v4i64][16];
; HSAIL: st_arg_align(8)_u64 {{\$d[0-9]+}}, [%return_vector_arg_v4i64][24];
; HSAIL: ret;
define <4 x i64> @return_vector_arg_v4i64(<4 x i64> %x) {
  ret <4 x i64> %x
}

; HSAIL: prog function &return_vector_arg_v8i64(align(64) arg_u64 %return_vector_arg_v8i64[8])(align(64) arg_u64 %x[8])
define <8 x i64> @return_vector_arg_v8i64(<8 x i64> %x) {
  ret <8 x i64> %x
}

; HSAIL: prog function &return_vector_arg_v16i64(align(128) arg_u64 %return_vector_arg_v16i64[16])(align(128) arg_u64 %x[16])
define <16 x i64> @return_vector_arg_v16i64(<16 x i64> %x) {
  ret <16 x i64> %x
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
; HSAIL-DAG: st_arg_align(4)_u32 {{\$s[0-9]+}}, [%return_arg_array_i32][8];
; HSAIL-DAG: st_arg_align(4)_u32 {{\$s[0-9]+}}, [%return_arg_array_i32][12];
; HSAIL: ret;
define [4 x i32] @return_arg_array_i32([4 x i32] %x) {
  ret [4 x i32] %x
}
