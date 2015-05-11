; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL: decl prog function &foo0(arg_u32 %ret)(arg_u32 %arg_p0);

; HSAIL: decl prog function &foo1(arg_u32 %ret)(
; HSAIL-NEXT: arg_u32 %arg_p0,
; HSAIL-NEXT: arg_u32 %arg_p1);

; HSAIL: decl prog function &foo2(arg_u32 %ret)(
; HSAIL-NEXT: arg_u32 %arg_p0,
; HSAIL-NEXT: arg_u32 %x,
; HSAIL-NEXT: arg_u32 %arg_p2);

; HSAIL: decl prog function &foo3(arg_u32 %ret)(
; HSAIL-NEXT: arg_u32 %arg_p0,
; HSAIL-NEXT: arg_u32 %x,
; HSAIL-NEXT: arg_u32 %arg_p2,
; HSAIL-NEXT: arg_u32 %y);


; HSAIL-LABEL: {{^}}prog function &foo0(arg_u32 %foo0)(arg_u32 %__arg_p0)
; HSAIL-NEXT: {
define i32 @foo0(i32) nounwind {
  ret i32 %0
}

; HSAIL-LABEL: {{^}}prog function &foo1(arg_u32 %foo1)(
; HSAIL-NEXT: arg_u32 %__arg_p0,
; HSAIL-NEXT: arg_u32 %__arg_p1)
; HSAIL-NEXT: {
define i32 @foo1(i32, i32) nounwind {
  ret i32 %1
}

; HSAIL-LABEL: {{^}}prog function &foo2(arg_u32 %foo2)(
; HSAIL-NEXT: arg_u32 %__arg_p0,
; HSAIL-NEXT: arg_u32 %x,
; HSAIL-NEXT: arg_u32 %__arg_p2)
; HSAIL-NEXT: {
define i32 @foo2(i32, i32 %x, i32) nounwind {
  ret i32 %1
}

; HSAIL-LABEL: {{^}}prog function &foo3(arg_u32 %foo3)(
; HSAIL-NEXT: arg_u32 %__arg_p0,
; HSAIL-NEXT: arg_u32 %x,
; HSAIL-NEXT: arg_u32 %__arg_p2,
; HSAIL-NEXT: arg_u32 %y)
; HSAIL-NEXT: {
define i32 @foo3(i32, i32 %x, i32, i32 %y) nounwind {
  ret i32 %1
}
