; RUN: llc -O0 -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &test_spill_cond_reg
; HSAIL: {
; HSAIL: align(4) spill_u8 %__spillStack[36];
; HSAIL-DAG: cmp_eq_b1_s32 $c0
; HSAIL-DAG: cmp_eq_b1_s32 $c1
; HSAIL-DAG: cmp_eq_b1_s32 $c2
; HSAIL-DAG: cmp_eq_b1_s32 $c3
; HSAIL-DAG: cmp_eq_b1_s32 $c4
; HSAIL-DAG: cmp_eq_b1_s32 $c5
; HSAIL-DAG: cmp_eq_b1_s32 $c6
; HSAIL-DAG: cmp_eq_b1_s32 $c7
; HSAIL-DAG: cvt_u32_b1 [[CVT_C0:\$s[0-9]+]], $c0
; HSAIL-DAG: cvt_u32_b1 [[CVT_C1:\$s[0-9]+]], $c1
; HSAIL-DAG: cvt_u32_b1 [[CVT_C2:\$s[0-9]+]], $c2
; HSAIL-DAG: cvt_u32_b1 [[CVT_C3:\$s[0-9]+]], $c3
; HSAIL-DAG: cvt_u32_b1 [[CVT_C4:\$s[0-9]+]], $c4
; HSAIL-DAG: cvt_u32_b1 [[CVT_C5:\$s[0-9]+]], $c5
; HSAIL-DAG: cvt_u32_b1 [[CVT_C6:\$s[0-9]+]], $c6
; HSAIL-DAG: cvt_u32_b1 [[CVT_C7:\$s[0-9]+]], $c7
; HSAIL-DAG: st_spill_align(4)_u32 [[CVT_C0]], [%__spillStack];
; HSAIL-DAG: st_spill_align(4)_u32 [[CVT_C1]],
; HSAIL-DAG: st_spill_align(4)_u32 [[CVT_C2]],
; HSAIL-DAG: st_spill_align(4)_u32 [[CVT_C3]],
; HSAIL-DAG: st_spill_align(4)_u32 [[CVT_C4]],
; HSAIL-DAG: st_spill_align(4)_u32 [[CVT_C5]],
; HSAIL-DAG: st_spill_align(4)_u32 [[CVT_C6]],
; HSAIL-DAG: st_spill_align(4)_u32 [[CVT_C7]],

; HSAIL: br @BB0_1;

; HSAIL: @BB0_1:
; HSAIL-DAG: ld_spill_align(4)_u32 [[RELOAD_C0:\$s[0-9]+]], [%__spillStack];
; HSAIL-DAG: cvt_b1_u32 {{\$c[0-9]+}}, [[RELOAD_C0]]

; HSAIL-DAG: ld_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack];
; HSAIL-DAG: ld_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][4];
; HSAIL-DAG: ld_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][8];
; HSAIL-DAG: ld_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][12];
; HSAIL-DAG: ld_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][16];
; HSAIL-DAG: ld_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][20];
; HSAIL-DAG: ld_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][24];
; HSAIL-DAG: ld_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][28];
; HSAIL-DAG: ld_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][32];

; HSAIL-DAG: cvt_b1_u32 $c{{[0-9]+}}, $s{{[0-9]+}}
; HSAIL-DAG: cvt_b1_u32 $c{{[0-9]+}}, $s{{[0-9]+}}
; HSAIL-DAG: cvt_b1_u32 $c{{[0-9]+}}, $s{{[0-9]+}}
; HSAIL-DAG: cvt_b1_u32 $c{{[0-9]+}}, $s{{[0-9]+}}
; HSAIL-DAG: cvt_b1_u32 $c{{[0-9]+}}, $s{{[0-9]+}}
; HSAIL-DAG: cvt_b1_u32 $c{{[0-9]+}}, $s{{[0-9]+}}
; HSAIL-DAG: cvt_b1_u32 $c{{[0-9]+}}, $s{{[0-9]+}}

; HSAIL-DAG: and_b1
; HSAIL-DAG: and_b1
; HSAIL-DAG: and_b1
; HSAIL-DAG: and_b1
; HSAIL-DAG: and_b1
; HSAIL-DAG: and_b1
; HSAIL-DAG: and_b1
; HSAIL-DAG: cvt_s32_b1 [[RESULT:\$s[0-9]+]]
; HSAIL-DAG: st_global_u8 [[RESULT]]
; HSAIL: ret;

