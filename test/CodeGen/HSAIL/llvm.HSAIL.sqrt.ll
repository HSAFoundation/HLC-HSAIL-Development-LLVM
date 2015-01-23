; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare float @llvm.HSAIL.sqrt.ftz.f32(float) #0
declare double @llvm.HSAIL.sqrt.f64(double) #0

; HSAIL-LABEL: {{^}}prog function &hsail_sqrt_ftz_f32(
; HSAIL: sqrt_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @hsail_sqrt_ftz_f32(float addrspace(1)* %out, float addrspace(1)* %src) #1 {
  %val = load float addrspace(1)* %src, align 4
  %sqrt = call float @llvm.HSAIL.sqrt.ftz.f32(float %val) #0
  store float %sqrt, float addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &hsail_sqrt_f64(
; HSAIL: sqrt_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @hsail_sqrt_f64(double addrspace(1)* %out, double addrspace(1)* %src) #1 {
  %val = load double addrspace(1)* %src, align 4
  %sqrt = call double @llvm.HSAIL.sqrt.f64(double %val) #0
  store double %sqrt, double addrspace(1)* %out
  ret void
}

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
