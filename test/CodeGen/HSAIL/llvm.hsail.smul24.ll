; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.hsail.smul24(i32, i32) #0
declare i32 @llvm.HSAIL.mul24.s32(i32, i32) #0

; HSAIL-LABEL: {{^}}prog function &test_mul24_s32(
; HSAIL: mul24_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_mul24_s32(i32 %x, i32 %y) #0 {
  %val = call i32 @llvm.hsail.smul24(i32 %x, i32 %y) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_mul24_s32(
; HSAIL: mul24_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_legacy_mul24_s32(i32 %x, i32 %y) #0 {
  %val = call i32 @llvm.HSAIL.mul24.s32(i32 %x, i32 %y) #0
  ret i32 %val
}

attributes #0 = { nounwind readnone }
