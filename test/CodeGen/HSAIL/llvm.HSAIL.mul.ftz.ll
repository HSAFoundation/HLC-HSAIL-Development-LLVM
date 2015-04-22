; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

declare float @llvm.HSAIL.mul.ftz.f32(float) #0

; HSAIL-LABEL: {{^}}prog function &test_mul_ftz_f32(
; HSAIL: mul_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 0F3f800000;
define float @test_mul_ftz_f32(float %x) #0 {
  %sqrt = call float @llvm.HSAIL.mul.ftz.f32(float %x) #0
  ret float %sqrt
}

attributes #0 = { nounwind readnone }
