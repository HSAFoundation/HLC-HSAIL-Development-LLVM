;RUN: llc -march=hsail -filetype=asm  < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

declare i32 @llvm.HSAIL.get.global.id(i32) readnone

; FUNC-LABEL: {{^}}prog function &test_sub_i32
; HSAIL: sub_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @test_sub_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %b_ptr = getelementptr i32 addrspace(1)* %in, i32 1
  %a = load i32 addrspace(1)* %in
  %b = load i32 addrspace(1)* %b_ptr
  %result = sub i32 %a, %b
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_sub_v2i32
; HSAIL: sub_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: sub_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @test_sub_v2i32(<2 x i32> addrspace(1)* %out, <2 x i32> addrspace(1)* %in) {
  %b_ptr = getelementptr <2 x i32> addrspace(1)* %in, i32 1
  %a = load <2 x i32> addrspace(1)* %in
  %b = load <2 x i32> addrspace(1)* %b_ptr
  %result = sub <2 x i32> %a, %b
  store <2 x i32> %result, <2 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_sub_v4i32
; HSAIL: sub_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: sub_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: sub_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: sub_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @test_sub_v4i32(<4 x i32> addrspace(1)* %out, <4 x i32> addrspace(1)* %in) {
  %b_ptr = getelementptr <4 x i32> addrspace(1)* %in, i32 1
  %a = load <4 x i32> addrspace(1)* %in
  %b = load <4 x i32> addrspace(1)* %b_ptr
  %result = sub <4 x i32> %a, %b
  store <4 x i32> %result, <4 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &s_sub_i64
; HSAIL: sub_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @s_sub_i64(i64 addrspace(1)* noalias %out, i64 %a, i64 %b) nounwind {
  %result = sub i64 %a, %b
  store i64 %result, i64 addrspace(1)* %out, align 8
  ret void
}

; FUNC-LABEL: {{^}}prog function &v_sub_i64
; HSAIL: shl_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 3;
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: sub_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @v_sub_i64(i64 addrspace(1)* noalias %out, i64 addrspace(1)* noalias %inA, i64 addrspace(1)* noalias %inB) nounwind {
  %tid = call i32 @llvm.HSAIL.get.global.id(i32 0) readnone
  %a_ptr = getelementptr i64 addrspace(1)* %inA, i32 %tid
  %b_ptr = getelementptr i64 addrspace(1)* %inB, i32 %tid
  %a = load i64 addrspace(1)* %a_ptr
  %b = load i64 addrspace(1)* %b_ptr
  %result = sub i64 %a, %b
  store i64 %result, i64 addrspace(1)* %out, align 8
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_sub_v2i64
; HSAIL: sub_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: sub_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @test_sub_v2i64(<2 x i64> addrspace(1)* %out, <2 x i64> addrspace(1)* %in) {
  %b_ptr = getelementptr <2 x i64> addrspace(1)* %in, i64 1
  %a = load <2 x i64> addrspace(1)* %in
  %b = load <2 x i64> addrspace(1)* %b_ptr
  %result = sub <2 x i64> %a, %b
  store <2 x i64> %result, <2 x i64> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_sub_v4i64
; HSAIL: sub_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: sub_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: sub_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: sub_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @test_sub_v4i64(<4 x i64> addrspace(1)* %out, <4 x i64> addrspace(1)* %in) {
  %b_ptr = getelementptr <4 x i64> addrspace(1)* %in, i64 1
  %a = load <4 x i64> addrspace(1)* %in
  %b = load <4 x i64> addrspace(1)* %b_ptr
  %result = sub <4 x i64> %a, %b
  store <4 x i64> %result, <4 x i64> addrspace(1)* %out
  ret void
}
