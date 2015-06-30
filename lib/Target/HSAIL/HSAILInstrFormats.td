//===------ HSAILInstrFormats.td ---------------------------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Instruction format superclass
//===----------------------------------------------------------------------===//

// TODO HSA : fix so that a space is not emitted prior to end of
// statement semi-colon

class HSAILInst<dag outs, dag ins,
                string asmstr,
                list<dag> pattern,
                bits<16> BrigVal = 0,
                bit appendSemicolon = 1>
  : Instruction {
  field bits<32> Inst;
  let Namespace = "HSAIL";
  dag OutOperandList = outs;
  dag InOperandList = ins;
  let AsmString = !if(appendSemicolon, !strconcat(asmstr, ";"), asmstr);
  let Pattern = pattern;

  let UseNamedOperandTable = 1;
  let Inst{15-0} = BrigVal;

  // Target specific flags
  // Important! Keep in sync with HSAIL.h::HSAILTSFLAG

  // Instruction classes. See BrigKind.
  bit InstAddr = 0;
  bit InstAtomic = 0;
  bit InstBasic = 0;
  bit InstBr = 0;
  bit InstCmp = 0;
  bit InstCvt = 0;
  bit InstImage = 0;
  bit InstLane = 0;
  bit InstMem = 0;
  bit InstMemFence = 0;
  bit InstMod = 0;
  bit InstQueryImage = 0;
  bit InstQuerySampler = 0;
  bit InstQueue = 0;
  bit InstSeg = 0;
  bit InstSegCvt = 0;
  bit InstSignal = 0;
  bit InstSourceType = 0;

  // FIXME: Remove these
  bit isConv = 0;
  bit isImageInst = 0;

  bits<2> RoundAttr = 0;

  // Most instructions with a width modifier default to 1.
  bits<2> WidthAttr = WidthAttrValues.ONE;

  bit HasDefaultSegment = 0;

  let TSFlags{3} = InstAddr;
  let TSFlags{4} = InstAtomic;
  let TSFlags{5} = InstBasic;
  let TSFlags{6} = InstBr;
  let TSFlags{7} = InstCmp;
  let TSFlags{8} = InstCvt;
  let TSFlags{9} = InstImage;
  let TSFlags{10} = InstLane;
  let TSFlags{11} = InstMem;
  let TSFlags{12} = InstMemFence;
  let TSFlags{13} = InstMod;
  let TSFlags{14} = InstQueryImage;
  let TSFlags{15} = InstQuerySampler;
  let TSFlags{16} = InstQueue;
  let TSFlags{17} = InstSeg;
  let TSFlags{18} = InstSegCvt;
  let TSFlags{19} = InstSignal;
  let TSFlags{20} = InstSourceType;

  let TSFlags{23} = isConv;
  let TSFlags{24} = isImageInst;

  let TSFlags{26-25} = RoundAttr;
  let TSFlags{28-27} = WidthAttr;

  let TSFlags{29} = HasDefaultSegment;

  // Store the opcode here because we want access to it in
  // BRIGAsmPrinter, but can't really use the normal MC binary
  // encoding method to do so.
  let TSFlags{63-48} = BrigVal;
}

////////////////////////////////////////////////////////////////////////////////
// Basic instruction formats
////////////////////////////////////////////////////////////////////////////////
// InstBasic
class HSAILInstBasic<bits<16> BrigVal,
                     dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let hasSideEffects = 0;
  let InstBasic = 1;
}

class HSAILInstBasic_0Op_NoRet<string opName, bits<16> BrigVal, HSAILProfile P> :
  HSAILInstBasic<BrigVal,
                 (outs),
                 (ins BrigType:$TypeLength),
  opName#"$TypeLength"
> {
  let hasSideEffects = 1;
}

class HSAILInstBasic_0Op<string opName, bits<16> BrigVal, HSAILProfile P> :
  HSAILInstBasic<BrigVal,
                 (outs P.DestRC:$dest),
                 (ins BrigType:$TypeLength),
  opName#"$TypeLength\t$dest"
>;

multiclass InstBasic_0Op_UnsignedIntTypes<string opName, bits<16> BrigVal> {
  def _U32 : HSAILInstBasic_0Op<opName, BrigVal, Inst_U32>;
  def _U64 : HSAILInstBasic_0Op<opName, BrigVal, Inst_U64>;
}

class HSAILInstBasic_1Op<string opName, bits<16> BrigVal, HSAILProfile P> :
  HSAILInstBasic<BrigVal,
                 (outs P.DestRC:$dest),
                 (ins P.Src0RC:$src0, BrigType:$TypeLength),
  opName#"$TypeLength\t$dest, $src0"
>;

multiclass InstBasic_1Op_FPTypes<string opName, bits<16> BrigVal> {
  def _F32 : HSAILInstBasic_1Op<opName, BrigVal, Inst_F32_F32>;
  def _F64 : HSAILInstBasic_1Op<opName, BrigVal, Inst_F64_F64>;
}

multiclass InstBasic_1Op_SignedIntTypes<string opName, bits<16> BrigVal> {
  def _S32 : HSAILInstBasic_1Op<opName, BrigVal, Inst_S32_S32>;
  def _S64 : HSAILInstBasic_1Op<opName, BrigVal, Inst_S64_S64>;
}

multiclass InstBasic_1Op_UnsignedIntTypes<string opName, bits<16> BrigVal> {
  def _U32 : HSAILInstBasic_1Op<opName, BrigVal, Inst_U32_U32>;
  def _U64 : HSAILInstBasic_1Op<opName, BrigVal, Inst_U64_U64>;
}

multiclass InstBasic_1Op_BitTypes<string opName, bits<16> BrigVal> {
  def _B1 : HSAILInstBasic_1Op<opName, BrigVal, Inst_B1_B1>;
  def _B32 : HSAILInstBasic_1Op<opName, BrigVal, Inst_B32_B32>;
  def _B64 : HSAILInstBasic_1Op<opName, BrigVal, Inst_B64_B64>;
}

multiclass InstBasic_1Op_SF<string opName, bits<16> BrigVal> {
  def _F32 : HSAILInstBasic_1Op<opName, BrigVal, Inst_F32_F32>;
  def _F64 : HSAILInstBasic_1Op<opName, BrigVal, Inst_F64_F64>;

  def _S32 : HSAILInstBasic_1Op<opName, BrigVal, Inst_S32_S32>;
  def _S64 : HSAILInstBasic_1Op<opName, BrigVal, Inst_S64_S64>;
}

multiclass InstBasic_1Op_BF<string opName, bits<16> BrigVal> {
  def _F32 : HSAILInstBasic_1Op<opName, BrigVal, Inst_F32_F32>;
  def _F64 : HSAILInstBasic_1Op<opName, BrigVal, Inst_F64_F64>;

  def _B1 : HSAILInstBasic_1Op<opName, BrigVal, Inst_B1_B1>;
  def _B32 : HSAILInstBasic_1Op<opName, BrigVal, Inst_B32_B32>;
  def _B64 : HSAILInstBasic_1Op<opName, BrigVal, Inst_B64_B64>;
}

// Instructions like gridsize which always use an i32 immediate source
multiclass InstBasic_1Op_U32ImmSrc<string opName, bits<16> BrigVal> {
  def _U32 : HSAILInstBasic_1Op<opName, BrigVal, Inst_U32_U32>;
  def _U64 : HSAILInstBasic_1Op<opName, BrigVal, Inst_U64_U32>;
}

class HSAILInstBasic_2Op<string opName, bits<16> BrigVal, HSAILProfile P> :
  HSAILInstBasic<BrigVal,
                 (outs P.DestRC:$dest),
                 (ins P.Src0RC:$src0, P.Src1RC:$src1,
                      BrigType:$TypeLength),
  opName#"$TypeLength\t$dest, $src0, $src1"
>;

multiclass InstBasic_2Op_FPTypes<string opName, bits<16> BrigVal> {
  def _F32 : HSAILInstBasic_2Op<opName, BrigVal, Inst_F32_F32_F32>;
  def _F64 : HSAILInstBasic_2Op<opName, BrigVal, Inst_F64_F64_F64>;
}

multiclass InstBasic_2Op_SignedIntTypes<string opName, bits<16> BrigVal> {
  def _S32 : HSAILInstBasic_2Op<opName, BrigVal, Inst_S32_S32_S32>;
  def _S64 : HSAILInstBasic_2Op<opName, BrigVal, Inst_S64_S64_S64>;
}

multiclass InstBasic_2Op_UnsignedIntTypes<string opName, bits<16> BrigVal> {
  def _U32 : HSAILInstBasic_2Op<opName, BrigVal, Inst_U32_U32_U32>;
  def _U64 : HSAILInstBasic_2Op<opName, BrigVal, Inst_U64_U64_U64>;
}

multiclass InstBasic_2Op_BitTypes<string opName, bits<16> BrigVal> {
  def _B1 : HSAILInstBasic_2Op<opName, BrigVal, Inst_B1_B1_B1>;
  def _B32 : HSAILInstBasic_2Op<opName, BrigVal, Inst_B32_B32_B32>;
  def _B64 : HSAILInstBasic_2Op<opName, BrigVal, Inst_B64_B64_B64>;
}

multiclass InstBasic_2Op_IntTypes<string opName, bits<16> BrigVal> {
  def _S32 : HSAILInstBasic_2Op<opName, BrigVal, Inst_S32_S32_S32>;
  def _S64 : HSAILInstBasic_2Op<opName, BrigVal, Inst_S64_S64_S64>;
  def _U32 : HSAILInstBasic_2Op<opName, BrigVal, Inst_U32_U32_U32>;
  def _U64 : HSAILInstBasic_2Op<opName, BrigVal, Inst_U64_U64_U64>;
}

multiclass InstBasic_2Op_ShiftTypes<string opName, bits<16> BrigVal> {
  def _S32 : HSAILInstBasic_2Op<opName, BrigVal, Inst_S32_S32_S32>;
  def _S64 : HSAILInstBasic_2Op<opName, BrigVal, Inst_S64_S64_U32>;
  def _U32 : HSAILInstBasic_2Op<opName, BrigVal, Inst_U32_U32_U32>;
  def _U64 : HSAILInstBasic_2Op<opName, BrigVal, Inst_U64_U64_U32>;
}

