; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -strict-whitespace -check-prefix=HSAIL %s

declare i32 @foo(i32 %x) #0

; HSAIL-LABEL: {{^}}prog function &call_foo(arg_u32 %call_foo)()
; HSAIL-NEXT: {{^}}{
; HSAIL: {{^}}	mov_b32	$s0, 123;
; HSAIL: {{^}}	{
; HSAIL-NEXT: {{^}}		arg_u32 %foo;
; HSAIL-NEXT: {{^}}		arg_u32 %x;
; HSAIL-NEXT: {{^}}		st_arg_align(4)_u32	$s0, [%x];
; HSAIL-NEXT: {{^}}		call	&foo (%foo) (%x);
; HSAIL-NEXT: {{^}}		ld_arg_align(4)_u32	$s0, [%foo];
; HSAIL-NEXT: {{^}}	}
; HSAIL-NEXT: {{^}}	st_arg_align(4)_u32	$s0, [%call_foo];
; HSAIL-NEXT: {{^}}	ret;
; HSAIL-NEXT:{{^}}};
define i32 @call_foo() #0 {
  %ret = call i32 @foo(i32 123) #0
  ret i32 %ret
}


attributes #0 = { nounwind }
