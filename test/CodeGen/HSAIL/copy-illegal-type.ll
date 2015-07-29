; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &test_copy_v4i8
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @test_copy_v4i8(<4 x i8> addrspace(1)* %out, <4 x i8> addrspace(1)* %in) nounwind {
  %val = load <4 x i8> addrspace(1)* %in, align 4
  store <4 x i8> %val, <4 x i8> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_copy_v4i8_x2
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out0];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out1];
define void @test_copy_v4i8_x2(<4 x i8> addrspace(1)* %out0, <4 x i8> addrspace(1)* %out1, <4 x i8> addrspace(1)* %in) nounwind {
  %val = load <4 x i8> addrspace(1)* %in, align 4
  store <4 x i8> %val, <4 x i8> addrspace(1)* %out0, align 4
  store <4 x i8> %val, <4 x i8> addrspace(1)* %out1, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_copy_v4i8_x3
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out0];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out1];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out2];
define void @test_copy_v4i8_x3(<4 x i8> addrspace(1)* %out0, <4 x i8> addrspace(1)* %out1, <4 x i8> addrspace(1)* %out2, <4 x i8> addrspace(1)* %in) nounwind {
  %val = load <4 x i8> addrspace(1)* %in, align 4
  store <4 x i8> %val, <4 x i8> addrspace(1)* %out0, align 4
  store <4 x i8> %val, <4 x i8> addrspace(1)* %out1, align 4
  store <4 x i8> %val, <4 x i8> addrspace(1)* %out2, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_copy_v4i8_x4
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out0];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out1];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out2];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out3];
define void @test_copy_v4i8_x4(<4 x i8> addrspace(1)* %out0, <4 x i8> addrspace(1)* %out1, <4 x i8> addrspace(1)* %out2, <4 x i8> addrspace(1)* %out3, <4 x i8> addrspace(1)* %in) nounwind {
  %val = load <4 x i8> addrspace(1)* %in, align 4
  store <4 x i8> %val, <4 x i8> addrspace(1)* %out0, align 4
  store <4 x i8> %val, <4 x i8> addrspace(1)* %out1, align 4
  store <4 x i8> %val, <4 x i8> addrspace(1)* %out2, align 4
  store <4 x i8> %val, <4 x i8> addrspace(1)* %out3, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_copy_v4i8_extra_use
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out0];
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 9;
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out1];
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 9;
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 9;
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 9;
define void @test_copy_v4i8_extra_use(<4 x i8> addrspace(1)* %out0, <4 x i8> addrspace(1)* %out1, <4 x i8> addrspace(1)* %in) nounwind {
  %val = load <4 x i8> addrspace(1)* %in, align 4
  %add = add <4 x i8> %val, <i8 9, i8 9, i8 9, i8 9>
  store <4 x i8> %val, <4 x i8> addrspace(1)* %out0, align 4
  store <4 x i8> %add, <4 x i8> addrspace(1)* %out1, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_copy_v4i8_x2_extra_use
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out0];
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 9;
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out1];
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 9;
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 9;
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 9;
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out2];
define void @test_copy_v4i8_x2_extra_use(<4 x i8> addrspace(1)* %out0, <4 x i8> addrspace(1)* %out1, <4 x i8> addrspace(1)* %out2, <4 x i8> addrspace(1)* %in) nounwind {
  %val = load <4 x i8> addrspace(1)* %in, align 4
  %add = add <4 x i8> %val, <i8 9, i8 9, i8 9, i8 9>
  store <4 x i8> %val, <4 x i8> addrspace(1)* %out0, align 4
  store <4 x i8> %add, <4 x i8> addrspace(1)* %out1, align 4
  store <4 x i8> %val, <4 x i8> addrspace(1)* %out2, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_copy_v3i8
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: shr_u32  {{\$s[0-9]+}}, {{\$s[0-9]+}}, 16;
; HSAIL: shr_u32  {{\$s[0-9]+}}, {{\$s[0-9]+}}, 8;
define void @test_copy_v3i8(<3 x i8> addrspace(1)* %out, <3 x i8> addrspace(1)* %in) nounwind {
  %val = load <3 x i8> addrspace(1)* %in, align 4
  store <3 x i8> %val, <3 x i8> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_copy_v4i8_volatile_load
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @test_copy_v4i8_volatile_load(<4 x i8> addrspace(1)* %out, <4 x i8> addrspace(1)* %in) nounwind {
  %val = load volatile <4 x i8> addrspace(1)* %in, align 4
  store <4 x i8> %val, <4 x i8> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_copy_v4i8_volatile_store
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @test_copy_v4i8_volatile_store(<4 x i8> addrspace(1)* %out, <4 x i8> addrspace(1)* %in) nounwind {
  %val = load <4 x i8> addrspace(1)* %in, align 4
  store volatile <4 x i8> %val, <4 x i8> addrspace(1)* %out, align 4
  ret void
}
