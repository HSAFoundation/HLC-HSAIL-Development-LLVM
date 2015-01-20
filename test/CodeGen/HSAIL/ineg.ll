; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &ineg_s32(
; HSAIL: neg_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @ineg_s32(i32 addrspace(1)* %out, i32 %in) {
  %ineg = sub i32 0, %in
  store i32 %ineg, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &ineg_v2i32(
; HSAIL: neg_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: neg_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @ineg_v2i32(<2 x i32> addrspace(1)* nocapture %out, <2 x i32> %in) {
  %ineg = sub <2 x i32> zeroinitializer, %in
  store <2 x i32> %ineg, <2 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &ineg_v4i32(
; HSAIL: neg_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: neg_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: neg_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: neg_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @ineg_v4i32(<4 x i32> addrspace(1)* nocapture %out, <4 x i32> %in) {
  %ineg = sub <4 x i32> zeroinitializer, %in
  store <4 x i32> %ineg, <4 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &ineg_free_i32(
; HSAIL: neg_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @ineg_free_i32(i32 addrspace(1)* %out, i32 %in) {
  %bc = bitcast i32 %in to i32
  %sub = sub i32 0, %bc
  store i32 %sub, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &ineg_fold_i32(
; HSAIL: neg_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: mul_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @ineg_fold_i32(i32 addrspace(1)* %out, i32 %in) {
  %sub = sub i32 0, %in
  %mul = mul i32 %sub, %in
  store i32 %mul, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &ineg_s64(
; HSAIL: neg_s64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @ineg_s64(i64 addrspace(1)* %out, i64 %in) {
  %ineg = sub i64 0, %in
  store i64 %ineg, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &ineg_v2i64(
; HSAIL: neg_s64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: neg_s64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @ineg_v2i64(<2 x i64> addrspace(1)* nocapture %out, <2 x i64> %in) {
  %ineg = sub <2 x i64> zeroinitializer, %in
  store <2 x i64> %ineg, <2 x i64> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &ineg_v4i64(
; HSAIL: neg_s64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: neg_s64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: neg_s64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: neg_s64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @ineg_v4i64(<4 x i64> addrspace(1)* nocapture %out, <4 x i64> %in) {
  %ineg = sub <4 x i64> zeroinitializer, %in
  store <4 x i64> %ineg, <4 x i64> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &ineg_free_i64(
; HSAIL: neg_s64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @ineg_free_i64(i64 addrspace(1)* %out, i64 %in) {
  %bc = bitcast i64 %in to i64
  %sub = sub i64 0, %bc
  store i64 %sub, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &ineg_fold_i64(
; HSAIL: neg_s64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: mul_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @ineg_fold_i64(i64 addrspace(1)* %out, i64 %in) {
  %sub = sub i64 0, %in
  %mul = mul i64 %sub, %in
  store i64 %mul, i64 addrspace(1)* %out
  ret void
}
