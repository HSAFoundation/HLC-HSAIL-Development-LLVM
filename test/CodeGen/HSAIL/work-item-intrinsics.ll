; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}prog function &ngroups_x
; HSAIL: gridgroups_u32 {{\$s[0-9]+}}, 0;
define void @ngroups_x(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.num.groups(i32 0) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &ngroups_y
; HSAIL: gridgroups_u32 {{\$s[0-9]+}}, 1;
define void @ngroups_y(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.num.groups(i32 1) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &ngroups_z
; HSAIL: gridgroups_u32 {{\$s[0-9]+}}, 2;
define void @ngroups_z(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.num.groups(i32 2) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &global_size_x
; HSAIL: gridsize_u32 {{\$s[0-9]+}}, 0;
define void @global_size_x(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.global.size(i32 0) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &global_size_y
; HSAIL: gridsize_u32 {{\$s[0-9]+}}, 1;
define void @global_size_y(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.global.size(i32 1) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &global_size_z
; HSAIL: gridsize_u32 {{\$s[0-9]+}}, 2;
define void @global_size_z(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.global.size(i32 2) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &local_size_x
; HSAIL: workgroupsize_u32 {{\$s[0-9]+}}, 0;
define void @local_size_x(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.workgroup.size(i32 0) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &local_size_y
; HSAIL: workgroupsize_u32 {{\$s[0-9]+}}, 1;
define void @local_size_y(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.workgroup.size(i32 1) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &local_size_z
; HSAIL: workgroupsize_u32 {{\$s[0-9]+}}, 2;
define void @local_size_z(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.workgroup.size(i32 2) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &tgid_x
; HSAIL: workgroupid_u32 {{\$s[0-9]+}}, 0;
define void @tgid_x(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.group.id(i32 0) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &tgid_y
; HSAIL: workgroupid_u32 {{\$s[0-9]+}}, 1;
define void @tgid_y(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.group.id(i32 1) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &tgid_z
; HSAIL: workgroupid_u32 {{\$s[0-9]+}}, 2;
define void @tgid_z(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.group.id(i32 2) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &tidig_x
; HSAIL: workitemabsid_u32 {{\$s[0-9]+}}, 0;
define void @tidig_x(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.global.id(i32 0) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &tidig_y
; HSAIL: workitemabsid_u32 {{\$s[0-9]+}}, 1;
define void @tidig_y(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.global.id(i32 1) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &tidig_z
; HSAIL: workitemabsid_u32 {{\$s[0-9]+}}, 2;
define void @tidig_z(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.global.id(i32 2) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

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

; FUNC-LABEL: {{^}}prog function &currentworkgroup_size_x
; HSAIL: currentworkgroupsize_u32 {{\$s[0-9]+}}, 0;
define void @currentworkgroup_size_x(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.currentworkgroup.size(i32 0) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &currentworkgroup_size_y
; HSAIL: currentworkgroupsize_u32 {{\$s[0-9]+}}, 1;
define void @currentworkgroup_size_y(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.currentworkgroup.size(i32 1) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &currentworkgroup_size_z
; HSAIL: currentworkgroupsize_u32 {{\$s[0-9]+}}, 2;
define void @currentworkgroup_size_z(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.currentworkgroup.size(i32 2) #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &get_work_dim
; HSAIL: dim_u32 {{\$s[0-9]+}};
define void @get_work_dim(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.work.dim() #0
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &get_workitemid_flat
; HSAIL: workitemflatid_u32 {{\$s[0-9]+}};
define void @get_workitemid_flat(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.workitemid.flat() #1
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &get_workitemid_flatabs
; HSAIL: workitemflatabsid_u32 {{\$s[0-9]+}};
define void @get_workitemid_flatabs(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.workitemid.flatabs() #1
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &get_lane_id
; HSAIL: laneid_u32 {{\$s[0-9]+}};
define void @get_lane_id(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.lane.id() #1
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &get_dynwave_id
; HSAIL: waveid_u32 {{\$s[0-9]+}};
define void @get_dynwave_id(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.dynwave.id() #1
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &get_maxdynwave_id
; HSAIL: maxwaveid_u32 {{\$s[0-9]+}};
define void @get_maxdynwave_id(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.maxdynwave.id() #1
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &get_clock
; HSAIL: clock_u64 {{\$d[0-9]+}};
define void @get_clock(i64 addrspace(1)* %out) #1 {
  %tmp0 = call i64 @llvm.HSAIL.get.clock() #1
  store i64 %tmp0, i64 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}prog function &get_cu
; HSAIL: cuid_u32 {{\$s[0-9]+}};
define void @get_cu(i32 addrspace(1)* %out) #1 {
  %tmp0 = call i32 @llvm.HSAIL.get.cu() #1
  store i32 %tmp0, i32 addrspace(1)* %out
  ret void
}

declare i32 @llvm.HSAIL.get.num.groups(i32) #0
declare i32 @llvm.HSAIL.get.global.size(i32 ) #0
declare i32 @llvm.HSAIL.workgroup.size(i32) #0
declare i32 @llvm.HSAIL.get.group.id(i32 ) #0
declare i32 @llvm.HSAIL.get.global.id(i32) #0
declare i32 @llvm.HSAIL.currentworkgroup.size(i32) #0
declare i32 @llvm.HSAIL.get.work.dim() #0

declare i32 @llvm.HSAIL.workitemid.flat() #0
declare i32 @llvm.HSAIL.workitemid.flatabs() #0
declare i32 @llvm.HSAIL.get.lane.id() #0
declare i32 @llvm.HSAIL.get.dynwave.id() #0
declare i32 @llvm.HSAIL.get.maxdynwave.id() #0
declare i64 @llvm.HSAIL.get.clock() #1
declare i32 @llvm.HSAIL.get.cu() #1

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
