; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.hsail.bitrev.i32(i32) #0
declare i64 @llvm.hsail.bitrev.i64(i64) #0

; HSAIL-LABEL: {{^}}prog function &test_bitrev_i32(
; HSAIL: bitrev_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_bitrev_i32(i32 %x) #0 {
  %val = call i32 @llvm.hsail.bitrev.i32(i32 %x) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_bitrev_i64(
; HSAIL: bitrev_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define i64 @test_bitrev_i64(i64 %x) #0 {
  %val = call i64 @llvm.hsail.bitrev.i64(i64 %x) #0
  ret i64 %val
}

attributes #0 = { nounwind readnone }
