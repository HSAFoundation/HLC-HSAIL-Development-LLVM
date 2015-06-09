//===------------------------------------------------------*- tablegen -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

defm ADD : InstMod_2Op_IntTypes<"add", BrigOpcode.ADD>;
defm ADD : InstMod_2Op_FPTypes<"add", BrigOpcode.ADD>;

defm SUB : InstMod_2Op_IntTypes<"sub", BrigOpcode.SUB>;
defm SUB : InstMod_2Op_FPTypes<"sub", BrigOpcode.SUB>;

defm MUL : InstMod_2Op_IntTypes<"mul", BrigOpcode.MUL>;
defm MUL : InstMod_2Op_FPTypes<"mul", BrigOpcode.MUL>;

defm DIV : InstMod_2Op_IntTypes<"div", BrigOpcode.DIV>;
defm DIV : InstMod_2Op_FPTypes<"div", BrigOpcode.DIV>;

defm REM : InstBasic_2Op_IntTypes<"rem", BrigOpcode.REM>;

defm MULHI : InstBasic_2Op_IntTypes<"mulhi", BrigOpcode.MULHI>;

defm ABS : InstMod_1Op_SignedIntTypes<"abs", BrigOpcode.ABS>;
defm ABS : InstMod_1Op_FPTypes<"abs", BrigOpcode.ABS>;

defm : InstMod_2Op_IntTypes_Pat<"ADD", add>;
defm : InstMod_2Op_FPTypes_Pat<"ADD", fadd>;
defm : InstMod_2Op_Intrin_FPTypes_Pat<"ADD", int_hsail_fadd>;

defm : InstMod_2Op_IntTypes_Pat<"SUB", sub, 0>;
defm : InstMod_2Op_FPTypes_Pat<"SUB", fsub>;
defm : InstMod_2Op_Intrin_FPTypes_Pat<"SUB", int_hsail_fsub>;

defm : InstMod_2Op_IntTypes_Pat<"MUL", mul, 0>;
defm : InstMod_2Op_FPTypes_Pat<"MUL", fmul>;
defm : InstMod_2Op_Intrin_FPTypes_Pat<"MUL", int_hsail_fmul>;

defm : InstMod_2Op_IntTypes_Pat<"DIV", udiv, 0>;
defm : InstMod_2Op_IntTypes_Pat<"DIV", sdiv, 1>;
defm : InstMod_2Op_FPTypes_Pat<"DIV", fdiv>;
defm : InstMod_2Op_Intrin_FPTypes_Pat<"DIV", int_hsail_fdiv>;

// Division without implicit ftz.
def : InstMod_2Op_Pat<DIV_F32, int_HSAIL_div_f32, f32,
  BrigType.F32, BrigRound.FLOAT_DEFAULT, 0
>;

defm : InstBasic_2Op_IntTypes_Pat<"REM", urem, 0>;
defm : InstBasic_2Op_IntTypes_Pat<"REM", srem, 1>;

defm : InstBasic_2Op_IntTypes_Pat<"MULHI", mulhu, 0>;
defm : InstBasic_2Op_IntTypes_Pat<"MULHI", mulhs, 1>;


def : InstMod_1Op_Pat<ABS_F32, fabs, f32, BrigType.F32>;
def : InstMod_1Op_Pat<ABS_F64, fabs, f64, BrigType.F64>;

defm MAD : InstBasic_3Op_SUF<"mad", BrigOpcode.MAD>;
defm : InstBasic_3Op_IntTypes_Pat<"MAD", HSAILumad, 0>;

// u[32,64] forms illegal in HSAIL
defm NEG : InstBasic_1Op_SF<"neg", BrigOpcode.NEG>;

let AddedComplexity = 2 in {
// Needs to match before sub pattern.
defm : InstBasic_1Op_IntTypes_Pat<"NEG", ineg, 1>;
}

defm : InstBasic_1Op_FPTypes_Pat<"NEG", fneg>;

defm COPYSIGN : InstMod_2Op_FPTypes<"copysign", BrigOpcode.COPYSIGN>;

// FIXME: Need to support fcopysign with different second operand type.
def : InstMod_2Op_Pat<COPYSIGN_F32, fcopysign, f32, BrigType.F32, BrigRound.NONE, 0>;
def : InstMod_2Op_Pat<COPYSIGN_F64, fcopysign, f64, BrigType.F64, BrigRound.NONE, 0>;


