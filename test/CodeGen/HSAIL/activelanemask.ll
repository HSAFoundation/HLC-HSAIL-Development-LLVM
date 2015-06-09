; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; These really return structs of 4 x i64

declare { i64, i64, i64, i64 } @llvm.hsail.activelanemask(i32, i1) #1

declare { i64, i64, i64, i64 } @llvm.HSAIL.activelanemask.v4.b64.b1(i1) #0
declare { i64, i64, i64, i64 } @llvm.HSAIL.activelanemask.v4.width.b64.b1(i1) #0

; HSAIL-LABEL: {{^}}prog function &test_activelanemask_b64(
; HSAIL: activelanemask_v4_b64_b1 ({{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}), {{\$c[0-9]+}};
define void @test_activelanemask_b64(i64 addrspace(1)* %out0,
                                     i64 addrspace(1)* %out1,
                                     i64 addrspace(1)* %out2,
                                     i64 addrspace(1)* %out3,
                                     i32 %x) #0 {
  %cmp = icmp eq i32 %x, 0
  %tmp = call { i64, i64, i64, i64 } @llvm.hsail.activelanemask(i32 1, i1 %cmp) #0
  %elt0 = extractvalue { i64, i64, i64, i64 } %tmp, 0
  %elt1 = extractvalue { i64, i64, i64, i64 } %tmp, 1
  %elt2 = extractvalue { i64, i64, i64, i64 } %tmp, 2
  %elt3 = extractvalue { i64, i64, i64, i64 } %tmp, 3
  store i64 %elt0, i64 addrspace(1)* %out0
  store i64 %elt1, i64 addrspace(1)* %out1
  store i64 %elt2, i64 addrspace(1)* %out2
  store i64 %elt3, i64 addrspace(1)* %out3
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelanemask_wavesize_b64(
; HSAIL: activelanemask_v4_width(WAVESIZE)_b64_b1 ({{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}), {{\$c[0-9]+}};
define void @test_activelanemask_wavesize_b64(i64 addrspace(1)* %out0,
                                              i64 addrspace(1)* %out1,
                                              i64 addrspace(1)* %out2,
                                              i64 addrspace(1)* %out3,
                                              i32 %x) #0 {
  %cmp = icmp eq i32 %x, 0
  %tmp = call { i64, i64, i64, i64 } @llvm.hsail.activelanemask(i32 33, i1 %cmp) #0
  %elt0 = extractvalue { i64, i64, i64, i64 } %tmp, 0
  %elt1 = extractvalue { i64, i64, i64, i64 } %tmp, 1
  %elt2 = extractvalue { i64, i64, i64, i64 } %tmp, 2
  %elt3 = extractvalue { i64, i64, i64, i64 } %tmp, 3
  store i64 %elt0, i64 addrspace(1)* %out0
  store i64 %elt1, i64 addrspace(1)* %out1
  store i64 %elt2, i64 addrspace(1)* %out2
  store i64 %elt3, i64 addrspace(1)* %out3
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelanemask_b64_imm(
; HSAIL: activelanemask_v4_b64_b1 ({{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}), 1;
define void @test_activelanemask_b64_imm(i64 addrspace(1)* %out0,
                                         i64 addrspace(1)* %out1,
                                         i64 addrspace(1)* %out2,
                                         i64 addrspace(1)* %out3) #0 {
  %tmp = call { i64, i64, i64, i64 } @llvm.hsail.activelanemask(i32 1, i1 true) #0
  %elt0 = extractvalue { i64, i64, i64, i64 } %tmp, 0
  %elt1 = extractvalue { i64, i64, i64, i64 } %tmp, 1
  %elt2 = extractvalue { i64, i64, i64, i64 } %tmp, 2
  %elt3 = extractvalue { i64, i64, i64, i64 } %tmp, 3
  store i64 %elt0, i64 addrspace(1)* %out0
  store i64 %elt1, i64 addrspace(1)* %out1
  store i64 %elt2, i64 addrspace(1)* %out2
  store i64 %elt3, i64 addrspace(1)* %out3
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_activelanemask_width_b64(
; HSAIL: activelanemask_v4_width(WAVESIZE)_b64_b1 ({{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}), {{\$c[0-9]+}};
define void @test_activelanemask_width_b64(i64 addrspace(1)* %out0,
                                           i64 addrspace(1)* %out1,
                                           i64 addrspace(1)* %out2,
                                           i64 addrspace(1)* %out3,
                                           i32 %x) #0 {
  %cmp = icmp eq i32 %x, 0
  %tmp = call { i64, i64, i64, i64 } @llvm.HSAIL.activelanemask.v4.width.b64.b1(i1 %cmp) #0
  %elt0 = extractvalue { i64, i64, i64, i64 } %tmp, 0
  %elt1 = extractvalue { i64, i64, i64, i64 } %tmp, 1
  %elt2 = extractvalue { i64, i64, i64, i64 } %tmp, 2
  %elt3 = extractvalue { i64, i64, i64, i64 } %tmp, 3
  store i64 %elt0, i64 addrspace(1)* %out0
  store i64 %elt1, i64 addrspace(1)* %out1
  store i64 %elt2, i64 addrspace(1)* %out2
  store i64 %elt3, i64 addrspace(1)* %out3
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_activelanemask_b64(
; HSAIL: activelanemask_v4_b64_b1 ({{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}), {{\$c[0-9]+}};
define void @test_legacy_activelanemask_b64(i64 addrspace(1)* %out0,
                                            i64 addrspace(1)* %out1,
                                            i64 addrspace(1)* %out2,
                                            i64 addrspace(1)* %out3,
                                            i32 %x) #0 {
  %cmp = icmp eq i32 %x, 0
  %tmp = call { i64, i64, i64, i64 } @llvm.HSAIL.activelanemask.v4.b64.b1(i1 %cmp) #0
  %elt0 = extractvalue { i64, i64, i64, i64 } %tmp, 0
  %elt1 = extractvalue { i64, i64, i64, i64 } %tmp, 1
  %elt2 = extractvalue { i64, i64, i64, i64 } %tmp, 2
  %elt3 = extractvalue { i64, i64, i64, i64 } %tmp, 3
  store i64 %elt0, i64 addrspace(1)* %out0
  store i64 %elt1, i64 addrspace(1)* %out1
  store i64 %elt2, i64 addrspace(1)* %out2
  store i64 %elt3, i64 addrspace(1)* %out3
  ret void
}

; HSAIL-LABEL: {{^}}prog function &test_legacy_activelanemask_width_b64(
; HSAIL: activelanemask_v4_width(WAVESIZE)_b64_b1 ({{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}, {{\$d[0-9]+}}), {{\$c[0-9]+}};
define void @test_legacy_activelanemask_width_b64(i64 addrspace(1)* %out0,
                                                  i64 addrspace(1)* %out1,
                                                  i64 addrspace(1)* %out2,
                                                  i64 addrspace(1)* %out3,
                                                  i32 %x) #0 {
  %cmp = icmp eq i32 %x, 0
  %tmp = call { i64, i64, i64, i64 } @llvm.HSAIL.activelanemask.v4.width.b64.b1(i1 %cmp) #0
  %elt0 = extractvalue { i64, i64, i64, i64 } %tmp, 0
  %elt1 = extractvalue { i64, i64, i64, i64 } %tmp, 1
  %elt2 = extractvalue { i64, i64, i64, i64 } %tmp, 2
  %elt3 = extractvalue { i64, i64, i64, i64 } %tmp, 3
  store i64 %elt0, i64 addrspace(1)* %out0
  store i64 %elt1, i64 addrspace(1)* %out1
  store i64 %elt2, i64 addrspace(1)* %out2
  store i64 %elt3, i64 addrspace(1)* %out3
  ret void
}

attributes #0 = { nounwind }
attributes #1 = { nounwind readonly convergent }
