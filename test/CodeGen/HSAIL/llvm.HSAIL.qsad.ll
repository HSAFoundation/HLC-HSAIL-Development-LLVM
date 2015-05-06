; RUN: llc -march=hsail -mattr=+gcn -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i64 @llvm.HSAIL.qsad(i64, i64, i64) #0

; HSAIL-LABEL: {{^}}prog function &test_qsad_i64(
; HSAIL: gcn_qsad_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}};
define i64 @test_qsad_i64(i64 %x, i64 %y, i64 %z) #0 {
  %val = call i64 @llvm.HSAIL.qsad(i64 %x, i64 %y, i64 %z) #0
  ret i64 %val
}

; HSAIL-LABEL: {{^}}prog function &test_qsad_i64_rii(
; HSAIL: gcn_qsad_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 16777216, 2;
define i64 @test_qsad_i64_rii(i64 %x) #0 {
  %val = call i64 @llvm.HSAIL.qsad(i64 %x, i64 16777216, i64 2) #0
  ret i64 %val
}

; HSAIL-LABEL: {{^}}prog function &test_qsad_i64_rir(
; HSAIL: gcn_qsad_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, 1, {{\$d[0-9]+}};
define i64 @test_qsad_i64_rir(i64 %x, i64 %y) #0 {
  %val = call i64 @llvm.HSAIL.qsad(i64 %x, i64 1, i64 %y) #0
  ret i64 %val
}

; HSAIL-LABEL: {{^}}prog function &test_qsad_i64_rri(
; HSAIL: gcn_qsad_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}, 7;
define i64 @test_qsad_i64_rri(i64 %x, i64 %y) #0 {
  %val = call i64 @llvm.HSAIL.qsad(i64 %x, i64 %y, i64 7) #0
  ret i64 %val
}

; HSAIL-LABEL: {{^}}prog function &test_qsad_i64_iri(
; HSAIL: gcn_qsad_b64 {{\$d[0-9]+}}, 342421, {{\$d[0-9]+}}, 9;
define i64 @test_qsad_i64_iri(i64 %x) #0 {
  %val = call i64 @llvm.HSAIL.qsad(i64 342421, i64 %x, i64 9) #0
  ret i64 %val
}

; HSAIL-LABEL: {{^}}prog function &test_qsad_i64_iir(
; HSAIL: gcn_qsad_b64 {{\$d[0-9]+}}, 256, 65536, {{\$d[0-9]+}};
define i64 @test_qsad_i64_iir(i64 %x) #0 {
  %val = call i64 @llvm.HSAIL.qsad(i64 256, i64 65536, i64 %x) #0
  ret i64 %val
}

; HSAIL-LABEL: {{^}}prog function &test_qsad_i64_iii(
; HSAIL: gcn_qsad_b64 {{\$d[0-9]+}}, 3, 1234, 11;
define i64 @test_qsad_i64_iii() #0 {
  %val = call i64 @llvm.HSAIL.qsad(i64 3, i64 1234, i64 11) #0
  ret i64 %val
}

attributes #0 = { nounwind readnone }
