; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

declare float @llvm.hsail.nrsqrt.f32(float) #0
declare double @llvm.hsail.nrsqrt.f64(double) #0

declare float @llvm.HSAIL.nrsqrt.f32(float) #0
declare double @llvm.HSAIL.nrsqrt.f64(double) #0

; HSAIL-LABEL: {{^}}prog function &test_nrsqrt_f32(
; HSAIL: nrsqrt_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_nrsqrt_f32(float %x) #0 {
  %sqrt = call float @llvm.hsail.nrsqrt.f32(float %x) #0
  ret float %sqrt
}

; HSAIL-LABEL: {{^}}prog function &test_nrsqrt_f64(
; HSAIL: nrsqrt_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define double @test_nrsqrt_f64(double %x) #0 {
  %sqrt = call double @llvm.hsail.nrsqrt.f64(double %x) #0
  ret double %sqrt
}


; HSAIL-LABEL: {{^}}prog function &test_legacy_nrsqrt_f32(
; HSAIL: nrsqrt_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_legacy_nrsqrt_f32(float %x) #0 {
  %sqrt = call float @llvm.HSAIL.nrsqrt.f32(float %x) #0
  ret float %sqrt
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_nrsqrt_f64(
; HSAIL: nrsqrt_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define double @test_legacy_nrsqrt_f64(double %x) #0 {
  %sqrt = call double @llvm.HSAIL.nrsqrt.f64(double %x) #0
  ret double %sqrt
}

attributes #0 = { nounwind readnone }
