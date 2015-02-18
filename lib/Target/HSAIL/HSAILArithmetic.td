
def ADD : HSAILInstMod_2Op<"add", BrigOpcode.ADD>;
def SUB : HSAILInstMod_2Op<"sub", BrigOpcode.SUB>;
def MUL : HSAILInstMod_2Op<"mul", BrigOpcode.MUL>;
def DIV : HSAILInstMod_2Op<"div", BrigOpcode.DIV>;
def REM : HSAILInstBasic_2Op<"rem", BrigOpcode.REM>;
def MULHI : HSAILInstBasic_2Op<"mulhi", BrigOpcode.MULHI>;
def ABS : HSAILInstMod_1Op<"abs", BrigOpcode.ABS>;

defm : InstMod_2Op_IntTypes<ADD, add>;
defm : InstMod_2Op_FPTypes<ADD, fadd>;
defm : InstMod_2Op_IntTypes<SUB, sub, 0>;
defm : InstMod_2Op_FPTypes<SUB, fsub>;
defm : InstMod_2Op_IntTypes<MUL, mul, 0>;
defm : InstMod_2Op_FPTypes<MUL, fmul>;

defm : InstMod_2Op_IntTypes<DIV, udiv, 0>;
defm : InstMod_2Op_IntTypes<DIV, sdiv, 1>;
defm : InstMod_2Op_FPTypes<DIV, fdiv>;

// Division without implicit ftz.
def : InstMod_2Op_Pat<DIV, int_HSAIL_div_f32, f32,
  BrigTypeX.F32, BrigRound.FLOAT_NEAR_EVEN, 0
>;

defm : InstBasic_2Op_IntTypes<REM, urem, 0>;
defm : InstBasic_2Op_IntTypes<REM, srem, 1>;

defm : InstBasic_2Op_IntTypes<MULHI, mulhu, 0>;
defm : InstBasic_2Op_IntTypes<MULHI, mulhs, 1>;


def : InstMod_1Op_Pat<ABS, fabs, f32, BrigTypeX.F32>;
def : InstMod_1Op_Pat<ABS, fabs, f64, BrigTypeX.F64>;

def MAD : HSAILInstBasic_3Op<"mad", BrigOpcode.MAD>;
defm : InstBasic_3Op_IntTypes<MAD, HSAILumad, 0>;

// u[32,64] forms illegal in HSAIL
def NEG : HSAILInstBasic_1Op<"neg", BrigOpcode.NEG>;

let AddedComplexity = 2 in {
// Needs to match before sub pattern.
defm : InstBasic_1Op_IntTypes<NEG, ineg, 1>;
}

defm : InstBasic_1Op_FPTypes<NEG, fneg>;

def COPYSIGN : HSAILInstMod_2Op<"copysign", BrigOpcode.COPYSIGN>;

// FIXME: Need to support fcopysign with different second operand type.
def : InstMod_2Op_Pat<COPYSIGN, fcopysign, f32, BrigTypeX.F32, BrigRound.NONE, 0>;
def : InstMod_2Op_Pat<COPYSIGN, fcopysign, f64, BrigTypeX.F64, BrigRound.NONE, 0>;


def FMA : HSAILInstMod_3Op<"fma", BrigOpcode.FMA>;
defm : InstMod_3Op_FPTypes<FMA, fma>;

def NFMA : HSAILInstBasic_3Op<"nfma", BrigOpcode.NFMA>;
defm : InstBasic_3Op_FPTypes<NFMA, HSAILnfma>;

def MAX : HSAILInstMod_2Op<"max", BrigOpcode.MAX>;
def MIN : HSAILInstMod_2Op<"min", BrigOpcode.MIN>;

defm : InstMod_2Op_FPTypes<MAX, fmaxnum, BrigRound.NONE>;
defm : InstMod_2Op_FPTypes<MIN, fminnum, BrigRound.NONE>;

defm : InstMod_2Op_IntTypes<MAX, HSAILumax, 0>;
defm : InstMod_2Op_IntTypes<MAX, HSAILsmax, 1>;

defm : InstMod_2Op_IntTypes<MIN, HSAILumin, 0>;
defm : InstMod_2Op_IntTypes<MIN, HSAILsmin, 1>;

def GCN_MAX : HSAILInstBasic_2Op<"gcn_max", BrigOpcode.GCNMAX>;
def GCN_MIN : HSAILInstBasic_2Op<"gcn_min", BrigOpcode.GCNMIN>;

