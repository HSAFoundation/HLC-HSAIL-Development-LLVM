; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &test_loop
; HSAIL: ld_arg
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 1;
; HSAIL: ld_arg
; HSAIL: {{^@BB0_1:}}
; HSAIL: st_global_align(4)_u32 222, [
; HSAIL: cmp_ne_b1_s32 $c0, {{\$s[0-9]+}}, 0;
; HSAIL-NEXT: cbr_b1 {{\$c[0-9]+}}, @BB0_1;
; HSAIL: };
define void @test_loop(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, i32 %val) nounwind {
entry:
  br label %loop.body

loop.body:
  %i = phi i32 [0, %entry], [%i.inc, %loop.body]
  store i32 222, i32 addrspace(1)* %out
  %cmp = icmp ne i32 %i, %val
  %i.inc = add i32 %i, 1
  br i1 %cmp, label %loop.body, label %end

end:
  ret void
}
