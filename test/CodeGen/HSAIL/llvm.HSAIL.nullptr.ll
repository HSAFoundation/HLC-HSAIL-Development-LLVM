; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL32 -check-prefix=HSAIL %s
; RUN: llc -march=hsail64 -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL64 -check-prefix=HSAIL %s

declare i8* @llvm.HSAIL.nullptr.private() #0
declare i8 addrspace(1)* @llvm.HSAIL.nullptr.global.p1i8() #0
declare i8 addrspace(2)* @llvm.HSAIL.nullptr.readonly.p2i8() #0
declare i8 addrspace(3)* @llvm.HSAIL.nullptr.group() #0
declare i8 addrspace(4)* @llvm.HSAIL.nullptr.flat.p4i8() #0
declare i8 addrspace(7)* @llvm.HSAIL.nullptr.kernarg.p7i8() #0


; HSAIL-LABEL: {{^}}prog function &test_nullptr_private(
; HSAIL: nullptr_private_u32 {{\$s[0-9]+}};
define i8* @test_nullptr_private() #0 {
  %val = call i8* @llvm.HSAIL.nullptr.private() #0
  ret i8* %val
}

; HSAIL-LABEL: {{^}}prog function &test_nullptr_global(
; HSAIL32: nullptr_u32 {{\$s[0-9]+}};
; HSAIL64: nullptr_u64 {{\$d[0-9]+}};
define i8 addrspace(1)* @test_nullptr_global() #0 {
  %val = call i8 addrspace(1)* @llvm.HSAIL.nullptr.global.p1i8() #0
  ret i8 addrspace(1)* %val
}

; HSAIL-LABEL: {{^}}prog function &test_nullptr_readonly(
; HSAIL32: nullptr_u32 {{\$s[0-9]+}};
; HSAIL64: nullptr_u64 {{\$d[0-9]+}};
define i8 addrspace(2)* @test_nullptr_readonly() #0 {
  %val = call i8 addrspace(2)* @llvm.HSAIL.nullptr.readonly.p2i8() #0
  ret i8 addrspace(2)* %val
}

; HSAIL-LABEL: {{^}}prog function &test_nullptr_group(
; HSAIL: nullptr_group_u32 {{\$s[0-9]+}};
define i8 addrspace(3)* @test_nullptr_group() #0 {
  %val = call i8 addrspace(3)* @llvm.HSAIL.nullptr.group() #0
  ret i8 addrspace(3)* %val
}

; HSAIL-LABEL: {{^}}prog function &test_nullptr_flat(
; HSAIL32: nullptr_u32 {{\$s[0-9]+}};
; HSAIL64: nullptr_u64 {{\$d[0-9]+}};
define i8 addrspace(4)* @test_nullptr_flat() #0 {
  %val = call i8 addrspace(4)* @llvm.HSAIL.nullptr.flat.p4i8() #0
  ret i8 addrspace(4)* %val
}


; HSAIL-LABEL: {{^}}prog function &test_nullptr_kernarg(
; HSAIL32: nullptr_kernarg_u32 {{\$s[0-9]+}};
; HSAIL64: nullptr_kernarg_u64 {{\$d[0-9]+}};
define i8 addrspace(7)* @test_nullptr_kernarg() #0 {
  %val = call i8 addrspace(7)* @llvm.HSAIL.nullptr.kernarg.p7i8() #0
  ret i8 addrspace(7)* %val
}

attributes #0 = { nounwind readnone }
