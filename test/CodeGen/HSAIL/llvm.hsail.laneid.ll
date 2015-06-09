; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

declare i32 @llvm.hsail.laneid() #0
declare i32 @llvm.HSAIL.get.lane.id() #0

; FUNC-LABEL: {{^}}prog function &test_laneid(
; HSAIL: laneid_u32 {{\$s[0-9]+}};
define void @test_laneid(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.hsail.laneid() #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_legacy_get_laneid(
; HSAIL: laneid_u32 {{\$s[0-9]+}};
define void @test_legacy_get_laneid(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.lane.id() #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