// FIXME: Remove these intrinsics
def : InstBasic_2Op_Pat<GCN_MAX, int_HSAIL_gcn_max_f32, f32, f32, BrigTypeX.F32>;
def : InstBasic_2Op_Pat<GCN_MAX, int_HSAIL_gcn_max_f64, f64, f64, BrigTypeX.F64>;
def : InstBasic_2Op_Pat<GCN_MIN, int_HSAIL_gcn_min_f32, f32, f32, BrigTypeX.F32>;
def : InstBasic_2Op_Pat<GCN_MIN, int_HSAIL_gcn_min_f64, f64, f64, BrigTypeX.F64>;


def MUL24 : HSAILInstBasic_2Op<"mul24", BrigOpcode.MUL24>;
def : InstBasic_2Op_Pat<MUL24, HSAILsmul24, i32, i32, BrigTypeX.S32>;
def : InstBasic_2Op_Pat<MUL24, HSAILumul24, i32, i32, BrigTypeX.U32>;


def MAD24 : HSAILInstBasic_3Op<"mad24", BrigOpcode.MAD24>;
def : InstBasic_3Op_Pat<MAD24, HSAILsmad24, i32, BrigTypeX.S32>;
def : InstBasic_3Op_Pat<MAD24, HSAILumad24, i32, BrigTypeX.U32>;

def SQRT : HSAILInstMod_1Op<"sqrt", BrigOpcode.SQRT>;
def NSQRT : HSAILInstBasic_1Op<"nsqrt", BrigOpcode.NSQRT>;
def NRSQRT : HSAILInstBasic_1Op<"nrsqrt", BrigOpcode.NRSQRT>;
def NRCP : HSAILInstBasic_1Op<"rcp", BrigOpcode.NRCP>;

// FIXME: Having the ftz explicitly in this one is totally inconsistent
def : InstMod_1Op_Pat<SQRT, int_HSAIL_sqrt_ftz_f32, f32, BrigTypeX.F32,
                      BrigRound.FLOAT_NEAR_EVEN, 1
>;

def : InstMod_1Op_Pat<SQRT, int_HSAIL_sqrt_f64, f64, BrigTypeX.F64,
                      BrigRound.FLOAT_NEAR_EVEN, 0
>;

def : InstBasic_1Op_Pat<NSQRT, int_HSAIL_nsqrt_f32, f32, BrigTypeX.F32>;
def : InstBasic_1Op_Pat<NSQRT, int_HSAIL_nsqrt_f64, f64, BrigTypeX.F64>;

def : InstBasic_1Op_Pat<NRSQRT, int_HSAIL_nrsqrt_f32, f32, BrigTypeX.F32>;
def : InstBasic_1Op_Pat<NRSQRT, int_HSAIL_nrsqrt_f64, f64, BrigTypeX.F64>;

def : InstBasic_1Op_Pat<NRCP, int_HSAIL_nrcp_f32, f32, BrigTypeX.F32>;
def : InstBasic_1Op_Pat<NRCP, int_HSAIL_nrcp_f64, f64, BrigTypeX.F64>;


// HSAIL_SPEC_CURRENT <
def FRACT : HSAILInstMod_1Op<"fract", BrigOpcode.FRACT>;
defm : InstMod_1Op_FPTypes<FRACT, HSAILfract, BrigRound.NONE>;
// > HSAIL_SPEC_CURRENT

// Native Floating-Point Special Functions Operations
def NSIN : HSAILInstBasic_1Op<"nsin", BrigOpcode.NSIN>;
def NCOS : HSAILInstBasic_1Op<"ncos", BrigOpcode.NCOS>;
def NEXP2 : HSAILInstBasic_1Op<"nexp2", BrigOpcode.NEXP2>;
def NLOG2 : HSAILInstBasic_1Op<"nlog2", BrigOpcode.NLOG2>;

def : InstBasic_1Op_Pat<NSIN, int_HSAIL_nsin_f32, f32, BrigTypeX.F32>;
def : InstBasic_1Op_Pat<NCOS, int_HSAIL_ncos_f32, f32, BrigTypeX.F32>;
def : InstBasic_1Op_Pat<NEXP2, int_HSAIL_nexp2_f32, f32, BrigTypeX.F32>;
def : InstBasic_1Op_Pat<NLOG2, int_HSAIL_nlog2_f32, f32, BrigTypeX.F32>;


////////////////////////////////////////////////////////////////////////////////
// Logical bit ops.

def AND : HSAILInstBasic_2Op<"and", BrigOpcode.AND>;
def OR : HSAILInstBasic_2Op<"or", BrigOpcode.OR>;
def XOR : HSAILInstBasic_2Op<"xor", BrigOpcode.XOR>;

