; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.hsail.bitmask.i32(i32, i32) #0
declare i64 @llvm.hsail.bitmask.i64(i32, i32) #0

; HSAIL-LABEL: {{^}}prog function &test_bitmask_i32_rr(
; HSAIL: bitmask_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_bitmask_i32_rr(i32 %x, i32 %y) #0 {
  %val = call i32 @llvm.hsail.bitmask.i32(i32 %x, i32 %y) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_bitmask_i32_ri(
; HSAIL: bitmask_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 7;
define i32 @test_bitmask_i32_ri(i32 %x) #0 {
  %val = call i32 @llvm.hsail.bitmask.i32(i32 %x, i32 7) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_bitmask_i32_ir(
; HSAIL: bitmask_b32 {{\$s[0-9]+}}, 7, {{\$s[0-9]+}};
define i32 @test_bitmask_i32_ir(i32 %x) #0 {
  %val = call i32 @llvm.hsail.bitmask.i32(i32 7, i32 %x) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_bitmask_i64_rr(
; HSAIL: bitmask_b64 {{\$d[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i64 @test_bitmask_i64_rr(i32 %x, i32 %y) #0 {
  %val = call i64 @llvm.hsail.bitmask.i64(i32 %x, i32 %y) #0
  ret i64 %val
}


attributes #0 = { nounwind readnone }
