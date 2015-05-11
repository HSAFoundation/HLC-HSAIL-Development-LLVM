; XFAIL: *
; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &test
; HSAIL: mad_u32  {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_u64_u32  {{\$d[0-9]+}}, {{\$s[0-9]+}};
define void @test(i64 addrspace(1)* %out, i32 %a, i32 %b, i32 %c) {
entry:
  %tmp0 = mul i32 %a, %b
  %tmp1 = add i32 %tmp0, %c
  %tmp2 = zext i32 %tmp1 to i64
  store i64 %tmp2, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &testi1toi32
; HSAIL: cmp_eq_b1_s32  {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_u32_b1  {{\$s[0-9]+}}, {{\$c[0-9]+}};
define void @testi1toi32(i32 addrspace(1)* %out, i32 %a, i32 %b) {
entry:
  %tmp0 = icmp eq i32 %a, %b
  %tmp1 = zext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &zext_i1_to_i64
; HSAIL: cmp_eq_b1_s32  {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_u64_b1  {{\$d[0-9]+}}, {{\$c[0-9]+}};
define void @zext_i1_to_i64(i64 addrspace(1)* %out, i32 %a, i32 %b) nounwind {
  %cmp = icmp eq i32 %a, %b
  %ext = zext i1 %cmp to i64
  store i64 %ext, i64 addrspace(1)* %out, align 8
  ret void
}
