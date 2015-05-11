; XFAIL: *
; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

declare float @llvm.sqrt.f32(float) #0
declare double @llvm.sqrt.f64(double) #0

; HSAIL-LABEL: {{^}}prog function &test_rsqrt_f32(
; HSAIL: nsqrt_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define float @test_rsqrt_f32(float %x) #0 {
  %sqrt = call float @llvm.sqrt.f32(float %x) #0
  %rsqrt = fdiv float 1.0, %sqrt
  ret float %rsqrt
}

; HSAIL-LABEL: {{^}}prog function &test_rsqrt_f64(
; HSAIL: nsqrt_f64 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define double @test_rsqrt_f64(double %x) #0 {
  %sqrt = call double @llvm.sqrt.f64(double %x) #0
  %rsqrt = fdiv double 1.0, %sqrt
  ret double %rsqrt
}

attributes #0 = { nounwind readnone }
