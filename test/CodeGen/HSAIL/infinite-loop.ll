; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &infinite_loop(
; HSAIL: ld_arg
; HSAIL: {{^@BB0_1:}}
; HSAIL: st_global_align(4)_u32
; HSAIL-NEXT: br @BB0_1
; HSAIL: };
define void @infinite_loop(i32 addrspace(1)* %out) {
entry:
  br label %for.body

for.body:                                         ; preds = %entry, %for.body
  store i32 999, i32 addrspace(1)* %out, align 4
  br label %for.body
}
