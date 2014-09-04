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
multiclass TernaryFusedPairOp<string asm, ValueType Ty, Operand OpTy,
                              SDNode ImmTy, RegisterClass RC, SDNode op1, 
                              SDNode op2> {

    def _rrr : HSAILInst<(outs RC:$dst), (ins RC:$src1, RC:$src2, RC:$src3),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
        [(set (Ty RC:$dst), 
            (op1 (op2 (Ty RC:$src1), (Ty RC:$src2)), 
                (Ty RC:$src3)))]>;

    def _rri : HSAILInst<(outs RC:$dst), (ins RC:$src1, RC:$src2, OpTy:$src3),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
        [(set (Ty RC:$dst), 
            (op1 (op2 (Ty RC:$src1), (Ty RC:$src2)), 
                (Ty ImmTy:$src3)))]>;

    def _rir : HSAILInst<(outs RC:$dst), (ins RC:$src1, OpTy:$src2, RC:$src3),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
        [(set (Ty RC:$dst), 
            (op1 (op2 (Ty RC:$src1), (Ty ImmTy:$src2)), 
                (Ty RC:$src3)))]>;
  
    def _rii : HSAILInst<(outs RC:$dst), (ins RC:$src1, OpTy:$src2, OpTy:$src3),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
        [(set (Ty RC:$dst), 
            (op1 (op2 (Ty RC:$src1), (Ty ImmTy:$src2)), 
                (Ty ImmTy:$src3)))]>;
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

// shift + add -> mad
multiclass TernaryFusedShlAdd<string asm, ValueType Ty, Operand OpTy, 
                              PatLeaf ImmTy, RegisterClass RC> {

    def _rir : HSAILInst<(outs RC:$dst), (ins RC:$src1, OpTy:$src2, RC:$src3),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
        [(set (Ty RC:$dst), (add 
            (shl (Ty RC:$src1), (i32 ImmTy:$src2)), 
            (Ty RC:$src3)))]>;
  
    def _rii : HSAILInst<(outs RC:$dst), (ins RC:$src1, OpTy:$src2, OpTy:$src3),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
        [(set (Ty RC:$dst), (add
            (shl (Ty RC:$src1), (i32 ImmTy:$src2)), 
            (Ty imm:$src3)))]>;
}

// Pre-optimized (const1 + (x << const2)) -> const1 | (x << const2).
// This requires mutual check of const1 and const2 to ensure last bit# set in
// const1 < const2 (i.e. or can be changed to add).
def orShlAsMad : PatFrag<(ops node:$reg, node:$shift, node:$mask), 
                         (or (shl node:$reg, node:$shift), node:$mask), [{
    ConstantSDNode *CNShift, *CNMask;
    if ((CNShift = dyn_cast<ConstantSDNode>(N->getOperand(0)->getOperand(1))) &&
        (CNMask  = dyn_cast<ConstantSDNode>(N->getOperand(1)))) {
        return (CNMask->getZExtValue() >> CNShift->getZExtValue()) == 0;
    }
    return false;
}]>;

defm mad_u32 : TernaryFusedPairOp<"mad_u32", i32, i32imm, imm, GPR32, add, mul>;
defm mad_s32 : TernaryFusedPairOp<"mad_s32", i32, i32imm, imm, GPR32, add, mul>;
defm mad_u64 : TernaryFusedPairOp<"mad_u64", i64, i64imm, imm, GPR64, add, mul>;
defm mad_s64 : TernaryFusedPairOp<"mad_s64", i64, i64imm, imm, GPR64, add, mul>;

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
// defm m2ad_u64 : TernaryFusedShlAdd<"mad_u64", i64, i64imm, shl64imm, GPR64>;

// We do not define 64 bit const1 | (x << const2) folding, as we have 64 bit
// or and shift, but no 64 bit mad.
// As 32 bit integer multiplication is curently expensive, optimization is
// commented out.
// def mor_u32 : HSAILInst<(outs GPR32:$dst), 
//                         (ins GPR32:$src1, i32imm:$src2, i32imm:$src3),
//                         "mad_u32\t$dst, $src1, $src2, $src3",
//                         [(set (i32 GPR32:$dst),
//                               (orShlAsMad (i32 GPR32:$src1), 
//                               (i32 shl32imm:$src2), (i32 imm:$src3)))]>;

let Predicates = [EnableFPMAD] in {
    defm nfma_f32 : TernaryFusedPairOp<"nfma_f32", f32, f32imm, fpimm, GPR32, 
                                      fadd, fmul>;
    defm nfma_f64 : TernaryFusedPairOp<"nfma_f64", f64, f64imm, fpimm, GPR64, 
                                      fadd, fmul>;
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

// Shifts do not need "and {31|63}, shift-bits".
multiclass ShrOp<string asm, SDNode op, RegisterClass RC, ValueType Ty,
                 Operand OpTy, PatLeaf ShImm> {

    def _rr : HSAILInst<(outs RC:$dst), (ins RC:$src1, GPR32:$src2),
        !strconcat(asm, "\t $dst, $src1, $src2"),
        [(set (Ty RC:$dst), 
            (op (Ty RC:$src1),
                     (and (i32 GPR32:$src2), (i32 ShImm))))]>;

    def _ir : HSAILInst<(outs RC:$dst), (ins OpTy:$src1, GPR32:$src2),
        !strconcat(asm, "\t $dst, $src1, $src2"),
        [(set (Ty RC:$dst), 
            (op (Ty imm:$src1),
                     (and (i32 GPR32:$src2), (i32 ShImm))))]>;
}

defm shr_u32 : ShrOp<"shr_u32", srl, GPR32, i32, i32imm, imm31>;
defm shr_s32 : ShrOp<"shr_s32", sra, GPR32, i32, i32imm, imm31>;
defm shl_u32 : ShrOp<"shl_u32", shl, GPR32, i32, i32imm, imm31>;
defm shr_u64 : ShrOp<"shr_u64", srl, GPR64, i64, i64imm, imm63>;
defm shr_s64 : ShrOp<"shr_s64", sra, GPR64, i64, i64imm, imm63>;
defm shl_u64 : ShrOp<"shl_u64", shl, GPR64, i64, i64imm, imm63>;

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
    def _rii : HSAILInst<(outs RC:$dst), (ins RC:$src1, i32imm:$src2,
                                          i32imm:$src3),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
        [(set (Ty RC:$dst), (and 
            (op (Ty RC:$src1), (i32 ShImm:$src2)), (Ty isMask:$src3)))]>;

    def _rri : HSAILInst<(outs RC:$dst), (ins RC:$src1, GPR32:$src2,
                                          i32imm:$src3),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
        [(set (Ty RC:$dst), (and 
            (op (Ty RC:$src1), (i32 GPR32:$src2)), (Ty isMask:$src3)))]>;
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
    def _rii : HSAILInst<(outs RC:$dst), (ins RC:$src1, i32imm:$src2,
                                          i32imm:$src3),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
        [(set (Ty RC:$dst), (SignNeutralExtract (Ty RC:$src1),
                                (i32 ShImm:$src2), (Ty isMask:$src3)))]>;
}

// No signed extract operations are defined since HSAIL specifies extract as
// left + right shifts rather than right shift + and
defm extract_u32 : ExtractOp<"bitextract_u32", i32, GPR32, isMax32bitShift, srl>;
defm extract_u64 : ExtractOp<"bitextract_u64", i64, GPR64, isMax64bitShift, srl>;
defm extract_b32 : SignNeutralExtractOp<"bitextract_u32", i32, GPR32, isMax32bitShift>;
defm extract_b64 : SignNeutralExtractOp<"bitextract_u64", i64, GPR64, isMax64bitShift>;

// BFI

def bfiImmIRR : PatFrag<(ops node:$src1, node:$src2, node:$src3, node:$src4), 
                        (or (and node:$src2, node:$src1),
                            (and node:$src3, node:$src4)), [{
    // check if src1 == ~src4
    ConstantSDNode *CN1, *CN2;
    if ((CN1 = dyn_cast<ConstantSDNode>(N->getOperand(0)->getOperand(1))) &&
        (CN2 = dyn_cast<ConstantSDNode>(N->getOperand(1)->getOperand(1)))) {
        return (CN1->getSExtValue() == ~(CN2->getSExtValue()));
    }
    return false;
}]>;

def bfiImmIIR3 : PatFrag<(ops node:$src1, node:$src2, node:$src3),
                          (xor
                               (xor node:$src3, (and node:$src3, node:$src1)),
                               node:$src2), [{
    // check if src2 & src1 == src2
    ConstantSDNode *CN1, *CN2;
    if ((CN1 = dyn_cast<ConstantSDNode>(N->getOperand(0)->getOperand(1)->
                                                          getOperand(1))) &&
        (CN2 = dyn_cast<ConstantSDNode>(N->getOperand(1)))) {
        uint64_t c2 = CN2->getZExtValue();
        return (CN1->getZExtValue() & c2) == c2;
    }
    return false;
}]>;

multiclass BitSelect<string asm, ValueType Ty, RegisterClass RC, Operand OpTy,
                     SDNode ImmTy> {

    def _rrr : HSAILInst<(outs RC:$dst), (ins RC:$src1, RC:$src2, RC:$src3),
                         !strconcat(asm,"\t $dst, $src1, $src2, $src3"),
                         [(set (Ty RC:$dst),
                               (or (and (Ty RC:$src1),
                                        (Ty RC:$src2)),
                                   (and (Ty RC:$src3),
                                        (not (Ty RC:$src1)))))]>;

    def _irr : HSAILInst<(outs RC:$dst), (ins OpTy:$src1, RC:$src2, RC:$src3),
                         !strconcat(asm,"\t $dst, $src1, $src2, $src3"),
                         [(set (Ty RC:$dst),
                               (bfiImmIRR (Ty ImmTy:$src1), (Ty RC:$src2),
                                          (Ty RC:$src3), (Ty ImmTy)))]>;

    def _rir : HSAILInst<(outs RC:$dst), (ins RC:$src1, OpTy:$src2, RC:$src3),
                         !strconcat(asm,"\t $dst, $src1, $src2, $src3"),
                         [(set (Ty RC:$dst),
                               (or (and (Ty RC:$src1),
                                        (Ty ImmTy:$src2)),
                                   (and (Ty RC:$src3),
                                        (not (Ty RC:$src1)))))]>;

    def _rii : HSAILInst<(outs RC:$dst), (ins RC:$src1, OpTy:$src2, OpTy:$src3),
                         !strconcat(asm,"\t $dst, $src1, $src2, $src3"),
                         [(set (Ty RC:$dst),
                               (or (and (Ty RC:$src1),
                                        (Ty ImmTy:$src2)),
                                   (and (not (Ty RC:$src1)),
                                        (Ty ImmTy:$src3))))]>;

    // Alternative rii pattern: (src1 & src2) | ((src1 & src3) ^ src3)
    def _rii1 : HSAILInst<(outs RC:$dst), (ins RC:$src1, OpTy:$src2, OpTy:$src3),
                         !strconcat(asm,"\t $dst, $src1, $src2, $src3"),
                         [(set (Ty RC:$dst),
                               (or (and (Ty RC:$src1),
                                        (Ty ImmTy:$src2)),
                                   (xor (and (Ty RC:$src1),
                                             (Ty ImmTy:$src3)),
                                        (Ty ImmTy:$src3))))]>;

    def _rri : HSAILInst<(outs RC:$dst), (ins RC:$src1, RC:$src2, OpTy:$src3),
                         !strconcat(asm,"\t $dst, $src1, $src2, $src3"),
                         [(set (Ty RC:$dst),
                               (or (and (Ty RC:$src1),
                                        (Ty RC:$src2)),
                                   (and (not (Ty RC:$src1)),
                                        (Ty ImmTy:$src3))))]>;

    // Alternative rri pattern: (src1 & src2) | ((src1 & src3) ^ src3)
    def _rri1 : HSAILInst<(outs RC:$dst), (ins RC:$src1, RC:$src2, OpTy:$src3),
                         !strconcat(asm,"\t $dst, $src1, $src2, $src3"),
                         [(set (Ty RC:$dst),
                               (or (and (Ty RC:$src1),
                                        (Ty RC:$src2)),
                                   (xor (and (Ty RC:$src1),
                                             (Ty ImmTy:$src3)),
                                        (Ty ImmTy:$src3))))]>;

    // Alternative pattern: (src3 ^ (src1 & (src2 ^ src3)))
    def _rrr2 : HSAILInst<(outs RC:$dst), (ins RC:$src1, RC:$src2, RC:$src3),
                         !strconcat(asm,"\t $dst, $src1, $src2, $src3"),
                         [(set (Ty RC:$dst),
                               (xor (Ty RC:$src3),
                                    (and (Ty RC:$src1),
                                         (xor (Ty RC:$src2),
                                              (Ty RC:$src3)))))]>;

    def _irr2 : HSAILInst<(outs RC:$dst), (ins OpTy:$src1, RC:$src2, RC:$src3),
                         !strconcat(asm,"\t $dst, $src1, $src2, $src3"),
                         [(set (Ty RC:$dst),
                               (xor (Ty RC:$src3),
                                    (and (xor (Ty RC:$src2),
                                              (Ty RC:$src3)),
                                         (Ty ImmTy:$src1))))]>;

    def _iir2 : HSAILInst<(outs RC:$dst), (ins OpTy:$src1, OpTy:$src2, RC:$src3),
                         !strconcat(asm,"\t $dst, $src1, $src2, $src3"),
                         [(set (Ty RC:$dst),
                               (xor (Ty RC:$src3),
                                    (and (xor (Ty RC:$src3),
                                              (Ty ImmTy:$src2)),
                                         (Ty ImmTy:$src1))))]>;

    def _rir2 : HSAILInst<(outs RC:$dst), (ins RC:$src1, OpTy:$src2, RC:$src3),
                         !strconcat(asm,"\t $dst, $src1, $src2, $src3"),
                         [(set (Ty RC:$dst),
                               (xor (Ty RC:$src3),
                                    (and (Ty RC:$src1),
                                         (xor (Ty RC:$src3),
                                              (Ty ImmTy:$src2)))))]>;

    def _rri2 : HSAILInst<(outs RC:$dst), (ins RC:$src1, RC:$src2, OpTy:$src3),
                         !strconcat(asm,"\t $dst, $src1, $src2, $src3"),
                         [(set (Ty RC:$dst),
                               (xor (and (Ty RC:$src1),
                                         (xor (Ty RC:$src2),
                                              (Ty ImmTy:$src3))),
                                    (Ty ImmTy:$src3)))]>;

    // Alternative pattern: ((src3 & src1) ^ src3) ^ (src2 & src1)
    def _rrr3 : HSAILInst<(outs RC:$dst), (ins RC:$src1, RC:$src2, RC:$src3),
                         !strconcat(asm,"\t $dst, $src1, $src2, $src3"),
                         [(set (Ty RC:$dst),
                               (xor (xor (Ty RC:$src3),
                                         (and (Ty RC:$src1),
                                              (Ty RC:$src3))),
                                    (and (Ty RC:$src1),
                                         (Ty RC:$src2))))]>;

    def _irr3 : HSAILInst<(outs RC:$dst), (ins OpTy:$src1, RC:$src2, RC:$src3),
                         !strconcat(asm,"\t $dst, $src1, $src2, $src3"),
                         [(set (Ty RC:$dst),
                               (xor (xor (Ty RC:$src3),
                                         (and (Ty RC:$src3),
                                              (Ty ImmTy:$src1))),
                                    (and (Ty RC:$src2),
                                         (Ty ImmTy:$src1))))]>;

    def _iir3 : HSAILInst<(outs RC:$dst), (ins OpTy:$src1, OpTy:$src2, RC:$src3),
                         !strconcat(asm,"\t $dst, $src1, $src2, $src3"),
                         [(set (Ty RC:$dst),
                               (bfiImmIIR3 (Ty ImmTy:$src1), (Ty ImmTy:$src2),
                                           (Ty RC:$src3)))]>;

    def _rri3 : HSAILInst<(outs RC:$dst), (ins RC:$src1, RC:$src2, OpTy:$src3),
                         !strconcat(asm,"\t $dst, $src1, $src2, $src3"),
                         [(set (Ty RC:$dst),
                               (xor (xor (and (Ty RC:$src1),
                                              (Ty ImmTy:$src3)),
                                         (Ty ImmTy:$src3)),
                                    (and (Ty RC:$src1),
                                         (Ty RC:$src2))))]>;

    def _rii3 : HSAILInst<(outs RC:$dst), (ins RC:$src1, OpTy:$src2, OpTy:$src3),
                         !strconcat(asm,"\t $dst, $src1, $src2, $src3"),
                         [(set (Ty RC:$dst),
                               (xor (xor (and (Ty RC:$src1),
                                              (Ty ImmTy:$src3)),
                                         (Ty ImmTy:$src3)),
                                    (and (Ty RC:$src1),
                                         (Ty ImmTy:$src2))))]>;
}

defm bitselect_b32 : BitSelect<"bitselect_b32", i32, GPR32, i32imm, imm>;
defm bitselect_b64 : BitSelect<"bitselect_b64", i64, GPR64, i64imm, imm>;

// pack

def pack_u32x2lo_to_hi: HSAILInst<(outs GPR64:$dst), (ins GPR32:$src),
                                 "pack_u32x2_u32\t $dst, 0, $src, 1",
                                 [(set (i64 GPR64:$dst),
                                       (shl (anyext (i32 GPR32:$src)),
                                            (i32 32)))]>;

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

let AddedComplexity = 5 in {
    multiclass fnrcp<string asm> {

        def _f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1),
            !strconcat(asm, "_f32\t $dst, $src1"),
            [(set (f32 GPR32:$dst), 
                (fdiv (fp32imm1), (f32 GPR32:$src1)))]>;

        def _f64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1),
            !strconcat(asm, "_f64\t $dst, $src1"),
            [(set (f64 GPR64:$dst), 
                (fdiv (fp64imm1), (f64 GPR64:$src1)))]>;
    }
}

