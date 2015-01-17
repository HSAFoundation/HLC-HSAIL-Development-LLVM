////////////////////////////////////////////////////////////////////////////////
// conversion routines

//class HSAIL_Cvt<string opName, dag ins, dag outs, list<dag> pattern> :
//class HSAIL_Cvt<string opName, SDPatternOperator node> :
def cvt : HSAILInst<
    (outs unknown:$dest),
    (ins ftz:$ftz,
         BrigRound:$round,
         BrigTypeX:$destTypedestLength,
         BrigTypeX:$srcTypesrcLength,
         unknown:$src),
    "cvt$ftz$round$destTypedestLength$srcTypesrcLength\t$dest, $src",
   []
> {
  let isConv = 1;
}

class CvtPat<ValueType destvt,
             ValueType srcvt,
             int destbt,
             int srcbt,
             SDPatternOperator node,
             int roundmode = BrigRound.NONE,
             int ftz = 0> : Pat<
  (destvt (node srcvt:$src)),
  (cvt ftz, roundmode, destbt, srcbt, $src)
>;

class CvtSInt32RoundPat<ValueType srcvt,
                        int srcbt,
                        SDPatternOperator roundop,
                        int roundmode,
                        int ftz = 0> : Pat<
  (i32 (fp_to_sint (roundop srcvt:$src))),
  (cvt ftz, roundmode, BrigTypeX.S32, srcbt, $src)
>;

class UnaryFTZInst<string opName> : HSAILInst<
    (outs unknown:$dest),
    (ins ftz:$ftz, BrigTypeX:$TypeLength, unknown:$src),
    opName#"$ftz$TypeLength\t$dest, $src",
   []
>;

def rint : UnaryFTZInst<"rint"> {
  let isConv = 1;
}

def floor : UnaryFTZInst<"floor"> {
  let isConv = 1;
}

def ceil : UnaryFTZInst<"ceil"> {
  let isConv = 1;
}

// Need to call something different because trunc is already a
// standard SDNode name.
def trunc_hsail : UnaryFTZInst<"trunc"> {
  let isConv = 1;
}

class UnaryFTZPat<Instruction inst,
                  ValueType vt,
                  int bt,
                  SDPatternOperator node,
                  int ftz = 0> : Pat <
  (vt (node vt:$src)),
  (inst ftz, bt, $src)
>;


def : CvtPat<f64, i64, BrigTypeX.F64, BrigTypeX.S64, sint_to_fp, BrigRound.FLOAT_NEAR_EVEN>;
def : CvtPat<f64, i64, BrigTypeX.F64, BrigTypeX.U64, uint_to_fp, BrigRound.FLOAT_NEAR_EVEN>;
def : CvtPat<f64, i32, BrigTypeX.F64, BrigTypeX.S32, sint_to_fp, BrigRound.FLOAT_NEAR_EVEN>;
def : CvtPat<f64, i32, BrigTypeX.F64, BrigTypeX.U32, uint_to_fp, BrigRound.FLOAT_NEAR_EVEN>;
def : CvtPat<f64, i1, BrigTypeX.F64, BrigTypeX.B1, sint_to_fp, BrigRound.FLOAT_NEAR_EVEN>;
def : CvtPat<f64, i1, BrigTypeX.F64, BrigTypeX.B1, uint_to_fp, BrigRound.FLOAT_NEAR_EVEN>;

def : CvtPat<f32, i64, BrigTypeX.F32, BrigTypeX.S64, sint_to_fp, BrigRound.FLOAT_NEAR_EVEN>;
def : CvtPat<f32, i64, BrigTypeX.F32, BrigTypeX.U64, uint_to_fp, BrigRound.FLOAT_NEAR_EVEN>;
def : CvtPat<f32, i32, BrigTypeX.F32, BrigTypeX.S32, sint_to_fp, BrigRound.FLOAT_NEAR_EVEN>;
def : CvtPat<f32, i32, BrigTypeX.F32, BrigTypeX.U32, uint_to_fp, BrigRound.FLOAT_NEAR_EVEN>;
def : CvtPat<f32, i1, BrigTypeX.F32, BrigTypeX.B1, sint_to_fp, BrigRound.FLOAT_NEAR_EVEN>;
def : CvtPat<f32, i1, BrigTypeX.F32, BrigTypeX.B1, uint_to_fp, BrigRound.FLOAT_NEAR_EVEN>;

