; XFAIL: *
; AddrSpaceCast optimization. Segment load/store should be generated after optimization.
;
; RUN: llc -march=hsail-64 -filetype=asm -o - %s | FileCheck %s

target triple = "hsail64-pc-unknown-amdopencl"


; CHECK: ld_v2_global
; CHECK: st_v2_global
define spir_kernel void @__OpenCL_sample_test_kernel(i32 addrspace(1)* nocapture %sourceA, i32 addrspace(1)* nocapture %destValues) nounwind {
entry:
  %0 = tail call spir_func i64 @__hsail_ld_kernarg_u64(i32 0) nounwind readnone
  %1 = tail call spir_func i32 @__hsail_get_global_id(i32 0) nounwind readnone
  %2 = zext i32 %1 to i64
  %3 = add i64 %2, %0
  %sext = shl i64 %3, 32
  %4 = bitcast i32 addrspace(1)* %destValues to i32 addrspace(4)*
  %5 = bitcast i32 addrspace(1)* %sourceA to i32 addrspace(4)*
  %6 = ashr exact i64 %sext, 31
  %7 = getelementptr inbounds i32 addrspace(4)* %5, i64 %6
  %arrayidx_v4 = bitcast i32 addrspace(4)* %7 to <2 x i32> addrspace(4)*
  %vecload = load <2 x i32> addrspace(4)* %arrayidx_v4, align 4
  %8 = extractelement <2 x i32> %vecload, i32 0
  %9 = extractelement <2 x i32> %vecload, i32 1
  %10 = tail call spir_func i32 @__hsail_lastbit_u32(i32 %8) nounwind readonly
  %11 = icmp eq i32 %8, 0
  %12 = select i1 %11, i32 32, i32 %10
  %13 = tail call spir_func i32 @__hsail_lastbit_u32(i32 %9) nounwind readonly
  %14 = icmp eq i32 %9, 0
  %15 = select i1 %14, i32 32, i32 %13
  %16 = getelementptr inbounds i32 addrspace(4)* %4, i64 %6
  %17 = insertelement <2 x i32> undef, i32 %12, i32 0
  %18 = insertelement <2 x i32> %17, i32 %15, i32 1
  %arrayidx_v41 = bitcast i32 addrspace(4)* %16 to <2 x i32> addrspace(4)*
  store <2 x i32> %18, <2 x i32> addrspace(4)* %arrayidx_v41, align 4
  ret void
}

declare spir_func i32 @__hsail_lastbit_u32(i32) nounwind readonly

declare spir_func i64 @__hsail_ld_kernarg_u64(i32) nounwind readnone

declare spir_func i32 @__hsail_get_global_id(i32) nounwind readnone

!opencl.kernels = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!6}
!opencl.ocl.version = !{!7}
!opencl.used.extensions = !{!8}
!opencl.used.optional.core.features = !{!8}
!opencl.compiler.options = !{!8}

!0 = metadata !{void (i32 addrspace(1)*, i32 addrspace(1)*)* @__OpenCL_sample_test_kernel, metadata !1, metadata !2, metadata !3, metadata !4, metadata !5}
!1 = metadata !{metadata !"kernel_arg_addr_space", i32 1, i32 1}
!2 = metadata !{metadata !"kernel_arg_access_qual", metadata !"none", metadata !"none"}
!3 = metadata !{metadata !"kernel_arg_type", metadata !"int*", metadata !"int*"}
!4 = metadata !{metadata !"kernel_arg_type_qual", metadata !"", metadata !""}
!5 = metadata !{metadata !"kernel_arg_base_type", metadata !"int*", metadata !"int*"}
!6 = metadata !{i32 1, i32 2}
!7 = metadata !{i32 2, i32 0}
!8 = metadata !{}
