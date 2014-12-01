; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -strict-whitespace -check-prefix=DEFAULT32 %s
; RUN: llc -march=hsail64 -verify-machineinstrs < %s | FileCheck -strict-whitespace -check-prefix=DEFAULT64 %s

; DEFAULT32: {{^}}version 0:20140528:$full:$small;
; DEFAULT64: {{^}}version 0:20140528:$full:$large;

define void @empty_func() {
  ret void
}
