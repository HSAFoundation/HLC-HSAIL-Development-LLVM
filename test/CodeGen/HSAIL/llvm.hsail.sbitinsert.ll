; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.hsail.sbitinsert.i32(i32, i32, i32, i32) #0
declare i64 @llvm.hsail.sbitinsert.i64(i64, i64, i32, i32) #0

; HSAIL-LABEL: {{^}}prog function &test_sbitinsert_i32(
; HSAIL: bitinsert_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_sbitinsert_i32(i32 %x, i32 %y, i32 %z, i32 %w) #0 {
  %val = call i32 @llvm.hsail.sbitinsert.i32(i32 %x, i32 %y, i32 %z, i32 %w) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_sbitinsert_i32_riii(
; HSAIL: bitinsert_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 1, 2, 3;
define i32 @test_sbitinsert_i32_riii(i32 %x) #0 {
  %val = call i32 @llvm.hsail.sbitinsert.i32(i32 %x, i32 1, i32 2, i32 3) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_sbitinsert_i32_rirr(
; HSAIL: bitinsert_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 1, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_sbitinsert_i32_rirr(i32 %x, i32 %y, i32 %z) #0 {
  %val = call i32 @llvm.hsail.sbitinsert.i32(i32 %x, i32 1, i32 %y, i32 %z) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_sbitinsert_i32_rrri(
; HSAIL: bitinsert_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, 7;
define i32 @test_sbitinsert_i32_rrri(i32 %x, i32 %y, i32 %z) #0 {
  %val = call i32 @llvm.hsail.sbitinsert.i32(i32 %x, i32 %y, i32 %z, i32 7) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_sbitinsert_i32_iiii(
; HSAIL: bitinsert_s32 {{\$s[0-9]+}}, 3, 9, 11, 7;
define i32 @test_sbitinsert_i32_iiii() #0 {
  %val = call i32 @llvm.hsail.sbitinsert.i32(i32 3, i32 9, i32 11, i32 7) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_sbitinsert_i64(
; HSAIL: bitinsert_s64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i64 @test_sbitinsert_i64(i64 %x, i64 %y, i32 %z, i32 %w) #0 {
  %val = call i64 @llvm.hsail.sbitinsert.i64(i64 %x, i64 %y, i32 %z, i32 %w) #0
  ret i64 %val
}

attributes #0 = { nounwind readnone }