defm : InstBasic_2Op_BitIntTypes<AND, and>;
defm : InstBasic_2Op_BitIntTypes<OR, or>;
defm : InstBasic_2Op_BitIntTypes<XOR, xor>;

////////////////////////////////////////////////////////////////////////////////
// not (integer, 1-bit, 32-bit, and 64-bit)
def NOT : HSAILInstBasic_1Op<"not", BrigOpcode.NOT>;
defm : InstBasic_1Op_BitIntTypes<NOT, not>;

////////////////////////////////////////////////////////////////////////////////
// cvt

def CVT : InstCvt<"cvt">;

////////////////////////////////////////////////////////////////////////////////
// popcount (integer, 1-bit, 32-bit, and 64-bit)

// Patterns for integer intrinsics that match to InstSourceType. The
// LLVM intrinsics return an integer with equivalent width as the
// source, but the HSAIL instructions truncate to a 32-bit result.
multiclass InstSourceType_1Op_Pats<Instruction inst,
                                   SDPatternOperator node,
                                   bit bit_src = 0> {
  def : Pat<
    (i64 (node i64:$src0)),
    (CVT 0, 0, BrigTypeX.U64, BrigTypeX.U32,
      (i32 (inst i64:$src0, BrigTypeX.U32, !if(bit_src, BrigTypeX.B64, BrigTypeX.U64))))
  >;

  def : Pat<
    (i32 (trunc (node i64:$src0))),
    (i32 (inst i64:$src0, BrigTypeX.U32, !if(bit_src, BrigTypeX.B64, BrigTypeX.U64)))
  >;

  def : Pat<
    (i32 (node i32:$src0)),
    (inst i32:$src0, BrigTypeX.U32, !if(bit_src, BrigTypeX.B32, BrigTypeX.U32))
  >;
}

def POPCOUNT : HSAILInstSourceType_1Op<"popcount", BrigOpcode.POPCOUNT>;

defm : InstSourceType_1Op_Pats<POPCOUNT, ctpop, 1>;

////////////////////////////////////////////////////////////////////////////////
// firstbit (integer, 1-bit, 32-bit, and 64-bit)
// HSAIL_SPEC_CURRENT <

def FIRSTBIT : HSAILInstSourceType_1Op<"firstbit", BrigOpcode.FIRSTBIT>;
defm : InstSourceType_1Op_Pats<FIRSTBIT, ctlz>;
def : InstSourceType_1Op_Pat<FIRSTBIT, int_HSAIL_firstbit_u32, i32, BrigTypeX.U32, BrigTypeX.U32>;

// > HSAIL_SPEC_CURRENT

////////////////////////////////////////////////////////////////////////////////
// lastbit (integer, 1-bit, 32-bit, and 64-bit)
// HSAIL_SPEC_CURRENT <

def LASTBIT : HSAILInstSourceType_1Op<"lastbit", BrigOpcode.LASTBIT>;

defm : InstSourceType_1Op_Pats<LASTBIT, cttz>;
def : InstSourceType_1Op_Pat<LASTBIT, int_HSAIL_lastbit_u32, i32, BrigTypeX.U32, BrigTypeX.U32>;

// > HSAIL_SPEC_CURRENT

////////////////////////////////////////////////////////////////////////////////
// signbit (integer, 1-bit, 32-bit, and 64-bit)

////////////////////////////////////////////////////////////////////////////////
// shl (integer, signed and unsigned, 32-bit and 64-bit)
// shr (integer, signed and unsigned, 32-bit and 64-bit)
def SHL : HSAILInstBasic_2Op<"shl", BrigOpcode.SHL>;
def SHR : HSAILInstBasic_2Op<"shr", BrigOpcode.SHR>;

def : InstBasic_2Op_Pat<SHL, shl, i32, i32, BrigTypeX.U32>;
def : InstBasic_2Op_Pat<SHL, shl, i64, i32, BrigTypeX.U64>;

def : InstBasic_2Op_Pat<SHR, srl, i32, i32, BrigTypeX.U32>;
def : InstBasic_2Op_Pat<SHR, srl, i64, i32, BrigTypeX.U64>;

def : InstBasic_2Op_Pat<SHR, sra, i32, i32, BrigTypeX.S32>;
def : InstBasic_2Op_Pat<SHR, sra, i64, i32, BrigTypeX.S64>;

////////////////////////////////////////////////////////////////////////////////
// cmov (1-bit, 32-bit, and 64-bit; integer and float)

