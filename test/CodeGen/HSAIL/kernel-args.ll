; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog kernel &i8_kernarg(
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in];
; HSAIL: and_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 255;
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
define spir_kernel void @i8_kernarg(i32 addrspace(1)* nocapture %out, i8 %in) nounwind {
  %tmp0 = zext i8 %in to i32
  store i32 %tmp0, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &i8_zext_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in];
define spir_kernel void @i8_zext_kernarg(i32 addrspace(1)* nocapture %out, i8 zeroext %in) nounwind {
  %tmp0 = zext i8 %in to i32
  store i32 %tmp0, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &i8_sext_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_width(all)_s8 {{\$s[0-9]+}}, [%in];
define spir_kernel void @i8_sext_kernarg(i32 addrspace(1)* nocapture %out, i8 signext %in) nounwind {
  %tmp0 = sext i8 %in to i32
  store i32 %tmp0, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &i16_kernarg(
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in];
; HSAIL: and_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 65535;
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
define spir_kernel void @i16_kernarg(i32 addrspace(1)* nocapture %out, i16 %in) nounwind {
  %tmp0 = zext i16 %in to i32
  store i32 %tmp0, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &i16_zext_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in];
define spir_kernel void @i16_zext_kernarg(i32 addrspace(1)* nocapture %out, i16 zeroext %in) nounwind {
  %tmp0 = zext i16 %in to i32
  store i32 %tmp0, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &i16_sext_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_align(2)_width(all)_s16 {{\$s[0-9]+}}, [%in];
define spir_kernel void @i16_sext_kernarg(i32 addrspace(1)* nocapture %out, i16 signext %in) nounwind {
  %tmp0 = sext i16 %in to i32
  store i32 %tmp0, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &i32_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in];
define spir_kernel void @i32_kernarg(i32 addrspace(1)* nocapture %out, i32 %in) nounwind {
  store i32 %in, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &f32_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_align(4)_width(all)_f32 {{\$s[0-9]+}}, [%in];
define spir_kernel void @f32_kernarg(float addrspace(1)* nocapture %out, float %in) nounwind {
  store float %in, float addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &v2i8_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][1];
define spir_kernel void @v2i8_kernarg(<2 x i8> addrspace(1)* %out, <2 x i8> %in) {
  store <2 x i8> %in, <2 x i8> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &v2i16_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][2];
define spir_kernel void @v2i16_kernarg(<2 x i16> addrspace(1)* %out, <2 x i16> %in) {
  store <2 x i16> %in, <2 x i16> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &v2i32_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][4];
define spir_kernel void @v2i32_kernarg(<2 x i32> addrspace(1)* nocapture %out, <2 x i32> %in) nounwind {
  store <2 x i32> %in, <2 x i32> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &v2f32_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_align(4)_width(all)_f32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_kernarg_align(4)_width(all)_f32 {{\$s[0-9]+}}, [%in][4];
define spir_kernel void @v2f32_kernarg(<2 x float> addrspace(1)* nocapture %out, <2 x float> %in) nounwind {
  store <2 x float> %in, <2 x float> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &v3i8_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][2];
define spir_kernel void @v3i8_kernarg(<3 x i8> addrspace(1)* nocapture %out, <3 x i8> %in) nounwind {
  store <3 x i8> %in, <3 x i8> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &v3i16_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][2];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][4];
; HSAIL: shl_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 16;
; HSAIL: and_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 65535;
; HSAIL: or_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define spir_kernel void @v3i16_kernarg(<3 x i16> addrspace(1)* nocapture %out, <3 x i16> %in) nounwind {
  store <3 x i16> %in, <3 x i16> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &v3i32_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 [[OUT:\$s[0-9]+]], [%out];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][8];

; HSAIL: st_global_align(4)_u32 {{\$s[0-9]+}}, {{\[}}[[OUT]]+4];
; HSAIL: st_global_align(4)_u32 {{\$s[0-9]+}}, {{\[}}[[OUT]]{{\]}};
; HSAIL: st_global_align(4)_u32 {{\$s[0-9]+}}, {{\[}}[[OUT]]+8];

; XHSAIL: pack_u32x2_u32 {{\$d[0-9]+}}, _u32x2(0,0), {{\$s[0-9]+}}, 1;
; XHSAIL: ld_kernarg_align(16)_u32 {{\$s[0-9]+}}, [%in];
; XHSAIL: cvt_u64_u32 {{\$d[0-9]+}}, {{\$s[0-9]+}};
; XHSAIL: or_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};

; HSAIL: ret;
define spir_kernel void @v3i32_kernarg(<3 x i32> addrspace(1)* nocapture %out, <3 x i32> %in) nounwind {
  store <3 x i32> %in, <3 x i32> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &v3f32_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_align(4)_width(all)_f32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_kernarg_align(4)_width(all)_f32 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_kernarg_align(4)_width(all)_f32 {{\$s[0-9]+}}, [%in][8];

; XHSAIL: pack_u32x2_u32 {{\$d[0-9]+}}, _u32x2(0,0), {{\$s[0-9]+}}, 1;
; XHSAIL: cvt_u64_u32 {{\$d[0-9]+}}, {{\$s[0-9]+}};
; XHSAIL: or_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};

; HSAIL: ret;
define spir_kernel void @v3f32_kernarg(<3 x float> addrspace(1)* nocapture %out, <3 x float> %in) nounwind {
  store <3 x float> %in, <3 x float> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &v4i8_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][2];
define spir_kernel void @v4i8_kernarg(<4 x i8> addrspace(1)* %out, <4 x i8> %in) {
  store <4 x i8> %in, <4 x i8> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &v4i16_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][2];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][6];
define spir_kernel void @v4i16_kernarg(<4 x i16> addrspace(1)* %out, <4 x i16> %in) {
  store <4 x i16> %in, <4 x i16> addrspace(1)* %out
  ret void
}


; FUNC-LABEL: {{^}}prog kernel &v4i32_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][8];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][12];
define spir_kernel void @v4i32_kernarg(<4 x i32> addrspace(1)* nocapture %out, <4 x i32> %in) nounwind {
  store <4 x i32> %in, <4 x i32> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &v4f32_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_align(4)_width(all)_f32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_kernarg_align(4)_width(all)_f32 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_kernarg_align(4)_width(all)_f32 {{\$s[0-9]+}}, [%in][8];
; HSAIL: ld_kernarg_align(4)_width(all)_f32 {{\$s[0-9]+}}, [%in][12];
define spir_kernel void @v4f32_kernarg(<4 x float> addrspace(1)* nocapture %out, <4 x float> %in) nounwind {
  store <4 x float> %in, <4 x float> addrspace(1)* %out, align 4
  ret void
}


; FUNC-LABEL: {{^}}prog kernel &v8i8_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][1];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][2];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][3];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][5];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][6];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][7];
; HSAIL: ret;
define spir_kernel void @v8i8_kernarg(<8 x i8> addrspace(1)* %out, <8 x i8> %in) {
  store <8 x i8> %in, <8 x i8> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &v8i16_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][2];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][6];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][8];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][10];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][12];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][14];
