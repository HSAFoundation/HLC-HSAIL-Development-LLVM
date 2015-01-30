; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &bitalign_pat0_0(
; HSAIL: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL: bytealign_b32 {{\$s[0-9]+}}, [[SRC0]], [[SRC0]], 2;
; HSAIL: ret;
define i32 @bitalign_pat0_0(i32 %src0) #0 {
  %tmp0 = shl i32 %src0, 16
  %tmp1 = lshr i32 %src0, 16
  %or = or i32 %tmp0, %tmp1
  ret i32 %or
}

; HSAIL-LABEL: {{^}}prog function &bitalign_pat0_1(
; HSAIL: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL: bitalign_b32 {{\$s[0-9]+}}, [[SRC0]], [[SRC0]], 1;
; HSAIL: ret;
define i32 @bitalign_pat0_1(i32 %src0) #0 {
  %tmp0 = shl i32 %src0, 31
  %tmp1 = lshr i32 %src0, 1
  %or = or i32 %tmp0, %tmp1
  ret i32 %or
}

; HSAIL-LABEL: {{^}}prog function &bitalign_pat0_2(
; HSAIL: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL: bitalign_b32 {{\$s[0-9]+}}, [[SRC0]], [[SRC0]], 31;
; HSAIL: ret;
define i32 @bitalign_pat0_2(i32 %src0) #0 {
  %tmp0 = shl i32 %src0, 1
  %tmp1 = lshr i32 %src0, 31
  %or = or i32 %tmp0, %tmp1
  ret i32 %or
}

; HSAIL-LABEL: {{^}}prog function &bitalign_pat0_3(
; HSAIL: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL: bitalign_b32 {{\$s[0-9]+}}, [[SRC0]], [[SRC0]], 23;
; HSAIL: ret;
define i32 @bitalign_pat0_3(i32 %src0) #0 {
  %tmp0 = shl i32 %src0, 9
  %tmp1 = lshr i32 %src0, 23
  %or = or i32 %tmp0, %tmp1
  ret i32 %or
}

; HSAIL-LABEL: {{^}}prog function &bitalign_pat0_4(
; HSAIL: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL: bytealign_b32 {{\$s[0-9]+}}, [[SRC0]], [[SRC0]], 3;
; HSAIL: ret;
define i32 @bitalign_pat0_4(i32 %src0) #0 {
  %tmp0 = shl i32 %src0, 8
  %tmp1 = lshr i32 %src0, 24
  %or = or i32 %tmp0, %tmp1
  ret i32 %or
}

; HSAIL-LABEL: {{^}}prog function &bitalign_pat0_5(
; HSAIL: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL: bytealign_b32 {{\$s[0-9]+}}, [[SRC0]], [[SRC0]], 1;
; HSAIL: ret;
define i32 @bitalign_pat0_5(i32 %src0) #0 {
  %tmp0 = shl i32 %src0, 24
  %tmp1 = lshr i32 %src0, 8
  %or = or i32 %tmp0, %tmp1
  ret i32 %or
}

; FIXME: The pattern looks like it is supposed to eliminate the and of
; src1.

; HSAIL-LABEL: {{^}}prog function &bitalign_pat1(
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC1:\$s[0-9]+]], [%src1];
; HSAIL-DAG: and_b32 [[AND_SRC1:\$s[0-9]+]], [[SRC1]], 31;
; HSAIL-DAG: neg_s32 [[NEG_SRC1:\$s[0-9]+]], [[AND_SRC1]];
; HSAIL: bitalign_b32 {{\$s[0-9]+}}, [[SRC0]], [[SRC0]], [[NEG_SRC1]];
; HSAIL: ret;
define i32 @bitalign_pat1(i32 %src0, i32 %src1) #0 {
  %and31 = and i32 %src1, 31
  %shl = shl i32 %src0, %and31

  %neg.src1 = sub i32 0, %src1
  %and.neg = and i32 %neg.src1, 31
  %srl = lshr i32 %src0, %and.neg

  %or = or i32 %shl, %srl
  ret i32 %or
}

; HSAIL-LABEL: {{^}}prog function &bitalign_pat2(
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC1:\$s[0-9]+]], [%src1];
; HSAIL-DAG: neg_s32 [[NEG_SRC1:\$s[0-9]+]], [[SRC1]]
; HSAIL: bitalign_b32 {{\$s[0-9]+}}, [[SRC0]], [[SRC0]], [[NEG_SRC1]];
; HSAIL: ret;
define i32 @bitalign_pat2(i32 %src0, i32 %src1) #0 {
  %shl = shl i32 %src0, %src1

  %and = and i32 %src1, 31
  %sub = sub i32 32, %and
  %srl = lshr i32 %src0, %sub

  %or = or i32 %shl, %srl
  ret i32 %or
}

attributes #0 = { nounwind readnone }
