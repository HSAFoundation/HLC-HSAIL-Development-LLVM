; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &test_imagefence(
; HSAIL: imagefence;
define void @test_imagefence() #0 {
  call void @llvm.HSAIL.imagefence() #0
  ret void
}
declare void @llvm.HSAIL.imagefence() #0

attributes #1 = { nounwind }
