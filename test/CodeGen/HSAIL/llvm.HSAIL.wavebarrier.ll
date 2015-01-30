; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &test_wavebarrier(
; HSAIL: wavebarrier;
define void @test_wavebarrier(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.wavebarrier() #1
  ret void
}

declare void @llvm.HSAIL.wavebarrier() #1

attributes #1 = { nounwind noduplicate }
