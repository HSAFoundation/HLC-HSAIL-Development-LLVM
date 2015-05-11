; RUN: llc -march=hsail -mattr=+gcn -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s
; RUN: llc -march=hsail64 -mattr=+gcn -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

declare i32 @llvm.HSAIL.gcn.atomic.consume.u32(i32 addrspace(5)*) #1

; HSAIL-LABEL: {{^}}prog function &test_atomic_consume_u32(
; HSAIL: gcn_atomic_consume_u32 {{\$s[0-9]+}}, [{{\$s[0-9]+}}+32];
define void @test_atomic_consume_u32(i32 addrspace(1)* %out, i32 addrspace(5)* %in) #1 {
  %gep = getelementptr i32, i32 addrspace(5)* %in, i32 8
  %val = call i32 @llvm.HSAIL.gcn.atomic.consume.u32(i32 addrspace(5)* %gep) #1
  store i32 %val, i32 addrspace(1)* %out
  ret void
}

attributes #1 = { nounwind }
