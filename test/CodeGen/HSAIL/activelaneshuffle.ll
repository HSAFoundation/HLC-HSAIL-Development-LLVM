; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

declare i32 @llvm.HSAIL.activelaneshuffle.b32.i32(i32, i32, i32, i1) nounwind
declare i64 @llvm.HSAIL.activelaneshuffle.b64.i64(i64, i32, i64, i1) nounwind

; FUNC-LABEL: {{^}}prog function &test_activelaneshuffle_b32
; HSAIL: activelaneshuffle_b32 {{\$s[0-9]+}}, 0, 0, 0, 0;
define void @test_activelaneshuffle_b32(i32 addrspace(1)* %out) nounwind {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.b32.i32(i32 0, i32 0, i32 0, i1 false) nounwind
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_activelaneshuffle_b64
; HSAIL: activelaneshuffle_b64 {{\$d[0-9]+}}, 0, 0, 0, 0;
define void @test_activelaneshuffle_b64(i64 addrspace(1)* %out) nounwind {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.b64.i64(i64 0, i32 0, i64 0, i1 false) nounwind
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}
