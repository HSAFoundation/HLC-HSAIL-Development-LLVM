//===------------------------------------------------------*- tablegen -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Fused instruction patterns
//
// This files contains optimizations, rather than definitions
// essential for the code generation.
//
//===----------------------------------------------------------------------===//

////////////////////////////////////////////////////////////////////////////////
// llc command line options predicates
def EnableFPMAD        : Predicate<"CurDAG->getTarget().Options.LessPreciseFPMAD()">;
def UnsafeFPMath       : Predicate<"CurDAG->getTarget().Options.UnsafeFPMath">;
def NoInfsFPMath       : Predicate<"CurDAG->getTarget().Options.NoInfsFPMath">;
def NoNaNsFPMath       : Predicate<"CurDAG->getTarget().Options.NoNaNsFPMath">;

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
    return CurDAG->getTargetConstant(1u << (N->getZExtValue()), SDLoc(N), MVT::i32);
}]>;

def getShiftMult64 : SDNodeXForm<imm, [{
    return CurDAG->getTargetConstant(((uint64_t)1u) << (N->getZExtValue()),
       SDLoc(N), MVT::i64);
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
  defm : TernaryFusedPairOp<NFMA_F32, f32, fpimm, GPR32, fadd, fmul, BrigType.F32>;
  defm : TernaryFusedPairOp<NFMA_F64, f64, fpimm, GPR64, fadd, fmul, BrigType.F64>;
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
    return CurDAG->getTargetConstant(countPopulation(N->getZExtValue()),
                                     SDLoc(N), MVT::i32);
}]>;

def isMask : PatLeaf<(imm), [{
    return isMask_64(N->getZExtValue());
}]>;

// Extract masks like (val & 0b0001111000) >> 3
// Most common use looks like: (x & 0xFF00) >> 8
class BitExtractOp<HSAILInst bitextractInst, ValueType Ty, int bt> : Pat<
  (and (srl Ty:$src0, (i32 (GPROrImm i32:$src1))), (Ty isMask:$src2)),
  (bitextractInst $src0, $src1, (i32 (popCnt $src2)), bt)
>;

