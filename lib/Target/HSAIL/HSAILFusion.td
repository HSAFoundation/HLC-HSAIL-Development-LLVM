//===--- HSAILFusion.td - Fused instructions -------------*- tablegen -*---===//
//
// Fused instruction patterns
//
// This files contains optimizations, rather than definitions essential for the
// codegeneration.
//
//===----------------------------------------------------------------------===//
////////////////////////////////////////////////////////////////////////////////
// llc command line options predicates
def EnableFPMAD        : Predicate<"CurDAG->getTarget().Options.LessPreciseFPMAD()">;
def UnsafeFPMath       : Predicate<"CurDAG->getTarget().Options.UnsafeFPMath">;
def NoInfsFPMath       : Predicate<"CurDAG->getTarget().Options.NoInfsFPMath">;
def NoNaNsFPMath       : Predicate<"CurDAG->getTarget().Options.NoNaNsFPMath">;
def EnableGCNMinMax    : Predicate<"llvm::EnableGCNMinMax">;

////////////////////////////////////////////////////////////////////////////////
// fused operation multiclasses
multiclass TernaryFusedPairOp<Instruction inst,
                              ValueType Ty, SDNode ImmTy,
                              RegisterClass RC, SDNode op1, SDNode op2, int bt> {
  def _rrr : Pat<
    (op1 (op2 RC:$src0, RC:$src1), RC:$src2),
    (inst RC:$src0, RC:$src1, RC:$src2, bt)
  >;

  def _rri : Pat<
    (op1 (op2 RC:$src0, RC:$src1), (Ty ImmTy:$src2)),
    (inst RC:$src0, RC:$src1, ImmTy:$src2, bt)
  >;

  def _rir : Pat<
    (op1 (op2 RC:$src0, (Ty ImmTy:$src1)), RC:$src2),
    (inst RC:$src0, ImmTy:$src1, RC:$src2, bt)
  >;

  def _rii : Pat<
    (op1 (op2 RC:$src0, (Ty ImmTy:$src1)), (Ty ImmTy:$src2)),
    (inst RC:$src0, ImmTy:$src1, ImmTy:$src2, bt)
  >;
}

////////////////////////////////////////////////////////////////////////////////
// fused multiply-add
def getShiftMult32 : SDNodeXForm<imm, [{
    return CurDAG->getTargetConstant(1u << (N->getZExtValue()), MVT::i32);
}]>;

def getShiftMult64 : SDNodeXForm<imm, [{
    return CurDAG->getTargetConstant(((uint64_t)1u) << (N->getZExtValue()),
                                     MVT::i64);
}]>;

def shl32imm : PatLeaf<(imm), [{
    return N->getZExtValue() < 32;
}], getShiftMult32>;

def shl64imm : PatLeaf<(imm), [{
    return N->getZExtValue() < 64;
}], getShiftMult64>;


// Pre-optimized (const1 + (x << const2)) -> const1 | (x << const2).
// This requires mutual check of const1 and const2 to ensure last bit# set in
// const1 < const2 (i.e. or can be changed to add).
def orShlAsMad : PatFrag<
  (ops node:$reg, node:$shift, node:$mask),
  (or (shl node:$reg, node:$shift), node:$mask), [{
    ConstantSDNode *CNShift, *CNMask;
    if ((CNShift = dyn_cast<ConstantSDNode>(N->getOperand(0)->getOperand(1))) &&
        (CNMask  = dyn_cast<ConstantSDNode>(N->getOperand(1)))) {
        return (CNMask->getZExtValue() >> CNShift->getZExtValue()) == 0;
    }
    return false;
}]>;

// 32 bit integer multiplication is expensive operation on current HW,
// The cost of 32 bit mul is 4 times higher than a cost of add. Therefor
// shift + add fusion is commented out as not beneficial at the moment.
// defm m2ad_u32 : TernaryFusedShlAdd<"mad_u32", i32, i32imm, shl32imm, GPR32>;
//
// There are no 64 bit muls and mads in SI, but there are 64 bit shifts and
// adds. Reversing shifts from multipier is an unneeded burden for SC.
// Therefor folding of shift + add is commented out for 64 bit ops unless we
// have a HW supporing 64 bit mads.
//
// let Predicates = [EnableOpt] in {
// defm m2ad_u64 : TernaryFusedShlAdd<"mad_u64", i64, i64imm, shl64imm, GPR64>;
// }

