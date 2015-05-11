; RUN: llc -march=hsail < %s | FileCheck -check-prefix=NONE %s
; RUN: llc -march=hsail -mattr=+gcn < %s | FileCheck -check-prefix=GCN %s
; RUN: llc -march=hsail -mattr=+images < %s | FileCheck -check-prefix=IMAGES %s
; RUN: llc -march=hsail -mattr=+gcn,+images < %s | FileCheck -check-prefix=GCN -check-prefix=IMAGES %s
; RUN: llc -march=hsail -mcpu=kaveri < %s | FileCheck -check-prefix=GCN -check-prefix=IMAGES %s

; NONE-NOT: extension
; GCN: extension "amd:gcn";
; IMAGES: extension "IMAGE";

; We must have at least one function for subtarget features to be
; detected for the module.
define void @foo() {
  ret void
}
