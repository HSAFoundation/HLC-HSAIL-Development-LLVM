; RUN: llc -march=hsail -mattr=+gcn -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.HSAIL.imed3(i32, i32, i32) #0

; HSAIL-LABEL: {{^}}prog function &test_med3_s32(
; HSAIL: gcn_med3_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_med3_s32(i32 %x, i32 %y, i32 %z) #0 {
  %val = call i32 @llvm.HSAIL.imed3(i32 %x, i32 %y, i32 %z) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_med3_s32_rii(
; HSAIL: gcn_med3_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 1234, 2;
define i32 @test_med3_s32_rii(i32 %x) #0 {
  %val = call i32 @llvm.HSAIL.imed3(i32 %x, i32 1234, i32 2) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_med3_s32_rir(
; HSAIL: gcn_med3_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 1, {{\$s[0-9]+}};
define i32 @test_med3_s32_rir(i32 %x, i32 %y) #0 {
  %val = call i32 @llvm.HSAIL.imed3(i32 %x, i32 1, i32 %y) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_med3_s32_rri(
; HSAIL: gcn_med3_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, 7;
define i32 @test_med3_s32_rri(i32 %x, i32 %y) #0 {
  %val = call i32 @llvm.HSAIL.imed3(i32 %x, i32 %y, i32 7) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_med3_s32_iri(
; HSAIL: gcn_med3_s32 {{\$s[0-9]+}}, 342421, {{\$s[0-9]+}}, 9;
define i32 @test_med3_s32_iri(i32 %x) #0 {
  %val = call i32 @llvm.HSAIL.imed3(i32 342421, i32 %x, i32 9) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_med3_s32_iir(
; HSAIL: gcn_med3_s32 {{\$s[0-9]+}}, 256, 65536, {{\$s[0-9]+}};
define i32 @test_med3_s32_iir(i32 %x) #0 {
  %val = call i32 @llvm.HSAIL.imed3(i32 256, i32 65536, i32 %x) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_med3_s32_iii(
; HSAIL: gcn_med3_s32 {{\$s[0-9]+}}, 3, 1234, 11;
define i32 @test_med3_s32_iii() #0 {
  %val = call i32 @llvm.HSAIL.imed3(i32 3, i32 1234, i32 11) #0
  ret i32 %val
}

attributes #0 = { nounwind readnone }
