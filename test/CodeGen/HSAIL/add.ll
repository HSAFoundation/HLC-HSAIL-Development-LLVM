; RUN: llc < %s -march=hsail | FileCheck --check-prefix=HSAIL --check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &test1
; HSAIL: add_u32
define void @test1(i32 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %b_ptr = getelementptr i32 addrspace(1)* %in, i32 1
  %a = load i32 addrspace(1)* %in
  %b = load i32 addrspace(1)* %b_ptr
  %result = add i32 %a, %b
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: prog function &test2
; HSAIL: add_u32
; HSAIL: add_u32
define void @test2(<2 x i32> addrspace(1)* %out, <2 x i32> addrspace(1)* %in) {
  %b_ptr = getelementptr <2 x i32> addrspace(1)* %in, i32 1
  %a = load <2 x i32> addrspace(1)* %in
  %b = load <2 x i32> addrspace(1)* %b_ptr
  %result = add <2 x i32> %a, %b
  store <2 x i32> %result, <2 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: prog function &test4
; HSAL: add_u32
; HSAL: add_u32
; HSAL: add_u32
; HSAL: add_u32
define void @test4(<4 x i32> addrspace(1)* %out, <4 x i32> addrspace(1)* %in) {
  %b_ptr = getelementptr <4 x i32> addrspace(1)* %in, i32 1
  %a = load <4 x i32> addrspace(1)* %in
  %b = load <4 x i32> addrspace(1)* %b_ptr
  %result = add <4 x i32> %a, %b
  store <4 x i32> %result, <4 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: prog function &test8
; HSAIL: add_u32
; HSAIL: add_u32
; HSAIL: add_u32
; HSAIL: add_u32
; HSAIL: add_u32
; HSAIL: add_u32
; HSAIL: add_u32
; HSAIL: add_u32
define void @test8(<8 x i32> addrspace(1)* %out, <8 x i32> %a, <8 x i32> %b) {
entry:
  %0 = add <8 x i32> %a, %b
  store <8 x i32> %0, <8 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: prog function &test16
; HSAIL: add_u32
; HSAIL: add_u32
; HSAIL: add_u32
; HSAIL: add_u32
; HSAIL: add_u32
; HSAIL: add_u32
; HSAIL: add_u32
; HSAIL: add_u32
; HSAIL: add_u32
; HSAIL: add_u32
; HSAIL: add_u32
; HSAIL: add_u32
; HSAIL: add_u32
; HSAIL: add_u32
; HSAIL: add_u32
; HSAIL: add_u32
define void @test16(<16 x i32> addrspace(1)* %out, <16 x i32> %a, <16 x i32> %b) {
entry:
  %0 = add <16 x i32> %a, %b
  store <16 x i32> %0, <16 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: prog function &add64
; HSAIL: add_u64
define void @add64(i64 addrspace(1)* %out, i64 %a, i64 %b) {
entry:
  %0 = add i64 %a, %b
  store i64 %0, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &add_r_i_i32
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 123;
define void @add_r_i_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %a = load i32 addrspace(1)* %in
  %result = add i32 %a, 123
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &add_r_i_i64
; HSAIL: add_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 123;
define void @add_r_i_i64(i64 addrspace(1)* %out, i64 addrspace(1)* %in) {
  %a = load i64 addrspace(1)* %in
  %result = add i64 %a, 123
  store i64 %result, i64 addrspace(1)* %out
  ret void
}
