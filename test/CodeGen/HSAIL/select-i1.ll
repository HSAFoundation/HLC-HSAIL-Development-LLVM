; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &select_i1
; HSAIL: and_b32  {{\$s[0-9]+}}, {{\$s[0-9]+}}, 1;
; HSAIL: and_b32  {{\$s[0-9]+}}, {{\$s[0-9]+}}, 1;
; HSAIL: cmp_gt_b1_u32  {{\$c[0-9]+}}, {{\$s[0-9]+}}, 5;
; HSAIL: cvt_b1_u32 {{\$c[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_b1_u32 {{\$c[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b1  {{\$c[0-9]+}}, {{\$c[0-9]+}}, {{\$c[0-9]+}}, {{\$c[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;

define void @select_i1(i1 addrspace(1)* %out, i32 %cond, i1 %a, i1 %b) nounwind {
  %cmp = icmp ugt i32 %cond, 5
  %sel = select i1 %cmp, i1 %a, i1 %b
  store i1 %sel, i1 addrspace(1)* %out, align 4
  ret void
}
