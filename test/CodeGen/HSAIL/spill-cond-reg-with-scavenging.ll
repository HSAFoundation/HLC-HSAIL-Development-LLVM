; RUN: llc -O0 -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

declare void @llvm.HSAIL.barrier() #2

; Spill crs and have high enough s register pressure so that the
; register scavenger needs to create a new stack slot to handle the
; temporary registers created during the spill_b1/restore_b1
; expansion.

; HSAIL-LABEL: {{^}}prog function &test_spill_cond_reg_with_scavenging()(
; HSAIL: align(4) spill_u8 %__spillStack[164];
; HSAIL: {{^[ \t]}}spill_u32 %___spillScavenge;

; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][4];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][8];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][12];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][16];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][20];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][24];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][28];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][32];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][36];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][40];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][44];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][48];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][52];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][56];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][60];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][64];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][68];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][72];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][76];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][80];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][84];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][88];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][92];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][96];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][100];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][104];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][108];
; HSAIL: ld_spill_align(4)_u32 $s0, [%__spillStack];

; HSAIL: cmp_eq_b1_s32 $c0,
; HSAIL-NEXT: cmp_eq_b1_s32 $c1,
; HSAIL-NEXT: cmp_eq_b1_s32 $c2,
; HSAIL-NEXT: cmp_eq_b1_s32 $c3,
; HSAIL-NEXT: cmp_eq_b1_s32 $c4,
; HSAIL-NEXT: cmp_eq_b1_s32 $c5,
; HSAIL-NEXT: cmp_eq_b1_s32 $c6,
; HSAIL-NEXT: cmp_eq_b1_s32 $c7,

; $s0 is spilled and restored to scavenged slot for conversion
; HSAIL-NEXT: st_spill_align(4)_u32 $s0, [%___spillScavenge];
; HSAIL-NEXT: cvt_u32_b1 $s0, $c0;
; HSAIL: barrier;
; HSAIL: ld_spill_align(4)_u32 $s0, [%___spillScavenge];


; Make sure we use the last slots
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][156];
; HSAIL: st_spill_align(4)_u32 $s0, [%__spillStack][160];

define void @test_spill_cond_reg_with_scavenging(i1 addrspace(1)* %out, i32 addrspace(1)* %in, i32 addrspace(1)* %s) #0 {
  %b_ptr = getelementptr i32, i32 addrspace(1)* %in, i32 1
  %c_ptr = getelementptr i32, i32 addrspace(1)* %in, i32 2
  %d_ptr = getelementptr i32, i32 addrspace(1)* %in, i32 3
  %e_ptr = getelementptr i32, i32 addrspace(1)* %in, i32 4
  %a = load volatile i32, i32 addrspace(1)* %in
  %b = load volatile i32, i32 addrspace(1)* %b_ptr
  %c = load volatile i32, i32 addrspace(1)* %c_ptr
  %d = load volatile i32, i32 addrspace(1)* %d_ptr
  %e = load volatile i32, i32 addrspace(1)* %e_ptr

