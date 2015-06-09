; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &test_wavebarrier(
; HSAIL: wavebarrier;
define void @test_wavebarrier(i32 addrspace(1)* %out) #0 {
  call void @llvm.hsail.wavebarrier() #0
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_wavebarrier(
; HSAIL: wavebarrier;
define void @test_legacy_wavebarrier(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.wavebarrier() #1
  ret void
}

declare void @llvm.hsail.wavebarrier() #0
declare void @llvm.HSAIL.wavebarrier() #1

attributes #0 = { nounwind noduplicate convergent }
attributes #1 = { nounwind noduplicate }
