; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

declare float @llvm.fmuladd.f32(float, float, float)
declare double @llvm.fmuladd.f64(double, double, double)

; FUNC-LABEL: {{^}}prog function &fmuladd_f32
; HSAIL: mul_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: add_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @fmuladd_f32(float addrspace(1)* %out, float addrspace(1)* %in1,
                         float addrspace(1)* %in2, float addrspace(1)* %in3) {
  %r0 = load float, float addrspace(1)* %in1
  %r1 = load float, float addrspace(1)* %in2
  %r2 = load float, float addrspace(1)* %in3
  %r3 = tail call float @llvm.fmuladd.f32(float %r0, float %r1, float %r2)
  store float %r3, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fmuladd_f64
; HSAIL: mul_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: add_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @fmuladd_f64(double addrspace(1)* %out, double addrspace(1)* %in1,
                         double addrspace(1)* %in2, double addrspace(1)* %in3) {
  %r0 = load double, double addrspace(1)* %in1
  %r1 = load double, double addrspace(1)* %in2
  %r2 = load double, double addrspace(1)* %in3
  %r3 = tail call double @llvm.fmuladd.f64(double %r0, double %r1, double %r2)
  store double %r3, double addrspace(1)* %out
  ret void
}
