//===------------------------------------------------------*- tablegen -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

////////////////////////////////////////////////////////////////////////////////

let isNotDuplicable = 1, isCall = 1 in {
  // No semicolon because we need to specially handle the printing of
  // the variable_ops.
  def CALL : HSAILInst<(outs),
    (ins calltarget:$dest, variable_ops),
    "call\t$dest ", [],
    0,
    0
  >;
}

////////////////////////////////////////////////////////////////////////////////

let isNotDuplicable = 1, hasSideEffects = 1 in {
  def ARG_SCOPE_START : HSAILInst<
    (outs),
    (ins i32imm:$src0),
    "\\{",
    [(IL_callseq_start timm:$src0)],
    0,
    0
  >;

  def ARG_SCOPE_END : HSAILInst<
    (outs),
    (ins i32imm:$src0, i32imm:$src1),
    "\\}",
    [(IL_callseq_end timm:$src0, timm:$src1)],
    0,
    0
  >;
}

////////////////////////////////////////////////////////////////////////////////
// ret

let isTerminator = 1, isReturn = 1, isBarrier = 1, hasCtrlDep = 1,
    isNotDuplicable = 1, hasSideEffects = 1 in {
  def RET : HSAILInstBasic_0Op_NoRet<"ret", BrigOpcode.RET, Inst_Void>;
}

def : InstBasic_0Op_NoRet_Pat<RET, HSAILret>;

////////////////////////////////////////////////////////////////////////////////
// branch (unconditional and conditional)


let isBranch = 1, isTerminator = 1, hasCtrlDep = 1 in {
  let isBarrier = 1, WidthAttr = WidthAttrValues.ALL in {
    def BR : HSAILInstBr_1Op_NoRet<"br", BrigOpcode.BR>;
  }

  def CBR : HSAILInstBr_2Op_NoRet<"cbr", BrigOpcode.CBR>;

  // TODO: can sbr be used to support brind?
}

def : Pat<
  (br bb:$src0),
  (BR BrigWidth._ALL, bb:$src0, BrigType.NONE)
>;

def : Pat<
  (brcond i1:$src0, bb:$src1),
  (CBR BrigWidth._1, $src0, bb:$src1, BrigType.B1)
>;
