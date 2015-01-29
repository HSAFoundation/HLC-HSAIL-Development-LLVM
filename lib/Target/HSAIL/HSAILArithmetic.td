
def add_inst : HSAILInstMod_2Op<"add", BrigOpcode.ADD>;
def sub_inst : HSAILInstMod_2Op<"sub", BrigOpcode.SUB>;
def mul_inst : HSAILInstMod_2Op<"mul", BrigOpcode.MUL>;
def div_inst : HSAILInstMod_2Op<"div", BrigOpcode.DIV>;
def rem_inst : HSAILInstBasic_2Op<"rem", BrigOpcode.REM>;
def mulhi_inst : HSAILInstBasic_2Op<"mulhi", BrigOpcode.MULHI>;
def abs_inst : HSAILInstMod_1Op<"abs", BrigOpcode.ABS>;

defm : InstMod_2Op_IntTypes<add_inst, add>;
defm : InstMod_2Op_FPTypes<add_inst, fadd>;
defm : InstMod_2Op_IntTypes<sub_inst, sub, 0>;
defm : InstMod_2Op_FPTypes<sub_inst, fsub>;
defm : InstMod_2Op_IntTypes<mul_inst, mul, 0>;
defm : InstMod_2Op_FPTypes<mul_inst, fmul>;

defm : InstMod_2Op_IntTypes<div_inst, udiv, 0>;
defm : InstMod_2Op_IntTypes<div_inst, sdiv, 1>;
defm : InstMod_2Op_FPTypes<div_inst, fdiv>;

// Division without implicit ftz.
def : InstMod_2Op_Pat<div_inst, int_HSAIL_div_f32, f32,
  BrigTypeX.F32, BrigRound.FLOAT_NEAR_EVEN, 0
>;

defm : InstBasic_2Op_IntTypes<rem_inst, urem, 0>;
defm : InstBasic_2Op_IntTypes<rem_inst, srem, 1>;

defm : InstBasic_2Op_IntTypes<mulhi_inst, mulhu, 0>;
defm : InstBasic_2Op_IntTypes<mulhi_inst, mulhs, 1>;


def : InstMod_1Op_Pat<abs_inst, fabs, f32, BrigTypeX.F32>;
def : InstMod_1Op_Pat<abs_inst, fabs, f64, BrigTypeX.F64>;

def mad_inst : HSAILInstBasic_3Op<"mad", BrigOpcode.MAD>;
defm : InstBasic_3Op_IntTypes<mad_inst, HSAILumad, 0>;

// u[32,64] forms illegal in HSAIL
def neg : HSAILInstBasic_1Op<"neg", BrigOpcode.NEG>;

let AddedComplexity = 2 in {
// Needs to match before sub pattern.
defm : InstBasic_1Op_IntTypes<neg, ineg, 1>;
}

defm : InstBasic_1Op_FPTypes<neg, fneg>;

def copysign_inst : HSAILInstMod_2Op<"copysign", BrigOpcode.COPYSIGN>;

// FIXME: Need to support fcopysign with different second operand type.
def : InstMod_2Op_Pat<copysign_inst, fcopysign, f32, BrigTypeX.F32, BrigRound.NONE, 0>;
def : InstMod_2Op_Pat<copysign_inst, fcopysign, f64, BrigTypeX.F64, BrigRound.NONE, 0>;


def fma_inst : HSAILInstMod_3Op<"fma", BrigOpcode.FMA>;
defm : InstMod_3Op_FPTypes<fma_inst, fma>;

def nfma_inst : HSAILInstBasic_3Op<"nfma", BrigOpcode.NFMA>;
defm : InstBasic_3Op_FPTypes<nfma_inst, HSAILnfma>;

def max_inst : HSAILInstMod_2Op<"max", BrigOpcode.MAX>;
def min_inst : HSAILInstMod_2Op<"min", BrigOpcode.MIN>;

defm : InstMod_2Op_FPTypes<max_inst, fmaxnum, BrigRound.NONE>;
defm : InstMod_2Op_FPTypes<min_inst, fminnum, BrigRound.NONE>;

defm : InstMod_2Op_IntTypes<max_inst, HSAILumax, 0>;
defm : InstMod_2Op_IntTypes<max_inst, HSAILsmax, 1>;

defm : InstMod_2Op_IntTypes<min_inst, HSAILumin, 0>;
defm : InstMod_2Op_IntTypes<min_inst, HSAILsmin, 1>;

defm gcn_max : BinaryIntrF32<int_HSAIL_gcn_max_f32, "gcn_max_f32">;
defm gcn_max : BinaryIntrF64<int_HSAIL_gcn_max_f64, "gcn_max_f64">;

defm gcn_min : BinaryIntrF32<int_HSAIL_gcn_min_f32, "gcn_min_f32">;
defm gcn_min : BinaryIntrF64<int_HSAIL_gcn_min_f64, "gcn_min_f64">;


def mul24_inst : HSAILInstBasic_2Op<"mul24", BrigOpcode.MUL24>;
def : InstBasic_2Op_Pat<mul24_inst, HSAILsmul24, i32, i32, BrigTypeX.S32>;
def : InstBasic_2Op_Pat<mul24_inst, HSAILumul24, i32, i32, BrigTypeX.U32>;


def mad24_inst : HSAILInstBasic_3Op<"mad24", BrigOpcode.MAD24>;
def : InstBasic_3Op_Pat<mad24_inst, HSAILsmad24, i32, BrigTypeX.S32>;
def : InstBasic_3Op_Pat<mad24_inst, HSAILumad24, i32, BrigTypeX.U32>;

def sqrt_inst : HSAILInstMod_1Op<"sqrt", BrigOpcode.SQRT>;
def nsqrt_inst : HSAILInstBasic_1Op<"nsqrt", BrigOpcode.NSQRT>;
def nrsqrt_inst : HSAILInstBasic_1Op<"nrsqrt", BrigOpcode.NRSQRT>;
def nrcp_inst : HSAILInstBasic_1Op<"rcp", BrigOpcode.NRCP>;

// FIXME: Having the ftz explicitly in this one is totally inconsistent
def : InstMod_1Op_Pat<sqrt_inst, int_HSAIL_sqrt_ftz_f32, f32, BrigTypeX.F32,
                      BrigRound.FLOAT_NEAR_EVEN, 1
>;

def : InstMod_1Op_Pat<sqrt_inst, int_HSAIL_sqrt_f64, f64, BrigTypeX.F64,
                      BrigRound.FLOAT_NEAR_EVEN, 0
>;

def : InstBasic_1Op_Pat<nsqrt_inst, int_HSAIL_nsqrt_f32, f32, BrigTypeX.F32>;
def : InstBasic_1Op_Pat<nsqrt_inst, int_HSAIL_nsqrt_f64, f64, BrigTypeX.F64>;

def : InstBasic_1Op_Pat<nrsqrt_inst, int_HSAIL_nrsqrt_f32, f32, BrigTypeX.F32>;
def : InstBasic_1Op_Pat<nrsqrt_inst, int_HSAIL_nrsqrt_f64, f64, BrigTypeX.F64>;

def : InstBasic_1Op_Pat<nrcp_inst, int_HSAIL_nrcp_f32, f32, BrigTypeX.F32>;
def : InstBasic_1Op_Pat<nrcp_inst, int_HSAIL_nrcp_f64, f64, BrigTypeX.F64>;


// HSAIL_SPEC_CURRENT <
def fract_inst : HSAILInstMod_1Op<"fract", BrigOpcode.FRACT>;
defm : InstMod_1Op_FPTypes<fract_inst, HSAILfract, BrigRound.NONE>;
// > HSAIL_SPEC_CURRENT

