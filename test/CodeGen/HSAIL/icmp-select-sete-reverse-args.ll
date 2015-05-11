; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &test
; HSAIL: cmp_eq_b1_s32  {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32  {{\$s[0-9]+}}, {{\$c[0-9]+}}, 0, 4294967295;
define void @test(i32 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %tmp0 = load i32, i32 addrspace(1)* %in
  %arrayidx1 = getelementptr inbounds i32, i32 addrspace(1)* %in, i32 1
  %tmp1 = load i32, i32 addrspace(1)* %arrayidx1
  %cmp = icmp eq i32 %tmp0, %tmp1
  %value = select i1 %cmp, i32 0, i32 -1
  store i32 %value, i32 addrspace(1)* %out
  ret void
}
