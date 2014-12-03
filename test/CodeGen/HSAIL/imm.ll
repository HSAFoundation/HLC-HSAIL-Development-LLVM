; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &i64_imm_inline_lo
; HSAIL: st_global_align(8)_u64 1311768464867721221, [$s{{[0-9]+}}];
define void @i64_imm_inline_lo(i64 addrspace(1) *%out) {
  store i64 1311768464867721221, i64 addrspace(1) *%out ; 0x1234567800000005
  ret void
}

; FUNC-LABEL: {{^}}prog function &i64_imm_inline_hi
; HSAIL: st_global_align(8)_u64 21780256376, [$s{{[0-9]+}}];
define void @i64_imm_inline_hi(i64 addrspace(1) *%out) {
entry:
  store i64 21780256376, i64 addrspace(1) *%out ; 0x0000000512345678
  ret void
}
