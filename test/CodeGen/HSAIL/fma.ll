; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare float @llvm.fma.f32(float, float, float) #0
declare <2 x float> @llvm.fma.v2f32(<2 x float>, <2 x float>, <2 x float>) #0
declare <4 x float> @llvm.fma.v4f32(<4 x float>, <4 x float>, <4 x float>) #0

declare double @llvm.fma.f64(double, double, double) #0
declare <2 x double> @llvm.fma.v2f64(<2 x double>, <2 x double>, <2 x double>) #0
declare <4 x double> @llvm.fma.v4f64(<4 x double>, <4 x double>, <4 x double>) #0

declare float @llvm.HSAIL.fma.f32(float, float, float) #0
declare double @llvm.HSAIL.fma.f64(double, double, double) #0


; HSAIL-LABEL: {{^}}prog function &fma_f32(
; HSAIL: fma_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @fma_f32(float addrspace(1)* %out, float addrspace(1)* %in1,
                     float addrspace(1)* %in2, float addrspace(1)* %in3) #1 {
  %r0 = load float, float addrspace(1)* %in1
  %r1 = load float, float addrspace(1)* %in2
  %r2 = load float, float addrspace(1)* %in3
  %r3 = tail call float @llvm.fma.f32(float %r0, float %r1, float %r2) #0
  store float %r3, float addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fma_v2f32(
; HSAIL: fma_ftz_f32
; HSAIL: fma_ftz_f32
define void @fma_v2f32(<2 x float> addrspace(1)* %out, <2 x float> addrspace(1)* %in1,
                       <2 x float> addrspace(1)* %in2, <2 x float> addrspace(1)* %in3) #1 {
  %r0 = load <2 x float>, <2 x float> addrspace(1)* %in1
  %r1 = load <2 x float>, <2 x float> addrspace(1)* %in2
  %r2 = load <2 x float>, <2 x float> addrspace(1)* %in3
  %r3 = tail call <2 x float> @llvm.fma.v2f32(<2 x float> %r0, <2 x float> %r1, <2 x float> %r2) #0
  store <2 x float> %r3, <2 x float> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fma_v4f32(
; HSAIL: fma_ftz_f32
; HSAIL: fma_ftz_f32
; HSAIL: fma_ftz_f32
; HSAIL: fma_ftz_f32
define void @fma_v4f32(<4 x float> addrspace(1)* %out, <4 x float> addrspace(1)* %in1,
                       <4 x float> addrspace(1)* %in2, <4 x float> addrspace(1)* %in3) #1 {
  %r0 = load <4 x float>, <4 x float> addrspace(1)* %in1
  %r1 = load <4 x float>, <4 x float> addrspace(1)* %in2
  %r2 = load <4 x float>, <4 x float> addrspace(1)* %in3
  %r3 = tail call <4 x float> @llvm.fma.v4f32(<4 x float> %r0, <4 x float> %r1, <4 x float> %r2) #0
  store <4 x float> %r3, <4 x float> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fma_f64(
; SI: fma_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @fma_f64(double addrspace(1)* %out, double addrspace(1)* %in1,
                     double addrspace(1)* %in2, double addrspace(1)* %in3) #1 {
   %r0 = load double, double addrspace(1)* %in1
   %r1 = load double, double addrspace(1)* %in2
   %r2 = load double, double addrspace(1)* %in3
   %r3 = tail call double @llvm.fma.f64(double %r0, double %r1, double %r2) #0
   store double %r3, double addrspace(1)* %out
   ret void
}

; FUNC-LABEL: {{^}}prog function &fma_v2f64(
; SI: fma_f64
; SI: fma_f64
define void @fma_v2f64(<2 x double> addrspace(1)* %out, <2 x double> addrspace(1)* %in1,
                       <2 x double> addrspace(1)* %in2, <2 x double> addrspace(1)* %in3) #1 {
   %r0 = load <2 x double>, <2 x double> addrspace(1)* %in1
   %r1 = load <2 x double>, <2 x double> addrspace(1)* %in2
   %r2 = load <2 x double>, <2 x double> addrspace(1)* %in3
   %r3 = tail call <2 x double> @llvm.fma.v2f64(<2 x double> %r0, <2 x double> %r1, <2 x double> %r2) #0
   store <2 x double> %r3, <2 x double> addrspace(1)* %out
   ret void
}

; FUNC-LABEL: {{^}}prog function &fma_v4f64(
; SI: fma_f64
; SI: fma_f64
; SI: fma_f64
; SI: fma_f64
define void @fma_v4f64(<4 x double> addrspace(1)* %out, <4 x double> addrspace(1)* %in1,
                       <4 x double> addrspace(1)* %in2, <4 x double> addrspace(1)* %in3) #1 {
   %r0 = load <4 x double>, <4 x double> addrspace(1)* %in1
   %r1 = load <4 x double>, <4 x double> addrspace(1)* %in2
   %r2 = load <4 x double>, <4 x double> addrspace(1)* %in3
   %r3 = tail call <4 x double> @llvm.fma.v4f64(<4 x double> %r0, <4 x double> %r1, <4 x double> %r2) #0
   store <4 x double> %r3, <4 x double> addrspace(1)* %out
   ret void
}

; HSAIL-LABEL: {{^}}prog function &legacy_hsail_fma_f32(
; HSAIL: fma_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @legacy_hsail_fma_f32(float addrspace(1)* %out, float addrspace(1)* %in1,
                                  float addrspace(1)* %in2, float addrspace(1)* %in3) #1 {
  %r0 = load float, float addrspace(1)* %in1
  %r1 = load float, float addrspace(1)* %in2
  %r2 = load float, float addrspace(1)* %in3
  %r3 = tail call float @llvm.HSAIL.fma.f32(float %r0, float %r1, float %r2) #0
  store float %r3, float addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &legacy_hsail_fma_f64(
; HSAIL: fma_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @legacy_hsail_fma_f64(double addrspace(1)* %out, double addrspace(1)* %in1,
                                  double addrspace(1)* %in2, double addrspace(1)* %in3) #1 {
  %r0 = load double, double addrspace(1)* %in1
  %r1 = load double, double addrspace(1)* %in2
  %r2 = load double, double addrspace(1)* %in3
  %r3 = tail call double @llvm.HSAIL.fma.f64(double %r0, double %r1, double %r2) #0
  store double %r3, double addrspace(1)* %out
  ret void
}

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
