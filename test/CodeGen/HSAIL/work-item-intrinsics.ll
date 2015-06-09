; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

;

; FUNC-LABEL: {{^}}prog function &tidig_out_of_range
; HSAIL-NOT: workitemabsid_u32
; HSAIL: ret;
define void @tidig_out_of_range(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.global.id(i32 3) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; Undefined
; FUNC-LABEL: {{^}}prog function &tidig_reg
; HSAIL-NOT: workitemabsid
; HSAIL: ret;
define void @tidig_reg(i32 addrspace(1)* %out, i32 %dim) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.global.id(i32 %dim) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

declare i32 @llvm.HSAIL.get.global.id(i32) #0

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
