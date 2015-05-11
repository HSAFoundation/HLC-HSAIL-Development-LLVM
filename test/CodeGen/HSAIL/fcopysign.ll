; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare float @llvm.copysign.f32(float, float) #0
declare <2 x float> @llvm.copysign.v2f32(<2 x float>, <2 x float>) #0
declare <4 x float> @llvm.copysign.v4f32(<4 x float>, <4 x float>) #0

declare double @llvm.copysign.f64(double, double) #0
declare <2 x double> @llvm.copysign.v2f64(<2 x double>, <2 x double>) #0
declare <4 x double> @llvm.copysign.v4f64(<4 x double>, <4 x double>) #0

declare float @llvm.HSAIL.copysign.f32(float, float) #0
declare double @llvm.HSAIL.copysign.f64(double, double) #0


; HSAIL-LABEL: {{^}}prog function &test_copysign_f32(
; HSAIL: copysign_f32 [[RESULT:\$s[0-9]+]]
; HSAIL: st_global_align(4)_f32 [[RESULT]],
; HSAIL: ret;
define void @test_copysign_f32(float addrspace(1)* %out, float %mag, float %sign) #1 {
  %result = call float @llvm.copysign.f32(float %mag, float %sign) #0
  store float %result, float addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_copysign_v2f32(
; HSAIL: copysign_f32
; HSAIL: copysign_f32
define void @test_copysign_v2f32(<2 x float> addrspace(1)* %out, <2 x float> %mag, <2 x float> %sign) #1 {
  %result = call <2 x float> @llvm.copysign.v2f32(<2 x float> %mag, <2 x float> %sign) #0
  store <2 x float> %result, <2 x float> addrspace(1)* %out, align 8
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_copysign_v4f32(
; HSAIL: copysign_f32
; HSAIL: copysign_f32
; HSAIL: copysign_f32
; HSAIL: copysign_f32
define void @test_copysign_v4f32(<4 x float> addrspace(1)* %out, <4 x float> %mag, <4 x float> %sign) #1 {
  %result = call <4 x float> @llvm.copysign.v4f32(<4 x float> %mag, <4 x float> %sign) #0
  store <4 x float> %result, <4 x float> addrspace(1)* %out, align 16
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_copysign_f64(
; HSAIL: copysign_f64 [[RESULT:\$d[0-9]+]]
; HSAIL: st_global_align(8)_f64 [[RESULT]],
; HSAIL: ret;
define void @test_copysign_f64(double addrspace(1)* %out, double %mag, double %sign) #1 {
  %result = call double @llvm.copysign.f64(double %mag, double %sign) #0
  store double %result, double addrspace(1)* %out, align 8
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_copysign_v2f64(
; HSAIL: copysign_f64
; HSAIL: copysign_f64
define void @test_copysign_v2f64(<2 x double> addrspace(1)* %out, <2 x double> %mag, <2 x double> %sign) #1 {
  %result = call <2 x double> @llvm.copysign.v2f64(<2 x double> %mag, <2 x double> %sign) #0
  store <2 x double> %result, <2 x double> addrspace(1)* %out, align 8
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_copysign_v4f64(
; HSAIL: copysign_f64
; HSAIL: copysign_f64
; HSAIL: copysign_f64
; HSAIL: copysign_f64
define void @test_copysign_v4f64(<4 x double> addrspace(1)* %out, <4 x double> %mag, <4 x double> %sign) #1 {
  %result = call <4 x double> @llvm.copysign.v4f64(<4 x double> %mag, <4 x double> %sign) #0
  store <4 x double> %result, <4 x double> addrspace(1)* %out, align 8
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_hsail_copysign_f32(
; HSAIL: copysign_f32 [[RESULT:\$s[0-9]+]]
; HSAIL: st_global_align(4)_f32 [[RESULT]],
; HSAIL: ret;
define void @test_legacy_hsail_copysign_f32(float addrspace(1)* %out, float %mag, float %sign) #1 {
  %result = call float @llvm.HSAIL.copysign.f32(float %mag, float %sign) #0
  store float %result, float addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_hsail_copysign_f64(
; HSAIL: copysign_f64 [[RESULT:\$d[0-9]+]]
; HSAIL: st_global_align(8)_f64 [[RESULT]],
; HSAIL: ret;
define void @test_legacy_hsail_copysign_f64(double addrspace(1)* %out, double %mag, double %sign) #1 {
  %result = call double @llvm.HSAIL.copysign.f64(double %mag, double %sign) #0
  store double %result, double addrspace(1)* %out, align 8
  ret void
}

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
