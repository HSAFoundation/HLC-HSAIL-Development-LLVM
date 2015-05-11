; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.HSAIL.bfe(i32, i32, i32) #0

; HSAIL-LABEL: {{^}}prog function &test_bfe_i32(
; HSAIL: bitextract_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_bfe_i32(i32 %x, i32 %y, i32 %z) #0 {
  %val = call i32 @llvm.HSAIL.bfe(i32 %x, i32 %y, i32 %z) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_bfe_i32_rii(
; HSAIL: bitextract_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 1, 2;
define i32 @test_bfe_i32_rii(i32 %x) #0 {
  %val = call i32 @llvm.HSAIL.bfe(i32 %x, i32 1, i32 2) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_bfe_i32_rir(
; HSAIL: bitextract_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 1, {{\$s[0-9]+}};
define i32 @test_bfe_i32_rir(i32 %x, i32 %y) #0 {
  %val = call i32 @llvm.HSAIL.bfe(i32 %x, i32 1, i32 %y) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_bfe_i32_rri(
; HSAIL: bitextract_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, 7;
define i32 @test_bfe_i32_rri(i32 %x, i32 %y) #0 {
  %val = call i32 @llvm.HSAIL.bfe(i32 %x, i32 %y, i32 7) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_bfe_i32_iri(
; HSAIL: bitextract_u32 {{\$s[0-9]+}}, 3, {{\$s[0-9]+}}, 7;
define i32 @test_bfe_i32_iri(i32 %x) #0 {
  %val = call i32 @llvm.HSAIL.bfe(i32 3, i32 %x, i32 7) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_bfe_i32_iir(
; HSAIL: bitextract_u32 {{\$s[0-9]+}}, 3, 9, {{\$s[0-9]+}};
define i32 @test_bfe_i32_iir(i32 %x) #0 {
  %val = call i32 @llvm.HSAIL.bfe(i32 3, i32 9, i32 %x) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_bfe_i32_iii(
; HSAIL: bitextract_u32 {{\$s[0-9]+}}, 3, 9, 11;
define i32 @test_bfe_i32_iii() #0 {
  %val = call i32 @llvm.HSAIL.bfe(i32 3, i32 9, i32 11) #0
  ret i32 %val
}

attributes #0 = { nounwind readnone }
