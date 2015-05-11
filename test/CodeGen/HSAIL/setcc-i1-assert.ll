; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; FIXME: cmp_ne_b1_b1
; HSAIL-LABEL: {{^}}prog function &setcc_i1_branch(
; HSAIL-DAG: cmp_gt_b1_s32 [[C0:\$c[0-9]+]], {{\$s[0-9]+}}, 0;
; HSAIL-DAG: cmp_lt_b1_s32 [[C1:\$c[0-9]+]], {{\$s[0-9]+}}, 0;
; HSAIL: and_b1 [[AND:\$c[0-9]+]], [[C0]], [[C1]];
; HSAIL: cmp_ne_b1_b1 {{\$c[0-9]+}}, [[AND]], 1;
; HSAIL: ret
define void @setcc_i1_branch(i32 %arg, i32 %arg1) #0 {
bb:
  %tmp = icmp sgt i32 %arg1, 0
  %tmp2 = icmp slt i32 %arg, 0
  %tmp3 = and i1 %tmp, %tmp2
  br i1 %tmp3, label %bb4, label %bb8

bb4:                                              ; preds = %bb
  ret void

bb8:                                              ; preds = %bb6
  ret void
}

attributes #0 = { nounwind }