multiclass InstBasic_2Op_LdExp<string opName, bits<16> BrigVal> {
  def _F32 : HSAILInstBasic_2Op<opName, BrigVal, Inst_F32_F32_U32>;
  def _F64 : HSAILInstBasic_2Op<opName, BrigVal, Inst_F64_F64_U32>;
}

multiclass InstBasic_2Op_BitRetType_U32_U32<string opName, bits<16> BrigVal> {
  def _B32 : HSAILInstBasic_2Op<opName, BrigVal, Inst_B32_U32_U32>;
  def _B64 : HSAILInstBasic_2Op<opName, BrigVal, Inst_B64_U32_U32>;
}

class HSAILInstBasic_3Op<string opName, bits<16> BrigVal, HSAILProfile P> :
  HSAILInstBasic<BrigVal,
                 (outs P.DestRC:$dest),
                 (ins P.Src0RC:$src0, P.Src1RC:$src1, P.Src2RC:$src2,
                      BrigType:$TypeLength),
  opName#"$TypeLength\t$dest, $src0, $src1, $src2"
>;

class HSAILInstBasic_4Op<string opName, bits<16> BrigVal, HSAILProfile P> :
  HSAILInstBasic<BrigVal,
                 (outs P.DestRC:$dest),
                 (ins P.Src0RC:$src0, P.Src1RC:$src1, P.Src2RC:$src2,
                      P.Src3RC:$src3, BrigType:$TypeLength),
  opName#"$TypeLength\t$dest, $src0, $src1, $src2, $src3"
>;

multiclass InstBasic_3Op_FPTypes<string opName, bits<16> BrigVal> {
  def _F32 : HSAILInstBasic_3Op<opName, BrigVal, Inst_F32_F32_F32_F32>;
  def _F64 : HSAILInstBasic_3Op<opName, BrigVal, Inst_F64_F64_F64_F64>;
}

multiclass InstBasic_3Op_IntTypes<string opName, bits<16> BrigVal> {
  def _S32 : HSAILInstBasic_3Op<opName, BrigVal, Inst_S32_S32_S32_S32>;
  def _S64 : HSAILInstBasic_3Op<opName, BrigVal, Inst_S64_S64_S64_S64>;
  def _U32 : HSAILInstBasic_3Op<opName, BrigVal, Inst_U32_U32_U32_U32>;
  def _U64 : HSAILInstBasic_3Op<opName, BrigVal, Inst_U64_U64_U64_U64>;
}

multiclass InstBasic_3Op_BitTypes<string opName, bits<16> BrigVal> {
  def _B1 : HSAILInstBasic_3Op<opName, BrigVal, Inst_B1_B1_B1_B1>;
  def _B32 : HSAILInstBasic_3Op<opName, BrigVal, Inst_B32_B32_B32_B32>;
  def _B64 : HSAILInstBasic_3Op<opName, BrigVal, Inst_B64_B64_B64_B64>;
}

multiclass InstBasic_3Op_CMov<string opName, bits<16> BrigVal> {
  def _B1 : HSAILInstBasic_3Op<opName, BrigVal, Inst_B1_B1_B1_B1>;
  def _B32 : HSAILInstBasic_3Op<opName, BrigVal, Inst_B32_B1_B32_B32>;
  def _B64 : HSAILInstBasic_3Op<opName, BrigVal, Inst_B64_B1_B64_B64>;
}

multiclass InstBasic_3Op_BitExtract<string opName, bits<16> BrigVal> {
  def _S32 : HSAILInstBasic_3Op<opName, BrigVal, Inst_S32_S32_U32_U32>;
  def _S64 : HSAILInstBasic_3Op<opName, BrigVal, Inst_S64_S64_U32_U32>;

  def _U32 : HSAILInstBasic_3Op<opName, BrigVal, Inst_U32_U32_U32_U32>;
  def _U64 : HSAILInstBasic_3Op<opName, BrigVal, Inst_U64_U64_U32_U32>;
}

multiclass InstBasic_4Op_BitInsert<string opName, bits<16> BrigVal> {
  def _S32 : HSAILInstBasic_4Op<opName, BrigVal, Inst_S32_S32_S32_U32_U32>;
  def _S64 : HSAILInstBasic_4Op<opName, BrigVal, Inst_S64_S64_S64_U32_U32>;

  def _U32 : HSAILInstBasic_4Op<opName, BrigVal, Inst_U32_U32_U32_U32_U32>;
  def _U64 : HSAILInstBasic_4Op<opName, BrigVal, Inst_U64_U64_U64_U32_U32>;
}

multiclass InstBasic_3Op_SUF<string opName, bits<16> BrigVal> {
  def _S32 : HSAILInstBasic_3Op<opName, BrigVal, Inst_S32_S32_S32_S32>;
  def _S64 : HSAILInstBasic_3Op<opName, BrigVal, Inst_S64_S64_S64_S64>;

  def _U32 : HSAILInstBasic_3Op<opName, BrigVal, Inst_U32_U32_U32_U32>;
  def _U64 : HSAILInstBasic_3Op<opName, BrigVal, Inst_U64_U64_U64_U64>;

  def _F32 : HSAILInstBasic_3Op<opName, BrigVal, Inst_F32_F32_F32_F32>;
  def _F64 : HSAILInstBasic_3Op<opName, BrigVal, Inst_F64_F64_F64_F64>;
}


// InstMod
class HSAILInstMod<bits<16> BrigVal,
                   dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let hasSideEffects = 0;
  let InstMod = 1;
}

// TODO: Needs pack operand?
class HSAILInstMod_1Op<string opName, bits<16> BrigVal, HSAILProfile P> :
  HSAILInstMod<BrigVal,
               (outs P.DestRC:$dest),
               (ins ftz:$ftz, BrigRound:$round,
                    P.Src0RC:$src0,
                    BrigType:$TypeLength),
  opName#"$ftz$round$TypeLength\t$dest, $src0"
>;

multiclass InstMod_1Op_FPTypes<string opName, bits<16> BrigVal> {
  def _F32 : HSAILInstMod_1Op<opName, BrigVal, Inst_F32_F32>;
  def _F64 : HSAILInstMod_1Op<opName, BrigVal, Inst_F64_F64>;
}

multiclass InstMod_1Op_SignedIntTypes<string opName, bits<16> BrigVal> {
  def _S32 : HSAILInstMod_1Op<opName, BrigVal, Inst_S32_S32>;
  def _S64 : HSAILInstMod_1Op<opName, BrigVal, Inst_S64_S64>;
}

multiclass InstMod_1Op_UnsignedIntTypes<string opName, bits<16> BrigVal> {
  def _U32 : HSAILInstMod_1Op<opName, BrigVal, Inst_U32_U32>;
  def _U64 : HSAILInstMod_1Op<opName, BrigVal, Inst_U64_U64>;
}

multiclass InstMod_1Op_1BitTypes<string opName, bits<16> BrigVal> {
  def _B32 : HSAILInstMod_1Op<opName, BrigVal, Inst_B32_B32>;
  def _B64 : HSAILInstMod_1Op<opName, BrigVal, Inst_B64_B64>;
}

multiclass InstMod_1Op_IntTypes<string opName, bits<16> BrigVal> {
  def _S32 : HSAILInstMod_1Op<opName, BrigVal, Inst_S32_S32>;
  def _S64 : HSAILInstMod_1Op<opName, BrigVal, Inst_S64_S64>;
  def _U32 : HSAILInstMod_1Op<opName, BrigVal, Inst_U32_U32>;
  def _U64 : HSAILInstMod_1Op<opName, BrigVal, Inst_U64_U64>;
}

class HSAILInstMod_2Op<string opName, bits<16> BrigVal, HSAILProfile P> :
  HSAILInstMod<BrigVal,
               (outs P.DestRC:$dest),
               (ins ftz:$ftz, BrigRound:$round,
                    P.Src0RC:$src0, P.Src1RC:$src1,
                    BrigType:$TypeLength),
  opName#"$ftz$round$TypeLength\t$dest, $src0, $src1"
>;

multiclass InstMod_2Op_FPTypes<string opName, bits<16> BrigVal> {
  def _F32 : HSAILInstMod_2Op<opName, BrigVal, Inst_F32_F32_F32>;
  def _F64 : HSAILInstMod_2Op<opName, BrigVal, Inst_F64_F64_F64>;
}

multiclass InstMod_2Op_SignedIntTypes<string opName, bits<16> BrigVal> {
  def _S32 : HSAILInstMod_2Op<opName, BrigVal, Inst_S32_S32_S32>;
  def _S64 : HSAILInstMod_2Op<opName, BrigVal, Inst_S64_S64_S64>;
}

multiclass InstMod_2Op_UnsignedIntTypes<string opName, bits<16> BrigVal> {
  def _U32 : HSAILInstMod_2Op<opName, BrigVal, Inst_U32_U32_U32>;
  def _U64 : HSAILInstMod_2Op<opName, BrigVal, Inst_U64_U64_U64>;
}

multiclass InstMod_2Op_BitTypes<string opName, bits<16> BrigVal> {
  def _B32 : HSAILInstMod_2Op<opName, BrigVal, Inst_B32_B32_B32>;
  def _B64 : HSAILInstMod_2Op<opName, BrigVal, Inst_B64_B64_B64>;
}

multiclass InstMod_2Op_IntTypes<string opName, bits<16> BrigVal> {
  def _S32 : HSAILInstMod_2Op<opName, BrigVal, Inst_S32_S32_S32>;
  def _S64 : HSAILInstMod_2Op<opName, BrigVal, Inst_S64_S64_S64>;
  def _U32 : HSAILInstMod_2Op<opName, BrigVal, Inst_U32_U32_U32>;
  def _U64 : HSAILInstMod_2Op<opName, BrigVal, Inst_U64_U64_U64>;
}

multiclass InstMod_2Op_SUF<string opName, bits<16> BrigVal> {
  def _S32 : HSAILInstMod_2Op<opName, BrigVal, Inst_S32_S32_S32>;
  def _S64 : HSAILInstMod_2Op<opName, BrigVal, Inst_S64_S64_S64>;

  def _U32 : HSAILInstMod_2Op<opName, BrigVal, Inst_U32_U32_U32>;
  def _U64 : HSAILInstMod_2Op<opName, BrigVal, Inst_U64_U64_U64>;

  def _F32 : HSAILInstMod_2Op<opName, BrigVal, Inst_F32_F32_F32>;
  def _F64 : HSAILInstMod_2Op<opName, BrigVal, Inst_F64_F64_F64>;
}


