; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &bitextract_pat0_i32_rii_0(
; HSAIL: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL: bitextract_u32 {{\$s[0-9]+}}, [[SRC0]], 11, 3;
; HSAIL: ret;
define i32 @bitextract_pat0_i32_rii_0(i32 %src0) #0 {
  %tmp0 = lshr i32 %src0, 11
  %tmp1 = and i32 %tmp0, 7
  ret i32 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_pat0_i32_rii_1(
; HSAIL: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL-NEXT: shr_u32 [[RESULT:\$s[0-9]+]], [[SRC0]], 16
; HSAIL-NEXT: st_arg_align(4)_u32 [[RESULT]]
; HSAIL: ret;
define i32 @bitextract_pat0_i32_rii_1(i32 %src0) #0 {
  %tmp0 = lshr i32 %src0, 16
  %tmp1 = and i32 %tmp0, 65535
  ret i32 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_pat0_i32_rii_2(
; HSAIL: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL-NEXT: shr_u32 [[RESULT:\$s[0-9]+]], [[SRC0]], 31
; HSAIL-NEXT: st_arg_align(4)_u32 [[RESULT]]
; HSAIL: ret;
define i32 @bitextract_pat0_i32_rii_2(i32 %src0) #0 {
  %tmp0 = lshr i32 %src0, 31
  %tmp1 = and i32 %tmp0, 7
  ret i32 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_pat0_i32_rii_3(
; HSAIL: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL: bitextract_u32 {{\$s[0-9]+}}, [[SRC0]], 20, 1;
; HSAIL: ret;
define i32 @bitextract_pat0_i32_rii_3(i32 %src0) #0 {
  %tmp0 = lshr i32 %src0, 20
  %tmp1 = and i32 %tmp0, 1
  ret i32 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_pat0_i32_rii_4(
; HSAIL: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL: bitextract_u32 {{\$s[0-9]+}}, [[SRC0]], 1, 5;
; HSAIL: ret;
define i32 @bitextract_pat0_i32_rii_4(i32 %src0) #0 {
  %tmp0 = lshr i32 %src0, 1
  %tmp1 = and i32 %tmp0, 31
  ret i32 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_pat0_i32_rii_5(
; HSAIL: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL: bitextract_u32 {{\$s[0-9]+}}, [[SRC0]], 27, 4;
; HSAIL: ret;
define i32 @bitextract_pat0_i32_rii_5(i32 %src0) #0 {
  %tmp0 = lshr i32 %src0, 27
  %tmp1 = and i32 %tmp0, 15
  ret i32 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_pat0_i32_rii_not_0(
; HSAIL-NOT: bitextract_u32
; HSAIL: ret;
define i32 @bitextract_pat0_i32_rii_not_0(i32 %src0) #0 {
  %tmp0 = lshr i32 %src0, 11
  %tmp1 = and i32 %tmp0, 8
  ret i32 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_pat0_i32_rri_0(
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC1:\$s[0-9]+]], [%src1];
; HSAIL: bitextract_u32 {{\$s[0-9]+}}, [[SRC0]], [[SRC1]], 3;
; HSAIL: ret;
define i32 @bitextract_pat0_i32_rri_0(i32 %src0, i32 %src1) #0 {
  %tmp0 = lshr i32 %src0, %src1
  %tmp1 = and i32 %tmp0, 7
  ret i32 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_pat0_i32_rri_not_0(
; HSAIL-NOT: bitextract_u32
; HSAIL: ret;
define i32 @bitextract_pat0_i32_rri_not_0(i32 %src0, i32 %src1) #0 {
  %tmp0 = lshr i32 %src0, %src1
  %tmp1 = and i32 %tmp0, 8
  ret i32 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_pat0_i64_rii_0(
; HSAIL: ld_arg_align(8)_u64 [[SRC0:\$d[0-9]+]], [%src0];
; HSAIL: bitextract_u64 {{\$d[0-9]+}}, [[SRC0]], 11, 3;
; HSAIL: ret;
define i64 @bitextract_pat0_i64_rii_0(i64 %src0) #0 {
  %tmp0 = lshr i64 %src0, 11
  %tmp1 = and i64 %tmp0, 7
  ret i64 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_pat0_i64_rii_1(
; HSAIL: ld_arg_align(8)_u64 [[SRC0:\$d[0-9]+]], [%src0];
; HSAIL: bitextract_u64 {{\$d[0-9]+}}, [[SRC0]], 31, 16;
; HSAIL: ret;
define i64 @bitextract_pat0_i64_rii_1(i64 %src0) #0 {
  %tmp0 = lshr i64 %src0, 31
  %tmp1 = and i64 %tmp0, 65535
  ret i64 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_pat0_i64_rii_2(
; HSAIL: ld_arg_align(8)_u64 [[SRC0:\$d[0-9]+]], [%src0];
; HSAIL: bitextract_u64 {{\$d[0-9]+}}, [[SRC0]], 31, 32;
; HSAIL: ret;
define i64 @bitextract_pat0_i64_rii_2(i64 %src0) #0 {
  %tmp0 = lshr i64 %src0, 31
  %tmp1 = and i64 %tmp0, 4294967295
  ret i64 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_pat0_i64_rii_3(
; HSAIL: ld_arg_align(8)_u64 [[SRC0:\$d[0-9]+]], [%src0];
; HSAIL: bitextract_u64 {{\$d[0-9]+}}, [[SRC0]], 1, 32;
; HSAIL: ret;
define i64 @bitextract_pat0_i64_rii_3(i64 %src0) #0 {
  %tmp0 = lshr i64 %src0, 1
  %tmp1 = and i64 %tmp0, 4294967295
  ret i64 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_pat0_i64_rii_4(
; HSAIL: ld_arg_align(8)_u64 [[SRC0:\$d[0-9]+]], [%src0];
; HSAIL: bitextract_u64 {{\$d[0-9]+}}, [[SRC0]], 32, 3;
; HSAIL: ret;
define i64 @bitextract_pat0_i64_rii_4(i64 %src0) #0 {
  %tmp0 = lshr i64 %src0, 32
  %tmp1 = and i64 %tmp0, 7
  ret i64 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_pat0_i64_rii_5(
; HSAIL: ld_arg_align(8)_u64 [[SRC0:\$d[0-9]+]], [%src0];
; HSAIL: bitextract_u64 {{\$d[0-9]+}}, [[SRC0]], 33, 3;
; HSAIL: ret;
define i64 @bitextract_pat0_i64_rii_5(i64 %src0) #0 {
  %tmp0 = lshr i64 %src0, 33
  %tmp1 = and i64 %tmp0, 7
  ret i64 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_pat0_i64_rii_6(
; HSAIL: ld_arg_align(8)_u64 [[SRC0:\$d[0-9]+]], [%src0];
; HSAIL-NEXT: shr_u64 [[RESULT:\$d[0-9]+]], [[SRC0]], 63;
; HSAIL-NEXT: st_arg_align(8)_u64 [[RESULT]]
; HSAIL: ret;
define i64 @bitextract_pat0_i64_rii_6(i64 %src0) #0 {
  %tmp0 = lshr i64 %src0, 63
  %tmp1 = and i64 %tmp0, 7
  ret i64 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_pat0_i64_rii_not_0(
; HSAIL-NOT: bitextract_u64
; HSAIL: ret;
define i64 @bitextract_pat0_i64_rii_not_0(i64 %src0) #0 {
  %tmp0 = lshr i64 %src0, 11
  %tmp1 = and i64 %tmp0, 8
  ret i64 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_pat0_i64_rri_0(
; HSAIL-DAG: ld_arg_align(8)_u64 [[SRC0:\$d[0-9]+]], [%src0];
; HSAIL-DAG: ld_arg_align(8)_u64 [[SRC1:\$d[0-9]+]], [%src1];
; HSAIL-DAG: cvt_u32_u64 [[TRUNCSRC1:\$s[0-9]+]], [[SRC1]];
; HSAIL: bitextract_u64 {{\$d[0-9]+}}, [[SRC0]], [[TRUNCSRC1]], 3;
; HSAIL: ret;
define i64 @bitextract_pat0_i64_rri_0(i64 %src0, i64 %src1) #0 {
  %tmp0 = lshr i64 %src0, %src1
  %tmp1 = and i64 %tmp0, 7
  ret i64 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_pat0_i64_rri_not_0(
; HSAIL-NOT: bitextract_u64
; HSAIL: ret;
define i64 @bitextract_pat0_i64_rri_not_0(i64 %src0, i64 %src1) #0 {
  %tmp0 = lshr i64 %src0, %src1
  %tmp1 = and i64 %tmp0, 8
  ret i64 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i32_rii_0(
; HSAIL: bitextract_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 11, 3;
define i32 @bitextract_signed_pat1_i32_rii_0(i32 %src0) #0 {
  %tmp0 = ashr i32 %src0, 11 ; shift
  %tmp1 = and i32 %tmp0, 7 ; mask
  ret i32 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i32_rii_1(
; HSAIL: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL-NEXT: shr_u32 [[RESULT:\$s[0-9]+]], [[SRC0]], 16
; HSAIL-NEXT: st_arg_align(4)_u32 [[RESULT]]
; HSAIL: ret;
define i32 @bitextract_signed_pat1_i32_rii_1(i32 %src0) #0 {
  %tmp0 = ashr i32 %src0, 16
  %tmp1 = and i32 %tmp0, 65535
  ret i32 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i32_rii_2(
; HSAIL: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL-NEXT: shr_s32 [[TMP:\$s[0-9]+]], [[SRC0]], 31
; HSAIL-NEXT: and_b32 [[RESULT:\$s[0-9]+]], [[TMP]], 7;
; HSAIL-NEXT: st_arg_align(4)_u32 [[RESULT]]
; HSAIL: ret;
define i32 @bitextract_signed_pat1_i32_rii_2(i32 %src0) #0 {
  %tmp0 = ashr i32 %src0, 31
  %tmp1 = and i32 %tmp0, 7
  ret i32 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i32_rii_3(
; HSAIL: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL: bitextract_u32 {{\$s[0-9]+}}, [[SRC0]], 20, 1;
; HSAIL: ret;
define i32 @bitextract_signed_pat1_i32_rii_3(i32 %src0) #0 {
  %tmp0 = ashr i32 %src0, 20
  %tmp1 = and i32 %tmp0, 1
  ret i32 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i32_rii_4(
; HSAIL: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL: bitextract_u32 {{\$s[0-9]+}}, [[SRC0]], 1, 5;
; HSAIL: ret;
define i32 @bitextract_signed_pat1_i32_rii_4(i32 %src0) #0 {
  %tmp0 = ashr i32 %src0, 1
  %tmp1 = and i32 %tmp0, 31
  ret i32 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i32_rii_5(
; HSAIL: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL: bitextract_u32 {{\$s[0-9]+}}, [[SRC0]], 27, 4;
; HSAIL: ret;
define i32 @bitextract_signed_pat1_i32_rii_5(i32 %src0) #0 {
  %tmp0 = ashr i32 %src0, 27
  %tmp1 = and i32 %tmp0, 15
  ret i32 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i32_rii_6(
; HSAIL: bitextract_u32 {{\$s[0-9]+}}, [[SRC0]], 27, 3;
; HSAIL: ret;
define i32 @bitextract_signed_pat1_i32_rii_6(i32 %src0) #0 {
  %tmp0 = ashr i32 %src0, 27
  %tmp1 = and i32 %tmp0, 7
  ret i32 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i32_rii_not_0(
; HSAIL-NOT: bitextract_u32
; HSAIL: ret;
define i32 @bitextract_signed_pat1_i32_rii_not_0(i32 %src0) #0 {
  %tmp0 = ashr i32 %src0, 11
  %tmp1 = and i32 %tmp0, 8
  ret i32 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i32_rri_0(
; HSAIL: shr_s32
; HSAIL: and_b32
; HSAIL: ret;
define i32 @bitextract_signed_pat1_i32_rri_0(i32 %src0, i32 %src1) #0 {
  %tmp0 = ashr i32 %src0, %src1
  %tmp1 = and i32 %tmp0, 7
  ret i32 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i32_rri_not_0(
; HSAIL-NOT: bitextract_u32
; HSAIL: ret;
define i32 @bitextract_signed_pat1_i32_rri_not_0(i32 %src0, i32 %src1) #0 {
  %tmp0 = ashr i32 %src0, %src1
  %tmp1 = and i32 %tmp0, 8
  ret i32 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i32_rii_not_1(
; HSAIL-NOT: bitextract_u32
; HSAIL: ret;
define i32 @bitextract_signed_pat1_i32_rii_not_1(i32 %src0) #0 {
  %tmp0 = ashr i32 %src0, 27
  %tmp1 = and i32 %tmp0, 8
  ret i32 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i32_rii_not_2(
; HSAIL-NOT: bitextract_u32
; HSAIL: ret;
define i32 @bitextract_signed_pat1_i32_rii_not_2(i32 %src0) #0 {
  %tmp0 = ashr i32 %src0, 27
  %tmp1 = and i32 %tmp0, 8
  ret i32 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i64_rii_0(
; HSAIL: bitextract_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 11, 3;
define i64 @bitextract_signed_pat1_i64_rii_0(i64 %src0) #0 {
  %tmp0 = ashr i64 %src0, 11 ; shift
  %tmp1 = and i64 %tmp0, 7 ; mask
  ret i64 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i64_rii_1(
; HSAIL: ld_arg_align(8)_u64 [[SRC0:\$d[0-9]+]], [%src0];
; HSAIL-NEXT: shr_u64 [[RESULT:\$d[0-9]+]], [[SRC0]], 32
; HSAIL-NEXT: st_arg_align(8)_u64 [[RESULT]]
; HSAIL: ret;
define i64 @bitextract_signed_pat1_i64_rii_1(i64 %src0) #0 {
  %tmp0 = ashr i64 %src0, 32
  %tmp1 = and i64 %tmp0, 4294967295
  ret i64 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i64_rii_2(
; HSAIL: ld_arg_align(8)_u64 [[SRC0:\$d[0-9]+]], [%src0];
; HSAIL-NEXT: shr_s64 [[TMP:\$d[0-9]+]], [[SRC0]], 63
; HSAIL-NEXT: and_b64 [[RESULT:\$d[0-9]+]], [[TMP]], 7;
; HSAIL-NEXT: st_arg_align(8)_u64 [[RESULT]]
; HSAIL: ret;
define i64 @bitextract_signed_pat1_i64_rii_2(i64 %src0) #0 {
  %tmp0 = ashr i64 %src0, 63
  %tmp1 = and i64 %tmp0, 7
  ret i64 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i64_rii_3(
; HSAIL: ld_arg_align(8)_u64 [[SRC0:\$d[0-9]+]], [%src0];
; HSAIL: bitextract_u64 {{\$d[0-9]+}}, [[SRC0]], 20, 1;
; HSAIL: ret;
define i64 @bitextract_signed_pat1_i64_rii_3(i64 %src0) #0 {
  %tmp0 = ashr i64 %src0, 20
  %tmp1 = and i64 %tmp0, 1
  ret i64 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i64_rii_4(
; HSAIL: ld_arg_align(8)_u64 [[SRC0:\$d[0-9]+]], [%src0];
; HSAIL: bitextract_u64 {{\$d[0-9]+}}, [[SRC0]], 1, 5;
; HSAIL: ret;
define i64 @bitextract_signed_pat1_i64_rii_4(i64 %src0) #0 {
  %tmp0 = ashr i64 %src0, 1
  %tmp1 = and i64 %tmp0, 31
  ret i64 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i64_rii_5(
; HSAIL: ld_arg_align(8)_u64 [[SRC0:\$d[0-9]+]], [%src0];
; HSAIL: bitextract_u64 {{\$d[0-9]+}}, [[SRC0]], 27, 4;
; HSAIL: ret;
define i64 @bitextract_signed_pat1_i64_rii_5(i64 %src0) #0 {
  %tmp0 = ashr i64 %src0, 27
  %tmp1 = and i64 %tmp0, 15
  ret i64 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i64_rii_6(
; HSAIL: bitextract_u64 {{\$d[0-9]+}}, [[SRC0]], 27, 3;
; HSAIL: ret;
define i64 @bitextract_signed_pat1_i64_rii_6(i64 %src0) #0 {
  %tmp0 = ashr i64 %src0, 27
  %tmp1 = and i64 %tmp0, 7
  ret i64 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i64_rii_not_0(
; HSAIL-NOT: bitextract_u64
; HSAIL: ret;
define i64 @bitextract_signed_pat1_i64_rii_not_0(i64 %src0) #0 {
  %tmp0 = ashr i64 %src0, 11
  %tmp1 = and i64 %tmp0, 8
  ret i64 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i64_rri_0(
; HSAIL: shr_s64
; HSAIL: and_b64
; HSAIL: ret;
define i64 @bitextract_signed_pat1_i64_rri_0(i64 %src0, i64 %src1) #0 {
  %tmp0 = ashr i64 %src0, %src1
  %tmp1 = and i64 %tmp0, 7
  ret i64 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i64_rri_not_0(
; HSAIL-NOT: bitextract_u64
; HSAIL: ret;
define i64 @bitextract_signed_pat1_i64_rri_not_0(i64 %src0, i64 %src1) #0 {
  %tmp0 = ashr i64 %src0, %src1
  %tmp1 = and i64 %tmp0, 8
  ret i64 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i64_rii_not_1(
; HSAIL-NOT: bitextract_u64
; HSAIL: ret;
define i64 @bitextract_signed_pat1_i64_rii_not_1(i64 %src0) #0 {
  %tmp0 = ashr i64 %src0, 27
  %tmp1 = and i64 %tmp0, 8
  ret i64 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i64_rii_not_2(
; HSAIL-NOT: bitextract_u64
; HSAIL: ret;
define i64 @bitextract_signed_pat1_i64_rii_not_2(i64 %src0) #0 {
  %tmp0 = ashr i64 %src0, 27
  %tmp1 = and i64 %tmp0, 8
  ret i64 %tmp1
}

; HSAIL-LABEL: {{^}}prog function &bitextract_signed_pat1_i64_rii_not_3(
; HSAIL-NOT: bitextract_u64
; HSAIL: ret;
define i64 @bitextract_signed_pat1_i64_rii_not_3(i64 %src0) #0 {
  %tmp0 = ashr i64 %src0, 59
  %tmp1 = and i64 %tmp0, 8
  ret i64 %tmp1
}

attributes #0 = { nounwind readnone }
