; XFAIL: *
; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &xor_v2i32
; HSAIL: xor_b32	{{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: xor_b32	{{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @xor_v2i32(<2 x i32> addrspace(1)* %out, <2 x i32> addrspace(1)* %in0, <2 x i32> addrspace(1)* %in1) {
  %a = load <2 x i32>, <2 x i32> addrspace(1) * %in0
  %b = load <2 x i32>, <2 x i32> addrspace(1) * %in1
  %result = xor <2 x i32> %a, %b
  store <2 x i32> %result, <2 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &xor_v4i32
; HSAIL: xor_b32	{{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: xor_b32	{{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: xor_b32	{{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: xor_b32	{{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @xor_v4i32(<4 x i32> addrspace(1)* %out, <4 x i32> addrspace(1)* %in0, <4 x i32> addrspace(1)* %in1) {
  %a = load <4 x i32>, <4 x i32> addrspace(1) * %in0
  %b = load <4 x i32>, <4 x i32> addrspace(1) * %in1
  %result = xor <4 x i32> %a, %b
  store <4 x i32> %result, <4 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &xor_i1
; HSAIL: cmp_ge_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, 0F00000000;
; HSAIL: cmp_ge_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, 0F00000000;
; HSAIL: xor_b1 {{\$c[0-9]+}}, {{\$c[0-9]+}}, {{\$c[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @xor_i1(float addrspace(1)* %out, float addrspace(1)* %in0, float addrspace(1)* %in1) {
  %a = load float, float addrspace(1) * %in0
  %b = load float, float addrspace(1) * %in1
  %acmp = fcmp oge float %a, 0.000000e+00
  %bcmp = fcmp oge float %b, 0.000000e+00
  %xor = xor i1 %acmp, %bcmp
  %result = select i1 %xor, float %a, float %b
  store float %result, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &vector_xor_i32
; HSAIL: xor_b32	{{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @vector_xor_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %in0, i32 addrspace(1)* %in1) {
  %a = load i32, i32 addrspace(1)* %in0
  %b = load i32, i32 addrspace(1)* %in1
  %result = xor i32 %a, %b
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &scalar_xor_i32
; HSAIL: xor_b32	{{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @scalar_xor_i32(i32 addrspace(1)* %out, i32 %a, i32 %b) {
  %result = xor i32 %a, %b
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &scalar_not_i32
; HSAIL: not_b32	{{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @scalar_not_i32(i32 addrspace(1)* %out, i32 %a) {
  %result = xor i32 %a, -1
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &vector_not_i32
; HSAIL: not_b32	{{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @vector_not_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %in0, i32 addrspace(1)* %in1) {
  %a = load i32, i32 addrspace(1)* %in0
  %b = load i32, i32 addrspace(1)* %in1
  %result = xor i32 %a, -1
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &vector_xor_i64
; HSAIL: xor_b64	{{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @vector_xor_i64(i64 addrspace(1)* %out, i64 addrspace(1)* %in0, i64 addrspace(1)* %in1) {
  %a = load i64, i64 addrspace(1)* %in0
  %b = load i64, i64 addrspace(1)* %in1
  %result = xor i64 %a, %b
  store i64 %result, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &scalar_xor_i64
; HSAIL: xor_b64	{{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @scalar_xor_i64(i64 addrspace(1)* %out, i64 %a, i64 %b) {
  %result = xor i64 %a, %b
  store i64 %result, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &scalar_not_i64
; HSAIL: not_b64	{{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @scalar_not_i64(i64 addrspace(1)* %out, i64 %a) {
  %result = xor i64 %a, -1
  store i64 %result, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &vector_not_i64
; HSAIL: not_b64	{{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @vector_not_i64(i64 addrspace(1)* %out, i64 addrspace(1)* %in0, i64 addrspace(1)* %in1) {
  %a = load i64, i64 addrspace(1)* %in0
  %b = load i64, i64 addrspace(1)* %in1
  %result = xor i64 %a, -1
  store i64 %result, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &xor_cf
; HSAIL: cmp_eq_b1_s64	{{\$c[0-9]+}}, {{\$d[0-9]+}}, 0;
; HSAIL-NEXT: cbr_b1 {{\$c[0-9]+}}, @BB11_1;
; HSAIL: br @BB11_3
; HSAIL: {{^@BB11_1:}}
; HSAIL: xor_b64	{{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: {{^@BB11_3:}}
; HSAIL:st_global_u64	{{\$d[0-9]+}}, [{{\$s[0-9]+}}];
; HSAIL: ret;
define void @xor_cf(i64 addrspace(1)* %out, i64 addrspace(1)* %in, i64 %a, i64 %b) {
entry:
  %0 = icmp eq i64 %a, 0
  br i1 %0, label %if, label %else

if:
  %1 = xor i64 %a, %b
  br label %endif

else:
  %2 = load i64, i64 addrspace(1)* %in
  br label %endif

endif:
  %3 = phi i64 [%1, %if], [%2, %else]
  store i64 %3, i64 addrspace(1)* %out
  ret void
}
