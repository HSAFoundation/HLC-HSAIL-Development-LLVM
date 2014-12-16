; XFAIL: *
; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL32 -check-prefix=HSAIL %s
; RUN: llc -march=hsail64 -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL64 -check-prefix=HSAIL %s

; constantexpr ptrtoints to the wrong pointer size assert

@int0 = internal unnamed_addr addrspace(2) constant i32 9
@lds.int0 = internal unnamed_addr addrspace(3) global i32 undef

@ptr_to_int_gv_p3i32_ext = addrspace(2) constant i64 ptrtoint (i32 addrspace(3)* @lds.int0 to i64)
@ptr_to_int_gv_p2i32_trunc = addrspace(2) constant i32 ptrtoint (i32 addrspace(2)* @int0 to i32)