def CMOV : HSAILInstBasic_3Op<"cmov", BrigOpcode.CMOV>;

// Reduce complexity to prefer selecting various min / max patterns on
// select.
let AddedComplexity = -10 in {
  def : InstBasic_CMov_Pat<CMOV, i1, BrigTypeX.B1>;
  def : InstBasic_CMov_Pat<CMOV, i32, BrigTypeX.B32>;
  def : InstBasic_CMov_Pat<CMOV, f32, BrigTypeX.B32>;
  def : InstBasic_CMov_Pat<CMOV, i64, BrigTypeX.B64>;
  def : InstBasic_CMov_Pat<CMOV, f64, BrigTypeX.B64>;
}

////////////////////////////////////////////////////////////////////////////////
// bitrev (integer, 32-bit, and 64-bit)

////////////////////////////////////////////////////////////////////////////////
// extract (integer, 32-bit, and 64-bit)

////////////////////////////////////////////////////////////////////////////////
// insert (integer, 32-bit, and 64-bit)

////////////////////////////////////////////////////////////////////////////////
// mov

// FIXME: Spec calls TypeLength moveType for some reason, but that
// would be painful to deal with.
def MOV : HSAILInstBasic_1Op<"mov", BrigOpcode.MOV> {
  let isAsCheapAsAMove = 1;
  let isReMaterializable = 1;
}


// FIXME: Omitting 'node' in the output pattern results in invalid
// output with a mov using and defining the same register.
class MovImmPat<SDPatternOperator node, ValueType vt, int bt> : Pat <
  (vt node:$src0),
  (MOV node:$src0, bt)
>;

class BitconvertMovPat<ValueType destvt, ValueType srcvt, int bt> : Pat <
  (destvt (bitconvert srcvt:$src0)),
  (MOV $src0, bt)
>;


def : MovImmPat<imm, i1, BrigTypeX.B1>;
def : MovImmPat<imm, i32, BrigTypeX.B32>;
def : MovImmPat<imm, i64, BrigTypeX.B64>;
def : MovImmPat<fpimm, f32, BrigTypeX.F32>;
def : MovImmPat<fpimm, f64, BrigTypeX.F64>;

def : BitconvertMovPat<f64, i64, BrigTypeX.B64>;
def : BitconvertMovPat<i64, f64, BrigTypeX.B64>;
def : BitconvertMovPat<f32, i32, BrigTypeX.B32>;
def : BitconvertMovPat<i32, f32, BrigTypeX.B32>;


////////////////////////////////////////////////////////////////////////////////
// misc operations
def : Pat <
  (f32 (int_HSAIL_ftz_f32 f32:$src0)),
  (ADD 1, BrigRound.FLOAT_PLUS_INFINITY, $src0, (i32 0), BrigTypeX.F32)
>;

def BITSELECT : HSAILInstBasic_3Op<"bitselect", BrigOpcode.BITSELECT>;
defm : InstBasic_3Op_BitIntTypes<BITSELECT, HSAILbitselect>;

def PACK : HSAILInstSourceType_3Op<"pack", BrigOpcode.PACK>;

// Media - packcvt
def PACKCVT : HSAILInstSourceType_4Op<"packcvt", BrigOpcode.PACKCVT>;

def : InstSourceType_4Op_Pat<PACKCVT, int_HSAIL_packcvt_u8x4_f32,
   f32, BrigTypeX.U8X4, BrigTypeX.F32
>;

// Media - unpackcvt

def UNPACKCVT : HSAILInstSourceType_2Op<"unpackcvt", BrigOpcode.UNPACKCVT>;
def : InstSourceType_2Op_Pat<UNPACKCVT, int_HSAIL_unpackcvt_f32_u8x4,
   f32, BrigTypeX.F32, BrigTypeX.U8X4
>;

def BITALIGN : HSAILInstBasic_3Op<"bitalign", BrigOpcode.BITALIGN>;
def BYTEALIGN : HSAILInstBasic_3Op<"bytealign", BrigOpcode.BYTEALIGN>;

def : InstBasic_3Op_Pat<BITALIGN, int_HSAIL_bitalign_b32, i32, BrigTypeX.B32>;
def : InstBasic_3Op_Pat<BYTEALIGN, int_HSAIL_bytealign_b32, i32, BrigTypeX.B32>;

def LERP : HSAILInstBasic_3Op<"lerp", BrigOpcode.LERP>;
def : InstBasic_3Op_Pat<LERP, int_HSAIL_lerp_u8x4, i32, BrigTypeX.U8X4>;