let Predicates = [UnsafeFPMath] in {
    defm fnrcp : fnrcp<"nrcp">; // Pure 1.0 / x

    // -1.0 / x
    let AddedComplexity = 4 in {
     def : Pat<(fdiv fp32imm_minus1, (f32 GPR32:$src)),
               (neg_f32 (fnrcp_f32 (f32 GPR32:$src)))>;
     def : Pat<(fdiv fp64imm_minus1, (f64 GPR64:$src)),
               (neg_f64 (fnrcp_f64 (f64 GPR64:$src)))>;
    }

    let AddedComplexity = 5 in {
     def : Pat<(fdiv fp32imm_minus1, (fneg (f32 GPR32:$src))),
               (fnrcp_f32 (f32 GPR32:$src))>;
     def : Pat<(fdiv fp64imm_minus1, (fneg (f64 GPR64:$src))),
               (fnrcp_f64 (f64 GPR64:$src))>;
    }
}

////////////////////////////////////////////////////////////////////////////////
// rsqrt

let AddedComplexity = 15 in {
    multiclass fnrsqrt<string asm> {

        def _f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1),
            !strconcat(asm, "_f32\t $dst, $src1"),
            [(set (f32 GPR32:$dst), 
                (fdiv (fp32imm1), 
                    (int_HSAIL_nsqrt_f32 (f32 GPR32:$src1))))]>;

        def _f64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1),
            !strconcat(asm, "_f64\t $dst, $src1"),
            [(set (f64 GPR64:$dst), 
                (fdiv (fp64imm1), 
                    (int_HSAIL_nsqrt_f64 (f64 GPR64:$src1))))]>;
    }
}

