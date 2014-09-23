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
