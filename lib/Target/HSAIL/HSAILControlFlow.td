////////////////////////////////////////////////////////////////////////////////
// call

let isNotDuplicable = 1, isCall = 1 in {
         def target_call : HSAILInst<(outs ), (ins calltarget:$dest, variable_ops),
            "call $dest", []>;
}

////////////////////////////////////////////////////////////////////////////////
// lower and raise the stack

let isNotDuplicable = 1, hasSideEffects = 1 in {
    def arg_scope_start : HSAILInst<(outs), (ins i32imm:$src0),
                   "; begin of call sequence $src0",
                    [(IL_callseq_start timm:$src0)]>;
    def arg_scope_end   : HSAILInst<(outs), (ins i32imm:$src0, i32imm:$src1),
                   "; end of call sequence $src0 $src1",
                   [(IL_callseq_end timm:$src0, timm:$src1)]>;
}

////////////////////////////////////////////////////////////////////////////////
// ret

let isTerminator = 1, isReturn = 1, isBarrier = 1, hasCtrlDep = 1,
    isNotDuplicable = 1 in {
  def ret : HSAILInst<(outs), (ins), "ret", [(IL_retflag)]>;
}

////////////////////////////////////////////////////////////////////////////////
// branch (unconditional and conditional)

let isBranch = 1, isTerminator = 1, hasCtrlDep = 1 in {
  let isBarrier = 1 in {
    def branch : HSAILInst<(outs), (ins target:$label),
             "br\t$label",
             [(br bb:$label)]>;
  }
  def branch_cond : HSAILInst<(outs), (ins CR:$src, target:$label),
                "cbr_b1\t$src, $label",
                [(brcond (i1 CR:$src), (bb:$label))]>;
  def branch_ind : HSAILInst<(outs), (ins GPR32:$label),
                "br\t$label ",
        [(brind GPR32:$label)]>;
}

