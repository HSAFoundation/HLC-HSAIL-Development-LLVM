; XFAIL: *
; RUN: llc -march=hsail < %s

@0 = addrspace(2) global [4 x i32] [ i32 5, i32 4, i32 432, i32 3 ]

@alias = alias [4 x i32] addrspace(2)* @0

define i32 @use_alias_gv() nounwind {
  %gep = getelementptr [4 x i32] addrspace(2)* @alias, i32 0, i32 1
  %load = load i32 addrspace(2)* %gep
  ret i32 %load
}
