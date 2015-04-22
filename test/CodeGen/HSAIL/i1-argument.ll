; RUN: llc -debug -march=hsail -verify-machineinstrs < %s

; This hit an assert with -debug-only

; HSAIL: decl prog function &i1_sext_arg()(arg_u8 %x);
; HSAIL: decl prog function &i1_zext_arg()(arg_u8 %x);
; HSAIL: decl prog function &i1_arg()(arg_u8 %x);


; HSAIL: prog function &i1_sext_arg()(arg_u8 %x)
define void @i1_sext_arg(i1 signext %x) {
  ret void
}

; HSAIL: prog function &i1_zext_arg()(arg_u8 %x)
define void @i1_zext_arg(i1 zeroext %x) {
  ret void
}

; HSAIL: prog function &i1_arg()(arg_u8 %x)
define void @i1_arg(i1 %x) {
  ret void
}
