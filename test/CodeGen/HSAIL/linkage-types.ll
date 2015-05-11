; RUN: llc -march=hsail64 < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL: {{^}}readonly_u32 &private_gv[1] = u32[](1);
@private_gv = private addrspace(2) constant [1 x i32] [i32 1], align 4

; HSAIL: {{^}}readonly_u32 &internal_gv[1] = u32[](1);
@internal_gv = internal addrspace(2) constant [1 x i32] [i32 1], align 4

; HSAIL: {{^}}prog readonly_u32 &available_externally_gv[1] = u32[](1);
@available_externally_gv = available_externally addrspace(2) constant [1 x i32] [i32 1], align 4

; HSAIL: {{^}}readonly_u32 &linkonce_gv[1] = u32[](1);
@linkonce_gv = linkonce addrspace(2) constant [1 x i32] [i32 1], align 4

; HSAIL: {{^}}prog readonly_u32 &weak_gv[1] = u32[](1);
@weak_gv = weak addrspace(2) constant [1 x i32] [i32 1], align 4

; HSAIL: {{^}}readonly_u32 &common_gv[1] = u32[](0);
@common_gv = common addrspace(2) global [1 x i32] zeroinitializer, align 4

; HSAIL: {{^}}prog readonly_u32 &appending_gv[1] = u32[](0);
@appending_gv = appending addrspace(2) global [1 x i32] zeroinitializer, align 4

; HSAIL: {{^}}prog readonly_u32 &extern_weak_gv[1];
@extern_weak_gv = extern_weak addrspace(2) global [1 x i32], align 4

; HSAIL: {{^}}readonly_u32 &linkonce_odr_gv[1] = u32[](1);
@linkonce_odr_gv = linkonce_odr addrspace(2) constant [1 x i32] [i32 1], align 4

; HSAIL: {{^}}prog readonly_u32 &weak_odr_gv[1] = u32[](1);
@weak_odr_gv = weak_odr addrspace(2) constant [1 x i32] [i32 1], align 4

; HSAIL: {{^}}prog readonly_u32 &external_gv[1];
@external_gv = external addrspace(2) global [1 x i32], align 4

; HSAIL: {{^}}decl function &linkonce_odr_func(
; HSAIL: {{^}}function &linkonce_odr_func
define linkonce_odr i32 @linkonce_odr_func(i32) {
  ret i32 undef
}

define i32 @private_gv_user() #0 {
  %tmp = getelementptr inbounds [1 x i32], [1 x i32] addrspace(2)* @private_gv, i64 0, i64 undef
  %val = load i32, i32 addrspace(2)* %tmp
  ret i32 %val
}

define i32 @internal_gv_user() #0 {
  %tmp = getelementptr inbounds [1 x i32], [1 x i32] addrspace(2)* @internal_gv, i64 0, i64 undef
  %val = load i32, i32 addrspace(2)* %tmp
  ret i32 %val
}

define i32 @available_externally_gv_user() #0 {
  %tmp = getelementptr inbounds [1 x i32], [1 x i32] addrspace(2)* @available_externally_gv, i64 0, i64 undef
  %val = load i32, i32 addrspace(2)* %tmp
  ret i32 %val
}

define i32 @linkonce_gv_user() #0 {
  %tmp = getelementptr inbounds [1 x i32], [1 x i32] addrspace(2)* @linkonce_gv, i64 0, i64 undef
  %val = load i32, i32 addrspace(2)* %tmp
  ret i32 %val
}

define i32 @weak_gv_user() #0 {
  %tmp = getelementptr inbounds [1 x i32], [1 x i32] addrspace(2)* @weak_gv, i64 0, i64 undef
  %val = load i32, i32 addrspace(2)* %tmp
  ret i32 %val
}

define i32 @common_gv_user() #0 {
  %tmp = getelementptr inbounds [1 x i32], [1 x i32] addrspace(2)* @common_gv, i64 0, i64 undef
  %val = load i32, i32 addrspace(2)* %tmp
  ret i32 %val
}

define i32 @appending_gv_user() #0 {
  %tmp = getelementptr inbounds [1 x i32], [1 x i32] addrspace(2)* @appending_gv, i64 0, i64 undef
  %val = load i32, i32 addrspace(2)* %tmp
  ret i32 %val
}

define i32 @extern_weak_gv_user() #0 {
  %tmp = getelementptr inbounds [1 x i32], [1 x i32] addrspace(2)* @extern_weak_gv, i64 0, i64 undef
  %val = load i32, i32 addrspace(2)* %tmp
  ret i32 %val
}

define i32 @linkonce_odr_gv_user() #0 {
  %tmp = getelementptr inbounds [1 x i32], [1 x i32] addrspace(2)* @linkonce_odr_gv, i64 0, i64 undef
  %val = load i32, i32 addrspace(2)* %tmp
  ret i32 %val
}

define i32 @weak_odr_gv_user() #0 {
  %tmp = getelementptr inbounds [1 x i32], [1 x i32] addrspace(2)* @weak_odr_gv, i64 0, i64 undef
  %val = load i32, i32 addrspace(2)* %tmp
  ret i32 %val
}

define i32 @external_gv_user() #0 {
  %tmp = getelementptr inbounds [1 x i32], [1 x i32] addrspace(2)* @external_gv, i64 0, i64 undef
  %val = load i32, i32 addrspace(2)* %tmp
  ret i32 %val
}

attributes #0 = { nounwind uwtable }
