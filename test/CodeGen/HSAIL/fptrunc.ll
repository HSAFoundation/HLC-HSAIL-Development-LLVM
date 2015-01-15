; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &fptrunc_f64_to_f32(
; HSAIL: ld_arg_align(8)_f64 {{\$d[0-9]+}}, [%in];
; HSAIL-NEXT: cvt_ftz_f32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @fptrunc_f64_to_f32(float addrspace(1)* %out, double %in) {
  %result = fptrunc double %in to float
  store float %result, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fptrunc_v2f64_to_v2f32(
; HSAIL: cvt_ftz_f32_f64
; HSAIL: cvt_ftz_f32_f64
define void @fptrunc_v2f64_to_v2f32(<2 x float> addrspace(1)* %out, <2 x double> %in) {
  %result = fptrunc <2 x double> %in to <2 x float>
  store <2 x float> %result, <2 x float> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fptrunc_v4f64_to_v4f32(
; HSAIL: cvt_ftz_f32_f64
; HSAIL: cvt_ftz_f32_f64
; HSAIL: cvt_ftz_f32_f64
; HSAIL: cvt_ftz_f32_f64
define void @fptrunc_v4f64_to_v4f32(<4 x float> addrspace(1)* %out, <4 x double> %in) {
  %result = fptrunc <4 x double> %in to <4 x float>
  store <4 x float> %result, <4 x float> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fptrunc_v8f64_to_v8f32(
; HSAIL: cvt_ftz_f32_f64
; HSAIL: cvt_ftz_f32_f64
; HSAIL: cvt_ftz_f32_f64
; HSAIL: cvt_ftz_f32_f64
; HSAIL: cvt_ftz_f32_f64
; HSAIL: cvt_ftz_f32_f64
; HSAIL: cvt_ftz_f32_f64
; HSAIL: cvt_ftz_f32_f64
define void @fptrunc_v8f64_to_v8f32(<8 x float> addrspace(1)* %out, <8 x double> %in) {
  %result = fptrunc <8 x double> %in to <8 x float>
  store <8 x float> %result, <8 x float> addrspace(1)* %out
  ret void
}
