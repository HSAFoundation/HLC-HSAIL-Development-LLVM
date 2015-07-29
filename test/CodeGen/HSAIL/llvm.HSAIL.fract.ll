; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare float @llvm.HSAIL.fract.f32(float) #0
declare double @llvm.HSAIL.fract.f64(double) #0

; HSAIL-LABEL: {{^}}prog function &fract_f32(
; HSAIL: fract_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @fract_f32(float addrspace(1)* %out, float addrspace(1)* %src) #1 {
  %val = load float addrspace(1)* %src, align 4
  %fract = call float @llvm.HSAIL.fract.f32(float %val) #0
  store float %fract, float addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &fract_f64(
; HSAIL: fract_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @fract_f64(double addrspace(1)* %out, double addrspace(1)* %src) #1 {
  %val = load double addrspace(1)* %src, align 4
  %fract = call double @llvm.HSAIL.fract.f64(double %val) #0
  store double %fract, double addrspace(1)* %out
  ret void
}

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