// No signed extract operations are defined since HSAIL specifies extract as
// left + right shifts rather than right shift + and
let Predicates = [EnableOpt], AddedComplexity = 10 in {
  def : BitExtractOp<BITEXTRACT_U32, i32, BrigType.U32>;
  def : BitExtractOp<BITEXTRACT_U64, i64, BrigType.U64>;
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
multiclass BitSelect<HSAILInst bitselectInst, ValueType Ty, int bt> {
  def _rrr : Pat<
    (or (and Ty:$src0, Ty:$src1),
        (and Ty:$src2, (not Ty:$src0))),
    (bitselectInst $src0, $src1, $src2, bt)
  >;

  def _irr : Pat<
    (bfiImmIRR (Ty imm:$src0), Ty:$src1, Ty:$src2, (Ty imm)), (bitselectInst imm:$src0, $src1, $src2, bt)
  >;

  def _rir : Pat<
    (or (and Ty:$src0, (Ty imm:$src1)), (and Ty:$src2, (not Ty:$src0))),
    (bitselectInst $src0, imm:$src1, $src2, bt)
  >;

  def _rii : Pat<
    (or (and Ty:$src0, (Ty imm:$src1)),
        (and (not Ty:$src0), (Ty imm:$src2))),
    (bitselectInst $src0, imm:$src1, imm:$src2, bt)
  >;

  // Alternative rii pattern: (src0 & src1) | ((src0 & src2) ^ src2)
  def _rii1 : Pat<
    (or (and Ty:$src0, (Ty imm:$src1)),
        (xor (and Ty:$src0, (Ty imm:$src2)), (Ty imm:$src2))),
    (bitselectInst $src0, imm:$src1, imm:$src2, bt)
  >;

  def _rri : Pat<
    (or (and Ty:$src0, Ty:$src1),
        (and (not Ty:$src0), (Ty imm:$src2))),
    (bitselectInst $src0, $src1, imm:$src2, bt)
  >;

  // Alternative rri pattern: (src0 & src1) | ((src0 & src2) ^ src2)
  def _rri1 : Pat<
    (or (and Ty:$src0, Ty:$src1),
        (xor (and Ty:$src0, (Ty imm:$src2)), (Ty imm:$src2))),
    (bitselectInst $src0, $src1, imm:$src2, bt)
  >;

  // Alternative pattern: (src2 ^ (src0 & (src1 ^ src2)))
  let AddedComplexity = 10 in {
    def _rrr2 : Pat<
      (xor Ty:$src2, (and Ty:$src0, (xor Ty:$src1, Ty:$src2))),
      (bitselectInst $src0, $src1, $src2, bt)
    >;
  }

  let AddedComplexity = 11 in {
    // XXX - This is higher priority to fold the immediate.
    def _irr2 : Pat<
      (xor Ty:$src2, (and (xor Ty:$src1, Ty:$src2), imm:$src0)),
      (bitselectInst imm:$src0, $src1, $src2, bt)
    >;

    def _iir2 : Pat<
      (xor Ty:$src2, (and (xor Ty:$src2, (Ty imm:$src1)), (Ty imm:$src0))),
      (bitselectInst imm:$src0, imm:$src1, $src2, bt)
    >;

    def _rir2 : Pat<
      (xor Ty:$src2, (and Ty:$src0, (xor Ty:$src2, (Ty imm:$src1)))),
      (bitselectInst $src0, imm:$src1, $src2, bt)
    >;

    def _rri2 : Pat<
      (xor (and Ty:$src0, (xor Ty:$src1, (Ty imm:$src2))), (Ty imm:$src2)),
      (bitselectInst $src0, $src1, imm:$src2, bt)
    >;
  }

  // Alternative pattern: ((src0 & src2) ^ src2) ^ (src0 & src1)
  let AddedComplexity = 4 in {
    def _rrr3 : Pat<
      (xor (xor Ty:$src2, (and Ty:$src0, Ty:$src2)), (and Ty:$src0, Ty:$src1)),
      (bitselectInst $src0, $src1, $src2, bt)
    >;
  }

  let AddedComplexity = 5 in {
    def _irr3 : Pat<
      (xor (xor Ty:$src2, (and Ty:$src2, (Ty imm:$src0))),
           (and Ty:$src1, (Ty imm:$src0))),
      (bitselectInst imm:$src0, $src1, $src2, bt)
    >;

    def _iir3 : Pat<
      (bfiImmIIR3 (Ty imm:$src0), (Ty imm:$src1), Ty:$src2),
      (bitselectInst imm:$src0, imm:$src1, $src2, bt)
    >;
  }

  def _rri3 : Pat<
    (xor (xor (and Ty:$src0, (Ty imm:$src2)), (Ty imm:$src2)),
         (and Ty:$src0, Ty:$src1)),
    (bitselectInst $src0, $src1, imm:$src2, bt)
  >;

  def _rii3 : Pat<
    (xor (xor (and Ty:$src0, (Ty imm:$src2)), (Ty imm:$src2)),
         (and Ty:$src0, (Ty imm:$src1))),
    (bitselectInst $src0, imm:$src1, imm:$src2, bt)
  >;
}

let Predicates = [EnableOpt] in {
defm : BitSelect<BITSELECT_B32, i32, BrigType.B32>;
defm : BitSelect<BITSELECT_B64, i64, BrigType.B64>;
}

// pack

let Predicates = [EnableOpt], AddedComplexity = 5 in {
  def : Pat<
    (shl (i64 (anyext i32:$src)), (i32 32)),
    (PACK_U32X2_U32 (i64 0), $src, (i32 1), BrigType.U32X2, BrigType.U32)
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
      (NRCP_F32 $src, BrigType.F32)
    >;

    def : Pat<
      (fdiv fp64imm1, f64:$src),
      (NRCP_F64 $src, BrigType.F64)
    >;
  }

  // -1.0 / x
  let AddedComplexity = 4 in {
     def : Pat<
       (fdiv fp32imm_minus1, f32:$src),
       (NEG_F32 (f32 (NRCP_F32 $src, BrigType.F32)), BrigType.F32)
     >;

     def : Pat<
       (fdiv fp64imm_minus1, f64:$src),
       (NEG_F64 (f64 (NRCP_F64 $src, BrigType.F64)), BrigType.F64)
     >;
  }

  let AddedComplexity = 5 in {
    def : Pat<
      (fdiv fp32imm_minus1, (fneg f32:$src)),
      (NRCP_F32 $src, BrigType.F32)
    >;

    def : Pat<
      (fdiv fp64imm_minus1, (fneg f64:$src)),
      (NRCP_F64 $src, BrigType.F64)
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
      (NRSQRT_F32 $src, BrigType.F32)
    >;

    def : Pat<
      (fdiv fp64imm1, (int_HSAIL_nsqrt_f64 f64:$src)),
      (NRSQRT_F64 $src, BrigType.F64)
    >;
  }

  let AddedComplexity = 10 in {
    def : Pat<
      (fdiv f32:$src0, (int_HSAIL_nsqrt_f32 f32:$src1)),
      (f32 (MUL_F32 1, 0, $src0, (f32 (NRSQRT_F32 $src1, BrigType.F32)), BrigType.F32))
    >;

    def : Pat<
      (f32 (fdiv fpimm:$src0, (int_HSAIL_nsqrt_f32 f32:$src1))),
      (f32 (MUL_F32 1, 0, fpimm:$src0, (f32 (NRSQRT_F32 $src1, BrigType.F32)), BrigType.F32))
    >;

    def : Pat<
      (f64 (fdiv GPR64:$src0, (int_HSAIL_nsqrt_f64 f64:$src1))),
      (f64 (MUL_F64 0, 0, $src0, (f64 (NRSQRT_F64 $src1, BrigType.F64)), BrigType.F64))
    >;

    def : Pat<
      (f64 (fdiv fpimm:$src0, (int_HSAIL_nsqrt_f64 f64:$src1))),
      (f64 (MUL_F64 0, 0, fpimm:$src0, (f64 (NRSQRT_F64 (f64 GPR64:$src1), BrigType.F64)), BrigType.F64))
    >;
  }
}

