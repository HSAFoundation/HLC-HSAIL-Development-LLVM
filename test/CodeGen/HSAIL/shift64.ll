; RUN: llc < %s -march=hsail | FileCheck %s

define void @__OpenCL_shiftl64_ir_kernel(i64 addrspace(1)* nocapture %out, i64 %amt) nounwind {
; CHECK-LABEL: shiftl64_ir
; CHECK: {{shl_u64 \$d[0-9]+, 9756277979052589857, \$s[0-9]+;}}
entry:
  %tmp2 = and i64 %amt, 63
  %tmp3 = shl i64 -8690466094656961759, %tmp2
  store i64 %tmp3, i64 addrspace(1)* %out, align 8
  ret void
}

define void @__OpenCL_shiftl64_ri_kernel(i64 addrspace(1)* nocapture %out, i64 %val) nounwind {
; CHECK-LABEL: shiftl64_ri
; CHECK: {{shl_u64 \$d[0-9]+, \$d[0-9], 1;}}
entry:
  %tmp2 = shl i64 %val, 1
  store i64 %tmp2, i64 addrspace(1)* %out, align 8
  ret void
}

define void @__OpenCL_shiftl64_rr_kernel(i64 addrspace(1)* nocapture %out, i64 %val, i64 %amt) nounwind {
; CHECK-LABEL: shiftl64_rr
; CHECK: {{shl_u64 \$d[0-9]+, \$d[0-9], \$s[0-9]+;}}
entry:
  %tmp3 = and i64 %amt, 63
  %tmp4 = shl i64 %val, %tmp3
  store i64 %tmp4, i64 addrspace(1)* %out, align 8
  ret void
}

define void @__OpenCL_shiftr64s_ir_kernel(i64 addrspace(1)* nocapture %out, i64 %amt) nounwind {
; CHECK-LABEL: shiftr64s_ir
; CHECK: {{shr_s64 \$d[0-9]+, -8690466094656961759, \$s[0-9]+;}}
entry:
  %tmp2 = and i64 %amt, 63
  %tmp3 = ashr i64 -8690466094656961759, %tmp2
  store i64 %tmp3, i64 addrspace(1)* %out, align 8
  ret void
}

define void @__OpenCL_shiftr64s_ri_kernel(i64 addrspace(1)* nocapture %out, i64 %val) nounwind {
; CHECK-LABEL: shiftr64s_ri
; CHECK: {{shr_s64 \$d[0-9]+, \$d[0-9], 1;}}
entry:
  %tmp2 = ashr i64 %val, 1
  store i64 %tmp2, i64 addrspace(1)* %out, align 8
  ret void
}

define void @__OpenCL_shiftr64s_rr_kernel(i64 addrspace(1)* nocapture %out, i64 %val, i64 %amt) nounwind {
; CHECK-LABEL: shiftr64s_rr
; CHECK: {{shr_s64 \$d[0-9]+, \$d[0-9], \$s[0-9]+;}}
entry:
  %tmp3 = and i64 %amt, 63
  %tmp4 = ashr i64 %val, %tmp3
  store i64 %tmp4, i64 addrspace(1)* %out, align 8
  ret void
}

define void @__OpenCL_shiftr64u_ir_kernel(i64 addrspace(1)* nocapture %out, i64 %amt) nounwind {
; CHECK-LABEL: shiftr64u_ir
; CHECK: {{shr_u64 \$d[0-9]+, 9756277979052589857, \$s[0-9]+;}}
entry:
  %tmp2 = and i64 %amt, 63
  %tmp3 = lshr i64 -8690466094656961759, %tmp2
  store i64 %tmp3, i64 addrspace(1)* %out, align 8
  ret void
}

define void @__OpenCL_shiftr64u_ri_kernel(i64 addrspace(1)* nocapture %out, i64 %val) nounwind {
; CHECK-LABEL: shiftr64u_ri
; CHECK: {{shr_u64 \$d[0-9]+, \$d[0-9], 1;}}
entry:
  %tmp2 = lshr i64 %val, 1
  store i64 %tmp2, i64 addrspace(1)* %out, align 8
  ret void
}

define void @__OpenCL_shiftr64u_rr_kernel(i64 addrspace(1)* nocapture %out, i64 %val, i64 %amt) nounwind {
; CHECK-LABEL: shiftr64u_rr
; CHECK: {{shr_u64 \$d[0-9]+, \$d[0-9], \$s[0-9]+;}}
entry:
  %tmp3 = and i64 %amt, 63
  %tmp4 = lshr i64 %val, %tmp3
  store i64 %tmp4, i64 addrspace(1)* %out, align 8
  ret void
}
