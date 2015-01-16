; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &test_cvt_s32_neari_f32_pat(
; HSAIL: cvt_ftz_neari_s32_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
; HSAIL-NEXT: st_arg_align(4)_u32
; HSAIL-NEXT: ret
define i32 @test_cvt_s32_neari_f32_pat(float %x) #1 {
  %round = call float @llvm.rint.f32(float %x) #0
  %cvt = fptosi float %round to i32
  ret i32 %cvt
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_s32_neari_f64_pat(
; HSAIL: cvt_neari_s32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
; HSAIL-NEXT: st_arg_align(4)_u32
; HSAIL-NEXT: ret
define i32 @test_cvt_s32_neari_f64_pat(double %x) #1 {
  %round = call double @llvm.rint.f64(double %x) #0
  %cvt = fptosi double %round to i32
  ret i32 %cvt
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_s32_downi_f32_pat(
; HSAIL: cvt_ftz_downi_s32_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define i32 @test_cvt_s32_downi_f32_pat(float %x) #1 {
  %round = call float @llvm.floor.f32(float %x) #0
  %cvt = fptosi float %round to i32
  ret i32 %cvt
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_s32_downi_f64_pat(
; HSAIL: cvt_downi_s32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
define i32 @test_cvt_s32_downi_f64_pat(double %x) #1 {
  %round = call double @llvm.floor.f64(double %x) #0
  %cvt = fptosi double %round to i32
  ret i32 %cvt
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_s32_upi_f32(
; HSAIL: cvt_ftz_upi_s32_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define i32 @test_cvt_s32_upi_f32(float %x) #1 {
  %round = call float @llvm.ceil.f32(float %x) #0
  %cvt = fptosi float %round to i32
  ret i32 %cvt
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_s32_upi_f64(
; HSAIL: cvt_upi_s32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
define i32 @test_cvt_s32_upi_f64(double %x) #1 {
  %round = call double @llvm.ceil.f64(double %x) #0
  %cvt = fptosi double %round to i32
  ret i32 %cvt
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_s32_zeroi_f32_pat(
; HSAIL-NOT: trunc
; HSAIL: cvt_ftz_s32_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
; HSAIL-NEXT: st_arg_align(4)_u32
; HSAIL-NEXT: ret
define i32 @test_cvt_s32_zeroi_f32_pat(float %x) #1 {
  %round = call float @llvm.trunc.f32(float %x) #0
  %cvt = fptosi float %round to i32
  ret i32 %cvt
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_s32_zeroi_f64_pat(
; HSAIL-NOT: trunc
; HSAIL: cvt_s32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
; HSAIL-NEXT: st_arg_align(4)_u32
; HSAIL-NEXT: ret
define i32 @test_cvt_s32_zeroi_f64_pat(double %x) #1 {
  %round = call double @llvm.trunc.f64(double %x) #0
  %cvt = fptosi double %round to i32
  ret i32 %cvt
}

declare float @llvm.rint.f32(float) #0
declare double @llvm.rint.f64(double) #0

declare float @llvm.floor.f32(float) #0
declare double @llvm.floor.f64(double) #0

declare float @llvm.ceil.f32(float) #0
declare double @llvm.ceil.f64(double) #0

declare float @llvm.trunc.f32(float) #0
declare double @llvm.trunc.f64(double) #0

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