////////////////////////////////////////////////////////////////////////////////
// Min/Max

// A 'setcc' node with a single use.
def setcc_su : PatFrag<(ops node:$lhs, node:$rhs, node:$cc),
  (setcc node:$lhs, node:$rhs, node:$cc), [{
  return N->hasOneUse();
}]>;

multiclass minmax<Instruction inst, ValueType Ty, SDNode ImmTy,
                  CondCode cc12, CondCode cc21,
                  int bt,
                  int ftz = 0,
                  int round = BrigRound.NONE> {
  def : Pat<
    (select (i1 (setcc_su Ty:$src0, Ty:$src1, cc12)), Ty:$src0, Ty:$src1),
    (inst ftz, round, $src0, $src1, bt)
  >;

  def : Pat<
    (select (i1 (setcc_su Ty:$src0, ImmTy:$src1, cc12)), Ty:$src0, ImmTy:$src1),
    (inst ftz, round, $src0, ImmTy:$src1, bt)
  >;

  def : Pat<
    (select (i1 (setcc_su ImmTy:$src0, Ty:$src1, cc12)), ImmTy:$src0, Ty:$src1),
    (inst ftz, round, ImmTy:$src0, $src1, bt)
  >;

  def : Pat<
    (select (i1 (setcc_su Ty:$src0, Ty:$src1, cc21)), Ty:$src1, Ty:$src0),
    (inst ftz, round, $src0, $src1, bt)
  >;

  def : Pat<
    (select (i1 (setcc_su Ty:$src0, ImmTy:$src1, cc21)), ImmTy:$src1, Ty:$src0),
    (inst ftz, round, $src0, ImmTy:$src1, bt)
  >;

  def : Pat<
    (select (i1 (setcc_su ImmTy:$src0, Ty:$src1, cc21)), Ty:$src1, ImmTy:$src0),
    (inst ftz, round, ImmTy:$src0, $src1, bt)
  >;
}

