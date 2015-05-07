; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-NOT: __hsail_nsqrt_f32

; FIXME: Do we really need this over llvm.sqrt? What is nsqrt's behavior for < 0.0?

declare float @llvm.HSAIL.nsqrt.f32(float) #0
declare double @llvm.HSAIL.nsqrt.f64(double) #0
declare float @__hsail_nsqrt_f32(float) #0


; HSAIL-LABEL: {{^}}prog function &test_nsqrt_f32(
; HSAIL: nsqrt_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_nsqrt_f32(float %x) #0 {
  %sqrt = call float @llvm.HSAIL.nsqrt.f32(float %x) #0
  ret float %sqrt
}

; HSAIL-LABEL: {{^}}prog function &test_nsqrt_f64(
; HSAIL: nsqrt_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define double @test_nsqrt_f64(double %x) #0 {
  %sqrt = call double @llvm.HSAIL.nsqrt.f64(double %x) #0
  ret double %sqrt
}

; HSAIL-LABEL: {{^}}prog function &test_nsqrt_gccbuiltin_f32(
; HSAIL: nsqrt_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_nsqrt_gccbuiltin_f32(float %x) #0 {
  %sqrt = call float @__hsail_nsqrt_f32(float %x) #0
  ret float %sqrt
}

attributes #0 = { nounwind readnone }
