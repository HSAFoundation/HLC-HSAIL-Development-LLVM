; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &jump_table(
; HSAIL: cbr_b1 $c{{[0-9]+}}, @BB0_{{[0-9]+}};
; HSAIL: cbr_b1 $c{{[0-9]+}}, @BB0_{{[0-9]+}};
; HSAIL: cbr_b1 $c{{[0-9]+}}, @BB0_{{[0-9]+}};
; HSAIL: br @BB0_{{[0-9]+}}
; HSAIL: cbr_b1 $c{{[0-9]+}}, @BB0_{{[0-9]+}};
; HSAIL: cbr_b1 $c{{[0-9]+}}, @BB0_{{[0-9]+}};
; HSAIL: br @BB0_{{[0-9]+}}
define void @jump_table(i32 %x) {
entry:
  switch i32 %x, label %return [
    i32 3, label %bb0
    i32 1, label %bb1
    i32 4, label %bb1
    i32 5, label %bb2
  ]

bb0:
  store volatile i32 0, i32 addrspace(1)* undef
  br label %return

bb1:
  store volatile i32 1, i32 addrspace(1)* undef
  br label %return

bb2:
  store volatile i32 2, i32 addrspace(1)* undef
  br label %return

return:
   ret void
}