// We do not define 64 bit const1 | (x << const2) folding, as we have 64 bit
// or and shift, but no 64 bit mad.
// As 32 bit integer multiplication is curently expensive, optimization is
// commented out.
// let Predicates = [EnableOpt] in {
// def mor_u32 : Pat<(orShlAsMad GPR32:$src0,
//                               (i32 shl32imm:$src1), (i32 imm:$src2)),
//                   (umad_rii_u32 GPR32:$src0, shl32imm:$src1, imm:$src2)>;
// }

let Predicates = [EnableFPMAD] in {
  defm : TernaryFusedPairOp<nfma_inst, f32, fpimm, GPR32, fadd, fmul, BrigTypeX.F32>;
  defm : TernaryFusedPairOp<nfma_inst, f64, fpimm, GPR64, fadd, fmul, BrigTypeX.F64>;
}

////////////////////////////////////////////////////////////////////////////////
// bit strings
def imm31 : PatLeaf<(imm), [{
    return N->getZExtValue() == 31;
}]>;

def imm32 : PatLeaf<(imm), [{
    return N->getZExtValue() == 32;
}]>;

def imm63 : PatLeaf<(imm), [{
    return N->getZExtValue() == 63;
}]>;

// // Shifts do not need "and {31|63}, shift-bits".
// multiclass ShrOp<string asm, string t, SDNode op, RegisterClass RC,
//                  ValueType Ty, PatLeaf ShImm> {

//     def _rr : Pat<(op RC:$src0, (and GPR32:$src1, (i32 ShImm))),
//                   (!cast<HSAILInst>(asm##t) RC:$src0, GPR32:$src1)>;

//     def _ir : Pat<(op (Ty imm:$src0), (and GPR32:$src1, (i32 ShImm))),
//                   (!cast<HSAILInst>(asm#"_ir"#t) imm:$src0, GPR32:$src1)>;
// }

// let Predicates = [EnableOpt] in {
// defm shr_u32 : ShrOp<"shr", "_u32", srl, GPR32, i32, imm31>;
// defm shr_s32 : ShrOp<"shr", "_s32", sra, GPR32, i32, imm31>;
// defm shl_u32 : ShrOp<"shl", "_u32", shl, GPR32, i32, imm31>;
// defm shr_u64 : ShrOp<"shr", "_u64", srl, GPR64, i64, imm63>;
// defm shr_s64 : ShrOp<"shr", "_s64", sra, GPR64, i64, imm63>;
// defm shl_u64 : ShrOp<"shl", "_u64", shl, GPR64, i64, imm63>;
// }

def popCnt : SDNodeXForm<imm, [{
    return CurDAG->getTargetConstant(CountPopulation_64(N->getZExtValue()),
                                     MVT::i32);
}]>;

def isMask : PatLeaf<(imm), [{
    return isMask_64(N->getZExtValue());
}], popCnt>;

def extractShift : SDNodeXForm<imm, [{
    return CurDAG->getTargetConstant(N->getZExtValue(), MVT::i32);
}]>;

def isMax32bitShift : PatLeaf<(imm), [{
    return N->getZExtValue() < 32;
}], extractShift>;

def isMax64bitShift : PatLeaf<(imm), [{
    return N->getZExtValue() < 64;
}], extractShift>;

// Extract masks like (val & 0b0001111000) >> 3
// Most common use looks like: (x & 0xFF00) >> 8
multiclass ExtractOp<string asm, ValueType Ty, RegisterClass RC, PatLeaf ShImm,
                     SDNode op> {
    def _rii : HSAILInst<(outs RC:$dest), (ins RC:$src0, i32imm:$src1,
                                          i32imm:$src2),
        !strconcat(asm, "\t $dest, $src0, $src1, $src2"),
        [(set (Ty RC:$dest), (and
            (op (Ty RC:$src0), (i32 ShImm:$src1)), (Ty isMask:$src2)))]>;

    def _rri : HSAILInst<(outs RC:$dest), (ins RC:$src0, GPR32:$src1,
                                          i32imm:$src2),
        !strconcat(asm, "\t $dest, $src0, $src1, $src2"),
        [(set (Ty RC:$dest), (and
            (op (Ty RC:$src0), (i32 GPR32:$src1)), (Ty isMask:$src2)))]>;
}

