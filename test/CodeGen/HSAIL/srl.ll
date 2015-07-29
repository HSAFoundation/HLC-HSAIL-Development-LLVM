; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &lshr_i32
; HSAIL: shr_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @lshr_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %b_ptr = getelementptr i32 addrspace(1)* %in, i32 1
  %a = load i32 addrspace(1)* %in
  %b = load i32 addrspace(1)* %b_ptr
  %result = lshr i32 %a, %b
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &lshr_v2i32
; HSAIL: shr_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: shr_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @lshr_v2i32(<2 x i32> addrspace(1)* %out, <2 x i32> addrspace(1)* %in) {
  %b_ptr = getelementptr <2 x i32> addrspace(1)* %in, i32 1
  %a = load <2 x i32> addrspace(1) * %in
  %b = load <2 x i32> addrspace(1) * %b_ptr
  %result = lshr <2 x i32> %a, %b
  store <2 x i32> %result, <2 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &lshr_v4i32
; HSAIL: shr_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: shr_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: shr_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: shr_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @lshr_v4i32(<4 x i32> addrspace(1)* %out, <4 x i32> addrspace(1)* %in) {
  %b_ptr = getelementptr <4 x i32> addrspace(1)* %in, i32 1
  %a = load <4 x i32> addrspace(1) * %in
  %b = load <4 x i32> addrspace(1) * %b_ptr
  %result = lshr <4 x i32> %a, %b
  store <4 x i32> %result, <4 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &lshr_i64
; HSAIL: shr_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$s[0-9]+}};
define void @lshr_i64(i64 addrspace(1)* %out, i64 addrspace(1)* %in) {
  %b_ptr = getelementptr i64 addrspace(1)* %in, i64 1
  %a = load i64 addrspace(1) * %in
  %b = load i64 addrspace(1) * %b_ptr
  %result = lshr i64 %a, %b
  store i64 %result, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &lshr_v2i64
; HSAIL: shr_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: shr_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$s[0-9]+}};
define void @lshr_v2i64(<2 x i64> addrspace(1)* %out, <2 x i64> addrspace(1)* %in) {
  %b_ptr = getelementptr <2 x i64> addrspace(1)* %in, i64 1
  %a = load <2 x i64> addrspace(1) * %in
  %b = load <2 x i64> addrspace(1) * %b_ptr
  %result = lshr <2 x i64> %a, %b
  store <2 x i64> %result, <2 x i64> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &lshr_v4i64
; HSAIL: shr_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: shr_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: shr_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: shr_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$s[0-9]+}};
define void @lshr_v4i64(<4 x i64> addrspace(1)* %out, <4 x i64> addrspace(1)* %in) {
  %b_ptr = getelementptr <4 x i64> addrspace(1)* %in, i64 1
  %a = load <4 x i64> addrspace(1) * %in
  %b = load <4 x i64> addrspace(1) * %b_ptr
  %result = lshr <4 x i64> %a, %b
  store <4 x i64> %result, <4 x i64> addrspace(1)* %out
  ret void
}
