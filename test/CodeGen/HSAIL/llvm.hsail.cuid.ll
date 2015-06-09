; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

declare i32 @llvm.hsail.cuid() #0
declare i32 @llvm.HSAIL.get.cu() #1

; FUNC-LABEL: {{^}}prog function &test_cuid(
; HSAIL: cuid_u32 {{\$s[0-9]+}};
define void @test_cuid(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.hsail.cuid() #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_legacy_get_cu(
; HSAIL: cuid_u32 {{\$s[0-9]+}};
define void @test_legacy_get_cu(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.cu() #1
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