; Create lots of s register pressure.
  %s0_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 0
  %s1_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 1
  %s2_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 2
  %s3_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 3
  %s4_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 4
  %s5_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 5
  %s6_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 6
  %s7_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 7
  %s8_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 8
  %s9_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 9
  %s10_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 10
  %s11_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 11
  %s12_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 12
  %s13_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 13
  %s14_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 14
  %s15_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 15
  %s16_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 16
  %s17_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 17
  %s18_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 18
  %s19_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 19
  %s20_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 20
  %s21_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 21
  %s22_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 22
  %s23_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 23
  %s24_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 24
  %s25_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 25
  %s26_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 26
  %s27_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 27
  %s28_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 28
  %s29_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 29
  %s30_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 30
  %s31_ptr = getelementptr i32, i32 addrspace(1)* %s, i32 31

  %s0 = load volatile i32, i32 addrspace(1)* %s0_ptr
  %s1 = load volatile i32, i32 addrspace(1)* %s1_ptr
  %s2 = load volatile i32, i32 addrspace(1)* %s2_ptr
  %s3 = load volatile i32, i32 addrspace(1)* %s3_ptr
  %s4 = load volatile i32, i32 addrspace(1)* %s4_ptr
  %s5 = load volatile i32, i32 addrspace(1)* %s5_ptr
  %s6 = load volatile i32, i32 addrspace(1)* %s6_ptr
  %s7 = load volatile i32, i32 addrspace(1)* %s7_ptr
  %s8 = load volatile i32, i32 addrspace(1)* %s8_ptr
  %s9 = load volatile i32, i32 addrspace(1)* %s9_ptr
  %s10 = load volatile i32, i32 addrspace(1)* %s10_ptr
  %s11 = load volatile i32, i32 addrspace(1)* %s11_ptr
  %s12 = load volatile i32, i32 addrspace(1)* %s12_ptr
  %s13 = load volatile i32, i32 addrspace(1)* %s13_ptr
  %s14 = load volatile i32, i32 addrspace(1)* %s14_ptr
  %s15 = load volatile i32, i32 addrspace(1)* %s15_ptr
  %s16 = load volatile i32, i32 addrspace(1)* %s16_ptr
  %s17 = load volatile i32, i32 addrspace(1)* %s17_ptr
  %s18 = load volatile i32, i32 addrspace(1)* %s18_ptr
  %s19 = load volatile i32, i32 addrspace(1)* %s19_ptr
  %s20 = load volatile i32, i32 addrspace(1)* %s20_ptr
  %s21 = load volatile i32, i32 addrspace(1)* %s21_ptr
  %s22 = load volatile i32, i32 addrspace(1)* %s22_ptr
  %s23 = load volatile i32, i32 addrspace(1)* %s23_ptr
  %s24 = load volatile i32, i32 addrspace(1)* %s24_ptr
  %s25 = load volatile i32, i32 addrspace(1)* %s25_ptr
  %s26 = load volatile i32, i32 addrspace(1)* %s26_ptr
  %s27 = load volatile i32, i32 addrspace(1)* %s27_ptr
  %s28 = load volatile i32, i32 addrspace(1)* %s28_ptr
  %s29 = load volatile i32, i32 addrspace(1)* %s29_ptr
  %s30 = load volatile i32, i32 addrspace(1)* %s30_ptr
  %s31 = load volatile i32, i32 addrspace(1)* %s31_ptr

  %s32 = load volatile i32, i32 addrspace(1)* %s
  %s33 = load volatile i32, i32 addrspace(1)* %s
  %s34 = load volatile i32, i32 addrspace(1)* %s
  %s35 = load volatile i32, i32 addrspace(1)* %s
  %s36 = load volatile i32, i32 addrspace(1)* %s
  %s37 = load volatile i32, i32 addrspace(1)* %s
  %s38 = load volatile i32, i32 addrspace(1)* %s
  %s39 = load volatile i32, i32 addrspace(1)* %s
  %s40 = load volatile i32, i32 addrspace(1)* %s
  %s41 = load volatile i32, i32 addrspace(1)* %s
  %s42 = load volatile i32, i32 addrspace(1)* %s
  %s43 = load volatile i32, i32 addrspace(1)* %s
  %s44 = load volatile i32, i32 addrspace(1)* %s
  %s45 = load volatile i32, i32 addrspace(1)* %s
  %s46 = load volatile i32, i32 addrspace(1)* %s
  %s47 = load volatile i32, i32 addrspace(1)* %s
  %s48 = load volatile i32, i32 addrspace(1)* %s
  %s49 = load volatile i32, i32 addrspace(1)* %s
  %s50 = load volatile i32, i32 addrspace(1)* %s
  %s51 = load volatile i32, i32 addrspace(1)* %s
  %s52 = load volatile i32, i32 addrspace(1)* %s
  %s53 = load volatile i32, i32 addrspace(1)* %s
  %s54 = load volatile i32, i32 addrspace(1)* %s
  %s55 = load volatile i32, i32 addrspace(1)* %s
  %s56 = load volatile i32, i32 addrspace(1)* %s
  %s57 = load volatile i32, i32 addrspace(1)* %s
  %s58 = load volatile i32, i32 addrspace(1)* %s
  %s59 = load volatile i32, i32 addrspace(1)* %s
  %s60 = load volatile i32, i32 addrspace(1)* %s
  %s61 = load volatile i32, i32 addrspace(1)* %s
  %s62 = load volatile i32, i32 addrspace(1)* %s
  %s63 = load volatile i32, i32 addrspace(1)* %s

  %s64 = load volatile i32, i32 addrspace(1)* %s
  %s65 = load volatile i32, i32 addrspace(1)* %s
  %s66 = load volatile i32, i32 addrspace(1)* %s
  %s67 = load volatile i32, i32 addrspace(1)* %s
  %s68 = load volatile i32, i32 addrspace(1)* %s
  %s69 = load volatile i32, i32 addrspace(1)* %s
  %s70 = load volatile i32, i32 addrspace(1)* %s
  %s71 = load volatile i32, i32 addrspace(1)* %s
  %s72 = load volatile i32, i32 addrspace(1)* %s
  %s73 = load volatile i32, i32 addrspace(1)* %s
  %s74 = load volatile i32, i32 addrspace(1)* %s
  %s75 = load volatile i32, i32 addrspace(1)* %s
  %s76 = load volatile i32, i32 addrspace(1)* %s
  %s77 = load volatile i32, i32 addrspace(1)* %s
  %s78 = load volatile i32, i32 addrspace(1)* %s
  %s79 = load volatile i32, i32 addrspace(1)* %s
  %s80 = load volatile i32, i32 addrspace(1)* %s
  %s81 = load volatile i32, i32 addrspace(1)* %s
  %s82 = load volatile i32, i32 addrspace(1)* %s
  %s83 = load volatile i32, i32 addrspace(1)* %s
  %s84 = load volatile i32, i32 addrspace(1)* %s
  %s85 = load volatile i32, i32 addrspace(1)* %s
  %s86 = load volatile i32, i32 addrspace(1)* %s
  %s87 = load volatile i32, i32 addrspace(1)* %s
  %s88 = load volatile i32, i32 addrspace(1)* %s
  %s89 = load volatile i32, i32 addrspace(1)* %s
  %s90 = load volatile i32, i32 addrspace(1)* %s
  %s91 = load volatile i32, i32 addrspace(1)* %s
  %s92 = load volatile i32, i32 addrspace(1)* %s
  %s93 = load volatile i32, i32 addrspace(1)* %s
  %s94 = load volatile i32, i32 addrspace(1)* %s
  %s95 = load volatile i32, i32 addrspace(1)* %s

  %s96 = load volatile i32, i32 addrspace(1)* %s
  %s97 = load volatile i32, i32 addrspace(1)* %s
  %s98 = load volatile i32, i32 addrspace(1)* %s
  %s99 = load volatile i32, i32 addrspace(1)* %s
  %s100 = load volatile i32, i32 addrspace(1)* %s
  %s101 = load volatile i32, i32 addrspace(1)* %s
  %s102 = load volatile i32, i32 addrspace(1)* %s
  %s103 = load volatile i32, i32 addrspace(1)* %s
  %s104 = load volatile i32, i32 addrspace(1)* %s
  %s105 = load volatile i32, i32 addrspace(1)* %s
  %s106 = load volatile i32, i32 addrspace(1)* %s
  %s107 = load volatile i32, i32 addrspace(1)* %s
  %s108 = load volatile i32, i32 addrspace(1)* %s
  %s109 = load volatile i32, i32 addrspace(1)* %s
  %s110 = load volatile i32, i32 addrspace(1)* %s
  %s111 = load volatile i32, i32 addrspace(1)* %s
  %s112 = load volatile i32, i32 addrspace(1)* %s
  %s113 = load volatile i32, i32 addrspace(1)* %s
  %s114 = load volatile i32, i32 addrspace(1)* %s
  %s115 = load volatile i32, i32 addrspace(1)* %s
  %s116 = load volatile i32, i32 addrspace(1)* %s
  %s117 = load volatile i32, i32 addrspace(1)* %s
  %s118 = load volatile i32, i32 addrspace(1)* %s
  %s119 = load volatile i32, i32 addrspace(1)* %s
  %s120 = load volatile i32, i32 addrspace(1)* %s
  %s121 = load volatile i32, i32 addrspace(1)* %s
  %s122 = load volatile i32, i32 addrspace(1)* %s
  %s123 = load volatile i32, i32 addrspace(1)* %s
  %s124 = load volatile i32, i32 addrspace(1)* %s
  %s125 = load volatile i32, i32 addrspace(1)* %s
  %s126 = load volatile i32, i32 addrspace(1)* %s
  %s127 = load volatile i32, i32 addrspace(1)* %s

  %s128 = load volatile i32, i32 addrspace(1)* %s
  %s129 = load volatile i32, i32 addrspace(1)* %s
  %s130 = load volatile i32, i32 addrspace(1)* %s
  %s131 = load volatile i32, i32 addrspace(1)* %s
  %s132 = load volatile i32, i32 addrspace(1)* %s

  %cmp0 = icmp eq i32 %a, 0
  %cmp1 = icmp eq i32 %a, %b
  %cmp2 = icmp eq i32 %a, %c
  %cmp3 = icmp eq i32 %a, %d
  %cmp4 = icmp eq i32 %a, %e
  %cmp5 = icmp eq i32 %b, %c
  %cmp6 = icmp eq i32 %b, %d
  %cmp7 = icmp eq i32 %b, %e
  %cmp8 = icmp eq i32 %b, 0
  %cmp9 = icmp eq i32 %c, 0
  %cmp10 = icmp eq i32 %d, 0
  %cmp11 = icmp eq i32 %e, 0

  call void @llvm.HSAIL.barrier() #2

  store volatile i1 %cmp0, i1 addrspace(1)* %out
  store volatile i1 %cmp1, i1 addrspace(1)* %out
  store volatile i1 %cmp2, i1 addrspace(1)* %out
  store volatile i1 %cmp3, i1 addrspace(1)* %out
  store volatile i1 %cmp4, i1 addrspace(1)* %out
  store volatile i1 %cmp5, i1 addrspace(1)* %out
  store volatile i1 %cmp6, i1 addrspace(1)* %out
  store volatile i1 %cmp7, i1 addrspace(1)* %out
  store volatile i1 %cmp8, i1 addrspace(1)* %out
  store volatile i1 %cmp9, i1 addrspace(1)* %out
  store volatile i1 %cmp10, i1 addrspace(1)* %out
  store volatile i1 %cmp11, i1 addrspace(1)* %out

  store volatile i32 %s0, i32 addrspace(1)* %s
  store volatile i32 %s1, i32 addrspace(1)* %s
  store volatile i32 %s2, i32 addrspace(1)* %s
  store volatile i32 %s3, i32 addrspace(1)* %s
  store volatile i32 %s4, i32 addrspace(1)* %s
  store volatile i32 %s5, i32 addrspace(1)* %s
  store volatile i32 %s6, i32 addrspace(1)* %s
  store volatile i32 %s7, i32 addrspace(1)* %s
  store volatile i32 %s8, i32 addrspace(1)* %s
  store volatile i32 %s9, i32 addrspace(1)* %s
  store volatile i32 %s10, i32 addrspace(1)* %s
  store volatile i32 %s11, i32 addrspace(1)* %s
  store volatile i32 %s12, i32 addrspace(1)* %s
  store volatile i32 %s13, i32 addrspace(1)* %s
  store volatile i32 %s14, i32 addrspace(1)* %s
  store volatile i32 %s15, i32 addrspace(1)* %s
  store volatile i32 %s16, i32 addrspace(1)* %s
  store volatile i32 %s17, i32 addrspace(1)* %s
  store volatile i32 %s18, i32 addrspace(1)* %s
  store volatile i32 %s19, i32 addrspace(1)* %s
  store volatile i32 %s20, i32 addrspace(1)* %s
  store volatile i32 %s21, i32 addrspace(1)* %s
  store volatile i32 %s22, i32 addrspace(1)* %s
  store volatile i32 %s23, i32 addrspace(1)* %s
  store volatile i32 %s24, i32 addrspace(1)* %s
  store volatile i32 %s25, i32 addrspace(1)* %s
  store volatile i32 %s26, i32 addrspace(1)* %s
  store volatile i32 %s27, i32 addrspace(1)* %s
  store volatile i32 %s28, i32 addrspace(1)* %s
  store volatile i32 %s29, i32 addrspace(1)* %s
  store volatile i32 %s30, i32 addrspace(1)* %s
  store volatile i32 %s31, i32 addrspace(1)* %s
  store volatile i32 %s32, i32 addrspace(1)* %s
  store volatile i32 %s33, i32 addrspace(1)* %s
  store volatile i32 %s34, i32 addrspace(1)* %s
  store volatile i32 %s35, i32 addrspace(1)* %s
  store volatile i32 %s36, i32 addrspace(1)* %s
  store volatile i32 %s37, i32 addrspace(1)* %s
  store volatile i32 %s38, i32 addrspace(1)* %s
  store volatile i32 %s39, i32 addrspace(1)* %s
  store volatile i32 %s40, i32 addrspace(1)* %s
  store volatile i32 %s41, i32 addrspace(1)* %s
  store volatile i32 %s42, i32 addrspace(1)* %s
  store volatile i32 %s43, i32 addrspace(1)* %s
  store volatile i32 %s44, i32 addrspace(1)* %s
  store volatile i32 %s45, i32 addrspace(1)* %s
  store volatile i32 %s46, i32 addrspace(1)* %s
  store volatile i32 %s47, i32 addrspace(1)* %s
  store volatile i32 %s48, i32 addrspace(1)* %s
  store volatile i32 %s49, i32 addrspace(1)* %s
  store volatile i32 %s50, i32 addrspace(1)* %s
  store volatile i32 %s51, i32 addrspace(1)* %s
  store volatile i32 %s52, i32 addrspace(1)* %s
  store volatile i32 %s53, i32 addrspace(1)* %s
  store volatile i32 %s54, i32 addrspace(1)* %s
  store volatile i32 %s55, i32 addrspace(1)* %s
  store volatile i32 %s56, i32 addrspace(1)* %s
  store volatile i32 %s57, i32 addrspace(1)* %s
  store volatile i32 %s58, i32 addrspace(1)* %s
  store volatile i32 %s59, i32 addrspace(1)* %s
  store volatile i32 %s60, i32 addrspace(1)* %s
  store volatile i32 %s61, i32 addrspace(1)* %s
  store volatile i32 %s62, i32 addrspace(1)* %s
  store volatile i32 %s63, i32 addrspace(1)* %s
  store volatile i32 %s64, i32 addrspace(1)* %s
  store volatile i32 %s65, i32 addrspace(1)* %s
  store volatile i32 %s66, i32 addrspace(1)* %s
  store volatile i32 %s67, i32 addrspace(1)* %s
  store volatile i32 %s68, i32 addrspace(1)* %s
  store volatile i32 %s69, i32 addrspace(1)* %s
  store volatile i32 %s70, i32 addrspace(1)* %s
  store volatile i32 %s71, i32 addrspace(1)* %s
  store volatile i32 %s72, i32 addrspace(1)* %s
  store volatile i32 %s73, i32 addrspace(1)* %s
  store volatile i32 %s74, i32 addrspace(1)* %s
  store volatile i32 %s75, i32 addrspace(1)* %s
  store volatile i32 %s76, i32 addrspace(1)* %s
  store volatile i32 %s77, i32 addrspace(1)* %s
  store volatile i32 %s78, i32 addrspace(1)* %s
  store volatile i32 %s79, i32 addrspace(1)* %s
  store volatile i32 %s80, i32 addrspace(1)* %s
  store volatile i32 %s81, i32 addrspace(1)* %s
  store volatile i32 %s82, i32 addrspace(1)* %s
  store volatile i32 %s83, i32 addrspace(1)* %s
  store volatile i32 %s84, i32 addrspace(1)* %s
  store volatile i32 %s85, i32 addrspace(1)* %s
  store volatile i32 %s86, i32 addrspace(1)* %s
  store volatile i32 %s87, i32 addrspace(1)* %s
  store volatile i32 %s88, i32 addrspace(1)* %s
  store volatile i32 %s89, i32 addrspace(1)* %s
  store volatile i32 %s90, i32 addrspace(1)* %s
  store volatile i32 %s91, i32 addrspace(1)* %s
  store volatile i32 %s92, i32 addrspace(1)* %s
  store volatile i32 %s93, i32 addrspace(1)* %s
  store volatile i32 %s94, i32 addrspace(1)* %s
  store volatile i32 %s95, i32 addrspace(1)* %s
  store volatile i32 %s96, i32 addrspace(1)* %s
  store volatile i32 %s97, i32 addrspace(1)* %s
  store volatile i32 %s98, i32 addrspace(1)* %s
  store volatile i32 %s99, i32 addrspace(1)* %s
  store volatile i32 %s100, i32 addrspace(1)* %s
  store volatile i32 %s101, i32 addrspace(1)* %s
  store volatile i32 %s102, i32 addrspace(1)* %s
  store volatile i32 %s103, i32 addrspace(1)* %s
  store volatile i32 %s104, i32 addrspace(1)* %s
  store volatile i32 %s105, i32 addrspace(1)* %s
  store volatile i32 %s106, i32 addrspace(1)* %s
  store volatile i32 %s107, i32 addrspace(1)* %s
  store volatile i32 %s108, i32 addrspace(1)* %s
  store volatile i32 %s109, i32 addrspace(1)* %s
  store volatile i32 %s110, i32 addrspace(1)* %s
  store volatile i32 %s111, i32 addrspace(1)* %s
  store volatile i32 %s112, i32 addrspace(1)* %s
  store volatile i32 %s113, i32 addrspace(1)* %s
  store volatile i32 %s114, i32 addrspace(1)* %s
  store volatile i32 %s115, i32 addrspace(1)* %s
  store volatile i32 %s116, i32 addrspace(1)* %s
  store volatile i32 %s117, i32 addrspace(1)* %s
  store volatile i32 %s118, i32 addrspace(1)* %s
  store volatile i32 %s119, i32 addrspace(1)* %s
  store volatile i32 %s120, i32 addrspace(1)* %s
  store volatile i32 %s121, i32 addrspace(1)* %s
  store volatile i32 %s122, i32 addrspace(1)* %s
  store volatile i32 %s123, i32 addrspace(1)* %s
  store volatile i32 %s124, i32 addrspace(1)* %s
  store volatile i32 %s125, i32 addrspace(1)* %s
  store volatile i32 %s126, i32 addrspace(1)* %s
  store volatile i32 %s127, i32 addrspace(1)* %s
  store volatile i32 %s128, i32 addrspace(1)* %s
  store volatile i32 %s129, i32 addrspace(1)* %s
  store volatile i32 %s130, i32 addrspace(1)* %s
  store volatile i32 %s131, i32 addrspace(1)* %s
  store volatile i32 %s132, i32 addrspace(1)* %s

  br i1 %cmp0, label %bb, label %cc

bb:
  %and0 = and i1 %cmp1, %cmp2
  %and1 = and i1 %and0, %cmp3
  %and2 = and i1 %and1, %cmp4
  %and3 = and i1 %and2, %cmp5
  %and4 = and i1 %and3, %cmp6
  %and5 = and i1 %and4, %cmp7
  %and6 = and i1 %and5, %cmp8
  %and7 = and i1 %and6, %cmp8
  %and8 = and i1 %and7, %cmp9
  %and9 = and i1 %and8, %cmp10
  %and10 = and i1 %and9, %cmp11
  store volatile i1 %and10, i1 addrspace(1)* %out
  ret void

cc:
  ret void
}

attributes #0 = { nounwind }
attributes #1 = { nounwind readnone }
attributes #2 = { nounwind noduplicate }
