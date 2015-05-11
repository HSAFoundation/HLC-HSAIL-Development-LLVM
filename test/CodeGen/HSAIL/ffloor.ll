; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &floor_f32(
; HSAIL: floor_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define void @floor_f32(float addrspace(1)* %out, float %in) {
  %tmp = call float @llvm.floor.f32(float %in) #0
  store float %tmp, float addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &floor_v2f32(
; HSAIL: floor_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
; HSAIL: floor_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define void @floor_v2f32(<2 x float> addrspace(1)* %out, <2 x float> %in) {
  %tmp = call <2 x float> @llvm.floor.v2f32(<2 x float> %in) #0
  store <2 x float> %tmp, <2 x float> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &floor_v4f32(
; HSAIL: floor_ftz_f32
; HSAIL: floor_ftz_f32
; HSAIL: floor_ftz_f32
; HSAIL: floor_ftz_f32
define void @floor_v4f32(<4 x float> addrspace(1)* %out, <4 x float> %in) {
  %tmp = call <4 x float> @llvm.floor.v4f32(<4 x float> %in) #0
  store <4 x float> %tmp, <4 x float> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &ffloor_f64(
; HSAIL: floor_f64
define void @ffloor_f64(double addrspace(1)* %out, double %x) {
  %y = call double @llvm.floor.f64(double %x) #0
  store double %y, double addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &ffloor_v2f64(
; HSAIL: floor_f64
; HSAIL: floor_f64
define void @ffloor_v2f64(<2 x double> addrspace(1)* %out, <2 x double> %x) {
  %y = call <2 x double> @llvm.floor.v2f64(<2 x double> %x) #0
  store <2 x double> %y, <2 x double> addrspace(1)* %out
  ret void
}

; FIXME-FUNC-LABEL: {{^}}prog function &ffloor_v3f64(
; HSAIL: floor_f64
; HSAIL: floor_f64
; HSAIL: floor_f64
define void @ffloor_v3f64(<3 x double> addrspace(1)* %out, <3 x double> %x) {
  %y = call <3 x double> @llvm.floor.v3f64(<3 x double> %x) #0
  store <3 x double> %y, <3 x double> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &ffloor_v4f64(
; HSAIL: floor_f64
; HSAIL: floor_f64
; HSAIL: floor_f64
; HSAIL: floor_f64
define void @ffloor_v4f64(<4 x double> addrspace(1)* %out, <4 x double> %x) {
  %y = call <4 x double> @llvm.floor.v4f64(<4 x double> %x) #0
  store <4 x double> %y, <4 x double> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &ffloor_v8f64(
; HSAIL: floor_f64
; HSAIL: floor_f64
; HSAIL: floor_f64
; HSAIL: floor_f64
; HSAIL: floor_f64
; HSAIL: floor_f64
; HSAIL: floor_f64
; HSAIL: floor_f64
define void @ffloor_v8f64(<8 x double> addrspace(1)* %out, <8 x double> %x) {
  %y = call <8 x double> @llvm.floor.v8f64(<8 x double> %x) #0
  store <8 x double> %y, <8 x double> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &ffloor_v16f64(
; HSAIL: floor_f64
; HSAIL: floor_f64
; HSAIL: floor_f64
; HSAIL: floor_f64
; HSAIL: floor_f64
; HSAIL: floor_f64
; HSAIL: floor_f64
; HSAIL: floor_f64
; HSAIL: floor_f64
; HSAIL: floor_f64
; HSAIL: floor_f64
; HSAIL: floor_f64
; HSAIL: floor_f64
; HSAIL: floor_f64
; HSAIL: floor_f64
; HSAIL: floor_f64
define void @ffloor_v16f64(<16 x double> addrspace(1)* %out, <16 x double> %x) {
  %y = call <16 x double> @llvm.floor.v16f64(<16 x double> %x) #0
  store <16 x double> %y, <16 x double> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &legacy_hsail_floor_f32(
; HSAIL: floor_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define void @legacy_hsail_floor_f32(float addrspace(1)* %out, float %in) #1 {
  %tmp = call float @llvm.HSAIL.floor.f32(float %in) #0
  store float %tmp, float addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &legacy_hsail_floor_f64(
; HSAIL: floor_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
define void @legacy_hsail_floor_f64(double addrspace(1)* %out, double %in) #1 {
  %tmp = call double @llvm.HSAIL.floor.f64(double %in) #0
  store double %tmp, double addrspace(1)* %out
  ret void
}

declare float @llvm.floor.f32(float) #0
declare <2 x float> @llvm.floor.v2f32(<2 x float>) #0
declare <4 x float> @llvm.floor.v4f32(<4 x float>) #0

declare double @llvm.floor.f64(double) #0
declare <2 x double> @llvm.floor.v2f64(<2 x double>) #0
declare <3 x double> @llvm.floor.v3f64(<3 x double>) #0
declare <4 x double> @llvm.floor.v4f64(<4 x double>) #0
declare <8 x double> @llvm.floor.v8f64(<8 x double>) #0
declare <16 x double> @llvm.floor.v16f64(<16 x double>) #0

declare float @llvm.HSAIL.floor.f32(float) #0
declare double @llvm.HSAIL.floor.f64(double) #0

attributes #0 = { nounwind readnone }
