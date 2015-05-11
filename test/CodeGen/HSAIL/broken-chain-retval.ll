; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; This should work correctly, but the chain is somehow messed up when
; this is a return value. This incorrect selects if the intrinsic is
; marked readonly.

declare i32 @llvm.HSAIL.activelaneid.u32() #0

; HSAIL-LABEL: {{^}}prog function &test_activelaneid_u32(
; HSAIL: activelaneid_u32 {{\$s[0-9]+}};
define i32 @test_activelaneid_u32() #0 {
  %tmp = call i32 @llvm.HSAIL.activelaneid.u32() #0
  ret i32 %tmp
}

attributes #0 = { nounwind }
