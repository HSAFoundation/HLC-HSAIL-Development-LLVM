; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL32 -check-prefix=HSAIL %s
; RUN: llc -march=hsail64 -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL64 -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &test_addrspacecast_global_to_flat(
; HSAIL32: ld_arg_align(4)_u32 [[PTR:\$s[0-9]]], [%ptr];
; HSAIL32-NEXT: st_arg_align(4)_u32 [[PTR]]

; HSAIL64: ld_arg_align(8)_u64 [[PTR:\$d[0-9]]], [%ptr];
; HSAIL64-NEXT: st_arg_align(8)_u64 [[PTR]]
define i8 addrspace(4)* @test_addrspacecast_global_to_flat(i8 addrspace(1)* %ptr) #0 {
  %val = addrspacecast i8 addrspace(1)* %ptr to i8 addrspace(4)*
  ret i8 addrspace(4)* %val
}

; HSAIL-LABEL: {{^}}prog function &test_addrspacecast_flat_to_global(
; HSAIL32: ld_arg_align(4)_u32 [[PTR:\$s[0-9]]], [%ptr];
; HSAIL32-NEXT: st_arg_align(4)_u32 [[PTR]]

; HSAIL64: ld_arg_align(8)_u64 [[PTR:\$d[0-9]]], [%ptr];
; HSAIL64-NEXT: st_arg_align(8)_u64 [[PTR]]
define i8 addrspace(1)* @test_addrspacecast_flat_to_global(i8 addrspace(4)* %ptr) #0 {
  %val = addrspacecast i8 addrspace(4)* %ptr to i8 addrspace(1)*
  ret i8 addrspace(1)* %val
}

; FIXME: Immediate should be stored directly
; HSAIL-LABEL: {{^}}prog function &test_addrspacecast_global_to_flat_null_imm(
; HSAIL32: mov_b32 [[ZERO:\$s[0-9]+]], 0;
; HSAIL32-NEXT: st_arg_align(4)_u32 [[ZERO]]

; HSAIL64: mov_b64 [[ZERO:\$d[0-9]+]], 0;
; HSAIL64: st_arg_align(8)_u64 [[ZERO]]
define i8 addrspace(4)* @test_addrspacecast_global_to_flat_null_imm() #0 {
  %val = addrspacecast i8 addrspace(1)* null to i8 addrspace(4)*
  ret i8 addrspace(4)* %val
}

; HSAIL-LABEL: {{^}}prog function &test_addrspacecast_global_to_flat_ptrtoint_inttoptr(
; HSAIL32: mov_b32 [[PTR:\$s[0-9]+]], 12345;
; HSAIL32-NEXT: st_arg_align(4)_u32 [[PTR]]

; HSAIL64: mov_b64 [[PTR:\$d[0-9]+]], 12345;
; HSAIL64-NEXT: st_arg_align(8)_u64 [[PTR]]
define i8 addrspace(4)* @test_addrspacecast_global_to_flat_ptrtoint_inttoptr() #0 {
  %ptr = inttoptr i32 12345 to i8 addrspace(1)*
  %val = addrspacecast i8 addrspace(1)* %ptr to i8 addrspace(4)*
  ret i8 addrspace(4)* %val
}

; HSAIL-LABEL: {{^}}prog function &test_addrspacecast_flat_to_global_inttoptr(
; HSAIL32: mov_b32 [[PTR:\$s[0-9]+]], 12345;
; HSAIL32-NEXT: st_arg_align(4)_u32 [[PTR]]

; HSAIL64: mov_b64 [[PTR:\$d[0-9]+]], 12345;
; HSAIL64-NEXT: st_arg_align(8)_u64 [[PTR]]
define i8 addrspace(1)* @test_addrspacecast_flat_to_global_inttoptr() #0 {
  %ptr = inttoptr i32 12345 to i8 addrspace(4)*
  %val = addrspacecast i8 addrspace(4)* %ptr to i8 addrspace(1)*
  ret i8 addrspace(1)* %val
}

