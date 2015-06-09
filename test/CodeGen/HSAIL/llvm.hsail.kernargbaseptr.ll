; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL32 -check-prefix=HSAIL %s
; RUN: llc -march=hsail64 < %s | FileCheck -check-prefix=HSAIL64 -check-prefix=HSAIL %s

declare i8 addrspace(7)* @llvm.hsail.kernargbaseptr() #0

; HSAIL-LABEL: {{^}}prog function &test_kernargbaseptr(
; HSAIL32: kernargbaseptr_u32 [[PTR:\$s[0-9]+]];

; HSAIL64: kernargbaseptr_u64 [[PTR:\$d[0-9]+]];
define i8 addrspace(7)* @test_kernargbaseptr() #1 {
  %tmp0 = call i8 addrspace(7)* @llvm.hsail.kernargbaseptr() #0
  ret i8 addrspace(7)* %tmp0
}

; HSAIL-LABEL: {{^}}prog function &test_kernargbaseptr_load(
; HSAIL32: kernargbaseptr_u32 [[PTR:\$s[0-9]+]];
; HSAIL32: ld_kernarg_align(4)_u32 {{\$s[0-9]+}}, {{\[}}[[PTR]]{{\]}};

; HSAIL64: kernargbaseptr_u64 [[PTR:\$d[0-9]+]];
; HSAIL64: ld_kernarg_align(4)_u32 {{\$s[0-9]+}}, {{\[}}[[PTR]]{{\]}};
define i32 @test_kernargbaseptr_load() #1 {
  %tmp0 = call i8 addrspace(7)* @llvm.hsail.kernargbaseptr() #0
  %bc = bitcast i8 addrspace(7)* %tmp0 to i32 addrspace(7)*
  %load = load i32, i32 addrspace(7)* %bc
  ret i32 %load
}

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
