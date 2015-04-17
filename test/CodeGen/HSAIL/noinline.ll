; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL: {{^}}prog function &do_not_inline(
define i32 @do_not_inline() nounwind noinline {
  ret i32 123
}

; HSAIL: {{^}}prog function &caller()(arg_u32 %out)
; HSAIL: call &do_not_inline (%do_not_inline) ();
define void @caller(i32 addrspace(1)* %out) nounwind {
  %x = call i32 @do_not_inline() nounwind noinline
  store i32 %x, i32 addrspace(1)* %out
  ret void
}
