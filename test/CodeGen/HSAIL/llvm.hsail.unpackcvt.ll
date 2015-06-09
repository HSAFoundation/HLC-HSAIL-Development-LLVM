; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare float @llvm.hsail.unpackcvt(i32, i32) #0
declare float @llvm.HSAIL.unpackcvt.f32.u8x4(i32, i32) #0

; HSAIL-LABEL: {{^}}prog function &test_unpackcvt_f32_u8x4_0(
; HSAIL: unpackcvt_f32_u8x4 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 0;
define float @test_unpackcvt_f32_u8x4_0(i32 %x) #0 {
  %val = call float @llvm.hsail.unpackcvt(i32 %x, i32 0) #0
  ret float %val
}

; HSAIL-LABEL: {{^}}prog function &test_unpackcvt_f32_u8x4_1(
; HSAIL: unpackcvt_f32_u8x4 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 1;
define float @test_unpackcvt_f32_u8x4_1(i32 %x) #0 {
  %val = call float @llvm.hsail.unpackcvt(i32 %x, i32 1) #0
  ret float %val
}

; HSAIL-LABEL: {{^}}prog function &test_unpackcvt_f32_u8x4_2(
; HSAIL: unpackcvt_f32_u8x4 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 2;
define float @test_unpackcvt_f32_u8x4_2(i32 %x) #0 {
  %val = call float @llvm.hsail.unpackcvt(i32 %x, i32 2) #0
  ret float %val
}

; HSAIL-LABEL: {{^}}prog function &test_unpackcvt_f32_u8x4_3(
; HSAIL: unpackcvt_f32_u8x4 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 3;
define float @test_unpackcvt_f32_u8x4_3(i32 %x) #0 {
  %val = call float @llvm.hsail.unpackcvt(i32 %x, i32 3) #0
  ret float %val
}

; HSAIL-LABEL: {{^}}prog function &test_unpackcvt_f32_u8x4_0_imm(
; HSAIL: unpackcvt_f32_u8x4 {{\$s[0-9]+}}, u8x4(0,0,48,57), 0;
define float @test_unpackcvt_f32_u8x4_0_imm() #0 {
  %val = call float @llvm.hsail.unpackcvt(i32 12345, i32 0) #0
  ret float %val
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_unpackcvt_f32_u8x4_0(
; HSAIL: unpackcvt_f32_u8x4 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 0;
define float @test_legacy_unpackcvt_f32_u8x4_0(i32 %x) #0 {
  %val = call float @llvm.HSAIL.unpackcvt.f32.u8x4(i32 %x, i32 0) #0
  ret float %val
}

attributes #0 = { nounwind readnone }