defm FMA : InstMod_3Op_FPTypes<"fma", BrigOpcode.FMA>;
defm : InstMod_3Op_FPTypes_Pat<"FMA", fma>;

defm NFMA : InstBasic_3Op_FPTypes<"nfma", BrigOpcode.NFMA>;
defm : InstBasic_3Op_FPTypes_Pat<"NFMA", HSAILnfma>;

defm MAX : InstMod_2Op_SUF<"max", BrigOpcode.MAX>;
defm MIN : InstMod_2Op_SUF<"min", BrigOpcode.MIN>;

defm : InstMod_2Op_FPTypes_Pat<"MAX", fmaxnum, BrigRound.NONE>;
defm : InstMod_2Op_FPTypes_Pat<"MIN", fminnum, BrigRound.NONE>;

defm : InstMod_2Op_IntTypes_Pat<"MAX", HSAILumax, 0>;
defm : InstMod_2Op_IntTypes_Pat<"MAX", HSAILsmax, 1>;

defm : InstMod_2Op_IntTypes_Pat<"MIN", HSAILumin, 0>;
defm : InstMod_2Op_IntTypes_Pat<"MIN", HSAILsmin, 1>;

defm GCN_MAX : InstBasic_2Op_FPTypes<"gcn_max", BrigOpcode.GCNMAX>;
defm GCN_MIN : InstBasic_2Op_FPTypes<"gcn_min", BrigOpcode.GCNMIN>;

// FIXME: Remove these intrinsics
def : InstBasic_2Op_Pat<GCN_MAX_F32, int_HSAIL_gcn_max_f32, f32, f32, BrigType.F32>;
def : InstBasic_2Op_Pat<GCN_MAX_F64, int_HSAIL_gcn_max_f64, f64, f64, BrigType.F64>;
def : InstBasic_2Op_Pat<GCN_MIN_F32, int_HSAIL_gcn_min_f32, f32, f32, BrigType.F32>;
def : InstBasic_2Op_Pat<GCN_MIN_F64, int_HSAIL_gcn_min_f64, f64, f64, BrigType.F64>;


defm MUL24 : InstBasic_2Op_IntTypes<"mul24", BrigOpcode.MUL24>;
def : InstBasic_2Op_Pat<MUL24_S32, HSAILsmul24, i32, i32, BrigType.S32>;
def : InstBasic_2Op_Pat<MUL24_U32, HSAILumul24, i32, i32, BrigType.U32>;


defm MAD24 : InstBasic_3Op_IntTypes<"mad24", BrigOpcode.MAD24>;
def : InstBasic_3Op_Pat<MAD24_S32, HSAILsmad24, i32, BrigType.S32>;
def : InstBasic_3Op_Pat<MAD24_U32, HSAILumad24, i32, BrigType.U32>;

defm SQRT : InstMod_1Op_FPTypes<"sqrt", BrigOpcode.SQRT>;
defm NSQRT : InstBasic_1Op_FPTypes<"nsqrt", BrigOpcode.NSQRT>;
defm NRSQRT : InstBasic_1Op_FPTypes<"nrsqrt", BrigOpcode.NRSQRT>;
defm NRCP : InstBasic_1Op_FPTypes<"nrcp", BrigOpcode.NRCP>;

defm : InstMod_1Op_FPTypes_Intrin_Pat<"SQRT", int_hsail_fsqrt>;
defm : InstBasic_1Op_FPTypes_Pat<"NSQRT", int_hsail_nsqrt>;
defm : InstBasic_1Op_FPTypes_Pat<"NRSQRT", int_hsail_nrsqrt>;
defm : InstBasic_1Op_FPTypes_Pat<"NRCP", int_hsail_nrcp>;

defm FRACT : InstMod_1Op_FPTypes<"fract", BrigOpcode.FRACT>;
defm : InstMod_1Op_FPTypes_Pat<"FRACT", HSAILfract, BrigRound.FLOAT_DEFAULT>;

