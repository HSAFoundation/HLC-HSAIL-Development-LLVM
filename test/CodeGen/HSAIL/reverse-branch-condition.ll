; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL %s

; FUNC-LABEL: {{^}}prog function &test_inv_branch_i32_eq(
; HSAIL-DAG: ld_arg_align(4)_u32 [[VAL0:\$s[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(4)_u32 [[VAL1:\$s[0-9]+]], [%val1];
; HSAIL: cmp_ne_b1_s32 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_i32_eq(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, i32 %val0, i32 %val1) nounwind {
  %cmp = icmp eq i32 %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_inv_branch_i32_ne(
; HSAIL-DAG: ld_arg_align(4)_u32 [[VAL0:\$s[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(4)_u32 [[VAL1:\$s[0-9]+]], [%val1];
; HSAIL: cmp_eq_b1_s32 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_i32_ne(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, i32 %val0, i32 %val1) nounwind {
  %cmp = icmp ne i32 %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_inv_branch_i32_ugt(
; HSAIL-DAG: ld_arg_align(4)_u32 [[VAL0:\$s[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(4)_u32 [[VAL1:\$s[0-9]+]], [%val1];
; HSAIL: cmp_le_b1_u32 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_i32_ugt(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, i32 %val0, i32 %val1) nounwind {
  %cmp = icmp ugt i32 %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_inv_branch_i32_uge(
; HSAIL-DAG: ld_arg_align(4)_u32 [[VAL0:\$s[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(4)_u32 [[VAL1:\$s[0-9]+]], [%val1];
; HSAIL: cmp_lt_b1_u32 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_i32_uge(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, i32 %val0, i32 %val1) nounwind {
  %cmp = icmp uge i32 %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_inv_branch_i32_ult(
; HSAIL-DAG: ld_arg_align(4)_u32 [[VAL0:\$s[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(4)_u32 [[VAL1:\$s[0-9]+]], [%val1];
; HSAIL: cmp_ge_b1_u32 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_i32_ult(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, i32 %val0, i32 %val1) nounwind {
  %cmp = icmp ult i32 %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_inv_branch_i32_ule(
; HSAIL-DAG: ld_arg_align(4)_u32 [[VAL0:\$s[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(4)_u32 [[VAL1:\$s[0-9]+]], [%val1];
; HSAIL: cmp_gt_b1_u32 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_i32_ule(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, i32 %val0, i32 %val1) nounwind {
  %cmp = icmp ule i32 %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_inv_branch_i32_sgt(
; HSAIL-DAG: ld_arg_align(4)_u32 [[VAL0:\$s[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(4)_u32 [[VAL1:\$s[0-9]+]], [%val1];
; HSAIL: cmp_le_b1_s32 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_i32_sgt(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, i32 %val0, i32 %val1) nounwind {
  %cmp = icmp sgt i32 %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_inv_branch_i32_sge(
; HSAIL-DAG: ld_arg_align(4)_u32 [[VAL0:\$s[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(4)_u32 [[VAL1:\$s[0-9]+]], [%val1];
; HSAIL: cmp_lt_b1_s32 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_i32_sge(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, i32 %val0, i32 %val1) nounwind {
  %cmp = icmp sge i32 %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_inv_branch_i32_slt(
; HSAIL-DAG: ld_arg_align(4)_u32 [[VAL0:\$s[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(4)_u32 [[VAL1:\$s[0-9]+]], [%val1];
; HSAIL: cmp_ge_b1_s32 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_i32_slt(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, i32 %val0, i32 %val1) nounwind {
  %cmp = icmp slt i32 %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_inv_branch_i32_sle(
; HSAIL-DAG: ld_arg_align(4)_u32 [[VAL0:\$s[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(4)_u32 [[VAL1:\$s[0-9]+]], [%val1];
; HSAIL: cmp_gt_b1_s32 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_i32_sle(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, i32 %val0, i32 %val1) nounwind {
  %cmp = icmp sle i32 %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_inv_branch_f64_oeq(
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL0:\$d[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL1:\$d[0-9]+]], [%val1];
; HSAIL: cmp_neu_b1_f64 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_f64_oeq(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, double %val0, double %val1) nounwind {
  %cmp = fcmp oeq double %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_inv_branch_f64_ogt(
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL0:\$d[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL1:\$d[0-9]+]], [%val1];
; HSAIL: cmp_leu_b1_f64 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_f64_ogt(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, double %val0, double %val1) nounwind {
  %cmp = fcmp ogt double %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_inv_branch_f64_oge(
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL0:\$d[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL1:\$d[0-9]+]], [%val1];
; HSAIL: cmp_ltu_b1_f64 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_f64_oge(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, double %val0, double %val1) nounwind {
  %cmp = fcmp oge double %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_inv_branch_f64_olt(
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL0:\$d[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL1:\$d[0-9]+]], [%val1];
; HSAIL: cmp_geu_b1_f64 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_f64_olt(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, double %val0, double %val1) nounwind {
  %cmp = fcmp olt double %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_inv_branch_f64_ole(
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL0:\$d[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL1:\$d[0-9]+]], [%val1];
; HSAIL: cmp_gtu_b1_f64 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_f64_ole(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, double %val0, double %val1) nounwind {
  %cmp = fcmp ole double %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_inv_branch_f64_one(
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL0:\$d[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL1:\$d[0-9]+]], [%val1];
; HSAIL: cmp_equ_b1_f64 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_f64_one(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, double %val0, double %val1) nounwind {
  %cmp = fcmp one double %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_inv_branch_f64_ord(
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL0:\$d[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL1:\$d[0-9]+]], [%val1];
; HSAIL: cmp_nan_b1_f64 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_f64_ord(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, double %val0, double %val1) nounwind {
  %cmp = fcmp ord double %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_inv_branch_f64_ueq(
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL0:\$d[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL1:\$d[0-9]+]], [%val1];
; HSAIL: cmp_ne_b1_f64 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_f64_ueq(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, double %val0, double %val1) nounwind {
  %cmp = fcmp ueq double %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_inv_branch_f64_ugt(
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL0:\$d[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL1:\$d[0-9]+]], [%val1];
; HSAIL: cmp_le_b1_f64 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_f64_ugt(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, double %val0, double %val1) nounwind {
  %cmp = fcmp ugt double %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_inv_branch_f64_uge(
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL0:\$d[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL1:\$d[0-9]+]], [%val1];
; HSAIL: cmp_lt_b1_f64 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_f64_uge(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, double %val0, double %val1) nounwind {
  %cmp = fcmp uge double %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_inv_branch_f64_ult(
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL0:\$d[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL1:\$d[0-9]+]], [%val1];
; HSAIL: cmp_ge_b1_f64 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_f64_ult(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, double %val0, double %val1) nounwind {
  %cmp = fcmp ult double %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_inv_branch_f64_ule(
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL0:\$d[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL1:\$d[0-9]+]], [%val1];
; HSAIL: cmp_gt_b1_f64 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_f64_ule(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, double %val0, double %val1) nounwind {
  %cmp = fcmp ule double %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_inv_branch_f64_une(
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL0:\$d[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL1:\$d[0-9]+]], [%val1];
; HSAIL: cmp_eq_b1_f64 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_f64_une(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, double %val0, double %val1) nounwind {
  %cmp = fcmp une double %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}

; FUNC-LABEL: {{^}}prog function &test_inv_branch_f64_uno(
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL0:\$d[0-9]+]], [%val0];
; HSAIL-DAG: ld_arg_align(8)_f64 [[VAL1:\$d[0-9]+]], [%val1];
; HSAIL: cmp_num_b1_f64 [[CMP:\$c[0-9]+]], [[VAL0]], [[VAL1]];
; HSAIL: cbr_b1 [[CMP]], @BB[[FNNUM:[0-9]+]]_2;
; HSAIL: st_global_align(4)_u32 222
; HSAIL: {{^@BB}}[[FNNUM]]{{_2:}}
; HSAIL: ret;
define void @test_inv_branch_f64_uno(i32 addrspace(1)* noalias %out, i32 addrspace(1)* noalias %in, double %val0, double %val1) nounwind {
  %cmp = fcmp uno double %val0, %val1
  br i1 %cmp, label %store, label %end

store:
  store i32 222, i32 addrspace(1)* %out
  ret void

end:
  ret void
}