def : CvtPat<i32, f64, BrigTypeX.S32, BrigTypeX.F64, fp_to_sint, BrigRound.INTEGER_ZERO>;
def : CvtPat<i32, f64, BrigTypeX.U32, BrigTypeX.F64, fp_to_uint, BrigRound.INTEGER_ZERO>;
def : CvtPat<i64, f64, BrigTypeX.S64, BrigTypeX.F64, fp_to_sint, BrigRound.INTEGER_ZERO>;
def : CvtPat<i64, f64, BrigTypeX.U64, BrigTypeX.F64, fp_to_uint, BrigRound.INTEGER_ZERO>;

def : CvtPat<i32, f32, BrigTypeX.S32, BrigTypeX.F32, fp_to_sint, BrigRound.INTEGER_ZERO, 1>;
def : CvtPat<i32, f32, BrigTypeX.U32, BrigTypeX.F32, fp_to_uint, BrigRound.INTEGER_ZERO, 1>;
def : CvtPat<i64, f32, BrigTypeX.S64, BrigTypeX.F32, fp_to_sint, BrigRound.INTEGER_ZERO, 1>;
def : CvtPat<i64, f32, BrigTypeX.U64, BrigTypeX.F32, fp_to_uint, BrigRound.INTEGER_ZERO, 1>;

def : CvtPat<i64, i32, BrigTypeX.S64, BrigTypeX.S32, sext>;
def : CvtPat<i64, i32, BrigTypeX.U64, BrigTypeX.U32, zext>;
def : CvtPat<i64, i32, BrigTypeX.U64, BrigTypeX.U32, anyext>;

def : CvtPat<i64, i1, BrigTypeX.S64, BrigTypeX.B1, sext>;
def : CvtPat<i64, i1, BrigTypeX.U64, BrigTypeX.B1, zext>;
def : CvtPat<i64, i1, BrigTypeX.U64, BrigTypeX.B1, anyext>;

def : CvtPat<i32, i1, BrigTypeX.S32, BrigTypeX.B1, sext>;
def : CvtPat<i32, i1, BrigTypeX.U32, BrigTypeX.B1, zext>;
def : CvtPat<i32, i1, BrigTypeX.U32, BrigTypeX.B1, anyext>;

def : CvtPat<i1, i64, BrigTypeX.B1, BrigTypeX.U64, trunc>;
def : CvtPat<i1, i32, BrigTypeX.B1, BrigTypeX.U32, trunc>;
def : CvtPat<i32, i64, BrigTypeX.U32, BrigTypeX.U64, trunc>;

// ftz conversion complies our OpenCL contract wrt f64 denorms,
// because f32->f64 would not yield f64 denorms, so whether f64 is
// flushed or not does not really matter.
def : CvtPat<f64, f32, BrigTypeX.F64, BrigTypeX.F32, fextend, BrigRound.NONE, 1>;
def : CvtPat<f32, f64, BrigTypeX.F32, BrigTypeX.F64, fround, BrigRound.FLOAT_NEAR_EVEN, 1>;

def : CvtSInt32RoundPat<f64, BrigTypeX.F64, frint, BrigRound.INTEGER_NEAR_EVEN>;
def : CvtSInt32RoundPat<f64, BrigTypeX.F64, ffloor, BrigRound.INTEGER_MINUS_INFINITY>;
def : CvtSInt32RoundPat<f64, BrigTypeX.F64, fceil, BrigRound.INTEGER_PLUS_INFINITY>;
def : CvtSInt32RoundPat<f64, BrigTypeX.F64, ftrunc, BrigRound.INTEGER_ZERO>;

