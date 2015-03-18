; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &global_atomic_xchg_ret_i32(
; HSAIL: atomic_exch_global_scar_system_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @global_atomic_xchg_ret_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw xchg i32 addrspace(1)* %ptr, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_xchg_monotonic_ret_i32(
; HSAIL: atomic_exch_global_rlx_system_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @global_atomic_xchg_monotonic_ret_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw xchg i32 addrspace(1)* %ptr, i32 4 monotonic
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_xchg_acquire_ret_i32(
; HSAIL: atomic_exch_global_scacq_system_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @global_atomic_xchg_acquire_ret_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw xchg i32 addrspace(1)* %ptr, i32 4 acquire
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_xchg_release_ret_i32(
; HSAIL: atomic_exch_global_screl_system_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @global_atomic_xchg_release_ret_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw xchg i32 addrspace(1)* %ptr, i32 4 release
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_xchg_acq_rel_ret_i32(
; HSAIL: atomic_exch_global_scar_system_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @global_atomic_xchg_acq_rel_ret_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw xchg i32 addrspace(1)* %ptr, i32 4 acq_rel
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_xchg_ret_i32_offset(
; HSAIL: atomic_exch_global_scar_system_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 4;
define void @global_atomic_xchg_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw xchg i32 addrspace(1)* %gep, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_add_ret_i32(
; HSAIL: atomic_add_global_scar_system_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @global_atomic_add_ret_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw add i32 addrspace(1)* %ptr, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_add_ret_i32_offset(
; HSAIL: atomic_add_global_scar_system_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 4;
define void @global_atomic_add_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw add i32 addrspace(1)* %gep, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_inc_ret_i32(
; HSAIL: atomic_add_global_scar_system_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 1;
define void @global_atomic_inc_ret_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw add i32 addrspace(1)* %ptr, i32 1 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_inc_ret_i32_offset(
; HSAIL: atomic_add_global_scar_system_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 1;
define void @global_atomic_inc_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw add i32 addrspace(1)* %gep, i32 1 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_sub_ret_i32(
; HSAIL: atomic_sub_global_scar_system_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @global_atomic_sub_ret_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw sub i32 addrspace(1)* %ptr, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_sub_ret_i32_offset(
; HSAIL: atomic_sub_global_scar_system_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 4;
define void @global_atomic_sub_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw sub i32 addrspace(1)* %gep, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_dec_ret_i32(
; HSAIL: atomic_sub_global_scar_system_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 1;
define void @global_atomic_dec_ret_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw sub i32 addrspace(1)* %ptr, i32 1 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_dec_ret_i32_offset(
; HSAIL: atomic_sub_global_scar_system_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 1;
define void @global_atomic_dec_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw sub i32 addrspace(1)* %gep, i32 1 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_and_ret_i32(
; HSAIL: atomic_and_global_scar_system_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @global_atomic_and_ret_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw and i32 addrspace(1)* %ptr, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_and_ret_i32_offset(
; HSAIL: atomic_and_global_scar_system_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 4;
define void @global_atomic_and_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw and i32 addrspace(1)* %gep, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_or_ret_i32(
; HSAIL: atomic_or_global_scar_system_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @global_atomic_or_ret_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw or i32 addrspace(1)* %ptr, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_or_ret_i32_offset(
; HSAIL: atomic_or_global_scar_system_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 4;
define void @global_atomic_or_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw or i32 addrspace(1)* %gep, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_xor_ret_i32(
; HSAIL: atomic_xor_global_scar_system_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @global_atomic_xor_ret_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw xor i32 addrspace(1)* %ptr, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_xor_ret_i32_offset(
; HSAIL: atomic_xor_global_scar_system_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 4;
define void @global_atomic_xor_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw xor i32 addrspace(1)* %gep, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; FIXME: There is no atomic nand instr
; XHSAIL-LABEL: {{^}}prog function &global_atomic_nand_ret_i32(uction, so we somehow need to expand this.
; define void @global_atomic_nand_ret_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
;   %result = atomicrmw nand i32 addrspace(1)* %ptr, i32 4 seq_cst
;   store i32 %result, i32 addrspace(1)* %out, align 4
;   ret void
; }

; HSAIL-LABEL: {{^}}prog function &global_atomic_min_ret_i32(
; HSAIL: atomic_min_global_scar_system_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @global_atomic_min_ret_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw min i32 addrspace(1)* %ptr, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_min_ret_i32_offset(
; HSAIL: atomic_min_global_scar_system_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 4;
define void @global_atomic_min_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw min i32 addrspace(1)* %gep, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_max_ret_i32(
; HSAIL: atomic_max_global_scar_system_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @global_atomic_max_ret_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw max i32 addrspace(1)* %ptr, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_max_ret_i32_offset(
; HSAIL: atomic_max_global_scar_system_s32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 4;
define void @global_atomic_max_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw max i32 addrspace(1)* %gep, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_umin_ret_i32(
; HSAIL: atomic_min_global_scar_system_u32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @global_atomic_umin_ret_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw umin i32 addrspace(1)* %ptr, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_umin_ret_i32_offset(
; HSAIL: atomic_min_global_scar_system_u32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 4;
define void @global_atomic_umin_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw umin i32 addrspace(1)* %gep, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_umax_ret_i32(
; HSAIL: atomic_max_global_scar_system_u32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @global_atomic_umax_ret_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw umax i32 addrspace(1)* %ptr, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_umax_ret_i32_offset(
; HSAIL: atomic_max_global_scar_system_u32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 4;
define void @global_atomic_umax_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw umax i32 addrspace(1)* %gep, i32 4 seq_cst
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_xchg_noret_i32(
; HSAIL: atomic_exch_global_scar_system_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}], 4;
define void @global_atomic_xchg_noret_i32(i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw xchg i32 addrspace(1)* %ptr, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_xchg_noret_i32_offset(
; HSAIL: atomic_exch_global_scar_system_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 4;
define void @global_atomic_xchg_noret_i32_offset(i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw xchg i32 addrspace(1)* %gep, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_add_noret_i32(
; HSAIL: atomicnoret_add_global_scar_system_s32 [{{\$s[0-9]+}}], 4;
define void @global_atomic_add_noret_i32(i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw add i32 addrspace(1)* %ptr, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_add_noret_i32_offset(
; HSAIL: atomicnoret_add_global_scar_system_s32 [{{\$s[0-9]+}}+16], 4;
define void @global_atomic_add_noret_i32_offset(i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw add i32 addrspace(1)* %gep, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_inc_noret_i32(
define void @global_atomic_inc_noret_i32(i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw add i32 addrspace(1)* %ptr, i32 1 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_inc_noret_i32_offset(
define void @global_atomic_inc_noret_i32_offset(i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw add i32 addrspace(1)* %gep, i32 1 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_inc_noret_i32_bad_si_offset(
define void @global_atomic_inc_noret_i32_bad_si_offset(i32 addrspace(1)* %ptr, i32 %a, i32 %b) nounwind {
  %sub = sub i32 %a, %b
  %add = add i32 %sub, 4
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 %add
  %result = atomicrmw add i32 addrspace(1)* %gep, i32 1 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_sub_noret_i32(
; HSAIL: atomicnoret_sub_global_scar_system_s32 [{{\$s[0-9]+}}], 4;
define void @global_atomic_sub_noret_i32(i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw sub i32 addrspace(1)* %ptr, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_sub_noret_i32_offset(
; HSAIL: atomicnoret_sub_global_scar_system_s32 [{{\$s[0-9]+}}+16], 4;
define void @global_atomic_sub_noret_i32_offset(i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw sub i32 addrspace(1)* %gep, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_dec_noret_i32(
define void @global_atomic_dec_noret_i32(i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw sub i32 addrspace(1)* %ptr, i32 1 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_dec_noret_i32_offset(
define void @global_atomic_dec_noret_i32_offset(i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw sub i32 addrspace(1)* %gep, i32 1 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_and_noret_i32(
; HSAIL: atomicnoret_and_global_scar_system_b32 [{{\$s[0-9]+}}], 4;
define void @global_atomic_and_noret_i32(i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw and i32 addrspace(1)* %ptr, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_and_noret_i32_offset(
; HSAIL: atomicnoret_and_global_scar_system_b32 [{{\$s[0-9]+}}+16], 4;
define void @global_atomic_and_noret_i32_offset(i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw and i32 addrspace(1)* %gep, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_or_noret_i32(
; HSAIL: atomicnoret_or_global_scar_system_b32 [{{\$s[0-9]+}}], 4;
define void @global_atomic_or_noret_i32(i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw or i32 addrspace(1)* %ptr, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_or_noret_i32_offset(
; HSAIL: atomicnoret_or_global_scar_system_b32 [{{\$s[0-9]+}}+16], 4;
define void @global_atomic_or_noret_i32_offset(i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw or i32 addrspace(1)* %gep, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_xor_noret_i32(
; HSAIL: atomicnoret_xor_global_scar_system_b32 [{{\$s[0-9]+}}], 4;
define void @global_atomic_xor_noret_i32(i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw xor i32 addrspace(1)* %ptr, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_xor_noret_i32_offset(
; HSAIL: atomicnoret_xor_global_scar_system_b32 [{{\$s[0-9]+}}+16], 4;
define void @global_atomic_xor_noret_i32_offset(i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw xor i32 addrspace(1)* %gep, i32 4 seq_cst
  ret void
}

; FIXME: There is no atomic nand instr
; XHSAIL-LABEL: {{^}}prog function &global_atomic_nand_noret_i32(uction, so we somehow need to expand this.
; define void @global_atomic_nand_noret_i32(i32 addrspace(1)* %ptr) nounwind {
;   %result = atomicrmw nand i32 addrspace(1)* %ptr, i32 4 seq_cst
;   ret void
; }

; HSAIL-LABEL: {{^}}prog function &global_atomic_min_noret_i32(
; HSAIL: atomicnoret_min_global_scar_system_s32 [{{\$s[0-9]+}}], 4;
define void @global_atomic_min_noret_i32(i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw min i32 addrspace(1)* %ptr, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_min_noret_i32_offset(
; HSAIL: atomicnoret_min_global_scar_system_s32 [{{\$s[0-9]+}}+16], 4;
define void @global_atomic_min_noret_i32_offset(i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw min i32 addrspace(1)* %gep, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_max_noret_i32(
; HSAIL: atomicnoret_max_global_scar_system_s32 [{{\$s[0-9]+}}], 4;
define void @global_atomic_max_noret_i32(i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw max i32 addrspace(1)* %ptr, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_max_noret_i32_offset(
; HSAIL: atomicnoret_max_global_scar_system_s32 [{{\$s[0-9]+}}+16], 4;
define void @global_atomic_max_noret_i32_offset(i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw max i32 addrspace(1)* %gep, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_umin_noret_i32(
; HSAIL: atomicnoret_min_global_scar_system_u32 [{{\$s[0-9]+}}], 4;
define void @global_atomic_umin_noret_i32(i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw umin i32 addrspace(1)* %ptr, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_umin_noret_i32_offset(
; HSAIL: atomicnoret_min_global_scar_system_u32 [{{\$s[0-9]+}}+16], 4;
define void @global_atomic_umin_noret_i32_offset(i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw umin i32 addrspace(1)* %gep, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_umax_noret_i32(
; HSAIL: atomicnoret_max_global_scar_system_u32 [{{\$s[0-9]+}}], 4;
define void @global_atomic_umax_noret_i32(i32 addrspace(1)* %ptr) nounwind {
  %result = atomicrmw umax i32 addrspace(1)* %ptr, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_umax_noret_i32_offset(
; HSAIL: atomicnoret_max_global_scar_system_u32 [{{\$s[0-9]+}}+16], 4;
define void @global_atomic_umax_noret_i32_offset(i32 addrspace(1)* %ptr) nounwind {
  %gep = getelementptr i32 addrspace(1)* %ptr, i32 4
  %result = atomicrmw umax i32 addrspace(1)* %gep, i32 4 seq_cst
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_load_acquire_ret_i32(
; HSAIL: atomic_ld_global_scacq_system_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}];
define void @global_atomic_load_acquire_ret_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %result = load atomic i32 addrspace(1)* %ptr acquire, align 4
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_load_seq_cst_ret_i32(
; HSAIL: memfence_screl_system;
; HSAIL: atomic_ld_global_scacq_system_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}];
define void @global_atomic_load_seq_cst_ret_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %result = load atomic i32 addrspace(1)* %ptr seq_cst, align 4
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_load_monotonic_ret_i32(
; HSAIL: atomic_ld_global_rlx_system_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}];
define void @global_atomic_load_monotonic_ret_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %ptr) nounwind {
  %result = load atomic i32 addrspace(1)* %ptr monotonic, align 4
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_store_release_i32(
; HSAIL: atomicnoret_st_global_screl_system_b32 [{{\$s[0-9]+}}], 9;
define void @global_atomic_store_release_i32(i32 addrspace(1)* %ptr) nounwind {
  store atomic i32 9, i32 addrspace(1)* %ptr release, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_store_seq_cst_i32(
; HSAIL: atomicnoret_st_global_screl_system_b32 [{{\$s[0-9]+}}], 9;
; HSAIL: memfence_scacq_system;
define void @global_atomic_store_seq_cst_i32(i32 addrspace(1)* %ptr) nounwind {
  store atomic i32 9, i32 addrspace(1)* %ptr seq_cst, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_atomic_store_monotonic_i32(
; HSAIL: atomicnoret_st_global_rlx_system_b32 [{{\$s[0-9]+}}], {{\$s[0-9]+}};
define void @global_atomic_store_monotonic_i32(i32 addrspace(1)* %ptr, i32 %foo) nounwind {
  store atomic i32 %foo, i32 addrspace(1)* %ptr monotonic, align 4
  ret void
}
