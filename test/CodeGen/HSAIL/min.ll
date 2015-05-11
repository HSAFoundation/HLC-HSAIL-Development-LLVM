; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.HSAIL.get.global.id(i32) #0

; HSAIL-LABEL: {{^}}prog function &v_test_imin_sle_i32(
; HSAIL: min_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @v_test_imin_sle_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %aptr, i32 addrspace(1)* %bptr) #1 {
  %tid = call i32 @llvm.HSAIL.get.global.id(i32 0) #0
  %gep0 = getelementptr i32, i32 addrspace(1)* %aptr, i32 %tid
  %gep1 = getelementptr i32, i32 addrspace(1)* %bptr, i32 %tid
  %outgep = getelementptr i32, i32 addrspace(1)* %out, i32 %tid
  %a = load i32, i32 addrspace(1)* %gep0, align 4
  %b = load i32, i32 addrspace(1)* %gep1, align 4
  %cmp = icmp sle i32 %a, %b
  %val = select i1 %cmp, i32 %a, i32 %b
  store i32 %val, i32 addrspace(1)* %outgep, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &s_test_imin_sle_i32(
; HSAIL-DAG: ld_arg_align(4)_u32 [[A:\$s[0-9]+]], [%a];
; HSAIL-DAG: ld_arg_align(4)_u32 [[B:\$s[0-9]+]], [%b];
; HSAIL: min_s32 {{\$s[0-9]+}}, [[A]], [[B]];
define void @s_test_imin_sle_i32(i32 addrspace(1)* %out, i32 %a, i32 %b) #1 {
  %cmp = icmp sle i32 %a, %b
  %val = select i1 %cmp, i32 %a, i32 %b
  store i32 %val, i32 addrspace(1)* %out, align 4
  ret void
}

; FIXME: This is broken because of canonicaliztion of the le
; comparision with a constant.

