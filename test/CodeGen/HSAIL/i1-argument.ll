; RUN: llc -debug -march=hsail -verify-machineinstrs < %s

; This hit an assert with -debug-only

; HSAIL: decl prog function &i1_sext_arg()(arg_u8 %x);
; HSAIL: decl prog function &i1_zext_arg()(arg_u8 %x);
; HSAIL: decl prog function &i1_arg()(arg_u8 %x);


; HSAIL-LABEL: prog function &i1_sext_arg()(arg_s8 %x)
; HSAIL: ld_arg_s8 {{\$s[0-9]+}}, [%x];
define i1 @i1_sext_arg(i1 signext %x) {
  ret i1 %x
}

; HSAIL-LABEL: prog function &i1_zext_arg()(arg_u8 %x)
; HSAIL: ld_arg_u8 {{\$s[0-9]+}}, [%x];
define i1 @i1_zext_arg(i1 zeroext %x) {
  ret i1 %x
}

; HSAIL-LABEL: prog function &i1_arg()(arg_u8 %x)
; HSAIL: ld_arg_u8 {{\$s[0-9]+}}, [%x];
define i1 @i1_arg(i1 %x) {
  ret i1 %x
}