// Pattren for extract where we can use unsigned insn for signed argumet.
def SignNeutralExtract : PatFrag<(ops node:$reg, node:$shift, node:$mask),
                                 (and (sra node:$reg, node:$shift), node:$mask),
                                 [{
    ConstantSDNode *CNShift, *CNMask;
    if ((CNShift = dyn_cast<ConstantSDNode>(N->getOperand(0)->getOperand(1))) &&
        (CNMask  = dyn_cast<ConstantSDNode>(N->getOperand(1)))) {
        uint64_t mask = CNMask->getZExtValue();
        uint64_t shift = CNShift->getZExtValue();
        unsigned int size = N->getValueSizeInBits(0);
        if ((CountPopulation_64(mask) + shift) > size) return false;
        if (size == 32) {
            return ((0xffffffffu >> shift) & mask) == ((-1 >> shift) & mask);
        } else if (size == 64) {
            return ((((uint64_t)-1) >> shift) & mask) ==
                   ((((int64_t)-1) >> shift) & mask);
        }
    }
    return false;
}]>;

multiclass SignNeutralExtractOp<string asm, ValueType Ty, RegisterClass RC,
                                PatLeaf ShImm> {
    def _rii : HSAILInst<(outs RC:$dest), (ins RC:$src0, i32imm:$src1,
                                          i32imm:$src2),
        !strconcat(asm, "\t $dest, $src0, $src1, $src2"),
        [(set (Ty RC:$dest), (SignNeutralExtract (Ty RC:$src0),
                                (i32 ShImm:$src1), (Ty isMask:$src2)))]>;
}

// No signed extract operations are defined since HSAIL specifies extract as
// left + right shifts rather than right shift + and
let Predicates = [EnableOpt] in {
  def : Pat<
    (and (srl i32:$src0, (i32 isMax32bitShift:$src1)), (i32 isMask:$src2)),
    (media_bfe_rii_u32 $src0, isMax32bitShift:$src1, isMask:$src2)
  >;

  def : Pat<
    (and (srl GPR32:$src0, GPR32:$src1), (i32 isMask:$src2)),
    (media_bfe_rri_u32 GPR32:$src0, GPR32:$src1, isMask:$src2)
  >;

  defm extract_u64 : ExtractOp<"bitextract_u64", i64, GPR64, isMax64bitShift, srl>;

  def : Pat<
    (SignNeutralExtract i32:$src0, (i32 isMax32bitShift:$src1), (i32 isMask:$src2)),
    (media_bfe_rii_u32 GPR32:$src0, isMax32bitShift:$src1, isMask:$src2)
  >;

  defm extract_b64 : SignNeutralExtractOp<"bitextract_u64", i64, GPR64, isMax64bitShift>;
}

// BFI
def bfiImmIRR : PatFrag<
  (ops node:$src0, node:$src1, node:$src2, node:$src4),
  (or (and node:$src1, node:$src0), (and node:$src2, node:$src4)), [{
    // check if src1 == ~src4
    ConstantSDNode *CN1, *CN2;
    if ((CN1 = dyn_cast<ConstantSDNode>(N->getOperand(0)->getOperand(1))) &&
        (CN2 = dyn_cast<ConstantSDNode>(N->getOperand(1)->getOperand(1)))) {
        return (CN1->getSExtValue() == ~(CN2->getSExtValue()));
    }
    return false;
}]>;

def bfiImmIIR3 : PatFrag<
  (ops node:$src0, node:$src1, node:$src2),
  (xor (xor node:$src2, (and node:$src2, node:$src0)), node:$src1), [{
    // Check if src1 & src0 == src1.
    ConstantSDNode *CN1, *CN2;
    if ((CN1 = dyn_cast<ConstantSDNode>(N->getOperand(0)->getOperand(1)->
                                                          getOperand(1))) &&
        (CN2 = dyn_cast<ConstantSDNode>(N->getOperand(1)))) {
        uint64_t c2 = CN2->getZExtValue();
        return (CN1->getZExtValue() & c2) == c2;
    }
    return false;
}]>;

