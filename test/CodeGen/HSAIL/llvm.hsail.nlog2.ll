; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; FIXME: Do we really need this over llvm.log2?
declare float @llvm.hsail.nlog2.f32(float) #0
declare float @llvm.HSAIL.nlog2.f32(float) #0

; HSAIL-LABEL: {{^}}prog function &test_nlog2_f32(
; HSAIL: nlog2_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_nlog2_f32(float %x) #0 {
  %log2 = call float @llvm.hsail.nlog2.f32(float %x) #0
  ret float %log2
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_nlog2_f32(
; HSAIL: nlog2_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_legacy_nlog2_f32(float %x) #0 {
  %log2 = call float @llvm.HSAIL.nlog2.f32(float %x) #0
  ret float %log2
}

attributes #0 = { nounwind readnone }
