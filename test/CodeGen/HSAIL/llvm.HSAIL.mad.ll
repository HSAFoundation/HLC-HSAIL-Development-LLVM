; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.HSAIL.mad.u32(i32, i32, i32) #0
declare i64 @llvm.HSAIL.mad.u64(i64, i64, i64) #0


; HSAIL-LABEL: {{^}}prog function &test_mad_u32(
; HSAIL: mad_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_mad_u32(i32 %x, i32 %y, i32 %z) #0 {
  %val = call i32 @llvm.HSAIL.mad.u32(i32 %x, i32 %y, i32 %z) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_mad_u64(
; HSAIL: mad_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define i64 @test_mad_u64(i64 %x, i64 %y, i64 %z) #0 {
  %val = call i64 @llvm.HSAIL.mad.u64(i64 %x, i64 %y, i64 %z) #0
  ret i64 %val
}

attributes #0 = { nounwind readnone }
