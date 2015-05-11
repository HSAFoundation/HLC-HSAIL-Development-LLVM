; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &rint_f32(
; HSAIL: rint_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define void @rint_f32(float addrspace(1)* %out, float %in) #1 {
  %tmp = call float @llvm.rint.f32(float %in) #0
  store float %tmp, float addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &rint_v2f32(
; HSAIL: rint_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
; HSAIL: rint_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define void @rint_v2f32(<2 x float> addrspace(1)* %out, <2 x float> %in) #1 {
  %tmp = call <2 x float> @llvm.rint.v2f32(<2 x float> %in) #0
  store <2 x float> %tmp, <2 x float> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &rint_v4f32(
; HSAIL: rint_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
; HSAIL: rint_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
; HSAIL: rint_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
; HSAIL: rint_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define void @rint_v4f32(<4 x float> addrspace(1)* %out, <4 x float> %in) #1 {
  %tmp = call <4 x float> @llvm.rint.v4f32(<4 x float> %in) #0
  store <4 x float> %tmp, <4 x float> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &rint_f64(
; HSAIL: rint_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
define void @rint_f64(double addrspace(1)* %out, double %in) #1 {
  %tmp = call double @llvm.rint.f64(double %in)
  store double %tmp, double addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &rint_v2f64(
; HSAIL: rint_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
; HSAIL: rint_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
define void @rint_v2f64(<2 x double> addrspace(1)* %out, <2 x double> %in) #1 {
  %tmp = call <2 x double> @llvm.rint.v2f64(<2 x double> %in)
  store <2 x double> %tmp, <2 x double> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &rint_v4f64(
; HSAIL: rint_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
; HSAIL: rint_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
; HSAIL: rint_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
; HSAIL: rint_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
define void @rint_v4f64(<4 x double> addrspace(1)* %out, <4 x double> %in) #1 {
  %tmp = call <4 x double> @llvm.rint.v4f64(<4 x double> %in)
  store <4 x double> %tmp, <4 x double> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &legacy_hsail_rnd_f32(
; HSAIL: rint_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define void @legacy_hsail_rnd_f32(float addrspace(1)* %out, float %in) #1 {
  %tmp = call float @llvm.HSAIL.rnd.f32(float %in) #0
  store float %tmp, float addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &legacy_hsail_rnd_f64(
; HSAIL: rint_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
define void @legacy_hsail_rnd_f64(double addrspace(1)* %out, double %in) #1 {
  %tmp = call double @llvm.HSAIL.rnd.f64(double %in) #0
  store double %tmp, double addrspace(1)* %out
  ret void
}

declare float @llvm.HSAIL.rnd.f32(float) #0
declare double @llvm.HSAIL.rnd.f64(double) #0

declare float @llvm.rint.f32(float) #0
declare <2 x float> @llvm.rint.v2f32(<2 x float>) #0
declare <4 x float> @llvm.rint.v4f32(<4 x float>) #0

declare double @llvm.rint.f64(double) #0
declare <2 x double> @llvm.rint.v2f64(<2 x double>) #0
declare <4 x double> @llvm.rint.v4f64(<4 x double>) #0

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
