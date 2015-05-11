; RUN: llc -march=hsail -filetype=asm < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &test2
; HSAIL: and_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: and_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @test2(<2 x i32> addrspace(1)* %out, <2 x i32> addrspace(1)* %in) {
  %b_ptr = getelementptr <2 x i32>, <2 x i32> addrspace(1)* %in, i32 1
  %a = load <2 x i32>, <2 x i32> addrspace(1) * %in
  %b = load <2 x i32>, <2 x i32> addrspace(1) * %b_ptr
  %result = and <2 x i32> %a, %b
  store <2 x i32> %result, <2 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test4
; HSAIL: and_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: and_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: and_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: and_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @test4(<4 x i32> addrspace(1)* %out, <4 x i32> addrspace(1)* %in) {
  %b_ptr = getelementptr <4 x i32>, <4 x i32> addrspace(1)* %in, i32 1
  %a = load <4 x i32>, <4 x i32> addrspace(1) * %in
  %b = load <4 x i32>, <4 x i32> addrspace(1) * %b_ptr
  %result = and <4 x i32> %a, %b
  store <4 x i32> %result, <4 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &s_and_i32
; HSAIL: and_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @s_and_i32(i32 addrspace(1)* %out, i32 %a, i32 %b) {
  %and = and i32 %a, %b
  store i32 %and, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &s_and_constant_i32
; HSAIL: and_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 1234567;
define void @s_and_constant_i32(i32 addrspace(1)* %out, i32 %a) {
  %and = and i32 %a, 1234567
  store i32 %and, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &v_and_i32
; HSAIL: and_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @v_and_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %aptr, i32 addrspace(1)* %bptr) {
  %a = load i32, i32 addrspace(1)* %aptr, align 4
  %b = load i32, i32 addrspace(1)* %bptr, align 4
  %and = and i32 %a, %b
  store i32 %and, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &v_and_constant_i32
; HSAIL: and_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 1234567;
define void @v_and_constant_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %aptr) {
  %a = load i32, i32 addrspace(1)* %aptr, align 4
  %and = and i32 %a, 1234567
  store i32 %and, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &s_and_i64
; HSAIL: and_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @s_and_i64(i64 addrspace(1)* %out, i64 %a, i64 %b) {
  %and = and i64 %a, %b
  store i64 %and, i64 addrspace(1)* %out, align 8
  ret void
}

; FUNC-LABEL: {{^}}prog function &s_and_i1
; HSAIL: and_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: and_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 1;
define void @s_and_i1(i1 addrspace(1)* %out, i1 %a, i1 %b) {
  %and = and i1 %a, %b
  store i1 %and, i1 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &s_and_constant_i64
; HSAIL: and_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 281474976710655
define void @s_and_constant_i64(i64 addrspace(1)* %out, i64 %a) {
  %and = and i64 %a, 281474976710655
  store i64 %and, i64 addrspace(1)* %out, align 8
  ret void
}

; FUNC-LABEL: {{^}}prog function &v_and_i64
; HSAIL: and_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @v_and_i64(i64 addrspace(1)* %out, i64 addrspace(1)* %aptr, i64 addrspace(1)* %bptr) {
  %a = load i64, i64 addrspace(1)* %aptr, align 8
  %b = load i64, i64 addrspace(1)* %bptr, align 8
  %and = and i64 %a, %b
  store i64 %and, i64 addrspace(1)* %out, align 8
  ret void
}

; FUNC-LABEL: {{^}}prog function &v_and_i64_br
; HSAIL-DAG: mov_b64 {{\$d[0-9]+}}, 0;
; HSAIL-DAG: cmp_ne_b1_s32  {{\$c[0-9]+}}, {{\$s[0-9]+}}, 0;
; HSAIL: cbr_b1 {{\$c[0-9]+}}, @BB10_2;

; HSAIL: ld_global_align(8)_u64 {{\$d[0-9]+}}, [{{\$s[0-9]+}}];
; HSAIL: ld_global_align(8)_u64 {{\$d[0-9]+}}, [{{\$s[0-9]+}}];
; HSAIL: and_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};

; HSAIL: {{^}}@BB10_2:
; HSAIL: st_global_align(8)_u64 {{\$d[0-9]+}}, [{{\$s[0-9]+}}];
; HSAIL: ret;
define void @v_and_i64_br(i64 addrspace(1)* %out, i64 addrspace(1)* %aptr, i64 addrspace(1)* %bptr, i32 %cond) {
entry:
  %tmp0 = icmp eq i32 %cond, 0
  br i1 %tmp0, label %if, label %endif

if:
  %a = load i64, i64 addrspace(1)* %aptr, align 8
  %b = load i64, i64 addrspace(1)* %bptr, align 8
  %and = and i64 %a, %b
  br label %endif

endif:
  %tmp1 = phi i64 [%and, %if], [0, %entry]
  store i64 %tmp1, i64 addrspace(1)* %out, align 8
  ret void
}

; FUNC-LABEL: {{^}}prog function &v_and_constant_i64
; HSAIL: and_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 1234567;
define void @v_and_constant_i64(i64 addrspace(1)* %out, i64 addrspace(1)* %aptr) {
  %a = load i64, i64 addrspace(1)* %aptr, align 8
  %and = and i64 %a, 1234567
  store i64 %and, i64 addrspace(1)* %out, align 8
  ret void
}

; FUNC-LABEL:{{^}}prog function &and_i1
; HSAIL: cmp_ge_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, 0F00000000;
; HSAIL: cmp_ge_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, 0F00000000;
; HSAIL: and_b1 {{\$c[0-9]+}}, {{\$c[0-9]+}}, {{\$c[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @and_i1(float addrspace(1)* %out, float addrspace(1)* %in0, float addrspace(1)* %in1) {
  %a = load float, float addrspace(1) * %in0
  %b = load float, float addrspace(1) * %in1
  %acmp = fcmp oge float %a, 0.000000e+00
  %bcmp = fcmp oge float %b, 0.000000e+00
  %or = and i1 %acmp, %bcmp
  %result = select i1 %or, float %a, float %b
  store float %result, float addrspace(1)* %out
  ret void
}
