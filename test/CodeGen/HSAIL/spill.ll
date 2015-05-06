; RUN: llc -O0 -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &test_spill_branch_add
; HSAIL: {
; HSAIL: align(4) spill_u8 %__spillStack[12];
; HSAIL-DAG: ld_arg_align(4)_u32 [[IN:\$s[0-9]+]], [%in];
; HSAIL-DAG: ld_arg_align(4)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL-DAG: ld_global_align(4)_u32 [[A:\$s[0-9]+]], {{\[}}[[IN]]{{\]}};
; HSAIL-DAG: ld_global_align(4)_u32 [[B:\$s[0-9]+]], {{\[}}[[IN]]+4{{\]}};
; HSAIL-DAG: st_spill_align(4)_u32 [[A]], [%__spillStack];
; HSAIL-DAG: st_spill_align(4)_u32 [[B]], [%__spillStack][8];
; HSAIL-DAG: st_spill_align(4)_u32 [[OUT]], [%__spillStack][4];
; HSAIL: br @BB0_1;

; HSAIL: @BB0_1:
; HSAIL-DAG: ld_spill_align(4)_u32 [[A_RELOAD:\$s[0-9]+]], [%__spillStack];
; HSAIL-DAG: ld_spill_align(4)_u32 [[B_RELOAD:\$s[0-9]+]], [%__spillStack][8];
; HSAIL-DAG: ld_spill_align(4)_u32 [[OUT_RELOAD:\$s[0-9]+]], [%__spillStack][4];
; HSAIL-DAG: add_u32 [[RESULT:\$s[0-9]+]], [[A_RELOAD]], [[B_RELOAD]];
; HSAIL: st_global_align(4)_u32 [[RESULT]], {{\[}}[[OUT_RELOAD]]{{\]}};
; HSAIL: ret;
define void @test_spill_branch_add(i32 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %b_ptr = getelementptr i32 addrspace(1)* %in, i32 1
  %a = load i32 addrspace(1)* %in
  %b = load i32 addrspace(1)* %b_ptr
  br label %bb

bb:
  %result = add i32 %a, %b
  store i32 %result, i32 addrspace(1)* %out
  ret void
}