// TODO: This should be moved to a DAG combine. This currently gets
// confused by canonicalizations of a compare with a constant. le/ge
// comparisons with a constant are canonicalized to lt/gt with the
// constant incremented, which breaks the simple pattern.
let Predicates = [EnableOpt] in {
  defm : minmax<MIN_S32, i32, imm, SETLT,  SETGT, BrigType.S32>;
  defm : minmax<MIN_S32, i32, imm, SETLE,  SETGE, BrigType.S32>;
  defm : minmax<MIN_U32, i32, imm, SETULT, SETUGT, BrigType.U32>;
  defm : minmax<MIN_U32, i32, imm, SETULE, SETUGE, BrigType.U32>;
  defm : minmax<MAX_S32, i32, imm, SETGT,  SETLT, BrigType.S32>;
  defm : minmax<MAX_S32, i32, imm, SETGE,  SETLE, BrigType.S32>;
  defm : minmax<MAX_U32, i32, imm, SETUGT, SETULT, BrigType.U32>;
  defm : minmax<MAX_U32, i32, imm, SETUGE, SETULE, BrigType.U32>;
  defm : minmax<MIN_S64, i64, imm, SETLT,  SETGT, BrigType.S64>;
  defm : minmax<MIN_S64, i64, imm, SETLE,  SETGE, BrigType.S64>;
  defm : minmax<MIN_U64, i64, imm, SETULT, SETUGT, BrigType.U64>;
  defm : minmax<MIN_U64, i64, imm, SETULE, SETUGE, BrigType.U64>;
  defm : minmax<MAX_S64, i64, imm, SETGT,  SETLT, BrigType.S64>;
  defm : minmax<MAX_S64, i64, imm, SETGE,  SETLE, BrigType.S64>;
  defm : minmax<MAX_U64, i64, imm, SETUGT, SETULT, BrigType.U64>;
  defm : minmax<MAX_U64, i64, imm, SETUGE, SETULE, BrigType.U64>;
}

// Abs
let Predicates = [EnableOpt] in {
  def : Pat<
    (xor (add (sra i32:$src, (i32 31)), i32:$src),
         (sra i32:$src, (i32 31))),
    (ABS_S32 0, 0, $src, BrigType.S32)
  >;

  def : Pat<
    (xor (add (sra i64:$src, (i32 63)), i64:$src),
         (sra i64:$src, (i32 63))),
    (ABS_S64 0, 0, $src, BrigType.S64)
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

// FIXME: Change to default rounding mode
let Predicates = [EnableOpt] in {
  defm addmul1_f32 : FusedAddMul1<ADD_F32, f32, BrigType.F32, GPR32, fp32imm1,
                                  BrigRound.FLOAT_NEAR_EVEN, 1>;
  defm addmul1_f64 : FusedAddMul1<ADD_F64, f64, BrigType.F64, GPR64, fp64imm1,
                                  BrigRound.FLOAT_NEAR_EVEN, 0>;
}

let Predicates = [EnableOpt] in {
  def : Pat<
    (or (shl i32:$src0, i32:$src1),
        (srl i32:$src0, (sub imm32, (and i32:$src1, imm31)))),
    (BITALIGN_B32 $src0, $src0, (i32 (NEG_S32 $src1, BrigType.S32)), BrigType.B32)
  >;
}