class HSAILInstMod_3Op<string opName, bits<16> BrigVal, HSAILProfile P> :
  HSAILInstMod<BrigVal,
               (outs P.DestRC:$dest),
               (ins ftz:$ftz, BrigRound:$round,
                    P.Src0RC:$src0, P.Src1RC:$src1, P.Src2RC:$src2,
                    BrigType:$TypeLength),
  opName#"$ftz$round$TypeLength\t$dest, $src0, $src1, $src2"
>;

multiclass InstMod_3Op_FPTypes<string opName, bits<16> BrigVal> {
  def _F32 : HSAILInstMod_3Op<opName, BrigVal, Inst_F32_F32_F32_F32>;
  def _F64 : HSAILInstMod_3Op<opName, BrigVal, Inst_F64_F64_F64_F64>;
}


// InstCvt
class InstCvt<string opName, bits<16> BrigVal,
              RegisterClass DestRC,
              ValueType SrcVT> : HSAILInst<
    (outs DestRC:$dest),
    (ins ftz:$ftz,
         BrigRound:$round,
         BrigType:$destTypedestLength,
         BrigType:$sourceType,
         getRegClassForVT<SrcVT>.ret:$src),
    opName#"$ftz$round$destTypedestLength$sourceType\t$dest, $src",
   [], BrigVal
> {
  let isConv = 1;
  let InstCvt = 1;
}

// This also generates the illegal type to same type cvts, which
// hopefully will never be used.
multiclass InstCvt_SrcTypes<string opName, bits<16> BrigVal,
                         RegisterClass DestRC> {
  def _B1 : InstCvt<opName, BrigVal, DestRC, i1>;

  def _U32 : InstCvt<opName, BrigVal, DestRC, i32>;
  def _U64 : InstCvt<opName, BrigVal, DestRC, i64>;

  def _S32 : InstCvt<opName, BrigVal, DestRC, i32>;
  def _S64 : InstCvt<opName, BrigVal, DestRC, i64>;

  def _F16 : InstCvt<opName, BrigVal, DestRC, i32>;
  def _F32 : InstCvt<opName, BrigVal, DestRC, f32>;
  def _F64 : InstCvt<opName, BrigVal, DestRC, f64>;
}

multiclass InstCvt_DestTypes<string opName, bits<16> BrigVal> {
  defm _B1 : InstCvt_SrcTypes<opName, BrigVal, CR>;

  defm _U32 : InstCvt_SrcTypes<opName, BrigVal, GPR32>;
  defm _U64 : InstCvt_SrcTypes<opName, BrigVal, GPR64>;

  defm _S32 : InstCvt_SrcTypes<opName, BrigVal, GPR32>;
  defm _S64 : InstCvt_SrcTypes<opName, BrigVal, GPR64>;

  defm _F16 : InstCvt_SrcTypes<opName, BrigVal, GPR32>;
  defm _F32 : InstCvt_SrcTypes<opName, BrigVal, GPR32>;
  defm _F64 : InstCvt_SrcTypes<opName, BrigVal, GPR64>;
}

// InstSourceType
class HSAILInstSourceType<bits<16> BrigVal,
                          dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let hasSideEffects = 0;
  let InstSourceType = 1;
}

class HSAILInstSourceType_1Op<string opName, bits<16> BrigVal, HSAILProfile P> :
  HSAILInstSourceType<BrigVal,
                 (outs P.DestRC:$dest),
                 (ins P.Src0RC:$src0, BrigType:$TypeLength, BrigType:$sourceType),
  opName#"$TypeLength$sourceType\t$dest, $src0"
>;

multiclass InstSourceType_1Op_U32_BitTypes<string opName, bits<16> BrigVal> {
  def _U32_B32 : HSAILInstSourceType_1Op<opName, BrigVal, Inst_U32_B32>;
  def _U32_B64 : HSAILInstSourceType_1Op<opName, BrigVal, Inst_U32_B64>;
}

multiclass InstSourceType_1Op_U32_IntTypes<string opName, bits<16> BrigVal> {
  def _U32_S32 : HSAILInstSourceType_1Op<opName, BrigVal, Inst_U32_S32>;
  def _U32_S64 : HSAILInstSourceType_1Op<opName, BrigVal, Inst_U32_S64>;

  def _U32_U32 : HSAILInstSourceType_1Op<opName, BrigVal, Inst_U32_U32>;
  def _U32_U64 : HSAILInstSourceType_1Op<opName, BrigVal, Inst_U32_U64>;
}

class HSAILInstSourceType_2Op<string opName, bits<16> BrigVal, HSAILProfile P> :
  HSAILInstSourceType<BrigVal,
                 (outs P.DestRC:$dest),
                 (ins P.Src0RC:$src0, P.Src1RC:$src1,
                      BrigType:$TypeLength, BrigType:$sourceType),
  opName#"$TypeLength$sourceType\t$dest, $src0, $src1"
>;

multiclass InstSourceType_2Op_Class_Types<string opName, bits<16> BrigVal> {
  def _F32 : HSAILInstSourceType_2Op<opName, BrigVal, Inst_B1_F32_U32>;
  def _F64 : HSAILInstSourceType_2Op<opName, BrigVal, Inst_B1_F64_U32>;
}

class HSAILInstSourceType_3Op<string opName, bits<16> BrigVal, HSAILProfile P> :
  HSAILInstSourceType<BrigVal,
                 (outs P.DestRC:$dest),
                 (ins P.Src0RC:$src0, P.Src1RC:$src1, P.Src2RC:$src2,
                      BrigType:$TypeLength, BrigType:$sourceType),
  opName#"$TypeLength$sourceType\t$dest, $src0, $src1, $src2"
>;

// Missing types that require q registers.
multiclass InstSourceType_3Op_Pack_Types<string opName, bits<16> BrigVal> {
  def _U8X4_U32 : HSAILInstSourceType_3Op<opName, BrigVal, Inst_U8X4_U8X4_U32_U32>;
  def _S8X4_S32 : HSAILInstSourceType_3Op<opName, BrigVal, Inst_S8X4_S8X4_S32_U32>;

  def _U8X8_U32 : HSAILInstSourceType_3Op<opName, BrigVal, Inst_U8X8_U8X8_U32_U32>;
  def _S8X8_S32 : HSAILInstSourceType_3Op<opName, BrigVal, Inst_S8X8_S8X8_S32_U32>;

  def _U16X4_U32 : HSAILInstSourceType_3Op<opName, BrigVal, Inst_U16X4_U16X4_U32_U32>;
  def _S16X4_S32 : HSAILInstSourceType_3Op<opName, BrigVal, Inst_S16X4_S16X4_S32_U32>;

  def _U32X2_U32 : HSAILInstSourceType_3Op<opName, BrigVal, Inst_U32X2_U32X2_U32_U32>;
  def _S32X2_S32 : HSAILInstSourceType_3Op<opName, BrigVal, Inst_S32X2_S32X2_S32_U32>;

  def _F16X2_F16 : HSAILInstSourceType_3Op<opName, BrigVal, Inst_F16X2_F16X2_F16_U32>;
  def _F16X4_F16 : HSAILInstSourceType_3Op<opName, BrigVal, Inst_F16X4_F16X4_F16_U32>;
}

multiclass InstSourceType_3Op_Sad_Types<string opName, bits<16> BrigVal> {
  def _U32_U32 : HSAILInstSourceType_3Op<opName, BrigVal, Inst_U32_U32_U32_U32>;
  def _U32_U16X2 : HSAILInstSourceType_3Op<opName, BrigVal, Inst_U32_U16X2_U16X2_U32>;
  def _U32_U8X4 : HSAILInstSourceType_3Op<opName, BrigVal, Inst_U32_U8X4_U8X4_U32>;
}

class HSAILInstSourceType_4Op<string opName, bits<16> BrigVal, HSAILProfile P> :
  HSAILInstSourceType<BrigVal,
                 (outs P.DestRC:$dest),
                 (ins P.Src0RC:$src0, P.Src1RC:$src1, P.Src2RC:$src2, P.Src3RC:$src3,
                      BrigType:$TypeLength, BrigType:$sourceType),
  opName#"$TypeLength$sourceType\t$dest, $src0, $src1, $src2, $src3"
>;



// InstLane
class HSAILInstLane<bits<16> BrigVal,
                    dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let hasSideEffects = 1;
  let InstLane = 1;
}

class HSAILInstLane_0Op<string opName, bits<16> BrigVal, HSAILProfile P> :
  HSAILInstLane<
    BrigVal,
    (outs P.DestRC:$dest),
    (ins BrigWidth:$width, BrigType:$TypeLength, BrigType:$sourceType),
  opName#"$width$TypeLength$sourceType\t$dest"
>;

class HSAILInstLane_1Op<string opName, bits<16> BrigVal, HSAILProfile P> :
  HSAILInstLane<
    BrigVal,
    (outs P.DestRC:$dest),
    (ins BrigWidth:$width, P.Src0RC:$src0, BrigType:$TypeLength, BrigType:$sourceType),
  opName#"$width$TypeLength$sourceType\t$dest, $src0"
>;

class HSAILInstLane_ActiveLanePermute<string opName, bits<16> BrigVal, HSAILProfile P> :
  HSAILInstLane<
    BrigVal,
    (outs P.DestRC:$dest),
    (ins BrigWidth:$width,
         P.Src0RC:$src0, P.Src1RC:$src1, P.Src2RC:$src2, P.Src3RC:$src3,
         BrigType:$TypeLength, BrigType:$sourceType),
  opName#"$width$TypeLength$sourceType\t$dest, $src0, $src1, $src2, $src3"
>;

multiclass InstLane_ActiveLanePermute_Types<string opName, bits<16> BrigVal> {
  def _B1 : HSAILInstLane_ActiveLanePermute<opName, BrigVal, Inst_B1_B1_U32_B1_B1>;
  def _B32 : HSAILInstLane_ActiveLanePermute<opName, BrigVal, Inst_B32_B32_U32_B32_B1>;
  def _B64 : HSAILInstLane_ActiveLanePermute<opName, BrigVal, Inst_B64_B64_U32_B64_B1>;
}

class HSAILInstLane_ActiveLaneMask<string opName, bits<16> BrigVal> :
  HSAILInstLane<
    BrigVal,
    // FIXME: Using compound operands as dest seems to not be selectable
  //(outs Vec4Op:$dest),
    (outs GPR64:$dest0, GPR64:$dest1,  GPR64:$dest2,  GPR64:$dest3),
    (ins BrigWidth:$width,
         B1Op:$src0, BrigType:$TypeLength, BrigType:$sourceType),
