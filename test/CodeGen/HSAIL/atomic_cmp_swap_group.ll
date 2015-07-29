; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &lds_atomic_cmpxchg_ret_i32_offset(
; HSAIL: atomic_cas_group_scar_wg_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 7, {{\$s[0-9]+}};
define void @lds_atomic_cmpxchg_ret_i32_offset(i32 addrspace(1)* %out, i32 addrspace(3)* %ptr, i32 %swap) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %pair = cmpxchg i32 addrspace(3)* %gep, i32 7, i32 %swap seq_cst monotonic
  %result = extractvalue { i32, i1 } %pair, 0
  store i32 %result, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &lds_atomic_cmpxchg_ret_i64_offset(
; HSAIL: atomic_cas_group_scar_wg_b64 {{\$d[0-9]+}}, [{{\$s[0-9]+}}+32], 7, {{\$d[0-9]+}};
define void @lds_atomic_cmpxchg_ret_i64_offset(i64 addrspace(1)* %out, i64 addrspace(3)* %ptr, i64 %swap) nounwind {
  %gep = getelementptr i64 addrspace(3)* %ptr, i32 4
  %pair = cmpxchg i64 addrspace(3)* %gep, i64 7, i64 %swap seq_cst monotonic
  %result = extractvalue { i64, i1 } %pair, 0
  store i64 %result, i64 addrspace(1)* %out, align 8
  ret void
}

; HSAIL-LABEL: {{^}}prog function &lds_atomic_cmpxchg_noret_i32_offset(
; HSAIL: atomic_cas_group_scar_wg_b32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+16], 7, {{\$s[0-9]+}};
define void @lds_atomic_cmpxchg_noret_i32_offset(i32 addrspace(3)* %ptr, i32 %swap) nounwind {
  %gep = getelementptr i32 addrspace(3)* %ptr, i32 4
  %pair = cmpxchg i32 addrspace(3)* %gep, i32 7, i32 %swap seq_cst monotonic
  %result = extractvalue { i32, i1 } %pair, 0
  ret void
}

; HSAIL-LABEL: {{^}}prog function &lds_atomic_cmpxchg_noret_i64_offset(
; HSAIL: atomic_cas_group_scar_wg_b64 {{\$d[0-9]+}}, [{{\$s[0-9]+}}+32], 7, {{\$d[0-9]+}};
define void @lds_atomic_cmpxchg_noret_i64_offset(i64 addrspace(3)* %ptr, i64 %swap) nounwind {
  %gep = getelementptr i64 addrspace(3)* %ptr, i32 4
  %pair = cmpxchg i64 addrspace(3)* %gep, i64 7, i64 %swap seq_cst monotonic
  %result = extractvalue { i64, i1 } %pair, 0
  ret void
}
