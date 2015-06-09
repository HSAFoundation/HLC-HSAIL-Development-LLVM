; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; FIXME: Do we really need this over llvm.cos?

declare float @llvm.hsail.ncos.f32(float) #0
declare float @llvm.HSAIL.ncos.f32(float) #0

; HSAIL-LABEL: {{^}}prog function &test_ncos_f32(
; HSAIL: ncos_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_ncos_f32(float %x) #0 {
  %cos = call float @llvm.hsail.ncos.f32(float %x) #0
  ret float %cos
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_ncos_f32(
; HSAIL: ncos_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_legacy_ncos_f32(float %x) #0 {
  %cos = call float @llvm.HSAIL.ncos.f32(float %x) #0
  ret float %cos
}

attributes #0 = { nounwind readnone }
