; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; HSAIL: readonly_u32 &int0 = 9;
; HSAIL: readonly_u32 &int1 = 34;
; HSAIL: readonly_u32 &int2 = 123;
; HSAIL: readonly_u32 &int3 = 222;
; HSAIL: readonly_u32 &int4 = 2424;

; HSAIL: readonly_u32 &symbol_array[5] = {0, 0, 0, 0, 0};
; HSAIL: pragma  "initvarwithaddress:&symbol_array:0:4:&int0:0";
; HSAIL: pragma  "initvarwithaddress:&symbol_array:4:4:&int1:0";
; HSAIL: pragma  "initvarwithaddress:&symbol_array:8:4:&int2:0";
; HSAIL: pragma  "initvarwithaddress:&symbol_array:12:4:&int3:0";
; HSAIL: pragma  "initvarwithaddress:&symbol_array:16:4:&int4:0";

; HSAIL: readonly_u32 &i32_array[10] = {234, 456, 789, 235, 495, 1, 4, 9, 10, 453};

; HSAIL: readonly_u32 &constantexpr_address_array[5] = {0, 0, 0, 0, 0};
; HSAIL: pragma  "initvarwithaddress:&constantexpr_address_array:0:4:&i32_array:0";
; HSAIL: pragma  "initvarwithaddress:&constantexpr_address_array:4:4:&i32_array:16";
; HSAIL: pragma  "initvarwithaddress:&constantexpr_address_array:8:4:&i32_array:32";
; HSAIL: pragma  "initvarwithaddress:&constantexpr_address_array:12:4:&i32_array:36";
; HSAIL: pragma  "initvarwithaddress:&constantexpr_address_array:16:4:&i32_array:12";

; HSAIL: align(8) readonly_u8 &struct_foo_gv[16] = {0, 0, 128, 65, 0, 0, 0, 0, 0, 0, 0, 66, 0, 0, 0, 0};
; HSAIL: pragma  "initvarwithaddress:&struct_foo_gv:4:1:&constantexpr_address_array:0";
; HSAIL: pragma  "initvarwithaddress:&struct_foo_gv:12:1:&symbol_array:0";

; HSAIL: align(8) readonly_u8 &struct_bar_gv[24] = {7, 0, 0, 0, 0, 0, 0, 0, 23, 0, 0, 0, 45, 0, 0, 0, 0, 0, 0, 0, 212, 0, 0, 0};
; HSAIL: pragma  "initvarwithaddress:&struct_bar_gv:4:1:&constantexpr_address_array:0";
; HSAIL: pragma  "initvarwithaddress:&struct_bar_gv:16:1:&symbol_array:0";

; HSAIL: align(8) readonly_u8 &struct_packed_bar_gv[12] = {7, 0, 0, 0, 0, 23, 45, 0, 0, 0, 0, 212};
; HSAIL: pragma  "initvarwithaddress:&struct_packed_bar_gv:1:1:&constantexpr_address_array:0";
; HSAIL: pragma  "initvarwithaddress:&struct_packed_bar_gv:7:1:&symbol_array:0";


@int0 = internal unnamed_addr addrspace(2) constant i32 9
@int1 = internal unnamed_addr addrspace(2) constant i32 34
@int2 = internal unnamed_addr addrspace(2) constant i32 123
@int3 = internal unnamed_addr addrspace(2) constant i32 222
@int4 = internal unnamed_addr addrspace(2) constant i32 2424

@symbol_array = internal addrspace(2) constant [5 x i32 addrspace(2)*] [ i32 addrspace(2)* @int0, i32 addrspace(2)* @int1, i32 addrspace(2)* @int2, i32 addrspace(2)* @int3, i32 addrspace(2)* @int4 ]
@i32_array = internal unnamed_addr addrspace(2) constant [10 x i32] [i32 234, i32 456, i32 789, i32 235, i32 495, i32 1, i32 4, i32 9, i32 10, i32 453], align 4


@constantexpr_address_array = internal addrspace(2) constant [5 x i32 addrspace(2)*] [
  i32 addrspace(2)* getelementptr ([10 x i32] addrspace(2)* @i32_array, i32 0, i32 0),
  i32 addrspace(2)* getelementptr ([10 x i32] addrspace(2)* @i32_array, i32 0, i32 4),
  i32 addrspace(2)* getelementptr ([10 x i32] addrspace(2)* @i32_array, i32 0, i32 8),
  i32 addrspace(2)* getelementptr ([10 x i32] addrspace(2)* @i32_array, i32 0, i32 9),
  i32 addrspace(2)* getelementptr ([10 x i32] addrspace(2)* @i32_array, i32 0, i32 3)
]


