; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; FIXME: Should also support i64
declare i32 @llvm.hsail.lastbit.i32(i32) #0
declare i32 @llvm.hsail.lastbit.i64(i64) #0

declare i32 @llvm.HSAIL.lastbit.u32(i32) #0

; HSAIL-LABEL: {{^}}prog function &test_lastbit_i32(
; HSAIL: lastbit_u32_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_lastbit_i32(i32 %x) #0 {
  %ret = call i32 @llvm.hsail.lastbit.i32(i32 %x) #0
  ret i32 %ret
}

; HSAIL-LABEL: {{^}}prog function &test_lastbit_i64(
; HSAIL: lastbit_u32_u64 {{\$s[0-9]+}}, {{\$d[0-9]+}};
define i32 @test_lastbit_i64(i64 %x) #0 {
  %ret = call i32 @llvm.hsail.lastbit.i64(i64 %x) #0
  ret i32 %ret
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_lastbit_i32(
; HSAIL: lastbit_u32_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_legacy_lastbit_i32(i32 %x) #0 {
  %ret = call i32 @llvm.HSAIL.lastbit.u32(i32 %x) #0
  ret i32 %ret
}

attributes #0 = { nounwind readnone }
