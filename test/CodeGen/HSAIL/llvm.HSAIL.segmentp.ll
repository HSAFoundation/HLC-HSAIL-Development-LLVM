; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL32 -check-prefix=HSAIL %s
; RUN: llc -march=hsail64 -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL64 -check-prefix=HSAIL %s

declare i1 @llvm.HSAIL.segmentp.global.p4i8(i8 addrspace(4)*) #0
declare i1 @llvm.HSAIL.segmentp.local.p4i8(i8 addrspace(4)*) #0
declare i1 @llvm.HSAIL.segmentp.private.p4i8(i8 addrspace(4)*) #0

; HSAIL-LABEL: {{^}}prog function &test_segmentp_global(
; HSAIL32: segmentp_global_b1_u32 {{\$c[0-9]+}}, {{\$s[0-9]+}};
; HSAIL64: segmentp_global_b1_u64 {{\$c[0-9]+}}, {{\$d[0-9]+}};
define i32 @test_segmentp_global(i8 addrspace(4)* %ptr) #0 {
  %val = call i1 @llvm.HSAIL.segmentp.global.p4i8(i8 addrspace(4)* %ptr) #0
  %ext = sext i1 %val to i32
  ret i32 %ext
}

; HSAIL-LABEL: {{^}}prog function &test_segmentp_local(
; HSAIL32: segmentp_group_b1_u32 {{\$c[0-9]+}}, {{\$s[0-9]+}};
; HSAIL64: segmentp_group_b1_u64 {{\$c[0-9]+}}, {{\$d[0-9]+}};
define i32 @test_segmentp_local(i8 addrspace(4)* %ptr) #0 {
  %val = call i1 @llvm.HSAIL.segmentp.local.p4i8(i8 addrspace(4)* %ptr) #0
  %ext = sext i1 %val to i32
  ret i32 %ext
}

; HSAIL-LABEL: {{^}}prog function &test_segmentp_private(
; HSAIL32: segmentp_private_b1_u32 {{\$c[0-9]+}}, {{\$s[0-9]+}};
; HSAIL64: segmentp_private_b1_u64 {{\$c[0-9]+}}, {{\$d[0-9]+}};
define i32 @test_segmentp_private(i8 addrspace(4)* %ptr) #0 {
  %val = call i1 @llvm.HSAIL.segmentp.private.p4i8(i8 addrspace(4)* %ptr) #0
  %ext = sext i1 %val to i32
  ret i32 %ext
}

; HSAIL-LABEL: {{^}}prog function &test_segmentp_global_imm(
; HSAIL32: segmentp_global_b1_u32 {{\$c[0-9]+}}, 12345;
; HSAIL64: segmentp_global_b1_u64 {{\$c[0-9]+}}, 12345;
define i32 @test_segmentp_global_imm() #0 {
  %ptr = inttoptr i32 12345 to i8 addrspace(4)*
  %val = call i1 @llvm.HSAIL.segmentp.global.p4i8(i8 addrspace(4)* %ptr) #0
  %ext = sext i1 %val to i32
  ret i32 %ext
}

; HSAIL-LABEL: {{^}}prog function &test_segmentp_local_imm(
; HSAIL32: segmentp_group_b1_u32 {{\$c[0-9]+}}, 12345;
; HSAIL64: segmentp_group_b1_u64 {{\$c[0-9]+}}, 12345;
define i32 @test_segmentp_local_imm() #0 {
  %ptr = inttoptr i32 12345 to i8 addrspace(4)*
  %val = call i1 @llvm.HSAIL.segmentp.local.p4i8(i8 addrspace(4)* %ptr) #0
  %ext = sext i1 %val to i32
  ret i32 %ext
}

; HSAIL-LABEL: {{^}}prog function &test_segmentp_private_imm(
; HSAIL32: segmentp_private_b1_u32 {{\$c[0-9]+}}, 12345;
; HSAIL64: segmentp_private_b1_u64 {{\$c[0-9]+}}, 12345;
define i32 @test_segmentp_private_imm() #0 {
  %ptr = inttoptr i32 12345 to i8 addrspace(4)*
  %val = call i1 @llvm.HSAIL.segmentp.private.p4i8(i8 addrspace(4)* %ptr) #0
  %ext = sext i1 %val to i32
  ret i32 %ext
}

attributes #0 = { nounwind readnone}
