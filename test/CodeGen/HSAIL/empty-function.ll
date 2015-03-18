; XFAIL: *
; RUN: llc -march=hsail < %s
; XUN: llc -disable-validator -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &empty_func_void()()
; HSAIL-NEXT: {
; HSAIL: @empty_func_void_entry:
; HSAIL: };
define void @empty_func_void() {
  unreachable
}

; HSAIL-LABEL: {{^}}prog kernel &empty_kernel_void()
; HSAIL-NEXT: {
; HSAIL: @empty_kernel_void_entry:
; HSAIL: };
define spir_kernel void @empty_kernel_void() {
  unreachable
}

; HSAIL-LABEL: {{^}}prog function &empty_func_with_return_type()()
; HSAIL-NEXT: {
; HSAIL: };
define float @empty_func_with_return_type() {
  unreachable
}
