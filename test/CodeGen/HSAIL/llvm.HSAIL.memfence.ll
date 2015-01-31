; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &test_memfence_0(
; HSAIL: memfence_scar_global(wv);
define void @test_memfence_0(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 4, i32 2, i32 0, i32 0) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_1(
; HSAIL: memfence_scar_global(wg);
define void @test_memfence_1(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 4, i32 3, i32 0, i32 0) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_2(
; HSAIL: memfence_scar_global(cmp);
define void @test_memfence_2(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 4, i32 4, i32 0, i32 0) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_3(
; HSAIL: memfence_scar_global(sys);
define void @test_memfence_3(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 4, i32 5, i32 0, i32 0) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_4(
; HSAIL: memfence_scar_group(wv);
define void @test_memfence_4(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 4, i32 0, i32 2, i32 0) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_5(
; HSAIL: memfence_scar_group(wg);
define void @test_memfence_5(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 4, i32 0, i32 3, i32 0) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_6(
; HSAIL: memfence_scar_image(wi);
define void @test_memfence_6(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 4, i32 0, i32 0, i32 1) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_7(
; HSAIL: memfence_scar_image(wv);
define void @test_memfence_7(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 4, i32 0, i32 0, i32 2) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_8(
; HSAIL: memfence_scar_image(wg);
define void @test_memfence_8(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 4, i32 0, i32 0, i32 3) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_9(
; HSAIL: memfence_scar_global(wv)_group(wv);
define void @test_memfence_9(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 4, i32 2, i32 2, i32 0) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_10(
; HSAIL: memfence_scar_global(wg)_group(wv);
define void @test_memfence_10(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 4, i32 3, i32 2, i32 0) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_11(
; HSAIL: memfence_scar_global(wv)_group(wg);
define void @test_memfence_11(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 4, i32 2, i32 3, i32 0) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_12(
; HSAIL: memfence_scar_global(wg)_group(wg);
define void @test_memfence_12(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 4, i32 3, i32 3, i32 0) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_13(
; HSAIL: memfence_scar_global(cmp)_group(wg);
define void @test_memfence_13(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 4, i32 4, i32 3, i32 0) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_14(
; HSAIL: memfence_scar_global(sys)_group(wg);
define void @test_memfence_14(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 4, i32 5, i32 3, i32 0) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_15(
; HSAIL: memfence_screl_global(sys)_group(wg);
define void @test_memfence_15(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 3, i32 5, i32 3, i32 0) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_16(
; HSAIL: memfence_scacq_global(sys)_group(wg);
define void @test_memfence_16(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 2, i32 5, i32 3, i32 0) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_17(
; HSAIL: memfence_scacq_global(cmp)_group(wg);
define void @test_memfence_17(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 2, i32 4, i32 3, i32 0) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_18(
; HSAIL: memfence_scacq_group(wg);
define void @test_memfence_18(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 2, i32 0, i32 3, i32 0) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_19(
; HSAIL: memfence_scacq_group(wv);
define void @test_memfence_19(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 2, i32 0, i32 2, i32 0) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_20(
; HSAIL: memfence_screl_group(wv);
define void @test_memfence_20(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 3, i32 0, i32 2, i32 0) #1
  ret void
}

declare void @llvm.HSAIL.memfence(i32, i32, i32, i32) #1

attributes #1 = { nounwind noduplicate }
