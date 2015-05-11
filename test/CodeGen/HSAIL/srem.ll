; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &srem_i32(
; HSAIL: rem_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @srem_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %den_ptr = getelementptr i32, i32 addrspace(1)* %in, i32 1
  %num = load i32, i32 addrspace(1) * %in
  %den = load i32, i32 addrspace(1) * %den_ptr
  %result = srem i32 %num, %den
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &srem_i32_4(
; HSAIL-NOT: rem_s32
; HSAIL: ret;
define void @srem_i32_4(i32 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %num = load i32, i32 addrspace(1) * %in
  %result = srem i32 %num, 4
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; FIXME: Should use fast expansion
; HSAIL-LABEL: {{^}}prog function &srem_i32_7(
; XHSAIL: mulhi_s32 {{\$s[0-9]+}}, 2454267027
; XHSAIL: mullo_s32
; XHSAIL: sub_s32

; HSAIL-NOT: rem_s32
; HSAIL: mul_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 18446744071868851347;
; HSAIL-NOT: rem_f32
; HSAIL: ret;
define void @srem_i32_7(i32 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %num = load i32, i32 addrspace(1) * %in
  %result = srem i32 %num, 7
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &srem_v2i32(
; HSAIL: rem_s32
; HSAIL: rem_s32
define void @srem_v2i32(<2 x i32> addrspace(1)* %out, <2 x i32> addrspace(1)* %in) {
  %den_ptr = getelementptr <2 x i32>, <2 x i32> addrspace(1)* %in, i32 1
  %num = load <2 x i32>, <2 x i32> addrspace(1) * %in
  %den = load <2 x i32>, <2 x i32> addrspace(1) * %den_ptr
  %result = srem <2 x i32> %num, %den
  store <2 x i32> %result, <2 x i32> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &srem_v2i32_4(
; HSAIL-NOT: rem_s32
; HSAIL: ret
define void @srem_v2i32_4(<2 x i32> addrspace(1)* %out, <2 x i32> addrspace(1)* %in) {
  %num = load <2 x i32>, <2 x i32> addrspace(1) * %in
  %result = srem <2 x i32> %num, <i32 4, i32 4>
  store <2 x i32> %result, <2 x i32> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &srem_v4i32(
; HSAIL: rem_s32
; HSAIL: rem_s32
; HSAIL: rem_s32
; HSAIL: rem_s32
define void @srem_v4i32(<4 x i32> addrspace(1)* %out, <4 x i32> addrspace(1)* %in) {
  %den_ptr = getelementptr <4 x i32>, <4 x i32> addrspace(1)* %in, i32 1
  %num = load <4 x i32>, <4 x i32> addrspace(1) * %in
  %den = load <4 x i32>, <4 x i32> addrspace(1) * %den_ptr
  %result = srem <4 x i32> %num, %den
  store <4 x i32> %result, <4 x i32> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &srem_v4i32_4(
; HSAIL-NOT: rem_s32
; HSAIL: ret;
define void @srem_v4i32_4(<4 x i32> addrspace(1)* %out, <4 x i32> addrspace(1)* %in) {
  %num = load <4 x i32>, <4 x i32> addrspace(1) * %in
  %result = srem <4 x i32> %num, <i32 4, i32 4, i32 4, i32 4>
  store <4 x i32> %result, <4 x i32> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &srem_i64(
; HSAIL: rem_s64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @srem_i64(i64 addrspace(1)* %out, i64 addrspace(1)* %in) {
  %den_ptr = getelementptr i64, i64 addrspace(1)* %in, i64 1
  %num = load i64, i64 addrspace(1) * %in
  %den = load i64, i64 addrspace(1) * %den_ptr
  %result = srem i64 %num, %den
  store i64 %result, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &srem_i64_4(
; HSAIL-NOT: srem_s64
; HSAIL: ret;
define void @srem_i64_4(i64 addrspace(1)* %out, i64 addrspace(1)* %in) {
  %num = load i64, i64 addrspace(1) * %in
  %result = srem i64 %num, 4
  store i64 %result, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &srem_v2i64(
; HSAIL: rem_s64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: rem_s64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @srem_v2i64(<2 x i64> addrspace(1)* %out, <2 x i64> addrspace(1)* %in) {
  %den_ptr = getelementptr <2 x i64>, <2 x i64> addrspace(1)* %in, i64 1
  %num = load <2 x i64>, <2 x i64> addrspace(1) * %in
  %den = load <2 x i64>, <2 x i64> addrspace(1) * %den_ptr
  %result = srem <2 x i64> %num, %den
  store <2 x i64> %result, <2 x i64> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &srem_v2i64_4(
; HSAIL-NOT: rem_s64
; HSAIL: ret;
define void @srem_v2i64_4(<2 x i64> addrspace(1)* %out, <2 x i64> addrspace(1)* %in) {
  %num = load <2 x i64>, <2 x i64> addrspace(1) * %in
  %result = srem <2 x i64> %num, <i64 4, i64 4>
  store <2 x i64> %result, <2 x i64> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &srem_v4i64(
; HSAIL: rem_s64
; HSAIL: rem_s64
; HSAIL: rem_s64
; HSAIL: rem_s64
define void @srem_v4i64(<4 x i64> addrspace(1)* %out, <4 x i64> addrspace(1)* %in) {
  %den_ptr = getelementptr <4 x i64>, <4 x i64> addrspace(1)* %in, i64 1
  %num = load <4 x i64>, <4 x i64> addrspace(1) * %in
  %den = load <4 x i64>, <4 x i64> addrspace(1) * %den_ptr
  %result = srem <4 x i64> %num, %den
  store <4 x i64> %result, <4 x i64> addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &srem_v4i64_4(
; HSAIL-NOT: rem_s64
; HSAIL: ret;
define void @srem_v4i64_4(<4 x i64> addrspace(1)* %out, <4 x i64> addrspace(1)* %in) {
  %num = load <4 x i64>, <4 x i64> addrspace(1) * %in
  %result = srem <4 x i64> %num, <i64 4, i64 4, i64 4, i64 4>
  store <4 x i64> %result, <4 x i64> addrspace(1)* %out
  ret void
}