// Native Floating-Point Special Functions Operations
def NSIN_F32 : HSAILInstBasic_1Op<"nsin", BrigOpcode.NSIN, Inst_F32_F32>;
def NCOS_F32 : HSAILInstBasic_1Op<"ncos", BrigOpcode.NCOS, Inst_F32_F32>;
def NEXP2_F32 : HSAILInstBasic_1Op<"nexp2", BrigOpcode.NEXP2, Inst_F32_F32>;
def NLOG2_F32 : HSAILInstBasic_1Op<"nlog2", BrigOpcode.NLOG2, Inst_F32_F32>;

def : InstBasic_1Op_Pat<NSIN_F32, int_hsail_nsin, f32, BrigType.F32>;
def : InstBasic_1Op_Pat<NCOS_F32, int_hsail_ncos, f32, BrigType.F32>;
def : InstBasic_1Op_Pat<NEXP2_F32, int_hsail_nexp2, f32, BrigType.F32>;
def : InstBasic_1Op_Pat<NLOG2_F32, int_hsail_nlog2, f32, BrigType.F32>;

// Legacy intrinsic patterns.
def : InstBasic_1Op_Pat<NSIN_F32, int_HSAIL_nsin_f32, f32, BrigType.F32>;
def : InstBasic_1Op_Pat<NCOS_F32, int_HSAIL_ncos_f32, f32, BrigType.F32>;
def : InstBasic_1Op_Pat<NEXP2_F32, int_HSAIL_nexp2_f32, f32, BrigType.F32>;
def : InstBasic_1Op_Pat<NLOG2_F32, int_HSAIL_nlog2_f32, f32, BrigType.F32>;
def : InstBasic_1Op_Pat<NRCP_F32, int_HSAIL_nrcp_f32, f32, BrigType.F32>;
def : InstBasic_1Op_Pat<NRCP_F64, int_HSAIL_nrcp_f64, f64, BrigType.F64>;
def : InstBasic_1Op_Pat<NSQRT_F32, int_HSAIL_nsqrt_f32, f32, BrigType.F32>;
def : InstBasic_1Op_Pat<NSQRT_F64, int_HSAIL_nsqrt_f64, f64, BrigType.F64>;
def : InstBasic_1Op_Pat<NRSQRT_F32, int_HSAIL_nrsqrt_f32, f32, BrigType.F32>;
def : InstBasic_1Op_Pat<NRSQRT_F64, int_HSAIL_nrsqrt_f64, f64, BrigType.F64>;

// FIXME: Having the ftz explicitly in this one is totally inconsistent
def : InstMod_1Op_Pat<SQRT_F32, int_HSAIL_sqrt_ftz_f32, f32, BrigType.F32,
                      BrigRound.FLOAT_DEFAULT, 1
>;

def : InstMod_1Op_Pat<SQRT_F64, int_HSAIL_sqrt_f64, f64, BrigType.F64,
                      BrigRound.FLOAT_DEFAULT, 0
>;

////////////////////////////////////////////////////////////////////////////////
// Logical bit ops.

defm AND : InstBasic_2Op_BitTypes<"and", BrigOpcode.AND>;
defm OR : InstBasic_2Op_BitTypes<"or", BrigOpcode.OR>;
defm XOR : InstBasic_2Op_BitTypes<"xor", BrigOpcode.XOR>;

defm : InstBasic_2Op_BitIntTypes_Pat<"AND", and>;
defm : InstBasic_2Op_BitIntTypes_Pat<"OR", or>;
defm : InstBasic_2Op_BitIntTypes_Pat<"XOR", xor>;

////////////////////////////////////////////////////////////////////////////////
// not (integer, 1-bit, 32-bit, and 64-bit)
defm NOT : InstBasic_1Op_BitTypes<"not", BrigOpcode.NOT>;
defm : InstBasic_1Op_BitTypes_Pat<"NOT", not>;

////////////////////////////////////////////////////////////////////////////////
// cvt

defm CVT : InstCvt_DestTypes<"cvt", BrigOpcode.CVT>;

////////////////////////////////////////////////////////////////////////////////
// popcount (integer, 1-bit, 32-bit, and 64-bit)