//  opName#"$width$TypeLength$sourceType\t$dest, $src0"
  opName#"_v4$width$TypeLength$sourceType\t($dest0, $dest1, $dest2, $dest3), $src0"
>;

// InstBr
class HSAILInstBr<bits<16> BrigVal,
                  dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let hasSideEffects = 1;
  let InstBr = 1;
}

class HSAILInstBr_0Op_NoRet<string opName, bits<16> BrigVal> :
  HSAILInstBr<BrigVal,
              (outs),
              (ins BrigWidth:$width, BrigType:$TypeLength),
  opName#"$width$TypeLength"
>;

class HSAILInstBr_1Op_NoRet<string opName, bits<16> BrigVal> :
  HSAILInstBr<BrigVal,
              (outs),
              (ins BrigWidth:$width, unknown:$src0, BrigType:$TypeLength),
  opName#"$width$TypeLength\t$src0"
>;

class HSAILInstBr_2Op_NoRet<string opName, bits<16> BrigVal> :
  HSAILInstBr<BrigVal,
              (outs),
              (ins BrigWidth:$width, HSAILSrc1Operand:$src0, unknown:$src1, BrigType:$TypeLength),
  opName#"$width$TypeLength\t$src0, $src1"
>;

// InstSeg
class HSAILInstSeg<bits<16> BrigVal,
                  dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let hasSideEffects = 0;
  let InstSeg = 1;
}

class HSAILInstSeg_0Op<string opName, bits<16> BrigVal, HSAILProfile P> :
  HSAILInstSeg<BrigVal,
               (outs P.DestRC:$dest),
               (ins BrigSegment:$segment, BrigType:$TypeLength),
  opName#"$segment$TypeLength\t$dest"
>;

multiclass InstSeg_0Op_PtrTypes<string opName, bits<16> BrigVal> {
  def _U32 : HSAILInstSeg_0Op<opName, BrigVal, Inst_U32>;
  def _U64 : HSAILInstSeg_0Op<opName, BrigVal, Inst_U64>;
}

// InstSegCvt
class HSAILInstSegCvt<bits<16> BrigVal,
                      dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let hasSideEffects = 0;
  let InstSegCvt = 1;
}

class HSAILInstSegCvt_1Op<string opName, bits<16> BrigVal, HSAILProfile P> :
  HSAILInstSegCvt<BrigVal,
                 (outs P.DestRC:$dest),
                 (ins BrigSegment:$segment,
                      nonull:$nonull,
                      P.Src0RC:$src0,
                      BrigType:$destTypedestLength,
                      BrigType:$sourceType),
  opName#"$segment$nonull$destTypedestLength$sourceType\t$dest, $src0"
>;

multiclass InstSegCvt_1Op_PtrTypes<string opName, bits<16> BrigVal> {
  def _U32_U32 : HSAILInstSegCvt_1Op<opName, BrigVal, Inst_U32_U32>;
  def _U32_U64 : HSAILInstSegCvt_1Op<opName, BrigVal, Inst_U32_U64>;
  def _U64_U32 : HSAILInstSegCvt_1Op<opName, BrigVal, Inst_U64_U32>;
  def _U64_U64 : HSAILInstSegCvt_1Op<opName, BrigVal, Inst_U64_U64>;
}

multiclass InstSegCvt_1Op_Segmentp_Types<string opName, bits<16> BrigVal> {
  def _B1_U32 : HSAILInstSegCvt_1Op<opName, BrigVal, Inst_B1_U32>;
  def _B1_U64 : HSAILInstSegCvt_1Op<opName, BrigVal, Inst_B1_U64>;
}

// InstMemFence
class HSAILInstMemFence<bits<16> BrigVal,
                        dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let hasSideEffects = 1;
  let mayLoad = 1;
  let mayStore = 1;
  let isBarrier = 1;
  let isNotDuplicable = 1; // XXX - This seems unnecessary
  let InstMemFence = 1;
}

class InstMemFence<string opName, bits<16> BrigVal> :
  HSAILInstMemFence<
    BrigVal,
    (outs),
    (ins BrigMemoryOrder:$order,
         BrigMemoryScope:$scope),
    opName#"$order$scope"
>;

// InstMem
class HSAILInstMem<bits<16> BrigVal,
                   dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let mayLoad = 1;
  let mayStore = 1;
  let InstMem = 1;
}

class LD<string opName, bits<16> BrigVal, dag outs> :
  HSAILInstMem<BrigVal, outs,
    (ins MEMOP:$address,
       BrigType:$TypeLength,
       BrigSegment:$segment,
       BrigAlignment:$align,
       BrigWidth:$width,
       BrigMemoryModifierMask:$mask),
    opName#"$segment$align$width$mask$TypeLength\t$dest, $address"> {
  let mayStore = 0;
  let hasSideEffects = 0;
}

class StoreOperands<DAGOperand srcOp> {
  field dag op_ins = (ins srcOp:$src, MEMOP:$address, BrigType:$TypeLength,
                    BrigSegment:$segment, BrigAlignment:$align);
}

def store_u32 : StoreOperands<U32Op>;
def store_f32 : StoreOperands<F32Op>;
def store_u64 : StoreOperands<U64Op>;
def store_f64 : StoreOperands<F64Op>;

def store_v2_u32 : StoreOperands<Vec2SrcOpU32>;
def store_v2_f32 : StoreOperands<Vec2SrcOpF32>;

def store_v2_u64 : StoreOperands<Vec2SrcOpU64>;
def store_v2_f64 : StoreOperands<Vec2SrcOpF64>;

def store_v3_u32 : StoreOperands<Vec3SrcOpU32>;
def store_v3_f32 : StoreOperands<Vec3SrcOpF32>;

def store_v3_u64 : StoreOperands<Vec3SrcOpU64>;
def store_v3_f64 : StoreOperands<Vec3SrcOpF64>;

def store_v4_u32 : StoreOperands<Vec4SrcOpU32>;
def store_v4_f32 : StoreOperands<Vec4SrcOpF32>;
def store_v4_u64 : StoreOperands<Vec4SrcOpU64>;
def store_v4_f64 : StoreOperands<Vec4SrcOpF64>;


multiclass LD_Types<string opName, bits<16> BrigVal> {
  def _S8 : LD<opName, BrigVal, (outs GPR32:$dest)>,
            LdStVectorMap<NAME#"_S8", 1>;
  def _U8 : LD<opName, BrigVal, (outs GPR32:$dest)>,
            LdStVectorMap<NAME#"_U8", 1>;

  def _S16 : LD<opName, BrigVal, (outs GPR32:$dest)>,
             LdStVectorMap<NAME#"_S16", 1>;
  def _U16 : LD<opName, BrigVal, (outs GPR32:$dest)>,
             LdStVectorMap<NAME#"_U16", 1>;

  def _S32 : LD<opName, BrigVal, (outs GPR32:$dest)>,
             LdStVectorMap<NAME#"_S32", 1>;
  def _U32 : LD<opName, BrigVal, (outs GPR32:$dest)>,
             LdStVectorMap<NAME#"_U32", 1>;
  def _F32 : LD<opName, BrigVal, (outs GPR32:$dest)>,
             LdStVectorMap<NAME#"_F32", 1>;

  def _SAMP : LD<opName, BrigVal, (outs GPR32:$dest)>,
               LdStVectorMap<NAME#"_SAMP", 1>;

  def _S64 : LD<opName, BrigVal, (outs GPR64:$dest)>,
             LdStVectorMap<NAME#"_S64", 1>;
  def _U64 : LD<opName, BrigVal, (outs GPR64:$dest)>,
             LdStVectorMap<NAME#"_U64", 1>;
  def _F64 : LD<opName, BrigVal, (outs GPR64:$dest)>,
             LdStVectorMap<NAME#"_F64", 1>;


  def _V2_S8 : LD<opName#"_v2", BrigVal, (outs Vec2DestOp32:$dest)>,
               LdStVectorMap<NAME#"_S8", 2>;
  def _V2_U8 : LD<opName#"_v2", BrigVal, (outs Vec2DestOp32:$dest)>,
               LdStVectorMap<NAME#"_U8", 2>;

  def _V2_S16 : LD<opName#"_v2", BrigVal, (outs Vec2DestOp32:$dest)>,
                LdStVectorMap<NAME#"_S16", 2>;
  def _V2_U16 : LD<opName#"_v2", BrigVal, (outs Vec2DestOp32:$dest)>,
                LdStVectorMap<NAME#"_U16", 2>;

  def _V2_S32 : LD<opName#"_v2", BrigVal, (outs Vec2DestOp32:$dest)>,
                LdStVectorMap<NAME#"_S32", 2>;
  def _V2_U32 : LD<opName#"_v2", BrigVal, (outs Vec2DestOp32:$dest)>,
                LdStVectorMap<NAME#"_U32", 2>;
  def _V2_F32 : LD<opName#"_v2", BrigVal, (outs Vec2DestOp32:$dest)>,
                LdStVectorMap<NAME#"_F32", 2>;

  def _V2_S64 : LD<opName#"_v2", BrigVal, (outs Vec2DestOp64:$dest)>,
                LdStVectorMap<NAME#"_S64", 2>;
  def _V2_U64 : LD<opName#"_v2", BrigVal, (outs Vec2DestOp64:$dest)>,
                LdStVectorMap<NAME#"_U64", 2>;
  def _V2_F64 : LD<opName#"_v2", BrigVal, (outs Vec2DestOp64:$dest)>,
                LdStVectorMap<NAME#"_F64", 2>;


  def _V3_S8 : LD<opName#"_v3", BrigVal, (outs Vec3DestOp32:$dest)>,
               LdStVectorMap<NAME#"_S8", 3>;
  def _V3_U8 : LD<opName#"_v3", BrigVal, (outs Vec3DestOp32:$dest)>,
               LdStVectorMap<NAME#"_U8", 3>;

  def _V3_S16 : LD<opName#"_v3", BrigVal, (outs Vec3DestOp32:$dest)>,
                LdStVectorMap<NAME#"_S16", 3>;
  def _V3_U16 : LD<opName#"_v3", BrigVal, (outs Vec3DestOp32:$dest)>,
                LdStVectorMap<NAME#"_U16", 3>;

  def _V3_S32 : LD<opName#"_v3", BrigVal, (outs Vec3DestOp32:$dest)>,
                LdStVectorMap<NAME#"_S32", 3>;
  def _V3_U32 : LD<opName#"_v3", BrigVal, (outs Vec3DestOp32:$dest)>,
                LdStVectorMap<NAME#"_U32", 3>;
  def _V3_F32 : LD<opName#"_v3", BrigVal, (outs Vec3DestOp32:$dest)>,
                LdStVectorMap<NAME#"_F32", 3>;

  def _V3_S64 : LD<opName#"_v3", BrigVal, (outs Vec3DestOp64:$dest)>,
                LdStVectorMap<NAME#"_S64", 3>;
  def _V3_U64 : LD<opName#"_v3", BrigVal, (outs Vec3DestOp64:$dest)>,
                LdStVectorMap<NAME#"_U64", 3>;
  def _V3_F64 : LD<opName#"_v3", BrigVal, (outs Vec3DestOp64:$dest)>,
                LdStVectorMap<NAME#"_F64", 3>;


  def _V4_S8 : LD<opName#"_v4", BrigVal, (outs Vec4DestOp32:$dest)>,
               LdStVectorMap<NAME#"_S8", 4>;
  def _V4_U8 : LD<opName#"_v4", BrigVal, (outs Vec4DestOp32:$dest)>,
               LdStVectorMap<NAME#"_U8", 4>;

  def _V4_S16 : LD<opName#"_v4", BrigVal, (outs Vec4DestOp32:$dest)>,
                LdStVectorMap<NAME#"_S16", 4>;
  def _V4_U16 : LD<opName#"_v4", BrigVal, (outs Vec4DestOp32:$dest)>,
                LdStVectorMap<NAME#"_U16", 4>;

  def _V4_S32 : LD<opName#"_v4", BrigVal, (outs Vec4DestOp32:$dest)>,
                LdStVectorMap<NAME#"_S32", 4>;
  def _V4_U32 : LD<opName#"_v4", BrigVal, (outs Vec4DestOp32:$dest)>,
                LdStVectorMap<NAME#"_U32", 4>;
  def _V4_F32 : LD<opName#"_v4", BrigVal, (outs Vec4DestOp32:$dest)>,
                LdStVectorMap<NAME#"_F32", 4>;

  def _V4_S64 : LD<opName#"_v4", BrigVal, (outs Vec4DestOp64:$dest)>,
                LdStVectorMap<NAME#"_S64", 4>;
  def _V4_U64 : LD<opName#"_v4", BrigVal, (outs Vec4DestOp64:$dest)>,
                LdStVectorMap<NAME#"_U64", 4>;
  def _V4_F64 : LD<opName#"_v4", BrigVal, (outs Vec4DestOp64:$dest)>,
                LdStVectorMap<NAME#"_F64", 4>;
}

