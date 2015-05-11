; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &bitselect_pat0_rrr(
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC1:\$s[0-9]+]], [%src1];
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC2:\$s[0-9]+]], [%src2];

; HSAIL: bitselect_b32 {{\$s[0-9]+}}, [[SRC0]], [[SRC1]], [[SRC2]];
; HSAIL: ret;
define i32 @bitselect_pat0_rrr(i32 %src0, i32 %src1, i32 %src2) #0 {
  %tmp0 = and i32 %src0, %src1
  %tmp1 = xor i32 %src0, -1
  %tmp2 = and i32 %src2, %tmp1
  %or = or i32 %tmp0, %tmp2
  ret i32 %or
}

; HSAIL-LABEL: {{^}}prog function &bitselect_pat0_irr(
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC1:\$s[0-9]+]], [%src1];
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC2:\$s[0-9]+]], [%src2];
; HSAIL: bitselect_b32 {{\$s[0-9]+}}, 17, [[SRC1]], [[SRC2]];
; HSAIL: ret;
define i32 @bitselect_pat0_irr(i32 %src1, i32 %src2) #0 {
  %tmp0 = and i32 %src1, 17
  %tmp2 = and i32 %src2, -18
  %or = or i32 %tmp0, %tmp2
  ret i32 %or
}

; HSAIL-LABEL: {{^}}prog function &bitselect_pat0_rir(
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC2:\$s[0-9]+]], [%src2];
; HSAIL: bitselect_b32 {{\$s[0-9]+}}, [[SRC0]], 17, [[SRC2]];
; HSAIL: ret;
define i32 @bitselect_pat0_rir(i32 %src0, i32 %src2) #0 {
  %tmp0 = and i32 %src0, 17
  %tmp1 = xor i32 %src0, -1
  %tmp2 = and i32 %src2, %tmp1
  %or = or i32 %tmp0, %tmp2
  ret i32 %or
}

; HSAIL-LABEL: {{^}}prog function &bitselect_pat0_rii(
; HSAIL: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL: bitselect_b32 {{\$s[0-9]+}}, [[SRC0]], 11, 17;
; HSAIL: ret;
define i32 @bitselect_pat0_rii(i32 %src0, i32 %src1, i32 %src2) #0 {
  %tmp0 = and i32 %src0, 11
  %tmp1 = and i32 %src0, 17
  %tmp2 = xor i32 %tmp1, 17
  %or = or i32 %tmp0, %tmp2
  ret i32 %or
}

; HSAIL-LABEL: {{^}}prog function &bitselect_pat1_rii(
; HSAIL: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL: bitselect_b32 {{\$s[0-9]+}}, [[SRC0]], 17, 19;
; HSAIL: ret;
define i32 @bitselect_pat1_rii(i32 %src0, i32 %src2) #0 {
  %tmp0 = and i32 %src0, 17
  %tmp1 = and i32 %src0, 19
  %tmp2 = xor i32 %tmp1, 19

  %or = or i32 %tmp0, %tmp2
  ret i32 %or
}

; HSAIL-LABEL: {{^}}prog function &bitselect_not_pat1_rii(
; HSAIL-NOT: bitselect_b32
; HSAIL: ret;
define i32 @bitselect_not_pat1_rii(i32 %src0, i32 %src2) #0 {
  %tmp0 = and i32 %src0, 17
  %tmp1 = and i32 %src0, 19
  %tmp2 = xor i32 %tmp1, 18

  %or = or i32 %tmp0, %tmp2
  ret i32 %or
}

; HSAIL-LABEL: {{^}}prog function &bitselect_pat1_rri(
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC1:\$s[0-9]+]], [%src1];
; HSAIL: bitselect_b32 {{\$s[0-9]+}}, [[SRC0]], [[SRC1]], 13;
; HSAIL: ret;
define i32 @bitselect_pat1_rri(i32 %src0, i32 %src1) #0 {
  %tmp0 = and i32 %src0, %src1

  %tmp1 = xor i32 %src0, -1
  %tmp2 = and i32 %tmp1, 13

  %or = or i32 %tmp0, %tmp2
  ret i32 %or
}

; HSAIL-LABEL: {{^}}prog function &bitselect_pat2_rri(
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC1:\$s[0-9]+]], [%src1];
; HSAIL: bitselect_b32 {{\$s[0-9]+}}, [[SRC0]], [[SRC1]], 11;
; HSAIL: ret;
define i32 @bitselect_pat2_rri(i32 %src0, i32 %src1) #0 {
  %tmp0 = and i32 %src0, %src1

  %tmp1 = and i32 %src0, 11
  %tmp2 = xor i32 %tmp1, 11

  %xor = xor i32 %tmp0, %tmp2
  ret i32 %xor
}

; HSAIL-LABEL: {{^}}prog function &bitselect_not_pat2_rri(
; HSAIL-NOT: bitselect_b32
; HSAIL: ret;
define i32 @bitselect_not_pat2_rri(i32 %src0, i32 %src1) #0 {
  %tmp0 = and i32 %src0, %src1

  %tmp1 = and i32 %src0, 12
  %tmp2 = xor i32 %tmp1, 11

  %xor = xor i32 %tmp0, %tmp2
  ret i32 %xor
}