// FIXME: These patterns are pretty fragile and break by commuting
// operands of sources. Many fo them fail on canonicalized IR for the
// pattern they match.
multiclass BitSelect<ValueType Ty, int bt> {
  def _rrr : Pat<
    (or (and Ty:$src0, Ty:$src1),
        (and Ty:$src2, (not Ty:$src0))),
    (bitselect_inst $src0, $src1, $src2, bt)
  >;

  def _irr : Pat<
    (bfiImmIRR (Ty imm:$src0), Ty:$src1, Ty:$src2, (Ty imm)),
    (bitselect_inst imm:$src0, $src1, $src2, bt)
  >;

  def _rir : Pat<
    (or (and Ty:$src0, (Ty imm:$src1)), (and Ty:$src2, (not Ty:$src0))),
    (bitselect_inst $src0, imm:$src1, $src2, bt)
  >;

  def _rii : Pat<
    (or (and Ty:$src0, (Ty imm:$src1)),
        (and (not Ty:$src0), (Ty imm:$src2))),
    (bitselect_inst $src0, imm:$src1, imm:$src2, bt)
  >;

  // Alternative rii pattern: (src0 & src1) | ((src0 & src2) ^ src2)
  def _rii1 : Pat<
    (or (and Ty:$src0, (Ty imm:$src1)),
        (xor (and Ty:$src0, (Ty imm:$src2)), (Ty imm:$src2))),
    (bitselect_inst $src0, imm:$src1, imm:$src2, bt)
  >;

  def _rri : Pat<
    (or (and Ty:$src0, Ty:$src1),
        (and (not Ty:$src0), (Ty imm:$src2))),
    (bitselect_inst $src0, $src1, imm:$src2, bt)
  >;

  // Alternative rri pattern: (src0 & src1) | ((src0 & src2) ^ src2)
  def _rri1 : Pat<
    (or (and Ty:$src0, Ty:$src1),
        (xor (and Ty:$src0, (Ty imm:$src2)), (Ty imm:$src2))),
    (bitselect_inst $src0, $src1, imm:$src2, bt)
  >;

  // Alternative pattern: (src2 ^ (src0 & (src1 ^ src2)))
  let AddedComplexity = 10 in {
    def _rrr2 : Pat<
      (xor Ty:$src2, (and Ty:$src0, (xor Ty:$src1, Ty:$src2))),
      (bitselect_inst $src0, $src1, $src2, bt)
    >;
  }

  let AddedComplexity = 11 in {
    // XXX - This is higher priority to fold the immediate.
    def _irr2 : Pat<
      (xor Ty:$src2, (and (xor Ty:$src1, Ty:$src2), imm:$src0)),
      (bitselect_inst imm:$src0, $src1, $src2, bt)
    >;

    def _iir2 : Pat<
      (xor Ty:$src2, (and (xor Ty:$src2, (Ty imm:$src1)), (Ty imm:$src0))),
      (bitselect_inst imm:$src0, imm:$src1, $src2, bt)
    >;

    def _rir2 : Pat<
      (xor Ty:$src2, (and Ty:$src0, (xor Ty:$src2, (Ty imm:$src1)))),
      (bitselect_inst $src0, imm:$src1, $src2, bt)
    >;

    def _rri2 : Pat<
      (xor (and Ty:$src0, (xor Ty:$src1, (Ty imm:$src2))), (Ty imm:$src2)),
      (bitselect_inst $src0, $src1, imm:$src2, bt)
    >;
  }

  // Alternative pattern: ((src0 & src2) ^ src2) ^ (src0 & src1)
  let AddedComplexity = 4 in {
    def _rrr3 : Pat<
      (xor (xor Ty:$src2, (and Ty:$src0, Ty:$src2)), (and Ty:$src0, Ty:$src1)),
      (bitselect_inst $src0, $src1, $src2, bt)
    >;
  }

  let AddedComplexity = 5 in {
    def _irr3 : Pat<
      (xor (xor Ty:$src2, (and Ty:$src2, (Ty imm:$src0))),
           (and Ty:$src1, (Ty imm:$src0))),
      (bitselect_inst imm:$src0, $src1, $src2, bt)
    >;

    def _iir3 : Pat<
      (bfiImmIIR3 (Ty imm:$src0), (Ty imm:$src1), Ty:$src2),
      (bitselect_inst imm:$src0, imm:$src1, $src2, bt)
    >;
  }

  def _rri3 : Pat<
    (xor (xor (and Ty:$src0, (Ty imm:$src2)), (Ty imm:$src2)),
         (and Ty:$src0, Ty:$src1)),
    (bitselect_inst $src0, $src1, imm:$src2, bt)
  >;

  def _rii3 : Pat<
    (xor (xor (and Ty:$src0, (Ty imm:$src2)), (Ty imm:$src2)),
         (and Ty:$src0, (Ty imm:$src1))),
    (bitselect_inst $src0, imm:$src1, imm:$src2, bt)
  >;
}

