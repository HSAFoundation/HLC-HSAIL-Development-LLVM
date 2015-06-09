; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

declare i64 @llvm.hsail.packetid() #0

; FUNC-LABEL: {{^}}prog function &test_packetid(
; HSAIL: packetid_u64 {{\$d[0-9]+}};
define void @test_packetid(i64 addrspace(1)* %out) #1 {
  %tmp0 = call i64 @llvm.hsail.packetid() #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
