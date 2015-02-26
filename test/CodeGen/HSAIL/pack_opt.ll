; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &test_pack_opt(
; HSAIL: ld_arg_align(4)_u32 [[SRC:\$s[0-9]+]], [%src];
; HSAIL: pack_u32x2_u32 [[DEST:\$d[0-9]+]], u32x2(0,0), [[SRC]], 1;
; HSAIL: st_arg_align(8)_u64 [[DEST]]
define i64 @test_pack_opt(i32 %src) #0 {
  %tmp1 = zext i32 %src to i64
  %result = shl i64 %tmp1, 32
  ret i64 %result
}

attributes #0 = { nounwind readnone }
