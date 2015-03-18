; RUN: llc -march=hsail64 < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL: {{^}}readonly_u32 &gv[1] = u32[](1);

@gv = private addrspace(2) constant [1 x i32] [i32 1], align 4

define i32 @gv_user() #0 {
  %tmp = getelementptr inbounds [1 x i32] addrspace(2)* @gv, i64 0, i64 undef
  %val = load i32 addrspace(2)*%tmp
  ret i32 %val
}

attributes #0 = { nounwind uwtable }
