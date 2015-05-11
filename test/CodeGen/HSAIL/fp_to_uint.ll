; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &fp_to_uint_f32_i32
; HSAIL: cvt_ftz_u32_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @fp_to_uint_f32_i32 (i32 addrspace(1)* %out, float %in) {
  %conv = fptoui float %in to i32
  store i32 %conv, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fp_to_uint_f32_v2i32
; HSAIL: cvt_ftz_u32_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_ftz_u32_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @fp_to_uint_f32_v2i32(<2 x i32> addrspace(1)* %out, <2 x float> %in) {
  %result = fptoui <2 x float> %in to <2 x i32>
  store <2 x i32> %result, <2 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fp_to_uint_f32_v4i32
; HSAIL: cvt_ftz_u32_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_ftz_u32_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_ftz_u32_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_ftz_u32_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define void @fp_to_uint_f32_v4i32(<4 x i32> addrspace(1)* %out, <4 x float> addrspace(1)* %in) {
  %value = load <4 x float>, <4 x float> addrspace(1) * %in
  %result = fptoui <4 x float> %value to <4 x i32>
  store <4 x i32> %result, <4 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fp_to_uint_f32_i64
; HSAIL: cvt_ftz_u64_f32 {{\$d[0-9]+}}, {{\$s[0-9]+}};
define void @fp_to_uint_f32_i64 (i64 addrspace(1)* %out, float %in) {
  %conv = fptoui float %in to i64
  store i64 %conv, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fp_to_uint_f32_v2i64
; HSAIL: cvt_ftz_u64_f32 {{\$d[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_ftz_u64_f32 {{\$d[0-9]+}}, {{\$s[0-9]+}};
define void @fp_to_uint_f32_v2i64(<2 x i64> addrspace(1)* %out, <2 x float> %x) {
  %conv = fptoui <2 x float> %x to <2 x i64>
  store <2 x i64> %conv, <2 x i64> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fp_to_uint_f32_v4i64
; HSAIL: cvt_ftz_u64_f32 {{\$d[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_ftz_u64_f32 {{\$d[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_ftz_u64_f32 {{\$d[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: cvt_ftz_u64_f32 {{\$d[0-9]+}}, {{\$s[0-9]+}};
define void @fp_to_uint_f32_v4i64(<4 x i64> addrspace(1)* %out, <4 x float> %x) {
  %conv = fptoui <4 x float> %x to <4 x i64>
  store <4 x i64> %conv, <4 x i64> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fp_to_uint_f64_i32
; HSAIL: cvt_u32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}};
define void @fp_to_uint_f64_i32 (i32 addrspace(1)* %out, double %in) {
  %conv = fptoui double %in to i32
  store i32 %conv, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fp_to_uint_f64_v2i32
; HSAIL: cvt_u32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: cvt_u32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}};
define void @fp_to_uint_f64_v2i32(<2 x i32> addrspace(1)* %out, <2 x double> %in) {
  %result = fptoui <2 x double> %in to <2 x i32>
  store <2 x i32> %result, <2 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fp_to_uint_f64_v4i32
; HSAIL: cvt_u32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: cvt_u32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: cvt_u32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: cvt_u32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}};
define void @fp_to_uint_f64_v4i32(<4 x i32> addrspace(1)* %out, <4 x double> addrspace(1)* %in) {
  %value = load <4 x double>, <4 x double> addrspace(1) * %in
  %result = fptoui <4 x double> %value to <4 x i32>
  store <4 x i32> %result, <4 x i32> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fp_to_uint_f64_i64
; HSAIL: cvt_u64_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @fp_to_uint_f64_i64 (i64 addrspace(1)* %out, double %in) {
  %conv = fptoui double %in to i64
  store i64 %conv, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fp_to_uint_f64_v2i64
; HSAIL: cvt_u64_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: cvt_u64_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @fp_to_uint_f64_v2i64(<2 x i64> addrspace(1)* %out, <2 x double> %x) {
  %conv = fptoui <2 x double> %x to <2 x i64>
  store <2 x i64> %conv, <2 x i64> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &fp_to_uint_f64_v4i64
; HSAIL: cvt_u64_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: cvt_u64_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: cvt_u64_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
; HSAIL: cvt_u64_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}};
define void @fp_to_uint_f64_v4i64(<4 x i64> addrspace(1)* %out, <4 x double> %x) {
  %conv = fptoui <4 x double> %x to <4 x i64>
  store <4 x i64> %conv, <4 x i64> addrspace(1)* %out
  ret void
}
