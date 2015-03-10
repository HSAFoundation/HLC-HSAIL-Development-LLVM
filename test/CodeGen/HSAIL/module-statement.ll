; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -strict-whitespace -check-prefix=DEFAULT32 %s
; RUN: llc -march=hsail64 -verify-machineinstrs < %s | FileCheck -strict-whitespace -check-prefix=DEFAULT64 %s

; DEFAULT32: {{^}}module &__llvm_hsail_module:1:0:$full:$small:$near;
; DEFAULT64: {{^}}module &__llvm_hsail_module:1:0:$full:$large:$near;

define void @empty_func() {
  ret void
}
