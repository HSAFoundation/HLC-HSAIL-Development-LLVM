; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &select_i1
; HSAIL-DAG: ld_arg_align(4)_u32 [[COND:\$s[0-9]+]], [%cond];
; HSAIL-DAG: ld_arg_u8 [[A:\$s[0-9]+]], [%a];
; HSAIL-DAG: ld_arg_u8 [[B:\$s[0-9]+]], [%b];

; HSAIL-DAG: cvt_b1_u32 [[CVTA:\$c[0-9]+]], [[A]];
; HSAIL-DAG: cvt_b1_u32 [[CVTB:\$c[0-9]+]], [[B]];
; HSAIL-DAG: cmp_gt_b1_u32 [[CMP:\$c[0-9]+]], [[COND]], 5;

; HSAIL: cmov_b1 [[RESULT:\$c[0-9]+]], [[CMP]], [[CVTA]], [[CVTB]];
; HSAIL: cvt_s32_b1 [[CVTRESULT:\$s[0-9]+]], [[RESULT]];
; HSAIL: st_global_align(4)_u8 [[CVTRESULT]]
define void @select_i1(i1 addrspace(1)* %out, i32 %cond, i1 %a, i1 %b) nounwind {
  %cmp = icmp ugt i32 %cond, 5
  %sel = select i1 %cmp, i1 %a, i1 %b
  store i1 %sel, i1 addrspace(1)* %out, align 4
  ret void
}
