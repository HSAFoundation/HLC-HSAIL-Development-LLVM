; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; FIXME: Do we really need this over llvm.exp2?

declare float @llvm.hsail.nexp2.f32(float) #0
declare float @llvm.HSAIL.nexp2.f32(float) #0

; HSAIL-LABEL: {{^}}prog function &test_nexp2_f32(
; HSAIL: nexp2_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_nexp2_f32(float %x) #0 {
  %exp2 = call float @llvm.hsail.nexp2.f32(float %x) #0
  ret float %exp2
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_nexp2_f32(
; HSAIL: nexp2_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_legacy_nexp2_f32(float %x) #0 {
  %exp2 = call float @llvm.HSAIL.nexp2.f32(float %x) #0
  ret float %exp2
}

attributes #0 = { nounwind readnone }
