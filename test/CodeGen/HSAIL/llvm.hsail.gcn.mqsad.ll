; RUN: llc -march=hsail -mattr=+gcn -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i64 @llvm.hsail.gcn.mqsad(i64, i32, i64) #0
declare i64 @llvm.HSAIL.mqsad(i64, i32, i64) #0

; HSAIL-LABEL: {{^}}prog function &test_mqsad_i64(
; HSAIL: gcn_mqsad_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$s[0-9]+}}, {{\$d[0-9]+}};
define i64 @test_mqsad_i64(i64 %x, i32 %y, i64 %z) #0 {
  %val = call i64 @llvm.hsail.gcn.mqsad(i64 %x, i32 %y, i64 %z) #0
  ret i64 %val
}

; HSAIL-LABEL: {{^}}prog function &test_mqsad_i64_rii(
; HSAIL: gcn_mqsad_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$s[0-9]+}}, {{\$d[0-9]+}};
define i64 @test_mqsad_i64_rii(i64 %x) #0 {
  %val = call i64 @llvm.hsail.gcn.mqsad(i64 %x, i32 16777216, i64 2) #0
  ret i64 %val
}

; HSAIL-LABEL: {{^}}prog function &test_mqsad_i64_rir(
; HSAIL: gcn_mqsad_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$s[0-9]+}}, {{\$d[0-9]+}};
define i64 @test_mqsad_i64_rir(i64 %x, i64 %y) #0 {
  %val = call i64 @llvm.hsail.gcn.mqsad(i64 %x, i32 1, i64 %y) #0
  ret i64 %val
}

; HSAIL-LABEL: {{^}}prog function &test_mqsad_i64_rri(
; HSAIL: gcn_mqsad_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$s[0-9]+}}, {{\$d[0-9]+}};
define i64 @test_mqsad_i64_rri(i64 %x, i32 %y) #0 {
  %val = call i64 @llvm.hsail.gcn.mqsad(i64 %x, i32 %y, i64 7) #0
  ret i64 %val
}

; HSAIL-LABEL: {{^}}prog function &test_mqsad_i64_iri(
; HSAIL: gcn_mqsad_b64 {{\$d[0-9]+}}, 342421, {{\$s[0-9]+}}, {{\$d[0-9]+}};
define i64 @test_mqsad_i64_iri(i32 %x) #0 {
  %val = call i64 @llvm.hsail.gcn.mqsad(i64 342421, i32 %x, i64 9) #0
  ret i64 %val
}

; HSAIL-LABEL: {{^}}prog function &test_mqsad_i64_iir(
; HSAIL: gcn_mqsad_b64 {{\$d[0-9]+}}, 256, {{\$s[0-9]+}}, {{\$d[0-9]+}};
define i64 @test_mqsad_i64_iir(i64 %x) #0 {
  %val = call i64 @llvm.hsail.gcn.mqsad(i64 256, i32 65536, i64 %x) #0
  ret i64 %val
}

; HSAIL-LABEL: {{^}}prog function &test_mqsad_i64_iii(
; HSAIL: gcn_mqsad_b64 {{\$d[0-9]+}}, 3, {{\$s[0-9]+}}, {{\$d[0-9]+}};
define i64 @test_mqsad_i64_iii() #0 {
  %val = call i64 @llvm.hsail.gcn.mqsad(i64 3, i32 1234, i64 11) #0
  ret i64 %val
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_mqsad_i64(
; HSAIL: gcn_mqsad_b64 {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$s[0-9]+}}, {{\$d[0-9]+}};
define i64 @test_legacy_mqsad_i64(i64 %x, i32 %y, i64 %z) #0 {
  %val = call i64 @llvm.HSAIL.mqsad(i64 %x, i32 %y, i64 %z) #0
  ret i64 %val
}

attributes #0 = { nounwind readnone }
