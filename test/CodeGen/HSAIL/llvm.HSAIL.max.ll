; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.HSAIL.max.u32(i32, i32) #0
declare i64 @llvm.HSAIL.max.u64(i64, i64) #0
declare i32 @llvm.HSAIL.max.s32(i32, i32) #0
declare i64 @llvm.HSAIL.max.s64(i64, i64) #0


; HSAIL-LABEL: {{^}}prog function &test_max_u32(
; HSAIL: max_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_max_u32(i32 %x, i32 %y) #0 {
  %val = call i32 @llvm.HSAIL.max.u32(i32 %x, i32 %y) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_max_u64(
; HSAIL: max_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define i64 @test_max_u64(i64 %x, i64 %y) #0 {
  %val = call i64 @llvm.HSAIL.max.u64(i64 %x, i64 %y) #0
  ret i64 %val
}
; HSAIL-LABEL: {{^}}prog function &test_max_s32(
; HSAIL: max_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_max_s32(i32 %x, i32 %y) #0 {
  %val = call i32 @llvm.HSAIL.max.s32(i32 %x, i32 %y) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_max_s64(
; HSAIL: max_s64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define i64 @test_max_s64(i64 %x, i64 %y) #0 {
  %val = call i64 @llvm.HSAIL.max.s64(i64 %x, i64 %y) #0
  ret i64 %val
}

attributes #0 = { nounwind readnone }
