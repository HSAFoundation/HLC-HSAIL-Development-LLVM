; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

declare i32 @llvm.hsail.gridsize.i32(i32) #0
declare i64 @llvm.hsail.gridsize.i64(i32) #0

declare i32 @llvm.HSAIL.get.global.size(i32) #0


; FUNC-LABEL: {{^}}prog function &test_gridsize_i32_0
; HSAIL: gridsize_u32 {{\$s[0-9]+}}, 0;
define void @test_gridsize_i32_0(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.hsail.gridsize.i32(i32 0) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_gridsize_i32_1
; HSAIL: gridsize_u32 {{\$s[0-9]+}}, 1;
define void @test_gridsize_i32_1(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.hsail.gridsize.i32(i32 1) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_gridsize_i32_2
; HSAIL: gridsize_u32 {{\$s[0-9]+}}, 2;
define void @test_gridsize_i32_2(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.hsail.gridsize.i32(i32 2) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_gridsize_i64_0
; HSAIL: gridsize_u64 {{\$d[0-9]+}}, 0;
define void @test_gridsize_i64_0(i64 addrspace(1)* %out) #1 {
  %tmp0 = call i64 @llvm.hsail.gridsize.i64(i32 0) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_gridsize_i64_1
; HSAIL: gridsize_u64 {{\$d[0-9]+}}, 1;
define void @test_gridsize_i64_1(i64 addrspace(1)* %out) #1 {
  %tmp0 = call i64 @llvm.hsail.gridsize.i64(i32 1) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_gridsize_i64_2
; HSAIL: gridsize_u64 {{\$d[0-9]+}}, 2;
define void @test_gridsize_i64_2(i64 addrspace(1)* %out) #1 {
  %tmp0 = call i64 @llvm.hsail.gridsize.i64(i32 2) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_legacy_gridsize_0
; HSAIL: gridsize_u32 {{\$s[0-9]+}}, 0;
define void @test_legacy_gridsize_0(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.global.size(i32 0) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_legacy_gridsize_1
; HSAIL: gridsize_u32 {{\$s[0-9]+}}, 1;
define void @test_legacy_gridsize_1(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.global.size(i32 1) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_legacy_gridsize_2
; HSAIL: gridsize_u32 {{\$s[0-9]+}}, 2;
define void @test_legacy_gridsize_2(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.global.size(i32 2) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }


