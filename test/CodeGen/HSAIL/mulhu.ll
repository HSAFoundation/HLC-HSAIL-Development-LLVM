; XFAIL: *

; This is failing because DAGCombiner decides it is profitable to
; replace 32-bit mulhu with extend and do 64-bit multiply.

; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.HSAIL.mulhi.u32(i32, i32) #0
declare i64 @llvm.HSAIL.mulhi.u64(i64, i64) #0

; HSAIL-LABEL: {{^}}prog function &test_mulhu_i32(
; HSAIL: mulhi_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_mulhu_i32(i32 %x, i32 %y) #1 {
  %val = call i32 @llvm.HSAIL.mulhi.u32(i32 %x, i32 %y) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_mulhu_i64(
; HSAIL: mulhi_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define i64 @test_mulhu_i64(i64 %x, i64 %y) #1 {
  %val = call i64 @llvm.HSAIL.mulhi.u64(i64 %x, i64 %y) #0
  ret i64 %val
}

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
