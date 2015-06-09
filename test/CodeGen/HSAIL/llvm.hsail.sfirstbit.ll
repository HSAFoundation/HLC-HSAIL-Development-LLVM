; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.hsail.sfirstbit.i32(i32) #0
declare i32 @llvm.hsail.sfirstbit.i64(i64) #0

; HSAIL-LABEL: {{^}}prog function &test_sfirstbit_i32(
; HSAIL: firstbit_u32_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_sfirstbit_i32(i32 %x) #0 {
  %ret = call i32 @llvm.hsail.sfirstbit.i32(i32 %x) #0
  ret i32 %ret
}

; HSAIL-LABEL: {{^}}prog function &test_sfirstbit_i64(
; HSAIL: firstbit_u32_s64 {{\$s[0-9]+}}, {{\$d[0-9]+}};
define i32 @test_sfirstbit_i64(i64 %x) #0 {
  %ret = call i32 @llvm.hsail.sfirstbit.i64(i64 %x) #0
  ret i32 %ret
}

attributes #0 = { nounwind readnone }
