; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &setcc_v2i32
; HSAIL: cmp_eq_b1_s32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
; HSAIL: cmp_eq_b1_s32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
define void @setcc_v2i32(<2 x i32> addrspace(1)* %out, <2 x i32> %a, <2 x i32> %b) {
  %result = icmp eq <2 x i32> %a, %b
  %sext = sext <2 x i1> %result to <2 x i32>
  store <2 x i32> %sext, <2 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &setcc_v4i32
; HSAIL: cmp_eq_b1_s32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
; HSAIL: cmp_eq_b1_s32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
; HSAIL: cmp_eq_b1_s32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
; HSAIL: cmp_eq_b1_s32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
define void @setcc_v4i32(<4 x i32> addrspace(1)* %out, <4 x i32> addrspace(1)* %in) {
  %b_ptr = getelementptr <4 x i32> addrspace(1)* %in, i32 1
  %a = load <4 x i32> addrspace(1) * %in
  %b = load <4 x i32> addrspace(1) * %b_ptr
  %result = icmp eq <4 x i32> %a, %b
  %sext = sext <4 x i1> %result to <4 x i32>
  store <4 x i32> %sext, <4 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &f32_oeq
; HSAIL: cmp_eq_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
define void @f32_oeq(i32 addrspace(1)* %out, float %a, float %b) {
  %tmp0 = fcmp oeq float %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &f32_ogt
; HSAIL: cmp_gt_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
define void @f32_ogt(i32 addrspace(1)* %out, float %a, float %b) {
  %tmp0 = fcmp ogt float %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &f32_oge
; HSAIL: cmp_ge_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
define void @f32_oge(i32 addrspace(1)* %out, float %a, float %b) {
  %tmp0 = fcmp oge float %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &f32_olt
; HSAIL: cmp_lt_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
define void @f32_olt(i32 addrspace(1)* %out, float %a, float %b) {
  %tmp0 = fcmp olt float %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &f32_ole
; HSAIL: cmp_le_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
define void @f32_ole(i32 addrspace(1)* %out, float %a, float %b) {
  %tmp0 = fcmp ole float %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &f32_one
; HSAIL: cmp_ne_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
define void @f32_one(i32 addrspace(1)* %out, float %a, float %b) {
  %tmp0 = fcmp one float %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &f32_ord
; HSAIL: cmp_num_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
define void @f32_ord(i32 addrspace(1)* %out, float %a, float %b) {
  %tmp0 = fcmp ord float %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &f32_ueq
; HSAIL: cmp_equ_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;


define void @f32_ueq(i32 addrspace(1)* %out, float %a, float %b) {
  %tmp0 = fcmp ueq float %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &f32_ugt
; HSAIL: cmp_gtu_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;

define void @f32_ugt(i32 addrspace(1)* %out, float %a, float %b) {
  %tmp0 = fcmp ugt float %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &f32_uge
; HSAIL: cmp_geu_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;

define void @f32_uge(i32 addrspace(1)* %out, float %a, float %b) {
  %tmp0 = fcmp uge float %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &f32_ult
; HSAIL: cmp_ltu_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
define void @f32_ult(i32 addrspace(1)* %out, float %a, float %b) {
  %tmp0 = fcmp ult float %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &f32_ule
; HSAIL: cmp_leu_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;

define void @f32_ule(i32 addrspace(1)* %out, float %a, float %b) {
  %tmp0 = fcmp ule float %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &f32_une
; HSAIL: cmp_neu_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;

define void @f32_une(i32 addrspace(1)* %out, float %a, float %b) {
  %tmp0 = fcmp une float %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &f32_uno
; HSAIL: cmp_nan_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;

define void @f32_uno(i32 addrspace(1)* %out, float %a, float %b) {
  %tmp0 = fcmp uno float %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &i32_eq
; HSAIL: cmp_eq_b1_s32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
define void @i32_eq(i32 addrspace(1)* %out, i32 %a, i32 %b) {
  %tmp0 = icmp eq i32 %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &i32_ne
; HSAIL: cmp_ne_b1_s32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
define void @i32_ne(i32 addrspace(1)* %out, i32 %a, i32 %b) {
  %tmp0 = icmp ne i32 %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &i32_ugt
; HSAIL: cmp_gt_b1_u32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
define void @i32_ugt(i32 addrspace(1)* %out, i32 %a, i32 %b) {
  %tmp0 = icmp ugt i32 %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &i32_uge
; HSAIL: cmp_ge_b1_u32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
define void @i32_uge(i32 addrspace(1)* %out, i32 %a, i32 %b) {
  %tmp0 = icmp uge i32 %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &i32_ult
; HSAIL: cmp_lt_b1_u32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
define void @i32_ult(i32 addrspace(1)* %out, i32 %a, i32 %b) {
  %tmp0 = icmp ult i32 %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &i32_ule
; HSAIL: cmp_le_b1_u32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
define void @i32_ule(i32 addrspace(1)* %out, i32 %a, i32 %b) {
  %tmp0 = icmp ule i32 %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &i32_sgt
; HSAIL: cmp_gt_b1_s32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
define void @i32_sgt(i32 addrspace(1)* %out, i32 %a, i32 %b) {
  %tmp0 = icmp sgt i32 %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &i32_sge
; HSAIL: cmp_ge_b1_s32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
define void @i32_sge(i32 addrspace(1)* %out, i32 %a, i32 %b) {
  %tmp0 = icmp sge i32 %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &i32_slt
; HSAIL: cmp_lt_b1_s32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
define void @i32_slt(i32 addrspace(1)* %out, i32 %a, i32 %b) {
  %tmp0 = icmp slt i32 %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &i32_sle
; HSAIL: cmp_le_b1_s32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32 {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, 0;
define void @i32_sle(i32 addrspace(1)* %out, i32 %a, i32 %b) {
  %tmp0 = icmp sle i32 %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &i1_eq(
define void @i1_eq(i32 addrspace(1)* %out, i1 %a, i1 %b) {
  %tmp0 = icmp eq i1 %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &i1_ne(
define void @i1_ne(i32 addrspace(1)* %out, i1 %a, i1 %b) {
  %tmp0 = icmp ne i1 %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &i1_ugt(
define void @i1_ugt(i32 addrspace(1)* %out, i1 %a, i1 %b) {
  %tmp0 = icmp ugt i1 %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &i1_uge(
define void @i1_uge(i32 addrspace(1)* %out, i1 %a, i1 %b) {
  %tmp0 = icmp uge i1 %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &i1_ult(
define void @i1_ult(i32 addrspace(1)* %out, i1 %a, i1 %b) {
  %tmp0 = icmp ult i1 %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &i1_ule(
define void @i1_ule(i32 addrspace(1)* %out, i1 %a, i1 %b) {
  %tmp0 = icmp ule i1 %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &i1_sgt(
define void @i1_sgt(i32 addrspace(1)* %out, i1 %a, i1 %b) {
  %tmp0 = icmp sgt i1 %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &i1_sge(
define void @i1_sge(i32 addrspace(1)* %out, i1 %a, i1 %b) {
  %tmp0 = icmp sge i1 %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &i1_slt(
define void @i1_slt(i32 addrspace(1)* %out, i1 %a, i1 %b) {
  %tmp0 = icmp slt i1 %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &i1_sle(
define void @i1_sle(i32 addrspace(1)* %out, i1 %a, i1 %b) {
  %tmp0 = icmp sle i1 %a, %b
  %tmp1 = sext i1 %tmp0 to i32
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}
