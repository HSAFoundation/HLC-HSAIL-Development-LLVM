; RUN: llc -march=hsail -mattr=+gcn -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare float @llvm.maxnum.f32(float, float) #0
declare <2 x float> @llvm.maxnum.v2f32(<2 x float>, <2 x float>) #0
declare <4 x float> @llvm.maxnum.v4f32(<4 x float>, <4 x float>) #0
declare <8 x float> @llvm.maxnum.v8f32(<8 x float>, <8 x float>) #0
declare <16 x float> @llvm.maxnum.v16f32(<16 x float>, <16 x float>) #0

declare double @llvm.maxnum.f64(double, double) #0
declare <2 x double> @llvm.maxnum.v2f64(<2 x double>, <2 x double>) #0
declare <4 x double> @llvm.maxnum.v4f64(<4 x double>, <4 x double>) #0
declare <8 x double> @llvm.maxnum.v8f64(<8 x double>, <8 x double>) #0
declare <16 x double> @llvm.maxnum.v16f64(<16 x double>, <16 x double>) #0

declare float @llvm.HSAIL.max.f32(float, float) #0
declare double @llvm.HSAIL.max.f64(double, double) #0

declare float @llvm.HSAIL.gcn.max.f32(float, float) #0
declare double @llvm.HSAIL.gcn.max.f64(double, double) #0

; HSAIL-LABEL: {{^}}prog function &test_fmaxnum_f32(
; HSAIL: max_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}
define void @test_fmaxnum_f32(float addrspace(1)* %out, float %a, float %b) #1 {
  %val = call float @llvm.maxnum.f32(float %a, float %b) #0
  store float %val, float addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_fmaxnum_v2f32(
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
define void @test_fmaxnum_v2f32(<2 x float> addrspace(1)* %out, <2 x float> %a, <2 x float> %b) #1 {
  %val = call <2 x float> @llvm.maxnum.v2f32(<2 x float> %a, <2 x float> %b) #0
  store <2 x float> %val, <2 x float> addrspace(1)* %out, align 8
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_fmaxnum_v4f32(
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
define void @test_fmaxnum_v4f32(<4 x float> addrspace(1)* %out, <4 x float> %a, <4 x float> %b) #1 {
  %val = call <4 x float> @llvm.maxnum.v4f32(<4 x float> %a, <4 x float> %b) #0
  store <4 x float> %val, <4 x float> addrspace(1)* %out, align 16
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_fmaxnum_v8f32(
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
define void @test_fmaxnum_v8f32(<8 x float> addrspace(1)* %out, <8 x float> %a, <8 x float> %b) #1 {
  %val = call <8 x float> @llvm.maxnum.v8f32(<8 x float> %a, <8 x float> %b) #0
  store <8 x float> %val, <8 x float> addrspace(1)* %out, align 32
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_fmaxnum_v16f32(
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
; HSAIL: max_ftz_f32
define void @test_fmaxnum_v16f32(<16 x float> addrspace(1)* %out, <16 x float> %a, <16 x float> %b) #1 {
  %val = call <16 x float> @llvm.maxnum.v16f32(<16 x float> %a, <16 x float> %b) #0
  store <16 x float> %val, <16 x float> addrspace(1)* %out, align 64
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_fmaxnum_f64(
; HSAIL: max_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}
define void @test_fmaxnum_f64(double addrspace(1)* %out, double %a, double %b) #1 {
  %val = call double @llvm.maxnum.f64(double %a, double %b) #0
  store double %val, double addrspace(1)* %out, align 8
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_fmaxnum_v2f64(
; HSAIL: max_f64
; HSAIL: max_f64
define void @test_fmaxnum_v2f64(<2 x double> addrspace(1)* %out, <2 x double> %a, <2 x double> %b) #1 {
  %val = call <2 x double> @llvm.maxnum.v2f64(<2 x double> %a, <2 x double> %b) #0
  store <2 x double> %val, <2 x double> addrspace(1)* %out, align 16
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_fmaxnum_v4f64(
; HSAIL: max_f64
; HSAIL: max_f64
; HSAIL: max_f64
; HSAIL: max_f64
define void @test_fmaxnum_v4f64(<4 x double> addrspace(1)* %out, <4 x double> %a, <4 x double> %b) #1 {
  %val = call <4 x double> @llvm.maxnum.v4f64(<4 x double> %a, <4 x double> %b) #0
  store <4 x double> %val, <4 x double> addrspace(1)* %out, align 32
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_fmaxnum_v8f64(
; HSAIL: max_f64
; HSAIL: max_f64
; HSAIL: max_f64
; HSAIL: max_f64
; HSAIL: max_f64
; HSAIL: max_f64
; HSAIL: max_f64
; HSAIL: max_f64
define void @test_fmaxnum_v8f64(<8 x double> addrspace(1)* %out, <8 x double> %a, <8 x double> %b) #1 {
  %val = call <8 x double> @llvm.maxnum.v8f64(<8 x double> %a, <8 x double> %b) #0
  store <8 x double> %val, <8 x double> addrspace(1)* %out, align 64
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_fmaxnum_v16f64(
; HSAIL: max_f64
; HSAIL: max_f64
; HSAIL: max_f64
; HSAIL: max_f64
; HSAIL: max_f64
; HSAIL: max_f64
; HSAIL: max_f64
; HSAIL: max_f64
; HSAIL: max_f64
; HSAIL: max_f64
; HSAIL: max_f64
; HSAIL: max_f64
; HSAIL: max_f64
; HSAIL: max_f64
; HSAIL: max_f64
; HSAIL: max_f64
define void @test_fmaxnum_v16f64(<16 x double> addrspace(1)* %out, <16 x double> %a, <16 x double> %b) #1 {
  %val = call <16 x double> @llvm.maxnum.v16f64(<16 x double> %a, <16 x double> %b) #0
  store <16 x double> %val, <16 x double> addrspace(1)* %out, align 128
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_hsail_max_f32(
; HSAIL: max_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}
define void @test_legacy_hsail_max_f32(float addrspace(1)* %out, float %a, float %b) #1 {
  %val = call float @llvm.HSAIL.max.f32(float %a, float %b) #0
  store float %val, float addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_hsail_max_f64(
; HSAIL: max_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}
define void @test_legacy_hsail_max_f64(double addrspace(1)* %out, double %a, double %b) #1 {
  %val = call double @llvm.HSAIL.max.f64(double %a, double %b) #0
  store double %val, double addrspace(1)* %out, align 8
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_gcn_max_f32(
; HSAIL: gcn_max_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}
define void @test_legacy_gcn_max_f32(float addrspace(1)* %out, float %a, float %b) #1 {
  %val = call float @llvm.HSAIL.gcn.max.f32(float %a, float %b) #0
  store float %val, float addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_gcn_max_f64(
; HSAIL: gcn_max_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}
define void @test_legacy_gcn_max_f64(double addrspace(1)* %out, double %a, double %b) #1 {
  %val = call double @llvm.HSAIL.gcn.max.f64(double %a, double %b) #0
  store double %val, double addrspace(1)* %out, align 8
  ret void
}

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
