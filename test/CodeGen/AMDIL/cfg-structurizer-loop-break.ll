; RUN: llc -march=amdil -mcpu=tahiti < %s | FileCheck %s
;
; source code
; kernel void foo(global int* out, global int* in, int m, int n) {
;  int i = 0;
;  int j = 0;
;  do {
;    do {
;      out[i*n+j]=i+j;
;      if (in[i*n+j])
;        goto label1; // first exit of the outer loop
;      j++;
;    } while (j<n);
;    i++;
;  } while (i<m);  // second exit of the outer loop
;  out[i] = 1;
;  return;
;  label1:
;  out[j] = 2;
;  out[j+5] = 2;
;  return;
; }
;
; structurizer translates it to something like
; kernel void foo(global int* out, global int* in, int m, int n) {
;  int i = 0;
;  int j = 0;
;  do {
;    reg0=0;
;    do {
;      reg0=0;
;      out[i*n+j]=i+j;
;      if (in[i*n+j]) {
;        reg3=1;
;        break; // first exit of the outer loop, reg0=0
;      }
;      j++;
;    } while (j<n);
;    if(reg3==1)
;      break;
;    reg0=1;
;    i++;
;  } while (i<m); // second exit of the outer loop, reg0==1
;  if (reg0==0) {
;    out[j] = 2;
;    out[j+5] = 2;
;    return;
;  } else {
;    out[i] = 1;
;    return;
;  }
; }
;
; CHECK-LABEL: func {{[0-9]+}}
; CHECK: whileloop
; CHECK: mov [[reg0:r[0-9]+]].x___, [[lit0:l[0-9]+]]
; CHECK: whileloop
; CHECK: mov [[reg0]].x___, [[lit0]]
; CHECK: uav_raw_store
; CHECK: uav_raw_load
; CHECK: ine
; CHECK: if_logicalnz
; CHECK: mov [[reg3:r[0-9]+]].x___, [[lit1:l[0-9]+]]
; CHECK: break
; CHECK: endif
; CHECK: break_logicalz
; CHECK: endloop
; CHECK: break_logicalnz [[reg3]].x
; CHECK: mov [[reg0]].x___, [[lit1]]
; CHECK: break_logicalnz
; CHECK: endloop
; CHECK: mov [[reg1:r[0-9]+]].x___, [[lit0]]
; CHECK: ieq [[reg2:r[0-9]+]].x___, [[reg0]].x, [[reg1]].x
; CHECK: if_logicalnz [[reg2]].x
; CHECK: uav_raw_store
; CHECK: uav_raw_store
; CHECK: ret_dyn
; CHECK: else
; CHECK: uav_raw_store
; CHECK: ret_dyn
; CHECK: endif
; CHECK: endfunc
; CHECK-NOT: error
; CHECK-NOT: warning

define void @__OpenCL_foo_kernel(i32 addrspace(1)* nocapture %out, i32 addrspace(1)* nocapture %in, i32 %m, i32 %n) nounwind {
entry:
  br label %do.body2.outer

return:                                           ; preds = %label1, %do.exit
  ret void

do.exit:                                          ; preds = %do.exit1
  %conv32 = sext i32 %tmp26 to i64
  %arrayidx33 = getelementptr i32 addrspace(1)* %out, i64 %conv32
  store i32 1, i32 addrspace(1)* %arrayidx33, align 4
  br label %return

do.exit1:                                         ; preds = %if.end
  %tmp26 = add nsw i32 %i.0.ph, 1
  %cmp29 = icmp slt i32 %tmp26, %m
  br i1 %cmp29, label %do.body2.outer, label %do.exit

do.body2.outer:                                   ; preds = %do.exit1, %entry
  %i.0.ph = phi i32 [ 0, %entry ], [ %tmp26, %do.exit1 ]
  %j.0.ph = phi i32 [ 0, %entry ], [ %tmp22, %do.exit1 ]
  %tmp6 = mul i32 %i.0.ph, %n
  br label %do.body2

do.body2:                                         ; preds = %if.end, %do.body2.outer
  %j.0 = phi i32 [ %tmp22, %if.end ], [ %j.0.ph, %do.body2.outer ]
  %tmp8 = add nsw i32 %tmp6, %j.0
  %conv = sext i32 %tmp8 to i64
  %arrayidx = getelementptr i32 addrspace(1)* %out, i64 %conv
  %tmp11 = add nsw i32 %j.0, %i.0.ph
  store i32 %tmp11, i32 addrspace(1)* %arrayidx, align 4
  %arrayidx19 = getelementptr i32 addrspace(1)* %in, i64 %conv
  %tmp20 = load i32 addrspace(1)* %arrayidx19, align 4
  %tobool = icmp eq i32 %tmp20, 0
  br i1 %tobool, label %if.end, label %label1

if.end:                                           ; preds = %do.body2
  %tmp22 = add nsw i32 %j.0, 1
  %cmp = icmp slt i32 %tmp22, %n
  br i1 %cmp, label %do.body2, label %do.exit1

label1:                                           ; preds = %do.body2
  %conv36 = sext i32 %j.0 to i64
  %arrayidx37 = getelementptr i32 addrspace(1)* %out, i64 %conv36
  store i32 2, i32 addrspace(1)* %arrayidx37, align 4
  %tmp40 = add nsw i32 %j.0, 5
  %conv41 = sext i32 %tmp40 to i64
  %arrayidx42 = getelementptr i32 addrspace(1)* %out, i64 %conv41
  store i32 2, i32 addrspace(1)* %arrayidx42, align 4
  br label %return
}
