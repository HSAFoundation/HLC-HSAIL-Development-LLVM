; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

declare float @llvm.hsail.fadd.f32(i1, i32, float, float) #0
declare double @llvm.hsail.fadd.f64(i1, i32, double, double) #0


; HSAIL-LABEL: {{^}}prog function &test_add_default_f32(
; HSAIL: add_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_add_default_f32(float %x, float %y) #0 {
  %ret = call float @llvm.hsail.fadd.f32(i1 false, i32 1, float %x, float %y) #0
  ret float %ret
}

; HSAIL-LABEL: {{^}}prog function &test_add_near_f32(
; HSAIL: add_near_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_add_near_f32(float %x, float %y) #0 {
  %ret = call float @llvm.hsail.fadd.f32(i1 false, i32 2, float %x, float %y) #0
  ret float %ret
}

; HSAIL-LABEL: {{^}}prog function &test_add_zero_f32(
; HSAIL: add_zero_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_add_zero_f32(float %x, float %y) #0 {
  %ret = call float @llvm.hsail.fadd.f32(i1 false, i32 3, float %x, float %y) #0
  ret float %ret
}

; HSAIL-LABEL: {{^}}prog function &test_add_up_f32(
; HSAIL: add_up_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_add_up_f32(float %x, float %y) #0 {
  %ret = call float @llvm.hsail.fadd.f32(i1 false, i32 4, float %x, float %y) #0
  ret float %ret
}

; HSAIL-LABEL: {{^}}prog function &test_add_down_f32(
; HSAIL: add_down_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_add_down_f32(float %x, float %y) #0 {
  %ret = call float @llvm.hsail.fadd.f32(i1 false, i32 5, float %x, float %y) #0
  ret float %ret
}

; HSAIL-LABEL: {{^}}prog function &test_add_ftz_default_f32(
; HSAIL: add_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_add_ftz_default_f32(float %x, float %y) #0 {
  %ret = call float @llvm.hsail.fadd.f32(i1 true, i32 1, float %x, float %y) #0
  ret float %ret
}

; HSAIL-LABEL: {{^}}prog function &test_add_ftz_near_even_f32(
; HSAIL: add_ftz_near_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_add_ftz_near_even_f32(float %x, float %y) #0 {
  %ret = call float @llvm.hsail.fadd.f32(i1 true, i32 2, float %x, float %y) #0
  ret float %ret
}

; HSAIL-LABEL: {{^}}prog function &test_add_default_f64(
; HSAIL: add_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define double @test_add_default_f64(double %x, double %y) #0 {
  %ret = call double @llvm.hsail.fadd.f64(i1 false, i32 1, double %x, double %y) #0
  ret double %ret
}

; HSAIL-LABEL: {{^}}prog function &test_add_near_f64(
; HSAIL: add_near_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define double @test_add_near_f64(double %x, double %y) #0 {
  %ret = call double @llvm.hsail.fadd.f64(i1 false, i32 2, double %x, double %y) #0
  ret double %ret
}

; HSAIL-LABEL: {{^}}prog function &test_add_zero_f64(
; HSAIL: add_zero_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define double @test_add_zero_f64(double %x, double %y) #0 {
  %ret = call double @llvm.hsail.fadd.f64(i1 false, i32 3, double %x, double %y) #0
  ret double %ret
}

; HSAIL-LABEL: {{^}}prog function &test_add_up_f64(
; HSAIL: add_up_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define double @test_add_up_f64(double %x, double %y) #0 {
  %ret = call double @llvm.hsail.fadd.f64(i1 false, i32 4, double %x, double %y) #0
  ret double %ret
}

; HSAIL-LABEL: {{^}}prog function &test_add_down_f64(
; HSAIL: add_down_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define double @test_add_down_f64(double %x, double %y) #0 {
  %ret = call double @llvm.hsail.fadd.f64(i1 false, i32 5, double %x, double %y) #0
  ret double %ret
}

; HSAIL-LABEL: {{^}}prog function &test_add_ftz_default_f64(
; HSAIL: add_ftz_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define double @test_add_ftz_default_f64(double %x, double %y) #0 {
  %ret = call double @llvm.hsail.fadd.f64(i1 true, i32 1, double %x, double %y) #0
  ret double %ret
}

; HSAIL-LABEL: {{^}}prog function &test_add_ftz_near_even_f64(
; HSAIL: add_ftz_near_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define double @test_add_ftz_near_even_f64(double %x, double %y) #0 {
  %ret = call double @llvm.hsail.fadd.f64(i1 true, i32 2, double %x, double %y) #0
  ret double %ret
}

attributes #0 = { nounwind readnone }
