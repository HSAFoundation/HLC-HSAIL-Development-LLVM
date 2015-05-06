; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL: prog readonly_u32 &__unnamed_1[4] = u32[](5, 4, 432, 3);
; HSAIL: prog readonly_u32 &__unnamed_2[4] = u32[](1, 42, 432, 99);
; HSAIL: prog readonly_f32 &__unnamed_3[4] = f32[](0F3f800000, 0F40800000, 0F45800000, 0F41000000);


; HSAIL: decl prog function &__unnamed_4()(arg_u32 %arg_p0);
; HSAIL: decl prog function &__unnamed_5()();
; HSAIL: decl prog function &__unnamed_6()();
; HSAIL: decl prog function &call_alias()();
; HSAIL: decl prog function &__unnamed_7()();


@0 = addrspace(2) global [4 x i32] [ i32 5, i32 4, i32 432, i32 3 ]
@1 = addrspace(2) global [4 x i32] [ i32 1, i32 42, i32 432, i32 99 ]
@2 = addrspace(2) constant [4 x float] [ float 1.0, float 4.0, float 4096.0, float 8.0 ]

declare void @3(i32)

; HSAIL-LABEL: {{^}}prog function &foo()()
; HSAIL: call &__unnamed_4 () (%__param_p0);
define void @foo() {
 call void @3(i32 1)
 ret void
}

; HSAIL-LABEL: {{^}}prog function &__unnamed_5()()
; HSAIL: call &__unnamed_4 () (%__param_p0);
define void @4() {
 call void @3(i32 1)
 ret void
}

; HSAIL-LABEL: {{^}}prog function &__unnamed_6()()
; HSAIL: ret;
define void @5() {
  ret void
}

; HSAIL-LABEL: {{^}}prog kernel &__unnamed_8()
; HSAIL: ret;
define spir_kernel void @6() {
  ret void
}

@falias = alias void ()* @5

; HSAIL-LABEL: {{^}}prog function &call_alias()()
; HSAIL: call &falias () ();
define void @call_alias() nounwind {
  call void @falias()
  ret void
}

; HSAIL-LABEL: {{^}}prog function &__unnamed_7()()
; HSAIL: // BB#0: // %named_entry_block
; HSAIL: ret;
define void @7() {
named_entry_block:
  ret void
}