// Native Floating-Point Special Functions Operations
def nsin_inst : HSAILInstBasic_1Op<"nsin", BrigOpcode.NSIN>;
def ncos_inst : HSAILInstBasic_1Op<"ncos", BrigOpcode.NCOS>;
def nexp2_inst : HSAILInstBasic_1Op<"nexp2", BrigOpcode.NEXP2>;
def nlog2_inst : HSAILInstBasic_1Op<"nlog2", BrigOpcode.NLOG2>;

def : InstBasic_1Op_Pat<nsin_inst, int_HSAIL_nsin_f32, f32, BrigTypeX.F32>;
def : InstBasic_1Op_Pat<ncos_inst, int_HSAIL_ncos_f32, f32, BrigTypeX.F32>;
def : InstBasic_1Op_Pat<nexp2_inst, int_HSAIL_nexp2_f32, f32, BrigTypeX.F32>;
def : InstBasic_1Op_Pat<nlog2_inst, int_HSAIL_nlog2_f32, f32, BrigTypeX.F32>;


////////////////////////////////////////////////////////////////////////////////
// Logical bit ops.

def and_inst : HSAILInstBasic_2Op<"and", BrigOpcode.AND>;
def or_inst : HSAILInstBasic_2Op<"or", BrigOpcode.OR>;
def xor_inst : HSAILInstBasic_2Op<"xor", BrigOpcode.XOR>;

defm : InstBasic_2Op_BitIntTypes<and_inst, and>;
defm : InstBasic_2Op_BitIntTypes<or_inst, or>;
defm : InstBasic_2Op_BitIntTypes<xor_inst, xor>;

////////////////////////////////////////////////////////////////////////////////
// not (integer, 1-bit, 32-bit, and 64-bit)
def not_inst : HSAILInstBasic_1Op<"not", BrigOpcode.NOT>;
defm : InstBasic_1Op_BitIntTypes<not_inst, not>;

////////////////////////////////////////////////////////////////////////////////
// cvt