class ST<string opName, bits<16> BrigVal, dag ins> :
  HSAILInstMem<BrigVal, (outs),
    ins,
    opName#"$segment$align$TypeLength\t$src, $address"> {
  let mayLoad = 0;
  let hasSideEffects = 0;
}

multiclass ST_Types<string opName, bits<16> BrigVal> {
  def _U8 : ST<opName, BrigVal, store_u32.op_ins>,
            LdStVectorMap<NAME#"_U8", 1>;

  def _U16 : ST<opName, BrigVal, store_u32.op_ins>,
             LdStVectorMap<NAME#"_U16", 1>;

  def _U32 : ST<opName, BrigVal, store_u32.op_ins>,
             LdStVectorMap<NAME#"_U32", 1>;
  def _F32 : ST<opName, BrigVal, store_f32.op_ins>,
             LdStVectorMap<NAME#"_F32", 1>;

  def _U64 : ST<opName, BrigVal, store_u64.op_ins>,
             LdStVectorMap<NAME#"_U64", 1>;
  def _F64 : ST<opName, BrigVal, store_f64.op_ins>,
             LdStVectorMap<NAME#"_F64", 1>;


  def _V2_U8 : ST<opName, BrigVal, store_v2_u32.op_ins>,
                LdStVectorMap<NAME#"_U8", 2>;
  def _V2_U16 : ST<opName, BrigVal, store_v2_u32.op_ins>,
                LdStVectorMap<NAME#"_U16", 2>;

  def _V2_U32 : ST<opName, BrigVal, store_v2_u32.op_ins>,
                LdStVectorMap<NAME#"_U32", 2>;
  def _V2_F32 : ST<opName, BrigVal, store_v2_f32.op_ins>,
                LdStVectorMap<NAME#"_F32", 2>;

  def _V2_U64 : ST<opName, BrigVal, store_v2_u64.op_ins>,
                LdStVectorMap<NAME#"_U64", 2>;
  def _V2_F64 : ST<opName, BrigVal, store_v2_f64.op_ins>,
                LdStVectorMap<NAME#"_F64", 2>;


  def _V3_U8 : ST<opName, BrigVal, store_v3_u32.op_ins>,
               LdStVectorMap<NAME#"_U8", 3>;
  def _V3_U16 : ST<opName, BrigVal, store_v3_u32.op_ins>,
                LdStVectorMap<NAME#"_U16", 3>;

  def _V3_U32 : ST<opName, BrigVal, store_v3_u32.op_ins>,
                LdStVectorMap<NAME#"_U32", 3>;
  def _V3_F32 : ST<opName, BrigVal, store_v3_f32.op_ins>,
                LdStVectorMap<NAME#"_F32", 3>;

  def _V3_U64 : ST<opName, BrigVal, store_v3_u64.op_ins>,
                LdStVectorMap<NAME#"_U64", 3>;
  def _V3_F64 : ST<opName, BrigVal, store_v3_f64.op_ins>,
                LdStVectorMap<NAME#"_F64", 3>;


  def _V4_U8 : ST<opName, BrigVal, store_v4_u32.op_ins>,
                LdStVectorMap<NAME#"_U8", 4>;

  def _V4_U16 : ST<opName, BrigVal, store_v4_u32.op_ins>,
                LdStVectorMap<NAME#"_U16", 4>;

  def _V4_U32 : ST<opName, BrigVal, store_v4_u32.op_ins>,
                LdStVectorMap<NAME#"_U32", 4>;
  def _V4_F32 : ST<opName, BrigVal, store_v4_f32.op_ins>,
                LdStVectorMap<NAME#"_F32", 4>;

  def _V4_U64 : ST<opName, BrigVal, store_v4_u64.op_ins>,
                LdStVectorMap<NAME#"_U64", 4>;
  def _V4_F64 : ST<opName, BrigVal, store_v4_f64.op_ins>,
                LdStVectorMap<NAME#"_F64", 4>;
}

// InstAtomic
class HSAILInstAtomic<bits<16> BrigVal,
                        dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let hasSideEffects = 1;
  let mayLoad = 1;
  let mayStore = 1;
  let InstAtomic = 1;

  int atomicOperation = ?;
}

class InstAtomic_0Op<string opName, bits<16> BrigVal,
                     int opVal, HSAILProfile P, string noRetOp = ""> :
  HSAILInstAtomic<
    BrigVal,
    (outs P.DestRC:$dest),
    (ins BrigAtomicOperation:$op,
         AddressSpace:$segment,
         BrigMemoryOrder:$order,
         BrigMemoryScope:$scope,
         equiv:$equiv,
         MEMOP:$address,
         BrigType:$TypeLength),
    opName#"$segment$order$scope$equiv$TypeLength\t$dest, $address"
>, AtomicNoRet<noRetOp, 1> {
  let atomicOperation = opVal;
}

class InstAtomic_1Op<string opName, bits<16> BrigVal,
                     int opVal, HSAILProfile P, string noRetOp = ""> :
  HSAILInstAtomic<
    BrigVal,
    (outs P.DestRC:$dest),
    (ins BrigAtomicOperation:$op,
         AddressSpace:$segment,
         BrigMemoryOrder:$order,
         BrigMemoryScope:$scope,
         equiv:$equiv,
         MEMOP:$address,
         P.Src0RC:$src0,
         BrigType:$TypeLength),
    opName#"$segment$order$scope$equiv$TypeLength\t$dest, $address, $src0"
>, AtomicNoRet<noRetOp, 1> {
  let atomicOperation = opVal;
}

class InstAtomic_2Op<string opName, bits<16> BrigVal,
                     int opVal, HSAILProfile P, string noRetOp = ""> :
  HSAILInstAtomic<
    BrigVal,
    (outs P.DestRC:$dest),
    (ins BrigAtomicOperation:$op,
         AddressSpace:$segment,
         BrigMemoryOrder:$order,
         BrigMemoryScope:$scope,
         equiv:$equiv,
         MEMOP:$address,
         P.Src0RC:$src0,
         P.Src1RC:$src1,
         BrigType:$TypeLength),
    opName#"$segment$order$scope$equiv$TypeLength\t$dest, $address, $src0, $src1"
>, AtomicNoRet<noRetOp, 1> {
  let atomicOperation = opVal;
}

multiclass InstAtomic_0Op_BitTypes<string opName, bits<16> BrigVal,
                                   int opVal, string noRetOp = ""> {
  def _B32 : InstAtomic_0Op<opName, BrigVal, opVal, Inst_B32, noRetOp#"_b32">;
  def _B64 : InstAtomic_0Op<opName, BrigVal, opVal, Inst_B64, noRetOp#"_b64">;
}

multiclass InstAtomic_1Op_BitTypes<string opName, bits<16> BrigVal,
                                   int opVal, string noRetOp = ""> {
  def _B32 : InstAtomic_1Op<opName, BrigVal, opVal, Inst_B32_B32, noRetOp#"_b32">;
  def _B64 : InstAtomic_1Op<opName, BrigVal, opVal, Inst_B64_B64, noRetOp#"_b64">;
}

multiclass InstAtomic_2Op_BitTypes<string opName, bits<16> BrigVal, int opVal, string noRetOp = ""> {
  def _B32 : InstAtomic_2Op<opName, BrigVal, opVal, Inst_B32_B32_B32, noRetOp#"_b32">;
  def _B64 : InstAtomic_2Op<opName, BrigVal, opVal, Inst_B64_B64_B64, noRetOp#"_b64">;
}