%struct.foo = type { float, [5 x i32 addrspace(2)*] addrspace(2)* }

%struct.bar = type { i8, [5 x i32 addrspace(2)*] addrspace(2)*, i8 }
%struct.packed.bar = type <{ i8, [5 x i32 addrspace(2)*] addrspace(2)*, i8 }>

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


; FUNC-LABEL: {{^}}prog function &test_symbol_array(
define void @test_symbol_array(i32 addrspace(1)* %out, i32 %index) {
  %tmp0 = getelementptr inbounds [5 x i32 addrspace(2)*] addrspace(2)* @symbol_array, i32 0, i32 %index
  %ptr = load i32 addrspace(2)* addrspace(2)* %tmp0
  %tmp1 = load i32 addrspace(2)* %ptr
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_constantexpr_address_array(
define void @test_constantexpr_address_array(i32 addrspace(1)* %out, i32 %index) {
  %tmp0 = getelementptr inbounds [5 x i32 addrspace(2)*] addrspace(2)* @constantexpr_address_array, i32 0, i32 %index
  %ptr = load i32 addrspace(2)* addrspace(2)* %tmp0
  %tmp1 = load i32 addrspace(2)* %ptr
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_struct_foo_gv(
define void @test_struct_foo_gv(i32 addrspace(1)* %out, i32 %index) {
  %tmp0 = getelementptr inbounds [2 x %struct.foo] addrspace(2)* @struct_foo_gv, i32 0, i32 %index, i32 1
  %tmp1 = load [5 x i32 addrspace(2)*] addrspace(2)* addrspace(2)* %tmp0
  %tmp2 = getelementptr [5 x i32 addrspace(2)*] addrspace(2)* %tmp1, i32 0, i32 1
  %tmp3 = load i32 addrspace(2)* addrspace(2)* %tmp2
  %load = load i32 addrspace(2)* %tmp3
  store i32 %load, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_struct_bar_gv(
define void @test_struct_bar_gv(i32 addrspace(1)* %out, i32 %index) {
  %tmp0 = getelementptr inbounds [2 x %struct.bar] addrspace(2)* @struct_bar_gv, i32 0, i32 %index, i32 1
  %tmp1 = load [5 x i32 addrspace(2)*] addrspace(2)* addrspace(2)* %tmp0
  %tmp2 = getelementptr [5 x i32 addrspace(2)*] addrspace(2)* %tmp1, i32 0, i32 1
  %tmp3 = load i32 addrspace(2)* addrspace(2)* %tmp2
  %load = load i32 addrspace(2)* %tmp3
  store i32 %load, i32 addrspace(1)* %out
  ret void
}

; FIXME: First load using wrong alignment?

; FUNC-LABEL: {{^}}prog function &test_packed_struct_bar_gv(
; HSAIL: mul_u32 [[PTR0:\$s[0-9]+]], $s{{[0-9]+}}, 6;
; HSAIL: ld_readonly_align(4)_u32 [[PTR1:\$s[0-9]+]], [&struct_packed_bar_gv]{{\[}}[[PTR0]]+1];
; HSAIL-NEXT: ld_readonly_align(4)_u32 [[PTR2:\$s[0-9]+]], {{\[}}[[PTR1]]+8];
; HSAIL-NEXT: ld_readonly_align(4)_u32 [[VAL:\$s[0-9]+]], {{\[}}[[PTR2]]{{\]}};
; HSAIL: st_global_align(4)_u32 [[VAL]]
define void @test_packed_struct_bar_gv(i32 addrspace(1)* %out, i32 %index) {
  %tmp0 = getelementptr inbounds [2 x %struct.packed.bar] addrspace(2)* @struct_packed_bar_gv, i32 0, i32 %index, i32 1
  %tmp1 = load [5 x i32 addrspace(2)*] addrspace(2)* addrspace(2)* %tmp0
  %tmp2 = getelementptr [5 x i32 addrspace(2)*] addrspace(2)* %tmp1, i32 0, i32 2
  %tmp3 = load i32 addrspace(2)* addrspace(2)* %tmp2
  %load = load i32 addrspace(2)* %tmp3
  store i32 %load, i32 addrspace(1)* %out
  ret void
}
