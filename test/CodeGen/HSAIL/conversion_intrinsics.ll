; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; float to int

; HSAIL-LABEL: {{^}}prog function &test_cvt_s32_neari_f32(
; HSAIL: cvt_ftz_neari_s32_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define i32 @test_cvt_s32_neari_f32(float %x) #1 {
  %y = call i32 @llvm.HSAIL.cvt.s32.neari.f32(float %x) #0
  ret i32 %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_s32_downi_f32(
; HSAIL: cvt_ftz_downi_s32_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define i32 @test_cvt_s32_downi_f32(float %x) #1 {
  %y = call i32 @llvm.HSAIL.cvt.s32.downi.f32(float %x) #0
  ret i32 %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_s32_upi_f32(
; HSAIL: cvt_ftz_upi_s32_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define i32 @test_cvt_s32_upi_f32(float %x) #1 {
  %y = call i32 @llvm.HSAIL.cvt.s32.upi.f32(float %x) #0
  ret i32 %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_s32_zeroi_f32(
; HSAIL: cvt_ftz_s32_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define i32 @test_cvt_s32_zeroi_f32(float %x) #1 {
  %y = call i32 @llvm.HSAIL.cvt.s32.zeroi.f32(float %x) #0
  ret i32 %y
}

; float to unsigned int

; HSAIL-LABEL: {{^}}prog function &test_cvt_u32_neari_f32(
; HSAIL: cvt_ftz_neari_u32_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define i32 @test_cvt_u32_neari_f32(float %x) #1 {
  %y = call i32 @llvm.HSAIL.cvt.u32.neari.f32(float %x) #0
  ret i32 %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_u32_downi_f32(
; HSAIL: cvt_ftz_downi_u32_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define i32 @test_cvt_u32_downi_f32(float %x) #1 {
  %y = call i32 @llvm.HSAIL.cvt.u32.downi.f32(float %x) #0
  ret i32 %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_u32_upi_f32(
; HSAIL: cvt_ftz_upi_u32_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define i32 @test_cvt_u32_upi_f32(float %x) #1 {
  %y = call i32 @llvm.HSAIL.cvt.u32.upi.f32(float %x) #0
  ret i32 %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_u32_zeroi_f32(
; HSAIL: cvt_ftz_u32_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define i32 @test_cvt_u32_zeroi_f32(float %x) #1 {
  %y = call i32 @llvm.HSAIL.cvt.u32.zeroi.f32(float %x) #0
  ret i32 %y
}


 ; float to long

; HSAIL-LABEL: {{^}}prog function &test_cvt_s64_neari_f32(
; HSAIL: cvt_ftz_neari_s64_f32 {{\$d[0-9]+}}, {{\$s[0-9]+}}
define i64 @test_cvt_s64_neari_f32(float %x) #1 {
  %y = call i64 @llvm.HSAIL.cvt.s64.neari.f32(float %x) #0
  ret i64 %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_s64_downi_f32(
; HSAIL: cvt_ftz_downi_s64_f32 {{\$d[0-9]+}}, {{\$s[0-9]+}}
define i64 @test_cvt_s64_downi_f32(float %x) #1 {
  %y = call i64 @llvm.HSAIL.cvt.s64.downi.f32(float %x) #0
  ret i64 %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_s64_upi_f32(
; HSAIL: cvt_ftz_upi_s64_f32 {{\$d[0-9]+}}, {{\$s[0-9]+}}
define i64 @test_cvt_s64_upi_f32(float %x) #1 {
  %y = call i64 @llvm.HSAIL.cvt.s64.upi.f32(float %x) #0
  ret i64 %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_s64_zeroi_f32(
; HSAIL: cvt_ftz_s64_f32 {{\$d[0-9]+}}, {{\$s[0-9]+}}
define i64 @test_cvt_s64_zeroi_f32(float %x) #1 {
  %y = call i64 @llvm.HSAIL.cvt.s64.zeroi.f32(float %x) #0
  ret i64 %y
}

; float to unsigned long

; HSAIL-LABEL: {{^}}prog function &test_cvt_u64_neari_f32(
; HSAIL: cvt_ftz_neari_u64_f32 {{\$d[0-9]+}}, {{\$s[0-9]+}}
define i64 @test_cvt_u64_neari_f32(float %x) #1 {
  %y = call i64 @llvm.HSAIL.cvt.u64.neari.f32(float %x) #0
  ret i64 %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_u64_downi_f32(
; HSAIL: cvt_ftz_downi_u64_f32 {{\$d[0-9]+}}, {{\$s[0-9]+}}
define i64 @test_cvt_u64_downi_f32(float %x) #1 {
  %y = call i64 @llvm.HSAIL.cvt.u64.downi.f32(float %x) #0
  ret i64 %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_u64_upi_f32(
; HSAIL: cvt_ftz_upi_u64_f32 {{\$d[0-9]+}}, {{\$s[0-9]+}}
define i64 @test_cvt_u64_upi_f32(float %x) #1 {
  %y = call i64 @llvm.HSAIL.cvt.u64.upi.f32(float %x) #0
  ret i64 %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_u64_zeroi_f32(
; HSAIL: cvt_ftz_u64_f32 {{\$d[0-9]+}}, {{\$s[0-9]+}}
define i64 @test_cvt_u64_zeroi_f32(float %x) #1 {
  %y = call i64 @llvm.HSAIL.cvt.u64.zeroi.f32(float %x) #0
  ret i64 %y
}

; double to int

; HSAIL-LABEL: {{^}}prog function &test_cvt_s32_neari_f64(
; HSAIL: cvt_neari_s32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
define i32 @test_cvt_s32_neari_f64(double %x) #1 {
  %y = call i32 @llvm.HSAIL.cvt.s32.neari.f64(double %x) #0
  ret i32 %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_s32_downi_f64(
; HSAIL: cvt_downi_s32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
define i32 @test_cvt_s32_downi_f64(double %x) #1 {
  %y = call i32 @llvm.HSAIL.cvt.s32.downi.f64(double %x) #0
  ret i32 %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_s32_upi_f64(
; HSAIL: cvt_upi_s32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
define i32 @test_cvt_s32_upi_f64(double %x) #1 {
  %y = call i32 @llvm.HSAIL.cvt.s32.upi.f64(double %x) #0
  ret i32 %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_s32_zeroi_f64(
; HSAIL: cvt_s32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
define i32 @test_cvt_s32_zeroi_f64(double %x) #1 {
  %y = call i32 @llvm.HSAIL.cvt.s32.zeroi.f64(double %x) #0
  ret i32 %y
}


; double to unsigned int

; HSAIL-LABEL: {{^}}prog function &test_cvt_u32_neari_f64(
; HSAIL: cvt_neari_u32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
define i32 @test_cvt_u32_neari_f64(double %x) #1 {
  %y = call i32 @llvm.HSAIL.cvt.u32.neari.f64(double %x) #0
  ret i32 %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_u32_downi_f64(
; HSAIL: cvt_downi_u32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
define i32 @test_cvt_u32_downi_f64(double %x) #1 {
  %y = call i32 @llvm.HSAIL.cvt.u32.downi.f64(double %x) #0
  ret i32 %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_u32_upi_f64(
; HSAIL: cvt_upi_u32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
define i32 @test_cvt_u32_upi_f64(double %x) #1 {
  %y = call i32 @llvm.HSAIL.cvt.u32.upi.f64(double %x) #0
  ret i32 %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_u32_zeroi_f64(
; HSAIL: cvt_u32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
define i32 @test_cvt_u32_zeroi_f64(double %x) #1 {
  %y = call i32 @llvm.HSAIL.cvt.u32.zeroi.f64(double %x) #0
  ret i32 %y
}

; double to long

; HSAIL-LABEL: {{^}}prog function &test_cvt_s64_neari_f64(
; HSAIL: cvt_neari_s64_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
define i64 @test_cvt_s64_neari_f64(double %x) #1 {
  %y = call i64 @llvm.HSAIL.cvt.s64.neari.f64(double %x) #0
  ret i64 %y

}

; HSAIL-LABEL: {{^}}prog function &test_cvt_s64_downi_f64(
; HSAIL: cvt_downi_s64_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
define i64 @test_cvt_s64_downi_f64(double %x) #1 {
  %y = call i64 @llvm.HSAIL.cvt.s64.downi.f64(double %x) #0
  ret i64 %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_s64_upi_f64(
; HSAIL: cvt_upi_s64_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
define i64 @test_cvt_s64_upi_f64(double %x) #1 {
  %y = call i64 @llvm.HSAIL.cvt.s64.upi.f64(double %x) #0
  ret i64 %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_s64_zeroi_f64(
; HSAIL: cvt_s64_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
define i64 @test_cvt_s64_zeroi_f64(double %x) #1 {
  %y = call i64 @llvm.HSAIL.cvt.s64.zeroi.f64(double %x) #0
  ret i64 %y
}

; double to unsigned long

; HSAIL-LABEL: {{^}}prog function &test_cvt_u64_neari_f64(
; HSAIL: cvt_neari_u64_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
define i64 @test_cvt_u64_neari_f64(double %x) #1 {
  %y = call i64 @llvm.HSAIL.cvt.u64.neari.f64(double %x) #0
  ret i64 %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_u64_downi_f64(
; HSAIL: cvt_downi_u64_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
define i64 @test_cvt_u64_downi_f64(double %x) #1 {
  %y = call i64 @llvm.HSAIL.cvt.u64.downi.f64(double %x) #0
  ret i64 %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_u64_upi_f64(
; HSAIL: cvt_upi_u64_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
define i64 @test_cvt_u64_upi_f64(double %x) #1 {
  %y = call i64 @llvm.HSAIL.cvt.u64.upi.f64(double %x) #0
  ret i64 %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_u64_zeroi_f64(
; HSAIL: cvt_u64_f64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
define i64 @test_cvt_u64_zeroi_f64(double %x) #1 {
  %y = call i64 @llvm.HSAIL.cvt.u64.zeroi.f64(double %x) #0
  ret i64 %y
}

; half to float

; HSAIL-LABEL: {{^}}prog function &test_cvt_f32_f16(
; HSAIL: cvt_f32_f16 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define float @test_cvt_f32_f16(i32 %x) #1 {
  %y = call float @llvm.HSAIL.cvt.f32.f16(i32 %x) #0
  ret float %y
}

; float to half

; HSAIL-LABEL: {{^}}prog function &test_cvt_zero_f16_f32(
; HSAIL: cvt_zero_f16_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define float @test_cvt_zero_f16_f32(float %x) #1 {
  %y = call float @llvm.HSAIL.cvt.zero.f16.f32(float %x) #0
  ret float %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_near_f16_f32(
; HSAIL: cvt_f16_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define float @test_cvt_near_f16_f32(float %x) #1 {
  %y = call float @llvm.HSAIL.cvt.near.f16.f32(float %x) #0
  ret float %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_down_f16_f32(
; HSAIL: cvt_down_f16_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define float @test_cvt_down_f16_f32(float %x) #1 {
  %y = call float @llvm.HSAIL.cvt.down.f16.f32(float %x) #0
  ret float %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_up_f16_f32(
; HSAIL: cvt_up_f16_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define float @test_cvt_up_f16_f32(float %x) #1 {
  %y = call float @llvm.HSAIL.cvt.up.f16.f32(float   %x) #0
  ret float %y
}

; double to half

; HSAIL-LABEL: {{^}}prog function &test_cvt_zero_f16_f64(
; HSAIL: cvt_zero_f16_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
define float @test_cvt_zero_f16_f64(double %x) #1 {
  %y = call float @llvm.HSAIL.cvt.zero.f16.f64(double %x) #0
  ret float %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_near_f16_f64(
; HSAIL: cvt_f16_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
define float @test_cvt_near_f16_f64(double %x) #1 {
  %y = call float @llvm.HSAIL.cvt.near.f16.f64(double %x) #0
  ret float %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_down_f16_f64(
; HSAIL: cvt_down_f16_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
define float @test_cvt_down_f16_f64(double %x) #1 {
  %y = call float @llvm.HSAIL.cvt.down.f16.f64(double %x) #0
  ret float %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_up_f16_f64(
; HSAIL: cvt_up_f16_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
define float @test_cvt_up_f16_f64(double %x) #1 {
  %y = call float @llvm.HSAIL.cvt.up.f16.f64(double %x) #0
  ret float %y
}


; int to float

; HSAIL-LABEL: {{^}}prog function &test_cvt_f32_down_i32(
; HSAIL: cvt_down_f32_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define float @test_cvt_f32_down_i32(i32 %x) #1 {
  %y = call float @llvm.HSAIL.cvt.f32.down.i32(i32 %x) #0
  ret float %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_f32_up_i32(
; HSAIL: cvt_up_f32_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define float @test_cvt_f32_up_i32(i32 %x) #1 {
  %y = call float @llvm.HSAIL.cvt.f32.up.i32(i32 %x) #0
  ret float %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_f32_zero_i32(
; HSAIL: cvt_zero_f32_s32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define float @test_cvt_f32_zero_i32(i32 %x) #1 {
  %y = call float @llvm.HSAIL.cvt.f32.zero.i32(i32 %x) #0
  ret float %y
}


; unsigned int to float

; HSAIL-LABEL: {{^}}prog function &test_cvt_f32_down_u32(
; HSAIL: cvt_down_f32_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define float @test_cvt_f32_down_u32(i32 %x) #1 {
  %y = call float @llvm.HSAIL.cvt.f32.down.u32(i32 %x) #0
  ret float %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_f32_up_u32(
; HSAIL: cvt_up_f32_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define float @test_cvt_f32_up_u32(i32 %x) #1 {
  %y = call float @llvm.HSAIL.cvt.f32.up.u32(i32 %x) #0
  ret float %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_f32_zero_u32(
; HSAIL: cvt_zero_f32_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}}
define float @test_cvt_f32_zero_u32(i32 %x) #1 {
  %y = call float @llvm.HSAIL.cvt.f32.zero.u32(i32 %x) #0
  ret float %y
}


; long to float

; HSAIL-LABEL: {{^}}prog function &test_cvt_f32_down_i64(
; HSAIL: cvt_down_f32_s64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
define float @test_cvt_f32_down_i64(i64 %x) #1 {
  %y = call float @llvm.HSAIL.cvt.f32.down.i64(i64 %x) #0
  ret float %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_f32_up_i64(
; HSAIL: cvt_up_f32_s64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
define float @test_cvt_f32_up_i64(i64 %x) #1 {
  %y = call float @llvm.HSAIL.cvt.f32.up.i64(i64 %x) #0
  ret float %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_f32_zero_i64(
; HSAIL: cvt_zero_f32_s64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
define float @test_cvt_f32_zero_i64(i64 %x) #1 {
  %y = call float @llvm.HSAIL.cvt.f32.zero.i64(i64 %x) #0
  ret float %y
}

; unsigned long to float

; HSAIL-LABEL: {{^}}prog function &test_cvt_f32_down_u64(
; HSAIL: cvt_down_f32_u64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
define float @test_cvt_f32_down_u64(i64 %x) #1 {
  %y = call float @llvm.HSAIL.cvt.f32.down.u64(i64 %x) #0
  ret float %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_f32_up_u64(
; HSAIL: cvt_up_f32_u64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
define float @test_cvt_f32_up_u64(i64 %x) #1 {
  %y = call float @llvm.HSAIL.cvt.f32.up.u64(i64 %x) #0
  ret float %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_f32_zero_u64(
; HSAIL: cvt_zero_f32_u64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
define float @test_cvt_f32_zero_u64(i64 %x) #1 {
  %y = call float @llvm.HSAIL.cvt.f32.zero.u64(i64 %x) #0
  ret float %y
}

; long to double

; HSAIL-LABEL: {{^}}prog function &test_cvt_f64_down_i64(
; HSAIL: cvt_down_f64_s64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
define double @test_cvt_f64_down_i64(i64 %x) #1 {
  %y = call double @llvm.HSAIL.cvt.f64.down.i64(i64 %x) #0
  ret double %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_f64_up_i64(
; HSAIL: cvt_up_f64_s64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
define double @test_cvt_f64_up_i64(i64 %x) #1 {
  %y = call double @llvm.HSAIL.cvt.f64.up.i64(i64 %x) #0
  ret double %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_f64_zero_i64(
; HSAIL: cvt_zero_f64_s64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
define double @test_cvt_f64_zero_i64(i64 %x) #1 {
  %y = call double @llvm.HSAIL.cvt.f64.zero.i64(i64 %x) #0
  ret double %y
}

; unsigned long to double
; HSAIL-LABEL: {{^}}prog function &test_cvt_f64_down_u64(
; HSAIL: cvt_down_f64_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
define double @test_cvt_f64_down_u64(i64 %x) #1 {
  %y = call double @llvm.HSAIL.cvt.f64.down.u64(i64 %x) #0
  ret double %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_f64_up_u64(
; HSAIL: cvt_up_f64_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
define double @test_cvt_f64_up_u64(i64 %x) #1 {
  %y = call double @llvm.HSAIL.cvt.f64.up.u64(i64 %x) #0
  ret double %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_f64_zero_u64(
; HSAIL: cvt_zero_f64_u64 {{\$d[0-9]+}}, {{\$d[0-9]+}}
define double @test_cvt_f64_zero_u64(i64 %x) #1 {
  %y = call double @llvm.HSAIL.cvt.f64.zero.u64(i64 %x) #0
  ret double %y
}


; double to float

; HSAIL-LABEL: {{^}}prog function &test_cvt_f32_down_f64(
; HSAIL: cvt_ftz_down_f32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
define float @test_cvt_f32_down_f64(double %x) #1 {
  %y = call float @llvm.HSAIL.cvt.f32.down.f64(double %x) #0
  ret float %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_f32_up_f64(
; HSAIL: cvt_ftz_up_f32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
define float @test_cvt_f32_up_f64(double %x) #1 {
  %y = call float @llvm.HSAIL.cvt.f32.up.f64(double %x) #0
  ret float %y
}

; HSAIL-LABEL: {{^}}prog function &test_cvt_f32_zero_f64(
; HSAIL: cvt_ftz_zero_f32_f64 {{\$s[0-9]+}}, {{\$d[0-9]+}}
define float @test_cvt_f32_zero_f64(double %x) #1 {
  %y = call float @llvm.HSAIL.cvt.f32.zero.f64(double %x) #0
  ret float %y
}

declare i32 @llvm.HSAIL.cvt.s32.neari.f32(float) #0
declare i32 @llvm.HSAIL.cvt.s32.downi.f32(float) #0
declare i32 @llvm.HSAIL.cvt.s32.upi.f32(float) #0
declare i32 @llvm.HSAIL.cvt.s32.zeroi.f32(float) #0
declare i32 @llvm.HSAIL.cvt.u32.neari.f32(float) #0
declare i32 @llvm.HSAIL.cvt.u32.downi.f32(float) #0
declare i32 @llvm.HSAIL.cvt.u32.upi.f32(float) #0
declare i32 @llvm.HSAIL.cvt.u32.zeroi.f32(float) #0
declare i64 @llvm.HSAIL.cvt.s64.neari.f32(float) #0
declare i64 @llvm.HSAIL.cvt.s64.downi.f32(float) #0
declare i64 @llvm.HSAIL.cvt.s64.upi.f32(float) #0
declare i64 @llvm.HSAIL.cvt.s64.zeroi.f32(float) #0
declare i64 @llvm.HSAIL.cvt.u64.neari.f32(float) #0
declare i64 @llvm.HSAIL.cvt.u64.downi.f32(float) #0
declare i64 @llvm.HSAIL.cvt.u64.upi.f32(float) #0
declare i64 @llvm.HSAIL.cvt.u64.zeroi.f32(float) #0
declare i32 @llvm.HSAIL.cvt.s32.neari.f64(double) #0
declare i32 @llvm.HSAIL.cvt.s32.downi.f64(double) #0
declare i32 @llvm.HSAIL.cvt.s32.upi.f64(double) #0
declare i32 @llvm.HSAIL.cvt.s32.zeroi.f64(double) #0
declare i32 @llvm.HSAIL.cvt.u32.neari.f64(double) #0
declare i32 @llvm.HSAIL.cvt.u32.downi.f64(double) #0
declare i32 @llvm.HSAIL.cvt.u32.upi.f64(double) #0
declare i32 @llvm.HSAIL.cvt.u32.zeroi.f64(double) #0
declare i64 @llvm.HSAIL.cvt.s64.neari.f64(double) #0
declare i64 @llvm.HSAIL.cvt.s64.downi.f64(double) #0
declare i64 @llvm.HSAIL.cvt.s64.upi.f64(double) #0
declare i64 @llvm.HSAIL.cvt.s64.zeroi.f64(double) #0
declare i64 @llvm.HSAIL.cvt.u64.neari.f64(double) #0
declare i64 @llvm.HSAIL.cvt.u64.downi.f64(double) #0
declare i64 @llvm.HSAIL.cvt.u64.upi.f64(double) #0
declare i64 @llvm.HSAIL.cvt.u64.zeroi.f64(double) #0
declare float @llvm.HSAIL.cvt.f32.f16(i32) #0
declare float @llvm.HSAIL.cvt.zero.f16.f32(float) #0
declare float @llvm.HSAIL.cvt.near.f16.f32(float) #0
declare float @llvm.HSAIL.cvt.down.f16.f32(float) #0
declare float @llvm.HSAIL.cvt.up.f16.f32(float) #0
declare float @llvm.HSAIL.cvt.zero.f16.f64(double) #0
declare float @llvm.HSAIL.cvt.near.f16.f64(double) #0
declare float @llvm.HSAIL.cvt.down.f16.f64(double) #0
declare float @llvm.HSAIL.cvt.up.f16.f64(double) #0
declare float @llvm.HSAIL.cvt.f32.down.i32(i32) #0
declare float @llvm.HSAIL.cvt.f32.up.i32(i32) #0
declare float @llvm.HSAIL.cvt.f32.zero.i32(i32) #0
declare float @llvm.HSAIL.cvt.f32.down.u32(i32) #0
declare float @llvm.HSAIL.cvt.f32.up.u32(i32) #0
declare float @llvm.HSAIL.cvt.f32.zero.u32(i32) #0
declare float @llvm.HSAIL.cvt.f32.down.i64(i64) #0
declare float @llvm.HSAIL.cvt.f32.up.i64(i64) #0
declare float @llvm.HSAIL.cvt.f32.zero.i64(i64) #0
declare float @llvm.HSAIL.cvt.f32.down.u64(i64) #0
declare float @llvm.HSAIL.cvt.f32.up.u64(i64) #0
declare float @llvm.HSAIL.cvt.f32.zero.u64(i64) #0
declare double @llvm.HSAIL.cvt.f64.down.i64(i64) #0
declare double @llvm.HSAIL.cvt.f64.up.i64(i64) #0
declare double @llvm.HSAIL.cvt.f64.zero.i64(i64) #0
declare double @llvm.HSAIL.cvt.f64.down.u64(i64) #0
declare double @llvm.HSAIL.cvt.f64.up.u64(i64) #0
declare double @llvm.HSAIL.cvt.f64.zero.u64(i64) #0
declare float @llvm.HSAIL.cvt.f32.down.f64(double) #0
declare float @llvm.HSAIL.cvt.f32.up.f64(double) #0
declare float @llvm.HSAIL.cvt.f32.zero.f64(double) #0

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
