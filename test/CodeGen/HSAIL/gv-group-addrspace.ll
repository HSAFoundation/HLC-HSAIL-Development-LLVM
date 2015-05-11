; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

%struct.foo = type { float, [5 x i32] }


@scalar_i32 = addrspace(3) global i32 undef
@scalar_f32 = addrspace(3) global float undef
@scalar_i1 = addrspace(3) global i1 undef

@vector_v4i32 = addrspace(3) global <4 x i32> undef
@vector_v3i32 = addrspace(3) global <3 x i32> undef

@array_i32 = addrspace(3) global [7 x i32] undef, align 4

@float_array_gv = addrspace(3) global [5 x float] undef
@double_array_gv = addrspace(3) global [5 x double] undef

@struct_foo_gv = addrspace(3) global %struct.foo undef
@array_struct_foo_gv = addrspace(3) global [10 x %struct.foo] undef

@array_v1_gv = addrspace(3) global [4 x <1 x i32>] undef


; HSAIL-LABEL: {{^}}prog function &test_scalar_i32()(
; HSAIL: {
; HSAIL-NEXT: group_u32 %scalar_i32;
; HSAIL: ld_group_align(4)_u32 {{\$s[0-9]+}}, [%scalar_i32];
; HSAIL: ret;
define void @test_scalar_i32(i32 addrspace(1)* %out) {
  %tmp1 = load i32, i32 addrspace(3)* @scalar_i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_scalar_f32()(
; HSAIL: {
; HSAIL-NEXT: group_f32 %scalar_f32;
; HSAIL: ld_group_align(4)_f32 {{\$s[0-9]+}}, [%scalar_f32];
; HSAIL: ret;
define void @test_scalar_f32(float addrspace(1)* %out) {
  %tmp1 = load float, float addrspace(3)* @scalar_f32
  store float %tmp1, float addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_vector_v4i32()(
; HSAIL: {
; HSAIL-NEXT: group_u32 %vector_v4i32[4];
; HSAIL-DAG: ld_group_align(16)_u32 {{\$s[0-9]+}}, [%vector_v4i32];
; HSAIL-DAG: ld_group_align(4)_u32 {{\$s[0-9]+}}, [%vector_v4i32][4];
; HSAIL-DAG: ld_group_align(8)_u32 {{\$s[0-9]+}}, [%vector_v4i32][8];
; HSAIL-DAG: ld_group_align(4)_u32 {{\$s[0-9]+}}, [%vector_v4i32][12];
; HSAIL: ret;
define void @test_vector_v4i32(<4 x i32> addrspace(1)* %out) {
  %tmp1 = load <4 x i32>, <4 x i32> addrspace(3)* @vector_v4i32
  store <4 x i32> %tmp1, <4 x i32> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_vector_v3i32()(
; HSAIL: {
; HSAIL-NEXT: group_u32 %vector_v3i32[4];
; HSAIL-DAG: ld_group_align(16)_u64 {{\$d[0-9]+}}, [%vector_v3i32];
; HSAIL-DAG: ld_group_align(8)_u32 {{\$s[0-9]+}}, [%vector_v3i32][8];
; HSAIL: ret;
define void @test_vector_v3i32(<3 x i32> addrspace(1)* %out) {
  %tmp1 = load <3 x i32>, <3 x i32> addrspace(3)* @vector_v3i32
  store <3 x i32> %tmp1, <3 x i32> addrspace(1)* %out
  ret void
}

; FIXME: Align of load and declaration should match
; HSAIL-LABEL: {{^}}prog function &test_scalar_i1()(
; HSAIL: {
; HSAIL-NEXT: group_u8 %scalar_i1;
; HSAIL: ld_group_u8 {{\$s[0-9]+}}, [%scalar_i1];
; HSAIL: ret;
define void @test_scalar_i1(i1 addrspace(1)* %out) {
  %tmp1 = load i1, i1 addrspace(3)* @scalar_i1
  store i1 %tmp1, i1 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_array_i32()(
; HSAIL: {
; HSAIL-NEXT: group_u32 %array_i32[7];
; HSAIL: ld_group_align(4)_u32 {{\$s[0-9]+}}, [%array_i32][{{\$s[0-9]+}}];
; HSAIL: ret;
define void @test_array_i32(i32 addrspace(1)* %out, i32 %index) {
  %tmp0 = getelementptr inbounds [7 x i32], [7 x i32] addrspace(3)* @array_i32, i32 0, i32 %index
  %tmp1 = load i32, i32 addrspace(3)* %tmp0
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_float_array_gv()(
; HSAIL: {
; HSAIL-NEXT: group_f32 %float_array_gv[5];
; HSAIL: ld_group_align(4)_f32 {{\$s[0-9]+}}, [%float_array_gv][{{\$s[0-9]+}}];
; HSAIL: ret;
define void @test_float_array_gv(float addrspace(1)* %out, i32 %index) {
  %tmp0 = getelementptr inbounds [5 x float], [5 x float] addrspace(3)* @float_array_gv, i32 0, i32 %index
  %tmp1 = load float, float addrspace(3)* %tmp0
  store float %tmp1, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_double_array_gv()(
; HSAIL: group_f64 %double_array_gv[5];
; HSAIL: shl_u32 [[ADDR:\$s[0-9]+]], {{\$s[0-9]+}}, 3;
; HSAIL: ld_group_align(8)_f64 [[LD:\$d[0-9]+]], [%double_array_gv]{{\[}}[[ADDR]]{{\]}};
; HSAIL: st_global_align(8)_f64 [[LD]]
; HSAIL: ret;
define void @test_double_array_gv(double addrspace(1)* %out, i32 %index) {
  %tmp0 = getelementptr inbounds [5 x double], [5 x double] addrspace(3)* @double_array_gv, i32 0, i32 %index
  %tmp1 = load double, double addrspace(3)* %tmp0
  store double %tmp1, double addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &struct_foo_gv_load()(
; HSAIL: align(8) group_u8 %struct_foo_gv[24];
; HSAIL: ld_group_align(8)_u32 [[LD:\$s[0-9]+]], [%struct_foo_gv][8];
; HSAIL: st_global_align(4)_u32 [[LD]]
; HSAIL: ret;
define void @struct_foo_gv_load(i32 addrspace(1)* %out, i32 %index) {
  %gep = getelementptr inbounds %struct.foo, %struct.foo addrspace(3)* @struct_foo_gv, i32 0, i32 1, i32 1
  %load = load i32, i32 addrspace(3)* %gep, align 4
  store i32 %load, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &array_struct_foo_gv_load()(
; HSAIL: align(8) group_u8 %array_struct_foo_gv[240];
; HSAIL: shl_u32 [[ADDR:\$s[0-9]+]], {{\$s[0-9]+}}, 2;
; HSAIL: ld_group_align(4)_u32 [[LD:\$s[0-9]+]], [%array_struct_foo_gv]{{\[}}[[ADDR]]+4{{\]}};
; HSAIL: st_global_align(4)_u32 [[LD]]
; HSAIL: ret;
define void @array_struct_foo_gv_load(i32 addrspace(1)* %out, i32 %index) {
  %gep = getelementptr inbounds [10 x %struct.foo], [10 x %struct.foo] addrspace(3)* @array_struct_foo_gv, i32 0, i32 0, i32 1, i32 %index
  %load = load i32, i32 addrspace(3)* %gep, align 4
  store i32 %load, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &array_v1_gv_load()(
; HSAIL: group_u32 %array_v1_gv[4];

; HSAIL: shl_u32 [[ADDR:\$s[0-9]+]], {{\$s[0-9]+}}, 2;
; HSAIL: ld_group_align(4)_u32 [[LD:\$s[0-9]+]], [%array_v1_gv]{{\[}}[[ADDR]]{{\]}};
; HSAIL: st_global_align(4)_u32 [[LD]]
; HSAIL: ret;
define void @array_v1_gv_load(<1 x i32> addrspace(1)* %out, i32 %index) {
  %gep = getelementptr inbounds [4 x <1 x i32>], [4 x <1 x i32>] addrspace(3)* @array_v1_gv, i32 0, i32 %index
  %load = load <1 x i32>, <1 x i32> addrspace(3)* %gep, align 4
  store <1 x i32> %load, <1 x i32> addrspace(1)* %out, align 4
  ret void
}