; HSAIL: @BB0_2:
; HSAIL: ret;
define void @test_spill_cond_reg(i1 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %b_ptr = getelementptr i32 addrspace(1)* %in, i32 1
  %c_ptr = getelementptr i32 addrspace(1)* %in, i32 2
  %d_ptr = getelementptr i32 addrspace(1)* %in, i32 3
  %e_ptr = getelementptr i32 addrspace(1)* %in, i32 4
  %f_ptr = getelementptr i32 addrspace(1)* %in, i32 5
  %a = load i32 addrspace(1)* %in
  %b = load i32 addrspace(1)* %b_ptr
  %c = load i32 addrspace(1)* %c_ptr
  %d = load i32 addrspace(1)* %d_ptr
  %e = load i32 addrspace(1)* %e_ptr

  %cmp0 = icmp eq i32 %a, 0
  %cmp1 = icmp eq i32 %a, %b
  %cmp2 = icmp eq i32 %a, %c
  %cmp3 = icmp eq i32 %a, %d
  %cmp4 = icmp eq i32 %a, %e
  %cmp5 = icmp eq i32 %b, %c
  %cmp6 = icmp eq i32 %b, %d
  %cmp7 = icmp eq i32 %b, %e
  %cmp8 = icmp eq i32 %b, 0
  br i1 %cmp0, label %bb, label %cc

bb:
  %and0 = and i1 %cmp1, %cmp2
  %and1 = and i1 %and0, %cmp3
  %and2 = and i1 %and1, %cmp4
  %and3 = and i1 %and2, %cmp5
  %and4 = and i1 %and3, %cmp6
  %and5 = and i1 %and4, %cmp7
  %and6 = and i1 %and5, %cmp8
  store i1 %and6, i1 addrspace(1)* %out
  ret void

cc:
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_spill_cond_reg_priv(arg_u32 %test_spill_cond_reg_priv)(
; HSAIL: align(4) private_u8 %__privateStack[52];
; HSAIL: align(4) spill_u8 %__spillStack[40];

; HSAIL: lda_private_u32 {{\$s[0-9]+}}, [%__privateStack];
; HSAIL: st_private_align(4)_u32 123, [%__privateStack][{{\$s[0-9]+}}];

; HSAIL-DAG: st_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack];
; HSAIL-DAG: st_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][4];
; HSAIL-DAG: st_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][8];
; HSAIL-DAG: st_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][12];
; HSAIL-DAG: st_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][16];
; HSAIL-DAG: st_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][20];
; HSAIL-DAG: st_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][24];
; HSAIL-DAG: st_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][28];
; HSAIL-DAG: st_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][32];
; HSAIL-DAG: st_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][36];

; HSAIL: @BB1_1:
; HSAIL-DAG: ld_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack];
; HSAIL-DAG: ld_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][36];
; HSAIL-DAG: ld_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][20];
; HSAIL-DAG: ld_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][28];
; HSAIL-DAG: ld_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][24];
; HSAIL-DAG: ld_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][32];
; HSAIL-DAG: ld_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][16];
; HSAIL-DAG: ld_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][12];
; HSAIL-DAG: ld_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][8];
; HSAIL-DAG: ld_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][4];
; HSAIL-DAG: ld_spill_align(4)_u32 {{\$s[0-9]+}}, [%__spillStack][20];
; HSAIL-DAG: ld_private_align(4)_u32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+12];
; HSAIL: st_arg_align(4)_u32
; HSAIL: ret;
define i32 @test_spill_cond_reg_priv(i1 addrspace(1)* %out, i32 addrspace(1)* %in, i32 %index0, i32 %index1) {
  %alloca = alloca [13 x i32]
  %b_ptr = getelementptr i32 addrspace(1)* %in, i32 1
  %c_ptr = getelementptr i32 addrspace(1)* %in, i32 2
  %d_ptr = getelementptr i32 addrspace(1)* %in, i32 3
  %e_ptr = getelementptr i32 addrspace(1)* %in, i32 4
  %f_ptr = getelementptr i32 addrspace(1)* %in, i32 5
  %a = load i32 addrspace(1)* %in
  %b = load i32 addrspace(1)* %b_ptr
  %c = load i32 addrspace(1)* %c_ptr
  %d = load i32 addrspace(1)* %d_ptr
  %e = load i32 addrspace(1)* %e_ptr

  %cmp0 = icmp eq i32 %a, 0
  %cmp1 = icmp eq i32 %a, %b
  %cmp2 = icmp eq i32 %a, %c
  %cmp3 = icmp eq i32 %a, %d
  %cmp4 = icmp eq i32 %a, %e
  %cmp5 = icmp eq i32 %b, %c
  %cmp6 = icmp eq i32 %b, %d
  %cmp7 = icmp eq i32 %b, %e
  %cmp8 = icmp eq i32 %b, 0

  %gep.0 = getelementptr [13 x i32]* %alloca, i32 0, i32 %index0
  %gep.1 = getelementptr [13 x i32]* %alloca, i32 0, i32 %index1
  store i32 123, i32* %gep.0
  br i1 %cmp0, label %bb, label %cc

bb:
  %and0 = and i1 %cmp1, %cmp2
  %and1 = and i1 %and0, %cmp3
  %and2 = and i1 %and1, %cmp4
  %and3 = and i1 %and2, %cmp5
  %and4 = and i1 %and3, %cmp6
  %and5 = and i1 %and4, %cmp7
  %and6 = and i1 %and5, %cmp8
  %gep.2 = getelementptr i32* %gep.1, i32 3
  %load = load i32* %gep.2
  store i1 %and6, i1 addrspace(1)* %out
  ret i32 %load

cc:
  ret i32 0
}