def : CvtSInt32RoundPat<f32, BrigTypeX.F32, frint, BrigRound.INTEGER_NEAR_EVEN, 1>;
def : CvtSInt32RoundPat<f32, BrigTypeX.F32, ffloor, BrigRound.INTEGER_MINUS_INFINITY, 1>;
def : CvtSInt32RoundPat<f32, BrigTypeX.F32, fceil, BrigRound.INTEGER_PLUS_INFINITY, 1>;
def : CvtSInt32RoundPat<f32, BrigTypeX.F32, ftrunc, BrigRound.INTEGER_ZERO, 1>;


////////////////////////////////////////////////////////////////////////////////
// support for explicit conversions

// float to int
def : CvtPat<i32, f32, BrigTypeX.S32, BrigTypeX.F32,
             int_HSAIL_cvt_s32_neari_f32,
             BrigRound.INTEGER_NEAR_EVEN, 1>;
def : CvtPat<i32, f32, BrigTypeX.S32, BrigTypeX.F32,
             int_HSAIL_cvt_s32_downi_f32,
             BrigRound.INTEGER_MINUS_INFINITY, 1>;
def : CvtPat<i32, f32, BrigTypeX.S32, BrigTypeX.F32,
             int_HSAIL_cvt_s32_upi_f32,
             BrigRound.INTEGER_PLUS_INFINITY, 1>;
def : CvtPat<i32, f32, BrigTypeX.S32, BrigTypeX.F32,
             int_HSAIL_cvt_s32_zeroi_f32,
             BrigRound.INTEGER_ZERO, 1>;

// float to uint
def : CvtPat<i32, f32, BrigTypeX.U32, BrigTypeX.F32,
             int_HSAIL_cvt_u32_neari_f32,
             BrigRound.INTEGER_NEAR_EVEN, 1>;
def : CvtPat<i32, f32, BrigTypeX.U32, BrigTypeX.F32,
             int_HSAIL_cvt_u32_downi_f32,
             BrigRound.INTEGER_MINUS_INFINITY, 1>;
def : CvtPat<i32, f32, BrigTypeX.U32, BrigTypeX.F32,
             int_HSAIL_cvt_u32_upi_f32,
             BrigRound.INTEGER_PLUS_INFINITY, 1>;
def : CvtPat<i32, f32, BrigTypeX.U32, BrigTypeX.F32,
             int_HSAIL_cvt_u32_zeroi_f32,
             BrigRound.INTEGER_ZERO, 1>;


// float to long
def : CvtPat<i64, f32, BrigTypeX.S64, BrigTypeX.F32,
             int_HSAIL_cvt_s64_neari_f32,
             BrigRound.INTEGER_NEAR_EVEN, 1>;
def : CvtPat<i64, f32, BrigTypeX.S64, BrigTypeX.F32,
             int_HSAIL_cvt_s64_downi_f32,
             BrigRound.INTEGER_MINUS_INFINITY, 1>;
def : CvtPat<i64, f32, BrigTypeX.S64, BrigTypeX.F32,
             int_HSAIL_cvt_s64_upi_f32,
             BrigRound.INTEGER_PLUS_INFINITY, 1>;
def : CvtPat<i64, f32, BrigTypeX.S64, BrigTypeX.F32,
             int_HSAIL_cvt_s64_zeroi_f32,
             BrigRound.INTEGER_ZERO, 1>;

// float to ulong
def : CvtPat<i64, f32, BrigTypeX.U64, BrigTypeX.F32,
             int_HSAIL_cvt_u64_neari_f32,
             BrigRound.INTEGER_NEAR_EVEN, 1>;
def : CvtPat<i64, f32, BrigTypeX.U64, BrigTypeX.F32,
             int_HSAIL_cvt_u64_downi_f32,
             BrigRound.INTEGER_MINUS_INFINITY, 1>;
def : CvtPat<i64, f32, BrigTypeX.U64, BrigTypeX.F32,
             int_HSAIL_cvt_u64_upi_f32,
             BrigRound.INTEGER_PLUS_INFINITY, 1>;
