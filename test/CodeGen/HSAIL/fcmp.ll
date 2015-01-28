; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &fcmp_olt_f32
; HSAIL: cmp_lt_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32
define void @fcmp_olt_f32(float addrspace(1)* %out, float addrspace(1)* %in1, float addrspace(1)* %in2) {
  %r0 = load float addrspace(1)* %in1
  %r1 = load float addrspace(1)* %in2
  %r2 = fcmp olt float %r0, %r1
  %r3 = select i1 %r2, float %r0, float %r1
  store float %r3, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fcmp_ole_f32
; HSAIL: cmp_le_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32
define void @fcmp_ole_f32(float addrspace(1)* %out, float addrspace(1)* %in1, float addrspace(1)* %in2) {
  %r0 = load float addrspace(1)* %in1
  %r1 = load float addrspace(1)* %in2
  %r2 = fcmp ole float %r0, %r1
  %r3 = select i1 %r2, float %r0, float %r1
  store float %r3, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fcmp_ogt_f32
; HSAIL: cmp_gt_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32
define void @fcmp_ogt_f32(float addrspace(1)* %out, float addrspace(1)* %in1, float addrspace(1)* %in2) {
  %r0 = load float addrspace(1)* %in1
  %r1 = load float addrspace(1)* %in2
  %r2 = fcmp ogt float %r0, %r1
  %r3 = select i1 %r2, float %r0, float %r1
  store float %r3, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fcmp_oge_f32
; HSAIL: cmp_ge_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32
define void @fcmp_oge_f32(float addrspace(1)* %out, float addrspace(1)* %in1, float addrspace(1)* %in2) {
  %r0 = load float addrspace(1)* %in1
  %r1 = load float addrspace(1)* %in2
  %r2 = fcmp oge float %r0, %r1
  %r3 = select i1 %r2, float %r0, float %r1
  store float %r3, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fcmp_one_f32
; HSAIL: cmp_ne_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32
define void @fcmp_one_f32(float addrspace(1)* %out, float addrspace(1)* %in1, float addrspace(1)* %in2) {
  %r0 = load float addrspace(1)* %in1
  %r1 = load float addrspace(1)* %in2
  %r2 = fcmp one float %r0, %r1
  %r3 = select i1 %r2, float %r0, float %r1
  store float %r3, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fcmp_oeq_f32
; HSAIL: cmp_eq_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32
define void @fcmp_oeq_f32(float addrspace(1)* %out, float addrspace(1)* %in1, float addrspace(1)* %in2) {
  %r0 = load float addrspace(1)* %in1
  %r1 = load float addrspace(1)* %in2
  %r2 = fcmp oeq float %r0, %r1
  %r3 = select i1 %r2, float %r0, float %r1
  store float %r3, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fcmp_ult_f32
; HSAIL: cmp_ltu_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32
define void @fcmp_ult_f32(float addrspace(1)* %out, float addrspace(1)* %in1, float addrspace(1)* %in2) {
  %r0 = load float addrspace(1)* %in1
  %r1 = load float addrspace(1)* %in2
  %r2 = fcmp ult float %r0, %r1
  %r3 = select i1 %r2, float %r0, float %r1
  store float %r3, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fcmp_ule_f32
; HSAIL: cmp_leu_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32
define void @fcmp_ule_f32(float addrspace(1)* %out, float addrspace(1)* %in1, float addrspace(1)* %in2) {
  %r0 = load float addrspace(1)* %in1
  %r1 = load float addrspace(1)* %in2
  %r2 = fcmp ule float %r0, %r1
  %r3 = select i1 %r2, float %r0, float %r1
  store float %r3, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fcmp_ugt_f32
; HSAIL: cmp_gtu_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32
define void @fcmp_ugt_f32(float addrspace(1)* %out, float addrspace(1)* %in1, float addrspace(1)* %in2) {
  %r0 = load float addrspace(1)* %in1
  %r1 = load float addrspace(1)* %in2
  %r2 = fcmp ugt float %r0, %r1
  %r3 = select i1 %r2, float %r0, float %r1
  store float %r3, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fcmp_uge_f32
; HSAIL: cmp_geu_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32
define void @fcmp_uge_f32(float addrspace(1)* %out, float addrspace(1)* %in1, float addrspace(1)* %in2) {
  %r0 = load float addrspace(1)* %in1
  %r1 = load float addrspace(1)* %in2
  %r2 = fcmp uge float %r0, %r1
  %r3 = select i1 %r2, float %r0, float %r1
  store float %r3, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fcmp_une_f32
; HSAIL: cmp_neu_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32
define void @fcmp_une_f32(float addrspace(1)* %out, float addrspace(1)* %in1, float addrspace(1)* %in2) {
  %r0 = load float addrspace(1)* %in1
  %r1 = load float addrspace(1)* %in2
  %r2 = fcmp une float %r0, %r1
  %r3 = select i1 %r2, float %r0, float %r1
  store float %r3, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fcmp_ueq_f32
; HSAIL: cmp_equ_ftz_b1_f32 {{\$c[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cmov_b32
define void @fcmp_ueq_f32(float addrspace(1)* %out, float addrspace(1)* %in1, float addrspace(1)* %in2) {
  %r0 = load float addrspace(1)* %in1
  %r1 = load float addrspace(1)* %in2
  %r2 = fcmp ueq float %r0, %r1
  %r3 = select i1 %r2, float %r0, float %r1
  store float %r3, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fcmp_olt_f64
; HSAIL: cmp_lt_b1_f64 {{\$c[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: cmov_b64
define void @fcmp_olt_f64(double addrspace(1)* %out, double addrspace(1)* %in1, double addrspace(1)* %in2) {
  %r0 = load double addrspace(1)* %in1
  %r1 = load double addrspace(1)* %in2
  %r2 = fcmp olt double %r0, %r1
  %r3 = select i1 %r2, double %r0, double %r1
  store double %r3, double addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fcmp_ole_f64
; HSAIL: cmp_le_b1_f64 {{\$c[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: cmov_b64
define void @fcmp_ole_f64(double addrspace(1)* %out, double addrspace(1)* %in1, double addrspace(1)* %in2) {
  %r0 = load double addrspace(1)* %in1
  %r1 = load double addrspace(1)* %in2
  %r2 = fcmp ole double %r0, %r1
  %r3 = select i1 %r2, double %r0, double %r1
  store double %r3, double addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fcmp_ogt_f64
; HSAIL: cmp_gt_b1_f64 {{\$c[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: cmov_b64
define void @fcmp_ogt_f64(double addrspace(1)* %out, double addrspace(1)* %in1, double addrspace(1)* %in2) {
  %r0 = load double addrspace(1)* %in1
  %r1 = load double addrspace(1)* %in2
  %r2 = fcmp ogt double %r0, %r1
  %r3 = select i1 %r2, double %r0, double %r1
  store double %r3, double addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fcmp_oge_f64
; HSAIL: cmp_ge_b1_f64 {{\$c[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: cmov_b64
define void @fcmp_oge_f64(double addrspace(1)* %out, double addrspace(1)* %in1, double addrspace(1)* %in2) {
  %r0 = load double addrspace(1)* %in1
  %r1 = load double addrspace(1)* %in2
  %r2 = fcmp oge double %r0, %r1
  %r3 = select i1 %r2, double %r0, double %r1
  store double %r3, double addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fcmp_one_f64
; HSAIL: cmp_ne_b1_f64 {{\$c[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: cmov_b64
define void @fcmp_one_f64(double addrspace(1)* %out, double addrspace(1)* %in1, double addrspace(1)* %in2) {
  %r0 = load double addrspace(1)* %in1
  %r1 = load double addrspace(1)* %in2
  %r2 = fcmp one double %r0, %r1
  %r3 = select i1 %r2, double %r0, double %r1
  store double %r3, double addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fcmp_oeq_f64
; HSAIL: cmp_eq_b1_f64 {{\$c[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: cmov_b64
define void @fcmp_oeq_f64(double addrspace(1)* %out, double addrspace(1)* %in1, double addrspace(1)* %in2) {
  %r0 = load double addrspace(1)* %in1
  %r1 = load double addrspace(1)* %in2
  %r2 = fcmp oeq double %r0, %r1
  %r3 = select i1 %r2, double %r0, double %r1
  store double %r3, double addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fcmp_ult_f64
; HSAIL: cmp_ltu_b1_f64 {{\$c[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: cmov_b64
define void @fcmp_ult_f64(double addrspace(1)* %out, double addrspace(1)* %in1, double addrspace(1)* %in2) {
  %r0 = load double addrspace(1)* %in1
  %r1 = load double addrspace(1)* %in2
  %r2 = fcmp ult double %r0, %r1
  %r3 = select i1 %r2, double %r0, double %r1
  store double %r3, double addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fcmp_ule_f64
; HSAIL: cmp_leu_b1_f64 {{\$c[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: cmov_b64
define void @fcmp_ule_f64(double addrspace(1)* %out, double addrspace(1)* %in1, double addrspace(1)* %in2) {
  %r0 = load double addrspace(1)* %in1
  %r1 = load double addrspace(1)* %in2
  %r2 = fcmp ule double %r0, %r1
  %r3 = select i1 %r2, double %r0, double %r1
  store double %r3, double addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fcmp_ugt_f64
; HSAIL: cmp_gtu_b1_f64 {{\$c[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: cmov_b64
define void @fcmp_ugt_f64(double addrspace(1)* %out, double addrspace(1)* %in1, double addrspace(1)* %in2) {
  %r0 = load double addrspace(1)* %in1
  %r1 = load double addrspace(1)* %in2
  %r2 = fcmp ugt double %r0, %r1
  %r3 = select i1 %r2, double %r0, double %r1
  store double %r3, double addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fcmp_uge_f64
; HSAIL: cmp_geu_b1_f64 {{\$c[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: cmov_b64
define void @fcmp_uge_f64(double addrspace(1)* %out, double addrspace(1)* %in1, double addrspace(1)* %in2) {
  %r0 = load double addrspace(1)* %in1
  %r1 = load double addrspace(1)* %in2
  %r2 = fcmp uge double %r0, %r1
  %r3 = select i1 %r2, double %r0, double %r1
  store double %r3, double addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fcmp_une_f64
; HSAIL: cmp_neu_b1_f64 {{\$c[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: cmov_b64
define void @fcmp_une_f64(double addrspace(1)* %out, double addrspace(1)* %in1, double addrspace(1)* %in2) {
  %r0 = load double addrspace(1)* %in1
  %r1 = load double addrspace(1)* %in2
  %r2 = fcmp une double %r0, %r1
  %r3 = select i1 %r2, double %r0, double %r1
  store double %r3, double addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fcmp_ueq_f64
; HSAIL: cmp_equ_b1_f64 {{\$c[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: cmov_b64
define void @fcmp_ueq_f64(double addrspace(1)* %out, double addrspace(1)* %in1, double addrspace(1)* %in2) {
  %r0 = load double addrspace(1)* %in1
  %r1 = load double addrspace(1)* %in2
  %r2 = fcmp ueq double %r0, %r1
  %r3 = select i1 %r2, double %r0, double %r1
  store double %r3, double addrspace(1)* %out
  ret void
}
