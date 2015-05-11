; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL: prog alloc(agent) global_u32 &global_i32_undef;
@global_i32_undef = addrspace(1) global i32 undef

; HSAIL: prog alloc(agent) global_u32 &global_i32_zeroinit = 0;

@global_i32_zeroinit = addrspace(1) global i32 zeroinitializer

; HSAIL: prog readonly_u32 &readonly_i32_zeroinit = 0;

@readonly_i32_zeroinit = addrspace(2) global i32 zeroinitializer
