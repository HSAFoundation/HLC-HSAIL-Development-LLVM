; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

%struct.foo = type { float, [5 x i32] }

; HSAIL-DAG: prog readonly_u32 &scalar_i32 = 99;
; HSAIL-DAG: prog align(16) readonly_u32 &vector_v4i32[4] = u32[](47, 256, 99, 1299);
; HSAIL-DAG: prog align(16) readonly_u32 &vector_v3i32[4] = u32[](47, 256, 12, 0);
; HSAIL-DAG: prog align(16) readonly_u32 &zero_vector_v4i32[4] = u32[](0, 0, 0, 0);
; HSAIL-DAG: prog align(16) readonly_u32 &zero_vector_v3i32[4] = u32[](0, 0, 0, 0);

; HSAIL-DAG: prog readonly_f32 &scalar_f32 = 0F40000000;
; HSAIL-DAG: prog align(16) readonly_f32 &zero_vector_v4f32[4] = f32[](0F00000000, 0F00000000, 0F00000000, 0F00000000);
; HSAIL-DAG: prog align(16) readonly_f32 &zero_vector_v3f32[4] = f32[](0F00000000, 0F00000000, 0F00000000, 0F00000000);

; HSAIL-DAG: prog readonly_f64 &scalar_f64 = 0D4000000000000000;
; HSAIL-DAG: prog align(32) readonly_f64 &zero_vector_v4f64[4] = f64[](0D0000000000000000, 0D0000000000000000, 0D0000000000000000, 0D0000000000000000);
; HSAIL-DAG: prog align(32) readonly_f64 &zero_vector_v3f64[4] = f64[](0D0000000000000000, 0D0000000000000000, 0D0000000000000000, 0D0000000000000000);

; HSAIL-DAG: prog readonly_u32 &array_array[16] = u32[](1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4);
; HSAIL-DAG: prog readonly_u32 &array_array_array[32] = u32[](1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4);
; HSAIL-DAG: prog align(8) readonly_u32 &array_array_vector[16] = u32[](1, 2, 3, 4, 5, 6, 7, 8, 1, 2, 3, 4, 5, 6, 7, 8);
; HSAIL-DAG: prog align(8) readonly_u8 &array_array_struct[192] = u8[](0, 0, 0, 63, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 63, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 65, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 65, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 66, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);


