; RUN: llc -march=hsail64 < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL: prog alloc(agent) global_u32 &gv_with_ptr = 0;
; HSAIL: pragma "initvarwithaddress:&gv_with_ptr:0:4:0:4";

@gv_with_ptr = addrspace(1) global i32* inttoptr (i64 4 to i32*), align 4