let Predicates = [UnsafeFPMath] in {
    defm fnrsqrt : fnrsqrt<"nrsqrt">; // Pure 1.0 / sqrt(x)

    let AddedComplexity = 10 in {
        def : Pat<(f32 (fdiv GPR32:$src1, (int_HSAIL_nsqrt_f32 GPR32:$src2))),
                  (f32 (mul_f32 GPR32:$src1, (nrsqrt_f32 (f32 GPR32:$src2))))>;
        def : Pat<(f32 (fdiv fpimm:$src1, (int_HSAIL_nsqrt_f32 GPR32:$src2))),
                  (f32 (mul_f32 fpimm:$src1, (nrsqrt_f32 (f32 GPR32:$src2))))>;
        def : Pat<(f64 (fdiv GPR64:$src1, (int_HSAIL_nsqrt_f64 GPR64:$src2))),
                  (f64 (mul_f64 GPR64:$src1, (nrsqrt_f64 (f64 GPR64:$src2))))>;
        def : Pat<(f64 (fdiv fpimm:$src1, (int_HSAIL_nsqrt_f64 GPR64:$src2))),
                  (f64 (mul_f64 fpimm:$src1, (nrsqrt_f64 (f64 GPR64:$src2))))>;
    }
}

////////////////////////////////////////////////////////////////////////////////
// Min/Max
multiclass minmax<string asm, ValueType Ty, Operand OpTy, SDNode ImmTy,
                  RegisterClass RC, CondCode cc12, CondCode cc21> {

    def _rr12 : HSAILInst<(outs RC:$dst), (ins RC:$src1, RC:$src2),
        !strconcat(asm, "\t $dst, $src1, $src2"),
        [(set (Ty RC:$dst),
            (select (i1 (setcc RC:$src1, RC:$src2, cc12)),
                    RC:$src1, RC:$src2))]>;

    def _ri12 : HSAILInst<(outs RC:$dst), (ins RC:$src1, OpTy:$src2),
        !strconcat(asm, "\t $dst, $src1, $src2"),
        [(set (Ty RC:$dst),
            (select (i1 (setcc RC:$src1, ImmTy:$src2, cc12)),
                    RC:$src1, ImmTy:$src2))]>;

    def _ir12 : HSAILInst<(outs RC:$dst), (ins OpTy:$src1, RC:$src2),
        !strconcat(asm, "\t $dst, $src1, $src2"),
        [(set (Ty RC:$dst),
            (select (i1 (setcc ImmTy:$src1, RC:$src2, cc12)),
                    ImmTy:$src1, RC:$src2))]>;

    def _rr21 : HSAILInst<(outs RC:$dst), (ins RC:$src1, RC:$src2),
        !strconcat(asm, "\t $dst, $src1, $src2"),
        [(set (Ty RC:$dst),
            (select (i1 (setcc RC:$src1, RC:$src2, cc21)),
                    RC:$src2, RC:$src1))]>;

    def _ri21 : HSAILInst<(outs RC:$dst), (ins RC:$src1, OpTy:$src2),
        !strconcat(asm, "\t $dst, $src1, $src2"),
        [(set (Ty RC:$dst),
            (select (i1 (setcc RC:$src1, ImmTy:$src2, cc21)),
                    ImmTy:$src2, RC:$src1))]>;

    def _ir21 : HSAILInst<(outs RC:$dst), (ins OpTy:$src1, RC:$src2),
        !strconcat(asm, "\t $dst, $src1, $src2"),
        [(set (Ty RC:$dst),
            (select (i1 (setcc ImmTy:$src1, RC:$src2, cc21)),
                    RC:$src2, ImmTy:$src1))]>;
}