def cvt : InstCvt<"cvt">;

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
    (cvt 0, 0, BrigTypeX.U64, BrigTypeX.U32,
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

def popcount_inst : HSAILInstSourceType_1Op<"popcount", BrigOpcode.POPCOUNT>;

defm : InstSourceType_1Op_Pats<popcount_inst, ctpop, 1>;

////////////////////////////////////////////////////////////////////////////////
// firstbit (integer, 1-bit, 32-bit, and 64-bit)
// HSAIL_SPEC_CURRENT <

def firstbit_inst : HSAILInstSourceType_1Op<"firstbit", BrigOpcode.FIRSTBIT>;
defm : InstSourceType_1Op_Pats<firstbit_inst, ctlz>;
def : InstSourceType_1Op_Pat<firstbit_inst, int_HSAIL_firstbit_u32, i32, BrigTypeX.U32, BrigTypeX.U32>;

// > HSAIL_SPEC_CURRENT

////////////////////////////////////////////////////////////////////////////////
// lastbit (integer, 1-bit, 32-bit, and 64-bit)
// HSAIL_SPEC_CURRENT <

def lastbit_inst : HSAILInstSourceType_1Op<"lastbit", BrigOpcode.LASTBIT>;

defm : InstSourceType_1Op_Pats<lastbit_inst, cttz>;
def : InstSourceType_1Op_Pat<lastbit_inst, int_HSAIL_lastbit_u32, i32, BrigTypeX.U32, BrigTypeX.U32>;

// > HSAIL_SPEC_CURRENT

////////////////////////////////////////////////////////////////////////////////
// signbit (integer, 1-bit, 32-bit, and 64-bit)

////////////////////////////////////////////////////////////////////////////////
// shl (integer, signed and unsigned, 32-bit and 64-bit)
// shr (integer, signed and unsigned, 32-bit and 64-bit)
def shl_inst : HSAILInstBasic_2Op<"shl", BrigOpcode.SHL>;
def shr_inst : HSAILInstBasic_2Op<"shr", BrigOpcode.SHR>;

def : InstBasic_2Op_Pat<shl_inst, shl, i32, i32, BrigTypeX.U32>;
def : InstBasic_2Op_Pat<shl_inst, shl, i64, i32, BrigTypeX.U64>;

def : InstBasic_2Op_Pat<shr_inst, srl, i32, i32, BrigTypeX.U32>;
def : InstBasic_2Op_Pat<shr_inst, srl, i64, i32, BrigTypeX.U64>;

def : InstBasic_2Op_Pat<shr_inst, sra, i32, i32, BrigTypeX.S32>;
def : InstBasic_2Op_Pat<shr_inst, sra, i64, i32, BrigTypeX.S64>;

////////////////////////////////////////////////////////////////////////////////
// cmov (1-bit, 32-bit, and 64-bit; integer and float)

def cmov_inst : HSAILInstBasic_3Op<"cmov", BrigOpcode.CMOV>;

// Reduce complexity to prefer selecting various min / max patterns on
// select.
let AddedComplexity = -10 in {
  def : InstBasic_CMov_Pat<cmov_inst, i1, BrigTypeX.B1>;
  def : InstBasic_CMov_Pat<cmov_inst, i32, BrigTypeX.B32>;
  def : InstBasic_CMov_Pat<cmov_inst, f32, BrigTypeX.B32>;
  def : InstBasic_CMov_Pat<cmov_inst, i64, BrigTypeX.B64>;
  def : InstBasic_CMov_Pat<cmov_inst, f64, BrigTypeX.B64>;
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
def mov : HSAILInstBasic_1Op<"mov", BrigOpcode.MOV> {
  let isAsCheapAsAMove = 1;
  let isReMaterializable = 1;
}


// FIXME: Omitting 'node' in the output pattern results in invalid
// output with a mov using and defining the same register.
class MovImmPat<SDPatternOperator node, ValueType vt, int bt> : Pat <
  (vt node:$src0),
  (mov node:$src0, bt)
>;

class BitconvertMovPat<ValueType destvt, ValueType srcvt, int bt> : Pat <
  (destvt (bitconvert srcvt:$src0)),
  (mov $src0, bt)
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
  (add_inst 1, BrigRound.FLOAT_PLUS_INFINITY, $src0, (i32 0), BrigTypeX.F32)
>;

def bitselect_inst : HSAILInstBasic_3Op<"bitselect", BrigOpcode.BITSELECT>;
defm : InstBasic_3Op_BitIntTypes<bitselect_inst, HSAILbitselect>;

def pack_inst : HSAILInstSourceType_3Op<"pack", BrigOpcode.PACK>;

// Media - packcvt
def packcvt_inst : HSAILInstSourceType_4Op<"packcvt", BrigOpcode.PACKCVT>;

def : InstSourceType_4Op_Pat<packcvt_inst, int_HSAIL_packcvt_u8x4_f32,
   f32, BrigTypeX.U8X4, BrigTypeX.F32
>;

// Media - unpackcvt

def unpackcvt_inst : HSAILInstSourceType_2Op<"unpackcvt", BrigOpcode.UNPACKCVT>;
def : InstSourceType_2Op_Pat<unpackcvt_inst, int_HSAIL_unpackcvt_f32_u8x4,
   f32, BrigTypeX.F32, BrigTypeX.U8X4
>;

def bitalign_inst : HSAILInstBasic_3Op<"bitalign", BrigOpcode.BITALIGN>;
def bytealign_inst : HSAILInstBasic_3Op<"bytealign", BrigOpcode.BYTEALIGN>;

def : InstBasic_3Op_Pat<bitalign_inst, int_HSAIL_bitalign_b32, i32, BrigTypeX.B32>;
def : InstBasic_3Op_Pat<bytealign_inst, int_HSAIL_bytealign_b32, i32, BrigTypeX.B32>;

def lerp_inst : HSAILInstBasic_3Op<"lerp", BrigOpcode.LERP>;
def : InstBasic_3Op_Pat<lerp_inst, int_HSAIL_lerp_u8x4, i32, BrigTypeX.U8X4>;

def sad_inst : HSAILInstSourceType_3Op<"sad", BrigOpcode.SAD>;
def : InstSourceType_3Op_Pat<sad_inst, int_HSAIL_sad_u32_u8x4,
   i32, BrigTypeX.U32, BrigTypeX.U8X4
>;

def sadhi_inst : HSAILInstSourceType_3Op<"sadhi", BrigOpcode.SADHI>;
def : InstSourceType_3Op_Pat<sadhi_inst, int_HSAIL_sadhi_u16x2_u8x4,
   i32, BrigTypeX.U16X2, BrigTypeX.U8X4
>;

// media_ops2

def gcn_msad_inst : HSAILInstBasic_3Op<"gcn_msad", BrigOpcode.GCNMSAD>;
def : InstBasic_3Op_Pat<gcn_msad_inst, int_HSAIL_msad, i32, BrigTypeX.B32>;

def gcn_sadw_inst : HSAILInstBasic_3Op<"gcn_sadw", BrigOpcode.GCNSADW>;
def : InstBasic_3Op_Pat<gcn_sadw_inst, int_HSAIL_sadw, i32, BrigTypeX.B32>;

def gcn_sadd_inst : HSAILInstBasic_3Op<"gcn_sadd", BrigOpcode.GCNSADD>;
def : InstBasic_3Op_Pat<gcn_sadd_inst, int_HSAIL_sadd, i32, BrigTypeX.B32>;

def gcn_min3_inst : HSAILInstBasic_3Op<"gcn_min3", BrigOpcode.GCNMIN3>;
def : InstBasic_3Op_Pat<gcn_min3_inst, int_HSAIL_imin3, i32, BrigTypeX.S32>;
def : InstBasic_3Op_Pat<gcn_min3_inst, int_HSAIL_umin3, i32, BrigTypeX.U32>;
def : InstBasic_3Op_Pat<gcn_min3_inst, int_HSAIL_fmin3, f32, BrigTypeX.F32>;



defm media_umax3        :  TernaryIntrU32<int_HSAIL_umax3, "gcn_max3_u32">;
defm media_imax3        :  TernaryIntrS32<int_HSAIL_imax3, "gcn_max3_s32">;
defm media_f32_max3    :  TernaryIntrF32<int_HSAIL_f32_max3, "gcn_max3_f32">;
defm media_umedian3     :  TernaryIntrU32<int_HSAIL_umedian3, "gcn_med3_u32">;
defm media_imedian3     :  TernaryIntrS32<int_HSAIL_imedian3, "gcn_med3_s32">;
defm media_f32_median3 :  TernaryIntrF32<int_HSAIL_f32_median3, "gcn_med3_f32">;
defm media_bfe         :  TernaryIntrU32<int_HSAIL_bfe, "bitextract_u32">;
defm media_bfm         :  BinaryIntrU32<int_HSAIL_bfm, "gcn_bfm_b32">;
defm media_ibfe        :  TernaryIntrS32<int_HSAIL_ibfe,"bitextract_s32">;
defm media_qsad64     :   TernaryIntrU64<int_HSAIL_qsad, "gcn_qsad_b64">;

def gcn_mqsad_inst : HSAILInstBasic_3Op<"gcn_mqsad", BrigOpcode.GCNMQSAD>;

def : Pat<
  (int_HSAIL_mqsad (i64 (GPROrImm i64:$src0)), i32:$src1, i64:$src2),
  (gcn_mqsad_inst $src0, $src1, $src2, BrigTypeX.B64)
>;


def gcn_fldexp_inst : HSAILInstBasic_2Op<"gcn_fldexp", BrigOpcode.GCNFLDEXP>;
def : InstBasic_2Op_Pat<gcn_fldexp_inst, HSAILfldexp, f32, i32, BrigTypeX.F32>;
def : InstBasic_2Op_Pat<gcn_fldexp_inst, HSAILfldexp, f64, i32, BrigTypeX.F64>;
