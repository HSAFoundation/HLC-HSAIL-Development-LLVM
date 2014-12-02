; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &test_select_v4i64
; HSAIL: cmp_ne_b1_s32  {{\$c[0-9]+}}, {{\$s[0-9]+}}, 0;
; HSAIL: cmov_b64  {{\$d[0-9]+}}, {{\$c[0-9]+}}, 0, 4;
; HSAIL: cmp_ne_b1_s32  {{\$c[0-9]+}}, {{\$s[0-9]+}}, 0;
; HSAIL: cmov_b64  {{\$d[0-9]+}}, {{\$c[0-9]+}}, 1, 5;
; HSAIL: cmp_ne_b1_s32  {{\$c[0-9]+}}, {{\$s[0-9]+}}, 0;
; HSAIL: cmov_b64  {{\$d[0-9]+}}, {{\$c[0-9]+}}, 2, 6;
; HSAIL: cmp_ne_b1_s32  {{\$c[0-9]+}}, {{\$s[0-9]+}}, 0;
; HSAIL: cmov_b64  {{\$d[0-9]+}}, {{\$c[0-9]+}}, 3, 7;
define void @test_select_v4i64(<4 x i64> addrspace(1)* %out, <4 x i32> %c) {
  %cmp = icmp ne  <4 x i32> %c, <i32 0, i32 0, i32 0, i32 0>
  %result = select <4 x i1> %cmp, <4 x i64> <i64 0, i64 1, i64 2, i64 3>, <4 x i64> <i64 4, i64 5, i64 6, i64 7>
  store <4 x i64> %result, <4 x i64> addrspace(1)* %out
  ret void
}