defm min_s32  : minmax<"min_s32", i32, i32imm, imm,   GPR32, SETLT,  SETGT>;
defm min_u32  : minmax<"min_u32", i32, i32imm, imm,   GPR32, SETULT, SETUGT>;
defm max_s32  : minmax<"max_s32", i32, i32imm, imm,   GPR32, SETGT,  SETLT>;
defm max_u32  : minmax<"max_u32", i32, i32imm, imm,   GPR32, SETUGT, SETULT>;
defm min_s64  : minmax<"min_s64", i64, i64imm, imm,   GPR64, SETLT,  SETGT>;
defm min_u64  : minmax<"min_u64", i64, i64imm, imm,   GPR64, SETULT, SETUGT>;
defm max_s64  : minmax<"max_s64", i64, i64imm, imm,   GPR64, SETGT,  SETLT>;
defm max_u64  : minmax<"max_u64", i64, i64imm, imm,   GPR64, SETUGT, SETULT>;
defm minu_f64 : minmax<"min_f64", f64, f64imm, fpimm, GPR64, SETULT, SETUGT>;
defm maxu_f64 : minmax<"max_f64", f64, f64imm, fpimm, GPR64, SETUGT, SETULT>;
defm mino_f64 : minmax<"min_f64", f64, f64imm, fpimm, GPR64, SETOLT, SETOGT>;
defm maxo_f64 : minmax<"max_f64", f64, f64imm, fpimm, GPR64, SETOGT, SETOLT>;

