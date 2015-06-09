; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

declare i32 @llvm.hsail.workitemflatabsid.i32() #0
declare i64 @llvm.hsail.workitemflatabsid.i64() #0

declare i32 @llvm.HSAIL.workitemid.flatabs() #0

; FUNC-LABEL: {{^}}prog function &test_workitemflatabsid_i32(
; HSAIL: workitemflatabsid_u32 {{\$s[0-9]+}};
define void @test_workitemflatabsid_i32(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.hsail.workitemflatabsid.i32() #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_workitemflatabsid_i64(
; HSAIL: workitemflatabsid_u64 {{\$d[0-9]+}};
define void @test_workitemflatabsid_i64(i64 addrspace(1)* %out) #1 {
  %tmp0 = call i64 @llvm.hsail.workitemflatabsid.i64() #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_legacy_workitemid_flatabs(
; HSAIL: workitemflatabsid_u32 {{\$s[0-9]+}};
define void @test_legacy_workitemid_flatabs(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.workitemid.flatabs() #1
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
