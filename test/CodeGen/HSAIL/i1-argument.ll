; XFAIL: *
; RUN: llc -debug -march=hsail -verify-machineinstrs < %s

; This hits an assert with -debug-only
define void @foo(i1 %x) {
  ret void
}