let Predicates = [EnableGCNMinMax] in {
    defm minu_f32 : minmax<"gcn_min_f32", f32, f32imm, fpimm, GPR32, SETULT, SETUGT>;
    defm maxu_f32 : minmax<"gcn_max_f32", f32, f32imm, fpimm, GPR32, SETUGT, SETULT>;
    defm mino_f32 : minmax<"gcn_min_f32", f32, f32imm, fpimm, GPR32, SETOLT, SETOGT>;
    defm maxo_f32 : minmax<"gcn_max_f32", f32, f32imm, fpimm, GPR32, SETOGT, SETOLT>;
}

////////////////////////////////////////////////////////////////////////////////
// Abs
class abs<string asm, ValueType Ty, RegisterClass RC, int shift> :
  HSAILInst<(outs RC:$dst), (ins RC:$src),
            !strconcat(asm, "\t $dst, $src"),
            [(set (Ty RC:$dst),
                  (xor (add (sra (Ty RC:$src), (i32 shift)), (Ty RC:$src)),
                       (sra (Ty RC:$src), (i32 shift))))]>;

def folded_abs_s32 : abs<"abs_s32", i32, GPR32, 31>;
def folded_abs_s64 : abs<"abs_s64", i64, GPR64, 63>;

////////////////////////////////////////////////////////////////////////////////
// Misc patterns
// Upper half of the expression result:
// (float)((int) f32 / i32)) -> mulhi_u32
// Expr morphed to: ((i64)f32 * (i64)i32) >> 32

