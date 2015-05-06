; RUN: llc -march=hsail -mattr=+gcn -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare float @llvm.HSAIL.fmin3(float, float, float) #0

; HSAIL-LABEL: {{^}}prog function &test_min3_f32(
; HSAIL: gcn_min3_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_min3_f32(float %x, float %y, float %z) #0 {
  %val = call float @llvm.HSAIL.fmin3(float %x, float %y, float %z) #0
  ret float %val
}

; HSAIL-LABEL: {{^}}prog function &test_min3_f32_rii(
; HSAIL: gcn_min3_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 0F449a4000, 0F40000000;
define float @test_min3_f32_rii(float %x) #0 {
  %val = call float @llvm.HSAIL.fmin3(float %x, float 1234.0, float 2.0) #0
  ret float %val
}

; HSAIL-LABEL: {{^}}prog function &test_min3_f32_rir(
; HSAIL: gcn_min3_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 0F3f800000, {{\$s[0-9]+}};
define float @test_min3_f32_rir(float %x, float %y) #0 {
  %val = call float @llvm.HSAIL.fmin3(float %x, float 1.0, float %y) #0
  ret float %val
}

; HSAIL-LABEL: {{^}}prog function &test_min3_f32_rri(
; HSAIL: gcn_min3_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, 0F41000000;
define float @test_min3_f32_rri(float %x, float %y) #0 {
  %val = call float @llvm.HSAIL.fmin3(float %x, float %y, float 8.0) #0
  ret float %val
}

; HSAIL-LABEL: {{^}}prog function &test_min3_f32_iri(
; HSAIL: gcn_min3_f32 {{\$s[0-9]+}}, 0F48a732a0, {{\$s[0-9]+}}, 0F41100000;
define float @test_min3_f32_iri(float %x) #0 {
  %val = call float @llvm.HSAIL.fmin3(float 342421.0, float %x, float 9.0) #0
  ret float %val
}

; HSAIL-LABEL: {{^}}prog function &test_min3_f32_iir(
; HSAIL: gcn_min3_f32 {{\$s[0-9]+}}, 0F43800000, 0F449a4000, {{\$s[0-9]+}};
define float @test_min3_f32_iir(float %x) #0 {
  %val = call float @llvm.HSAIL.fmin3(float 256.0, float 1234.0, float %x) #0
  ret float %val
}

; HSAIL-LABEL: {{^}}prog function &test_min3_f32_iii(
; HSAIL: gcn_min3_f32 {{\$s[0-9]+}}, 0F40400000, 0F449a4000, 0F41300000;
define float @test_min3_f32_iii() #0 {
  %val = call float @llvm.HSAIL.fmin3(float 3.0, float 1234.0, float 11.0) #0
  ret float %val
}

attributes #0 = { nounwind readnone }
