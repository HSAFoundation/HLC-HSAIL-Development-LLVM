; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare float @fabsf(float) readnone
declare float @llvm.fabs.f32(float) readnone
declare <2 x float> @llvm.fabs.v2f32(<2 x float>) readnone
declare <4 x float> @llvm.fabs.v4f32(<4 x float>) readnone

declare double @fabs(double) readnone
declare double @llvm.fabs.f64(double) readnone
declare <2 x double> @llvm.fabs.v2f64(<2 x double>) readnone
declare <4 x double> @llvm.fabs.v4f64(<4 x double>) readnone

declare float @llvm.HSAIL.abs.f32(float) readnone
declare double @llvm.HSAIL.abs.f64(double) readnone


; DAGCombiner will transform:
; (fabs (f32 bitcast (i32 a))) => (f32 bitcast (and (i32 a), 0x7FFFFFFF))
; unless isFabsFree returns true

; HSAIL-LABEL: {{^}}prog function &fabs_fn_free(
; HSAIL: abs_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @fabs_fn_free(float addrspace(1)* %out, i32 %in) {
  %bc= bitcast i32 %in to float
  %fabs = call float @fabsf(float %bc)
  store float %fabs, float addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fabs_free(
; HSAIL: abs_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @fabs_free(float addrspace(1)* %out, i32 %in) {
  %bc= bitcast i32 %in to float
  %fabs = call float @llvm.fabs.f32(float %bc)
  store float %fabs, float addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fabs_f32(
; HSAIL: abs_f32
define void @fabs_f32(float addrspace(1)* %out, float %in) {
  %fabs = call float @llvm.fabs.f32(float %in)
  store float %fabs, float addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fabs_v2f32(
; HSAIL: abs_f32
; HSAIL: abs_f32
define void @fabs_v2f32(<2 x float> addrspace(1)* %out, <2 x float> %in) {
  %fabs = call <2 x float> @llvm.fabs.v2f32(<2 x float> %in)
  store <2 x float> %fabs, <2 x float> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fabs_v4f32(
; HSAIL: abs_f32
; HSAIL: abs_f32
; HSAIL: abs_f32
; HSAIL: abs_f32
define void @fabs_v4f32(<4 x float> addrspace(1)* %out, <4 x float> %in) {
  %fabs = call <4 x float> @llvm.fabs.v4f32(<4 x float> %in)
  store <4 x float> %fabs, <4 x float> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fabs_fn_fold(
; HSAIL: abs_f32
; HSAIL: mul_ftz_f32
define void @fabs_fn_fold(float addrspace(1)* %out, float %in0, float %in1) {
  %fabs = call float @fabsf(float %in0)
  %fmul = fmul float %fabs, %in1
  store float %fmul, float addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fabs_fold(
; HSAIL: abs_f32
; HSAIL: mul_ftz_f32
define void @fabs_fold(float addrspace(1)* %out, float %in0, float %in1) {
  %fabs = call float @llvm.fabs.f32(float %in0)
  %fmul = fmul float %fabs, %in1
  store float %fmul, float addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fabs_f64(
; HSAIL: abs_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @fabs_f64(double addrspace(1)* %out, double %in) {
  %fabs = call double @llvm.fabs.f64(double %in)
  store double %fabs, double addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fabs_v2f64(
; HSAIL: abs_f64
; HSAIL: abs_f64
define void @fabs_v2f64(<2 x double> addrspace(1)* %out, <2 x double> %in) {
  %fabs = call <2 x double> @llvm.fabs.v2f64(<2 x double> %in)
  store <2 x double> %fabs, <2 x double> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fabs_v4f64(
; HSAIL: abs_f64
; HSAIL: abs_f64
; HSAIL: abs_f64
; HSAIL: abs_f64
define void @fabs_v4f64(<4 x double> addrspace(1)* %out, <4 x double> %in) {
  %fabs = call <4 x double> @llvm.fabs.v4f64(<4 x double> %in)
  store <4 x double> %fabs, <4 x double> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fabs_fold_f64(
; HSAIL: abs_f64
; HSAIL: mul_f64
define void @fabs_fold_f64(double addrspace(1)* %out, double %in0, double %in1) {
  %fabs = call double @llvm.fabs.f64(double %in0)
  %fmul = fmul double %fabs, %in1
  store double %fmul, double addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fabs_fn_fold_f64(
; HSAIL: abs_f64
; HSAIL: mul_f64
define void @fabs_fn_fold_f64(double addrspace(1)* %out, double %in0, double %in1) {
  %fabs = call double @fabs(double %in0)
  %fmul = fmul double %fabs, %in1
  store double %fmul, double addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fabs_free_f64(
; HSAIL: abs_f64
define void @fabs_free_f64(double addrspace(1)* %out, i64 %in) {
  %bc= bitcast i64 %in to double
  %fabs = call double @llvm.fabs.f64(double %bc)
  store double %fabs, double addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fabs_fn_free_f64(
; HSAIL: abs_f64
define void @fabs_fn_free_f64(double addrspace(1)* %out, i64 %in) {
  %bc= bitcast i64 %in to double
  %fabs = call double @fabs(double %bc)
  store double %fabs, double addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &legacy_hsail_abs_f32(
; HSAIL: abs_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @legacy_hsail_abs_f32(float addrspace(1)* %out, float %in) {
  %fabs = call float @llvm.HSAIL.abs.f32(float %in)
  store float %fabs, float addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &legacy_hsail_abs_f64(
; HSAIL: abs_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @legacy_hsail_abs_f64(double addrspace(1)* %out, double %in) {
  %fabs = call double @llvm.HSAIL.abs.f64(double %in)
  store double %fabs, double addrspace(1)* %out
  ret void
}
