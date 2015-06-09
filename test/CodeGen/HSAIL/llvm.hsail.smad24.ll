; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.hsail.smad24(i32, i32, i32) #0
declare i32 @llvm.HSAIL.mad24.s32(i32, i32, i32) #0

; HSAIL-LABEL: {{^}}prog function &test_smad24(
; HSAIL: mad24_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_smad24(i32 %x, i32 %y, i32 %z) #0 {
  %val = call i32 @llvm.hsail.smad24(i32 %x, i32 %y, i32 %z) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_mad24_s32(
; HSAIL: mad24_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_mad24_s32(i32 %x, i32 %y, i32 %z) #0 {
  %val = call i32 @llvm.HSAIL.mad24.s32(i32 %x, i32 %y, i32 %z) #0
  ret i32 %val
}

attributes #0 = { nounwind readnone }
