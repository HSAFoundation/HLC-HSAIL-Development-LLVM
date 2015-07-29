; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &group_atomic_xchg_ret_i32(
; HSAIL: atomic_exch_group_scar_wg_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @group_atomic_xchg_ret_i32(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw xchg i32 addrspace(3)* %ptr, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_xchg_monotonic_ret_i32(
; HSAIL: atomic_exch_group_rlx_wg_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @group_atomic_xchg_monotonic_ret_i32(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw xchg i32 addrspace(3)* %ptr, i32 4 monotonic
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_xchg_acquire_ret_i32(
; HSAIL: atomic_exch_group_scacq_wg_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @group_atomic_xchg_acquire_ret_i32(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw xchg i32 addrspace(3)* %ptr, i32 4 acquire
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_xchg_release_ret_i32(
; HSAIL: atomic_exch_group_screl_wg_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @group_atomic_xchg_release_ret_i32(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw xchg i32 addrspace(3)* %ptr, i32 4 release
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_xchg_acq_rel_ret_i32(
; HSAIL: atomic_exch_group_scar_wg_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @group_atomic_xchg_acq_rel_ret_i32(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw xchg i32 addrspace(3)* %ptr, i32 4 acq_rel
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_xchg_ret_i32_offset(
; HSAIL: atomic_exch_group_scar_wg_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 4;
define void @group_atomic_xchg_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw xchg i32 addrspace(3)* %gep, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_add_ret_i32(
; HSAIL: atomic_add_group_scar_wg_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @group_atomic_add_ret_i32(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw add i32 addrspace(3)* %ptr, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_add_ret_i32_offset(
; HSAIL: atomic_add_group_scar_wg_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 4;
define void @group_atomic_add_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw add i32 addrspace(3)* %gep, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_inc_ret_i32(
; HSAIL: atomic_add_group_scar_wg_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 1;
define void @group_atomic_inc_ret_i32(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw add i32 addrspace(3)* %ptr, i32 1 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_inc_ret_i32_offset(
; HSAIL: atomic_add_group_scar_wg_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 1;
define void @group_atomic_inc_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw add i32 addrspace(3)* %gep, i32 1 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_sub_ret_i32(
; HSAIL: atomic_sub_group_scar_wg_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @group_atomic_sub_ret_i32(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw sub i32 addrspace(3)* %ptr, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_sub_ret_i32_offset(
; HSAIL: atomic_sub_group_scar_wg_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 4;
define void @group_atomic_sub_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw sub i32 addrspace(3)* %gep, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_dec_ret_i32(
; HSAIL: atomic_sub_group_scar_wg_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 1;
define void @group_atomic_dec_ret_i32(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw sub i32 addrspace(3)* %ptr, i32 1 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_dec_ret_i32_offset(
; HSAIL: atomic_sub_group_scar_wg_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 1;
define void @group_atomic_dec_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw sub i32 addrspace(3)* %gep, i32 1 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_and_ret_i32(
; HSAIL: atomic_and_group_scar_wg_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @group_atomic_and_ret_i32(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw and i32 addrspace(3)* %ptr, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_and_ret_i32_offset(
; HSAIL: atomic_and_group_scar_wg_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 4;
define void @group_atomic_and_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw and i32 addrspace(3)* %gep, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_or_ret_i32(
; HSAIL: atomic_or_group_scar_wg_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @group_atomic_or_ret_i32(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw or i32 addrspace(3)* %ptr, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_or_ret_i32_offset(
; HSAIL: atomic_or_group_scar_wg_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 4;
define void @group_atomic_or_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw or i32 addrspace(3)* %gep, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_xor_ret_i32(
; HSAIL: atomic_xor_group_scar_wg_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @group_atomic_xor_ret_i32(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw xor i32 addrspace(3)* %ptr, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_xor_ret_i32_offset(
; HSAIL: atomic_xor_group_scar_wg_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 4;
define void @group_atomic_xor_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw xor i32 addrspace(3)* %gep, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; FIXME: There is no atomic nand instr
; XHSAIL-LABEL: {{^}}prog function &group_atomic_nand_ret_i32(uction, so we somehow need to expand this.
; define void @group_atomic_nand_ret_i32(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
;   %result = atomicrmw nand i32 addrspace(3)* %ptr, i32 4 seq_cst
;   store i32 %result, i32 addrspace(1)* %out, align 4
;   ret void
; }

; HSAIL-LABEL: {{^}}prog function &group_atomic_min_ret_i32(
; HSAIL: atomic_min_group_scar_wg_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @group_atomic_min_ret_i32(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw min i32 addrspace(3)* %ptr, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_min_ret_i32_offset(
; HSAIL: atomic_min_group_scar_wg_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 4;
define void @group_atomic_min_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw min i32 addrspace(3)* %gep, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_max_ret_i32(
; HSAIL: atomic_max_group_scar_wg_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @group_atomic_max_ret_i32(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw max i32 addrspace(3)* %ptr, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_max_ret_i32_offset(
; HSAIL: atomic_max_group_scar_wg_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 4;
define void @group_atomic_max_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw max i32 addrspace(3)* %gep, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_umin_ret_i32(
; HSAIL: atomic_min_group_scar_wg_u32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @group_atomic_umin_ret_i32(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw umin i32 addrspace(3)* %ptr, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_umin_ret_i32_offset(
; HSAIL: atomic_min_group_scar_wg_u32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 4;
define void @group_atomic_umin_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw umin i32 addrspace(3)* %gep, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_umax_ret_i32(
; HSAIL: atomic_max_group_scar_wg_u32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @group_atomic_umax_ret_i32(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw umax i32 addrspace(3)* %ptr, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_umax_ret_i32_offset(
; HSAIL: atomic_max_group_scar_wg_u32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 4;
define void @group_atomic_umax_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw umax i32 addrspace(3)* %gep, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_xchg_noret_i32(
; HSAIL: atomic_exch_group_scar_wg_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @group_atomic_xchg_noret_i32(i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw xchg i32 addrspace(3)* %ptr, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_xchg_noret_i32_offset(
; HSAIL: atomic_exch_group_scar_wg_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 4;
define void @group_atomic_xchg_noret_i32_offset(i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw xchg i32 addrspace(3)* %gep, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_add_noret_i32(
; HSAIL: atomicnoret_add_group_scar_wg_s32 [{{\$s[0-9]+}}], 4;
define void @group_atomic_add_noret_i32(i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw add i32 addrspace(3)* %ptr, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_add_noret_i32_offset(
; HSAIL: atomicnoret_add_group_scar_wg_s32 [{{\$s[0-9]+}}+16], 4;
define void @group_atomic_add_noret_i32_offset(i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw add i32 addrspace(3)* %gep, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_inc_noret_i32(
define void @group_atomic_inc_noret_i32(i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw add i32 addrspace(3)* %ptr, i32 1 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_inc_noret_i32_offset(
define void @group_atomic_inc_noret_i32_offset(i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw add i32 addrspace(3)* %gep, i32 1 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_inc_noret_i32_bad_si_offset(
define void @group_atomic_inc_noret_i32_bad_si_offset(i32 addrspace(3)* %ptr, i32 %a, i32 %b) nounwind {
  %sub = sub i32 %a, %b
  %add = add i32 %sub, 4
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 %add
  %result = atomicrmw add i32 addrspace(3)* %gep, i32 1 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_sub_noret_i32(
; HSAIL: atomicnoret_sub_group_scar_wg_s32 [{{\$s[0-9]+}}], 4;
define void @group_atomic_sub_noret_i32(i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw sub i32 addrspace(3)* %ptr, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_sub_noret_i32_offset(
; HSAIL: atomicnoret_sub_group_scar_wg_s32 [{{\$s[0-9]+}}+16], 4;
define void @group_atomic_sub_noret_i32_offset(i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw sub i32 addrspace(3)* %gep, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_dec_noret_i32(
define void @group_atomic_dec_noret_i32(i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw sub i32 addrspace(3)* %ptr, i32 1 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_dec_noret_i32_offset(
define void @group_atomic_dec_noret_i32_offset(i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw sub i32 addrspace(3)* %gep, i32 1 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_and_noret_i32(
; HSAIL: atomicnoret_and_group_scar_wg_b32 [{{\$s[0-9]+}}], 4;
define void @group_atomic_and_noret_i32(i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw and i32 addrspace(3)* %ptr, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_and_noret_i32_offset(
; HSAIL: atomicnoret_and_group_scar_wg_b32 [{{\$s[0-9]+}}+16], 4;
define void @group_atomic_and_noret_i32_offset(i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw and i32 addrspace(3)* %gep, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_or_noret_i32(
; HSAIL: atomicnoret_or_group_scar_wg_b32 [{{\$s[0-9]+}}], 4;
define void @group_atomic_or_noret_i32(i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw or i32 addrspace(3)* %ptr, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_or_noret_i32_offset(
; HSAIL: atomicnoret_or_group_scar_wg_b32 [{{\$s[0-9]+}}+16], 4;
define void @group_atomic_or_noret_i32_offset(i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw or i32 addrspace(3)* %gep, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_xor_noret_i32(
; HSAIL: atomicnoret_xor_group_scar_wg_b32 [{{\$s[0-9]+}}], 4;
define void @group_atomic_xor_noret_i32(i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw xor i32 addrspace(3)* %ptr, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_xor_noret_i32_offset(
; HSAIL: atomicnoret_xor_group_scar_wg_b32 [{{\$s[0-9]+}}+16], 4;
define void @group_atomic_xor_noret_i32_offset(i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw xor i32 addrspace(3)* %gep, i32 4 seq_cst
  ret void
}

; FIXME: There is no atomic nand instr
; XHSAIL-LABEL: {{^}}prog function &group_atomic_nand_noret_i32(uction, so we somehow need to expand this.
; define void @group_atomic_nand_noret_i32(i32 addrspace(3)* %ptr) nounwind {
;   %result = atomicrmw nand i32 addrspace(3)* %ptr, i32 4 seq_cst
;   ret void
; }

; HSAIL-LABEL: {{^}}prog function &group_atomic_min_noret_i32(
; HSAIL: atomicnoret_min_group_scar_wg_s32 [{{\$s[0-9]+}}], 4;
define void @group_atomic_min_noret_i32(i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw min i32 addrspace(3)* %ptr, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_min_noret_i32_offset(
; HSAIL: atomicnoret_min_group_scar_wg_s32 [{{\$s[0-9]+}}+16], 4;
define void @group_atomic_min_noret_i32_offset(i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw min i32 addrspace(3)* %gep, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_max_noret_i32(
; HSAIL: atomicnoret_max_group_scar_wg_s32 [{{\$s[0-9]+}}], 4;
define void @group_atomic_max_noret_i32(i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw max i32 addrspace(3)* %ptr, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_max_noret_i32_offset(
; HSAIL: atomicnoret_max_group_scar_wg_s32 [{{\$s[0-9]+}}+16], 4;
define void @group_atomic_max_noret_i32_offset(i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw max i32 addrspace(3)* %gep, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_umin_noret_i32(
; HSAIL: atomicnoret_min_group_scar_wg_u32 [{{\$s[0-9]+}}], 4;
define void @group_atomic_umin_noret_i32(i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw umin i32 addrspace(3)* %ptr, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_umin_noret_i32_offset(
; HSAIL: atomicnoret_min_group_scar_wg_u32 [{{\$s[0-9]+}}+16], 4;
define void @group_atomic_umin_noret_i32_offset(i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw umin i32 addrspace(3)* %gep, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_umax_noret_i32(
; HSAIL: atomicnoret_max_group_scar_wg_u32 [{{\$s[0-9]+}}], 4;
define void @group_atomic_umax_noret_i32(i32 addrspace(3)* %ptr) nounwind {
  %result = atomicrmw umax i32 addrspace(3)* %ptr, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_umax_noret_i32_offset(
; HSAIL: atomicnoret_max_group_scar_wg_u32 [{{\$s[0-9]+}}+16], 4;
define void @group_atomic_umax_noret_i32_offset(i32 addrspace(3)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %result = atomicrmw umax i32 addrspace(3)* %gep, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_load_acquire_ret_i32(
; HSAIL: atomic_ld_group_scacq_wg_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}];
define void @group_atomic_load_acquire_ret_i32(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %result = load atomic i32 addrspace(3)* %ptr acquire, align 4
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_load_seq_cst_ret_i32(
; HSAIL: memfence_screl_wg;
; HSAIL: atomic_ld_group_scacq_wg_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}];
define void @group_atomic_load_seq_cst_ret_i32(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %result = load atomic i32 addrspace(3)* %ptr seq_cst, align 4
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_load_monotonic_ret_i32(
; HSAIL: atomic_ld_group_rlx_wg_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}];
define void @group_atomic_load_monotonic_ret_i32(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr) nounwind {
  %result = load atomic i32 addrspace(3)* %ptr monotonic, align 4
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_store_release_i32(
; HSAIL: atomicnoret_st_group_screl_wg_b32 [{{\$s[0-9]+}}], 9;
define void @group_atomic_store_release_i32(i32 addrspace(3)* %ptr) nounwind {
  store atomic i32 9, i32 addrspace(3)* %ptr release, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_store_seq_cst_i32(
; HSAIL: atomicnoret_st_group_screl_wg_b32 [{{\$s[0-9]+}}], 9;
; HSAIL: memfence_scacq_wg;
define void @group_atomic_store_seq_cst_i32(i32 addrspace(3)* %ptr) nounwind {
  store atomic i32 9, i32 addrspace(3)* %ptr seq_cst, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &group_atomic_store_monotonic_i32(
; HSAIL: atomicnoret_st_group_rlx_wg_b32 [{{\$s[0-9]+}}], {{\$s[0-9]+}};
define void @group_atomic_store_monotonic_i32(i32 addrspace(3)* %ptr, i32 %foo) nounwind {
  store atomic i32 %foo, i32 addrspace(3)* %ptr monotonic, align 4
  ret void
}
