////////////////////////////////////////////////////////////////////////////////
// call

let isNotDuplicable = 1, isCall = 1 in {
         def target_call : HSAILInst<(outs ), (ins calltarget:$dst, variable_ops),
            "call $dst", []>;
}

////////////////////////////////////////////////////////////////////////////////
// lower and raise the stack

let isNotDuplicable = 1, hasSideEffects = 1 in {
    def arg_scope_start : HSAILInst<(outs), (ins i32imm:$amt),
                   "; begin of call sequence $amt",
                    [(IL_callseq_start timm:$amt)]>;
    def arg_scope_end   : HSAILInst<(outs), (ins i32imm:$amt1, i32imm:$amt2),
                   "; end of call sequence $amt1 $amt2",
                   [(IL_callseq_end timm:$amt1, timm:$amt2)]>;
}

////////////////////////////////////////////////////////////////////////////////
// ret

let isTerminator = 1, isReturn = 1, isBarrier = 1, hasCtrlDep = 1,
    isNotDuplicable = 1 in {
  def ret : HSAILInst<(outs), (ins), "ret", [(IL_retflag)]>;
}

////////////////////////////////////////////////////////////////////////////////
// branch (unconditional and conditional)

let isBranch = 1, isTerminator = 1, hasCtrlDep = 1, needSpecialProcessing = 1  in {
  let isBarrier = 1 in {
    def branch : HSAILInst<(outs), (ins target:$disp),
             "br\t$disp",
             [(br bb:$disp)]>;
  }
  def branch_cond : HSAILInst<(outs), (ins CR:$cond, target:$disp),
                "cbr_b1\t$cond, $disp",
                [(brcond (i1 CR:$cond), (bb:$disp))]>;
  def branch_ind : HSAILInst<(outs), (ins GPR32:$disp),
                "br\t$disp ", 
        [(brind GPR32:$disp)]>;
}

