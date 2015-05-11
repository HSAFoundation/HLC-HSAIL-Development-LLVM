; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &fneg_f32
; HSAIL: neg_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @fneg_f32(float addrspace(1)* %out, float %in) {
  %fneg = fsub float -0.000000e+00, %in
  store float %fneg, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fneg_v2f32
; HSAIL: neg_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: neg_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};

define void @fneg_v2f32(<2 x float> addrspace(1)* nocapture %out, <2 x float> %in) {
  %fneg = fsub <2 x float> <float -0.000000e+00, float -0.000000e+00>, %in
  store <2 x float> %fneg, <2 x float> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fneg_v4f32
; HSAIL: neg_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: neg_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: neg_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: neg_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @fneg_v4f32(<4 x float> addrspace(1)* nocapture %out, <4 x float> %in) {
  %fneg = fsub <4 x float> <float -0.000000e+00, float -0.000000e+00, float -0.000000e+00, float -0.000000e+00>, %in
  store <4 x float> %fneg, <4 x float> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fneg_free_f32
; HSAIL: sub_ftz_f32 {{\$s[0-9]+}}, 0F00000000, {{\$s[0-9]+}};
define void @fneg_free_f32(float addrspace(1)* %out, i32 %in) {
  %bc = bitcast i32 %in to float
  %fsub = fsub float 0.0, %bc
  store float %fsub, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fneg_fold_f32
; HSAIL: neg_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: mul_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @fneg_fold_f32(float addrspace(1)* %out, float %in) {
  %fsub = fsub float -0.0, %in
  %fmul = fmul float %fsub, %in
  store float %fmul, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fneg_f64
; HSAIL: neg_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @fneg_f64(double addrspace(1)* %out, double %in) {
  %fneg = fsub double -0.000000e+00, %in
  store double %fneg, double addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fneg_v2f64
; HSAIL: neg_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: neg_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @fneg_v2f64(<2 x double> addrspace(1)* nocapture %out, <2 x double> %in) {
  %fneg = fsub <2 x double> <double -0.000000e+00, double -0.000000e+00>, %in
  store <2 x double> %fneg, <2 x double> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fneg_v4f64
; HSAIL: neg_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: neg_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: neg_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: neg_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @fneg_v4f64(<4 x double> addrspace(1)* nocapture %out, <4 x double> %in) {
  %fneg = fsub <4 x double> <double -0.000000e+00, double -0.000000e+00, double -0.000000e+00, double -0.000000e+00>, %in
  store <4 x double> %fneg, <4 x double> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fneg_free_f64
; HSAIL: sub_f64 {{\$d[0-9]+}}, 0D0000000000000000, {{\$d[0-9]+}};
define void @fneg_free_f64(double addrspace(1)* %out, i64 %in) {
  %bc = bitcast i64 %in to double
  %fsub = fsub double 0.0, %bc
  store double %fsub, double addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fneg_fold_f64
; HSAIL: neg_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: mul_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @fneg_fold_f64(double addrspace(1)* %out, double %in) {
  %fsub = fsub double -0.0, %in
  %fmul = fmul double %fsub, %in
  store double %fmul, double addrspace(1)* %out
  ret void
}
