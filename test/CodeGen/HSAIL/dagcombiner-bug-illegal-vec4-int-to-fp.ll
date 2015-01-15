; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &sint
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: cvt_f32_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @sint(<4 x float> addrspace(1)* %out, i32 addrspace(1)* %in) {
  %ptr = getelementptr i32 addrspace(1)* %in, i32 1
  %sint = load i32 addrspace(1) * %in
  %conv = sitofp i32 %sint to float
  %tmp0 = insertelement <4 x float> undef, float %conv, i32 0
  %splat = shufflevector <4 x float> %tmp0, <4 x float> undef, <4 x i32> zeroinitializer
  store <4 x float> %splat, <4 x float> addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &uint
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%in];
; HSAIL: cvt_f32_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
; HSAIL: ld_arg_align(4)_u32 {{\$s[0-9]+}}, [%out];
define void @uint(<4 x float> addrspace(1)* %out, i32 addrspace(1)* %in) {
  %ptr = getelementptr i32 addrspace(1)* %in, i32 1
  %uint = load i32 addrspace(1) * %in
  %conv = uitofp i32 %uint to float
  %tmp0 = insertelement <4 x float> undef, float %conv, i32 0
  %splat = shufflevector <4 x float> %tmp0, <4 x float> undef, <4 x i32> zeroinitializer
  store <4 x float> %splat, <4 x float> addrspace(1)* %out
  ret void
}
