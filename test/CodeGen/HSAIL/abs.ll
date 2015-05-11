; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &test_xor_abs_pat_i32(
; HSAIL: ld_arg_align(4)_u32 [[VAL:\$s[0-9]+]], [%x];
; HSAIL: abs_s32 [[ABS:\$s[0-9]+]], [[VAL]];
; HSAIL: st_arg_align(4)_u32 [[ABS]]
define i32 @test_xor_abs_pat_i32(i32 %x) #0 {
  %sra = ashr i32 %x, 31
  %add = add i32 %sra, %x
  %xor = xor i32 %sra, %add
  ret i32 %xor
}

; HSAIL-LABEL: {{^}}prog function &test_xor_abs_pat_i64(
; HSAIL: ld_arg_align(8)_u64 [[VAL:\$d[0-9]+]], [%x];
; HSAIL: abs_s64 [[ABS:\$d[0-9]+]], [[VAL]];
; HSAIL: st_arg_align(8)_u64 [[ABS]]
define i64 @test_xor_abs_pat_i64(i64 %x) #0 {
  %sra = ashr i64 %x, 63
  %add = add i64 %sra, %x
  %xor = xor i64 %sra, %add
  ret i64 %xor
}

attributes #0 = { nounwind readnone }