def isUpper32AllOnes : PatLeaf<(imm), [{
    return (N->getZExtValue() >> 32) == 0xffffffff;
}]>;

def F2IDivI2F64 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, i64imm:$src2),
    "mulhi_u32\t$dst, $src1, $src2",
    [(set (i32 GPR32:$dst), (trunc 
        (srl 
            (mul 
                 (sext (i32 GPR32:$src1)), 
                 (i64 isUpper32AllOnes:$src2)), 
            (i32 32))))]>;


////////////////////////////////////////////////////////////////////////////////
// fadd y (fmul x, 1)
multiclass FusedAddMul1<string asm, ValueType Ty, Operand OpTy,
                       SDNode ImmTy, RegisterClass RC, PatLeaf one> {

    def _rri : HSAILInst<(outs RC:$dst), (ins RC:$src1, RC:$src2),
        !strconcat(asm, "\t $dst, $src1, $src2"),
        [(set (Ty RC:$dst), 
            (fadd (Ty RC:$src1), (fmul (Ty RC:$src2), one)))]>;
  
    def _iri : HSAILInst<(outs RC:$dst), (ins OpTy:$src1, RC:$src2),
        !strconcat(asm, "\t $dst, $src1, $src2"),
        [(set (Ty RC:$dst), 
            (fadd (Ty ImmTy:$src1), (fmul (Ty RC:$src2), one)))]>;
}

