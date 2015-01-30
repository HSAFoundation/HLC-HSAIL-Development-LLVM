; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.HSAIL.activelaneshuffle.b32(i32, i32, i32, i1) #0
declare i64 @llvm.HSAIL.activelaneshuffle.b64(i64, i32, i64, i1) #0

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b32_iiii(
; HSAIL: activelaneshuffle_b32 {{\$s[0-9]+}}, 0, 0, 0, 0;
define void @test_activelaneshuffle_b32_iiii(i32 addrspace(1)* %out) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.b32(i32 0, i32 0, i32 0, i1 false) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b32_rrrr(
; HSAIL: activelaneshuffle_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$c[0-9]+}};
define void @test_activelaneshuffle_b32_rrrr(i32 addrspace(1)* %out, i32 %src0, i32 %src1, i32 %src2, i1 %src3) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.b32(i32 %src0, i32 %src1, i32 %src2, i1 %src3) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b32_irrr(
; HSAIL: activelaneshuffle_b32 {{\$s[0-9]+}}, 10, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$c[0-9]+}};
define void @test_activelaneshuffle_b32_irrr(i32 addrspace(1)* %out, i32 %src1, i32 %src2, i1 %src3) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.b32(i32 10, i32 %src1, i32 %src2, i1 %src3) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b32_rirr(
; HSAIL: activelaneshuffle_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 7, {{\$s[0-9]+}}, {{\$c[0-9]+}};
define void @test_activelaneshuffle_b32_rirr(i32 addrspace(1)* %out, i32 %src0, i32 %src2, i1 %src3) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.b32(i32 %src0, i32 7, i32 %src2, i1 %src3) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b32_rrir(
; HSAIL: activelaneshuffle_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, 3, {{\$c[0-9]+}};
define void @test_activelaneshuffle_b32_rrir(i32 addrspace(1)* %out, i32 %src0, i32 %src1, i1 %src3) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.b32(i32 %src0, i32 %src1, i32 3, i1 %src3) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b32_rrri(
; HSAIL: activelaneshuffle_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, 1;
define void @test_activelaneshuffle_b32_rrri(i32 addrspace(1)* %out, i32 %src0, i32 %src1, i32 %src2) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.b32(i32 %src0, i32 %src1, i32 %src2, i1 true) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b32_iirr(
; HSAIL: activelaneshuffle_b32 {{\$s[0-9]+}}, 9, 13, {{\$s[0-9]+}}, {{\$c[0-9]+}};
define void @test_activelaneshuffle_b32_iirr(i32 addrspace(1)* %out, i32 %src2, i1 %src3) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.b32(i32 9, i32 13, i32 %src2, i1 %src3) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b32_riir(
; HSAIL: activelaneshuffle_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 13, 56, {{\$c[0-9]+}};
define void @test_activelaneshuffle_b32_riir(i32 addrspace(1)* %out, i32 %src0, i1 %src3) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.b32(i32 %src0, i32 13, i32 56, i1 %src3) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b32_rrii(
; HSAIL: activelaneshuffle_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, 23, 1;
define void @test_activelaneshuffle_b32_rrii(i32 addrspace(1)* %out, i32 %src0, i32 %src1) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.b32(i32 %src0, i32 %src1, i32 23, i1 true) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b32_irir(
; HSAIL: activelaneshuffle_b32 {{\$s[0-9]+}}, 11, {{\$s[0-9]+}}, 43, {{\$c[0-9]+}};
define void @test_activelaneshuffle_b32_irir(i32 addrspace(1)* %out, i32 %src1, i1 %src3) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.b32(i32 11, i32 %src1, i32 43, i1 %src3) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b32_riri(
; HSAIL: activelaneshuffle_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 11, {{\$s[0-9]+}}, 0;
define void @test_activelaneshuffle_b32_riri(i32 addrspace(1)* %out, i32 %src0, i32 %src2) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.b32(i32 %src0, i32 11, i32 %src2, i1 false) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b32_irri(
; HSAIL: activelaneshuffle_b32 {{\$s[0-9]+}}, 17, {{\$s[0-9]+}}, {{\$s[0-9]+}}, 0;
define void @test_activelaneshuffle_b32_irri(i32 addrspace(1)* %out, i32 %src1, i32 %src2) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.b32(i32 17, i32 %src1, i32 %src2, i1 false) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b32_iiir(
; HSAIL: activelaneshuffle_b32 {{\$s[0-9]+}}, 11, 9, 43, {{\$c[0-9]+}};
define void @test_activelaneshuffle_b32_iiir(i32 addrspace(1)* %out, i1 %src3) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.b32(i32 11, i32 9, i32 43, i1 %src3) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b32_riii(
; HSAIL: activelaneshuffle_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 11, 22, 0;
define void @test_activelaneshuffle_b32_riii(i32 addrspace(1)* %out, i32 %src0, i32 %src2) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.b32(i32 %src0, i32 11, i32 22, i1 false) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b32_iiri(
; HSAIL: activelaneshuffle_b32 {{\$s[0-9]+}}, 3, 11, {{\$s[0-9]+}}, 0;
define void @test_activelaneshuffle_b32_iiri(i32 addrspace(1)* %out, i32 %src2) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.b32(i32 3, i32 11, i32 %src2, i1 false) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b32_irii(
; HSAIL: activelaneshuffle_b32 {{\$s[0-9]+}}, 11, {{\$s[0-9]+}}, 43, 1;
define void @test_activelaneshuffle_b32_irii(i32 addrspace(1)* %out, i32 %src1) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.b32(i32 11, i32 %src1, i32 43, i1 true) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b64_iiii(
; HSAIL: activelaneshuffle_b64 {{\$d[0-9]+}}, 0, 0, 0, 0;
define void @test_activelaneshuffle_b64_iiii(i64 addrspace(1)* %out) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.b64(i64 0, i32 0, i64 0, i1 false) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b64_rrrr(
; HSAIL: activelaneshuffle_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$s[0-9]+}}, {{\$d[0-9]+}}, {{\$c[0-9]+}};
define void @test_activelaneshuffle_b64_rrrr(i64 addrspace(1)* %out, i64 %src0, i32 %src1, i64 %src2, i1 %src3) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.b64(i64 %src0, i32 %src1, i64 %src2, i1 %src3) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b64_irrr(
; HSAIL: activelaneshuffle_b64 {{\$d[0-9]+}}, 10, {{\$s[0-9]+}}, {{\$d[0-9]+}}, {{\$c[0-9]+}};
define void @test_activelaneshuffle_b64_irrr(i64 addrspace(1)* %out, i32 %src1, i64 %src2, i1 %src3) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.b64(i64 10, i32 %src1, i64 %src2, i1 %src3) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b64_rirr(
; HSAIL: activelaneshuffle_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 7, {{\$d[0-9]+}}, {{\$c[0-9]+}};
define void @test_activelaneshuffle_b64_rirr(i64 addrspace(1)* %out, i64 %src0, i64 %src2, i1 %src3) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.b64(i64 %src0, i32 7, i64 %src2, i1 %src3) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b64_rrir(
; HSAIL: activelaneshuffle_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$s[0-9]+}}, 3, {{\$c[0-9]+}};
define void @test_activelaneshuffle_b64_rrir(i64 addrspace(1)* %out, i64 %src0, i32 %src1, i1 %src3) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.b64(i64 %src0, i32 %src1, i64 3, i1 %src3) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b64_rrri(
; HSAIL: activelaneshuffle_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$s[0-9]+}}, {{\$d[0-9]+}}, 1;
define void @test_activelaneshuffle_b64_rrri(i64 addrspace(1)* %out, i64 %src0, i32 %src1, i64 %src2) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.b64(i64 %src0, i32 %src1, i64 %src2, i1 true) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b64_iirr(
; HSAIL: activelaneshuffle_b64 {{\$d[0-9]+}}, 9, 13, {{\$d[0-9]+}}, {{\$c[0-9]+}};
define void @test_activelaneshuffle_b64_iirr(i64 addrspace(1)* %out, i64 %src2, i1 %src3) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.b64(i64 9, i32 13, i64 %src2, i1 %src3) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b64_riir(
; HSAIL: activelaneshuffle_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 13, 56, {{\$c[0-9]+}};
define void @test_activelaneshuffle_b64_riir(i64 addrspace(1)* %out, i64 %src0, i1 %src3) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.b64(i64 %src0, i32 13, i64 56, i1 %src3) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b64_rrii(
; HSAIL: activelaneshuffle_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$s[0-9]+}}, 23, 1;
define void @test_activelaneshuffle_b64_rrii(i64 addrspace(1)* %out, i64 %src0, i32 %src1) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.b64(i64 %src0, i32 %src1, i64 23, i1 true) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b64_irir(
; HSAIL: activelaneshuffle_b64 {{\$d[0-9]+}}, 11, {{\$s[0-9]+}}, 43, {{\$c[0-9]+}};
define void @test_activelaneshuffle_b64_irir(i64 addrspace(1)* %out, i32 %src1, i1 %src3) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.b64(i64 11, i32 %src1, i64 43, i1 %src3) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b64_riri(
; HSAIL: activelaneshuffle_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 11, {{\$d[0-9]+}}, 0;
define void @test_activelaneshuffle_b64_riri(i64 addrspace(1)* %out, i64 %src0, i64 %src2) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.b64(i64 %src0, i32 11, i64 %src2, i1 false) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b64_irri(
; HSAIL: activelaneshuffle_b64 {{\$d[0-9]+}}, 17, {{\$s[0-9]+}}, {{\$d[0-9]+}}, 0;
define void @test_activelaneshuffle_b64_irri(i64 addrspace(1)* %out, i32 %src1, i64 %src2) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.b64(i64 17, i32 %src1, i64 %src2, i1 false) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b64_iiir(
; HSAIL: activelaneshuffle_b64 {{\$d[0-9]+}}, 11, 9, 43, {{\$c[0-9]+}};
define void @test_activelaneshuffle_b64_iiir(i64 addrspace(1)* %out, i1 %src3) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.b64(i64 11, i32 9, i64 43, i1 %src3) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b64_riii(
; HSAIL: activelaneshuffle_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 11, 22, 0;
define void @test_activelaneshuffle_b64_riii(i64 addrspace(1)* %out, i64 %src0, i64 %src2) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.b64(i64 %src0, i32 11, i64 22, i1 false) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b64_iiri(
; HSAIL: activelaneshuffle_b64 {{\$d[0-9]+}}, 3, 11, {{\$d[0-9]+}}, 0;
define void @test_activelaneshuffle_b64_iiri(i64 addrspace(1)* %out, i64 %src2) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.b64(i64 3, i32 11, i64 %src2, i1 false) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_b64_irii(
; HSAIL: activelaneshuffle_b64 {{\$d[0-9]+}}, 11, {{\$s[0-9]+}}, 43, 1;
define void @test_activelaneshuffle_b64_irii(i64 addrspace(1)* %out, i32 %src1) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.b64(i64 11, i32 %src1, i64 43, i1 true) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; --------------------------------------------------------------------------------

declare i32 @llvm.HSAIL.activelaneshuffle.width.b32(i32, i32, i32, i1) #0
declare i64 @llvm.HSAIL.activelaneshuffle.width.b64(i64, i32, i64, i1) #0

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b32_iiii(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b32 {{\$s[0-9]+}}, 0, 0, 0, 0;
define void @test_activelaneshuffle_width_b32_iiii(i32 addrspace(1)* %out) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.width.b32(i32 0, i32 0, i32 0, i1 false) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b32_rrrr(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$c[0-9]+}};
define void @test_activelaneshuffle_width_b32_rrrr(i32 addrspace(1)* %out, i32 %src0, i32 %src1, i32 %src2, i1 %src3) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.width.b32(i32 %src0, i32 %src1, i32 %src2, i1 %src3) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b32_irrr(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b32 {{\$s[0-9]+}}, 10, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$c[0-9]+}};
define void @test_activelaneshuffle_width_b32_irrr(i32 addrspace(1)* %out, i32 %src1, i32 %src2, i1 %src3) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.width.b32(i32 10, i32 %src1, i32 %src2, i1 %src3) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b32_rirr(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 7, {{\$s[0-9]+}}, {{\$c[0-9]+}};
define void @test_activelaneshuffle_width_b32_rirr(i32 addrspace(1)* %out, i32 %src0, i32 %src2, i1 %src3) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.width.b32(i32 %src0, i32 7, i32 %src2, i1 %src3) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b32_rrir(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, 3, {{\$c[0-9]+}};
define void @test_activelaneshuffle_width_b32_rrir(i32 addrspace(1)* %out, i32 %src0, i32 %src1, i1 %src3) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.width.b32(i32 %src0, i32 %src1, i32 3, i1 %src3) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b32_rrri(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, 1;
define void @test_activelaneshuffle_width_b32_rrri(i32 addrspace(1)* %out, i32 %src0, i32 %src1, i32 %src2) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.width.b32(i32 %src0, i32 %src1, i32 %src2, i1 true) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b32_iirr(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b32 {{\$s[0-9]+}}, 9, 13, {{\$s[0-9]+}}, {{\$c[0-9]+}};
define void @test_activelaneshuffle_width_b32_iirr(i32 addrspace(1)* %out, i32 %src2, i1 %src3) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.width.b32(i32 9, i32 13, i32 %src2, i1 %src3) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b32_riir(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 13, 56, {{\$c[0-9]+}};
define void @test_activelaneshuffle_width_b32_riir(i32 addrspace(1)* %out, i32 %src0, i1 %src3) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.width.b32(i32 %src0, i32 13, i32 56, i1 %src3) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b32_rrii(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, {{\$s[0-9]+}}, 23, 1;
define void @test_activelaneshuffle_width_b32_rrii(i32 addrspace(1)* %out, i32 %src0, i32 %src1) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.width.b32(i32 %src0, i32 %src1, i32 23, i1 true) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b32_irir(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b32 {{\$s[0-9]+}}, 11, {{\$s[0-9]+}}, 43, {{\$c[0-9]+}};
define void @test_activelaneshuffle_width_b32_irir(i32 addrspace(1)* %out, i32 %src1, i1 %src3) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.width.b32(i32 11, i32 %src1, i32 43, i1 %src3) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b32_riri(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 11, {{\$s[0-9]+}}, 0;
define void @test_activelaneshuffle_width_b32_riri(i32 addrspace(1)* %out, i32 %src0, i32 %src2) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.width.b32(i32 %src0, i32 11, i32 %src2, i1 false) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b32_irri(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b32 {{\$s[0-9]+}}, 17, {{\$s[0-9]+}}, {{\$s[0-9]+}}, 0;
define void @test_activelaneshuffle_width_b32_irri(i32 addrspace(1)* %out, i32 %src1, i32 %src2) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.width.b32(i32 17, i32 %src1, i32 %src2, i1 false) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b32_iiir(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b32 {{\$s[0-9]+}}, 11, 9, 43, {{\$c[0-9]+}};
define void @test_activelaneshuffle_width_b32_iiir(i32 addrspace(1)* %out, i1 %src3) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.width.b32(i32 11, i32 9, i32 43, i1 %src3) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b32_riii(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b32 {{\$s[0-9]+}}, {{\$s[0-9]+}}, 11, 22, 0;
define void @test_activelaneshuffle_width_b32_riii(i32 addrspace(1)* %out, i32 %src0, i32 %src2) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.width.b32(i32 %src0, i32 11, i32 22, i1 false) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b32_iiri(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b32 {{\$s[0-9]+}}, 3, 11, {{\$s[0-9]+}}, 0;
define void @test_activelaneshuffle_width_b32_iiri(i32 addrspace(1)* %out, i32 %src2) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.width.b32(i32 3, i32 11, i32 %src2, i1 false) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b32_irii(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b32 {{\$s[0-9]+}}, 11, {{\$s[0-9]+}}, 43, 1;
define void @test_activelaneshuffle_width_b32_irii(i32 addrspace(1)* %out, i32 %src1) #0 {
  %tmp0 = call i32 @llvm.HSAIL.activelaneshuffle.width.b32(i32 11, i32 %src1, i32 43, i1 true) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b64_iiii(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b64 {{\$d[0-9]+}}, 0, 0, 0, 0;
define void @test_activelaneshuffle_width_b64_iiii(i64 addrspace(1)* %out) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.width.b64(i64 0, i32 0, i64 0, i1 false) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b64_rrrr(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$s[0-9]+}}, {{\$d[0-9]+}}, {{\$c[0-9]+}};
define void @test_activelaneshuffle_width_b64_rrrr(i64 addrspace(1)* %out, i64 %src0, i32 %src1, i64 %src2, i1 %src3) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.width.b64(i64 %src0, i32 %src1, i64 %src2, i1 %src3) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b64_irrr(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b64 {{\$d[0-9]+}}, 10, {{\$s[0-9]+}}, {{\$d[0-9]+}}, {{\$c[0-9]+}};
define void @test_activelaneshuffle_width_b64_irrr(i64 addrspace(1)* %out, i32 %src1, i64 %src2, i1 %src3) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.width.b64(i64 10, i32 %src1, i64 %src2, i1 %src3) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b64_rirr(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 7, {{\$d[0-9]+}}, {{\$c[0-9]+}};
define void @test_activelaneshuffle_width_b64_rirr(i64 addrspace(1)* %out, i64 %src0, i64 %src2, i1 %src3) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.width.b64(i64 %src0, i32 7, i64 %src2, i1 %src3) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b64_rrir(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$s[0-9]+}}, 3, {{\$c[0-9]+}};
define void @test_activelaneshuffle_width_b64_rrir(i64 addrspace(1)* %out, i64 %src0, i32 %src1, i1 %src3) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.width.b64(i64 %src0, i32 %src1, i64 3, i1 %src3) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b64_rrri(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$s[0-9]+}}, {{\$d[0-9]+}}, 1;
define void @test_activelaneshuffle_width_b64_rrri(i64 addrspace(1)* %out, i64 %src0, i32 %src1, i64 %src2) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.width.b64(i64 %src0, i32 %src1, i64 %src2, i1 true) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b64_iirr(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b64 {{\$d[0-9]+}}, 9, 13, {{\$d[0-9]+}}, {{\$c[0-9]+}};
define void @test_activelaneshuffle_width_b64_iirr(i64 addrspace(1)* %out, i64 %src2, i1 %src3) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.width.b64(i64 9, i32 13, i64 %src2, i1 %src3) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b64_riir(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 13, 56, {{\$c[0-9]+}};
define void @test_activelaneshuffle_width_b64_riir(i64 addrspace(1)* %out, i64 %src0, i1 %src3) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.width.b64(i64 %src0, i32 13, i64 56, i1 %src3) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b64_rrii(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$s[0-9]+}}, 23, 1;
define void @test_activelaneshuffle_width_b64_rrii(i64 addrspace(1)* %out, i64 %src0, i32 %src1) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.width.b64(i64 %src0, i32 %src1, i64 23, i1 true) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b64_irir(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b64 {{\$d[0-9]+}}, 11, {{\$s[0-9]+}}, 43, {{\$c[0-9]+}};
define void @test_activelaneshuffle_width_b64_irir(i64 addrspace(1)* %out, i32 %src1, i1 %src3) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.width.b64(i64 11, i32 %src1, i64 43, i1 %src3) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b64_riri(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 11, {{\$d[0-9]+}}, 0;
define void @test_activelaneshuffle_width_b64_riri(i64 addrspace(1)* %out, i64 %src0, i64 %src2) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.width.b64(i64 %src0, i32 11, i64 %src2, i1 false) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b64_irri(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b64 {{\$d[0-9]+}}, 17, {{\$s[0-9]+}}, {{\$d[0-9]+}}, 0;
define void @test_activelaneshuffle_width_b64_irri(i64 addrspace(1)* %out, i32 %src1, i64 %src2) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.width.b64(i64 17, i32 %src1, i64 %src2, i1 false) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b64_iiir(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b64 {{\$d[0-9]+}}, 11, 9, 43, {{\$c[0-9]+}};
define void @test_activelaneshuffle_width_b64_iiir(i64 addrspace(1)* %out, i1 %src3) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.width.b64(i64 11, i32 9, i64 43, i1 %src3) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b64_riii(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 11, 22, 0;
define void @test_activelaneshuffle_width_b64_riii(i64 addrspace(1)* %out, i64 %src0, i64 %src2) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.width.b64(i64 %src0, i32 11, i64 22, i1 false) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b64_iiri(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b64 {{\$d[0-9]+}}, 3, 11, {{\$d[0-9]+}}, 0;
define void @test_activelaneshuffle_width_b64_iiri(i64 addrspace(1)* %out, i64 %src2) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.width.b64(i64 3, i32 11, i64 %src2, i1 false) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelaneshuffle_width_b64_irii(
; HSAIL: activelaneshuffle_width(WAVESIZE)_b64 {{\$d[0-9]+}}, 11, {{\$s[0-9]+}}, 43, 1;
define void @test_activelaneshuffle_width_b64_irii(i64 addrspace(1)* %out, i32 %src1) #0 {
  %tmp0 = call i64 @llvm.HSAIL.activelaneshuffle.width.b64(i64 11, i32 %src1, i64 43, i1 true) #0
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

attributes #0 = { nounwind }
