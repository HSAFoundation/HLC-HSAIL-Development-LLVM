; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.HSAIL.bytealign.b32(i32, i32, i32) #0

; HSAIL-LABEL: {{^}}prog function &test_bytealign_i32(
; HSAIL: bytealign_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_bytealign_i32(i32 %x, i32 %y, i32 %z) #0 {
  %val = call i32 @llvm.HSAIL.bytealign.b32(i32 %x, i32 %y, i32 %z) #0
  ret i32 %val
}

attributes #0 = { nounwind readnone }
