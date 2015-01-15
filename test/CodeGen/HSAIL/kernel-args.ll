; XFAIL: *
; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &i8_arg
; HSAIL: ld_arg_u8 {{\$s[0-9]+}}, [%in];
; HSAIL: and_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 255;
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @i8_arg(i32 addrspace(1)* nocapture %out, i8 %in) nounwind {
  %tmp0 = zext i8 %in to i32
  store i32 %tmp0, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &i8_zext_arg
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_arg_u8 {{\$s[0-9]+}}, [%in];
define void @i8_zext_arg(i32 addrspace(1)* nocapture %out, i8 zeroext %in) nounwind {
  %tmp0 = zext i8 %in to i32
  store i32 %tmp0, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &i8_sext_arg
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_arg_s8 {{\$s[0-9]+}}, [%in];
define void @i8_sext_arg(i32 addrspace(1)* nocapture %out, i8 signext %in) nounwind {
  %tmp0 = sext i8 %in to i32
  store i32 %tmp0, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &i16_arg
; HSAIL: ld_arg_align(2)_u16 {{\$s[0-9]+}}, [%in];
; HSAIL: and_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 65535;
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @i16_arg(i32 addrspace(1)* nocapture %out, i16 %in) nounwind {
  %tmp0 = zext i16 %in to i32
  store i32 %tmp0, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &i16_zext_arg
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_arg_align(2)_u16 {{\$s[0-9]+}}, [%in];
define void @i16_zext_arg(i32 addrspace(1)* nocapture %out, i16 zeroext %in) nounwind {
  %tmp0 = zext i16 %in to i32
  store i32 %tmp0, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &i16_sext_arg
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_arg_align(2)_s16 {{\$s[0-9]+}}, [%in];
define void @i16_sext_arg(i32 addrspace(1)* nocapture %out, i16 signext %in) nounwind {
  %tmp0 = sext i16 %in to i32
  store i32 %tmp0, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &i32_arg
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
define void @i32_arg(i32 addrspace(1)* nocapture %out, i32 %in) nounwind {
  store i32 %in, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &f32_arg
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_arg_align(4)_f32 {{\$s[0-9]+}}, [%in];
define void @f32_arg(float addrspace(1)* nocapture %out, float %in) nounwind {
  store float %in, float addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &v2i8_arg
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_arg_align(2)_u8 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_u8 {{\$s[0-9]+}}, [%in][1];
define void @v2i8_arg(<2 x i8> addrspace(1)* %out, <2 x i8> %in) {
  store <2 x i8> %in, <2 x i8> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &v2i16_arg
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_arg_align(4)_u16 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(2)_u16 {{\$s[0-9]+}}, [%in][2];
define void @v2i16_arg(<2 x i16> addrspace(1)* %out, <2 x i16> %in) {
  store <2 x i16> %in, <2 x i16> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &v2i32_arg
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_arg_align(8)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in][4];
define void @v2i32_arg(<2 x i32> addrspace(1)* nocapture %out, <2 x i32> %in) nounwind {
  store <2 x i32> %in, <2 x i32> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &v2f32_arg
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_arg_align(8)_f32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(4)_f32 {{\$s[0-9]+}}, [%in][4];
define void @v2f32_arg(<2 x float> addrspace(1)* nocapture %out, <2 x float> %in) nounwind {
  store <2 x float> %in, <2 x float> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &v3i8_arg
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_arg_align(4)_u8 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(2)_u8 {{\$s[0-9]+}}, [%in][2];
define void @v3i8_arg(<3 x i8> addrspace(1)* nocapture %out, <3 x i8> %in) nounwind {
  store <3 x i8> %in, <3 x i8> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &v3i16_arg
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_arg_align(8)_u16 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(2)_u16 {{\$s[0-9]+}}, [%in][2];
; HSAIL: ld_arg_align(4)_u16 {{\$s[0-9]+}}, [%in][4];
; HSAIL: shl_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 16;
; HSAIL: and_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 65535;
; HSAIL: or_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @v3i16_arg(<3 x i16> addrspace(1)* nocapture %out, <3 x i16> %in) nounwind {
  store <3 x i16> %in, <3 x i16> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &v3i32_arg
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_arg_align(8)_u32 {{\$s[0-9]+}}, [%in][8];
; HSAIL: pack_u32x2_u32 {{\$d[0-9]+}}, _u32x2(0,0), {{\$s[0-9]+}}, 1;
; HSAIL: ld_arg_align(16)_u32 {{\$s[0-9]+}}, [%in];

; HSAIL: cvt_u64_u32 {{\$d[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: or_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @v3i32_arg(<3 x i32> addrspace(1)* nocapture %out, <3 x i32> %in) nounwind {
  store <3 x i32> %in, <3 x i32> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &v3f32_arg
; HSAIL: ld_arg_align(16)_f32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(4)_f32 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_arg_align(8)_f32 {{\$s[0-9]+}}, [%in][8];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];

; HSAIL: pack_u32x2_u32 {{\$d[0-9]+}}, _u32x2(0,0), {{\$s[0-9]+}}, 1;
; HSAIL: cvt_u64_u32 {{\$d[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: or_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @v3f32_arg(<3 x float> addrspace(1)* nocapture %out, <3 x float> %in) nounwind {
  store <3 x float> %in, <3 x float> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &v4i8_arg
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_arg_align(4)_u8 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(2)_u8 {{\$s[0-9]+}}, [%in][2];
define void @v4i8_arg(<4 x i8> addrspace(1)* %out, <4 x i8> %in) {
  store <4 x i8> %in, <4 x i8> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &v4i16_arg
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_arg_align(8)_u16 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(2)_u16 {{\$s[0-9]+}}, [%in][2];
; HSAIL: ld_arg_align(4)_u16 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_arg_align(2)_u16 {{\$s[0-9]+}}, [%in][6];
define void @v4i16_arg(<4 x i16> addrspace(1)* %out, <4 x i16> %in) {
  store <4 x i16> %in, <4 x i16> addrspace(1)* %out
  ret void
}


; FUNC-LABEL: {{^}}prog function &v4i32_arg
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_arg_align(16)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_arg_align(8)_u32 {{\$s[0-9]+}}, [%in][8];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in][12];
define void @v4i32_arg(<4 x i32> addrspace(1)* nocapture %out, <4 x i32> %in) nounwind {
  store <4 x i32> %in, <4 x i32> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &v4f32_arg
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_arg_align(16)_f32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(4)_f32 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_arg_align(8)_f32 {{\$s[0-9]+}}, [%in][8];
; HSAIL: ld_arg_align(4)_f32 {{\$s[0-9]+}}, [%in][12];
define void @v4f32_arg(<4 x float> addrspace(1)* nocapture %out, <4 x float> %in) nounwind {
  store <4 x float> %in, <4 x float> addrspace(1)* %out, align 4
  ret void
}


; FUNC-LABEL: {{^}}prog function &v8i8_arg
; HSAIL: ld_arg_align(8)_u8 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(2)_u8 {{\$s[0-9]+}}, [%in][2];
; HSAIL: ld_arg_u8 {{\$s[0-9]+}}, [%in][3];
; HSAIL: ld_arg_align(4)_u8 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_arg_u8 {{\$s[0-9]+}}, [%in][5];
; HSAIL: ld_arg_align(2)_u8 {{\$s[0-9]+}}, [%in][6];
; HSAIL: ld_arg_u8 {{\$s[0-9]+}}, [%in][7];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @v8i8_arg(<8 x i8> addrspace(1)* %out, <8 x i8> %in) {
  store <8 x i8> %in, <8 x i8> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &v8i16_arg
; HSAIL: ld_arg_align(16)_u16 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(2)_u16 {{\$s[0-9]+}}, [%in][2];
; HSAIL: ld_arg_align(4)_u16 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_arg_align(2)_u16 {{\$s[0-9]+}}, [%in][6];
; HSAIL: ld_arg_align(8)_u16 {{\$s[0-9]+}}, [%in][8];
; HSAIL: ld_arg_align(2)_u16 {{\$s[0-9]+}}, [%in][10];
; HSAIL: ld_arg_align(4)_u16 {{\$s[0-9]+}}, [%in][12];
; HSAIL: ld_arg_align(2)_u16 {{\$s[0-9]+}}, [%in][14];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @v8i16_arg(<8 x i16> addrspace(1)* %out, <8 x i16> %in) {
  store <8 x i16> %in, <8 x i16> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &v8i32_arg
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_arg_align(32)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_arg_align(8)_u32 {{\$s[0-9]+}}, [%in][8];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in][12];
; HSAIL: ld_arg_align(16)_u32 {{\$s[0-9]+}}, [%in][16];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in][20];
; HSAIL: ld_arg_align(8)_u32 {{\$s[0-9]+}}, [%in][24];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in][28];
define void @v8i32_arg(<8 x i32> addrspace(1)* nocapture %out, <8 x i32> %in) nounwind {
  store <8 x i32> %in, <8 x i32> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &v8f32_arg
; HSAIL: ld_arg_align(32)_f32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(4)_f32 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_arg_align(8)_f32 {{\$s[0-9]+}}, [%in][8];
; HSAIL: ld_arg_align(4)_f32 {{\$s[0-9]+}}, [%in][12];
; HSAIL: ld_arg_align(16)_f32 {{\$s[0-9]+}}, [%in][16];
; HSAIL: ld_arg_align(4)_f32 {{\$s[0-9]+}}, [%in][20];
; HSAIL: ld_arg_align(8)_f32 {{\$s[0-9]+}}, [%in][24];
; HSAIL: ld_arg_align(4)_f32 {{\$s[0-9]+}}, [%in][28];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @v8f32_arg(<8 x float> addrspace(1)* nocapture %out, <8 x float> %in) nounwind {
  store <8 x float> %in, <8 x float> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &v16i8_arg
; HSAIL: ld_arg_align(16)_u8 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(2)_u8 {{\$s[0-9]+}}, [%in][2];
; HSAIL: ld_arg_u8 {{\$s[0-9]+}}, [%in][3];
; HSAIL: ld_arg_align(4)_u8 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_arg_u8 {{\$s[0-9]+}}, [%in][5];
; HSAIL: ld_arg_align(2)_u8 {{\$s[0-9]+}}, [%in][6];
; HSAIL: ld_arg_u8 {{\$s[0-9]+}}, [%in][7];
; HSAIL: ld_arg_align(8)_u8 {{\$s[0-9]+}}, [%in][8];
; HSAIL: ld_arg_u8 {{\$s[0-9]+}}, [%in][9];
; HSAIL: ld_arg_align(2)_u8 {{\$s[0-9]+}}, [%in][10];
; HSAIL: ld_arg_u8 {{\$s[0-9]+}}, [%in][11];
; HSAIL: ld_arg_align(4)_u8 {{\$s[0-9]+}}, [%in][12];
; HSAIL: ld_arg_u8 {{\$s[0-9]+}}, [%in][13];
; HSAIL: ld_arg_align(2)_u8 {{\$s[0-9]+}}, [%in][14];
; HSAIL: ld_arg_u8 {{\$s[0-9]+}}, [%in][15];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @v16i8_arg(<16 x i8> addrspace(1)* %out, <16 x i8> %in) {
  store <16 x i8> %in, <16 x i8> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &v16i16_arg
; HSAIL: ld_arg_align(32)_u16 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(2)_u16 {{\$s[0-9]+}}, [%in][2];
; HSAIL: ld_arg_align(4)_u16 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_arg_align(2)_u16 {{\$s[0-9]+}}, [%in][6];
; HSAIL: ld_arg_align(8)_u16 {{\$s[0-9]+}}, [%in][8];
; HSAIL: ld_arg_align(2)_u16 {{\$s[0-9]+}}, [%in][10];
; HSAIL: ld_arg_align(4)_u16 {{\$s[0-9]+}}, [%in][12];
; HSAIL: ld_arg_align(2)_u16 {{\$s[0-9]+}}, [%in][14];
; HSAIL: ld_arg_align(16)_u16 {{\$s[0-9]+}}, [%in][16];
; HSAIL: ld_arg_align(2)_u16 {{\$s[0-9]+}}, [%in][18];
; HSAIL: ld_arg_align(4)_u16 {{\$s[0-9]+}}, [%in][20];
; HSAIL: ld_arg_align(2)_u16 {{\$s[0-9]+}}, [%in][22];
; HSAIL: ld_arg_align(8)_u16 {{\$s[0-9]+}}, [%in][24];
; HSAIL: ld_arg_align(2)_u16 {{\$s[0-9]+}}, [%in][26];
; HSAIL: ld_arg_align(4)_u16 {{\$s[0-9]+}}, [%in][28];
; HSAIL: ld_arg_align(2)_u16 {{\$s[0-9]+}}, [%in][30];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @v16i16_arg(<16 x i16> addrspace(1)* %out, <16 x i16> %in) {
  store <16 x i16> %in, <16 x i16> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &v16i32_arg
; HSAIL: ld_arg_align(64)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in][4];
; HSAIL: ld_arg_align(8)_u32 {{\$s[0-9]+}}, [%in][8];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in][12];
; HSAIL: ld_arg_align(16)_u32 {{\$s[0-9]+}}, [%in][16];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in][20];
; HSAIL: ld_arg_align(8)_u32 {{\$s[0-9]+}}, [%in][24];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in][28];
; HSAIL: ld_arg_align(32)_u32 {{\$s[0-9]+}}, [%in][32];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in][36];
; HSAIL: ld_arg_align(8)_u32 {{\$s[0-9]+}}, [%in][40];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in][44];
; HSAIL: ld_arg_align(16)_u32 {{\$s[0-9]+}}, [%in][48];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in][52];
; HSAIL: ld_arg_align(8)_u32 {{\$s[0-9]+}}, [%in][56];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in][60];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @v16i32_arg(<16 x i32> addrspace(1)* nocapture %out, <16 x i32> %in) nounwind {
  store <16 x i32> %in, <16 x i32> addrspace(1)* %out, align 4
  ret void
}

define void @v16f32_arg(<16 x float> addrspace(1)* nocapture %out, <16 x float> %in) nounwind {
  store <16 x float> %in, <16 x float> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}prog function &kernel_arg_i64
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_arg_align(8)_u64 {{\$d[0-9]+}}, [%a];
define void @kernel_arg_i64(i64 addrspace(1)* %out, i64 %a) nounwind {
  store i64 %a, i64 addrspace(1)* %out, align 8
  ret void
}
