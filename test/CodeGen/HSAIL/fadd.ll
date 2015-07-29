; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck %s -check-prefix=HSAIL -check-prefix=FUNC

; FUNC-LABEL: {{^}}prog function &fadd_f32
; HSAIL: add_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @fadd_f32(float addrspace(1)* %out, float %a, float %b) {
   %add = fadd float %a, %b
   store float %add, float addrspace(1)* %out, align 4
   ret void
}

; FUNC-LABEL: {{^}}prog function &fadd_v2f32
; HSAIL: add_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: add_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @fadd_v2f32(<2 x float> addrspace(1)* %out, <2 x float> %a, <2 x float> %b) {
  %add = fadd <2 x float> %a, %b
  store <2 x float> %add, <2 x float> addrspace(1)* %out, align 8
  ret void
}

; FUNC-LABEL: {{^}}prog function &fadd_v4f32
; HSAIL: add_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: add_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: add_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: add_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @fadd_v4f32(<4 x float> addrspace(1)* %out, <4 x float> addrspace(1)* %in) {
  %b_ptr = getelementptr <4 x float> addrspace(1)* %in, i32 1
  %a = load <4 x float> addrspace(1)* %in, align 16
  %b = load <4 x float> addrspace(1)* %b_ptr, align 16
  %result = fadd <4 x float> %a, %b
  store <4 x float> %result, <4 x float> addrspace(1)* %out, align 16
  ret void
}

; FUNC-LABEL: {{^}}prog function &fadd_v8f32
; HSAIL: add_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: add_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: add_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: add_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: add_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: add_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: add_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: add_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @fadd_v8f32(<8 x float> addrspace(1)* %out, <8 x float> %a, <8 x float> %b) {
  %add = fadd <8 x float> %a, %b
  store <8 x float> %add, <8 x float> addrspace(1)* %out, align 32
  ret void
}

; FUNC-LABEL: {{^}}prog function &fadd_f64
; HSAIL: add_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @fadd_f64(double addrspace(1)* %out, double addrspace(1)* %in1,
                      double addrspace(1)* %in2) {
  %r0 = load double addrspace(1)* %in1
  %r1 = load double addrspace(1)* %in2
  %r2 = fadd double %r0, %r1
  store double %r2, double addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fadd_v2f64
; HSAIL: add_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: add_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @fadd_v2f64(<2 x double> addrspace(1)* %out, <2 x double> %a, <2 x double> %b) {
  %add = fadd <2 x double> %a, %b
  store <2 x double> %add, <2 x double> addrspace(1)* %out, align 8
  ret void
}

; FUNC-LABEL: {{^}}prog function &fadd_v4f64
; HSAIL: add_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: add_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: add_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: add_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @fadd_v4f64(<4 x double> addrspace(1)* %out, <4 x double> addrspace(1)* %in) {
  %b_ptr = getelementptr <4 x double> addrspace(1)* %in, i32 1
  %a = load <4 x double> addrspace(1)* %in, align 16
  %b = load <4 x double> addrspace(1)* %b_ptr, align 16
  %result = fadd <4 x double> %a, %b
  store <4 x double> %result, <4 x double> addrspace(1)* %out, align 16
  ret void
}

; FUNC-LABEL: {{^}}prog function &fadd_v8f64
; HSAIL: add_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: add_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: add_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: add_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: add_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: add_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: add_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: add_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @fadd_v8f64(<8 x double> addrspace(1)* %out, <8 x double> %a, <8 x double> %b) {
  %add = fadd <8 x double> %a, %b
  store <8 x double> %add, <8 x double> addrspace(1)* %out, align 32
  ret void
}

; FUNC-LABEL: {{^}}prog function &fadd_f32_r_i
; HSAIL: add_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 0F44800000;
define void @fadd_f32_r_i(float addrspace(1)* %out, float %a, float %b) {
   %add = fadd float %a, 1024.0
   store float %add, float addrspace(1)* %out, align 4
   ret void
}

; FUNC-LABEL: {{^}}prog function &fadd_f64_r_i
; HSAIL: add_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 0D4090000000000000;
define void @fadd_f64_r_i(double addrspace(1)* %out, double %a, double %b) {
   %add = fadd double %a, 1024.0
   store double %add, double addrspace(1)* %out, align 4
   ret void
}
