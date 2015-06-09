; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.hsail.sadhi(i32, i32, i32) #0
declare i32 @llvm.HSAIL.sadhi.u16x2.u8x4(i32, i32, i32) #0

; HSAIL-LABEL: {{^}}prog function &test_sadhi_u16x2_i32(
; HSAIL: sadhi_u16x2_u8x4 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_sadhi_u16x2_i32(i32 %x, i32 %y, i32 %z) #0 {
  %val = call i32 @llvm.hsail.sadhi(i32 %x, i32 %y, i32 %z) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_sadhi_u16x2_i32_rii(
; HSAIL: sadhi_u16x2_u8x4 {{\$s[0-9]+}}, {{\$s[0-9]+}}, u8x4(1,0,0,0), u16x2(0,2);
define i32 @test_sadhi_u16x2_i32_rii(i32 %x) #0 {
  %val = call i32 @llvm.hsail.sadhi(i32 %x, i32 16777216, i32 2) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_sadhi_u16x2_i32_rir(
; HSAIL: sadhi_u16x2_u8x4 {{\$s[0-9]+}}, {{\$s[0-9]+}}, u8x4(1,1,1,1), {{\$s[0-9]+}};
define i32 @test_sadhi_u16x2_i32_rir(i32 %x, i32 %y) #0 {
  %val = call i32 @llvm.hsail.sadhi(i32 %x, i32 16843009, i32 %y) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_sadhi_u16x2_i32_rri(
; HSAIL: sadhi_u16x2_u8x4 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, u16x2(2,123);
define i32 @test_sadhi_u16x2_i32_rri(i32 %x, i32 %y) #0 {
  %val = call i32 @llvm.hsail.sadhi(i32 %x, i32 %y, i32 131195) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_sadhi_u16x2_i32_rii_max(
; HSAIL: sadhi_u16x2_u8x4 {{\$s[0-9]+}}, {{\$s[0-9]+}}, u8x4(255,255,255,255), u16x2(65535,65535);
define i32 @test_sadhi_u16x2_i32_rii_max(i32 %x, i32 %y) #0 {
  %val = call i32 @llvm.hsail.sadhi(i32 %x, i32 4294967295, i32 4294967295) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_sadhi_u16x2_i32_iri(
; HSAIL: sadhi_u16x2_u8x4 {{\$s[0-9]+}}, u8x4(0,5,57,149), {{\$s[0-9]+}}, u16x2(0,9);
define i32 @test_sadhi_u16x2_i32_iri(i32 %x) #0 {
  %val = call i32 @llvm.hsail.sadhi(i32 342421, i32 %x, i32 9) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_sadhi_u16x2_i32_iir(
; HSAIL: sadhi_u16x2_u8x4 {{\$s[0-9]+}}, u8x4(0,0,1,0), u8x4(0,1,0,0), {{\$s[0-9]+}};
define i32 @test_sadhi_u16x2_i32_iir(i32 %x) #0 {
  %val = call i32 @llvm.hsail.sadhi(i32 256, i32 65536, i32 %x) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_sadhi_u16x2_i32_iii(
; HSAIL: sadhi_u16x2_u8x4 {{\$s[0-9]+}}, u8x4(0,0,0,3), u8x4(0,0,4,210), u16x2(0,11);
define i32 @test_sadhi_u16x2_i32_iii() #0 {
  %val = call i32 @llvm.hsail.sadhi(i32 3, i32 1234, i32 11) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_sadhi_u16x2_i32(
; HSAIL: sadhi_u16x2_u8x4 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_legacy_sadhi_u16x2_i32(i32 %x, i32 %y, i32 %z) #0 {
  %val = call i32 @llvm.HSAIL.sadhi.u16x2.u8x4(i32 %x, i32 %y, i32 %z) #0
  ret i32 %val
}

attributes #0 = { nounwind readnone }
