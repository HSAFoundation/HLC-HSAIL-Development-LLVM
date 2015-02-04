; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL32 -check-prefix=HSAIL %s
; RUN: llc -march=hsail64 -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL64 -check-prefix=HSAIL %s

; FIXME: Remove these intrinsics and implement addrspacecast.

declare i8 addrspace(4)* @llvm.HSAIL.addrspacecast.g2f.p1i8(i8 addrspace(1)*) #0
declare i8 addrspace(1)* @llvm.HSAIL.addrspacecast.f2g.p4i8(i8 addrspace(4)*) #0

declare i8 addrspace(4)* @llvm.HSAIL.addrspacecast.l2f.p3i8(i8 addrspace(3)*) #0
declare i8 addrspace(3)* @llvm.HSAIL.addrspacecast.f2l.p4i8(i8 addrspace(4)*) #0

; HSAIL-LABEL: {{^}}prog function &test_addrspacecast_global_to_flat(
; HSAIL32: ld_arg_align(4)_u32 [[PTR:\$s[0-9]]], [%ptr];
; HSAIL32: stof_global_u32_u32 [[CAST:\$s[0-9]+]], [[PTR]];
; HSAIL32: st_arg_align(4)_u32 [[CAST]]

; HSAIL64: ld_arg_align(8)_u64 [[PTR:\$d[0-9]]], [%ptr];
; HSAIL64: stof_global_u64_u64 [[CAST:\$d[0-9]+]], [[PTR]];
; HSAIL64: st_arg_align(8)_u64 [[CAST]]
define i8 addrspace(4)* @test_addrspacecast_global_to_flat(i8 addrspace(1)* %ptr) #0 {
  %val = call i8 addrspace(4)* @llvm.HSAIL.addrspacecast.g2f.p1i8(i8 addrspace(1)* %ptr) #0
  ret i8 addrspace(4)* %val
}

; HSAIL-LABEL: {{^}}prog function &test_addrspacecast_flat_to_global(
; HSAIL32: ld_arg_align(4)_u32 [[PTR:\$s[0-9]]], [%ptr];
; HSAIL32: ftos_global_u32_u32 [[CAST:\$s[0-9]+]], [[PTR]];
; HSAIL32: st_arg_align(4)_u32 [[CAST]]

; HSAIL64: ld_arg_align(8)_u64 [[PTR:\$d[0-9]]], [%ptr];
; HSAIL64: ftos_global_u64_u64 [[CAST:\$d[0-9]+]], [[PTR]];
; HSAIL64: st_arg_align(8)_u64 [[CAST]]
define i8 addrspace(1)* @test_addrspacecast_flat_to_global(i8 addrspace(4)* %ptr) #0 {
  %val = call i8 addrspace(1)* @llvm.HSAIL.addrspacecast.f2g.p4i8(i8 addrspace(4)* %ptr) #0
  ret i8 addrspace(1)* %val
}

; HSAIL-LABEL: {{^}}prog function &test_addrspacecast_global_to_group(
; HSAIL32: ld_arg_align(4)_u32 [[PTR:\$s[0-9]]], [%ptr];
; HSAIL32: stof_group_u32_u32 [[CAST:\$s[0-9]+]], [[PTR]];
; HSAIL32: st_arg_align(4)_u32 [[CAST]]

; HSAIL64: ld_arg_align(4)_u32 [[PTR:\$s[0-9]]], [%ptr];
; HSAIL64: stof_group_u64_u32 [[CAST:\$d[0-9]+]], [[PTR]];
; HSAIL64: st_arg_align(8)_u64 [[CAST]]
define i8 addrspace(4)* @test_addrspacecast_global_to_group(i8 addrspace(3)* %ptr) #0 {
  %val = call i8 addrspace(4)* @llvm.HSAIL.addrspacecast.l2f.p3i8(i8 addrspace(3)* %ptr) #0
  ret i8 addrspace(4)* %val
}

; HSAIL-LABEL: {{^}}prog function &test_addrspacecast_group_to_global(
; HSAIL32: ld_arg_align(4)_u32 [[PTR:\$s[0-9]]], [%ptr];
; HSAIL32: ftos_group_u32_u32 [[CAST:\$s[0-9]+]], [[PTR]];
; HSAIL32: st_arg_align(4)_u32 [[CAST]]

; HSAIL64: ld_arg_align(8)_u64 [[PTR:\$d[0-9]]], [%ptr];
; HSAIL64: ftos_group_u32_u64 [[CAST:\$s[0-9]+]], [[PTR]];
; HSAIL64: st_arg_align(4)_u32 [[CAST]]
define i8 addrspace(3)* @test_addrspacecast_group_to_global(i8 addrspace(4)* %ptr) #0 {
  %val = call i8 addrspace(3)* @llvm.HSAIL.addrspacecast.f2l.p4i8(i8 addrspace(4)* %ptr) #0
  ret i8 addrspace(3)* %val
}

attributes #0 = { nounwind readnone }
