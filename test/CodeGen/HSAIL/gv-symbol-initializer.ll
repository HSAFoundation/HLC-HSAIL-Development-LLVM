; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL32 -check-prefix=HSAIL %s
; RUN: llc -march=hsail64 -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL64 -check-prefix=HSAIL %s


; HSAIL: readonly_u32 &int0 = 9;
; HSAIL: readonly_u32 &int1 = 34;
; HSAIL: readonly_u32 &int2 = 123;
; HSAIL: readonly_u32 &int3 = 222;
; HSAIL: readonly_u32 &int4 = 2424;


; HSAIL32: readonly_u32 &symbol_array[5] = u32[](0, 0, 0, 0, 0);
; HSAIL32: pragma  "initvarwithaddress:&symbol_array:0:4:&int0:0";
; HSAIL32: pragma  "initvarwithaddress:&symbol_array:4:4:&int1:0";
; HSAIL32: pragma  "initvarwithaddress:&symbol_array:8:4:&int2:0";
; HSAIL32: pragma  "initvarwithaddress:&symbol_array:12:4:&int3:0";
; HSAIL32: pragma  "initvarwithaddress:&symbol_array:16:4:&int4:0";

; HSAIL32: readonly_u32 &i32_array[10] = u32[](234, 456, 789, 235, 495, 1, 4, 9, 10, 453);

; HSAIL32: readonly_u32 &constantexpr_address_array[5] = u32[](0, 0, 0, 0, 0);
; HSAIL32: pragma  "initvarwithaddress:&constantexpr_address_array:0:4:&i32_array:0";
; HSAIL32: pragma  "initvarwithaddress:&constantexpr_address_array:4:4:&i32_array:16";
; HSAIL32: pragma  "initvarwithaddress:&constantexpr_address_array:8:4:&i32_array:32";
; HSAIL32: pragma  "initvarwithaddress:&constantexpr_address_array:12:4:&i32_array:36";
; HSAIL32: pragma  "initvarwithaddress:&constantexpr_address_array:16:4:&i32_array:12";

; HSAIL32: align(8) readonly_u8 &struct_foo_gv[16] = u8[](0, 0, 128, 65, 0, 0, 0, 0, 0, 0, 0, 66, 0, 0, 0, 0);
; HSAIL32: pragma  "initvarwithaddress:&struct_foo_gv:4:1:&constantexpr_address_array:0";
; HSAIL32: pragma  "initvarwithaddress:&struct_foo_gv:12:1:&symbol_array:0";

; HSAIL32: align(8) readonly_u8 &struct_bar_gv[24] = u8[](7, 0, 0, 0, 0, 0, 0, 0, 23, 0, 0, 0, 45, 0, 0, 0, 0, 0, 0, 0, 212, 0, 0, 0);
; HSAIL32: pragma  "initvarwithaddress:&struct_bar_gv:4:1:&constantexpr_address_array:0";
; HSAIL32: pragma  "initvarwithaddress:&struct_bar_gv:16:1:&symbol_array:0";

; HSAIL32: align(8) readonly_u8 &struct_packed_bar_gv[12] = u8[](7, 0, 0, 0, 0, 23, 45, 0, 0, 0, 0, 212);
; HSAIL32: pragma  "initvarwithaddress:&struct_packed_bar_gv:1:1:&constantexpr_address_array:0";
; HSAIL32: pragma  "initvarwithaddress:&struct_packed_bar_gv:7:1:&symbol_array:0";

