; RUN: llc -march=hsail < %s | FileCheck %s

; CHECK-LABEL: {{^}}prog function &shiftl64_ir(
; CHECK: {{shl_u64 \$d[0-9]+, 9756277979052589857, \$s[0-9]+;}}
define void @shiftl64_ir(i64 addrspace(1)* nocapture %out, i64 %amt) nounwind {
  %tmp2 = and i64 %amt, 63
  %tmp3 = shl i64 -8690466094656961759, %tmp2
  store i64 %tmp3, i64 addrspace(1)* %out, align 8
  ret void
}

; CHECK-LABEL: {{^}}prog function &shiftl64_ri(
; CHECK: {{shl_u64 \$d[0-9]+, \$d[0-9], 1;}}
define void @shiftl64_ri(i64 addrspace(1)* nocapture %out, i64 %val) nounwind {
  %tmp2 = shl i64 %val, 1
  store i64 %tmp2, i64 addrspace(1)* %out, align 8
  ret void
}

; CHECK-LABEL: {{^}}prog function &shiftl64_rr(
; CHECK: {{shl_u64 \$d[0-9]+, \$d[0-9], \$s[0-9]+;}}
define void @shiftl64_rr(i64 addrspace(1)* nocapture %out, i64 %val, i64 %amt) nounwind {
  %tmp3 = and i64 %amt, 63
  %tmp4 = shl i64 %val, %tmp3
  store i64 %tmp4, i64 addrspace(1)* %out, align 8
  ret void
}

; CHECK-LABEL: {{^}}prog function &shiftr64s_ir(
; CHECK: {{shr_s64 \$d[0-9]+, -8690466094656961759, \$s[0-9]+;}}
define void @shiftr64s_ir(i64 addrspace(1)* nocapture %out, i64 %amt) nounwind {
  %tmp2 = and i64 %amt, 63
  %tmp3 = ashr i64 -8690466094656961759, %tmp2
  store i64 %tmp3, i64 addrspace(1)* %out, align 8
  ret void
}

; CHECK-LABEL: {{^}}prog function &shiftr64s_ri(
; CHECK: {{shr_s64 \$d[0-9]+, \$d[0-9], 1;}}
define void @shiftr64s_ri(i64 addrspace(1)* nocapture %out, i64 %val) nounwind {
  %tmp2 = ashr i64 %val, 1
  store i64 %tmp2, i64 addrspace(1)* %out, align 8
  ret void
}

; CHECK-LABEL: {{^}}prog function &shiftr64s_rr(
; CHECK: {{shr_s64 \$d[0-9]+, \$d[0-9], \$s[0-9]+;}}
define void @shiftr64s_rr(i64 addrspace(1)* nocapture %out, i64 %val, i64 %amt) nounwind {
  %tmp3 = and i64 %amt, 63
  %tmp4 = ashr i64 %val, %tmp3
  store i64 %tmp4, i64 addrspace(1)* %out, align 8
  ret void
}

; CHECK-LABEL: {{^}}prog function &shiftr64u_ir(
; CHECK: {{shr_u64 \$d[0-9]+, 9756277979052589857, \$s[0-9]+;}}
define void @shiftr64u_ir(i64 addrspace(1)* nocapture %out, i64 %amt) nounwind {
  %tmp2 = and i64 %amt, 63
  %tmp3 = lshr i64 -8690466094656961759, %tmp2
  store i64 %tmp3, i64 addrspace(1)* %out, align 8
  ret void
}

; CHECK-LABEL: {{^}}prog function &shiftr64u_ri(
; CHECK: {{shr_u64 \$d[0-9]+, \$d[0-9], 1;}}
define void @shiftr64u_ri(i64 addrspace(1)* nocapture %out, i64 %val) nounwind {
  %tmp2 = lshr i64 %val, 1
  store i64 %tmp2, i64 addrspace(1)* %out, align 8
  ret void
}

; CHECK-LABEL: {{^}}prog function &shiftr64u_rr(
; CHECK: {{shr_u64 \$d[0-9]+, \$d[0-9], \$s[0-9]+;}}
define void @shiftr64u_rr(i64 addrspace(1)* nocapture %out, i64 %val, i64 %amt) nounwind {
  %tmp3 = and i64 %amt, 63
  %tmp4 = lshr i64 %val, %tmp3
  store i64 %tmp4, i64 addrspace(1)* %out, align 8
  ret void
}
