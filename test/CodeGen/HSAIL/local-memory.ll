; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

@local_memory_i32.local_mem = internal unnamed_addr addrspace(3) global [128 x i32] undef, align 4

; FUNC-LABEL: {{^}}prog function &local_memory_i32
; HSAIL: group_u32 %local_memory_i32.local_mem[128];
; HSAIL: st_group_align(4)_u32 {{\$s[0-9]+}}, [%local_memory_i32.local_mem][{{\$s[0-9]+}}];
; HSAIL: barrier;
; HSAIL: ld_group_align(4)_u32 {{\$s[0-9]+}}, [%local_memory_i32.local_mem][{{\$s[0-9]+}}];
; HSAIL: ret;
define void @local_memory_i32(i32 addrspace(1)* %out) #0 {
  %y.i = call i32 @llvm.HSAIL.workitemid.flat() #0
  %arrayidx = getelementptr inbounds [128 x i32] addrspace(3)* @local_memory_i32.local_mem, i32 0, i32 %y.i
  store i32 %y.i, i32 addrspace(3)* %arrayidx, align 4
  %add = add nsw i32 %y.i, 1
  %cmp = icmp eq i32 %add, 16
  %.add = select i1 %cmp, i32 0, i32 %add
  call void @llvm.HSAIL.barrier()
  %arrayidx1 = getelementptr inbounds [128 x i32] addrspace(3)* @local_memory_i32.local_mem, i32 0, i32 %.add
  %tmp0 = load i32 addrspace(3)* %arrayidx1, align 4
  %arrayidx2 = getelementptr inbounds i32 addrspace(1)* %out, i32 %y.i
  store i32 %tmp0, i32 addrspace(1)* %arrayidx2, align 4
  ret void
}

@local_memory_i8.local_mem = internal unnamed_addr addrspace(3) global [128 x i8] undef

; FUNC-LABEL: {{^}}prog function &local_memory_i8
; HSAIL: align(4) group_u8 %local_memory_i8.local_mem[128];
; HSAIL: st_group_u8 {{\$s[0-9]+}}, [%local_memory_i8.local_mem][{{\$s[0-9]+}}];
; HSAIL: barrier;
; HSAIL: ld_group_u8 {{\$s[0-9]+}}, [%local_memory_i8.local_mem][{{\$s[0-9]+}}];
; HSAIL: ret;
define void @local_memory_i8(i8 addrspace(1)* %out) #0 {
  %y.i = call i32 @llvm.HSAIL.workitemid.flat() #0
  %arrayidx = getelementptr inbounds [128 x i8] addrspace(3)* @local_memory_i8.local_mem, i32 0, i32 %y.i
  %y.i.trunc = trunc i32 %y.i to i8
  store i8 %y.i.trunc, i8 addrspace(3)* %arrayidx
  %add = add nsw i32 %y.i, 1
  %cmp = icmp eq i32 %add, 16
  %.add = select i1 %cmp, i32 0, i32 %add
  call void @llvm.HSAIL.barrier()
  %arrayidx1 = getelementptr inbounds [128 x i8] addrspace(3)* @local_memory_i8.local_mem, i32 0, i32 %.add
  %tmp0 = load i8 addrspace(3)* %arrayidx1
  %arrayidx2 = getelementptr inbounds i8 addrspace(1)* %out, i32 %y.i
  store i8 %tmp0, i8 addrspace(1)* %arrayidx2
  ret void
}


@local_memory_i16.local_mem = internal unnamed_addr addrspace(3) global [128 x i16] undef

; FUNC-LABEL: {{^}}prog function &local_memory_i16
; HSAIL: align(4) group_u16 %local_memory_i16.local_mem[128];
; HSAIL: st_group_align(2)_u16 {{\$s[0-9]+}}, [%local_memory_i16.local_mem][{{\$s[0-9]+}}];
; HSAIL: barrier;
; HSAIL: ld_group_align(2)_u16 {{\$s[0-9]+}}, [%local_memory_i16.local_mem][{{\$s[0-9]+}}];
; HSAIL: ret;
define void @local_memory_i16(i16 addrspace(1)* %out) #0 {
  %y.i = call i32 @llvm.HSAIL.workitemid.flat() #0
  %arrayidx = getelementptr inbounds [128 x i16] addrspace(3)* @local_memory_i16.local_mem, i32 0, i32 %y.i
  %y.i.trunc = trunc i32 %y.i to i16
  store i16 %y.i.trunc, i16 addrspace(3)* %arrayidx
  %add = add nsw i32 %y.i, 1
  %cmp = icmp eq i32 %add, 16
  %.add = select i1 %cmp, i32 0, i32 %add
  call void @llvm.HSAIL.barrier()
  %arrayidx1 = getelementptr inbounds [128 x i16] addrspace(3)* @local_memory_i16.local_mem, i32 0, i32 %.add
  %tmp0 = load i16 addrspace(3)* %arrayidx1
  %arrayidx2 = getelementptr inbounds i16 addrspace(1)* %out, i32 %y.i
  store i16 %tmp0, i16 addrspace(1)* %arrayidx2
  ret void
}

