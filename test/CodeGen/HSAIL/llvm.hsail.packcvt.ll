; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.hsail.packcvt(float, float, float, float) #0
declare i32 @llvm.HSAIL.packcvt.u8x4.f32(float, float, float, float) #0

; HSAIL-LABEL: {{^}}prog function &test_packcvt_u8x4_f32_rrrr(
; HSAIL: packcvt_u8x4_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_packcvt_u8x4_f32_rrrr(float %x, float %y, float %z, float %w) #0 {
  %val = call i32 @llvm.hsail.packcvt(float %x, float %y, float %z, float %w) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_packcvt_u8x4_f32_rrri(
; HSAIL: packcvt_u8x4_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, 0F3f800000;
define i32 @test_packcvt_u8x4_f32_rrri(float %x, float %y, float %z) #0 {
  %val = call i32 @llvm.hsail.packcvt(float %x, float %y, float %z, float 1.0) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_packcvt_u8x4_f32_rrir(
; HSAIL: packcvt_u8x4_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, 0F3f800000, {{\$s[0-9]+}};
define i32 @test_packcvt_u8x4_f32_rrir(float %x, float %y, float %z) #0 {
  %val = call i32 @llvm.hsail.packcvt(float %x, float %y, float 1.0, float %z) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_packcvt_u8x4_f32_rirr(
; HSAIL: packcvt_u8x4_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 0F3f800000, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_packcvt_u8x4_f32_rirr(float %x, float %y, float %z) #0 {
  %val = call i32 @llvm.hsail.packcvt(float %x, float 1.0, float %y, float %z) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_packcvt_u8x4_f32_irrr(
; HSAIL: packcvt_u8x4_f32 {{\$s[0-9]+}}, 0F3f800000, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_packcvt_u8x4_f32_irrr(float %x, float %y, float %z) #0 {
  %val = call i32 @llvm.hsail.packcvt(float 1.0, float %x, float %y, float %z) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_packcvt_u8x4_f32_iirr(
; HSAIL: packcvt_u8x4_f32 {{\$s[0-9]+}}, 0F3f800000, 0F40000000, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_packcvt_u8x4_f32_iirr(float %x, float %y) #0 {
  %val = call i32 @llvm.hsail.packcvt(float 1.0, float 2.0, float %x, float %y) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_packcvt_u8x4_f32_riir(
; HSAIL: packcvt_u8x4_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 0F3f800000, 0F40000000, {{\$s[0-9]+}};
define i32 @test_packcvt_u8x4_f32_riir(float %x, float %y) #0 {
  %val = call i32 @llvm.hsail.packcvt(float %x, float 1.0, float 2.0, float %y) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_packcvt_u8x4_f32_rrii(
; HSAIL: packcvt_u8x4_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, 0F3f800000, 0F40000000;
define i32 @test_packcvt_u8x4_f32_rrii(float %x, float %y) #0 {
  %val = call i32 @llvm.hsail.packcvt(float %x, float %y, float 1.0, float 2.0) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_packcvt_u8x4_f32_riri(
; HSAIL: packcvt_u8x4_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 0F3f800000, {{\$s[0-9]+}}, 0F40000000;
define i32 @test_packcvt_u8x4_f32_riri(float %x, float %y) #0 {
  %val = call i32 @llvm.hsail.packcvt(float %x, float 1.0, float %y, float 2.0) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_packcvt_u8x4_f32_irir(
; HSAIL: packcvt_u8x4_f32 {{\$s[0-9]+}}, 0F3f800000, {{\$s[0-9]+}}, 0F40000000, {{\$s[0-9]+}};
define i32 @test_packcvt_u8x4_f32_irir(float %x, float %y) #0 {
  %val = call i32 @llvm.hsail.packcvt(float 1.0, float %x, float 2.0, float %y) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_packcvt_u8x4_f32_iiir(
; HSAIL: packcvt_u8x4_f32 {{\$s[0-9]+}}, 0F3f800000, 0F40000000, 0F40400000, {{\$s[0-9]+}};
define i32 @test_packcvt_u8x4_f32_iiir(float %x) #0 {
  %val = call i32 @llvm.hsail.packcvt(float 1.0, float 2.0, float 3.0, float %x) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_packcvt_u8x4_f32_riii(
; HSAIL: packcvt_u8x4_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 0F3f800000, 0F40000000, 0F40400000;
define i32 @test_packcvt_u8x4_f32_riii(float %x) #0 {
  %val = call i32 @llvm.hsail.packcvt(float %x, float 1.0, float 2.0, float 3.0) #0
  ret i32 %val
}

; FIXME: This should constant fold.
; HSAIL-LABEL: {{^}}prog function &test_packcvt_u8x4_f32_iiii(
; HSAIL: packcvt_u8x4_f32 {{\$s[0-9]+}}, 0F3f800000, 0F40000000, 0F40400000, 0F40800000;
define i32 @test_packcvt_u8x4_f32_iiii(float %x) #0 {
  %val = call i32 @llvm.hsail.packcvt(float 1.0, float 2.0, float 3.0, float 4.0) #0
  ret i32 %val
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_packcvt_u8x4_f32_rrrr(
; HSAIL: packcvt_u8x4_f32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_legacy_packcvt_u8x4_f32_rrrr(float %x, float %y, float %z, float %w) #0 {
  %val = call i32 @llvm.HSAIL.packcvt.u8x4.f32(float %x, float %y, float %z, float %w) #0
  ret i32 %val
}

attributes #0 = { nounwind readnone }
