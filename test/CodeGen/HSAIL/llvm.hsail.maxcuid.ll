; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

declare i32 @llvm.hsail.maxcuid() #0

; FUNC-LABEL: {{^}}prog function &test_maxcuid(
; HSAIL: maxcuid_u32 {{\$s[0-9]+}};
define void @test_maxcuid(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.hsail.maxcuid() #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
