; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; This asserted in the register coalescer because it couldn't figure
; out the dest reg class from the mov instruction definition.

; HSAIL-LABEL: {{^}}prog function &foo(
; HSAIL: mov_b64 {{\$d[0-9]+}}, 0;
; HSAIL: mov_b64 {{\$d[0-9]+}}, 0;
; HSAIL-NOT: mov
; HSAIL: @BB0_1:
; HSAIL-NOT: mov
; HSAIL: br
define void @foo() #0 {
bb:
  br label %bb1

bb1:
  %tmp = phi i64 [ 0, %bb ], [ %tmp5, %bb1 ]
  %tmp2 = mul nsw i64 %tmp, 6
  %tmp3 = insertelement <4 x i64> undef, i64 %tmp2, i32 1
  %tmp4 = mul nsw i64 %tmp, 15
  %tmp5 = add i64 %tmp, 1
  br label %bb1
}

attributes #0 = { nounwind }
