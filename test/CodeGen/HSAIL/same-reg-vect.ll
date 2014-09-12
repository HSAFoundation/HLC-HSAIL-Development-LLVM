; XFAIL: *
; Loads can be combined even if memory operands are different in case if base registers are the same.
; In this example two loads will have memory operands based on %a and %1 but still can be combined.
;
; RUN: llc < %s -march=hsail -filetype=asm | FileCheck %s
; CHECK: ld_v2

define spir_kernel void @func1(i8 addrspace(4)* nocapture %p, i32 addrspace(1)* nocapture %out) nounwind {
entry:
  %a = bitcast i8 addrspace(4)* %p to i32 addrspace(4)*
  %0 = load i32 addrspace(4)* %a, align 4
  %b = getelementptr inbounds i8 addrspace(4)* %p, i32 4
  %1 = bitcast i8 addrspace(4)* %b to i32 addrspace(4)*
  %2 = load i32 addrspace(4)* %1, align 4
  %add = add i32 %2, %0
  store i32 %add, i32 addrspace(1)* %out, align 4
  ret void
}
