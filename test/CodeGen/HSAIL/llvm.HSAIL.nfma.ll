; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare float @llvm.HSAIL.nfma.f32(float, float, float) #0
declare double @llvm.HSAIL.nfma.f64(double, double, double) #0


; HSAIL-LABEL: {{^}}prog function &test_nfma_f32(
; HSAIL: nfma_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define float @test_nfma_f32(float %x, float %y, float %z) #0 {
  %val = call float @llvm.HSAIL.nfma.f32(float %x, float %y, float %z) #0
  ret float %val
}

; HSAIL-LABEL: {{^}}prog function &test_nfma_f64(
; HSAIL: nfma_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define double @test_nfma_f64(double %x, double %y, double %z) #0 {
  %val = call double @llvm.HSAIL.nfma.f64(double %x, double %y, double %z) #0
  ret double %val
}

attributes #0 = { nounwind readnone }