// Patterns for integer intrinsics that match to InstSourceType. The
// LLVM intrinsics return an integer with equivalent width as the
// source, but the HSAIL instructions truncate to a 32-bit result.
multiclass InstSourceType_1Op_Pats<string inst,
                                   SDPatternOperator node,
                                   bit bit_src = 0> {
  def : Pat<
    (i64 (node i64:$src0)),
    (CVT_U64_U32 0, 0, BrigType.U64, BrigType.U32,
      (i32 (!cast<HSAILInst>(inst#!if(bit_src, "_B64", "_U64")) i64:$src0, BrigType.U32, !if(bit_src, BrigType.B64, BrigType.U64))))
  >;

  def : Pat<
    (i32 (trunc (node i64:$src0))),
    (i32 (!cast<HSAILInst>(inst#!if(bit_src, "_B64", "_U64")) i64:$src0, BrigType.U32, !if(bit_src, BrigType.B64, BrigType.U64)))
  >;

  def : Pat<
    (i32 (node i32:$src0)),
    (!cast<HSAILInst>(inst#!if(bit_src, "_B32", "_U32")) i32:$src0, BrigType.U32, !if(bit_src, BrigType.B32, BrigType.U32))
  >;
}

defm POPCOUNT : InstSourceType_1Op_U32_BitTypes<"popcount", BrigOpcode.POPCOUNT>;

defm : InstSourceType_1Op_Pats<"POPCOUNT_U32", ctpop, 1>;

////////////////////////////////////////////////////////////////////////////////
// firstbit (integer, 1-bit, 32-bit, and 64-bit)

defm FIRSTBIT : InstSourceType_1Op_U32_IntTypes<"firstbit", BrigOpcode.FIRSTBIT>;
defm : InstSourceType_1Op_Pats<"FIRSTBIT_U32", ctlz>;

def : InstSourceType_1Op_Pat<FIRSTBIT_U32_U32, int_hsail_ufirstbit, i32, i32, BrigType.U32, BrigType.U32>;
def : InstSourceType_1Op_Pat<FIRSTBIT_U32_U64, int_hsail_ufirstbit, i32, i64, BrigType.U32, BrigType.U64>;
def : InstSourceType_1Op_Pat<FIRSTBIT_U32_S32, int_hsail_sfirstbit, i32, i32, BrigType.U32, BrigType.S32>;
def : InstSourceType_1Op_Pat<FIRSTBIT_U32_S64, int_hsail_sfirstbit, i32, i64, BrigType.U32, BrigType.S64>;

def : InstSourceType_1Op_Pat<FIRSTBIT_U32_U32, int_HSAIL_firstbit_u32, i32, i32, BrigType.U32, BrigType.U32>;

////////////////////////////////////////////////////////////////////////////////
// lastbit (integer, 1-bit, 32-bit, and 64-bit)
defm LASTBIT : InstSourceType_1Op_U32_IntTypes<"lastbit", BrigOpcode.LASTBIT>;

defm : InstSourceType_1Op_Pats<"LASTBIT_U32", cttz>;

def : InstSourceType_1Op_Pat<LASTBIT_U32_U32, int_hsail_lastbit, i32, i32, BrigType.U32, BrigType.U32>;
def : InstSourceType_1Op_Pat<LASTBIT_U32_U64, int_hsail_lastbit, i32, i64, BrigType.U32, BrigType.U64>;

def : InstSourceType_1Op_Pat<LASTBIT_U32_U32, int_HSAIL_lastbit_u32, i32, i32, BrigType.U32, BrigType.U32>;

////////////////////////////////////////////////////////////////////////////////
// signbit (integer, 1-bit, 32-bit, and 64-bit)

////////////////////////////////////////////////////////////////////////////////
// shl (integer, signed and unsigned, 32-bit and 64-bit)
// shr (integer, signed and unsigned, 32-bit and 64-bit)
defm SHL : InstBasic_2Op_ShiftTypes<"shl", BrigOpcode.SHL>;
defm SHR : InstBasic_2Op_ShiftTypes<"shr", BrigOpcode.SHR>;

def : InstBasic_2Op_Pat<SHL_U32, shl, i32, i32, BrigType.U32>;
def : InstBasic_2Op_Pat<SHL_U64, shl, i64, i32, BrigType.U64>;

def : InstBasic_2Op_Pat<SHR_U32, srl, i32, i32, BrigType.U32>;
def : InstBasic_2Op_Pat<SHR_U64, srl, i64, i32, BrigType.U64>;

def : InstBasic_2Op_Pat<SHR_S32, sra, i32, i32, BrigType.S32>;
def : InstBasic_2Op_Pat<SHR_S64, sra, i64, i32, BrigType.S64>;

////////////////////////////////////////////////////////////////////////////////
// cmov (1-bit, 32-bit, and 64-bit; integer and float)

defm CMOV : InstBasic_3Op_CMov<"cmov", BrigOpcode.CMOV>;

// Reduce complexity to prefer selecting various min / max patterns on
// select.
let AddedComplexity = -10 in {
  def : InstBasic_CMov_Pat<CMOV_B1, i1, BrigType.B1>;
  def : InstBasic_CMov_Pat<CMOV_B32, i32, BrigType.B32>;
  def : InstBasic_CMov_Pat<CMOV_B64, i64, BrigType.B64>;
}

////////////////////////////////////////////////////////////////////////////////
// extract (integer, 32-bit, and 64-bit)

////////////////////////////////////////////////////////////////////////////////
// insert (integer, 32-bit, and 64-bit)

////////////////////////////////////////////////////////////////////////////////
// mov

let isAsCheapAsAMove = 1, isReMaterializable = 1 in {
  // FIXME: Spec calls TypeLength moveType for some reason, but that
  // would be painful to deal with.
  defm MOV : InstBasic_1Op_BF<"mov", BrigOpcode.MOV>;
}


// FIXME: Omitting 'node' in the output pattern results in invalid
// output with a mov using and defining the same register.
class MovImmPat<HSAILInst movInst, SDPatternOperator node, ValueType vt, int bt> : Pat <
  (vt node:$src0),
  (movInst node:$src0, bt)
>;

class BitconvertMovPat<HSAILInst movInst, ValueType destvt, ValueType srcvt, int bt> : Pat <
  (destvt (bitconvert srcvt:$src0)),
  (movInst $src0, bt)
>;


def : MovImmPat<MOV_B1, imm, i1, BrigType.B1>;
def : MovImmPat<MOV_B32, imm, i32, BrigType.B32>;
def : MovImmPat<MOV_B64, imm, i64, BrigType.B64>;
def : MovImmPat<MOV_F32, fpimm, f32, BrigType.F32>;
def : MovImmPat<MOV_F64, fpimm, f64, BrigType.F64>;

def : BitconvertMovPat<MOV_B64, f64, i64, BrigType.B64>;
def : BitconvertMovPat<MOV_B64, i64, f64, BrigType.B64>;
def : BitconvertMovPat<MOV_B32, f32, i32, BrigType.B32>;
def : BitconvertMovPat<MOV_B32, i32, f32, BrigType.B32>;


////////////////////////////////////////////////////////////////////////////////
// misc operations

defm BITSELECT : InstBasic_3Op_BitTypes<"bitselect", BrigOpcode.BITSELECT>;
defm : InstBasic_3Op_BitTypes_Pat<"BITSELECT", HSAILbitselect>;

defm PACK : InstSourceType_3Op_Pack_Types<"pack", BrigOpcode.PACK>;

// Media - packcvt
def PACKCVT_U8X4_F32 : HSAILInstSourceType_4Op<"packcvt", BrigOpcode.PACKCVT, Inst_U8X4_F32_F32_F32_F32>;

def : InstSourceType_4Op_Pat<PACKCVT_U8X4_F32, int_hsail_packcvt,
   f32, BrigType.U8X4, BrigType.F32
>;

def : InstSourceType_4Op_Pat<PACKCVT_U8X4_F32, int_HSAIL_packcvt_u8x4_f32,
   f32, BrigType.U8X4, BrigType.F32
>;

// Media - unpackcvt

// TODO: src1 must be immediate.
def UNPACKCVT_F32_U8X4 : HSAILInstSourceType_2Op<"unpackcvt", BrigOpcode.UNPACKCVT, Inst_F32_U8X4_U32>;

def : InstSourceType_2Op_Pat<UNPACKCVT_F32_U8X4, int_hsail_unpackcvt,
   f32, BrigType.F32, BrigType.U8X4
>;

def : InstSourceType_2Op_Pat<UNPACKCVT_F32_U8X4, int_HSAIL_unpackcvt_f32_u8x4,
   f32, BrigType.F32, BrigType.U8X4
>;

defm BITALIGN : InstBasic_3Op_BitTypes<"bitalign", BrigOpcode.BITALIGN>;
defm BYTEALIGN : InstBasic_3Op_BitTypes<"bytealign", BrigOpcode.BYTEALIGN>;

def : InstBasic_3Op_Pat<BITALIGN_B32, int_hsail_bitalign, i32, BrigType.B32>;
def : InstBasic_3Op_Pat<BYTEALIGN_B32, int_hsail_bytealign, i32, BrigType.B32>;

def : InstBasic_3Op_Pat<BITALIGN_B32, int_HSAIL_bitalign_b32, i32, BrigType.B32>;
def : InstBasic_3Op_Pat<BYTEALIGN_B32, int_HSAIL_bytealign_b32, i32, BrigType.B32>;

def LERP_U8X4 : HSAILInstBasic_3Op<"lerp", BrigOpcode.LERP, Inst_U8X4_U8X4_U8X4_U8X4>;

def : InstBasic_3Op_Pat<LERP_U8X4, int_hsail_lerp, i32, BrigType.U8X4>;
def : InstBasic_3Op_Pat<LERP_U8X4, int_HSAIL_lerp_u8x4, i32, BrigType.U8X4>;

defm SAD : InstSourceType_3Op_Sad_Types<"sad", BrigOpcode.SAD>;

def : InstSourceType_3Op_Pat<SAD_U32_U32, int_hsail_sad_u32_u32,
   i32, BrigType.U32, BrigType.U32
>;

def : InstSourceType_3Op_Pat<SAD_U32_U16X2, int_hsail_sad_u32_u16x2,
   i32, BrigType.U32, BrigType.U16X2
>;

def : InstSourceType_3Op_Pat<SAD_U32_U8X4, int_hsail_sad_u32_u8x4,
   i32, BrigType.U32, BrigType.U8X4
>;

def : InstSourceType_3Op_Pat<SAD_U32_U8X4, int_HSAIL_sad_u32_u8x4,
   i32, BrigType.U32, BrigType.U8X4
>;

def SADHI_U16X2_U8X4 : HSAILInstSourceType_3Op<"sadhi", BrigOpcode.SADHI, Inst_U16X2_U8X4_U8X4_U16X2>;

def : InstSourceType_3Op_Pat<SADHI_U16X2_U8X4, int_hsail_sadhi,
   i32, BrigType.U16X2, BrigType.U8X4
>;

def : InstSourceType_3Op_Pat<SADHI_U16X2_U8X4, int_HSAIL_sadhi_u16x2_u8x4,
   i32, BrigType.U16X2, BrigType.U8X4
>;

// media_ops2

def GCN_MSAD_B32 : HSAILInstBasic_3Op<"gcn_msad", BrigOpcode.GCNMSAD, Inst_B32_B32_B32_B32>;
def : InstBasic_3Op_Pat<GCN_MSAD_B32, int_hsail_gcn_msad, i32, BrigType.B32>;
def : InstBasic_3Op_Pat<GCN_MSAD_B32, int_HSAIL_msad, i32, BrigType.B32>;

def GCN_SADW_B32 : HSAILInstBasic_3Op<"gcn_sadw", BrigOpcode.GCNSADW, Inst_B32_B32_B32_B32>;
def : InstBasic_3Op_Pat<GCN_SADW_B32, int_hsail_gcn_sadw, i32, BrigType.B32>;
def : InstBasic_3Op_Pat<GCN_SADW_B32, int_HSAIL_sadw, i32, BrigType.B32>;

def GCN_SADD_B32 : HSAILInstBasic_3Op<"gcn_sadd", BrigOpcode.GCNSADD, Inst_B32_B32_B32_B32>;
def : InstBasic_3Op_Pat<GCN_SADD_B32, int_hsail_gcn_sadd, i32, BrigType.B32>;
def : InstBasic_3Op_Pat<GCN_SADD_B32, int_HSAIL_sadd, i32, BrigType.B32>;

defm GCN_MIN3 : InstBasic_3Op_SUF<"gcn_min3", BrigOpcode.GCNMIN3>;
def : InstBasic_3Op_Pat<GCN_MIN3_S32, int_HSAIL_imin3, i32, BrigType.S32>;
def : InstBasic_3Op_Pat<GCN_MIN3_U32, int_HSAIL_umin3, i32, BrigType.U32>;
def : InstBasic_3Op_Pat<GCN_MIN3_F32, int_HSAIL_fmin3, f32, BrigType.F32>;

defm GCN_MAX3 : InstBasic_3Op_SUF<"gcn_max3", BrigOpcode.GCNMAX3>;
def : InstBasic_3Op_Pat<GCN_MAX3_S32, int_HSAIL_imax3, i32, BrigType.S32>;
def : InstBasic_3Op_Pat<GCN_MAX3_U32, int_HSAIL_umax3, i32, BrigType.U32>;
def : InstBasic_3Op_Pat<GCN_MAX3_F32, int_HSAIL_fmax3, f32, BrigType.F32>;

defm GCN_MED3 : InstBasic_3Op_SUF<"gcn_med3", BrigOpcode.GCNMED3>;
def : InstBasic_3Op_Pat<GCN_MED3_S32, int_HSAIL_imed3, i32, BrigType.S32>;
def : InstBasic_3Op_Pat<GCN_MED3_U32, int_HSAIL_umed3, i32, BrigType.U32>;
def : InstBasic_3Op_Pat<GCN_MED3_F32, int_HSAIL_fmed3, f32, BrigType.F32>;

defm BITEXTRACT : InstBasic_3Op_BitExtract<"bitextract", BrigOpcode.BITEXTRACT>;
defm : InstBasic_3Op_BitExtract_IntTypes_Pat<"BITEXTRACT", HSAILubitextract, 0>;
defm : InstBasic_3Op_BitExtract_IntTypes_Pat<"BITEXTRACT", HSAILsbitextract, 1>;

defm BITINSERT : InstBasic_4Op_BitInsert<"bitinsert", BrigOpcode.BITINSERT>;
defm : InstBasic_4Op_BitInsert_IntTypes_Pat<"BITINSERT", int_hsail_sbitinsert, 1>;
defm : InstBasic_4Op_BitInsert_IntTypes_Pat<"BITINSERT", int_hsail_ubitinsert, 0>;

defm BITMASK : InstBasic_2Op_BitRetType_U32_U32<"bitmask", BrigOpcode.BITMASK>;
defm : InstBasic_2Op_BitRetType_U32_U32_Pat<"BITMASK", int_hsail_bitmask>;

defm BITREV : InstBasic_1Op_BitTypes<"bitrev", BrigOpcode.BITREV>;
defm : InstBasic_1Op_BitTypes_Pat<"BITREV", int_hsail_bitrev>;

def GCN_BFM_B32 : HSAILInstBasic_2Op<"gcn_bfm", BrigOpcode.GCNBFM, Inst_B32_B32_B32>;
def : InstBasic_2Op_Pat<GCN_BFM_B32, int_hsail_gcn_bfm,
   i32, i32, BrigType.B32
>;
def : InstBasic_2Op_Pat<GCN_BFM_B32, int_HSAIL_bfm,
   i32, i32, BrigType.B32
>;

def GCN_QSAD_B64 : HSAILInstBasic_3Op<"gcn_qsad", BrigOpcode.GCNQSAD, Inst_B64_B64_B64_B64>;
def : InstBasic_3Op_Pat<GCN_QSAD_B64, int_hsail_gcn_qsad,
   i64, BrigType.B64
>;
def : InstBasic_3Op_Pat<GCN_QSAD_B64, int_HSAIL_qsad,
   i64, BrigType.B64
>;

def GCN_MQSAD : HSAILInstBasic_3Op<"gcn_mqsad", BrigOpcode.GCNMQSAD, Inst_B64_B64_B32_B64>;

def : Pat<
  (int_HSAIL_mqsad (i64 (GPROrImm i64:$src0)), i32:$src1, i64:$src2),
  (GCN_MQSAD $src0, $src1, $src2, BrigType.B64)
>;

def : Pat<
  (int_hsail_gcn_mqsad (i64 (GPROrImm i64:$src0)), i32:$src1, i64:$src2),
  (GCN_MQSAD $src0, $src1, $src2, BrigType.B64)
>;


defm GCN_FLDEXP : InstBasic_2Op_LdExp<"gcn_fldexp", BrigOpcode.GCNFLDEXP>;
def : InstBasic_2Op_Pat<GCN_FLDEXP_F32, HSAILfldexp, f32, i32, BrigType.F32>;
def : InstBasic_2Op_Pat<GCN_FLDEXP_F64, HSAILfldexp, f64, i32, BrigType.F64>;
