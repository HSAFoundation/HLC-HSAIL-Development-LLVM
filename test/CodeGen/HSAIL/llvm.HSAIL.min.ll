; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.HSAIL.min.u32(i32, i32) #0
declare i64 @llvm.HSAIL.min.u64(i64, i64) #0
declare i32 @llvm.HSAIL.min.s32(i32, i32) #0
declare i64 @llvm.HSAIL.min.s64(i64, i64) #0


; HSAIL-LABEL: {{^}}prog function &test_min_u32(
; HSAIL: min_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_min_u32(i32 %x, i32 %y) #0 {
  %val = call i32 @llvm.HSAIL.min.u32(i32 %x, i32 %y) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_min_u64(
; HSAIL: min_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define i64 @test_min_u64(i64 %x, i64 %y) #0 {
  %val = call i64 @llvm.HSAIL.min.u64(i64 %x, i64 %y) #0
  ret i64 %val
}
; HSAIL-LABEL: {{^}}prog function &test_min_s32(
; HSAIL: min_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_min_s32(i32 %x, i32 %y) #0 {
  %val = call i32 @llvm.HSAIL.min.s32(i32 %x, i32 %y) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_min_s64(
; HSAIL: min_s64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define i64 @test_min_s64(i64 %x, i64 %y) #0 {
  %val = call i64 @llvm.HSAIL.min.s64(i64 %x, i64 %y) #0
  ret i64 %val
}

attributes #0 = { nounwind readnone }