defm addmul1_f32 : FusedAddMul1<"add_ftz_f32", f32, f32imm, fpimm, GPR32, fp32imm1>;
defm addmul1_f64 : FusedAddMul1<"add_f64", f64, f64imm, fpimm, GPR64, fp64imm1>;

////////////////////////////////////////////////////////////////////////////////
// rotate

// rotate (x, const)
def byteSzImm : SDNodeXForm<imm, [{
    return CurDAG->getTargetConstant(((N->getZExtValue() & 31) >> 3), MVT::i32);
}]>;

def isByteSzShift : PatLeaf<(imm), [{
    return (N->getZExtValue() & 7) == 0;
}], byteSzImm>;

def RotateByte32const : PatFrag<(ops node:$reg, node:$shl, node:$shr), 
                                (or (shl node:$reg, node:$shl),
                                    (srl node:$reg, node:$shr)),
                                [{
    ConstantSDNode *CNShl, *CNShr;
    if ((CNShl = dyn_cast<ConstantSDNode>(N->getOperand(0)->getOperand(1))) &&
        (CNShr = dyn_cast<ConstantSDNode>(N->getOperand(1)->getOperand(1)))) {
        uint32_t shl = CNShl->getZExtValue() & 31;
        uint32_t shr = CNShr->getZExtValue() & 31;
        return ((shl + shr) == 32) && ((shl & 7) == 0);
    }
    return false;
}]>;

