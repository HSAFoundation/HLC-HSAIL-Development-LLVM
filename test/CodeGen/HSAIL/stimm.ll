; XFAIL: *
; Check that immediate stores are possible, fp immediate stores are possible, and vector stores can mix immediates and registers
; RUN: llc < %s -march=hsail | FileCheck %s

define void @__OpenCL_v4doubleimm_kernel(i32 %global_offset_0, i32 %global_offset_1, i32 %global_offset_2, <4 x double> addrspace(1)* nocapture %out) nounwind {
; CHECK-LABEL: {{^}}prog kernel &__OpenCL_v4doubleimm_kernel(
; CHECK: (0, 4607182418800017408, 4613937818241073152, 4616189618054758400)
entry:
  store <4 x double> <double 0.000000e+00, double 1.000000e+00, double 3.000000e+00, double 4.000000e+00>, <4 x double> addrspace(1)* %out, align 32
  ret void
}

define void @__OpenCL_v4imm_kernel(i32 %global_offset_0, i32 %global_offset_1, i32 %global_offset_2, <4 x i32> addrspace(1)* nocapture %out) nounwind {
; CHECK-LABEL: {{^}}prog kernel &__OpenCL_v4imm_kernel(
; CHECK: (0, 1, 3, 4)
entry:
  store <4 x i32> <i32 0, i32 1, i32 3, i32 4>, <4 x i32> addrspace(1)* %out, align 16
  ret void
}

define void @__OpenCL_v4mix_kernel(i32 %global_offset_0, i32 %global_offset_1, i32 %global_offset_2, <4 x i32> addrspace(3)* nocapture %out, i32 %x) nounwind {
; CHECK-LABEL: {{^}}prog kernel &__OpenCL_v4mix_kernel(
; CHECK: {{\(0, 1, \$s[0-9]+, 4\)}}
entry:
  %tmp4 = insertelement <4 x i32> <i32 0, i32 1, i32 undef, i32 4>, i32 %x, i32 2
  store <4 x i32> %tmp4, <4 x i32> addrspace(3)* %out, align 16
  ret void
}

define void @__OpenCL_trap_kernel(i64 %global_offset_0, i64 %global_offset_1, i64 %global_offset_2, i32 addrspace(1)* nocapture %pVal) nounwind {
; CHECK-LABEL: trap
; CHECK: {{\(42, \$s[0-9]+\)}}
entry:
  %arrayidx2 = getelementptr i32, i32 addrspace(1)* %pVal, i64 1
  %tmp5 = load i32, i32 addrspace(1)* %arrayidx2, align 4
  %conv = sext i32 %tmp5 to i64
  %tmp6 = udiv i64 %conv, 13
  %conv7 = trunc i64 %tmp6 to i32
  %0 = insertelement <2 x i32> <i32 42, i32 undef>, i32 %conv7, i32 1
  %arrayidx_v4 = bitcast i32 addrspace(1)* %pVal to <2 x i32> addrspace(1)*
  store <2 x i32> %0, <2 x i32> addrspace(1)* %arrayidx_v4, align 4
  ret void
}
