; XFAIL: *
; RUN: opt -O3 -march=hsail-64 < %s | llc -march=hsail-64 | FileCheck %s

target triple = "hsail64-pc-unknown-amdopencl"

declare i64 @get_group_id(i32) nounwind readnone

define void @__OpenCL_non_profitable_kernel(i32 addrspace(1)* noalias %rowDelimiters, float addrspace(1)* noalias %out) nounwind {
; CHECK-LABEL: __OpenCL_non_profitable_kernel
; CHECK: {{add_u32 \$s[0-9]+, \$s[0-9]+, 5;}}
; CHECK: {{ld_global_.*_u32 .*, \[\$d[0-9]+\];}}
entry:
  %rowDelimiters.addr = alloca i32 addrspace(1)*, align 8
  %out.addr = alloca float addrspace(1)*, align 8
  %aaa = alloca i32, align 4
  %t = alloca i32, align 4
  store i32 addrspace(1)* %rowDelimiters, i32 addrspace(1)** %rowDelimiters.addr, align 8
  store float addrspace(1)* %out, float addrspace(1)** %out.addr, align 8
  %call = call i64 @get_group_id(i32 0) nounwind
  %conv = trunc i64 %call to i32
  store i32 %conv, i32* %aaa, align 4
  %tmp = load i32 addrspace(1)** %rowDelimiters.addr, align 8
  %tmp1 = load i32* %aaa, align 4
  %tmp2 = add nsw i32 %tmp1, 5
  %conv3 = sext i32 %tmp2 to i64
  %arrayidx = getelementptr i32 addrspace(1)* %tmp, i64 %conv3
  %tmp4 = load i32 addrspace(1)* %arrayidx, align 4
  store i32 %tmp4, i32* %t, align 4
  %tmp5 = load float addrspace(1)** %out.addr, align 8
  %tmp6 = load i32* %aaa, align 4
  %conv7 = sext i32 %tmp6 to i64
  %arrayidx8 = getelementptr float addrspace(1)* %tmp5, i64 %conv7
  %tmp9 = load i32* %t, align 4
  %conv10 = sitofp i32 %tmp9 to float
  store float %conv10, float addrspace(1)* %arrayidx8, align 4
  br label %return

return:                                           ; preds = %entry
  ret void
}

define void @__OpenCL_profitable_kernel(i32 addrspace(1)* noalias %rowDelimiters, float addrspace(1)* noalias %out) nounwind {
; CHECK-LABEL: __OpenCL_profitable_kernel
; CHECK: {{ld_global_.*_u32 .*, \[\$d[0-9]+\+20\];}}
; CHECK: {{ld_global_.*_u32 .*, \[\$d[0-9]+\+40\];}}
entry:
  %rowDelimiters.addr = alloca i32 addrspace(1)*, align 8
  %out.addr = alloca float addrspace(1)*, align 8
  %aaa = alloca i32, align 4
  %t = alloca i32, align 4
  %t2 = alloca i32, align 4
  store i32 addrspace(1)* %rowDelimiters, i32 addrspace(1)** %rowDelimiters.addr, align 8
  store float addrspace(1)* %out, float addrspace(1)** %out.addr, align 8
  %call = call i64 @get_group_id(i32 0) nounwind
  %conv = trunc i64 %call to i32
  store i32 %conv, i32* %aaa, align 4
  %tmp = load i32 addrspace(1)** %rowDelimiters.addr, align 8
  %tmp1 = load i32* %aaa, align 4
  %tmp2 = add nsw i32 %tmp1, 5
  %conv3 = sext i32 %tmp2 to i64
  %arrayidx = getelementptr i32 addrspace(1)* %tmp, i64 %conv3
  %tmp4 = load i32 addrspace(1)* %arrayidx, align 4
  store i32 %tmp4, i32* %t, align 4
  %tmp5 = load i32 addrspace(1)** %rowDelimiters.addr, align 8
  %tmp6 = load i32* %aaa, align 4
  %tmp7 = add nsw i32 %tmp6, 10
  %conv8 = sext i32 %tmp7 to i64
  %arrayidx9 = getelementptr i32 addrspace(1)* %tmp5, i64 %conv8
  %tmp10 = load i32 addrspace(1)* %arrayidx9, align 4
  store i32 %tmp10, i32* %t2, align 4
  %tmp11 = load float addrspace(1)** %out.addr, align 8
  %tmp12 = load i32* %aaa, align 4
  %conv13 = sext i32 %tmp12 to i64
  %arrayidx14 = getelementptr float addrspace(1)* %tmp11, i64 %conv13
  %tmp15 = load i32* %t, align 4
  %tmp16 = load i32* %t2, align 4
  %tmp17 = add nsw i32 %tmp15, %tmp16
  %conv18 = sitofp i32 %tmp17 to float
  store float %conv18, float addrspace(1)* %arrayidx14, align 4
  br label %return

return:                                           ; preds = %entry
  ret void
}
