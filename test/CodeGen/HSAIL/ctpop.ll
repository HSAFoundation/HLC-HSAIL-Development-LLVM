; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.ctpop.i32(i32) #0
declare <2 x i32> @llvm.ctpop.v2i32(<2 x i32>) #0
declare <4 x i32> @llvm.ctpop.v4i32(<4 x i32>) #0
declare <8 x i32> @llvm.ctpop.v8i32(<8 x i32>) #0
declare <16 x i32> @llvm.ctpop.v16i32(<16 x i32>) #0

declare i64 @llvm.ctpop.i64(i64) #0
declare <2 x i64> @llvm.ctpop.v2i64(<2 x i64>) #0
declare <4 x i64> @llvm.ctpop.v4i64(<4 x i64>) #0
declare <8 x i64> @llvm.ctpop.v8i64(<8 x i64>) #0
declare <16 x i64> @llvm.ctpop.v16i64(<16 x i64>) #0

declare i32 @llvm.HSAIL.popcount.u32.b32(i32) #0

; HSAIL-LABEL: {{^}}prog function &s_ctpop_i32(
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%val];
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @s_ctpop_i32(i32 addrspace(1)* noalias %out, i32 %val) #1 {
  %ctpop = call i32 @llvm.ctpop.i32(i32 %val) #0
  store i32 %ctpop, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_ctpop_i32(
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @v_ctpop_i32(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in) #1 {
  %val = load i32 addrspace(1)* %in, align 4
  %ctpop = call i32 @llvm.ctpop.i32(i32 %val) #0
  store i32 %ctpop, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_ctpop_add_chain_i32
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in1];
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in0];
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @v_ctpop_add_chain_i32(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in0, i32 addrspace(1)* noalias %in1) #1 {
  %val0 = load i32 addrspace(1)* %in0, align 4
  %val1 = load i32 addrspace(1)* %in1, align 4
  %ctpop0 = call i32 @llvm.ctpop.i32(i32 %val0) #0
  %ctpop1 = call i32 @llvm.ctpop.i32(i32 %val1) #0
  %add = add i32 %ctpop0, %ctpop1
  store i32 %add, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_ctpop_v2i32(
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @v_ctpop_v2i32(<2 x i32> addrspace(1)* noalias %out, <2 x i32> addrspace(1)* noalias %in) #1 {
  %val = load <2 x i32> addrspace(1)* %in, align 8
  %ctpop = call <2 x i32> @llvm.ctpop.v2i32(<2 x i32> %val) #0
  store <2 x i32> %ctpop, <2 x i32> addrspace(1)* %out, align 8
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_ctpop_v4i32(
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @v_ctpop_v4i32(<4 x i32> addrspace(1)* noalias %out, <4 x i32> addrspace(1)* noalias %in) #1 {
  %val = load <4 x i32> addrspace(1)* %in, align 16
  %ctpop = call <4 x i32> @llvm.ctpop.v4i32(<4 x i32> %val) #0
  store <4 x i32> %ctpop, <4 x i32> addrspace(1)* %out, align 16
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_ctpop_v8i32(
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @v_ctpop_v8i32(<8 x i32> addrspace(1)* noalias %out, <8 x i32> addrspace(1)* noalias %in) #1 {
  %val = load <8 x i32> addrspace(1)* %in, align 32
  %ctpop = call <8 x i32> @llvm.ctpop.v8i32(<8 x i32> %val) #0
  store <8 x i32> %ctpop, <8 x i32> addrspace(1)* %out, align 32
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_ctpop_v16i32(
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @v_ctpop_v16i32(<16 x i32> addrspace(1)* noalias %out, <16 x i32> addrspace(1)* noalias %in) #1 {
  %val = load <16 x i32> addrspace(1)* %in, align 32
  %ctpop = call <16 x i32> @llvm.ctpop.v16i32(<16 x i32> %val) #0
  store <16 x i32> %ctpop, <16 x i32> addrspace(1)* %out, align 32
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_ctpop_i32_add_inline_constant(
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 4;
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @v_ctpop_i32_add_inline_constant(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in) #1 {
  %val = load i32 addrspace(1)* %in, align 4
  %ctpop = call i32 @llvm.ctpop.i32(i32 %val) #0
  %add = add i32 %ctpop, 4
  store i32 %add, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_ctpop_i32_add_inline_constant_inv(
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 4;
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @v_ctpop_i32_add_inline_constant_inv(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in) #1 {
  %val = load i32 addrspace(1)* %in, align 4
  %ctpop = call i32 @llvm.ctpop.i32(i32 %val) #0
  %add = add i32 4, %ctpop
  store i32 %add, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_ctpop_i32_add_literal(
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 99999;
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @v_ctpop_i32_add_literal(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in) #1 {
  %val = load i32 addrspace(1)* %in, align 4
  %ctpop = call i32 @llvm.ctpop.i32(i32 %val) #0
  %add = add i32 %ctpop, 99999
  store i32 %add, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_ctpop_i32_add_var(
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%const];
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @v_ctpop_i32_add_var(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, i32 %const) #1 {
  %val = load i32 addrspace(1)* %in, align 4
  %ctpop = call i32 @llvm.ctpop.i32(i32 %val) #0
  %add = add i32 %ctpop, %const
  store i32 %add, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_ctpop_i32_add_var_inv(
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%const];
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @v_ctpop_i32_add_var_inv(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, i32 %const) #1 {
  %val = load i32 addrspace(1)* %in, align 4
  %ctpop = call i32 @llvm.ctpop.i32(i32 %val) #0
  %add = add i32 %const, %ctpop
  store i32 %add, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_ctpop_i32_add_vvar_inv(
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%constptr];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: add_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @v_ctpop_i32_add_vvar_inv(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, i32 addrspace(1)* noalias %constptr) #1 {
  %val = load i32 addrspace(1)* %in, align 4
  %ctpop = call i32 @llvm.ctpop.i32(i32 %val) #0
  %gep = getelementptr i32 addrspace(1)* %constptr, i32 4
  %const = load i32 addrspace(1)* %gep, align 4
  %add = add i32 %const, %ctpop
  store i32 %add, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &ctpop_i32_in_br(
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%cond];
; HSAIL: cmp_eq_b1_s32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, 0;
; HSAIL: cbr_b1 {{\$c[0-9]+}}, @BB13_1;
; HSAIL: br @BB13_3;
; HSAIL: {{^@BB13_1:}}
; HSAIL: ld_global_align(4)_u32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}];
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: {{^@BB13_3:}}
; HSAIL: st_global_align(4)_u32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}];
define void @ctpop_i32_in_br(i32 addrspace(1)* %out, i32 addrspace(1)* %in, i32 %cond) #1 {
entry:
  %0 = icmp eq i32 %cond, 0
  br i1 %0, label %if, label %else

if:
  %1 = load i32 addrspace(1)* %in
  %2 = call i32 @llvm.ctpop.i32(i32 %1)
  br label %endif

else:
  %3 = getelementptr i32 addrspace(1)* %in, i32 1
  %4 = load i32 addrspace(1)* %3
  br label %endif

endif:
  %5 = phi i32 [%2, %if], [%4, %else]
  store i32 %5, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &s_ctpop_i64(
; HSAIL: popcount_u32_b64 [[RESULT:\$s[0-9]+]], {{\$d[0-9]+}};
; HSAIL-NOT: cvt
; HSAIL: st_global_align(4)_u32 [[RESULT]]
define void @s_ctpop_i64(i32 addrspace(1)* noalias %out, i64 %val) #1 {
  %ctpop = call i64 @llvm.ctpop.i64(i64 %val) #0
  %truncctpop = trunc i64 %ctpop to i32
  store i32 %truncctpop, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &ctpop_no_trunc_i64(
; HSAIL: popcount_u32_b64 [[POPCNT:\$s[0-9]+]], {{\$d[0-9]+}};
; HSAIL: cvt_u64_u32 [[RESULT:\$d[0-9]+]], [[POPCNT]]
; HSAIL: st_global_align(8)_u64 [[RESULT]]
define void @ctpop_no_trunc_i64(i64 addrspace(1)* noalias %out, i64 %val) #1 {
  %ctpop = call i64 @llvm.ctpop.i64(i64 %val) #0
  store i64 %ctpop, i64 addrspace(1)* %out, align 8
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_ctpop_i64(
define void @v_ctpop_i64(i32 addrspace(1)* noalias %out, i64 addrspace(1)* noalias %in) #1 {
  %val = load i64 addrspace(1)* %in, align 8
  %ctpop = call i64 @llvm.ctpop.i64(i64 %val) #0
  %truncctpop = trunc i64 %ctpop to i32
  store i32 %truncctpop, i32 addrspace(1)* %out, align 4
  ret void
}

; HSAIL-LABEL: {{^}}prog function &s_ctpop_v2i64(
define void @s_ctpop_v2i64(<2 x i32> addrspace(1)* noalias %out, <2 x i64> %val) #1 {
  %ctpop = call <2 x i64> @llvm.ctpop.v2i64(<2 x i64> %val) #0
  %truncctpop = trunc <2 x i64> %ctpop to <2 x i32>
  store <2 x i32> %truncctpop, <2 x i32> addrspace(1)* %out, align 8
  ret void
}

; HSAIL-LABEL: {{^}}prog function &s_ctpop_v4i64(
define void @s_ctpop_v4i64(<4 x i32> addrspace(1)* noalias %out, <4 x i64> %val) #1 {
  %ctpop = call <4 x i64> @llvm.ctpop.v4i64(<4 x i64> %val) #0
  %truncctpop = trunc <4 x i64> %ctpop to <4 x i32>
  store <4 x i32> %truncctpop, <4 x i32> addrspace(1)* %out, align 16
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_ctpop_v2i64(
define void @v_ctpop_v2i64(<2 x i32> addrspace(1)* noalias %out, <2 x i64> addrspace(1)* noalias %in) #1 {
  %val = load <2 x i64> addrspace(1)* %in, align 16
  %ctpop = call <2 x i64> @llvm.ctpop.v2i64(<2 x i64> %val) #0
  %truncctpop = trunc <2 x i64> %ctpop to <2 x i32>
  store <2 x i32> %truncctpop, <2 x i32> addrspace(1)* %out, align 8
  ret void
}

; HSAIL-LABEL: {{^}}prog function &v_ctpop_v4i64(
define void @v_ctpop_v4i64(<4 x i32> addrspace(1)* noalias %out, <4 x i64> addrspace(1)* noalias %in) #1 {
  %val = load <4 x i64> addrspace(1)* %in, align 32
  %ctpop = call <4 x i64> @llvm.ctpop.v4i64(<4 x i64> %val) #0
  %truncctpop = trunc <4 x i64> %ctpop to <4 x i32>
  store <4 x i32> %truncctpop, <4 x i32> addrspace(1)* %out, align 16
  ret void
}

; HSAIL-LABEL: {{^}}prog function &ctpop_i64_in_br(
define void @ctpop_i64_in_br(i64 addrspace(1)* %out, i64 addrspace(1)* %in, i64 %ctpop_arg, i32 %cond) #1 {
entry:
  %tmp0 = icmp eq i32 %cond, 0
  br i1 %tmp0, label %if, label %else

if:
  %tmp2 = call i64 @llvm.ctpop.i64(i64 %ctpop_arg)
  br label %endif

else:
  %tmp3 = getelementptr i64 addrspace(1)* %in, i32 1
  %tmp4 = load i64 addrspace(1)* %tmp3
  br label %endif

endif:
  %tmp5 = phi i64 [%tmp2, %if], [%tmp4, %else]
  store i64 %tmp5, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &legacy_hsail_popcount_i32(
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%val];
; HSAIL: popcount_u32_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @legacy_hsail_popcount_i32(i32 addrspace(1)* noalias %out, i32 %val) #1 {
  %ctpop = call i32 @llvm.HSAIL.popcount.u32.b32(i32 %val) #0
  store i32 %ctpop, i32 addrspace(1)* %out, align 4
  ret void
}

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