def : CvtPat<i64, f32, BrigTypeX.U64, BrigTypeX.F32,
             int_HSAIL_cvt_u64_zeroi_f32,
             BrigRound.INTEGER_ZERO, 1>;



// double to int
def : CvtPat<i32, f64, BrigTypeX.S32, BrigTypeX.F64,
             int_HSAIL_cvt_s32_neari_f64,
             BrigRound.INTEGER_NEAR_EVEN>;
def : CvtPat<i32, f64, BrigTypeX.S32, BrigTypeX.F64,
             int_HSAIL_cvt_s32_downi_f64,
             BrigRound.INTEGER_MINUS_INFINITY>;
def : CvtPat<i32, f64, BrigTypeX.S32, BrigTypeX.F64,
             int_HSAIL_cvt_s32_upi_f64,
             BrigRound.INTEGER_PLUS_INFINITY>;
def : CvtPat<i32, f64, BrigTypeX.S32, BrigTypeX.F64,
             int_HSAIL_cvt_s32_zeroi_f64,
             BrigRound.INTEGER_ZERO>;

// double to uint
def : CvtPat<i32, f64, BrigTypeX.U32, BrigTypeX.F64,
             int_HSAIL_cvt_u32_neari_f64,
             BrigRound.INTEGER_NEAR_EVEN>;
def : CvtPat<i32, f64, BrigTypeX.U32, BrigTypeX.F64,
             int_HSAIL_cvt_u32_downi_f64,
             BrigRound.INTEGER_MINUS_INFINITY>;
def : CvtPat<i32, f64, BrigTypeX.U32, BrigTypeX.F64,
             int_HSAIL_cvt_u32_upi_f64,
             BrigRound.INTEGER_PLUS_INFINITY>;
def : CvtPat<i32, f64, BrigTypeX.U32, BrigTypeX.F64,
             int_HSAIL_cvt_u32_zeroi_f64,
             BrigRound.INTEGER_ZERO>;


// double to long
def : CvtPat<i64, f64, BrigTypeX.S64, BrigTypeX.F64,
             int_HSAIL_cvt_s64_neari_f64,
             BrigRound.INTEGER_NEAR_EVEN>;
def : CvtPat<i64, f64, BrigTypeX.S64, BrigTypeX.F64,
             int_HSAIL_cvt_s64_downi_f64,
             BrigRound.INTEGER_MINUS_INFINITY>;
def : CvtPat<i64, f64, BrigTypeX.S64, BrigTypeX.F64,
             int_HSAIL_cvt_s64_upi_f64,
             BrigRound.INTEGER_PLUS_INFINITY>;
def : CvtPat<i64, f64, BrigTypeX.S64, BrigTypeX.F64,
             int_HSAIL_cvt_s64_zeroi_f64,
             BrigRound.INTEGER_ZERO>;

// double to ulong
def : CvtPat<i64, f64, BrigTypeX.U64, BrigTypeX.F64,
             int_HSAIL_cvt_u64_neari_f64,
             BrigRound.INTEGER_NEAR_EVEN>;
def : CvtPat<i64, f64, BrigTypeX.U64, BrigTypeX.F64,
             int_HSAIL_cvt_u64_downi_f64,
             BrigRound.INTEGER_MINUS_INFINITY>;
def : CvtPat<i64, f64, BrigTypeX.U64, BrigTypeX.F64,
             int_HSAIL_cvt_u64_upi_f64,
             BrigRound.INTEGER_PLUS_INFINITY>;
def : CvtPat<i64, f64, BrigTypeX.U64, BrigTypeX.F64,
             int_HSAIL_cvt_u64_zeroi_f64,
             BrigRound.INTEGER_ZERO>;

// half to float
def : CvtPat<f32, i32, BrigTypeX.F32, BrigTypeX.F16,
             int_HSAIL_cvt_f32_f16
>;

// float to half
def : CvtPat<f32, f32, BrigTypeX.F16, BrigTypeX.F32,
  int_HSAIL_cvt_zero_f16_f32, BrigRound.FLOAT_ZERO
>;
def : CvtPat<f32, f32, BrigTypeX.F16, BrigTypeX.F32,
  int_HSAIL_cvt_near_f16_f32, BrigRound.FLOAT_NEAR_EVEN
>;
def : CvtPat<f32, f32, BrigTypeX.F16, BrigTypeX.F32,
  int_HSAIL_cvt_down_f16_f32, BrigRound.FLOAT_MINUS_INFINITY
>;
def : CvtPat<f32, f32, BrigTypeX.F16, BrigTypeX.F32,
  int_HSAIL_cvt_up_f16_f32, BrigRound.FLOAT_PLUS_INFINITY
>;

// double to half
def : CvtPat<f32, f64, BrigTypeX.F16, BrigTypeX.F64,
  int_HSAIL_cvt_zero_f16_f64, BrigRound.FLOAT_ZERO
>;
def : CvtPat<f32, f64, BrigTypeX.F16, BrigTypeX.F64,
  int_HSAIL_cvt_near_f16_f64, BrigRound.FLOAT_NEAR_EVEN
>;
def : CvtPat<f32, f64, BrigTypeX.F16, BrigTypeX.F64,
  int_HSAIL_cvt_down_f16_f64, BrigRound.FLOAT_MINUS_INFINITY
>;
def : CvtPat<f32, f64, BrigTypeX.F16, BrigTypeX.F64,
  int_HSAIL_cvt_up_f16_f64, BrigRound.FLOAT_PLUS_INFINITY
>;

// int to float
def : CvtPat<f32, i32, BrigTypeX.F32, BrigTypeX.S32,
  int_HSAIL_cvt_f32_down_i32, BrigRound.FLOAT_MINUS_INFINITY
>;
def : CvtPat<f32, i32, BrigTypeX.F32, BrigTypeX.S32,
  int_HSAIL_cvt_f32_up_i32, BrigRound.FLOAT_PLUS_INFINITY
>;
def : CvtPat<f32, i32, BrigTypeX.F32, BrigTypeX.S32,
  int_HSAIL_cvt_f32_zero_i32, BrigRound.FLOAT_ZERO
>;

// uint to float
def : CvtPat<f32, i32, BrigTypeX.F32, BrigTypeX.U32,
  int_HSAIL_cvt_f32_down_u32, BrigRound.FLOAT_MINUS_INFINITY
>;
def : CvtPat<f32, i32, BrigTypeX.F32, BrigTypeX.U32,
  int_HSAIL_cvt_f32_up_u32, BrigRound.FLOAT_PLUS_INFINITY
>;
def : CvtPat<f32, i32, BrigTypeX.F32, BrigTypeX.U32,
  int_HSAIL_cvt_f32_zero_u32, BrigRound.FLOAT_ZERO
>;

// long to float
def : CvtPat<f32, i64, BrigTypeX.F32, BrigTypeX.S64,
  int_HSAIL_cvt_f32_down_i64, BrigRound.FLOAT_MINUS_INFINITY
>;
def : CvtPat<f32, i64, BrigTypeX.F32, BrigTypeX.S64,
  int_HSAIL_cvt_f32_up_i64, BrigRound.FLOAT_PLUS_INFINITY
>;
def : CvtPat<f32, i64, BrigTypeX.F32, BrigTypeX.S64,
  int_HSAIL_cvt_f32_zero_i64, BrigRound.FLOAT_ZERO
>;

// ulong to float
def : CvtPat<f32, i64, BrigTypeX.F32, BrigTypeX.U64,
  int_HSAIL_cvt_f32_down_u64, BrigRound.FLOAT_MINUS_INFINITY
>;
def : CvtPat<f32, i64, BrigTypeX.F32, BrigTypeX.U64,
  int_HSAIL_cvt_f32_up_u64, BrigRound.FLOAT_PLUS_INFINITY