; HSAIL-LABEL: {{^}}prog function &test_imin_imm_sle_i32(
; HSAIL: cmp_lt_b1_s32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, 9;
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, {{\$s[0-9]+}}, 8;
; XHSAIL: ld_arg_align(4)_u32 [[A:\$s[0-9]+]], [%a];
; XHSAIL: min_s32 {{\$s[0-9]+}}, [[A]], 8;
define void @test_imin_imm_sle_i32(i32 addrspace(1)* %out, i32 %a) #1 {
  %cmp = icmp sle i32 %a, 8
  %val = select i1 %cmp, i32 %a, i32 8
  store i32 %val, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_imin_imm_slt_i32(
; HSAIL: ld_arg_align(4)_u32 [[A:\$s[0-9]+]], [%a];
; HSAIL: min_s32 {{\$s[0-9]+}}, [[A]], 8;
define void @test_imin_imm_slt_i32(i32 addrspace(1)* %out, i32 %a) #1 {
  %cmp = icmp slt i32 %a, 8
  %val = select i1 %cmp, i32 %a, i32 8
  store i32 %val, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_test_imin_slt_i32(
; HSAIL: min_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @v_test_imin_slt_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %aptr, i32 addrspace(1)* %bptr) #1 {
  %tid = call i32 @llvm.HSAIL.get.global.id(i32 0) #0
  %gep0 = getelementptr i32, i32 addrspace(1)* %aptr, i32 %tid
  %gep1 = getelementptr i32, i32 addrspace(1)* %bptr, i32 %tid
  %outgep = getelementptr i32, i32 addrspace(1)* %out, i32 %tid
  %a = load i32, i32 addrspace(1)* %gep0, align 4
  %b = load i32, i32 addrspace(1)* %gep1, align 4
  %cmp = icmp slt i32 %a, %b
  %val = select i1 %cmp, i32 %a, i32 %b
  store i32 %val, i32 addrspace(1)* %outgep, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &s_test_imin_slt_i32(
; HSAIL-DAG: ld_arg_align(4)_u32 [[A:\$s[0-9]+]], [%a];
; HSAIL-DAG: ld_arg_align(4)_u32 [[B:\$s[0-9]+]], [%b];
; HSAIL: min_s32 {{\$s[0-9]+}}, [[A]], [[B]];
define void @s_test_imin_slt_i32(i32 addrspace(1)* %out, i32 %a, i32 %b) #1 {
  %cmp = icmp slt i32 %a, %b
  %val = select i1 %cmp, i32 %a, i32 %b
  store i32 %val, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_test_umin_ule_i32(
; HSAIL: min_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @v_test_umin_ule_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %aptr, i32 addrspace(1)* %bptr) #1 {
  %tid = call i32 @llvm.HSAIL.get.global.id(i32 0) #0
  %gep0 = getelementptr i32, i32 addrspace(1)* %aptr, i32 %tid
  %gep1 = getelementptr i32, i32 addrspace(1)* %bptr, i32 %tid
  %outgep = getelementptr i32, i32 addrspace(1)* %out, i32 %tid
  %a = load i32, i32 addrspace(1)* %gep0, align 4
  %b = load i32, i32 addrspace(1)* %gep1, align 4
  %cmp = icmp ule i32 %a, %b
  %val = select i1 %cmp, i32 %a, i32 %b
  store i32 %val, i32 addrspace(1)* %outgep, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &s_test_umin_ule_i32(
; HSAIL: min_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @s_test_umin_ule_i32(i32 addrspace(1)* %out, i32 %a, i32 %b) #1 {
  %cmp = icmp ule i32 %a, %b
  %val = select i1 %cmp, i32 %a, i32 %b
  store i32 %val, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_test_umin_ult_i32(
; HSAIL: min_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @v_test_umin_ult_i32(i32 addrspace(1)* %out, i32 addrspace(1)* %aptr, i32 addrspace(1)* %bptr) #1 {
  %tid = call i32 @llvm.HSAIL.get.global.id(i32 0) #0
  %gep0 = getelementptr i32, i32 addrspace(1)* %aptr, i32 %tid
  %gep1 = getelementptr i32, i32 addrspace(1)* %bptr, i32 %tid
  %outgep = getelementptr i32, i32 addrspace(1)* %out, i32 %tid
  %a = load i32, i32 addrspace(1)* %gep0, align 4
  %b = load i32, i32 addrspace(1)* %gep1, align 4
  %cmp = icmp ult i32 %a, %b
  %val = select i1 %cmp, i32 %a, i32 %b
  store i32 %val, i32 addrspace(1)* %outgep, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &s_test_umin_ult_i32(
; HSAIL: min_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @s_test_umin_ult_i32(i32 addrspace(1)* %out, i32 %a, i32 %b) #1 {
  %cmp = icmp ult i32 %a, %b
  %val = select i1 %cmp, i32 %a, i32 %b
  store i32 %val, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_test_umin_ult_i32_multi_use(
; HSAIL-NOT: min_u32
; HSAIL: cmp
; HSAIL-NEXT: cmov
; HSAIL-NOT: min_u32
; HSAIL: ret;
define void @v_test_umin_ult_i32_multi_use(i32 addrspace(1)* %out0, i1 addrspace(1)* %out1, i32 addrspace(1)* %aptr, i32 addrspace(1)* %bptr) #1 {
  %tid = call i32 @llvm.HSAIL.get.global.id(i32 0) #0
  %gep0 = getelementptr i32, i32 addrspace(1)* %aptr, i32 %tid
  %gep1 = getelementptr i32, i32 addrspace(1)* %bptr, i32 %tid
  %outgep0 = getelementptr i32, i32 addrspace(1)* %out0, i32 %tid
  %outgep1 = getelementptr i1, i1 addrspace(1)* %out1, i32 %tid
  %a = load i32, i32 addrspace(1)* %gep0, align 4
  %b = load i32, i32 addrspace(1)* %gep1, align 4
  %cmp = icmp ult i32 %a, %b
  %val = select i1 %cmp, i32 %a, i32 %b
  store i32 %val, i32 addrspace(1)* %outgep0, align 4
  store i1 %cmp, i1 addrspace(1)* %outgep1
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_test_imin_sle_i64(
; HSAIL: min_s64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @v_test_imin_sle_i64(i64 addrspace(1)* %out, i64 addrspace(1)* %aptr, i64 addrspace(1)* %bptr) #1 {
  %tid = call i32 @llvm.HSAIL.get.global.id(i32 0) #0
  %gep0 = getelementptr i64, i64 addrspace(1)* %aptr, i32 %tid
  %gep1 = getelementptr i64, i64 addrspace(1)* %bptr, i32 %tid
  %outgep = getelementptr i64, i64 addrspace(1)* %out, i32 %tid
  %a = load i64, i64 addrspace(1)* %gep0
  %b = load i64, i64 addrspace(1)* %gep1
  %cmp = icmp sle i64 %a, %b
  %val = select i1 %cmp, i64 %a, i64 %b
  store i64 %val, i64 addrspace(1)* %outgep
  ret void
}

; HSAIL-LABEL: {{^}}prog function &s_test_imin_sle_i64(
; HSAIL-DAG: ld_arg_align(8)_u64 [[A:\$d[0-9]+]], [%a];
; HSAIL-DAG: ld_arg_align(8)_u64 [[B:\$d[0-9]+]], [%b];
; HSAIL: min_s64 {{\$d[0-9]+}}, [[A]], [[B]];
define void @s_test_imin_sle_i64(i64 addrspace(1)* %out, i64 %a, i64 %b) #1 {
  %cmp = icmp sle i64 %a, %b
  %val = select i1 %cmp, i64 %a, i64 %b
  store i64 %val, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_test_imin_slt_i64(
; HSAIL: min_s64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @v_test_imin_slt_i64(i64 addrspace(1)* %out, i64 addrspace(1)* %aptr, i64 addrspace(1)* %bptr) #1 {
  %tid = call i32 @llvm.HSAIL.get.global.id(i32 0) #0
  %gep0 = getelementptr i64, i64 addrspace(1)* %aptr, i32 %tid
  %gep1 = getelementptr i64, i64 addrspace(1)* %bptr, i32 %tid
  %outgep = getelementptr i64, i64 addrspace(1)* %out, i32 %tid
  %a = load i64, i64 addrspace(1)* %gep0
  %b = load i64, i64 addrspace(1)* %gep1
  %cmp = icmp slt i64 %a, %b
  %val = select i1 %cmp, i64 %a, i64 %b
  store i64 %val, i64 addrspace(1)* %outgep
  ret void
}

; HSAIL-LABEL: {{^}}prog function &s_test_imin_slt_i64(
; HSAIL-DAG: ld_arg_align(8)_u64 [[A:\$d[0-9]+]], [%a];
; HSAIL-DAG: ld_arg_align(8)_u64 [[B:\$d[0-9]+]], [%b];
; HSAIL: min_s64 {{\$d[0-9]+}}, [[A]], [[B]];
define void @s_test_imin_slt_i64(i64 addrspace(1)* %out, i64 %a, i64 %b) #1 {
  %cmp = icmp slt i64 %a, %b
  %val = select i1 %cmp, i64 %a, i64 %b
  store i64 %val, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_test_umin_ule_i64(
; HSAIL: min_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @v_test_umin_ule_i64(i64 addrspace(1)* %out, i64 addrspace(1)* %aptr, i64 addrspace(1)* %bptr) #1 {
  %tid = call i32 @llvm.HSAIL.get.global.id(i32 0) #0
  %gep0 = getelementptr i64, i64 addrspace(1)* %aptr, i32 %tid
  %gep1 = getelementptr i64, i64 addrspace(1)* %bptr, i32 %tid
  %outgep = getelementptr i64, i64 addrspace(1)* %out, i32 %tid
  %a = load i64, i64 addrspace(1)* %gep0
  %b = load i64, i64 addrspace(1)* %gep1
  %cmp = icmp ule i64 %a, %b
  %val = select i1 %cmp, i64 %a, i64 %b
  store i64 %val, i64 addrspace(1)* %outgep
  ret void
}

; HSAIL-LABEL: {{^}}prog function &s_test_umin_ule_i64(
; HSAIL: min_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @s_test_umin_ule_i64(i64 addrspace(1)* %out, i64 %a, i64 %b) #1 {
  %cmp = icmp ule i64 %a, %b
  %val = select i1 %cmp, i64 %a, i64 %b
  store i64 %val, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_test_umin_ult_i64(
; HSAIL: min_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @v_test_umin_ult_i64(i64 addrspace(1)* %out, i64 addrspace(1)* %aptr, i64 addrspace(1)* %bptr) #1 {
  %tid = call i32 @llvm.HSAIL.get.global.id(i32 0) #0
  %gep0 = getelementptr i64, i64 addrspace(1)* %aptr, i32 %tid
  %gep1 = getelementptr i64, i64 addrspace(1)* %bptr, i32 %tid
  %outgep = getelementptr i64, i64 addrspace(1)* %out, i32 %tid
  %a = load i64, i64 addrspace(1)* %gep0
  %b = load i64, i64 addrspace(1)* %gep1
  %cmp = icmp ult i64 %a, %b
  %val = select i1 %cmp, i64 %a, i64 %b
  store i64 %val, i64 addrspace(1)* %outgep
  ret void
}

; HSAIL-LABEL: {{^}}prog function &s_test_umin_ult_i64(
; HSAIL: min_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @s_test_umin_ult_i64(i64 addrspace(1)* %out, i64 %a, i64 %b) #1 {
  %cmp = icmp ult i64 %a, %b
  %val = select i1 %cmp, i64 %a, i64 %b
  store i64 %val, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_test_umin_ult_i64_multi_use(
; HSAIL-NOT: min_u64
; HSAIL: cmp
; HSAIL-NEXT: cmov
; HSAIL-NOT: min_u64
; HSAIL: ret;
define void @v_test_umin_ult_i64_multi_use(i64 addrspace(1)* %out0, i1 addrspace(1)* %out1, i64 addrspace(1)* %aptr, i64 addrspace(1)* %bptr) #1 {
  %tid = call i32 @llvm.HSAIL.get.global.id(i32 0) #0
  %gep0 = getelementptr i64, i64 addrspace(1)* %aptr, i32 %tid
  %gep1 = getelementptr i64, i64 addrspace(1)* %bptr, i32 %tid
  %outgep0 = getelementptr i64, i64 addrspace(1)* %out0, i32 %tid
  %outgep1 = getelementptr i1, i1 addrspace(1)* %out1, i32 %tid
  %a = load i64, i64 addrspace(1)* %gep0
  %b = load i64, i64 addrspace(1)* %gep1
  %cmp = icmp ult i64 %a, %b
  %val = select i1 %cmp, i64 %a, i64 %b
  store i64 %val, i64 addrspace(1)* %outgep0
  store i1 %cmp, i1 addrspace(1)* %outgep1
  ret void
}

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
