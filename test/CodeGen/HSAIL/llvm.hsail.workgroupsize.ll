; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

declare i32 @llvm.hsail.workgroupsize(i32) #0
declare i32 @llvm.HSAIL.workgroup.size(i32) #0

; FUNC-LABEL: {{^}}prog function &test_workgroupsize_0(
; HSAIL: workgroupsize_u32 {{\$s[0-9]+}}, 0;
define void @test_workgroupsize_0(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.hsail.workgroupsize(i32 0) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_workgroupsize_1(
; HSAIL: workgroupsize_u32 {{\$s[0-9]+}}, 1;
define void @test_workgroupsize_1(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.hsail.workgroupsize(i32 1) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_workgroupsize_2(
; HSAIL: workgroupsize_u32 {{\$s[0-9]+}}, 2;
define void @test_workgroupsize_2(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.hsail.workgroupsize(i32 2) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &legacy_workgroup_size_0(
; HSAIL: workgroupsize_u32 {{\$s[0-9]+}}, 0;
define void @legacy_workgroup_size_0(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.workgroup.size(i32 0) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &legacy_workgroup_size_1(
; HSAIL: workgroupsize_u32 {{\$s[0-9]+}}, 1;
define void @legacy_workgroup_size_1(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.workgroup.size(i32 1) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &legacy_workgroup_size_2(
; HSAIL: workgroupsize_u32 {{\$s[0-9]+}}, 2;
define void @legacy_workgroup_size_2(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.workgroup.size(i32 2) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
