; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

declare float @llvm.hsail.fsqrt.f32(i1, i32, float) #0
declare double @llvm.hsail.fsqrt.f64(i1, i32, double) #0


; HSAIL-LABEL: {{^}}prog function &test_sqrt_default_f32(
; HSAIL: sqrt_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_sqrt_default_f32(float %x) #0 {
  %ret = call float @llvm.hsail.fsqrt.f32(i1 false, i32 1, float %x) #0
  ret float %ret
}

; HSAIL-LABEL: {{^}}prog function &test_sqrt_near_f32(
; HSAIL: sqrt_near_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_sqrt_near_f32(float %x) #0 {
  %ret = call float @llvm.hsail.fsqrt.f32(i1 false, i32 2, float %x) #0
  ret float %ret
}

; HSAIL-LABEL: {{^}}prog function &test_sqrt_zero_f32(
; HSAIL: sqrt_zero_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_sqrt_zero_f32(float %x) #0 {
  %ret = call float @llvm.hsail.fsqrt.f32(i1 false, i32 3, float %x) #0
  ret float %ret
}

; HSAIL-LABEL: {{^}}prog function &test_sqrt_up_f32(
; HSAIL: sqrt_up_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_sqrt_up_f32(float %x) #0 {
  %ret = call float @llvm.hsail.fsqrt.f32(i1 false, i32 4, float %x) #0
  ret float %ret
}

; HSAIL-LABEL: {{^}}prog function &test_sqrt_down_f32(
; HSAIL: sqrt_down_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_sqrt_down_f32(float %x) #0 {
  %ret = call float @llvm.hsail.fsqrt.f32(i1 false, i32 5, float %x) #0
  ret float %ret
}

; HSAIL-LABEL: {{^}}prog function &test_sqrt_ftz_default_f32(
; HSAIL: sqrt_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_sqrt_ftz_default_f32(float %x) #0 {
  %ret = call float @llvm.hsail.fsqrt.f32(i1 true, i32 1, float %x) #0
  ret float %ret
}

; HSAIL-LABEL: {{^}}prog function &test_sqrt_ftz_near_even_f32(
; HSAIL: sqrt_ftz_near_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_sqrt_ftz_near_even_f32(float %x) #0 {
  %ret = call float @llvm.hsail.fsqrt.f32(i1 true, i32 2, float %x) #0
  ret float %ret
}

; HSAIL-LABEL: {{^}}prog function &test_sqrt_default_f64(
; HSAIL: sqrt_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define double @test_sqrt_default_f64(double %x) #0 {
  %ret = call double @llvm.hsail.fsqrt.f64(i1 false, i32 1, double %x) #0
  ret double %ret
}

; HSAIL-LABEL: {{^}}prog function &test_sqrt_near_f64(
; HSAIL: sqrt_near_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define double @test_sqrt_near_f64(double %x) #0 {
  %ret = call double @llvm.hsail.fsqrt.f64(i1 false, i32 2, double %x) #0
  ret double %ret
}

; HSAIL-LABEL: {{^}}prog function &test_sqrt_zero_f64(
; HSAIL: sqrt_zero_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define double @test_sqrt_zero_f64(double %x) #0 {
  %ret = call double @llvm.hsail.fsqrt.f64(i1 false, i32 3, double %x) #0
  ret double %ret
}

; HSAIL-LABEL: {{^}}prog function &test_sqrt_up_f64(
; HSAIL: sqrt_up_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define double @test_sqrt_up_f64(double %x) #0 {
  %ret = call double @llvm.hsail.fsqrt.f64(i1 false, i32 4, double %x) #0
  ret double %ret
}

; HSAIL-LABEL: {{^}}prog function &test_sqrt_down_f64(
; HSAIL: sqrt_down_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define double @test_sqrt_down_f64(double %x) #0 {
  %ret = call double @llvm.hsail.fsqrt.f64(i1 false, i32 5, double %x) #0
  ret double %ret
}

; HSAIL-LABEL: {{^}}prog function &test_sqrt_ftz_default_f64(
; HSAIL: sqrt_ftz_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define double @test_sqrt_ftz_default_f64(double %x) #0 {
  %ret = call double @llvm.hsail.fsqrt.f64(i1 true, i32 1, double %x) #0
  ret double %ret
}

; HSAIL-LABEL: {{^}}prog function &test_sqrt_ftz_near_even_f64(
; HSAIL: sqrt_ftz_near_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define double @test_sqrt_ftz_near_even_f64(double %x) #0 {
  %ret = call double @llvm.hsail.fsqrt.f64(i1 true, i32 2, double %x) #0
  ret double %ret
}

attributes #0 = { nounwind readnone }
