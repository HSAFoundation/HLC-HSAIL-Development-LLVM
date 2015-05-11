; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

declare i32 @llvm.HSAIL.workitemid.flat() #0

@lds_global =  addrspace(3) global [128 x i32] undef, align 4

; FUNC-LABEL: {{^}}prog function &directly_load_arg
; HSAIL: ld_arg_align(4)_u32 [[ADDRREG:\$s[0-9]]], [%in];
; HSAIL: ld_global_align(4)_u32 [[REG:\$s[0-9]]], {{\[}}[[ADDRREG]]{{\]}};
; HSAIL: add_u32 {{\$s[0-9]+}}, [[REG]], [[REG]];
; HSAIL: ret;
define void @directly_load_arg(i32 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %a = load i32, i32 addrspace(1)* %in
  %result = add i32 %a, %a
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &positive_imm_offset_arg
; HSAIL: ld_arg_align(4)_u32 [[ADDRREG:\$s[0-9]]], [%in];
; HSAIL: ld_global_align(4)_u32 [[REG:\$s[0-9]]], {{\[}}[[ADDRREG]]+28{{\]}};
; HSAIL: add_u32 {{\$s[0-9]+}}, [[REG]], [[REG]];
; HSAIL: ret;
define void @positive_imm_offset_arg(i32 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %gep = getelementptr i32, i32 addrspace(1)* %in, i32 7
  %a = load i32, i32 addrspace(1)* %gep
  %result = add i32 %a, %a
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &negative_imm_offset_arg
; HSAIL: ld_arg_align(4)_u32 [[ADDRREG:\$s[0-9]]], [%in];
; HSAIL: ld_global_align(4)_u32 [[REG:\$s[0-9]]], {{\[}}[[ADDRREG]]-36{{\]}};
; HSAIL: add_u32 {{\$s[0-9]+}}, [[REG]], [[REG]];
; HSAIL: ret;
define void @negative_imm_offset_arg(i32 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %gep = getelementptr i32, i32 addrspace(1)* %in, i32 -9
  %a = load i32, i32 addrspace(1)* %gep
  %result = add i32 %a, %a
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &directly_load_kernarg
; HSAIL: ld_kernarg_align(4)_width(all)_u32 [[KERNARG:\$s[0-9]]], [%in];
; HSAIL: ld_global_align(4)_u32 [[REG:\$s[0-9]]], {{\[}}[[KERNARG]]{{\]}};
; HSAIL: add_u32 {{\$s[0-9]+}}, [[REG]], [[REG]];
define spir_kernel void @directly_load_kernarg(i32 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %a = load i32, i32 addrspace(1)* %in
  %result = add i32 %a, %a
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &positive_imm_offset_kernarg
; HSAIL: ld_kernarg_align(4)_width(all)_u32 [[KERNARG:\$s[0-9]]], [%in];
; HSAIL: ld_global_align(4)_u32 [[REG:\$s[0-9]]], {{\[}}[[KERNARG]]+28{{\]}};
; HSAIL: add_u32 {{\$s[0-9]+}}, [[REG]], [[REG]];
define spir_kernel void @positive_imm_offset_kernarg(i32 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %gep = getelementptr i32, i32 addrspace(1)* %in, i32 7
  %a = load i32, i32 addrspace(1)* %gep
  %result = add i32 %a, %a
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog kernel &negative_imm_offset_kernarg
; HSAIL: ld_kernarg_align(4)_width(all)_u32 [[KERNARG:\$s[0-9]]], [%in];
; HSAIL: ld_global_align(4)_u32 [[REG:\$s[0-9]]], {{\[}}[[KERNARG]]-36{{\]}};
; HSAIL: add_u32 {{\$s[0-9]+}}, [[REG]], [[REG]];
define spir_kernel void @negative_imm_offset_kernarg(i32 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %gep = getelementptr i32, i32 addrspace(1)* %in, i32 -9
  %a = load i32, i32 addrspace(1)* %gep
  %result = add i32 %a, %a
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &directly_load_global
; HSAIL: group_u32 %lds_global[128];
; HSAIL: ld_group_align(4)_u32 [[REG:\$s[0-9]]], [%lds_global];
; HSAIL: add_u32 {{\$s[0-9]+}}, [[REG]], [[REG]];
define void @directly_load_global(i32 addrspace(1)* %out) {
  %a = load i32, i32 addrspace(3)* getelementptr inbounds ([128 x i32], [128 x i32] addrspace(3)* @lds_global, i32 0, i32 0)
  %result = add i32 %a, %a
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &positive_imm_offset_global
; HSAIL: group_u32 %lds_global[128];
; HSAIL: ld_group_align(4)_u32 [[REG:\$s[0-9]]], [%lds_global][28];
; HSAIL: add_u32 {{\$s[0-9]+}}, [[REG]], [[REG]];
define void @positive_imm_offset_global(i32 addrspace(1)* %out) {
  %a = load i32, i32 addrspace(3)* getelementptr inbounds ([128 x i32], [128 x i32] addrspace(3)* @lds_global, i32 0, i32 7)
  %result = add i32 %a, %a
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &negative_imm_offset_global
; HSAIL: group_u32 %lds_global[128];
; HSAIL: lda_group_u32 [[REG:\$s[0-9]]], [%lds_global][-36];
; HSAIL: st_global_align(4)_u32 [[REG]],
define void @negative_imm_offset_global(i32 addrspace(3)* addrspace(1)* %out) {
  %gep = getelementptr inbounds [128 x i32], [128 x i32] addrspace(3)* @lds_global, i32 0, i32 -9
  store i32 addrspace(3)* %gep, i32 addrspace(3)* addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &reg_offset_global
; HSAIL: group_u32 %lds_global[128];
; HSAIL: workitemflatid_u32	[[TID:\$s[0-9]+]];
; HSAIL: ld_group_align(4)_u32 [[REG:\$s[0-9]]], [%lds_global]{{\[}}[[TID]]{{\]}};
; HSAIL: add_u32 {{\$s[0-9]+}}, [[REG]], [[REG]];
define void @reg_offset_global(i32 addrspace(1)* %out) {
  %tid = call i32 @llvm.HSAIL.workitemid.flat() #0
  %gep = getelementptr [128 x i32], [128 x i32] addrspace(3)* @lds_global, i32 0, i32 %tid
  %a = load i32, i32 addrspace(3)* %gep
  %result = add i32 %a, %a
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &reg_offset_positive_offset_global
; HSAIL: group_u32 %lds_global[128];
; HSAIL: workitemflatid_u32	[[TID:\$s[0-9]+]];
; HSAIL: ld_group_align(4)_u32 [[REG:\$s[0-9]]], [%lds_global]{{\[}}[[TID]]+48];
; HSAIL: add_u32 {{\$s[0-9]+}}, [[REG]], [[REG]];
define void @reg_offset_positive_offset_global(i32 addrspace(1)* %out) {
  %tid = call i32 @llvm.HSAIL.workitemid.flat() #0
  %tid_offset = add i32 %tid, 12
  %gep = getelementptr [128 x i32], [128 x i32] addrspace(3)* @lds_global, i32 0, i32 %tid_offset
  %a = load i32, i32 addrspace(3)* %gep
  %result = add i32 %a, %a
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &reg_offset_negative_offset_global
; HSAIL: group_u32 %lds_global[128];
; HSAIL: workitemflatid_u32	[[TID:\$s[0-9]+]];
; HSAIL: ld_group_align(4)_u32 [[REG:\$s[0-9]]], [%lds_global]{{\[}}[[TID]]-60];
; HSAIL: add_u32 {{\$s[0-9]+}}, [[REG]], [[REG]];
define void @reg_offset_negative_offset_global(i32 addrspace(1)* %out) {
  %tid = call i32 @llvm.HSAIL.workitemid.flat() #0
  %tid_offset = add i32 %tid, -15
  %gep = getelementptr [128 x i32], [128 x i32] addrspace(3)* @lds_global, i32 0, i32 %tid_offset
  %a = load i32, i32 addrspace(3)* %gep
  %result = add i32 %a, %a
  store i32 %result, i32 addrspace(1)* %out
  ret void
}

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
