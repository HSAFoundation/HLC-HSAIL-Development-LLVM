; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL32 -check-prefix=HSAIL %s
; RUN: llc -march=hsail64 < %s | FileCheck -check-prefix=HSAIL64 -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &test_kernarg_u32(
; HSAIL32: kernargbaseptr_u32 [[PTR:\$s[0-9]+]];
; HSAIL32: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, {{\[}}[[PTR]]{{\]}};

; HSAIL64: kernargbaseptr_u64 [[PTR:\$d[0-9]+]];
; HSAIL64: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, {{\[}}[[PTR]]{{\]}};
define i32 @test_kernarg_u32() #1 {
  %tmp0 = call i32 @llvm.HSAIL.ld.kernarg.u32(i32 0) #0
  ret i32 %tmp0
}

; HSAIL-LABEL: {{^}}prog function &test_kernarg_u64(
; HSAIL32: kernargbaseptr_u32 [[PTR:\$s[0-9]+]];
; HSAIL32: ld_kernarg_align(8)_width(all)_u64 {{\$d[0-9]+}}, {{\[}}[[PTR]]{{\]}};

; HSAIL64: kernargbaseptr_u64 [[PTR:\$d[0-9]+]];
; HSAIL64: ld_kernarg_align(8)_width(all)_u64 {{\$d[0-9]+}}, {{\[}}[[PTR]]{{\]}};
define i64 @test_kernarg_u64() #1 {
  %tmp0 = call i64 @llvm.HSAIL.ld.kernarg.u64(i32 0) #0
  ret i64 %tmp0
}

; HSAIL-LABEL: {{^}}prog function &test_kernarg_u32_offset(
; HSAIL32: kernargbaseptr_u32 [[PTR:\$s[0-9]+]];
; HSAIL32: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, {{\[}}[[PTR]]+16];

; HSAIL64: kernargbaseptr_u64 [[PTR:\$d[0-9]+]];
; HSAIL64: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, {{\[}}[[PTR]]+16];
define i32 @test_kernarg_u32_offset() #1 {
  %tmp0 = call i32 @llvm.HSAIL.ld.kernarg.u32(i32 16) #0
  ret i32 %tmp0
}

; HSAIL-LABEL: {{^}}prog function &test_kernarg_u64_offset(
; HSAIL32: kernargbaseptr_u32 [[PTR:\$s[0-9]+]];
; HSAIL32: ld_kernarg_align(8)_width(all)_u64 {{\$d[0-9]+}}, {{\[}}[[PTR]]+32];

; HSAIL64: kernargbaseptr_u64 [[PTR:\$d[0-9]+]];
; HSAIL64: ld_kernarg_align(8)_width(all)_u64 {{\$d[0-9]+}}, {{\[}}[[PTR]]+32];
define i64 @test_kernarg_u64_offset() #1 {
  %tmp0 = call i64 @llvm.HSAIL.ld.kernarg.u64(i32 32) #0
  ret i64 %tmp0
}

; XHSAIL-LABEL: {{^}}prog function &test_kernarg_u32_dynamic_offset(
; XHSAIL32: kernargbaseptr_u32 [[PTR:\$s[0-9]+]];
; XHSAIL32: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, {{\[}}[[PTR]]+16];

; XHSAIL64: kernargbaseptr_u64 [[PTR:\$d[0-9]+]];
; XHSAIL64: ld_kernarg_align(4)_width(all)_u32 {{\$s[0-9]+}}, {{\[}}[[PTR]]+16];
; define i32 @test_kernarg_u32_dynamic_offset(i32 %off) #1 {
;   %tmp0 = call i32 @llvm.HSAIL.ld.kernarg.u32(i32 %off) #0
;   ret i32 %tmp0
; }

; XHSAIL-LABEL: {{^}}prog function &test_kernarg_u64_dynamic_offset(
; XHSAIL32: kernargbaseptr_u32 [[PTR:\$s[0-9]+]];
; XHSAIL32: ld_kernarg_align(8)_width(all)_u64 {{\$d[0-9]+}}, {{\[}}[[PTR]]+32];

; XHSAIL64: kernargbaseptr_u64 [[PTR:\$d[0-9]+]];
; XHSAIL64: ld_kernarg_align(8)_width(all)_u64 {{\$d[0-9]+}}, {{\[}}[[PTR]]+32];
; define i64 @test_kernarg_u64_dynamic_offset(i32 %off) #1 {
;   %tmp0 = call i64 @llvm.HSAIL.ld.kernarg.u64(i32 %off) #0
;   ret i64 %tmp0
; }

declare i32 @llvm.HSAIL.ld.kernarg.u32(i32) #0
declare i64 @llvm.HSAIL.ld.kernarg.u64(i32) #0

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
