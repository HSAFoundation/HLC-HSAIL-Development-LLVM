; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &fpext_f32_to_f64(
; HSAIL: cvt_ftz_f64_f32 {{\$d[0-9]+}}, {{\$s[0-9]+}};
define void @fpext_f32_to_f64(double addrspace(1)* %out, float %in) {
  %result = fpext float %in to double
  store double %result, double addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fpext_v2f32_to_v2f64(
; HSAIL: cvt_ftz_f64_f32
; HSAIL: cvt_ftz_f64_f32
define void @fpext_v2f32_to_v2f64(<2 x double> addrspace(1)* %out, <2 x float> %in) {
  %result = fpext <2 x float> %in to <2 x double>
  store <2 x double> %result, <2 x double> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fpext_v4f32_to_v4f64(
; HSAIL: cvt_ftz_f64_f32
; HSAIL: cvt_ftz_f64_f32
; HSAIL: cvt_ftz_f64_f32
; HSAIL: cvt_ftz_f64_f32
define void @fpext_v4f32_to_v4f64(<4 x double> addrspace(1)* %out, <4 x float> %in) {
  %result = fpext <4 x float> %in to <4 x double>
  store <4 x double> %result, <4 x double> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fpext_v8f32_to_v8f64(
; HSAIL: cvt_ftz_f64_f32
; HSAIL: cvt_ftz_f64_f32
; HSAIL: cvt_ftz_f64_f32
; HSAIL: cvt_ftz_f64_f32
define void @fpext_v8f32_to_v8f64(<8 x double> addrspace(1)* %out, <8 x float> %in) {
  %result = fpext <8 x float> %in to <8 x double>
  store <8 x double> %result, <8 x double> addrspace(1)* %out
  ret void
}
