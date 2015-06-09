; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s
; RUN: llc -march=hsail64 < %s | FileCheck -check-prefix=HSAIL %s

declare i8 addrspace(3)* @llvm.hsail.groupbaseptr() #0

; HSAIL-LABEL: {{^}}prog function &test_groupbaseptr(
; HSAIL: groupbaseptr_u32 [[PTR:\$s[0-9]+]];
define i8 addrspace(3)* @test_groupbaseptr() #1 {
  %tmp0 = call i8 addrspace(3)* @llvm.hsail.groupbaseptr() #0
  ret i8 addrspace(3)* %tmp0
}

; HSAIL-LABEL: {{^}}prog function &test_groupbaseptr_load(
; HSAIL: groupbaseptr_u32 [[PTR:\$s[0-9]+]];
; HSAIL: ld_group_align(4)_u32 {{\$s[0-9]+}}, {{\[}}[[PTR]]{{\]}};
define i32 @test_groupbaseptr_load() #1 {
  %tmp0 = call i8 addrspace(3)* @llvm.hsail.groupbaseptr() #0
  %bc = bitcast i8 addrspace(3)* %tmp0 to i32 addrspace(3)*
  %load = load i32, i32 addrspace(3)* %bc
  ret i32 %load
}

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