; HSAIL-DAG: readonly_f32 &float_gv[5] = f32[](0F00000000, 0F3f800000, 0F40000000, 0F40400000, 0F40800000);
; HSAIL-DAG: readonly_f64 &double_gv[5] = f64[](0D0000000000000000, 0D3ff0000000000000, 0D4000000000000000, 0D4008000000000000, 0D4010000000000000);
; HSAIL-DAG: readonly_u32 &i32_gv[5] = u32[](0, 1, 2, 3, 4);
; HSAIL-DAG: align(8) readonly_u8 &struct_foo_gv[24] = u8[](0, 0, 128, 65, 0, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0, 4, 0, 0, 0);
; HSAIL-DAG: readonly_u32 &array_v1_gv[4] = u32[](1, 2, 3, 4);
; HSAIL-DAG: align(8) readonly_u8 &struct_foo_zeroinit[240] = u8[](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
; HSAIL-DAG: align(8) readonly_u8 &bare_struct_foo_zeroinit[24] = u8[](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

;HSAIL-DAG: align(8) readonly_u8 &struct_foo_partial_zeroinit[48] = u8[](0, 0, 128, 63, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

; HSAIL-DAG: prog align(8) readonly_u8 &struct_foo_undefinit[240];
; HSAIL-DAG: prog align(8) readonly_u8 &bare_struct_foo_undefinit[24];
; HSAIL-DAG: prog align(8) readonly_u8 &struct_foo_partial_undefinit[48] = u8[](0, 0, 128, 63, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

; HSAIL-DAG: readonly_u32 &zeroinit_scalar_array[1025] = u32[](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
; HSAIL-DAG: align(16) readonly_u32 &zeroinit_vector_array[16] = u32[](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

; HSAIL-DAG: prog readonly_u32 &undefinit_scalar_array[1025];
; HSAIL-DAG: prog align(16) readonly_u32 &undefinit_vector_array[16];

@scalar_i32 = addrspace(2) constant i32 99
@vector_v4i32 = addrspace(2) constant <4 x i32> <i32 47, i32 256, i32 99, i32 1299>
@vector_v3i32 = addrspace(2) constant <3 x i32> <i32 47, i32 256, i32 12>

@zero_vector_v4i32 = addrspace(2) constant <4 x i32> zeroinitializer
@zero_vector_v3i32 = addrspace(2) constant <3 x i32> zeroinitializer

@scalar_f32 = addrspace(2) constant float 2.0
@zero_vector_v4f32 = addrspace(2) constant <4 x float> zeroinitializer
@zero_vector_v3f32 = addrspace(2) constant <3 x float> zeroinitializer

@scalar_f64 = addrspace(2) constant double 2.0
@zero_vector_v4f64 = addrspace(2) constant <4 x double> zeroinitializer
@zero_vector_v3f64 = addrspace(2) constant <3 x double> zeroinitializer

@array_array = addrspace(2) constant [4 x [4 x i32]] [
  [4 x i32] [i32 1, i32 2, i32 3, i32 4 ],
  [4 x i32] [i32 1, i32 2, i32 3, i32 4 ],
  [4 x i32] [i32 1, i32 2, i32 3, i32 4 ],
  [4 x i32] [i32 1, i32 2, i32 3, i32 4 ]
]

@array_array_array = addrspace(2) constant [2 x [4 x [4 x i32]]] [
  [4 x [4 x i32]] [
    [4 x i32] [i32 1, i32 2, i32 3, i32 4 ],
    [4 x i32] [i32 1, i32 2, i32 3, i32 4 ],
    [4 x i32] [i32 1, i32 2, i32 3, i32 4 ],
    [4 x i32] [i32 1, i32 2, i32 3, i32 4 ]
  ],
  [4 x [4 x i32]] [
    [4 x i32] [i32 1, i32 2, i32 3, i32 4 ],
    [4 x i32] [i32 1, i32 2, i32 3, i32 4 ],
    [4 x i32] [i32 1, i32 2, i32 3, i32 4 ],
    [4 x i32] [i32 1, i32 2, i32 3, i32 4 ]
  ]
]

@array_array_vector = addrspace(2) constant [2 x [4 x <2 x i32>]] [
  [4 x <2 x i32>] [
    <2 x i32> <i32 1, i32 2>,
    <2 x i32> <i32 3, i32 4>,
    <2 x i32> <i32 5, i32 6>,
    <2 x i32> <i32 7, i32 8>
  ],
  [4 x <2 x i32>] [
    <2 x i32> <i32 1, i32 2>,
    <2 x i32> <i32 3, i32 4>,
    <2 x i32> <i32 5, i32 6>,
    <2 x i32> <i32 7, i32 8>
  ]
]

@array_array_struct = addrspace(2) constant [2 x [4 x %struct.foo]] [
  [4 x %struct.foo] [
    %struct.foo { float 0.5, [5 x i32] zeroinitializer },
    %struct.foo { float 1.0, [5 x i32] zeroinitializer },
    %struct.foo { float 2.0, [5 x i32] zeroinitializer },
    %struct.foo { float 4.0, [5 x i32] zeroinitializer }
  ],
  [4 x %struct.foo] [
    %struct.foo { float 8.0, [5 x i32] zeroinitializer },
    %struct.foo { float 16.0, [5 x i32] zeroinitializer },
    %struct.foo { float 32.0, [5 x i32] zeroinitializer },
    %struct.foo { float 64.0, [5 x i32] zeroinitializer }
  ]
]

@b = internal addrspace(2) constant [1 x i16] [ i16 7 ], align 2

@float_gv = internal unnamed_addr addrspace(2) constant [5 x float] [float 0.0, float 1.0, float 2.0, float 3.0, float 4.0], align 4
@double_gv = internal unnamed_addr addrspace(2) constant [5 x double] [double 0.0, double 1.0, double 2.0, double 3.0, double 4.0], align 4

@struct_foo_gv = internal unnamed_addr addrspace(2) constant [1 x %struct.foo] [ %struct.foo { float 16.0, [5 x i32] [i32 0, i32 1, i32 2, i32 3, i32 4] } ]

@struct_foo_zeroinit = unnamed_addr addrspace(2) constant [10 x %struct.foo] zeroinitializer

@bare_struct_foo_zeroinit = unnamed_addr addrspace(2) constant %struct.foo zeroinitializer

@struct_foo_partial_zeroinit = unnamed_addr addrspace(2) constant [2 x %struct.foo] [
  %struct.foo { float 1.0, [5 x i32] zeroinitializer },
  %struct.foo { float 2.0, [5 x i32] zeroinitializer }
]

@struct_foo_undefinit = unnamed_addr addrspace(2) constant [10 x %struct.foo] undef

@bare_struct_foo_undefinit = unnamed_addr addrspace(2) constant %struct.foo undef

@struct_foo_partial_undefinit = unnamed_addr addrspace(2) constant [2 x %struct.foo] [
  %struct.foo { float 1.0, [5 x i32] undef },
  %struct.foo { float 2.0, [5 x i32] undef }
]

@zeroinit_scalar_array = internal unnamed_addr addrspace(2) constant [1025 x i32] zeroinitializer
@zeroinit_vector_array = internal addrspace(2) constant [4 x <4 x i32>] zeroinitializer

@undefinit_scalar_array = unnamed_addr addrspace(2) constant [1025 x i32] undef
@undefinit_vector_array = addrspace(2) constant [4 x <4 x i32>] undef

@array_v1_gv = internal addrspace(2) constant [4 x <1 x i32>] [ <1 x i32> <i32 1>,
                                                                <1 x i32> <i32 2>,
                                                                <1 x i32> <i32 3>,
                                                                <1 x i32> <i32 4> ]

; FUNC-LABEL: {{^}}prog function &float(
; HSAIL: shl_u32 [[ADDR:\$s[0-9]+]], {{\$s[0-9]+}}, 2;
; HSAIL: ld_readonly_align(4)_f32 [[LD:\$s[0-9]+]], [&float_gv]{{\[}}[[ADDR]]{{\]}};
; HSAIL: st_global_align(4)_f32 [[LD]]
; HSAIL: ret;
define void @float(float addrspace(1)* %out, i32 %index) {
  %tmp0 = getelementptr inbounds [5 x float], [5 x float] addrspace(2)* @float_gv, i32 0, i32 %index
  %tmp1 = load float, float addrspace(2)* %tmp0
  store float %tmp1, float addrspace(1)* %out
  ret void
}


; FUNC-LABEL: {{^}}prog function &double(
; HSAIL: shl_u32 [[ADDR:\$s[0-9]+]], {{\$s[0-9]+}}, 3;
; HSAIL: ld_readonly_align(8)_f64 [[LD:\$d[0-9]+]], [&double_gv]{{\[}}[[ADDR]]{{\]}};
; HSAIL: st_global_align(8)_f64 [[LD]]
; HSAIL: ret;
define void @double(double addrspace(1)* %out, i32 %index) {
  %tmp0 = getelementptr inbounds [5 x double], [5 x double] addrspace(2)* @double_gv, i32 0, i32 %index
  %tmp1 = load double, double addrspace(2)* %tmp0
  store double %tmp1, double addrspace(1)* %out
  ret void
}

@i32_gv = internal unnamed_addr addrspace(2) constant [5 x i32] [i32 0, i32 1, i32 2, i32 3, i32 4], align 4

; FUNC-LABEL: {{^}}prog function &i32(
; HSAIL: shl_u32 [[ADDR:\$s[0-9]+]], {{\$s[0-9]+}}, 2;
; HSAIL: ld_readonly_align(4)_u32 [[LD:\$s[0-9]+]], [&i32_gv]{{\[}}[[ADDR]]{{\]}};
; HSAIL: st_global_align(4)_u32 [[LD]]
; HSAIL: ret;
define void @i32(i32 addrspace(1)* %out, i32 %index) {
  %tmp0 = getelementptr inbounds [5 x i32], [5 x i32] addrspace(2)* @i32_gv, i32 0, i32 %index
  %tmp1 = load i32, i32 addrspace(2)* %tmp0
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &struct_foo_gv_load(
; HSAIL: shl_u32 [[ADDR:\$s[0-9]+]], {{\$s[0-9]+}}, 2;
; HSAIL: ld_readonly_align(4)_u32 [[LD:\$s[0-9]+]], [&struct_foo_gv]{{\[}}[[ADDR]]+4{{\]}};
; HSAIL: st_global_align(4)_u32 [[LD]]
; HSAIL: ret;
define void @struct_foo_gv_load(i32 addrspace(1)* %out, i32 %index) {
  %gep = getelementptr inbounds [1 x %struct.foo], [1 x %struct.foo] addrspace(2)* @struct_foo_gv, i32 0, i32 0, i32 1, i32 %index
  %load = load i32, i32 addrspace(2)* %gep, align 4
  store i32 %load, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &struct_foo_gv_zeroinit_load(
; HSAIL: shl_u32 [[ADDR:\$s[0-9]+]], {{\$s[0-9]+}}, 2;
; HSAIL: ld_readonly_align(4)_u32 [[LD:\$s[0-9]+]], [&struct_foo_zeroinit]{{\[}}[[ADDR]]+4{{\]}};
; HSAIL: st_global_align(4)_u32 [[LD]]
; HSAIL: ret;
define void @struct_foo_gv_zeroinit_load(i32 addrspace(1)* %out, i32 %index) {
  %gep = getelementptr inbounds [10 x %struct.foo], [10 x %struct.foo] addrspace(2)* @struct_foo_zeroinit, i32 0, i32 0, i32 1, i32 %index
  %load = load volatile i32, i32 addrspace(2)* %gep, align 4
  store i32 %load, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &bare_struct_foo_gv_zeroinit_load(
; HSAIL: shl_u32 [[ADDR:\$s[0-9]+]], {{\$s[0-9]+}}, 2;
; HSAIL: ld_readonly_align(4)_u32 [[LD:\$s[0-9]+]], [&bare_struct_foo_zeroinit]{{\[}}[[ADDR]]+4{{\]}};
; HSAIL: st_global_align(4)_u32 [[LD]]
; HSAIL: ret;
define void @bare_struct_foo_gv_zeroinit_load(i32 addrspace(1)* %out, i32 %index) {
  %gep = getelementptr inbounds %struct.foo, %struct.foo addrspace(2)* @bare_struct_foo_zeroinit, i32 0, i32 1, i32 %index
  %load = load volatile i32, i32 addrspace(2)* %gep, align 4
  store i32 %load, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &struct_foo_gv_partial_zeroinit_load(
; HSAIL: shl_u32 [[ADDR:\$s[0-9]+]], {{\$s[0-9]+}}, 2;
; HSAIL: ld_readonly_align(4)_u32 [[LD:\$s[0-9]+]], [&struct_foo_partial_zeroinit]{{\[}}[[ADDR]]+4{{\]}};
; HSAIL: st_global_align(4)_u32 [[LD]]
; HSAIL: ret;
define void @struct_foo_gv_partial_zeroinit_load(i32 addrspace(1)* %out, i32 %index) {
  %gep = getelementptr inbounds [2 x %struct.foo], [2 x %struct.foo] addrspace(2)* @struct_foo_partial_zeroinit, i32 0, i32 0, i32 1, i32 %index
  %load = load volatile i32, i32 addrspace(2)* %gep, align 4
  store i32 %load, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &array_v1_gv_load(
; HSAIL: shl_u32 [[ADDR:\$s[0-9]+]], {{\$s[0-9]+}}, 2;
; HSAIL: ld_readonly_align(4)_u32 [[LD:\$s[0-9]+]], [&array_v1_gv]{{\[}}[[ADDR]]{{\]}};
; HSAIL: st_global_align(4)_u32 [[LD]]
; HSAIL: ret;
define void @array_v1_gv_load(<1 x i32> addrspace(1)* %out, i32 %index) {
  %gep = getelementptr inbounds [4 x <1 x i32>], [4 x <1 x i32>] addrspace(2)* @array_v1_gv, i32 0, i32 %index
  %load = load <1 x i32>, <1 x i32> addrspace(2)* %gep, align 4
  store <1 x i32> %load, <1 x i32> addrspace(1)* %out, align 4
  ret void
}


; FUNC-LABEL: {{^}}prog function &zeroinit_scalar_array_load(
; HSAIL: shl_u32 [[ADDR:\$s[0-9]+]], {{\$s[0-9]+}}, 2;
; HSAIL: ld_readonly_align(4)_u32 [[LD:\$s[0-9]+]], [&zeroinit_scalar_array]{{\[}}[[ADDR]]{{\]}};
; HSAIL: st_global_align(4)_u32 [[LD]]
; HSAIL: ret;
define void @zeroinit_scalar_array_load(i32 addrspace(1)* %out, i32 %index) {
  %gep = getelementptr inbounds [1025 x i32], [1025 x i32] addrspace(2)* @zeroinit_scalar_array, i32 0, i32 %index
  %load = load i32, i32 addrspace(2)* %gep, align 4
  store i32 %load, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &zeroinit_vector_array_load(
define void @zeroinit_vector_array_load(<4 x i32> addrspace(1)* %out, i32 %index) {
  %gep = getelementptr inbounds [4 x <4 x i32>], [4 x <4 x i32>] addrspace(2)* @zeroinit_vector_array, i32 0, i32 %index
  %load = load <4 x i32>, <4 x i32> addrspace(2)* %gep, align 16
  store <4 x i32> %load, <4 x i32> addrspace(1)* %out, align 16
  ret void
}

; FUNC-LABEL: {{^}}prog function &gv_addressing_in_branch(
; HSAIL: shl_u32 [[ADDR:\$s[0-9]+]], {{\$s[0-9]+}}, 2;
; HSAIL: ld_readonly_align(4)_f32 [[LD:\$s[0-9]+]], [&float_gv]{{\[}}[[ADDR]]{{\]}};
; HSAIL: st_global_align(4)_f32 [[LD]]
; HSAIL: ret;
define void @gv_addressing_in_branch(float addrspace(1)* %out, i32 %index, i32 %a) {
entry:
  %tmp0 = icmp eq i32 0, %a
  br i1 %tmp0, label %if, label %else

if:
  %tmp1 = getelementptr inbounds [5 x float], [5 x float] addrspace(2)* @float_gv, i32 0, i32 %index
  %tmp2 = load float, float addrspace(2)* %tmp1
  store float %tmp2, float addrspace(1)* %out
  br label %endif

else:
  store float 1.0, float addrspace(1)* %out
  br label %endif

endif:
  ret void
}
