; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL: decl prog function &empty()();
; HSAIL: decl prog function &empty_w_arg()(arg_u32 %x);

; HSAIL: decl prog function &empty_w_args()(
; HSAIL-NEXT: arg_u32 %x,
; HSAIL-NEXT: arg_u32 %y);

; HSAIL: decl prog function &unreachable_empty()();

; HSAIL: prog function &empty()()
; HSAIL: ret;
; HSAIL-NEXT: };
define void @empty() {
  ret void
}

; HSAIL: prog function &empty_w_arg()(arg_u32 %x)
define void @empty_w_arg(i32 %x) {
  ret void
}

; HSAIL: prog function &empty_w_args()(
; HSAIL-NEXT: arg_u32 %x,
; HSAIL-NEXT: arg_u32 %y)
define void @empty_w_args(i32 %x, i32 %y) {
  ret void
}

; HSAIL: prog function &unreachable_empty()()
; HSAIL-NOT: ret
; HSAIL: };
define void @unreachable_empty() {
  unreachable
}
