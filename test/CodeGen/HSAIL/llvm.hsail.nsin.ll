; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; FIXME: Do we really need this over llvm.sin?
declare float @llvm.hsail.nsin.f32(float) #0
declare float @llvm.HSAIL.nsin.f32(float) #0

; HSAIL-LABEL: {{^}}prog function &test_nsin_f32(
; HSAIL: nsin_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_nsin_f32(float %x) #0 {
  %sin = call float @llvm.hsail.nsin.f32(float %x) #0
  ret float %sin
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_nsin_f32(
; HSAIL: nsin_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_legacy_nsin_f32(float %x) #0 {
  %sin = call float @llvm.HSAIL.nsin.f32(float %x) #0
  ret float %sin
}

attributes #0 = { nounwind readnone }
