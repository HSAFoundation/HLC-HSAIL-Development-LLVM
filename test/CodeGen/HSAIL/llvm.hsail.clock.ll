; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i64 @llvm.hsail.clock() #0
declare i64 @llvm.HSAIL.get.clock() #1

; HSAIL-LABEL: {{^}}prog function &test_clock(
; HSAIL: clock_u64 {{\$d[0-9]+}};
define void @test_clock(i64 addrspace(1)* %out) #0 {
  %tmp0 = call i64 @llvm.hsail.clock() #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_clock(
; HSAIL: clock_u64 {{\$d[0-9]+}};
define void @test_legacy_clock(i64 addrspace(1)* %out) #0 {
  %tmp0 = call i64 @llvm.HSAIL.get.clock() #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

attributes #0 = { nounwind }
