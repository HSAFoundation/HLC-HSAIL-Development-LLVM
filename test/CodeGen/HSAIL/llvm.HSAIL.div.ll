; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare float @llvm.HSAIL.div.f32(float, float) #0

declare float @llvm.HSAIL.div.ftz.f32(float, float) #0

; HSAIL-LABEL: {{^}}prog function &test_div_f32(
; HSAIL: div_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_div_f32(float %x, float %y) #0 {
  %val = call float @llvm.HSAIL.div.f32(float %x, float %y) #0
  ret float %val
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_div_ftz_f32(
; HSAIL: div_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_legacy_div_ftz_f32(float %x, float %y) #0 {
  %val = call float @llvm.HSAIL.div.ftz.f32(float %x, float %y) #0
  ret float %val
}

attributes #0 = { nounwind readnone }
