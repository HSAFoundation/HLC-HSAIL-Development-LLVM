; RUN: llc -march=hsail64 -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog kernel &no_align_on_kernarg(
; HSAIL-NOT: align(4)
; HSAIL: kernarg_u64
define spir_kernel void @no_align_on_kernarg(i32 addrspace(1)* %out) {
  store i32 999, i32 addrspace(1)* %out, align 4
  ret void
}