; HSAIL-LABEL: {{^}}prog function &bitselect_pat3_rrr(
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC1:\$s[0-9]+]], [%src1];
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC2:\$s[0-9]+]], [%src2];
; HSAIL: bitselect_b32 {{\$s[0-9]+}}, [[SRC0]], [[SRC1]], [[SRC2]];
; HSAIL: ret;
define i32 @bitselect_pat3_rrr(i32 %src0, i32 %src1, i32 %src2) #0 {
  %tmp0 = xor i32 %src1, %src2
  %tmp1 = and i32 %src0, %tmp0
  %tmp2 = xor i32 %src2, %tmp1
  ret i32 %tmp2
}

; HSAIL-LABEL: {{^}}prog function &bitselect_pat3_irr(
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC1:\$s[0-9]+]], [%src1];
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC2:\$s[0-9]+]], [%src2];
; HSAIL: bitselect_b32 {{\$s[0-9]+}}, 7, [[SRC1]], [[SRC2]];
; HSAIL: ret;
define i32 @bitselect_pat3_irr(i32 %src0, i32 %src1, i32 %src2) #0 {
  %tmp0 = xor i32 %src1, %src2
  %tmp1 = and i32 %tmp0, 7
  %tmp2 = xor i32 %src2, %tmp1
  ret i32 %tmp2
}

; HSAIL-LABEL: {{^}}prog function &bitselect_pat3_iir(
; HSAIL: ld_arg_align(4)_u32 [[SRC2:\$s[0-9]+]], [%src2];
; HSAIL: bitselect_b32 {{\$s[0-9]+}}, 23, 7, [[SRC2]];
; HSAIL: ret;
define i32 @bitselect_pat3_iir(i32 %src2) #0 {
  %tmp0 = xor i32 7, %src2
  %tmp1 = and i32 23, %tmp0
  %tmp2 = xor i32 %src2, %tmp1
  ret i32 %tmp2
}

; HSAIL-LABEL: {{^}}prog function &bitselect_pat3_rir(
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC2:\$s[0-9]+]], [%src2];
; HSAIL: bitselect_b32 {{\$s[0-9]+}}, [[SRC0]], 11, [[SRC2]];
; HSAIL: ret;
define i32 @bitselect_pat3_rir(i32 %src0, i32 %src2) #0 {
  %tmp0 = xor i32 11, %src2
  %tmp1 = and i32 %src0, %tmp0
  %tmp2 = xor i32 %src2, %tmp1
  ret i32 %tmp2
}

; HSAIL-LABEL: {{^}}prog function &bitselect_pat3_rri(
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC1:\$s[0-9]+]], [%src1];
; HSAIL: bitselect_b32 {{\$s[0-9]+}}, [[SRC0]], [[SRC1]], 23;
; HSAIL: ret;
define i32 @bitselect_pat3_rri(i32 %src0, i32 %src1) #0 {
  %tmp0 = xor i32 %src1, 23
  %tmp1 = and i32 %src0, %tmp0
  %tmp2 = xor i32 23, %tmp1
  ret i32 %tmp2
}

; HSAIL-LABEL: {{^}}prog function &bitselect_not_pat3_rri(
; HSAIL-NOT: bitselect_b32
; HSAIL: ret;
define i32 @bitselect_not_pat3_rri(i32 %src0, i32 %src1) #0 {
  %tmp0 = xor i32 %src1, 23
  %tmp1 = and i32 %src0, %tmp0
  %tmp2 = xor i32 17, %tmp1
  ret i32 %tmp2
}

; HSAIL-LABEL: {{^}}prog function &bitselect_pat4_rrr(
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC1:\$s[0-9]+]], [%src1];
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC2:\$s[0-9]+]], [%src2];
; HSAIL: bitselect_b32 {{\$s[0-9]+}}, [[SRC0]], [[SRC1]], [[SRC2]];
; HSAIL: ret;
define i32 @bitselect_pat4_rrr(i32 %src0, i32 %src1, i32 %src2) #0 {
  %tmp0 = and i32 %src0, %src2
  %tmp1 = xor i32 %src2, %tmp0

  %tmp2 = and i32 %src0, %src1

  %tmp3 = xor i32 %tmp1, %tmp2
  ret i32 %tmp3
}

; FIXME: This should match, but permuting the operators prevents the
; match.

; HSAIL-LABEL: {{^}}prog function &bitselect_pat4_rrr_commute0(
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC1:\$s[0-9]+]], [%src1];
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC2:\$s[0-9]+]], [%src2];
; HSAIL-NOT: bitselect_b32
; HSAIL: ret;
define i32 @bitselect_pat4_rrr_commute0(i32 %src0, i32 %src1, i32 %src2) #0 {
  %tmp0 = and i32 %src0, %src2
  %tmp1 = xor i32 %tmp0, %src2 ; Commuting breaks match

  %tmp2 = and i32 %src0, %src1

  %tmp3 = xor i32 %tmp2, %tmp1
  ret i32 %tmp3
}

