; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &i8_arg(
; HSAIL: ld_arg_u8 [[REG:\$s[0-9]+]], [%y];
; HSAIL: st_global_u8 [[REG]]
define void @i8_arg(i8 %x, i8 %y, i8 addrspace(1)* %out) {
  store i8 %y, i8 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &i8_arg_sext(
; HSAIL: ld_arg_u8 [[REG0:\$s[0-9]+]], [%y];
; HSAIL: shl_u32 [[REG1:\$s[0-9]+]], [[REG0]], 24;
; HSAIL: shr_s32 [[REG2:\$s[0-9]+]], [[REG1]], 24;
; HSAIL: st_global_align(4)_u32 [[REG2]]
define void @i8_arg_sext(i8 %x, i8 %y, i32 addrspace(1)* %out) {
  %exty = sext i8 %y to i32
  store i32 %exty, i32 addrspace(1)* %out
  ret void
}

; FIXME: The and is redundant
; HSAIL-LABEL: {{^}}prog function &i8_arg_zext(
; HSAIL: ld_arg_u8 [[REG0:\$s[0-9]+]], [%y];
; HSAIL: and_b32 [[REG1:\$s[0-9]+]], [[REG0]], 255;
; HSAIL: st_global_align(4)_u32 [[REG1]]
define void @i8_arg_zext(i8 %x, i8 %y, i32 addrspace(1)* %out) {
  %exty = zext i8 %y to i32
  store i32 %exty, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &i8_sext_arg_ext(
; HSAIL: ld_arg_s8 [[REG:\$s[0-9]+]], [%y];
; HSAIL-NEXT: st_global_align(4)_u32 [[REG]],
define void @i8_sext_arg_ext(i8 signext %x, i8 signext %y, i32 addrspace(1)* %out) {
  %exty = sext i8 %y to i32
  store i32 %exty, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &i8_zext_arg_ext(
; HSAIL: ld_arg_u8 [[REG:\$s[0-9]+]], [%y];
; HSAIL-NEXT: st_global_align(4)_u32 [[REG]],
define void @i8_zext_arg_ext(i8 zeroext %x, i8 zeroext %y, i32 addrspace(1)* %out) {
  %exty = zext i8 %y to i32
  store i32 %exty, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &i8_sext_arg(
; HSAIL: ld_arg_s8 [[REG:\$s[0-9]+]], [%y];
; HSAIL-NEXT: st_global_u8 [[REG]],
define void @i8_sext_arg(i8 signext %x, i8 signext %y, i8 addrspace(1)* %out) {
  store i8 %y, i8 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &i8_zext_arg(
; HSAIL: ld_arg_u8 [[REG:\$s[0-9]+]], [%y];
; HSAIL-NEXT: st_global_u8 [[REG]],
define void @i8_zext_arg(i8 zeroext %x, i8 zeroext %y, i8 addrspace(1)* %out) {
  store i8 %y, i8 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &i16_arg(
; HSAIL: ld_arg_align(2)_u16 [[REG:\$s[0-9]+]], [%y];
; HSAIL: st_global_align(2)_u16 [[REG]]
define void @i16_arg(i16 %x, i16 %y, i16 addrspace(1)* %out) {
  store i16 %y, i16 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &i16_arg_sext(
; HSAIL: ld_arg_align(2)_u16 [[REG0:\$s[0-9]+]], [%y];
; HSAIL: shl_u32 [[REG1:\$s[0-9]+]], [[REG0]], 16;
; HSAIL: shr_s32 [[REG2:\$s[0-9]+]], [[REG1]], 16;
; HSAIL: st_global_align(4)_u32 [[REG2]]
define void @i16_arg_sext(i16 %x, i16 %y, i32 addrspace(1)* %out) {
  %exty = sext i16 %y to i32
  store i32 %exty, i32 addrspace(1)* %out
  ret void
}

; FIXME: The and is redundant
; HSAIL-LABEL: {{^}}prog function &i16_arg_zext(
; HSAIL: ld_arg_align(2)_u16 [[REG0:\$s[0-9]+]], [%y];
; HSAIL: and_b32 [[REG1:\$s[0-9]+]], [[REG0]], 65535;
; HSAIL: st_global_align(4)_u32 [[REG1]]
define void @i16_arg_zext(i16 %x, i16 %y, i32 addrspace(1)* %out) {
  %exty = zext i16 %y to i32
  store i32 %exty, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &i16_sext_arg_ext(
; HSAIL: ld_arg_align(2)_s16 [[REG:\$s[0-9]+]], [%y];
; HSAIL-NEXT: st_global_align(4)_u32 [[REG]],
define void @i16_sext_arg_ext(i16 signext %x, i16 signext %y, i32 addrspace(1)* %out) {
  %exty = sext i16 %y to i32
  store i32 %exty, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &i16_zext_arg_ext(
; HSAIL: ld_arg_align(2)_u16 [[REG:\$s[0-9]+]], [%y];
; HSAIL-NEXT: st_global_align(4)_u32 [[REG]],
define void @i16_zext_arg_ext(i16 zeroext %x, i16 zeroext %y, i32 addrspace(1)* %out) {
  %exty = zext i16 %y to i32
  store i32 %exty, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &i16_sext_arg(
; HSAIL: ld_arg_align(2)_s16 [[REG:\$s[0-9]+]], [%y];
; HSAIL-NEXT: st_global_align(2)_u16 [[REG]],
define void @i16_sext_arg(i16 signext %x, i16 signext %y, i16 addrspace(1)* %out) {
  store i16 %y, i16 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &i16_zext_arg(
; HSAIL: ld_arg_align(2)_u16 [[REG:\$s[0-9]+]], [%y];
; HSAIL-NEXT: st_global_align(2)_u16 [[REG]],
define void @i16_zext_arg(i16 zeroext %x, i16 zeroext %y, i16 addrspace(1)* %out) {
  store i16 %y, i16 addrspace(1)* %out
  ret void
}
