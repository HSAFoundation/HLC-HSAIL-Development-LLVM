; RUN: llc -march=hsail -mattr=+gcn < %s | FileCheck -check-prefix=HSAIL %s

declare float @llvm.HSAIL.gcn.fldexp.f32(float, i32) #0
declare double @llvm.HSAIL.gcn.fldexp.f64(double, i32) #0

; HSAIL-LABEL: {{^}}prog function &test_gcn_fldexp_f32_rr(
; HSAIL: gcn_fldexp_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_gcn_fldexp_f32_rr(float %x, i32 %y) #0 {
  %val = call float @llvm.HSAIL.gcn.fldexp.f32(float %x, i32 %y) #0
  ret float %val
}

; HSAIL-LABEL: {{^}}prog function &test_gcn_fldexp_f32_ri(
; HSAIL: gcn_fldexp_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 9;
define float @test_gcn_fldexp_f32_ri(float %x) #0 {
  %val = call float @llvm.HSAIL.gcn.fldexp.f32(float %x, i32 9) #0
  ret float %val
}

; HSAIL-LABEL: {{^}}prog function &test_gcn_fldexp_f32_ir(
; HSAIL: gcn_fldexp_f32 {{\$s[0-9]+}}, 0F41200000, {{\$s[0-9]+}};
define float @test_gcn_fldexp_f32_ir(i32 %y) #0 {
  %val = call float @llvm.HSAIL.gcn.fldexp.f32(float 10.0, i32 %y) #0
  ret float %val
}

; FIXME: This should constant fold
; HSAIL-LABEL: {{^}}prog function &test_gcn_fldexp_f32_ii(
; HSAIL: gcn_fldexp_f32 {{\$s[0-9]+}}, 0F41200000, 8;
define float @test_gcn_fldexp_f32_ii(i32 %y) #0 {
  %val = call float @llvm.HSAIL.gcn.fldexp.f32(float 10.0, i32 8) #0
  ret float %val
}

; HSAIL-LABEL: {{^}}prog function &test_gcn_fldexp_f64_rr(
; HSAIL: gcn_fldexp_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$s[0-9]+}};
define double @test_gcn_fldexp_f64_rr(double %x, i32 %y) #0 {
  %val = call double @llvm.HSAIL.gcn.fldexp.f64(double %x, i32 %y) #0
  ret double %val
}

; HSAIL-LABEL: {{^}}prog function &test_gcn_fldexp_f64_ri(
; HSAIL: gcn_fldexp_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 9;
define double @test_gcn_fldexp_f64_ri(double %x) #0 {
  %val = call double @llvm.HSAIL.gcn.fldexp.f64(double %x, i32 9) #0
  ret double %val
}

; HSAIL-LABEL: {{^}}prog function &test_gcn_fldexp_f64_ir(
; HSAIL: gcn_fldexp_f64 {{\$d[0-9]+}}, 0D4024000000000000, {{\$s[0-9]+}};
define double @test_gcn_fldexp_f64_ir(i32 %y) #0 {
  %val = call double @llvm.HSAIL.gcn.fldexp.f64(double 10.0, i32 %y) #0
  ret double %val
}

; FIXME: This should constant fold
; HSAIL-LABEL: {{^}}prog function &test_gcn_fldexp_f64_ii(
; HSAIL: gcn_fldexp_f64 {{\$d[0-9]+}}, 0D4024000000000000, 8;
define double @test_gcn_fldexp_f64_ii(i32 %y) #0 {
  %val = call double @llvm.HSAIL.gcn.fldexp.f64(double 10.0, i32 8) #0
  ret double %val
}

attributes #0 = { nounwind readnone }
