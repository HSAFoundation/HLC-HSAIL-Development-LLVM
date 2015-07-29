; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &fdiv_f32
; HSAIL: div_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @fdiv_f32(float addrspace(1)* %out, float %a, float %b) {
  %tmp0 = fdiv float %a, %b
  store float %tmp0, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fdiv_v2f32
; HSAIL: div_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @fdiv_v2f32(<2 x float> addrspace(1)* %out, <2 x float> %a, <2 x float> %b) {
  %tmp0 = fdiv <2 x float> %a, %b
  store <2 x float> %tmp0, <2 x float> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fdiv_v4f32
; HSAIL: div_ftz_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @fdiv_v4f32(<4 x float> addrspace(1)* %out, <4 x float> addrspace(1)* %in) {
  %b_ptr = getelementptr <4 x float> addrspace(1)* %in, i32 1
  %a = load <4 x float> addrspace(1) * %in
  %b = load <4 x float> addrspace(1) * %b_ptr
  %result = fdiv <4 x float> %a, %b
  store <4 x float> %result, <4 x float> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fdiv_f64
; HSAIL: div_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @fdiv_f64(double addrspace(1)* %out, double %a, double %b) {
  %tmp0 = fdiv double %a, %b
  store double %tmp0, double addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fdiv_v2f64
; HSAIL: div_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @fdiv_v2f64(<2 x double> addrspace(1)* %out, <2 x double> %a, <2 x double> %b) {
  %tmp0 = fdiv <2 x double> %a, %b
  store <2 x double> %tmp0, <2 x double> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fdiv_v4f64
; HSAIL: div_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @fdiv_v4f64(<4 x double> addrspace(1)* %out, <4 x double> addrspace(1)* %in) {
  %b_ptr = getelementptr <4 x double> addrspace(1)* %in, i32 1
  %a = load <4 x double> addrspace(1) * %in
  %b = load <4 x double> addrspace(1) * %b_ptr
  %result = fdiv <4 x double> %a, %b
  store <4 x double> %result, <4 x double> addrspace(1)* %out
  ret void
}
