; RUN: llc -march=hsail < %s


; HSAIL: decl prog function &i1_sext_ret(arg_s32 %ret)();

; HSAIL: decl prog function &i1_zext_ret(arg_u32 %ret)();

; HSAIL-LABEL: {{^}}prog function &i1_sext_ret(arg_s32 %i1_sext_ret)()
; HSAIL: st_arg_u32	{{\$s[0-9]+}}, [%i1_sext_ret];
define signext i1 @i1_sext_ret() {
  ret i1 true
}

; HSAIL-LABL: {{^}}prog function &i1_zext_ret(arg_u32 %i1_zext_ret)()
; HSAIL: st_arg_u32	{{\$s[0-9]+}}, [%i1_zext_ret];
define zeroext i1 @i1_zext_ret() {
  ret i1 true
}

define zeroext i8 @i8_zext_ret() {
  ret i8 123
}

define zeroext i8 @i8_zext_ret_arg(i8 %x) {
  ret i8 %x
}
