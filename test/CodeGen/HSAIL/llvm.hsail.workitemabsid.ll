; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

declare i32 @llvm.hsail.workitemabsid.i32(i32) #0
declare i64 @llvm.hsail.workitemabsid.i64(i32) #0

declare i32 @llvm.HSAIL.get.global.id(i32) #0


; FUNC-LABEL: {{^}}prog function &test_workitemabsid_i32_0
; HSAIL: workitemabsid_u32 {{\$s[0-9]+}}, 0;
define void @test_workitemabsid_i32_0(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.hsail.workitemabsid.i32(i32 0) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_workitemabsid_i32_1
; HSAIL: workitemabsid_u32 {{\$s[0-9]+}}, 1;
define void @test_workitemabsid_i32_1(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.hsail.workitemabsid.i32(i32 1) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_workitemabsid_i32_2
; HSAIL: workitemabsid_u32 {{\$s[0-9]+}}, 2;
define void @test_workitemabsid_i32_2(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.hsail.workitemabsid.i32(i32 2) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_workitemabsid_i64_0
; HSAIL: workitemabsid_u64 {{\$d[0-9]+}}, 0;
define void @test_workitemabsid_i64_0(i64 addrspace(1)* %out) #1 {
  %tmp0 = call i64 @llvm.hsail.workitemabsid.i64(i32 0) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_workitemabsid_i64_1
; HSAIL: workitemabsid_u64 {{\$d[0-9]+}}, 1;
define void @test_workitemabsid_i64_1(i64 addrspace(1)* %out) #1 {
  %tmp0 = call i64 @llvm.hsail.workitemabsid.i64(i32 1) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_workitemabsid_i64_2
; HSAIL: workitemabsid_u64 {{\$d[0-9]+}}, 2;
define void @test_workitemabsid_i64_2(i64 addrspace(1)* %out) #1 {
  %tmp0 = call i64 @llvm.hsail.workitemabsid.i64(i32 2) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_legacy_workitemabsid_0
; HSAIL: workitemabsid_u32 {{\$s[0-9]+}}, 0;
define void @test_legacy_workitemabsid_0(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.global.id(i32 0) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_legacy_workitemabsid_1
; HSAIL: workitemabsid_u32 {{\$s[0-9]+}}, 1;
define void @test_legacy_workitemabsid_1(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.global.id(i32 1) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_legacy_workitemabsid_2
; HSAIL: workitemabsid_u32 {{\$s[0-9]+}}, 2;
define void @test_legacy_workitemabsid_2(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.global.id(i32 2) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }


