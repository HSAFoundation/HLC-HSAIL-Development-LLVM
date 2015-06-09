; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.hsail.ufirstbit.i32(i32) #0
declare i32 @llvm.hsail.ufirstbit.i64(i64) #0
declare i32 @llvm.HSAIL.firstbit.u32(i32) #0

; HSAIL-LABEL: {{^}}prog function &test_ufirstbit_i32(
; HSAIL: firstbit_u32_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_ufirstbit_i32(i32 %x) #0 {
  %ret = call i32 @llvm.hsail.ufirstbit.i32(i32 %x) #0
  ret i32 %ret
}

; HSAIL-LABEL: {{^}}prog function &test_ufirstbit_i64(
; HSAIL: firstbit_u32_u64 {{\$s[0-9]+}}, {{\$d[0-9]+}};
define i32 @test_ufirstbit_i64(i64 %x) #0 {
  %ret = call i32 @llvm.hsail.ufirstbit.i64(i64 %x) #0
  ret i32 %ret
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_ufirstbit_i32(
; HSAIL: firstbit_u32_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_legacy_ufirstbit_i32(i32 %x) #0 {
  %ret = call i32 @llvm.HSAIL.firstbit.u32(i32 %x) #0
  ret i32 %ret
}

attributes #0 = { nounwind readnone }