>;
def : CvtPat<f32, i64, BrigTypeX.F32, BrigTypeX.U64,
  int_HSAIL_cvt_f32_zero_u64, BrigRound.FLOAT_ZERO
>;

// long to double
def : CvtPat<f64, i64, BrigTypeX.F64, BrigTypeX.S64,
  int_HSAIL_cvt_f64_down_i64, BrigRound.FLOAT_MINUS_INFINITY
>;
def : CvtPat<f64, i64, BrigTypeX.F64, BrigTypeX.S64,
  int_HSAIL_cvt_f64_up_i64, BrigRound.FLOAT_PLUS_INFINITY
>;
def : CvtPat<f64, i64, BrigTypeX.F64, BrigTypeX.S64,
  int_HSAIL_cvt_f64_zero_i64, BrigRound.FLOAT_ZERO
>;

// ulong to double
def : CvtPat<f64, i64, BrigTypeX.F64, BrigTypeX.U64,
  int_HSAIL_cvt_f64_down_u64, BrigRound.FLOAT_MINUS_INFINITY
>;
def : CvtPat<f64, i64, BrigTypeX.F64, BrigTypeX.U64,
  int_HSAIL_cvt_f64_up_u64, BrigRound.FLOAT_PLUS_INFINITY
>;
def : CvtPat<f64, i64, BrigTypeX.F64, BrigTypeX.U64,
  int_HSAIL_cvt_f64_zero_u64, BrigRound.FLOAT_ZERO
>;

// double to float
def : CvtPat<f32, f64, BrigTypeX.F32, BrigTypeX.F64,
  int_HSAIL_cvt_f32_down_f64, BrigRound.FLOAT_MINUS_INFINITY, 1
>;
def : CvtPat<f32, f64, BrigTypeX.F32, BrigTypeX.F64,
  int_HSAIL_cvt_f32_up_f64, BrigRound.FLOAT_PLUS_INFINITY, 1
>;
def : CvtPat<f32, f64, BrigTypeX.F32, BrigTypeX.F64,
  int_HSAIL_cvt_f32_zero_f64, BrigRound.FLOAT_ZERO, 1
>;

// 1bit => 32bit
let isConv = 1 in {
////////////////////////////////////////////////////////////////////////////////
// bitconvert

def bitcvt_f32_u32 : HSAILInst<(outs GPR32:$dest), (ins GPR32:$src),
                     "mov_b32\t$dest, $src",
                     [(set (i32 GPR32:$dest), (bitconvert (f32 GPR32:$src)))]>;

def bitcvt_f64_u64 : HSAILInst<(outs GPR64:$dest), (ins GPR64:$src),
                     "mov_b64\t$dest, $src",
                     [(set (i64 GPR64:$dest), (bitconvert (f64 GPR64:$src)))]>;

def bitcvt_u32_f32 : HSAILInst<(outs GPR32:$dest), (ins GPR32:$src),
                     "mov_b32\t$dest, $src",
                     [(set (f32 GPR32:$dest), (bitconvert (i32 GPR32:$src)))]>;

def bitcvt_u64_f64 : HSAILInst<(outs GPR64:$dest), (ins GPR64:$src),
                     "mov_b64\t$dest, $src",
                     [(set (f64 GPR64:$dest), (bitconvert (i64 GPR64:$src)))]>;
}


def : UnaryFTZPat<rint, f32, BrigTypeX.F32, frint, 1>;
def : UnaryFTZPat<rint, f64, BrigTypeX.F64, frint>;

def : UnaryFTZPat<floor, f32, BrigTypeX.F32, ffloor, 1>;
def : UnaryFTZPat<floor, f64, BrigTypeX.F64, ffloor>;

def : UnaryFTZPat<ceil, f32, BrigTypeX.F32, fceil, 1>;
def : UnaryFTZPat<ceil, f64, BrigTypeX.F64, fceil>;

def : UnaryFTZPat<trunc_hsail, f32, BrigTypeX.F32, ftrunc, 1>;
def : UnaryFTZPat<trunc_hsail, f64, BrigTypeX.F64, ftrunc>;
