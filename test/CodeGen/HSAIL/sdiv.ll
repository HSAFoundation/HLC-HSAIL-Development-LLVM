; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &sdiv_i32
; HSAIL: div_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @sdiv_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %den_ptr = getelementptr i32, i32 addrspace(1)* %in, i32 1
  %num = load i32, i32 addrspace(1) * %in
  %den = load i32, i32 addrspace(1) * %den_ptr
  %result = sdiv i32 %num, %den
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &sdiv_i32_4
; HSAIL: shr_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 31;
; HSAIL: shr_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 30;
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: shr_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 2;
define void @sdiv_i32_4(i32 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %num = load i32, i32 addrspace(1) * %in
  %result = sdiv i32 %num, 4
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &slow_sdiv_i32_3435
; XHSAIL: mulhi_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, -1734241525;
; XHSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; XHSAIL: shr_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 31;
; XHSAIL: shr_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 11;
; XHSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @slow_sdiv_i32_3435(i32 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %num = load i32, i32 addrspace(1) * %in
  %result = sdiv i32 %num, 3435
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &sdiv_v2i32
; HSAIL: div_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: div_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @sdiv_v2i32(<2 x i32> addrspace(1)* %out, <2 x i32> addrspace(1)* %in) {
  %den_ptr = getelementptr <2 x i32>, <2 x i32> addrspace(1)* %in, i32 1
  %num = load <2 x i32>, <2 x i32> addrspace(1) * %in
  %den = load <2 x i32>, <2 x i32> addrspace(1) * %den_ptr
  %result = sdiv <2 x i32> %num, %den
  store <2 x i32> %result, <2 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &sdiv_v2i32_4
; HSAIL: shr_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 31;
; HSAIL: shr_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 30;
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: shr_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 2;
; HSAIL: shr_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 31;
; HSAIL: shr_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 30;
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: shr_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 2;
define void @sdiv_v2i32_4(<2 x i32> addrspace(1)* %out, <2 x i32> addrspace(1)* %in) {
  %num = load <2 x i32>, <2 x i32> addrspace(1) * %in
  %result = sdiv <2 x i32> %num, <i32 4, i32 4>
  store <2 x i32> %result, <2 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &sdiv_v4i32
; HSAIL: div_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: div_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: div_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: div_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @sdiv_v4i32(<4 x i32> addrspace(1)* %out, <4 x i32> addrspace(1)* %in) {
  %den_ptr = getelementptr <4 x i32>, <4 x i32> addrspace(1)* %in, i32 1
  %num = load <4 x i32>, <4 x i32> addrspace(1) * %in
  %den = load <4 x i32>, <4 x i32> addrspace(1) * %den_ptr
  %result = sdiv <4 x i32> %num, %den
  store <4 x i32> %result, <4 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &sdiv_v4i32_4
; HSAIL: shr_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 31;
; HSAIL: shr_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 30;
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: shr_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 31;
; HSAIL: shr_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 30;
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: shr_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 2;
; HSAIL: shr_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 31;
; HSAIL: shr_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 30;
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: shr_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 2;
define void @sdiv_v4i32_4(<4 x i32> addrspace(1)* %out, <4 x i32> addrspace(1)* %in) {
  %num = load <4 x i32>, <4 x i32> addrspace(1) * %in
  %result = sdiv <4 x i32> %num, <i32 4, i32 4, i32 4, i32 4>
  store <4 x i32> %result, <4 x i32> addrspace(1)* %out
  ret void
}
