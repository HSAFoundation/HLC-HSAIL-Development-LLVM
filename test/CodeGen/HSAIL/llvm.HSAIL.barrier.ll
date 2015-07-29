; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &test_barrier_0(
; HSAIL: barrier;
; HSAIL-NEXT: ret;
define void @test_barrier_0(i32 addrspace(1)* %out) #1 {
  call void @llvm.HSAIL.barrier() #1
  ret void
}

declare void @llvm.HSAIL.wavebarrier() #1

; HSAIL-LABEL: {{^}}prog function &test_barrier_1(
; HSAIL: st_global_align(4)_u32
; HSAIL: barrier;
; HSAIL: ld_global_align(4)_u32
define void @test_barrier_1(i32 addrspace(1)* %out) #1 {
  %tmp = call i32 @llvm.HSAIL.get.global.id(i32 0)
  %tmp1 = getelementptr i32 addrspace(1)* %out, i32 %tmp
  store i32 %tmp, i32 addrspace(1)* %tmp1
  call void @llvm.HSAIL.barrier() #1
  %tmp2 = call i32 @llvm.HSAIL.workgroup.size(i32 0) #0
  %tmp3 = sub i32 %tmp2, 1
  %tmp4 = sub i32 %tmp3, %tmp
  %tmp5 = getelementptr i32 addrspace(1)* %out, i32 %tmp4
  %tmp6 = load i32 addrspace(1)* %tmp5
  store i32 %tmp6, i32 addrspace(1)* %tmp1
  ret void
}

declare void @llvm.HSAIL.barrier() #1

; Function Attrs: nounwind readnone
declare i32 @llvm.HSAIL.get.global.id(i32) #0

; Function Attrs: nounwind readnone
declare i32 @llvm.HSAIL.workgroup.size(i32) #0

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind noduplicate }
