; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &test_mul_v2i32
; HSAIL: mul_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: mul_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @test_mul_v2i32(<2 x i32> addrspace(1)* %out, <2 x i32> addrspace(1)* %in) {
  %b_ptr = getelementptr <2 x i32> addrspace(1)* %in, i32 1
  %a = load <2 x i32> addrspace(1) * %in
  %b = load <2 x i32> addrspace(1) * %b_ptr
  %result = mul <2 x i32> %a, %b
  store <2 x i32> %result, <2 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &v_mul_v4i32
; HSAIL: mul_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: mul_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: mul_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: mul_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @v_mul_v4i32(<4 x i32> addrspace(1)* %out, <4 x i32> addrspace(1)* %in) {
  %b_ptr = getelementptr <4 x i32> addrspace(1)* %in, i32 1
  %a = load <4 x i32> addrspace(1) * %in
  %b = load <4 x i32> addrspace(1) * %b_ptr
  %result = mul <4 x i32> %a, %b
  store <4 x i32> %result, <4 x i32> addrspace(1)* %out
  ret void
}


; FUNC-LABEL: {{^}}prog function &s_trunc_i64_mul_to_i32
; HSAIL: mul_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: cvt_u32_u64  {{\$s[0-9]+}}, {{\$d[0-9]+}};
define void @s_trunc_i64_mul_to_i32(i32 addrspace(1)* %out, i64 %a, i64 %b) {
  %mul = mul i64 %b, %a
  %trunc = trunc i64 %mul to i32
  store i32 %trunc, i32 addrspace(1)* %out, align 8
  ret void
}

; FUNC-LABEL:{{^}}prog function &v_trunc_i64_mul_to_i32
; HSAIL: mul_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: cvt_u32_u64  {{\$s[0-9]+}}, {{\$d[0-9]+}};
define void @v_trunc_i64_mul_to_i32(i32 addrspace(1)* %out, i64 addrspace(1)* %aptr, i64 addrspace(1)* %bptr) nounwind {
  %a = load i64 addrspace(1)* %aptr, align 8
  %b = load i64 addrspace(1)* %bptr, align 8
  %mul = mul i64 %b, %a
  %trunc = trunc i64 %mul to i32
  store i32 %trunc, i32 addrspace(1)* %out, align 8
  ret void
}

; FUNC-LABEL:{{^}}prog function &mul64_sext_c
; HSAIL: cvt_s64_s32 {{\$d[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: mul_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 80;
define void @mul64_sext_c(i64 addrspace(1)* %out, i32 %in) {
entry:
  %0 = sext i32 %in to i64
  %1 = mul i64 %0, 80
  store i64 %1, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &v_mul64_sext_c
; HSAIL: cvt_s64_s32 {{\$d[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: mul_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 80;
define void @v_mul64_sext_c(i64 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %val = load i32 addrspace(1)* %in, align 4
  %ext = sext i32 %val to i64
  %mul = mul i64 %ext, 80
  store i64 %mul, i64 addrspace(1)* %out, align 8
  ret void
}


; FUNC-LABEL: {{^}}prog function &v_mul64_sext_inline_imm
; HSAIL: cvt_s64_s32 {{\$d[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: mul_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 9;
define void @v_mul64_sext_inline_imm(i64 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %val = load i32 addrspace(1)* %in, align 4
  %ext = sext i32 %val to i64
  %mul = mul i64 %ext, 9
  store i64 %mul, i64 addrspace(1)* %out, align 8
  ret void
}

; FUNC-LABEL: {{^}}prog function &s_mul_i32
; HSAIL: mul_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @s_mul_i32(i32 addrspace(1)* %out, i32 %a, i32 %b) nounwind {
  %mul = mul i32 %a, %b
  store i32 %mul, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &v_mul_i32
; HSAIL: mul_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @v_mul_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %b_ptr = getelementptr i32 addrspace(1)* %in, i32 1
  %a = load i32 addrspace(1)* %in
  %b = load i32 addrspace(1)* %b_ptr
  %result = mul i32 %a, %b
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &s_mul_i64
; HSAIL: mul_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @s_mul_i64(i64 addrspace(1)* %out, i64 %a, i64 %b) nounwind {
  %mul = mul i64 %a, %b
  store i64 %mul, i64 addrspace(1)* %out, align 8
  ret void
}

; FUNC-LABEL: {{^}}prog function &v_mul_i64
; HSAIL: mul_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @v_mul_i64(i64 addrspace(1)* %out, i64 addrspace(1)* %aptr, i64 addrspace(1)* %bptr) {
  %a = load i64 addrspace(1)* %aptr, align 8
  %b = load i64 addrspace(1)* %bptr, align 8
  %mul = mul i64 %a, %b
  store i64 %mul, i64 addrspace(1)* %out, align 8
  ret void
}

; FUNC-LABEL: {{^}}prog function &mul32_in_branch
; HSAIL: cmp_eq_b1_s32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, 0;
; HSAIL: mul_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @mul32_in_branch(i32 addrspace(1)* %out, i32 addrspace(1)* %in, i32 %a, i32 %b, i32 %c) {
entry:
  %0 = icmp eq i32 %a, 0
  br i1 %0, label %if, label %else

if:
  %1 = load i32 addrspace(1)* %in
  br label %endif

else:
  %2 = mul i32 %a, %b
  br label %endif

endif:
  %3 = phi i32 [%1, %if], [%2, %else]
  store i32 %3, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &mul64_in_branch
; HSAIL: cmp_eq_b1_s64 {{\$c[0-9]+}}, {{\$d[0-9]+}}, 0;
; HSAIL: mul_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @mul64_in_branch(i64 addrspace(1)* %out, i64 addrspace(1)* %in, i64 %a, i64 %b, i64 %c) {
entry:
  %0 = icmp eq i64 %a, 0
  br i1 %0, label %if, label %else

if:
  %1 = load i64 addrspace(1)* %in
  br label %endif

else:
  %2 = mul i64 %a, %b
  br label %endif

endif:
  %3 = phi i64 [%1, %if], [%2, %else]
  store i64 %3, i64 addrspace(1)* %out
  ret void
}
