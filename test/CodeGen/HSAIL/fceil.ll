; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &fceil_ftz_f32(
; HSAIL: ceil_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define void @fceil_ftz_f32(float addrspace(1)* %out, float %x) {
  %y = call float @llvm.ceil.f32(float %x) #0
  store float %y, float addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fceil_v2f32(
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
define void @fceil_v2f32(<2 x float> addrspace(1)* %out, <2 x float> %x) {
  %y = call <2 x float> @llvm.ceil.v2f32(<2 x float> %x) #0
  store <2 x float> %y, <2 x float> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fceil_v3f32(
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
define void @fceil_v3f32(<3 x float> addrspace(1)* %out, <3 x float> %x) {
  %y = call <3 x float> @llvm.ceil.v3f32(<3 x float> %x) #0
  store <3 x float> %y, <3 x float> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fceil_v4f32(
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
define void @fceil_v4f32(<4 x float> addrspace(1)* %out, <4 x float> %x) {
  %y = call <4 x float> @llvm.ceil.v4f32(<4 x float> %x) #0
  store <4 x float> %y, <4 x float> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fceil_v8f32(
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
define void @fceil_v8f32(<8 x float> addrspace(1)* %out, <8 x float> %x) {
  %y = call <8 x float> @llvm.ceil.v8f32(<8 x float> %x) #0
  store <8 x float> %y, <8 x float> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fceil_v16f32(
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
; HSAIL: ceil_ftz_f32
define void @fceil_v16f32(<16 x float> addrspace(1)* %out, <16 x float> %x) {
  %y = call <16 x float> @llvm.ceil.v16f32(<16 x float> %x) #0
  store <16 x float> %y, <16 x float> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fceil_f64(
; HSAIL: ceil_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
define void @fceil_f64(double addrspace(1)* %out, double %x) {
  %y = call double @llvm.ceil.f64(double %x) #0
  store double %y, double addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fceil_v2f64(
; HSAIL: ceil_f64
; HSAIL: ceil_f64
define void @fceil_v2f64(<2 x double> addrspace(1)* %out, <2 x double> %x) {
  %y = call <2 x double> @llvm.ceil.v2f64(<2 x double> %x) #0
  store <2 x double> %y, <2 x double> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fceil_v3f64(
; HSAIL: ceil_f64
; HSAIL: ceil_f64
; HSAIL: ceil_f64
define void @fceil_v3f64(<3 x double> addrspace(1)* %out, <3 x double> %x) {
  %y = call <3 x double> @llvm.ceil.v3f64(<3 x double> %x) #0
  store <3 x double> %y, <3 x double> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fceil_v4f64(
; HSAIL: ceil_f64
; HSAIL: ceil_f64
; HSAIL: ceil_f64
; HSAIL: ceil_f64
define void @fceil_v4f64(<4 x double> addrspace(1)* %out, <4 x double> %x) {
  %y = call <4 x double> @llvm.ceil.v4f64(<4 x double> %x) #0
  store <4 x double> %y, <4 x double> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fceil_v8f64(
; HSAIL: ceil_f64
; HSAIL: ceil_f64
; HSAIL: ceil_f64
; HSAIL: ceil_f64
; HSAIL: ceil_f64
; HSAIL: ceil_f64
; HSAIL: ceil_f64
; HSAIL: ceil_f64
define void @fceil_v8f64(<8 x double> addrspace(1)* %out, <8 x double> %x) {
  %y = call <8 x double> @llvm.ceil.v8f64(<8 x double> %x) #0
  store <8 x double> %y, <8 x double> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fceil_v16f64(
; HSAIL: ceil_f64
; HSAIL: ceil_f64
; HSAIL: ceil_f64
; HSAIL: ceil_f64
; HSAIL: ceil_f64
; HSAIL: ceil_f64
; HSAIL: ceil_f64
; HSAIL: ceil_f64
; HSAIL: ceil_f64
; HSAIL: ceil_f64
; HSAIL: ceil_f64
; HSAIL: ceil_f64
; HSAIL: ceil_f64
; HSAIL: ceil_f64
; HSAIL: ceil_f64
; HSAIL: ceil_f64
define void @fceil_v16f64(<16 x double> addrspace(1)* %out, <16 x double> %x) {
  %y = call <16 x double> @llvm.ceil.v16f64(<16 x double> %x) #0
  store <16 x double> %y, <16 x double> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &legacy_hsail_ceil_f32(
; HSAIL: ceil_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define void @legacy_hsail_ceil_f32(float addrspace(1)* %out, float %in) #1 {
  %tmp = call float @llvm.HSAIL.ceil.f32(float %in) #0
  store float %tmp, float addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &legacy_hsail_ceil_f64(
; HSAIL: ceil_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
define void @legacy_hsail_ceil_f64(double addrspace(1)* %out, double %in) #1 {
  %tmp = call double @llvm.HSAIL.ceil.f64(double %in) #0
  store double %tmp, double addrspace(1)* %out
  ret void
}

declare float @llvm.ceil.f32(float) #0
declare <2 x float> @llvm.ceil.v2f32(<2 x float>) #0
declare <3 x float> @llvm.ceil.v3f32(<3 x float>) #0
declare <4 x float> @llvm.ceil.v4f32(<4 x float>) #0
declare <8 x float> @llvm.ceil.v8f32(<8 x float>) #0
declare <16 x float> @llvm.ceil.v16f32(<16 x float>) #0

declare double @llvm.ceil.f64(double) #0
declare <2 x double> @llvm.ceil.v2f64(<2 x double>) #0
declare <3 x double> @llvm.ceil.v3f64(<3 x double>) #0
declare <4 x double> @llvm.ceil.v4f64(<4 x double>) #0
declare <8 x double> @llvm.ceil.v8f64(<8 x double>) #0
declare <16 x double> @llvm.ceil.v16f64(<16 x double>) #0

declare float @llvm.HSAIL.ceil.f32(float) #0
declare double @llvm.HSAIL.ceil.f64(double) #0

attributes #0 = { nounwind readnone }