; HSAIL32: align(8) readonly_u8 &struct_mixed_nullptr_sizes_0[16] = u8[](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
; HSAIL32: align(8) readonly_u8 &struct_mixed_nullptr_sizes_1[16] = u8[](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
; HSAIL32: pragma  "initvarwithaddress:&struct_mixed_nullptr_sizes_1:4:1:&int1:0";
; HSAIL32: pragma  "initvarwithaddress:&struct_mixed_nullptr_sizes_1:8:1:%lds.int0:0";

; HSAIL32: readonly_u32 &lds_symbol_array[5] = u32[](0, 0, 0, 0, 0);
; HSAIL32: pragma  "initvarwithaddress:&lds_symbol_array:0:4:%lds.int0:0";
; HSAIL32: pragma  "initvarwithaddress:&lds_symbol_array:4:4:%lds.int1:0";
; HSAIL32: pragma  "initvarwithaddress:&lds_symbol_array:8:4:%lds.int2:0";
; HSAIL32: pragma  "initvarwithaddress:&lds_symbol_array:12:4:%lds.int3:0";
; HSAIL32: pragma  "initvarwithaddress:&lds_symbol_array:16:4:%lds.int4:0";



; HSAIL32: prog readonly_u32 &scalar_p2i32 = 0;
; HSAIL32: pragma  "initvarwithaddress:&scalar_p2i32:0:4:&int0:0";

; HSAIL32: prog readonly_u32 &scalar_p3i32 = 0;
; HSAIL32: pragma  "initvarwithaddress:&scalar_p3i32:0:4:%lds.int0:0";

; HSAIL32: prog align(16) readonly_u32 &zero_vector_v4p2i32[4] = u32[](0, 0, 0, 0);
; HSAIL32: prog align(16) readonly_u32 &zero_vector_v3p2i32[4] = u32[](0, 0, 0, 0);

; HSAIL32: prog readonly_u32 &p2i32_array[4] = u32[](0, 0, 0, 0);
; HSAIL32: pragma  "initvarwithaddress:&p2i32_array:0:4:&int0:0";
; HSAIL32: pragma  "initvarwithaddress:&p2i32_array:4:4:&int1:0";
; HSAIL32: pragma  "initvarwithaddress:&p2i32_array:8:4:&int2:0";
; HSAIL32: pragma  "initvarwithaddress:&p2i32_array:12:4:&int3:0";

; HSAIL32: prog readonly_u32 &p3i32_array[4] = u32[](0, 0, 0, 0);
; HSAIL32: pragma  "initvarwithaddress:&p3i32_array:0:4:%lds.int0:0";
; HSAIL32: pragma  "initvarwithaddress:&p3i32_array:4:4:%lds.int1:0";
; HSAIL32: pragma  "initvarwithaddress:&p3i32_array:8:4:%lds.int2:0";
; HSAIL32: pragma  "initvarwithaddress:&p3i32_array:12:4:%lds.int3:0";

; HSAIL32: prog readonly_u32 &p2i32_array_array[16] = u32[](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
; HSAIL32: pragma  "initvarwithaddress:&p2i32_array_array:0:4:&int0:0";
; HSAIL32: pragma  "initvarwithaddress:&p2i32_array_array:4:4:&int1:0";
; HSAIL32: pragma  "initvarwithaddress:&p2i32_array_array:8:4:&int2:0";
; HSAIL32: pragma  "initvarwithaddress:&p2i32_array_array:12:4:&int3:0";
; HSAIL32: pragma  "initvarwithaddress:&p2i32_array_array:16:4:&int0:0";
; HSAIL32: pragma  "initvarwithaddress:&p2i32_array_array:20:4:&int1:0";
; HSAIL32: pragma  "initvarwithaddress:&p2i32_array_array:24:4:&int2:0";
; HSAIL32: pragma  "initvarwithaddress:&p2i32_array_array:28:4:&int3:0";
; HSAIL32: pragma  "initvarwithaddress:&p2i32_array_array:32:4:&int0:0";
; HSAIL32: pragma  "initvarwithaddress:&p2i32_array_array:36:4:&int1:0";
; HSAIL32: pragma  "initvarwithaddress:&p2i32_array_array:40:4:&int2:0";
; HSAIL32: pragma  "initvarwithaddress:&p2i32_array_array:44:4:&int3:0";
; HSAIL32: pragma  "initvarwithaddress:&p2i32_array_array:48:4:&int0:0";
; HSAIL32: pragma  "initvarwithaddress:&p2i32_array_array:52:4:&int1:0";
; HSAIL32: pragma  "initvarwithaddress:&p2i32_array_array:56:4:&int2:0";
; HSAIL32: pragma  "initvarwithaddress:&p2i32_array_array:60:4:&int3:0";

; HSAIL32: prog readonly_u32 &p3i32_array_array[16] = u32[](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
; HSAIL32: pragma  "initvarwithaddress:&p3i32_array_array:0:4:%lds.int0:0";
; HSAIL32: pragma  "initvarwithaddress:&p3i32_array_array:4:4:%lds.int1:0";
; HSAIL32: pragma  "initvarwithaddress:&p3i32_array_array:8:4:%lds.int2:0";
; HSAIL32: pragma  "initvarwithaddress:&p3i32_array_array:12:4:%lds.int3:0";
; HSAIL32: pragma  "initvarwithaddress:&p3i32_array_array:16:4:%lds.int0:0";
; HSAIL32: pragma  "initvarwithaddress:&p3i32_array_array:20:4:%lds.int1:0";
; HSAIL32: pragma  "initvarwithaddress:&p3i32_array_array:24:4:%lds.int2:0";
; HSAIL32: pragma  "initvarwithaddress:&p3i32_array_array:28:4:%lds.int3:0";
; HSAIL32: pragma  "initvarwithaddress:&p3i32_array_array:32:4:%lds.int0:0";
; HSAIL32: pragma  "initvarwithaddress:&p3i32_array_array:36:4:%lds.int1:0";
; HSAIL32: pragma  "initvarwithaddress:&p3i32_array_array:40:4:%lds.int2:0";
; HSAIL32: pragma  "initvarwithaddress:&p3i32_array_array:44:4:%lds.int3:0";
; HSAIL32: pragma  "initvarwithaddress:&p3i32_array_array:48:4:%lds.int0:0";
; HSAIL32: pragma  "initvarwithaddress:&p3i32_array_array:52:4:%lds.int1:0";
; HSAIL32: pragma  "initvarwithaddress:&p3i32_array_array:56:4:%lds.int2:0";
; HSAIL32: pragma  "initvarwithaddress:&p3i32_array_array:60:4:%lds.int3:0";

; HSAIL32: prog readonly_u32 &ptr_to_int_gv_p3i32 = 0;
; HSAIL32: pragma  "initvarwithaddress:&ptr_to_int_gv_p3i32:0:4:%lds.int0:0";

; HSAIL32: prog readonly_u32 &ptr_to_int_array_gv_p3i32[4] = u32[](0, 0, 0, 0);
; HSAIL32: pragma  "initvarwithaddress:&ptr_to_int_array_gv_p3i32:0:4:%lds.int0:0";
; HSAIL32: pragma  "initvarwithaddress:&ptr_to_int_array_gv_p3i32:4:4:%lds.int1:0";
; HSAIL32: pragma  "initvarwithaddress:&ptr_to_int_array_gv_p3i32:8:4:%lds.int2:0";
; HSAIL32: pragma  "initvarwithaddress:&ptr_to_int_array_gv_p3i32:12:4:%lds.int3:0";


; HSAIL64: readonly_u64 &symbol_array[5] = u64[](0, 0, 0, 0, 0);
; HSAIL64: pragma  "initvarwithaddress:&symbol_array:0:8:&int0:0";
; HSAIL64: pragma  "initvarwithaddress:&symbol_array:8:8:&int1:0";
; HSAIL64: pragma  "initvarwithaddress:&symbol_array:16:8:&int2:0";
; HSAIL64: pragma  "initvarwithaddress:&symbol_array:24:8:&int3:0";
; HSAIL64: pragma  "initvarwithaddress:&symbol_array:32:8:&int4:0";

; HSAIL64: readonly_u32 &i32_array[10] = u32[](234, 456, 789, 235, 495, 1, 4, 9, 10, 453);
; HSAIL64: readonly_u64 &constantexpr_address_array[5] = u64[](0, 0, 0, 0, 0);

; HSAIL64: pragma  "initvarwithaddress:&constantexpr_address_array:0:8:&i32_array:0";
; HSAIL64: pragma  "initvarwithaddress:&constantexpr_address_array:8:8:&i32_array:16";
; HSAIL64: pragma  "initvarwithaddress:&constantexpr_address_array:16:8:&i32_array:32";
; HSAIL64: pragma  "initvarwithaddress:&constantexpr_address_array:24:8:&i32_array:36";
; HSAIL64: pragma  "initvarwithaddress:&constantexpr_address_array:32:8:&i32_array:12";

; HSAIL64: align(8) readonly_u8 &struct_foo_gv[32] = u8[](0, 0, 128, 65, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
; HSAIL64: pragma  "initvarwithaddress:&struct_foo_gv:8:1:&constantexpr_address_array:0";
; HSAIL64: pragma  "initvarwithaddress:&struct_foo_gv:24:1:&symbol_array:0";

; HSAIL64: align(8) readonly_u8 &struct_bar_gv[48] = u8[](7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 23, 0, 0, 0, 0, 0, 0, 0, 45, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 212, 0, 0, 0, 0, 0, 0, 0);
; HSAIL64: pragma  "initvarwithaddress:&struct_bar_gv:8:1:&constantexpr_address_array:0";
; HSAIL64: pragma  "initvarwithaddress:&struct_bar_gv:32:1:&symbol_array:0";

; HSAIL64: align(8) readonly_u8 &struct_packed_bar_gv[20] = u8[](7, 0, 0, 0, 0, 0, 0, 0, 0, 23, 45, 0, 0, 0, 0, 0, 0, 0, 0, 212);
; HSAIL64: pragma  "initvarwithaddress:&struct_packed_bar_gv:1:1:&constantexpr_address_array:0";
; HSAIL64: pragma  "initvarwithaddress:&struct_packed_bar_gv:11:1:&symbol_array:0";

; HSAIL64: align(8) readonly_u8 &struct_mixed_nullptr_sizes_0[32] = u8[](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
; HSAIL64: align(8) readonly_u8 &struct_mixed_nullptr_sizes_1[32] = u8[](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
; HSAIL64: pragma  "initvarwithaddress:&struct_mixed_nullptr_sizes_1:8:1:&int1:0";
; HSAIL64: pragma  "initvarwithaddress:&struct_mixed_nullptr_sizes_1:16:1:%lds.int0:0";

; HSAIL64: readonly_u32 &lds_symbol_array[5] = u32[](0, 0, 0, 0, 0);
; HSAIL64: pragma  "initvarwithaddress:&lds_symbol_array:0:4:%lds.int0:0";
; HSAIL64: pragma  "initvarwithaddress:&lds_symbol_array:4:4:%lds.int1:0";
; HSAIL64: pragma  "initvarwithaddress:&lds_symbol_array:8:4:%lds.int2:0";
; HSAIL64: pragma  "initvarwithaddress:&lds_symbol_array:12:4:%lds.int3:0";
; HSAIL64: pragma  "initvarwithaddress:&lds_symbol_array:16:4:%lds.int4:0";


; HSAIL64: prog readonly_u64 &scalar_p2i32 = 0;
; HSAIL64: pragma  "initvarwithaddress:&scalar_p2i32:0:8:&int0:0";

; HSAIL64: prog readonly_u32 &scalar_p3i32 = 0;
; HSAIL64: pragma  "initvarwithaddress:&scalar_p3i32:0:4:%lds.int0:0";

; HSAIL64: prog align(32) readonly_u64 &zero_vector_v4p2i32[4] = u64[](0, 0, 0, 0);
; HSAIL64: prog align(16) readonly_u32 &zero_vector_v3p2i32[4] = u32[](0, 0, 0, 0);

; HSAIL64: prog readonly_u64 &p2i32_array[4] = u64[](0, 0, 0, 0);
; HSAIL64: pragma  "initvarwithaddress:&p2i32_array:0:8:&int0:0";
; HSAIL64: pragma  "initvarwithaddress:&p2i32_array:8:8:&int1:0";
; HSAIL64: pragma  "initvarwithaddress:&p2i32_array:16:8:&int2:0";
; HSAIL64: pragma  "initvarwithaddress:&p2i32_array:24:8:&int3:0";

; HSAIL64: prog readonly_u32 &p3i32_array[4] = u32[](0, 0, 0, 0);
; HSAIL64: pragma  "initvarwithaddress:&p3i32_array:0:4:%lds.int0:0";
; HSAIL64: pragma  "initvarwithaddress:&p3i32_array:4:4:%lds.int1:0";
; HSAIL64: pragma  "initvarwithaddress:&p3i32_array:8:4:%lds.int2:0";
; HSAIL64: pragma  "initvarwithaddress:&p3i32_array:12:4:%lds.int3:0";

; HSAIL64: prog readonly_u64 &p2i32_array_array[16] = u64[](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
; HSAIL64: pragma  "initvarwithaddress:&p2i32_array_array:0:8:&int0:0";
; HSAIL64: pragma  "initvarwithaddress:&p2i32_array_array:8:8:&int1:0";
; HSAIL64: pragma  "initvarwithaddress:&p2i32_array_array:16:8:&int2:0";
; HSAIL64: pragma  "initvarwithaddress:&p2i32_array_array:24:8:&int3:0";
; HSAIL64: pragma  "initvarwithaddress:&p2i32_array_array:32:8:&int0:0";
; HSAIL64: pragma  "initvarwithaddress:&p2i32_array_array:40:8:&int1:0";
; HSAIL64: pragma  "initvarwithaddress:&p2i32_array_array:48:8:&int2:0";
; HSAIL64: pragma  "initvarwithaddress:&p2i32_array_array:56:8:&int3:0";
; HSAIL64: pragma  "initvarwithaddress:&p2i32_array_array:64:8:&int0:0";
; HSAIL64: pragma  "initvarwithaddress:&p2i32_array_array:72:8:&int1:0";
; HSAIL64: pragma  "initvarwithaddress:&p2i32_array_array:80:8:&int2:0";
; HSAIL64: pragma  "initvarwithaddress:&p2i32_array_array:88:8:&int3:0";
; HSAIL64: pragma  "initvarwithaddress:&p2i32_array_array:96:8:&int0:0";
; HSAIL64: pragma  "initvarwithaddress:&p2i32_array_array:104:8:&int1:0";
; HSAIL64: pragma  "initvarwithaddress:&p2i32_array_array:112:8:&int2:0";
; HSAIL64: pragma  "initvarwithaddress:&p2i32_array_array:120:8:&int3:0";

; HSAIL64: prog readonly_u32 &p3i32_array_array[16] = u32[](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
; HSAIL64: pragma  "initvarwithaddress:&p3i32_array_array:0:4:%lds.int0:0";
; HSAIL64: pragma  "initvarwithaddress:&p3i32_array_array:4:4:%lds.int1:0";
; HSAIL64: pragma  "initvarwithaddress:&p3i32_array_array:8:4:%lds.int2:0";
; HSAIL64: pragma  "initvarwithaddress:&p3i32_array_array:12:4:%lds.int3:0";
; HSAIL64: pragma  "initvarwithaddress:&p3i32_array_array:16:4:%lds.int0:0";
; HSAIL64: pragma  "initvarwithaddress:&p3i32_array_array:20:4:%lds.int1:0";
; HSAIL64: pragma  "initvarwithaddress:&p3i32_array_array:24:4:%lds.int2:0";
; HSAIL64: pragma  "initvarwithaddress:&p3i32_array_array:28:4:%lds.int3:0";
; HSAIL64: pragma  "initvarwithaddress:&p3i32_array_array:32:4:%lds.int0:0";
; HSAIL64: pragma  "initvarwithaddress:&p3i32_array_array:36:4:%lds.int1:0";
; HSAIL64: pragma  "initvarwithaddress:&p3i32_array_array:40:4:%lds.int2:0";
; HSAIL64: pragma  "initvarwithaddress:&p3i32_array_array:44:4:%lds.int3:0";
; HSAIL64: pragma  "initvarwithaddress:&p3i32_array_array:48:4:%lds.int0:0";
; HSAIL64: pragma  "initvarwithaddress:&p3i32_array_array:52:4:%lds.int1:0";
; HSAIL64: pragma  "initvarwithaddress:&p3i32_array_array:56:4:%lds.int2:0";
; HSAIL64: pragma  "initvarwithaddress:&p3i32_array_array:60:4:%lds.int3:0";


; HSAIL64: prog readonly_u32 &ptr_to_int_gv_p3i32 = 0;
; HSAIL64: pragma  "initvarwithaddress:&ptr_to_int_gv_p3i32:0:4:%lds.int0:0";

; HSAIL64: prog readonly_u32 &ptr_to_int_array_gv_p3i32[4] = u32[](0, 0, 0, 0);
; HSAIL64: pragma  "initvarwithaddress:&ptr_to_int_array_gv_p3i32:0:4:%lds.int0:0";
; HSAIL64: pragma  "initvarwithaddress:&ptr_to_int_array_gv_p3i32:4:4:%lds.int1:0";
; HSAIL64: pragma  "initvarwithaddress:&ptr_to_int_array_gv_p3i32:8:4:%lds.int2:0";
; HSAIL64: pragma  "initvarwithaddress:&ptr_to_int_array_gv_p3i32:12:4:%lds.int3:0";


@int0 = internal unnamed_addr addrspace(2) constant i32 9
@int1 = internal unnamed_addr addrspace(2) constant i32 34
@int2 = internal unnamed_addr addrspace(2) constant i32 123
@int3 = internal unnamed_addr addrspace(2) constant i32 222
@int4 = internal unnamed_addr addrspace(2) constant i32 2424

@symbol_array = internal addrspace(2) constant [5 x i32 addrspace(2)*] [ i32 addrspace(2)* @int0, i32 addrspace(2)* @int1, i32 addrspace(2)* @int2, i32 addrspace(2)* @int3, i32 addrspace(2)* @int4 ]
@i32_array = internal unnamed_addr addrspace(2) constant [10 x i32] [i32 234, i32 456, i32 789, i32 235, i32 495, i32 1, i32 4, i32 9, i32 10, i32 453], align 4


@constantexpr_address_array = internal addrspace(2) constant [5 x i32 addrspace(2)*] [
  i32 addrspace(2)* getelementptr ([10 x i32], [10 x i32] addrspace(2)* @i32_array, i32 0, i32 0),
  i32 addrspace(2)* getelementptr ([10 x i32], [10 x i32] addrspace(2)* @i32_array, i32 0, i32 4),
  i32 addrspace(2)* getelementptr ([10 x i32], [10 x i32] addrspace(2)* @i32_array, i32 0, i32 8),
  i32 addrspace(2)* getelementptr ([10 x i32], [10 x i32] addrspace(2)* @i32_array, i32 0, i32 9),
  i32 addrspace(2)* getelementptr ([10 x i32], [10 x i32] addrspace(2)* @i32_array, i32 0, i32 3)
]

%struct.foo = type { float, [5 x i32 addrspace(2)*] addrspace(2)* }

%struct.bar = type { i8, [5 x i32 addrspace(2)*] addrspace(2)*, i8 }
%struct.packed.bar = type <{ i8, [5 x i32 addrspace(2)*] addrspace(2)*, i8 }>

%struct.mixed.nullptr.sizes = type { i32 addrspace(3)*, i32 addrspace(2)* }


@struct_foo_gv = internal unnamed_addr addrspace(2) constant [2 x %struct.foo] [
  %struct.foo { float 16.0, [5 x i32 addrspace(2)*] addrspace(2)* @constantexpr_address_array },
  %struct.foo { float 32.0, [5 x i32 addrspace(2)*] addrspace(2)* @symbol_array }
]

@struct_bar_gv = internal unnamed_addr addrspace(2) constant [2 x %struct.bar] [
  %struct.bar { i8 7, [5 x i32 addrspace(2)*] addrspace(2)* @constantexpr_address_array, i8 23 },
  %struct.bar { i8 45, [5 x i32 addrspace(2)*] addrspace(2)* @symbol_array, i8 212 }
]

@struct_packed_bar_gv = internal unnamed_addr addrspace(2) constant [2 x %struct.packed.bar] [
  %struct.packed.bar <{ i8 7, [5 x i32 addrspace(2)*] addrspace(2)* @constantexpr_address_array, i8 23 }>,
  %struct.packed.bar <{ i8 45, [5 x i32 addrspace(2)*] addrspace(2)* @symbol_array, i8 212 }>
]


@lds.int0 = internal unnamed_addr addrspace(3) global i32 undef
@lds.int1 = internal unnamed_addr addrspace(3) global i32 undef
@lds.int2 = internal unnamed_addr addrspace(3) global i32 undef
@lds.int3 = internal unnamed_addr addrspace(3) global i32 undef
@lds.int4 = internal unnamed_addr addrspace(3) global i32 undef


@struct_mixed_nullptr_sizes_0 = internal unnamed_addr addrspace(2) constant [2 x %struct.mixed.nullptr.sizes] zeroinitializer
@struct_mixed_nullptr_sizes_1 = internal unnamed_addr addrspace(2) constant [2 x %struct.mixed.nullptr.sizes] [
  %struct.mixed.nullptr.sizes { i32 addrspace(3)* null, i32 addrspace(2)* @int1 },
  %struct.mixed.nullptr.sizes { i32 addrspace(3)* @lds.int0, i32 addrspace(2)* null }
]

@lds_symbol_array = internal addrspace(2) constant [5 x i32 addrspace(3)*] [ i32 addrspace(3)* @lds.int0, i32 addrspace(3)* @lds.int1, i32 addrspace(3)* @lds.int2, i32 addrspace(3)* @lds.int3, i32 addrspace(3)* @lds.int4 ]



@scalar_p2i32 = addrspace(2) constant i32 addrspace(2)* @int0
@scalar_p3i32 = addrspace(2) constant i32 addrspace(3)* @lds.int0

@zero_vector_v4p2i32 = addrspace(2) constant <4 x i32 addrspace(2)*> zeroinitializer
@zero_vector_v3p2i32 = addrspace(2) constant <3 x i32 addrspace(3)*> zeroinitializer

@p2i32_array = addrspace(2) constant [4 x i32 addrspace(2)*] [ i32 addrspace(2)* @int0, i32 addrspace(2)* @int1, i32 addrspace(2)* @int2, i32 addrspace(2)* @int3]

@p3i32_array = addrspace(2) constant [4 x i32 addrspace(3)*] [ i32 addrspace(3)* @lds.int0, i32 addrspace(3)* @lds.int1, i32 addrspace(3)* @lds.int2, i32 addrspace(3)* @lds.int3]

@p2i32_array_array = addrspace(2) constant [4 x [4 x i32 addrspace(2)*]] [
  [4 x i32 addrspace(2)*] [ i32 addrspace(2)* @int0, i32 addrspace(2)* @int1, i32 addrspace(2)* @int2, i32 addrspace(2)* @int3],
  [4 x i32 addrspace(2)*] [ i32 addrspace(2)* @int0, i32 addrspace(2)* @int1, i32 addrspace(2)* @int2, i32 addrspace(2)* @int3],
  [4 x i32 addrspace(2)*] [ i32 addrspace(2)* @int0, i32 addrspace(2)* @int1, i32 addrspace(2)* @int2, i32 addrspace(2)* @int3],
  [4 x i32 addrspace(2)*] [ i32 addrspace(2)* @int0, i32 addrspace(2)* @int1, i32 addrspace(2)* @int2, i32 addrspace(2)* @int3]
]

@p3i32_array_array = addrspace(2) constant [4 x [4 x i32 addrspace(3)*]] [
  [4 x i32 addrspace(3)*] [ i32 addrspace(3)* @lds.int0, i32 addrspace(3)* @lds.int1, i32 addrspace(3)* @lds.int2, i32 addrspace(3)* @lds.int3],
  [4 x i32 addrspace(3)*] [ i32 addrspace(3)* @lds.int0, i32 addrspace(3)* @lds.int1, i32 addrspace(3)* @lds.int2, i32 addrspace(3)* @lds.int3],
  [4 x i32 addrspace(3)*] [ i32 addrspace(3)* @lds.int0, i32 addrspace(3)* @lds.int1, i32 addrspace(3)* @lds.int2, i32 addrspace(3)* @lds.int3],
  [4 x i32 addrspace(3)*] [ i32 addrspace(3)* @lds.int0, i32 addrspace(3)* @lds.int1, i32 addrspace(3)* @lds.int2, i32 addrspace(3)* @lds.int3]
]

@ptr_to_int_gv_p3i32 = addrspace(2) constant i32 ptrtoint (i32 addrspace(3)* @lds.int0 to i32)

@ptr_to_int_array_gv_p3i32 = addrspace(2) constant [4 x i32] [
  i32 ptrtoint (i32 addrspace(3)* @lds.int0 to i32),
  i32 ptrtoint (i32 addrspace(3)* @lds.int1 to i32),
  i32 ptrtoint (i32 addrspace(3)* @lds.int2 to i32),
  i32 ptrtoint (i32 addrspace(3)* @lds.int3 to i32)
  ]


; HSAIL-LABEL: {{^}}prog function &test_symbol_array(
define void @test_symbol_array(i32 addrspace(1)* %out, i32 %index) {
  %tmp0 = getelementptr inbounds [5 x i32 addrspace(2)*], [5 x i32 addrspace(2)*] addrspace(2)* @symbol_array, i32 0, i32 %index
  %ptr = load i32 addrspace(2)*, i32 addrspace(2)* addrspace(2)* %tmp0
  %tmp1 = load i32, i32 addrspace(2)* %ptr
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_constantexpr_address_array(
define void @test_constantexpr_address_array(i32 addrspace(1)* %out, i32 %index) {
  %tmp0 = getelementptr inbounds [5 x i32 addrspace(2)*], [5 x i32 addrspace(2)*] addrspace(2)* @constantexpr_address_array, i32 0, i32 %index
  %ptr = load i32 addrspace(2)*, i32 addrspace(2)* addrspace(2)* %tmp0
  %tmp1 = load i32, i32 addrspace(2)* %ptr
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_struct_foo_gv(
define void @test_struct_foo_gv(i32 addrspace(1)* %out, i32 %index) {
  %tmp0 = getelementptr inbounds [2 x %struct.foo], [2 x %struct.foo] addrspace(2)* @struct_foo_gv, i32 0, i32 %index, i32 1
  %tmp1 = load [5 x i32 addrspace(2)*] addrspace(2)*, [5 x i32 addrspace(2)*] addrspace(2)* addrspace(2)* %tmp0
  %tmp2 = getelementptr [5 x i32 addrspace(2)*], [5 x i32 addrspace(2)*] addrspace(2)* %tmp1, i32 0, i32 1
  %tmp3 = load i32 addrspace(2)*, i32 addrspace(2)* addrspace(2)* %tmp2
  %load = load i32, i32 addrspace(2)* %tmp3
  store i32 %load, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_struct_bar_gv(
define void @test_struct_bar_gv(i32 addrspace(1)* %out, i32 %index) {
  %tmp0 = getelementptr inbounds [2 x %struct.bar], [2 x %struct.bar] addrspace(2)* @struct_bar_gv, i32 0, i32 %index, i32 1
  %tmp1 = load [5 x i32 addrspace(2)*] addrspace(2)*, [5 x i32 addrspace(2)*] addrspace(2)* addrspace(2)* %tmp0
  %tmp2 = getelementptr [5 x i32 addrspace(2)*], [5 x i32 addrspace(2)*] addrspace(2)* %tmp1, i32 0, i32 1
  %tmp3 = load i32 addrspace(2)*, i32 addrspace(2)* addrspace(2)* %tmp2
  %load = load i32, i32 addrspace(2)* %tmp3
  store i32 %load, i32 addrspace(1)* %out
  ret void
}

; FIXME: First load using wrong alignment?

; HSAIL-LABEL: {{^}}prog function &test_packed_struct_bar_gv(
; HSAIL32: mul_u32 [[PTR0:\$s[0-9]+]], $s{{[0-9]+}}, 6;
; HSAIL32: ld_readonly_align(4)_u32 [[PTR1:\$s[0-9]+]], [&struct_packed_bar_gv]{{\[}}[[PTR0]]+1];
; HSAIL32-NEXT: ld_readonly_align(4)_u32 [[PTR2:\$s[0-9]+]], {{\[}}[[PTR1]]+8];
; HSAIL32-NEXT: ld_readonly_align(4)_u32 [[VAL:\$s[0-9]+]], {{\[}}[[PTR2]]{{\]}};
; HSAIL32: st_global_align(4)_u32 [[VAL]]
define void @test_packed_struct_bar_gv(i32 addrspace(1)* %out, i32 %index) {
  %tmp0 = getelementptr inbounds [2 x %struct.packed.bar], [2 x %struct.packed.bar] addrspace(2)* @struct_packed_bar_gv, i32 0, i32 %index, i32 1
  %tmp1 = load [5 x i32 addrspace(2)*] addrspace(2)*, [5 x i32 addrspace(2)*] addrspace(2)* addrspace(2)* %tmp0
  %tmp2 = getelementptr [5 x i32 addrspace(2)*], [5 x i32 addrspace(2)*] addrspace(2)* %tmp1, i32 0, i32 2
  %tmp3 = load i32 addrspace(2)*, i32 addrspace(2)* addrspace(2)* %tmp2
  %load = load i32, i32 addrspace(2)* %tmp3
  store i32 %load, i32 addrspace(1)* %out
  ret void
}


; HSAIL-LABEL: {{^}}prog function &test_mixed_nullptr_sizes_0(
define void @test_mixed_nullptr_sizes_0(i32 addrspace(2)* %arg) {
  %gep = getelementptr [2 x %struct.mixed.nullptr.sizes], [2 x %struct.mixed.nullptr.sizes] addrspace(2)* @struct_mixed_nullptr_sizes_0, i32 0, i32 1, i32 1
  %load = load volatile i32 addrspace(2)*, i32 addrspace(2)* addrspace(2)* %gep
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_mixed_nullptr_sizes_1(
define void @test_mixed_nullptr_sizes_1(i32 addrspace(2)* %arg) {
  %gep = getelementptr [2 x %struct.mixed.nullptr.sizes], [2 x %struct.mixed.nullptr.sizes] addrspace(2)* @struct_mixed_nullptr_sizes_1, i32 0, i32 1, i32 0
  %load = load volatile i32 addrspace(3)*, i32 addrspace(3)* addrspace(2)* %gep
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_lds_symbol_array(
define void @test_lds_symbol_array(i32 addrspace(1)* %out, i32 %index) {
  %tmp0 = getelementptr inbounds [5 x i32 addrspace(3)*], [5 x i32 addrspace(3)*] addrspace(2)* @lds_symbol_array, i32 0, i32 %index
  %ptr = load i32 addrspace(3)*, i32 addrspace(3)* addrspace(2)* %tmp0
  %tmp1 = load i32, i32 addrspace(3)* %ptr
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}
