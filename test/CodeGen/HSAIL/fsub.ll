; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &v_fsub_f32(
; HSAIL: sub_ftz_f32 {{\$s[[0-9]+}}, {{\$s[[0-9]+}}, {{\$s[[0-9]+}};
define void @v_fsub_f32(float addrspace(1)* %out, float addrspace(1)* %in) {
  %b_ptr = getelementptr float addrspace(1)* %in, i32 1
  %a = load float addrspace(1)* %in, align 4
  %b = load float addrspace(1)* %b_ptr, align 4
  %result = fsub float %a, %b
  store float %result, float addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &s_fsub_f32(
; HSAIL: sub_ftz_f32 {{\$s[[0-9]+}}, {{\$s[0-9]+}}, {{\$s[[0-9]+}};
define void @s_fsub_f32(float addrspace(1)* %out, float %a, float %b) {
  %sub = fsub float %a, %b
  store float %sub, float addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fsub_v2f32(
; HSAIL: sub_ftz_f32 {{\$s[[0-9]+}}, {{\$s[[0-9]+}}, {{\$s[[0-9]+}};
; HSAIL: sub_ftz_f32 {{\$s[[0-9]+}}, {{\$s[[0-9]+}}, {{\$s[[0-9]+}};
define void @fsub_v2f32(<2 x float> addrspace(1)* %out, <2 x float> %a, <2 x float> %b) {
  %sub = fsub <2 x float> %a, %b
  store <2 x float> %sub, <2 x float> addrspace(1)* %out, align 8
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fsub_v4f32(
; HSAIL: sub_ftz_f32 {{\$s[[0-9]+}}, {{\$s[[0-9]+}}, {{\$s[[0-9]+}};
; HSAIL: sub_ftz_f32 {{\$s[[0-9]+}}, {{\$s[[0-9]+}}, {{\$s[[0-9]+}};
; HSAIL: sub_ftz_f32 {{\$s[[0-9]+}}, {{\$s[[0-9]+}}, {{\$s[[0-9]+}};
; HSAIL: sub_ftz_f32 {{\$s[[0-9]+}}, {{\$s[[0-9]+}}, {{\$s[[0-9]+}};
define void @fsub_v4f32(<4 x float> addrspace(1)* %out, <4 x float> addrspace(1)* %in) {
  %b_ptr = getelementptr <4 x float> addrspace(1)* %in, i32 1
  %a = load <4 x float> addrspace(1)* %in, align 16
  %b = load <4 x float> addrspace(1)* %b_ptr, align 16
  %result = fsub <4 x float> %a, %b
  store <4 x float> %result, <4 x float> addrspace(1)* %out, align 16
  ret void
}

; HSAIL-LABEL: {{^}}prog function &s_fsub_v4f32(
; HSAIL: sub_ftz_f32 {{\$s[[0-9]+}}, {{\$s[[0-9]+}}, {{\$s[[0-9]+}};
; HSAIL: sub_ftz_f32 {{\$s[[0-9]+}}, {{\$s[[0-9]+}}, {{\$s[[0-9]+}};
; HSAIL: sub_ftz_f32 {{\$s[[0-9]+}}, {{\$s[[0-9]+}}, {{\$s[[0-9]+}};
; HSAIL: sub_ftz_f32 {{\$s[[0-9]+}}, {{\$s[[0-9]+}}, {{\$s[[0-9]+}};
define void @s_fsub_v4f32(<4 x float> addrspace(1)* %out, <4 x float> %a, <4 x float> %b) {
  %result = fsub <4 x float> %a, %b
  store <4 x float> %result, <4 x float> addrspace(1)* %out, align 16
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fsub_f64(
; HSAIL: sub_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}
define void @fsub_f64(double addrspace(1)* %out, double addrspace(1)* %in1,
                      double addrspace(1)* %in2) {
  %r0 = load double addrspace(1)* %in1
  %r1 = load double addrspace(1)* %in2
  %r2 = fsub double %r0, %r1
  store double %r2, double addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &s_fsub_f64(
; HSAIL: sub_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}
define void @s_fsub_f64(double addrspace(1)* %out, double %a, double %b) {
  %sub = fsub double %a, %b
  store double %sub, double addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &s_fsub_imm_f64(
; HSAIL: sub_f64 {{\$d[0-9]+}}, 0D4010000000000000, {{\$d[0-9]+}}
define void @s_fsub_imm_f64(double addrspace(1)* %out, double %a, double %b) {
  %sub = fsub double 4.0, %a
  store double %sub, double addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &s_fsub_imm_inf64(
; HSAIL: add_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 0Dc010000000000000
define void @s_fsub_imm_inf64(double addrspace(1)* %out, double %a, double %b) {
  %sub = fsub double %a, 4.0
  store double %sub, double addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &s_fsub_self_f64(
; HSAIL: sub_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}
define void @s_fsub_self_f64(double addrspace(1)* %out, double %a) {
  %sub = fsub double %a, %a
  store double %sub, double addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fsub_v2f64(
; HSAIL: sub_f64
; HSAIL: sub_f64
define void @fsub_v2f64(<2 x double> addrspace(1)* %out, <2 x double> %a, <2 x double> %b) {
  %sub = fsub <2 x double> %a, %b
  store <2 x double> %sub, <2 x double> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fsub_v4f64(
; HSAIL: sub_f64
; HSAIL: sub_f64
; HSAIL: sub_f64
; HSAIL: sub_f64
define void @fsub_v4f64(<4 x double> addrspace(1)* %out, <4 x double> addrspace(1)* %in) {
  %b_ptr = getelementptr <4 x double> addrspace(1)* %in, i32 1
  %a = load <4 x double> addrspace(1)* %in
  %b = load <4 x double> addrspace(1)* %b_ptr
  %result = fsub <4 x double> %a, %b
  store <4 x double> %result, <4 x double> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &s_fsub_v4f64(
; HSAIL: sub_f64
; HSAIL: sub_f64
; HSAIL: sub_f64
; HSAIL: sub_f64
define void @s_fsub_v4f64(<4 x double> addrspace(1)* %out, <4 x double> %a, <4 x double> %b) {
  %result = fsub <4 x double> %a, %b
  store <4 x double> %result, <4 x double> addrspace(1)* %out, align 16
  ret void
}
