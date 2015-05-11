; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL64 -check-prefix=HSAIL %s

; HSAIL-DAG: prog readonly_u32 &ptr_to_int_gv_p3i32 = 0;
; HSAIL-DAG: pragma  "initvarwithaddress:&ptr_to_int_gv_p3i32:0:4:%lds.int0:0";

; HSAIL32-DAG: prog readonly_u32 &ptr_to_int_gv_p2i32 = 0;
; HSAIL32-DAG: pragma  "initvarwithaddress:&ptr_to_int_gv_p2i32:0:4:&int0:0";

@int0 = internal unnamed_addr addrspace(2) constant i32 9
@lds.int0 = internal unnamed_addr addrspace(3) global i32 undef

@ptr_to_int_gv_p3i32 = addrspace(2) constant i32 ptrtoint (i32 addrspace(3)* @lds.int0 to i32)
@ptr_to_int_gv_p2i32 = addrspace(2) constant i32 ptrtoint (i32 addrspace(2)* @int0 to i32)