; HSAIL-LABEL: {{^}}prog function &test_addrspacecast_flat_to_global_null_imm(
; HSAIL32: mov_b32 [[PTR:\$s[0-9]+]], 0;
; HSAIL32-NEXT: st_arg_align(4)_u32 [[PTR]]

; HSAIL64: mov_b64 [[PTR:\$d[0-9]+]], 0;
; HSAIL64-NEXT: st_arg_align(8)_u64 [[PTR]]
define i8 addrspace(1)* @test_addrspacecast_flat_to_global_null_imm() #0 {
  %val = addrspacecast i8 addrspace(4)* null to i8 addrspace(1)*
  ret i8 addrspace(1)* %val
}

; HSAIL-LABEL: {{^}}prog function &test_addrspacecast_group_to_flat(
; HSAIL32: ld_arg_align(4)_u32 [[PTR:\$s[0-9]]], [%ptr];
; HSAIL32: stof_group_u32_u32 [[CAST:\$s[0-9]+]], [[PTR]];
; HSAIL32: st_arg_align(4)_u32 [[CAST]]

; HSAIL64: ld_arg_align(4)_u32 [[PTR:\$s[0-9]]], [%ptr];
; HSAIL64: stof_group_u64_u32 [[CAST:\$d[0-9]+]], [[PTR]];
; HSAIL64: st_arg_align(8)_u64 [[CAST]]
define i8 addrspace(4)* @test_addrspacecast_group_to_flat(i8 addrspace(3)* %ptr) #0 {
  %val = addrspacecast i8 addrspace(3)* %ptr to i8 addrspace(4)*
  ret i8 addrspace(4)* %val
}

; HSAIL-LABEL: {{^}}prog function &test_addrspacecast_flat_to_group(
; HSAIL32: ld_arg_align(4)_u32 [[PTR:\$s[0-9]]], [%ptr];
; HSAIL32: ftos_group_u32_u32 [[CAST:\$s[0-9]+]], [[PTR]];
; HSAIL32: st_arg_align(4)_u32 [[CAST]]

; HSAIL64: ld_arg_align(8)_u64 [[PTR:\$d[0-9]]], [%ptr];
; HSAIL64: ftos_group_u32_u64 [[CAST:\$s[0-9]+]], [[PTR]];
; HSAIL64: st_arg_align(4)_u32 [[CAST]]
define i8 addrspace(3)* @test_addrspacecast_flat_to_group(i8 addrspace(4)* %ptr) #0 {
  %val = addrspacecast i8 addrspace(4)* %ptr to i8 addrspace(3)*
  ret i8 addrspace(3)* %val
}

; HSAIL-LABEL: {{^}}prog function &test_addrspacecast_private_to_flat(
; HSAIL32: ld_arg_align(4)_u32 [[PTR:\$s[0-9]]], [%ptr];
; HSAIL32: stof_private_u32_u32 [[CAST:\$s[0-9]+]], [[PTR]];
; HSAIL32: st_arg_align(4)_u32 [[CAST]]

; HSAIL64: ld_arg_align(4)_u32 [[PTR:\$s[0-9]]], [%ptr];
; HSAIL64: stof_private_u64_u32 [[CAST:\$d[0-9]+]], [[PTR]];
; HSAIL64: st_arg_align(8)_u64 [[CAST]]
define i8 addrspace(4)* @test_addrspacecast_private_to_flat(i8* %ptr) #0 {
  %val = addrspacecast i8* %ptr to i8 addrspace(4)*
  ret i8 addrspace(4)* %val
}

; HSAIL-LABEL: {{^}}prog function &test_addrspacecast_flat_to_private(
; HSAIL32: ld_arg_align(4)_u32 [[PTR:\$s[0-9]]], [%ptr];
; HSAIL32: ftos_private_u32_u32 [[CAST:\$s[0-9]+]], [[PTR]];
; HSAIL32: st_arg_align(4)_u32 [[CAST]]

; HSAIL64: ld_arg_align(8)_u64 [[PTR:\$d[0-9]]], [%ptr];
; HSAIL64: ftos_private_u32_u64 [[CAST:\$s[0-9]+]], [[PTR]];
; HSAIL64: st_arg_align(4)_u32 [[CAST]]
define i8* @test_addrspacecast_flat_to_private(i8 addrspace(4)* %ptr) #0 {
  %val = addrspacecast i8 addrspace(4)* %ptr to i8*
  ret i8* %val
}

attributes #0 = { nounwind readnone }
