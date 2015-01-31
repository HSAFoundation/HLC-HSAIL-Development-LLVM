; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.HSAIL.activelaneid.u32() #0
declare i32 @llvm.HSAIL.activelaneid.width.u32() #0

; HSAIL-LABEL: {{^}}prog function &test_activelaneid_u32(
; HSAIL: activelaneid_u32 {{\$s[0-9]+}};
define void @test_activelaneid_u32(i32 addrspace(1)* %out) #0 {
  %tmp = call i32 @llvm.HSAIL.activelaneid.u32() #0
  store i32 %tmp, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneid_width_u32(
; HSAIL: activelaneid_width(WAVESIZE)_u32 {{\$s[0-9]+}};
define void @test_activelaneid_width_u32(i32 addrspace(1)* %out) #0 {
  %tmp = call i32 @llvm.HSAIL.activelaneid.width.u32() #0
  store i32 %tmp, i32 addrspace(1)* %out
  ret void
}

attributes #0 = { nounwind }
