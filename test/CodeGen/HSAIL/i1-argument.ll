; XFAIL: *
; RUN: llc -debug -march=hsail -verify-machineinstrs < %s

; This hits an assert with -debug-only
define void @i1_sext_arg(i1 signext %x) {
  ret void
}

define void @i1_zext_arg(i1 zeroext %x) {
  ret void
}

define void @i1_arg(i1 %x) {
  ret void
}