let Predicates = [EnableOpt] in {
defm : BitSelect<i32, BrigTypeX.B32>;
defm : BitSelect<i64, BrigTypeX.B64>;
}

// pack

let Predicates = [EnableOpt] in {
  def : Pat<
    (shl (i64 (anyext i32:$src)), (i32 32)),
    (pack_u32x2_u32_iri 0, $src, 1)
  >;
}

////////////////////////////////////////////////////////////////////////////////
// reciprocal

def fp32imm1 : PatLeaf<(f32 fpimm), [{
    return N->isExactlyValue(+1.0);
}]>;

def fp64imm1 : PatLeaf<(f64 fpimm), [{
    return N->isExactlyValue(+1.0);
}]>;

def fp32imm_minus1 : PatLeaf<(f32 fpimm), [{
    return N->isExactlyValue(-1.0);
}]>;

def fp64imm_minus1 : PatLeaf<(f64 fpimm), [{
    return N->isExactlyValue(-1.0);
}]>;

let Predicates = [UnsafeFPMath] in {
  // Pure 1.0 / x
  let AddedComplexity = 5 in {
    def : Pat<
      (fdiv fp32imm1, f32:$src),
      (nrcp_inst $src, BrigTypeX.F32)
    >;

    def : Pat<
      (fdiv fp64imm1, f64:$src),
      (nrcp_inst $src, BrigTypeX.F64)
    >;
  }

  // -1.0 / x
  let AddedComplexity = 4 in {
     def : Pat<
       (fdiv fp32imm_minus1, f32:$src),
       (neg (f32 (nrcp_inst $src, BrigTypeX.F32)), BrigTypeX.F32)
     >;

     def : Pat<
       (fdiv fp64imm_minus1, f64:$src),
       (neg (f64 (nrcp_inst $src, BrigTypeX.F64)), BrigTypeX.F64)
     >;
  }

  let AddedComplexity = 5 in {
    def : Pat<
      (fdiv fp32imm_minus1, (fneg f32:$src)),
      (nrcp_inst $src, BrigTypeX.F32)
    >;

    def : Pat<
      (fdiv fp64imm_minus1, (fneg f64:$src)),
      (nrcp_inst $src, BrigTypeX.F64)
    >;
  }
}

////////////////////////////////////////////////////////////////////////////////
// rsqrt

let Predicates = [UnsafeFPMath] in {
  // Pure 1.0 / sqrt(x)
  let AddedComplexity = 15 in {
    def : Pat<
      (fdiv fp32imm1, (int_HSAIL_nsqrt_f32 f32:$src)),
      (nrsqrt_inst $src, BrigTypeX.F32)
    >;

    def : Pat<
      (fdiv fp64imm1, (int_HSAIL_nsqrt_f64 f64:$src)),
      (nrsqrt_inst $src, BrigTypeX.F64)
    >;
  }

  let AddedComplexity = 10 in {
    def : Pat<
      (fdiv f32:$src0, (int_HSAIL_nsqrt_f32 f32:$src1)),
      (f32 (mul_inst 1, 0, $src0, (f32 (nrsqrt_inst $src1, BrigTypeX.F32)), BrigTypeX.F32))
    >;

    def : Pat<
      (f32 (fdiv fpimm:$src0, (int_HSAIL_nsqrt_f32 f32:$src1))),
      (f32 (mul_inst 1, 0, fpimm:$src0, (f32 (nrsqrt_inst $src1, BrigTypeX.F32)), BrigTypeX.F32))
    >;

    def : Pat<
      (f64 (fdiv GPR64:$src0, (int_HSAIL_nsqrt_f64 f64:$src1))),
      (f64 (mul_inst 0, 0, $src0, (f64 (nrsqrt_inst $src1, BrigTypeX.F64)), BrigTypeX.F64))
    >;

    def : Pat<
      (f64 (fdiv fpimm:$src0, (int_HSAIL_nsqrt_f64 f64:$src1))),
      (f64 (mul_inst 0, 0, fpimm:$src0, (f64 (nrsqrt_inst (f64 GPR64:$src1), BrigTypeX.F64)), BrigTypeX.F64))
    >;
  }
}

