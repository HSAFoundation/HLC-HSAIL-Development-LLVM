; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL: prog alloc(agent) global_u32 &global_i32_undef;
@global_i32_undef = addrspace(1) global i32 undef

; HSAIL: prog alloc(agent) global_u32 &global_i32_zeroinit = 0;
@global_i32_zeroinit = addrspace(1) global i32 zeroinitializer

; HSAIL: prog alloc(agent) global_f32 &global_f32_undef;
@global_f32_undef = addrspace(1) global float undef

; HSAIL: prog alloc(agent) global_f32 &global_f32_zeroinit = 0F00000000;
@global_f32_zeroinit = addrspace(1) global float zeroinitializer

; HSAIL: prog alloc(agent) global_f32 &global_f32_init = 0F3f800000;
@global_f32_init = addrspace(1) global float 1.0

; HSAIL: prog alloc(agent) global_f32 &global_f32_array_init[5] = f32[](0F00000000, 0F3f800000, 0F40000000, 0F40400000, 0F40800000);

@global_f32_array_init = addrspace(1) global [5 x float] [float 0.0, float 1.0, float 2.0, float 3.0, float 4.0], align 4

; HSAIL: prog readonly_u32 &readonly_i32_zeroinit = 0;
@readonly_i32_zeroinit = addrspace(2) global i32 zeroinitializer