; bitselect_pat4_rrr run through instcombine.
; FIXME: This should match bitselect
; HSAIL-LABEL: {{^}}prog function &bitselect_pat4_canonical_rrr(
; HSAIL-NOT: bitselect_b32
; HSAIL: ret;
define i32 @bitselect_pat4_canonical_rrr(i32 %src0, i32 %src1, i32 %src2) #0 {
  %tmp0 = xor i32 %src0, -1
  %tmp1 = and i32 %tmp0, %src2
  %tmp2 = and i32 %src0, %src1
  %tmp3 = xor i32 %tmp2, %tmp1
  ret i32 %tmp3
}

; HSAIL-LABEL: {{^}}prog function &bitselect_pat4_irr(
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC1:\$s[0-9]+]], [%src1];
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC2:\$s[0-9]+]], [%src2];
; HSAIL: bitselect_b32 {{\$s[0-9]+}}, 9, [[SRC1]], [[SRC2]];
; HSAIL: ret;
define i32 @bitselect_pat4_irr(i32 %src1, i32 %src2) #0 {
  %tmp0 = and i32 9, %src2
  %tmp1 = xor i32 %src2, %tmp0

  %tmp2 = and i32 9, %src1

  %tmp3 = xor i32 %tmp1, %tmp2
  ret i32 %tmp3
}

; HSAIL-LABEL: {{^}}prog function &bitselect_not_pat4_irr(
; HSAIL-NOT: bitselect_b32
; HSAIL: ret;
define i32 @bitselect_not_pat4_irr(i32 %src1, i32 %src2) #0 {
  %tmp0 = and i32 9, %src2
  %tmp1 = xor i32 %src2, %tmp0

  %tmp2 = and i32 11, %src1

  %tmp3 = xor i32 %tmp1, %tmp2
  ret i32 %tmp3
}

; HSAIL-LABEL: {{^}}prog function &bitselect_pat4_iir(
; HSAIL: ld_arg_align(4)_u32 [[SRC2:\$s[0-9]+]], [%src2];
; HSAIL: bitselect_b32 {{\$s[0-9]+}}, 7, 5, [[SRC2]];
; HSAIL: ret;
define i32 @bitselect_pat4_iir(i32 %src2) #0 {
  %tmp0 = and i32 %src2, 7
  %tmp1 = xor i32 %src2, %tmp0
  %tmp2 = xor i32 %tmp1, 5
  ret i32 %tmp2
}

; HSAIL-LABEL: {{^}}prog function &bitselect_pat4_rri(
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL-DAG: ld_arg_align(4)_u32 [[SRC1:\$s[0-9]+]], [%src1];
; HSAIL: bitselect_b32 {{\$s[0-9]+}}, [[SRC0]], [[SRC1]], 9;
; HSAIL: ret;
define i32 @bitselect_pat4_rri(i32 %src0, i32 %src1, i32 %src2) #0 {
  %tmp0 = and i32 %src0, 9
  %tmp1 = xor i32 %tmp0, 9

  %tmp2 = and i32 %src0, %src1

  %tmp3 = xor i32 %tmp1, %tmp2
  ret i32 %tmp3
}

; HSAIL-LABEL: {{^}}prog function &bitselect_not_pat4_rri(
; HSAIL-NOT: bitselect_b32
; HSAIL: ret;
define i32 @bitselect_not_pat4_rri(i32 %src0, i32 %src1, i32 %src2) #0 {
  %tmp0 = and i32 %src0, 9
  %tmp1 = xor i32 %tmp0, 12

  %tmp2 = and i32 %src0, %src1

  %tmp3 = xor i32 %tmp1, %tmp2
  ret i32 %tmp3
}

; HSAIL-LABEL: {{^}}prog function &bitselect_pat4_rii(
; HSAIL: ld_arg_align(4)_u32 [[SRC0:\$s[0-9]+]], [%src0];
; HSAIL: bitselect_b32 {{\$s[0-9]+}}, [[SRC0]], 7, 9;
; HSAIL: ret;
define i32 @bitselect_pat4_rii(i32 %src0, i32 %src1, i32 %src2) #0 {
  %tmp0 = and i32 %src0, 9
  %tmp1 = xor i32 %tmp0, 9

  %tmp2 = and i32 %src0, 7

  %tmp3 = xor i32 %tmp1, %tmp2
  ret i32 %tmp3
}

; HSAIL-LABEL: {{^}}prog function &bitselect_not_pat4_rii(
; HSAIL-NOT: bitselect_b32
; HSAIL: ret;
define i32 @bitselect_not_pat4_rii(i32 %src0, i32 %src1, i32 %src2) #0 {
  %tmp0 = and i32 %src0, 10
  %tmp1 = xor i32 %tmp0, 9

  %tmp2 = and i32 %src0, 7

  %tmp3 = xor i32 %tmp1, %tmp2
  ret i32 %tmp3
}

attributes #0 = { nounwind readnone }
