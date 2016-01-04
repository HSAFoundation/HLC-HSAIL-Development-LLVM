; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i64 @llvm.readcyclecounter() #0

; HSAIL-LABEL: {{^}}prog function &test_readcyclecounter(
; HSAIL: clock_u64 $d{{[0-9]+}}
; HSAIL: st_global_align(8)_u64
; HSAIL: clock_u64 $d{{[0-9]+}}
; HSAIL: st_global_align(8)_u64
define void @test_readcyclecounter(i64 addrspace(1)* %out) #0 {
  %cycle0 = call i64 @llvm.readcyclecounter()
  store volatile i64 %cycle0, i64 addrspace(1)* %out

  %cycle1 = call i64 @llvm.readcyclecounter()
  store volatile i64 %cycle1, i64 addrspace(1)* %out
  ret void
}

attributes #0 = { nounwind }
