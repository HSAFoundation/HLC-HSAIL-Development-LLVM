; RUN: llc -march=hsail -mattr=+gcn -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.HSAIL.bfm(i32, i32) #0

; HSAIL-LABEL: {{^}}prog function &test_bfm_i32(
; HSAIL: gcn_bfm_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_bfm_i32(i32 %x, i32 %y, i32 %z) #0 {
  %val = call i32 @llvm.HSAIL.bfm(i32 %x, i32 %y) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_bfm_i32_ri(
; HSAIL: gcn_bfm_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 7;
define i32 @test_bfm_i32_ri(i32 %x) #0 {
  %val = call i32 @llvm.HSAIL.bfm(i32 %x, i32 7) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_bfm_i32_ir(
; HSAIL: gcn_bfm_b32 {{\$s[0-9]+}}, 3, {{\$s[0-9]+}};
define i32 @test_bfm_i32_ir(i32 %x) #0 {
  %val = call i32 @llvm.HSAIL.bfm(i32 3, i32 %x) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_bfm_i32_ii(
; HSAIL: gcn_bfm_b32 {{\$s[0-9]+}}, 6, 9;
define i32 @test_bfm_i32_ii() #0 {
  %val = call i32 @llvm.HSAIL.bfm(i32 6, i32 9) #0
  ret i32 %val
}

attributes #0 = { nounwind readnone }
