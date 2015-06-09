; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.hsail.activelanecount(i32, i1) #1

declare i32 @llvm.HSAIL.activelanecount.u32.b1(i1) #0
declare i32 @llvm.HSAIL.activelanecount.width.u32.b1(i1) #0

; HSAIL-LABEL: {{^}}prog function &test_activelanecount_u32(
; HSAIL: activelanecount_u32_b1 {{\$s[0-9]+}}, {{\$c[0-9]+}};
define void @test_activelanecount_u32(i32 addrspace(1)* %out, i32 %x) #0 {
  %cmp = icmp eq i32 %x, 0
  %tmp = call i32 @llvm.hsail.activelanecount(i32 1, i1 %cmp) #0
  store i32 %tmp, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelanecount_wavesize_u32(
; HSAIL: activelanecount_width(WAVESIZE)_u32_b1 {{\$s[0-9]+}}, {{\$c[0-9]+}};
define void @test_activelanecount_wavesize_u32(i32 addrspace(1)* %out, i32 %x) #0 {
  %cmp = icmp eq i32 %x, 0
  %tmp = call i32 @llvm.hsail.activelanecount(i32 33, i1 %cmp) #0
  store i32 %tmp, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelanecount_all_u32(
; HSAIL: activelanecount_width(all)_u32_b1 {{\$s[0-9]+}}, {{\$c[0-9]+}};
define void @test_activelanecount_all_u32(i32 addrspace(1)* %out, i32 %x) #0 {
  %cmp = icmp eq i32 %x, 0
  %tmp = call i32 @llvm.hsail.activelanecount(i32 34, i1 %cmp) #0
  store i32 %tmp, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelanecount_u32_imm(
; HSAIL: activelanecount_u32_b1 {{\$s[0-9]+}}, 1;
define void @test_activelanecount_u32_imm(i32 addrspace(1)* %out) #0 {
  %tmp = call i32 @llvm.hsail.activelanecount(i32 1, i1 true) #0
  store i32 %tmp, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_activelanecount_u32(
; HSAIL: activelanecount_u32_b1 {{\$s[0-9]+}}, {{\$c[0-9]+}};
define void @test_legacy_activelanecount_u32(i32 addrspace(1)* %out, i32 %x) #0 {
  %cmp = icmp eq i32 %x, 0
  %tmp = call i32 @llvm.HSAIL.activelanecount.u32.b1(i1 %cmp) #0
  store i32 %tmp, i32 addrspace(1)* %out
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_activelanecount_width_u32(
; HSAIL: activelanecount_width(WAVESIZE)_u32_b1 {{\$s[0-9]+}}, {{\$c[0-9]+}};
define void @test_legacy_activelanecount_width_u32(i32 addrspace(1)* %out, i32 %x) #0 {
  %cmp = icmp eq i32 %x, 0
  %tmp = call i32 @llvm.HSAIL.activelanecount.width.u32.b1(i1 %cmp) #0
  store i32 %tmp, i32 addrspace(1)* %out
  ret void
}

attributes #0 = { nounwind }
attributes #1 = { nounwind readonly convergent }