let AddedComplexity = 1 in {
def RotateByte32_ri : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, i32imm:$src2,
                                                i32imm:$src3),
                               "bytealign_b32\t $dst, $src1, $src1, $src3",
                               [(set (i32 GPR32:$dst),
                                  (RotateByte32const (i32 GPR32:$src1),
                                    (i32 isByteSzShift:$src2),
                                    (i32 isByteSzShift:$src3)))]>;
}

def RotateBit32const : PatFrag<(ops node:$reg, node:$shl, node:$shr), 
                               (or (shl node:$reg, node:$shl),
                                   (srl node:$reg, node:$shr)),
                               [{
    ConstantSDNode *CNShl, *CNShr;
    if ((CNShl = dyn_cast<ConstantSDNode>(N->getOperand(0)->getOperand(1))) &&
        (CNShr = dyn_cast<ConstantSDNode>(N->getOperand(1)->getOperand(1)))) {
        uint32_t shl = CNShl->getZExtValue() & 31;
        uint32_t shr = CNShr->getZExtValue() & 31;
        return (shl + shr) == 32;
    }
    return false;
}]>;

def RotateBit32_ri : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, i32imm:$src2,
                                                   i32imm:$src3),
                               "bitalign_b32\t $dst, $src1, $src1, $src3",
                               [(set (i32 GPR32:$dst),
                                  (RotateBit32const (i32 GPR32:$src1),
                                    (i32 imm:$src2), (i32 imm:$src3)))]>;

def : Pat<(or (shl (i32 GPR32:$src1), (and (i32 GPR32:$src2), imm31)),
              (srl (i32 GPR32:$src1), (and (ineg (i32 GPR32:$src2)), imm31))),
          (media_bitalign_rrr GPR32:$src1, GPR32:$src1, (neg_s32 GPR32:$src2))>;

def : Pat<(or (shl (i32 GPR32:$src1), (i32 GPR32:$src2)),
              (srl (i32 GPR32:$src1), (sub imm32, (and (i32 GPR32:$src2), imm31)))),
          (media_bitalign_rrr GPR32:$src1, GPR32:$src1, (neg_s32 GPR32:$src2))>;
