; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &test_memfence_0(
; HSAIL: memfence_scacq_wave;
define void @test_memfence_0(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 2, i32 2) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_1(
; HSAIL: memfence_scacq_wg;
define void @test_memfence_1(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 2, i32 3) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_2(
; HSAIL: memfence_scacq_agent;
define void @test_memfence_2(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 2, i32 4) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_3(
; HSAIL: memfence_scacq_system;
define void @test_memfence_3(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 2, i32 5) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_4(
; HSAIL: memfence_screl_wave;
define void @test_memfence_4(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 3, i32 2) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_5(
; HSAIL: memfence_screl_wg;
define void @test_memfence_5(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 3, i32 3) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_6(
; HSAIL: memfence_screl_agent;
define void @test_memfence_6(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 3, i32 4) #1
  ret void
}
; HSAIL-LABEL: {{^}}prog function &test_memfence_7(
; HSAIL: memfence_screl_system;
define void @test_memfence_7(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 3, i32 5) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_8(
; HSAIL: memfence_scar_wave;
define void @test_memfence_8(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 4, i32 2) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_9(
; HSAIL: memfence_scar_wg;
define void @test_memfence_9(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 4, i32 3) #1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_memfence_10(
; HSAIL: memfence_scar_agent;
define void @test_memfence_10(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 4, i32 4) #1
  ret void
}
; HSAIL-LABEL: {{^}}prog function &test_memfence_11(
; HSAIL: memfence_scar_system;
define void @test_memfence_11(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.memfence(i32 4, i32 5) #1
  ret void
}

declare void @llvm.HSAIL.memfence(i32, i32) #1

attributes #1 = { nounwind noduplicate }
