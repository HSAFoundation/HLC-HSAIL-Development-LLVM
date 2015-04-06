; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.HSAIL.class.f32(float, i32) #0
declare i32 @llvm.HSAIL.class.f64(double, i32) #0

; HSAIL-LABEL: {{^}}prog function &test_class_f32(
; HSAIL: class_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_class_f32(float %x, i32 %y) #0 {
  %val = call i32 @llvm.HSAIL.class.f32(float %x, i32 %y) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_class_f32_ii(
; HSAIL: class_b1_f32 {{\$c[0-9]+}}, 0F41000000, 9;
define i32 @test_class_f32_ii() #0 {
  %val = call i32 @llvm.HSAIL.class.f32(float 8.0, i32 9) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_class_f32_ri(
; HSAIL: class_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, 9;
define i32 @test_class_f32_ri(float %x) #0 {
  %val = call i32 @llvm.HSAIL.class.f32(float %x, i32 9) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_class_f32_ir(
; HSAIL: class_b1_f32 {{\$c[0-9]+}}, 0F41000000, {{\$s[0-9]+}};
define i32 @test_class_f32_ir(i32 %y) #0 {
  %val = call i32 @llvm.HSAIL.class.f32(float 8.0, i32 %y) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_class_f64(
; HSAIL: class_b1_f64 {{\$c[0-9]+}}, {{\$d[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_class_f64(double %x, i32 %y) #0 {
  %val = call i32 @llvm.HSAIL.class.f64(double %x, i32 %y) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_class_f64_ii(
; HSAIL: class_b1_f64 {{\$c[0-9]+}}, 0D4020000000000000, 9;
define i32 @test_class_f64_ii() #0 {
  %val = call i32 @llvm.HSAIL.class.f64(double 8.0, i32 9) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_class_f64_ri(
; HSAIL: class_b1_f64 {{\$c[0-9]+}}, {{\$d[0-9]+}}, 9;
define i32 @test_class_f64_ri(double %x) #0 {
  %val = call i32 @llvm.HSAIL.class.f64(double %x, i32 9) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_class_f64_ir(
; HSAIL: class_b1_f64 {{\$c[0-9]+}}, 0D4020000000000000, {{\$s[0-9]+}};
define i32 @test_class_f64_ir(i32 %y) #0 {
  %val = call i32 @llvm.HSAIL.class.f64(double 8.0, i32 %y) #0
  ret i32 %val
}


attributes #0 = { nounwind readnone }
