; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s
; RUN: llc -march=hsail64 < %s | FileCheck -check-prefix=HSAIL64 %s

; HSAIL: module &__llvm_hsail_module:1:0:$full:$small:$near;
; HSAIL64: module &__llvm_hsail_module:1:0:$full:$large:$near;