multiclass InstAtomic_1Op_IntTypes<string opName, bits<16> BrigVal, int opVal, string noRetOp = ""> {
  def _S32 : InstAtomic_1Op<opName, BrigVal, opVal, Inst_S32_S32, noRetOp#"_s32">;
  def _S64 : InstAtomic_1Op<opName, BrigVal, opVal, Inst_S64_S64, noRetOp#"_s64">;

  def _U32 : InstAtomic_1Op<opName, BrigVal, opVal, Inst_U32_U32, noRetOp#"_u32">;
  def _U64 : InstAtomic_1Op<opName, BrigVal, opVal, Inst_U64_U64, noRetOp#"_u64">;
}

class InstAtomic_0Op_NoRet<string opName, bits<16> BrigVal, int opVal,
                           HSAILProfile P, string typeSuffix> :
  HSAILInstAtomic<
    BrigVal,
    (outs),
    (ins BrigAtomicOperation:$op,
         AddressSpace:$segment,
         BrigMemoryOrder:$order,
         BrigMemoryScope:$scope,
         equiv:$equiv,
         MEMOP:$address,
         BrigType:$TypeLength),
    opName#"$segment$order$scope$equiv$TypeLength\t$address"
>, AtomicNoRet<opName#typeSuffix, 0> {
  let atomicOperation = opVal;
}

class InstAtomic_1Op_NoRet<string opName, bits<16> BrigVal,
                           int opVal, HSAILProfile P,
                           string typeSuffix> :
  HSAILInstAtomic<
    BrigVal,
    (outs),
    (ins BrigAtomicOperation:$op,
         AddressSpace:$segment,
         BrigMemoryOrder:$order,
         BrigMemoryScope:$scope,
         equiv:$equiv,
         MEMOP:$address,
         P.Src0RC:$src0,
         BrigType:$TypeLength),
    opName#"$segment$order$scope$equiv$TypeLength\t$address, $src0"
>, AtomicNoRet<opName#typeSuffix, 0> {
  let atomicOperation = opVal;
}

class InstAtomic_2Op_NoRet<string opName, bits<16> BrigVal, int opVal,
                           HSAILProfile P, string typeSuffix> :
  HSAILInstAtomic<
    BrigVal,
    (outs),
    (ins BrigAtomicOperation:$op,
         AddressSpace:$segment,
         BrigMemoryOrder:$order,
         BrigMemoryScope:$scope,
         equiv:$equiv,
         MEMOP:$address,
         P.Src0RC:$src0,
         P.Src1RC:$src1,
         BrigType:$TypeLength),
    opName#"$segment$order$scope$equiv$TypeLength\t$address, $src0, $src1"
>, AtomicNoRet<opName#typeSuffix, 0> {
  let atomicOperation = opVal;
}

multiclass InstAtomic_1Op_NoRet_BitTypes<string opName, bits<16> BrigVal, int opVal> {
  def _B32 : InstAtomic_1Op_NoRet<opName, BrigVal, opVal, Inst_Void_B32, "_b32">;
  def _B64 : InstAtomic_1Op_NoRet<opName, BrigVal, opVal, Inst_Void_B64, "_b64">;
}

multiclass InstAtomic_1Op_NoRet_IntTypes<string opName, bits<16> BrigVal, int opVal> {
  def _S32 : InstAtomic_1Op_NoRet<opName, BrigVal, opVal, Inst_Void_S32, "_s32">;
  def _S64 : InstAtomic_1Op_NoRet<opName, BrigVal, opVal, Inst_Void_S64, "_s64">;

  def _U32 : InstAtomic_1Op_NoRet<opName, BrigVal, opVal, Inst_Void_U32, "_u32">;
  def _U64 : InstAtomic_1Op_NoRet<opName, BrigVal, opVal, Inst_Void_U64, "_u64">;
}

// InstCmp
class HSAILInstCmp<bits<16> BrigVal,
                   dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let hasSideEffects = 0;
  let InstCmp = 1;
  let isCompare = 1;
}

class InstCmp<string opName, bits<16> BrigVal, HSAILProfile P> :
  HSAILInstCmp<BrigVal,
    (outs P.DestRC:$dest),
    (ins BrigCompareOperation:$op,
         ftz:$ftz,
         P.Src0RC:$src0,
         P.Src1RC:$src1,
         BrigType:$destTypedestLength,
         BrigType:$sourceType),
    opName#"$op$ftz$destTypedestLength$sourceType\t$dest, $src0, $src1"
>;

