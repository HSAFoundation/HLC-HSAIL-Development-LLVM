; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

declare i32 @llvm.hsail.workitemid(i32) #0
declare i32 @llvm.HSAIL.get.local.id(i32) #0

; FUNC-LABEL: {{^}}prog function &test_workitemid_0(
; HSAIL: workitemid_u32 {{\$s[0-9]+}}, 0;
define void @test_workitemid_0(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.hsail.workitemid(i32 0) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_workitemid_1(
; HSAIL: workitemid_u32 {{\$s[0-9]+}}, 1;
define void @test_workitemid_1(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.hsail.workitemid(i32 1) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_workitemid_2(
; HSAIL: workitemid_u32 {{\$s[0-9]+}}, 2;
define void @test_workitemid_2(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.hsail.workitemid(i32 2) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_legacy_get_local_id_0(
; HSAIL: workitemid_u32 {{\$s[0-9]+}}, 0;
define void @test_legacy_get_local_id_0(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.local.id(i32 0) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_legacy_get_local_id_1(
; HSAIL: workitemid_u32 {{\$s[0-9]+}}, 1;
define void @test_legacy_get_local_id_1(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.local.id(i32 1) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_legacy_get_local_id_2(
; HSAIL: workitemid_u32 {{\$s[0-9]+}}, 2;
define void @test_legacy_get_local_id_2(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.local.id(i32 2) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
