; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

declare float @llvm.hsail.nrcp.f32(float) #0
declare double @llvm.hsail.nrcp.f64(double) #0
declare float @llvm.HSAIL.nrcp.f32(float) #0
declare double @llvm.HSAIL.nrcp.f64(double) #0

; HSAIL-LABEL: {{^}}prog function &test_nrcp_f32(
; HSAIL: nrcp_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_nrcp_f32(float %x) #0 {
  %sqrt = call float @llvm.hsail.nrcp.f32(float %x) #0
  ret float %sqrt
}

; HSAIL-LABEL: {{^}}prog function &test_nrcp_f64(
; HSAIL: nrcp_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define double @test_nrcp_f64(double %x) #0 {
  %sqrt = call double @llvm.hsail.nrcp.f64(double %x) #0
  ret double %sqrt
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_nrcp_f32(
; HSAIL: nrcp_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_legacy_nrcp_f32(float %x) #0 {
  %sqrt = call float @llvm.HSAIL.nrcp.f32(float %x) #0
  ret float %sqrt
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_nrcp_f64(
; HSAIL: nrcp_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define double @test_legacy_nrcp_f64(double %x) #0 {
  %sqrt = call double @llvm.HSAIL.nrcp.f64(double %x) #0
  ret double %sqrt
}

attributes #0 = { nounwind readnone }
