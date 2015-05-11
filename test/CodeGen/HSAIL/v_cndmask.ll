; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &v_cnd_nan
; HSAIL: cmp_ne_b1_s32  {{\$c[0-9]+}}, {{\$s[0-9]+}}, 0;
; HSAIL: cmov_b32  {{\$s[0-9]+}}, {{\$c[0-9]+}}, 4294967295, {{\$s[0-9]+}};
define void @v_cnd_nan(float addrspace(1)* %out, i32 %c, float %f) {
  %tmp0 = icmp ne i32 %c, 0
  %tmp1 = select i1 %tmp0, float 0xFFFFFFFFE0000000, float %f
  store float %tmp1, float addrspace(1)* %out
  ret void
}
