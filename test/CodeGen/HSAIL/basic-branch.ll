; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &test_branch(
; HSAIL: ld_arg_align(4)_u32 [[VAL:\$s[0-9]+]], [%val];
; HSAIL: cmp_eq_b1_s32 [[CMP:\$c[0-9]+]], [[VAL]], 0;
; HSAIL: cbr_b1 [[CMP]], @BB0_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB0_2:}}
; HSAIL: ret;
define void @test_branch(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, i32 %val) nounwind {
  %cmp = icmp ne i32 %val, 0
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}