define spir_kernel void @v8i16_kernarg(<8 x i16> addrspace(1)* %out, <8 x i16> %in) {
  store <8 x i16> %in, <8 x i16> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &v8i32_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][8];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][12];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][16];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][20];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][24];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][28];
define spir_kernel void @v8i32_kernarg(<8 x i32> addrspace(1)* nocapture %out, <8 x i32> %in) nounwind {
  store <8 x i32> %in, <8 x i32> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &v8f32_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_align(4)_width(all)_f32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_kernarg_align(4)_width(all)_f32 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_kernarg_align(4)_width(all)_f32 {{\$s[0-9]+}}, [%in][8];
; HSAIL: ld_kernarg_align(4)_width(all)_f32 {{\$s[0-9]+}}, [%in][12];
; HSAIL: ld_kernarg_align(4)_width(all)_f32 {{\$s[0-9]+}}, [%in][16];
; HSAIL: ld_kernarg_align(4)_width(all)_f32 {{\$s[0-9]+}}, [%in][20];
; HSAIL: ld_kernarg_align(4)_width(all)_f32 {{\$s[0-9]+}}, [%in][24];
; HSAIL: ld_kernarg_align(4)_width(all)_f32 {{\$s[0-9]+}}, [%in][28];
define spir_kernel void @v8f32_kernarg(<8 x float> addrspace(1)* nocapture %out, <8 x float> %in) nounwind {
  store <8 x float> %in, <8 x float> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &v16i8_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][2];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][3];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][5];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][6];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][7];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][8];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][9];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][10];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][11];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][12];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][13];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][14];
; HSAIL: ld_kernarg_width(all)_u8 {{\$s[0-9]+}}, [%in][15];
define spir_kernel void @v16i8_kernarg(<16 x i8> addrspace(1)* %out, <16 x i8> %in) {
  store <16 x i8> %in, <16 x i8> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &v16i16_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][2];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][6];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][8];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][10];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][12];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][14];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][16];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][18];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][20];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][22];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][24];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][26];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][28];
; HSAIL: ld_kernarg_align(2)_width(all)_u16 {{\$s[0-9]+}}, [%in][30];
define spir_kernel void @v16i16_kernarg(<16 x i16> addrspace(1)* %out, <16 x i16> %in) {
  store <16 x i16> %in, <16 x i16> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &v16i32_kernarg(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][8];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][12];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][16];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][20];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][24];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][28];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][32];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][36];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][40];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][44];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][48];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][52];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][56];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%in][60];
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
define spir_kernel void @v16i32_kernarg(<16 x i32> addrspace(1)* nocapture %out, <16 x i32> %in) nounwind {
  store <16 x i32> %in, <16 x i32> addrspace(1)* %out, align 4
  ret void
}

define spir_kernel void @v16f32_kernarg(<16 x float> addrspace(1)* nocapture %out, <16 x float> %in) nounwind {
  store <16 x float> %in, <16 x float> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &kernel_arg_i64(
; HSAIL: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_kernarg_align(8)_width(all)_u64 {{\$d[0-9]+}}, [%a];
define spir_kernel void @kernel_arg_i64(i64 addrspace(1)* %out, i64 %a) nounwind {
  store i64 %a, i64 addrspace(1)* %out, align 8
  ret void
}