@local_memory_i64.local_mem = internal unnamed_addr addrspace(3) global [128 x i64] undef

; FUNC-LABEL: {{^}}prog function &local_memory_i64
; HSAIL: group_u64 %local_memory_i64.local_mem[128];
; HSAIL: st_group_align(8)_u64 {{\$d[0-9]+}}, [%local_memory_i64.local_mem][{{\$s[0-9]+}}];
; HSAIL: barrier;
; HSAIL: ld_group_align(8)_u64 {{\$d[0-9]+}}, [%local_memory_i64.local_mem][{{\$s[0-9]+}}];
; HSAIL: ret;
define void @local_memory_i64(i64 addrspace(1)* %out) #0 {
  %y.i = call i32 @llvm.HSAIL.workitemid.flat() #0
  %arrayidx = getelementptr inbounds [128 x i64] addrspace(3)* @local_memory_i64.local_mem, i32 0, i32 %y.i
  %y.i.trunc = sext i32 %y.i to i64
  store i64 %y.i.trunc, i64 addrspace(3)* %arrayidx
  %add = add nsw i32 %y.i, 1
  %cmp = icmp eq i32 %add, 16
  %.add = select i1 %cmp, i32 0, i32 %add
  call void @llvm.HSAIL.barrier()
  %arrayidx1 = getelementptr inbounds [128 x i64] addrspace(3)* @local_memory_i64.local_mem, i32 0, i32 %.add
  %tmp0 = load i64 addrspace(3)* %arrayidx1
  %arrayidx2 = getelementptr inbounds i64 addrspace(1)* %out, i32 %y.i
  store i64 %tmp0, i64 addrspace(1)* %arrayidx2
  ret void
}


@local_memory_f32.local_mem = internal unnamed_addr addrspace(3) global [128 x float] undef

; FUNC-LABEL: {{^}}prog function &local_memory_f32
; HSAIL: group_f32 %local_memory_f32.local_mem[128];
; HSAIL: st_group_align(4)_f32 {{\$s[0-9]+}}, [%local_memory_f32.local_mem][{{\$s[0-9]+}}];
; HSAIL: barrier;
; HSAIL: ld_group_align(4)_f32 {{\$s[0-9]+}}, [%local_memory_f32.local_mem][{{\$s[0-9]+}}];
; HSAIL: ret;
define void @local_memory_f32(float addrspace(1)* %out) #0 {
  %y.i = call i32 @llvm.HSAIL.workitemid.flat() #0
  %arrayidx = getelementptr inbounds [128 x float] addrspace(3)* @local_memory_f32.local_mem, i32 0, i32 %y.i
  %y.i.trunc = uitofp i32 %y.i to float
  store float %y.i.trunc, float addrspace(3)* %arrayidx
  %add = add nsw i32 %y.i, 1
  %cmp = icmp eq i32 %add, 16
  %.add = select i1 %cmp, i32 0, i32 %add
  call void @llvm.HSAIL.barrier()
  %arrayidx1 = getelementptr inbounds [128 x float] addrspace(3)* @local_memory_f32.local_mem, i32 0, i32 %.add
  %tmp0 = load float addrspace(3)* %arrayidx1
  %arrayidx2 = getelementptr inbounds float addrspace(1)* %out, i32 %y.i
  store float %tmp0, float addrspace(1)* %arrayidx2
  ret void
}

declare i32 @llvm.HSAIL.workitemid.flat() #1
declare void @llvm.HSAIL.barrier() #0

attributes #0 = { nounwind }
attributes #1 = { nounwind readnone }
