; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &or_v2i32
; HSAIL: or_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: or_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @or_v2i32(<2 x i32> addrspace(1)* %out, <2 x i32> addrspace(1)* %in) {
  %b_ptr = getelementptr <2 x i32>, <2 x i32> addrspace(1)* %in, i32 1
  %a = load <2 x i32>, <2 x i32> addrspace(1) * %in
  %b = load <2 x i32>, <2 x i32> addrspace(1) * %b_ptr
  %result = or <2 x i32> %a, %b
  store <2 x i32> %result, <2 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &or_v4i32
; HSAIL: or_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: or_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: or_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: or_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @or_v4i32(<4 x i32> addrspace(1)* %out, <4 x i32> addrspace(1)* %in) {
  %b_ptr = getelementptr <4 x i32>, <4 x i32> addrspace(1)* %in, i32 1
  %a = load <4 x i32>, <4 x i32> addrspace(1) * %in
  %b = load <4 x i32>, <4 x i32> addrspace(1) * %b_ptr
  %result = or <4 x i32> %a, %b
  store <4 x i32> %result, <4 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &scalar_or_i32
; HSAIL: or_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @scalar_or_i32(i32 addrspace(1)* %out, i32 %a, i32 %b) {
  %or = or i32 %a, %b
  store i32 %or, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &vector_or_i32
; HSAIL: or_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @vector_or_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %a, i32 %b) {
  %loada = load i32, i32 addrspace(1)* %a
  %or = or i32 %loada, %b
  store i32 %or, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &scalar_or_literal_i32
; HSAIL: or_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 99999;
define void @scalar_or_literal_i32(i32 addrspace(1)* %out, i32 %a) {
  %or = or i32 %a, 99999
  store i32 %or, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &vector_or_literal_i32
; HSAIL: or_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 65535;
define void @vector_or_literal_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %a, i32 addrspace(1)* %b) {
  %loada = load i32, i32 addrspace(1)* %a, align 4
  %or = or i32 %loada, 65535
  store i32 %or, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &vector_or_inline_immediate_i32
; HSAIL: or_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 4;
define void @vector_or_inline_immediate_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %a, i32 addrspace(1)* %b) {
  %loada = load i32, i32 addrspace(1)* %a, align 4
  %or = or i32 %loada, 4
  store i32 %or, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &scalar_or_i64
; HSAIL: or_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @scalar_or_i64(i64 addrspace(1)* %out, i64 %a, i64 %b) {
  %or = or i64 %a, %b
  store i64 %or, i64 addrspace(1)* %out
  ret void
}

; FUNC_LABEL: {{^}}prog function &vector_or_i64
; HSAIL: or_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @vector_or_i64(i64 addrspace(1)* %out, i64 addrspace(1)* %a, i64 addrspace(1)* %b) {
  %loada = load i64, i64 addrspace(1)* %a, align 8
  %loadb = load i64, i64 addrspace(1)* %a, align 8
  %or = or i64 %loada, %loadb
  store i64 %or, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &scalar_vector_or_i64
; HSAIL: or_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @scalar_vector_or_i64(i64 addrspace(1)* %out, i64 addrspace(1)* %a, i64 %b) {
  %loada = load i64, i64 addrspace(1)* %a
  %or = or i64 %loada, %b
  store i64 %or, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &vector_or_i64_loadimm
; HSAIL: or_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 22470723082367;
define void @vector_or_i64_loadimm(i64 addrspace(1)* %out, i64 addrspace(1)* %a, i64 addrspace(1)* %b) {
  %loada = load i64, i64 addrspace(1)* %a, align 8
  %or = or i64 %loada, 22470723082367
  store i64 %or, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &vector_or_i64_imm
; HSAIL: or_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 8;
define void @vector_or_i64_imm(i64 addrspace(1)* %out, i64 addrspace(1)* %a, i64 addrspace(1)* %b) {
  %loada = load i64, i64 addrspace(1)* %a, align 8
  %or = or i64 %loada, 8
  store i64 %or, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL:{{^}}prog function &trunc_i64_or_to_i32
; HSAIL: or_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: cvt_u32_u64 {{\$s[0-9]+}}, {{\$d[0-9]+}};
define void @trunc_i64_or_to_i32(i32 addrspace(1)* %out, i64 %a, i64 %b) {
  %add = or i64 %b, %a
  %trunc = trunc i64 %add to i32
  store i32 %trunc, i32 addrspace(1)* %out, align 8
  ret void
}

; FUNC-LABEL:{{^}}prog function &or_i1
; HSAIL: cmp_ge_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, 0F00000000;
; HSAIL: cmp_ge_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, 0F00000000;
; HSAIL: or_b1 {{\$c[0-9]+}}, {{\$c[0-9]+}}, {{\$c[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @or_i1(float addrspace(1)* %out, float addrspace(1)* %in0, float addrspace(1)* %in1) {
  %a = load float, float addrspace(1) * %in0
  %b = load float, float addrspace(1) * %in1
  %acmp = fcmp oge float %a, 0.000000e+00
  %bcmp = fcmp oge float %b, 0.000000e+00
  %or = or i1 %acmp, %bcmp
  %result = select i1 %or, float %a, float %b
  store float %result, float addrspace(1)* %out
  ret void
}