////////////////////////////////////////////////////////////////////////////////
// Min/Max
multiclass minmax<Instruction inst, ValueType Ty, SDNode ImmTy,
                  CondCode cc12, CondCode cc21,
                  int bt,
                  int ftz = 0,
                  int round = BrigRound.FLOAT_NEAR_EVEN> {
  def _rr12 : Pat<
    (select (i1 (setcc Ty:$src0, Ty:$src1, cc12)), Ty:$src0, Ty:$src1),
    (inst ftz, round, $src0, $src1, bt)
  >;

  def _ri12 : Pat<
    (select (i1 (setcc Ty:$src0, ImmTy:$src1, cc12)), Ty:$src0, ImmTy:$src1),
    (inst ftz, round, $src0, ImmTy:$src1, bt)
  >;

  def _ir12 : Pat<
    (select (i1 (setcc ImmTy:$src0, Ty:$src1, cc12)), ImmTy:$src0, Ty:$src1),
    (inst ftz, round, ImmTy:$src0, $src1, bt)
  >;

  def _rr21 : Pat<
    (select (i1 (setcc Ty:$src0, Ty:$src1, cc21)), Ty:$src1, Ty:$src0),
    (inst ftz, round, $src0, $src1, bt)
  >;

  def _ri21 : Pat<
    (select (i1 (setcc Ty:$src0, ImmTy:$src1, cc21)), ImmTy:$src1, Ty:$src0),
    (inst ftz, round, $src0, ImmTy:$src1, bt)
  >;

  def _ir21 : Pat<
    (select (i1 (setcc ImmTy:$src0, Ty:$src1, cc21)), Ty:$src1, ImmTy:$src0),
    (inst ftz, round, ImmTy:$src0, $src1, bt)
  >;
}

let Predicates = [EnableOpt] in {
defm min_s32  : minmax<min_inst, i32, imm, SETLT,  SETGT, BrigTypeX.S32>;
defm min_u32  : minmax<min_inst, i32, imm, SETULT, SETUGT, BrigTypeX.U32>;
defm max_s32  : minmax<max_inst, i32, imm, SETGT,  SETLT, BrigTypeX.S32>;
defm max_u32  : minmax<max_inst, i32, imm, SETUGT, SETULT, BrigTypeX.U32>;
defm min_s64  : minmax<min_inst, i64, imm, SETLT,  SETGT, BrigTypeX.S64>;
defm min_u64  : minmax<min_inst, i64, imm, SETULT, SETUGT, BrigTypeX.U64>;
defm max_s64  : minmax<max_inst, i64, imm, SETGT,  SETLT, BrigTypeX.S64>;
defm max_u64  : minmax<max_inst, i64, imm, SETUGT, SETULT, BrigTypeX.U64>;
}

// Abs
let Predicates = [EnableOpt] in {
  def : Pat<
    (xor (add (sra i32:$src, (i32 31)), i32:$src),
         (sra i32:$src, (i32 31))),
    (abs_inst 0, 0, $src, BrigTypeX.S32)
  >;

  def : Pat<
    (xor (add (sra i64:$src, (i32 63)), i64:$src),
         (sra i64:$src, (i32 63))),
    (abs_inst 0, 0, $src, BrigTypeX.S64)
  >;
}

////////////////////////////////////////////////////////////////////////////////
// fadd y (fmul x, 1)
multiclass FusedAddMul1<HSAILInst op, ValueType Ty, int bt, RegisterClass RC,
                        PatLeaf one, int round, int ftz = 0> {
  def _rri : Pat<
    (fadd Ty:$src0, (fmul Ty:$src1, one)),
    (op ftz, round, $src0, $src1, bt)
  >;

  def _iri : Pat<
    (fadd (fmul Ty:$src0, one), (Ty fpimm:$src1)),
    (op ftz, round, $src0, (Ty fpimm:$src1), bt)
  >;
}

let Predicates = [EnableOpt] in {
  defm addmul1_f32 : FusedAddMul1<add_inst, f32, BrigTypeX.F32, GPR32, fp32imm1,
                                  BrigRound.FLOAT_NEAR_EVEN, 1>;
  defm addmul1_f64 : FusedAddMul1<add_inst, f64, BrigTypeX.F64, GPR64, fp64imm1,
                                  BrigRound.FLOAT_NEAR_EVEN, 0>;
}

let Predicates = [EnableOpt] in {
  def : Pat<
    (or (shl i32:$src0, i32:$src1),
        (srl i32:$src0, (sub imm32, (and i32:$src1, imm31)))),
    (bitalign_inst $src0, $src0, (i32 (neg $src1, BrigTypeX.S32)), BrigTypeX.B32)
  >;
}
