; RUN: llc -march=hsail64 < %s | FileCheck -check-prefix=HSAIL %s

; HSAIL-LABEL: {{^}}prog function &global_zextload_i16_to_i64(
; HSAIL: ld_global_align(2)_u16 [[LD:\$s[0-9]+]],
; HSAIL: cvt_u64_u32 [[CVT:\$d[0-9]+]], [[LD]];
; HSAIL: st_global_align(8)_u64 [[CVT]],
define void @global_zextload_i16_to_i64(i16 addrspace(1)* nocapture readonly %a, i64 addrspace(1)* nocapture %b) #0 {
  %load = load i16, i16 addrspace(1)* %a, align 2
  %ext = zext i16 %load to i64
  store i64 %ext, i64 addrspace(1)* %b, align 8
  ret void
}

; HSAIL-LABEL: {{^}}prog function &global_sextload_i16_to_i64(
; HSAIL: ld_global_align(2)_s16 [[LD:\$s[0-9]+]],
; HSAIL: cvt_s64_s32 [[CVT:\$d[0-9]+]], [[LD]];
; HSAIL: st_global_align(8)_u64 [[CVT]],
define void @global_sextload_i16_to_i64(i16 addrspace(1)* nocapture readonly %a, i64 addrspace(1)* nocapture %b) #0 {
  %load = load i16, i16 addrspace(1)* %a, align 2
  %ext = sext i16 %load to i64
  store i64 %ext, i64 addrspace(1)* %b, align 8
  ret void
}

attributes #0 = { nounwind }