multiclass InstCmp_CmpTypes<string opName, bits<16> BrigVal, BRIGType destTy> {
  def _B1 : InstCmp<opName, BrigVal, !cast<HSAILProfile>("Inst"#destTy.InstName#"_B1_B1")>;
  def _S32 : InstCmp<opName, BrigVal, !cast<HSAILProfile>("Inst"#destTy.InstName#"_S32_S32")>;
  def _S64 : InstCmp<opName, BrigVal, !cast<HSAILProfile>("Inst"#destTy.InstName#"_S64_S64")>;
  def _U32 : InstCmp<opName, BrigVal, !cast<HSAILProfile>("Inst"#destTy.InstName#"_U32_U32")>;
  def _U64 : InstCmp<opName, BrigVal, !cast<HSAILProfile>("Inst"#destTy.InstName#"_U64_U64")>;
  def _F32 : InstCmp<opName, BrigVal, !cast<HSAILProfile>("Inst"#destTy.InstName#"_F32_F32")>;
  def _F64 : InstCmp<opName, BrigVal, !cast<HSAILProfile>("Inst"#destTy.InstName#"_F64_F64")>;
}

// TODO: Support for other return types.
multiclass InstCmp_RetTypes<string opName, bits<16> BrigVal> {
  defm _B1 : InstCmp_CmpTypes<opName, BrigVal, B1Ty>;
  // defm _S32 : InstCmp_CmpTypes<opName, BrigVal, S32Ty>;
  // defm _U32 : InstCmp_CmpTypes<opName, BrigVal, U32Ty>;
  // defm _S64 : InstCmp_CmpTypes<opName, BrigVal, S64Ty>;
  // defm _U64 : InstCmp_CmpTypes<opName, BrigVal, U64Ty>;
  // defm _F32 : InstCmp_CmpTypes<opName, BrigVal, F32Ty>;
  // defm _F64 : InstCmp_CmpTypes<opName, BrigVal, F64Ty>;
}


// InstAddr
class HSAILInstAddr<bits<16> BrigVal,
                    dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let hasSideEffects = 0;
  let InstAddr = 1;
}

class HSAILInstAddr_1Op<string opName, bits<16> BrigVal, HSAILProfile P> :
  HSAILInstAddr<BrigVal,
                (outs P.DestRC:$dest),
                (ins BrigSegment:$segment, MEMOP:$address, BrigType:$TypeLength),
  opName#"$segment$TypeLength\t$dest, $address"
>;

multiclass InstAddr_1Op_PtrTypes<string opName, bits<16> BrigVal> {
  def _U32 : HSAILInstAddr_1Op<opName, BrigVal, Inst_U32_U32>;
  def _U64 : HSAILInstAddr_1Op<opName, BrigVal, Inst_U64_U64>;
}

// InstImage
class HSAILInstImage<bits<16> BrigVal,
                     dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let mayLoad = 1;
  let mayStore = 1;
  let InstImage = 1;
}

class HSAILInstImage_Ld_1D<string opName, bits<16> BrigVal> :
  HSAILInstImage<BrigVal,
                (outs GPR32:$destR, GPR32:$destG, GPR32:$destB, GPR32:$destA),
                (ins v4mod:$v4,
                     BrigType:$imageType,
                     BrigType:$coordType,
                     BrigImageGeometry:$geometry,
                     equiv:$equiv,
                     GPR64:$image,
                     GPR64:$sampler,
                     GPR32:$coordWidth,
                     BrigType:$destType),
  opName#"$v4$geometry$equiv$destType$imageType$coordType\t($destR, $destG, $destB, $destA), $image, $sampler, $coordWidth"> {
  let mayStore = 0;
}

////////////////////////////////////////////////////////////////////////////////
// Basic instruction patterns
////////////////////////////////////////////////////////////////////////////////

class InstBasic_0Op_Pat<HSAILInst inst,
                        SDPatternOperator node,
                        ValueType vt,
                        int bt> : Pat <
  (vt (node)),
  (inst bt)
>;

class InstBasic_0Op_NoRet_Pat<HSAILInst inst,
                             SDPatternOperator node> : Pat <
  (node),
  (inst BrigType.NONE)
>;

class InstBasic_1Op_Pat<HSAILInst inst,
                        SDPatternOperator node,
                        ValueType vt,
                        int bt> : Pat <
  (vt (node (vt (GPROrImm vt:$src0)))),
  (inst $src0, bt)
>;

// 1 operand is always i32 immediate
class GridSize_Pat<HSAILInst inst,
                   SDPatternOperator node,
                   ValueType vt,
                   int bt> : Pat <
  (vt (node i32:$src0)),
  (inst imm:$src0, bt)
>;

multiclass InstBasic_1Op_IntTypes_Pat<string inst,
                                      SDPatternOperator node,
                                      bit signed = 0> {
  def : InstBasic_1Op_Pat<!cast<HSAILInst>(inst#!if(signed, "_S32", "_U32")), node, i32,
    !if(signed, BrigType.S32, BrigType.U32)
  >;

  def : InstBasic_1Op_Pat<!cast<HSAILInst>(inst#!if(signed, "_S64", "_U64")), node, i64,
    !if(signed, BrigType.S64, BrigType.U64)
  >;
}

multiclass InstBasic_1Op_BitTypes_Pat<string inst,
                                      SDPatternOperator node,
                                      bit signed = 0> {
  def : InstBasic_1Op_Pat<!cast<HSAILInst>(inst#"_B32"), node, i32,
    BrigType.B32
  >;

  def : InstBasic_1Op_Pat<!cast<HSAILInst>(inst#"_B64"), node, i64,
    BrigType.B64
  >;

  def : InstBasic_1Op_Pat<!cast<HSAILInst>(inst#"_B1"), node, i1,
    BrigType.B1
  >;
}

multiclass InstBasic_1Op_FPTypes_Pat<string inst,
                                     SDPatternOperator node> {
  def : InstBasic_1Op_Pat<!cast<HSAILInst>(inst#"_F32"), node, f32, BrigType.F32>;
  def : InstBasic_1Op_Pat<!cast<HSAILInst>(inst#"_F64"), node, f64, BrigType.F64>;
}

class InstBasic_2Op_Pat<HSAILInst inst,
                        SDPatternOperator node,
                        ValueType vt0,
                        ValueType vt1,
                        int bt> : Pat <
  (vt0 (node (GPROrImm vt0:$src0), (vt1 (GPROrImm vt1:$src1)))),
  (inst $src0, $src1, bt)
>;

class InstBasic_2Op_RetType_Pat<HSAILInst inst,
                                SDPatternOperator node,
                                ValueType destvt,
                                ValueType vt0,
                                ValueType vt1,
                                int bt> : Pat <
  (destvt (node (GPROrImm vt0:$src0), (vt1 (GPROrImm vt1:$src1)))),
  (inst $src0, $src1, bt)
>;

multiclass InstBasic_2Op_BitRetType_U32_U32_Pat<string inst,
                                                SDPatternOperator node> {
  def : InstBasic_2Op_RetType_Pat<!cast<HSAILInst>(inst#"_B32"),
    node, i32, i32, i32, BrigType.B32
  >;

  def : InstBasic_2Op_RetType_Pat<!cast<HSAILInst>(inst#"_B64"),
    node, i64, i32, i32, BrigType.B64
  >;
}

multiclass InstBasic_2Op_IntTypes_Pat<string inst,
                                      SDPatternOperator node,
                                      bit signed = 0> {
  def : InstBasic_2Op_Pat<!cast<HSAILInst>(inst#!if(signed, "_S32", "_U32")), node, i32, i32,
    !if(signed, BrigType.S32, BrigType.U32)
  >;

  def : InstBasic_2Op_Pat<!cast<HSAILInst>(inst#!if(signed, "_S64", "_U64")), node, i64, i64,
    !if(signed, BrigType.S64, BrigType.U64)
  >;
}

multiclass InstBasic_2Op_BitIntTypes_Pat<string inst,
                                         SDPatternOperator node> {
  def : InstBasic_2Op_Pat<!cast<HSAILInst>(inst#"_B32"), node, i32, i32,
    BrigType.B32
  >;

  def : InstBasic_2Op_Pat<!cast<HSAILInst>(inst#"_B64"), node, i64, i64,
    BrigType.B64
  >;

  def : InstBasic_2Op_Pat<!cast<HSAILInst>(inst#"_B1"), node, i1, i1,
    BrigType.B1
  >;
}

multiclass InstBasic_2Op_FPTypes_Pat<HSAILInst inst,
                                     SDPatternOperator node> {
  def : InstBasic_2Op_Pat<inst, node, f32, f32, BrigType.F32>;
  def : InstBasic_2Op_Pat<inst, node, f64, f64, BrigType.F64>;
}

class InstBasic_3Op_Pat<HSAILInst inst,
                        SDPatternOperator node,
                        ValueType vt,
                        int bt> : Pat <
  (node (vt (GPROrImm vt:$src0)), (vt (GPROrImm vt:$src1)), (vt (GPROrImm vt:$src2))),
  (inst $src0, $src1, $src2, bt)
>;
multiclass InstBasic_3Op_IntTypes_Pat<string inst,
                                      SDPatternOperator node,
                                      bit signed = 0> {
  def : InstBasic_3Op_Pat<!cast<HSAILInst>(inst# !if(signed, "_S32", "_U32")), node, i32,
    !if(signed, BrigType.S32, BrigType.U32)
  >;

  def : InstBasic_3Op_Pat<!cast<HSAILInst>(inst# !if(signed, "_S64", "_U64")), node, i64,
    !if(signed, BrigType.S64, BrigType.U64)
  >;
}

// XXX - b1 missing intentionally with current set of instructions.
multiclass InstBasic_3Op_BitTypes_Pat<string inst,
                                      SDPatternOperator node> {
  def : InstBasic_3Op_Pat<!cast<HSAILInst>(inst#"_B32"), node, i32, BrigType.B32>;
  def : InstBasic_3Op_Pat<!cast<HSAILInst>(inst#"_B64"), node, i64, BrigType.B64>;
}

multiclass InstBasic_3Op_FPTypes_Pat<string inst,
                                     SDPatternOperator node> {
  def : InstBasic_3Op_Pat<!cast<HSAILInst>(inst#"_F32"), node, f32, BrigType.F32>;
  def : InstBasic_3Op_Pat<!cast<HSAILInst>(inst#"_F64"), node, f64, BrigType.F64>;
}

class InstBasic_CMov_Pat<HSAILInst inst,
                         ValueType vt,
                         int bt> : Pat <
  (select i1:$src0, (GPROrImm vt:$src1), (GPROrImm vt:$src2)),
  (vt (inst $src0, $src1, $src2, bt))
>;

class InstBasic_3Op_BitExtract_Pat<HSAILInst inst,
                                   SDPatternOperator node,
                                   ValueType vt,
                                   int bt> : Pat <
  (node (vt (GPROrImm vt:$src0)), (i32 (GPROrImm i32:$src1)), (i32 (GPROrImm i32:$src2))),
  (inst $src0, $src1, $src2, bt)
>;

multiclass InstBasic_3Op_BitExtract_IntTypes_Pat<string inst, SDPatternOperator node, bit signed> {
  def : InstBasic_3Op_BitExtract_Pat<!cast<HSAILInst>(inst# !if(signed, "_S32", "_U32")), node, i32,
    !if(signed, BrigType.S32, BrigType.U32)
  >;

  def : InstBasic_3Op_BitExtract_Pat<!cast<HSAILInst>(inst# !if(signed, "_S64", "_U64")), node, i64,
    !if(signed, BrigType.S64, BrigType.U64)
  >;
}

class InstBasic_4Op_BitInsert_Pat<HSAILInst inst,
                                  SDPatternOperator node,
                                  ValueType vt,
                                  int bt> : Pat <
  (node (vt (GPROrImm vt:$src0)),
        (vt (GPROrImm vt:$src1)),
        (i32 (GPROrImm i32:$src2)),
        (i32 (GPROrImm i32:$src3))),
  (inst $src0, $src1, $src2, $src3, bt)
>;

multiclass InstBasic_4Op_BitInsert_IntTypes_Pat<string inst, SDPatternOperator node, bit signed> {
  def : InstBasic_4Op_BitInsert_Pat<!cast<HSAILInst>(inst# !if(signed, "_S32", "_U32")), node, i32,
    !if(signed, BrigType.S32, BrigType.U32)
  >;

  def : InstBasic_4Op_BitInsert_Pat<!cast<HSAILInst>(inst# !if(signed, "_S64", "_U64")), node, i64,
    !if(signed, BrigType.S64, BrigType.U64)
  >;
}

////////////////////////////////////////////////////////////////////////////////
// Mod instruction patterns
////////////////////////////////////////////////////////////////////////////////

class InstMod_1Op_Pat<HSAILInst inst,
                      SDPatternOperator node,
                      ValueType vt,
                      int bt,
                      int round = BrigRound.NONE,
                      int ftz = 0> : Pat <
  (vt (node (GPROrImm vt:$src0))),
  (inst ftz, round, $src0, bt)
>;

class InstMod_1Op_Intrin_Pat<HSAILInst inst,
                             SDPatternOperator node,
                             ValueType vt,
                             int bt> : Pat <
  (vt (node i1:$ftz, i32:$round, (vt (GPROrImm vt:$src0)))),
  (inst imm:$ftz, imm:$round, $src0, bt)
>;

class InstMod_2Op_Pat<HSAILInst inst,
                      SDPatternOperator node,
                      ValueType vt,
                      int bt,
                      int round = BrigRound.NONE,
                      int ftz = 0> : Pat <
  (vt (node (vt (GPROrImm vt:$src0)), (vt (GPROrImm vt:$src1)))),
  (inst ftz, round, $src0, $src1, bt)
>;

class InstMod_2Op_Intrin_Pat<HSAILInst inst,
                             SDPatternOperator node,
                             ValueType vt,
                             int bt> : Pat <
  (vt (node i1:$ftz,
            i32:$round,
            (vt (GPROrImm vt:$src0)),
            (vt (GPROrImm vt:$src1)))),
  (inst imm:$ftz, imm:$round, $src0, $src1, bt)
>;

class InstMod_2Op_NoRound_Intrin_Pat<HSAILInst inst,
                                     SDPatternOperator node,
                                     ValueType vt,
                                     int bt> : Pat <
  (vt (node i1:$ftz,
            (vt (GPROrImm vt:$src0)),
            (vt (GPROrImm vt:$src1)))),
  (inst imm:$ftz, BrigRound.NONE, $src0, $src1, bt)
>;

class InstMod_3Op_Pat<HSAILInst inst,
                      SDPatternOperator node,
                      ValueType vt,
                      int bt,
                      int round = BrigRound.NONE,
                      int ftz = 0> : Pat <
  (vt (node (GPROrImm vt:$src0), (GPROrImm vt:$src1), (GPROrImm vt:$src2))),
  (inst ftz, round, $src0, $src1, $src2, bt)
>;

multiclass InstMod_1Op_FPTypes_Pat<string inst,
                                   SDPatternOperator node,
                                   int round = BrigRound.FLOAT_DEFAULT> {
  def : InstMod_1Op_Pat<!cast<HSAILInst>(inst#"_F32"), node, f32, BrigType.F32, round, 1>;
  def : InstMod_1Op_Pat<!cast<HSAILInst>(inst#"_F64"), node, f64, BrigType.F64, round, 0>;
}

multiclass InstMod_1Op_FPTypes_Intrin_Pat<string inst,
                                          SDPatternOperator node> {
  def : InstMod_1Op_Intrin_Pat<!cast<HSAILInst>(inst#"_F32"), node, f32, BrigType.F32>;
  def : InstMod_1Op_Intrin_Pat<!cast<HSAILInst>(inst#"_F64"), node, f64, BrigType.F64>;
}

multiclass InstMod_2Op_IntTypes_Pat<string inst,
                                   SDPatternOperator node,
                                   bit signed = 0> {
  def : InstMod_2Op_Pat<!cast<HSAILInst>(inst# !if(signed, "_S32", "_U32")), node, i32,
    !if(signed, BrigType.S32, BrigType.U32)
  >;

  def : InstMod_2Op_Pat<!cast<HSAILInst>(inst# !if(signed, "_S64", "_U64")), node, i64,
    !if(signed, BrigType.S64, BrigType.U64)
  >;
}

multiclass InstMod_2Op_FPTypes_Pat<string inst,
                                   SDPatternOperator node,
                                   int round = BrigRound.FLOAT_DEFAULT> {
  def : InstMod_2Op_Pat<!cast<HSAILInst>(inst#"_F32"), node, f32, BrigType.F32, round, 1>;
  def : InstMod_2Op_Pat<!cast<HSAILInst>(inst#"_F64"), node, f64, BrigType.F64, round, 0>;
}

multiclass InstMod_2Op_Intrin_FPTypes_Pat<string inst,
                                          SDPatternOperator node> {
  def : InstMod_2Op_Intrin_Pat<!cast<HSAILInst>(inst#"_F32"), node, f32, BrigType.F32>;
  def : InstMod_2Op_Intrin_Pat<!cast<HSAILInst>(inst#"_F64"), node, f64, BrigType.F64>;
}

multiclass InstMod_3Op_FPTypes_Pat<string inst,
                                   SDPatternOperator node> {
  def : InstMod_3Op_Pat<!cast<HSAILInst>(inst#"_F32"), node, f32, BrigType.F32, BrigRound.FLOAT_DEFAULT, 1>;
  def : InstMod_3Op_Pat<!cast<HSAILInst>(inst#"_F64"), node, f64, BrigType.F64, BrigRound.FLOAT_DEFAULT, 0>;
}

////////////////////////////////////////////////////////////////////////////////
// SourceType instruction patterns
////////////////////////////////////////////////////////////////////////////////

class InstSourceType_1Op_Pat<HSAILInst inst,
                             SDPatternOperator node,
                             ValueType destvt,
                             ValueType srcvt,
                             int destbt,
                             int srcbt> : Pat <
  (destvt (node (srcvt (GPROrImm srcvt:$src0)))),
  (inst $src0, destbt, srcbt)
>;

class InstSourceType_2Op_Pat<HSAILInst inst,
                             SDPatternOperator node,
                             ValueType vt,
                             int destbt,
                             int srcbt> : Pat <
  (vt (node (GPROrImm vt:$src0), (GPROrImm vt:$src1))),
  (inst $src0, $src1, destbt, srcbt)
>;

class InstSourceType_Class_Pat<HSAILInst inst,
                              SDPatternOperator node,
                              ValueType vt,
                              int srcbt> : Pat <
  (i1 (node (vt (GPROrImm vt:$src0)), (i32 (GPROrImm i32:$src1)))),
  (inst $src0, $src1, BrigType.B1, srcbt)
>;

class InstSourceType_3Op_Pat<HSAILInst inst,
                             SDPatternOperator node,
                             ValueType vt,
                             int destbt,
                             int srcbt> : Pat <
  (vt (node (GPROrImm vt:$src0), (GPROrImm vt:$src1), (GPROrImm vt:$src2))),
  (inst $src0, $src1, $src2, destbt, srcbt)
>;

class InstSourceType_4Op_Pat<HSAILInst inst,
                             SDPatternOperator node,
                             ValueType vt,
                             int destbt,
                             int srcbt> : Pat <
  (node (GPROrImm vt:$src0),
        (GPROrImm vt:$src1),
        (GPROrImm vt:$src2),
        (GPROrImm vt:$src3)),
  (inst $src0, $src1, $src2, $src3, destbt, srcbt)
>;

////////////////////////////////////////////////////////////////////////////////
// Lane instruction patterns
////////////////////////////////////////////////////////////////////////////////

class ActiveLanePermutePat<Instruction inst,
                           SDPatternOperator node,
                           ValueType vt,
                           int bt> : Pat<
  (vt (node (i32 timm:$width),
            (vt (GPROrImm vt:$src0)),
            (i32 (GPROrImm i32:$src1)),
            (vt (GPROrImm vt:$src2)),
            (i1 (GPROrImm i1:$src3)))),
  (inst (i32 $width), $src0, $src1, $src2, $src3, bt, BrigType.NONE)
>;

class ActiveLaneIdPat<Instruction inst,
                      SDPatternOperator node,
                      ValueType vt,
                      int bt> : Pat<
  (vt (node (i32 timm:$width))),
  (inst $width, bt, BrigType.NONE)
>;

class ActiveLaneCountPat<Instruction inst,
                      SDPatternOperator node,
                      ValueType vt,
                      int bt> : Pat<
  (vt (node (i32 timm:$width), (i1 (GPROrImm i1:$src0)))),
  (inst $width, $src0, bt, BrigType.B1)
>;

////////////////////////////////////////////////////////////////////////////////
// Br instruction patterns
////////////////////////////////////////////////////////////////////////////////

class InstBr_0Op_NoRet_Pat<HSAILInst inst,
                           SDPatternOperator node,
                           int width = BrigWidth._1> : Pat <
  (node),
  (inst width, BrigType.NONE)
>;

class InstBr_0Op_NoRet_Intrin_Pat<HSAILInst inst,
                                  SDPatternOperator node> : Pat <
  (node i32:$width),
  (inst imm:$width, BrigType.NONE)
>;

class InstBr_0Op_Pat<HSAILInst inst,
                     SDPatternOperator node,
                     int bt,
                     int width = BrigWidth._1> : Pat <
  (vt (node)),
  (inst width, bt)
>;

////////////////////////////////////////////////////////////////////////////////
// Seg instruction patterns
////////////////////////////////////////////////////////////////////////////////


class InstSeg_0Op_Pat<HSAILInst inst,
                      SDPatternOperator node,
                      ValueType vt,
                      int bt,
                      int segment> : Pat <
  (vt (node)),
  (inst segment, bt)
>;

////////////////////////////////////////////////////////////////////////////////
// Addr instruction patterns
////////////////////////////////////////////////////////////////////////////////

class InstAddr_1Op_Pat<HSAILInst inst,
                      SDPatternOperator node,
                      int bt,
                      int segment> : Pat <
  (node ADDR:$address),
  (inst segment, MEMOP:$address, bt)
>;

////////////////////////////////////////////////////////////////////////////////
// Atomic instruction patterns
////////////////////////////////////////////////////////////////////////////////

class AtomicPat_0Op_Pat<HSAILInstAtomic inst, SDPatternOperator node,
                        ValueType vt, int bt> : Pat<
  (node (AtomicAddr AddressSpace:$segment,
                    BrigMemoryOrder:$order,
                    BrigMemoryScope:$scope,
                    equiv:$equiv,
                    MEMOP:$address)),
  (vt (inst inst.atomicOperation,
            $segment,
            $order,
            $scope,
            $equiv,
            MEMOP:$address,
            bt))
>;

class AtomicPat_1Op_Pat<HSAILInstAtomic inst, SDPatternOperator node,
                        ValueType vt, int bt> : Pat<
  (node (AtomicAddr AddressSpace:$segment,
                    BrigMemoryOrder:$order,
                    BrigMemoryScope:$scope,
                    equiv:$equiv,
                    MEMOP:$address),
         (GPROrImm vt:$src0)),
  (vt (inst inst.atomicOperation,
            $segment,
            $order,
            $scope,
            $equiv,
            MEMOP:$address,
            $src0,
            bt))
>;

class AtomicPat_2Op_Pat<HSAILInstAtomic inst, SDPatternOperator node,
                        ValueType vt, int bt> : Pat<
  (node (AtomicAddr AddressSpace:$segment,
                    BrigMemoryOrder:$order,
                    BrigMemoryScope:$scope,
                    equiv:$equiv,
                    MEMOP:$address),
         (GPROrImm vt:$src0),
         (GPROrImm vt:$src1)),
  (vt (inst inst.atomicOperation,
            $segment,
            $order,
            $scope,
            $equiv,
            MEMOP:$address,
            vt:$src0,
            vt:$src1,
            bt))
>;

class AtomicPat_1Op_NoRet_Pat<HSAILInstAtomic inst, SDPatternOperator node,
                              ValueType vt, int bt> : Pat<
  (node (AtomicAddr AddressSpace:$segment,
                    BrigMemoryOrder:$order,
                    BrigMemoryScope:$scope,
                    equiv:$equiv,
                    MEMOP:$address),
        (vt (GPROrImm vt:$src0))),
  (inst inst.atomicOperation,
        $segment,
        $order,
        $scope,
        $equiv,
        MEMOP:$address,
        vt:$src0,
        bt)
>;

multiclass AtomicPat_0Op_BitTypes<string inst,
                                  SDPatternOperator node> {
  def : AtomicPat_0Op_Pat<
    !cast<HSAILInstAtomic>(inst#"_B32"), node, i32, BrigType.B32
  >;

  def : AtomicPat_0Op_Pat<
    !cast<HSAILInstAtomic>(inst#"_B64"), node, i64, BrigType.B64
  >;
}

multiclass AtomicPat_1Op_IntTypes<string inst,
                                  SDPatternOperator node,
                                  bit signed = 0> {
  def : AtomicPat_1Op_Pat<
    !cast<HSAILInstAtomic>(inst#!if(signed, "_S32", "_U32")), node, i32,
    !if(signed, BrigType.S32, BrigType.U32)
  >;

  def : AtomicPat_1Op_Pat<
    !cast<HSAILInstAtomic>(inst#!if(signed, "_S64", "_U64")), node, i64,
    !if(signed, BrigType.S64, BrigType.U64)
  >;
}

multiclass AtomicPat_1Op_BitTypes<string inst,
                                  SDPatternOperator node> {
  def : AtomicPat_1Op_Pat<
    !cast<HSAILInstAtomic>(inst#"_B32"), node, i32, BrigType.B32
  >;

  def : AtomicPat_1Op_Pat<
    !cast<HSAILInstAtomic>(inst#"_B64"), node, i64, BrigType.B64
  >;
}

multiclass AtomicPat_1Op_NoRet_BitTypes<string inst,
                                        SDPatternOperator node> {
  def : AtomicPat_1Op_NoRet_Pat<
    !cast<HSAILInstAtomic>(inst#"_B32"), node, i32, BrigType.B32
  >;

  def : AtomicPat_1Op_NoRet_Pat<
    !cast<HSAILInstAtomic>(inst#"_B64"), node, i64, BrigType.B64
  >;
}

multiclass AtomicPat_2Op_BitTypes<string inst,
                                  SDPatternOperator node> {
  def : AtomicPat_2Op_Pat<
    !cast<HSAILInstAtomic>(inst#"_B32"), node, i32, BrigType.B32
  >;

  def : AtomicPat_2Op_Pat<
    !cast<HSAILInstAtomic>(inst#"_B64"), node, i64, BrigType.B64
  >;
}

def target : Operand<OtherVT> {}