def SAD : HSAILInstSourceType_3Op<"sad", BrigOpcode.SAD>;
def : InstSourceType_3Op_Pat<SAD, int_HSAIL_sad_u32_u8x4,
   i32, BrigTypeX.U32, BrigTypeX.U8X4
>;

def SADHI : HSAILInstSourceType_3Op<"sadhi", BrigOpcode.SADHI>;
def : InstSourceType_3Op_Pat<SADHI, int_HSAIL_sadhi_u16x2_u8x4,
   i32, BrigTypeX.U16X2, BrigTypeX.U8X4
>;

// media_ops2

def GCN_MSAD : HSAILInstBasic_3Op<"gcn_msad", BrigOpcode.GCNMSAD>;
def : InstBasic_3Op_Pat<GCN_MSAD, int_HSAIL_msad, i32, BrigTypeX.B32>;

def GCN_SADW : HSAILInstBasic_3Op<"gcn_sadw", BrigOpcode.GCNSADW>;
def : InstBasic_3Op_Pat<GCN_SADW, int_HSAIL_sadw, i32, BrigTypeX.B32>;

def GCN_SADD : HSAILInstBasic_3Op<"gcn_sadd", BrigOpcode.GCNSADD>;
def : InstBasic_3Op_Pat<GCN_SADD, int_HSAIL_sadd, i32, BrigTypeX.B32>;

def GCN_MIN3 : HSAILInstBasic_3Op<"gcn_min3", BrigOpcode.GCNMIN3>;
def : InstBasic_3Op_Pat<GCN_MIN3, int_HSAIL_imin3, i32, BrigTypeX.S32>;
def : InstBasic_3Op_Pat<GCN_MIN3, int_HSAIL_umin3, i32, BrigTypeX.U32>;
def : InstBasic_3Op_Pat<GCN_MIN3, int_HSAIL_fmin3, f32, BrigTypeX.F32>;

def GCN_MAX3 : HSAILInstBasic_3Op<"gcn_max3", BrigOpcode.GCNMAX3>;
def : InstBasic_3Op_Pat<GCN_MAX3, int_HSAIL_imax3, i32, BrigTypeX.S32>;
def : InstBasic_3Op_Pat<GCN_MAX3, int_HSAIL_umax3, i32, BrigTypeX.U32>;
def : InstBasic_3Op_Pat<GCN_MAX3, int_HSAIL_fmax3, f32, BrigTypeX.F32>;

def GCN_MED3 : HSAILInstBasic_3Op<"gcn_med3", BrigOpcode.GCNMED3>;
def : InstBasic_3Op_Pat<GCN_MED3, int_HSAIL_imed3, i32, BrigTypeX.S32>;
def : InstBasic_3Op_Pat<GCN_MED3, int_HSAIL_umed3, i32, BrigTypeX.U32>;
def : InstBasic_3Op_Pat<GCN_MED3, int_HSAIL_fmed3, f32, BrigTypeX.F32>;

def BITEXTRACT : HSAILInstBasic_3Op<"bitextract", BrigOpcode.BITEXTRACT>;
defm : InstBasic_3Op_IntTypes<BITEXTRACT, HSAILubitextract, 0>;
defm : InstBasic_3Op_IntTypes<BITEXTRACT, HSAILsbitextract, 1>;


def GCN_BFM : HSAILInstBasic_2Op<"gcn_bfm", BrigOpcode.GCNBFM>;
def : InstBasic_2Op_Pat<GCN_BFM, int_HSAIL_bfm,
   i32, i32, BrigTypeX.B32
>;

def GCN_QSAD : HSAILInstBasic_3Op<"gcn_qsad", BrigOpcode.GCNQSAD>;
def : InstBasic_3Op_Pat<GCN_QSAD, int_HSAIL_qsad,
   i64, BrigTypeX.B64
>;

def GCN_MQSAD : HSAILInstBasic_3Op<"gcn_mqsad", BrigOpcode.GCNMQSAD>;

def : Pat<
  (int_HSAIL_mqsad (i64 (GPROrImm i64:$src0)), i32:$src1, i64:$src2),
  (GCN_MQSAD $src0, $src1, $src2, BrigTypeX.B64)
>;


def GCN_FLDEXP : HSAILInstBasic_2Op<"gcn_fldexp", BrigOpcode.GCNFLDEXP>;
def : InstBasic_2Op_Pat<GCN_FLDEXP, HSAILfldexp, f32, i32, BrigTypeX.F32>;
def : InstBasic_2Op_Pat<GCN_FLDEXP, HSAILfldexp, f64, i32, BrigTypeX.F64>;
