; RUN: llc -march=hsail64 < %s | FileCheck -check-prefix=HSAIL %s
;
; Regression tests a case where a condition was reversed using
; a 'not_b1 c1, c1' even though the negation was inside a loop.
; This caused loop control flow breakage.

; HSAIL: {{^}}prog function &toggling_condition
; HSAIL-NOT: not_b1 [[CONDREG:\$c[0-9]+]], [[CONDREG]]
; HSAIL: cmp_eq_b1_s32 [[CONDREG0:\$c[0-9]+]], {{\$s[0-9]+}}, 0;
; HSAIL: cbr_b1 [[CONDREG0:\$c[0-9]+]], @

define void @toggling_condition(i32 addrspace(1)* nocapture %idx, i32 %x_size, i32 %y_size, i32 %z_size) {
entry:
  %add = add i32 %x_size, 1
  %cmp.34 = icmp eq i32 %add, 0
  br i1 %cmp.34, label %for.cond.cleanup, label %for.cond.1.preheader.lr.ph

for.cond.1.preheader.lr.ph:                       ; preds = %entry
  %add2 = add i32 %y_size, 1
  %cmp3.30 = icmp eq i32 %add2, 0
  %add7 = add i32 %z_size, 1
  %cmp8.27 = icmp eq i32 %add7, 0
  br label %for.cond.1.preheader

for.cond.1.preheader:                             ; preds = %for.cond.cleanup.4, %for.cond.1.preheader.lr.ph
  %x.036 = phi i32 [ 0, %for.cond.1.preheader.lr.ph ], [ %inc16, %for.cond.cleanup.4 ]
  %i.035 = phi i32 [ 0, %for.cond.1.preheader.lr.ph ], [ %i.1.lcssa, %for.cond.cleanup.4 ]
  br i1 %cmp3.30, label %for.cond.cleanup.4, label %for.cond.6.preheader.preheader

for.cond.6.preheader.preheader:                   ; preds = %for.cond.1.preheader
  br label %for.cond.6.preheader

for.cond.cleanup.loopexit:                        ; preds = %for.cond.cleanup.4
  br label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond.cleanup.loopexit, %entry
  ret void

for.cond.6.preheader:                             ; preds = %for.cond.6.preheader.preheader, %for.cond.cleanup.9
  %y.032 = phi i32 [ %inc13, %for.cond.cleanup.9 ], [ 0, %for.cond.6.preheader.preheader ]
  %i.131 = phi i32 [ %i.2.lcssa, %for.cond.cleanup.9 ], [ %i.035, %for.cond.6.preheader.preheader ]
  br i1 %cmp8.27, label %for.cond.cleanup.9, label %for.body.10.preheader

for.body.10.preheader:                            ; preds = %for.cond.6.preheader
  br label %for.body.10

for.cond.cleanup.4.loopexit:                      ; preds = %for.cond.cleanup.9
  %i.2.lcssa.lcssa = phi i32 [ %i.2.lcssa, %for.cond.cleanup.9 ]
  br label %for.cond.cleanup.4

for.cond.cleanup.4:                               ; preds = %for.cond.cleanup.4.loopexit, %for.cond.1.preheader
  %i.1.lcssa = phi i32 [ %i.035, %for.cond.1.preheader ], [ %i.2.lcssa.lcssa, %for.cond.cleanup.4.loopexit ]
  %inc16 = add nuw nsw i32 %x.036, 1
  %exitcond38 = icmp eq i32 %inc16, %add
  br i1 %exitcond38, label %for.cond.cleanup.loopexit, label %for.cond.1.preheader

for.cond.6.for.cond.cleanup.9_crit_edge:          ; preds = %for.body.10
  %0 = add i32 %add7, %i.131
  br label %for.cond.cleanup.9

for.cond.cleanup.9:                               ; preds = %for.cond.6.preheader, %for.cond.6.for.cond.cleanup.9_crit_edge
  %i.2.lcssa = phi i32 [ %0, %for.cond.6.for.cond.cleanup.9_crit_edge ], [ %i.131, %for.cond.6.preheader ]
  %inc13 = add nuw nsw i32 %y.032, 1
  %exitcond37 = icmp eq i32 %inc13, %add2
  br i1 %exitcond37, label %for.cond.cleanup.4.loopexit, label %for.cond.6.preheader

for.body.10:                                      ; preds = %for.body.10.preheader, %for.body.10
  %z.029 = phi i32 [ %inc11, %for.body.10 ], [ 0, %for.body.10.preheader ]
  %i.228 = phi i32 [ %inc, %for.body.10 ], [ %i.131, %for.body.10.preheader ]
  %1 = sext i32 %i.228 to i64
  %arrayidx = getelementptr inbounds i32, i32 addrspace(1)* %idx, i64 %1
  store i32 %x.036, i32 addrspace(1)* %arrayidx, align 4
  %inc = add i32 %i.228, 1
  %inc11 = add nuw nsw i32 %z.029, 1
  %exitcond = icmp eq i32 %inc11, %add7
  br i1 %exitcond, label %for.cond.6.for.cond.cleanup.9_crit_edge, label %for.body.10
}

