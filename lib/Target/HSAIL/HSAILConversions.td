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


def rint : HSAILInst<
    (outs unknown:$dest),
    (ins ftz:$ftz, BrigTypeX:$TypeLength, unknown:$src),
    "rint$ftz$TypeLength\t$dest, $src",
   []
> {
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

// 1bit => 32bit
let isConv = 1 in {

// hsail conversion functions
def hsail_cvt_s32_neari_f64 : HSAILInst<(outs GPR32:$dest), (ins GPR64:$src),
                        "cvt_neari_s32_f64\t$dest,$src",
                        [(set (i32 GPR32:$dest), (fp_to_sint (frint GPR64:$src)))]>;

def hsail_cvt_s32_downi_f64 : HSAILInst<(outs GPR32:$dest), (ins GPR64:$src),
                        "cvt_downi_s32_f64\t$dest,$src",
                        [(set (i32 GPR32:$dest), (fp_to_sint  (int_HSAIL_floor_f64 GPR64:$src)))]>;

def hsail_cvt_s32_upi_f64 : HSAILInst<(outs GPR32:$dest), (ins GPR64:$src),
                        "cvt_upi_s32_f64\t$dest,$src",
                        [(set (i32 GPR32:$dest), (fp_to_sint  (int_HSAIL_ceil_f64 GPR64:$src)))]>;

def hsail_cvt_s32_zeroi_f64 : HSAILInst<(outs GPR32:$dest), (ins GPR64:$src),
                        "cvt_zeroi_s32_f64\t$dest,$src",
                        [(set (i32 GPR32:$dest), (fp_to_sint  (int_HSAIL_trunc_f64 GPR64:$src)))]>;

def hsail_cvt_s32_neari_f32 : HSAILInst<(outs GPR32:$dest), (ins GPR32:$src),
                        "cvt_ftz_neari_s32_f32\t$dest,$src",
                        [(set (i32 GPR32:$dest), (fp_to_sint (frint f32:$src)))]>;

def hsail_cvt_s32_downi_f32 : HSAILInst<(outs GPR32:$dest), (ins GPR32:$src),
                        "cvt_ftz_downi_s32_f32\t$dest,$src",
                        [(set (i32 GPR32:$dest), (fp_to_sint  (int_HSAIL_floor_f32 GPR32:$src)))]>;

def hsail_cvt_s32_upi_f32 : HSAILInst<(outs GPR32:$dest), (ins GPR32:$src),
                        "cvt_ftz_upi_s32_f32\t$dest,$src",
                        [(set (i32 GPR32:$dest), (fp_to_sint  (int_HSAIL_ceil_f32 GPR32:$src)))]>;

def hsail_cvt_s32_zeroi_f32 : HSAILInst<(outs GPR32:$dest), (ins GPR32:$src),
                        "cvt_ftz_zeroi_s32_f32\t$dest,$src",
                        [(set (i32 GPR32:$dest), (fp_to_sint  (int_HSAIL_trunc_f32 GPR32:$src)))]>;


////////////////////////////////////////////////////////////////////////////////
// support for explicit conversions
class ConvertIntr<Intrinsic intr, string asm,
                  RegisterClass FromRc, ValueType FromTy,
                  RegisterClass ToRc, ValueType ToTy> : HSAILInst<
  (outs ToRc:$dest), (ins FromRc:$src),
  !strconcat(asm, "\t $dest, $src"),
  [(set (ToTy ToRc:$dest), (intr (FromTy FromRc:$src)))]>;

// float to int
def cvt_s32_neari_f32 : ConvertIntr<int_HSAIL_cvt_s32_neari_f32,
                        "cvt_ftz_neari_s32_f32", GPR32, f32, GPR32, i32>;
def cvt_s32_downi_f32 : ConvertIntr<int_HSAIL_cvt_s32_downi_f32,
                        "cvt_ftz_downi_s32_f32", GPR32, f32, GPR32, i32>;
def cvt_s32_upi_f32   : ConvertIntr<int_HSAIL_cvt_s32_upi_f32,
                        "cvt_ftz_upi_s32_f32", GPR32, f32, GPR32, i32>;
def cvt_s32_zeroi_f32 : ConvertIntr<int_HSAIL_cvt_s32_zeroi_f32,
                        "cvt_ftz_zeroi_s32_f32", GPR32, f32, GPR32, i32>;

// float to unsigned int
def cvt_u32_neari_f32 : ConvertIntr<int_HSAIL_cvt_u32_neari_f32,
                        "cvt_ftz_neari_u32_f32", GPR32, f32, GPR32, i32>;
def cvt_u32_downi_f32 : ConvertIntr<int_HSAIL_cvt_u32_downi_f32,
                        "cvt_ftz_downi_u32_f32", GPR32, f32, GPR32, i32>;
def cvt_u32_upi_f32   : ConvertIntr<int_HSAIL_cvt_u32_upi_f32,
                        "cvt_ftz_upi_u32_f32", GPR32, f32, GPR32, i32>;
def cvt_u32_zeroi_f32 : ConvertIntr<int_HSAIL_cvt_u32_zeroi_f32,
                        "cvt_ftz_zeroi_u32_f32", GPR32, f32, GPR32, i32>;

 // float to long
def cvt_s64_neari_f32 : ConvertIntr<int_HSAIL_cvt_s64_neari_f32,
                        "cvt_ftz_neari_s64_f32", GPR32, f32, GPR64, i64>;
def cvt_s64_downi_f32 : ConvertIntr<int_HSAIL_cvt_s64_downi_f32,
                        "cvt_ftz_downi_s64_f32", GPR32, f32, GPR64, i64>;
def cvt_s64_upi_f32   : ConvertIntr<int_HSAIL_cvt_s64_upi_f32,
                        "cvt_ftz_upi_s64_f32", GPR32, f32, GPR64, i64>;
def cvt_s64_zeroi_f32 : ConvertIntr<int_HSAIL_cvt_s64_zeroi_f32,
                        "cvt_ftz_zeroi_s64_f32", GPR32, f32, GPR64, i64>;

// float to unsigned long
def cvt_u64_neari_f32 : ConvertIntr<int_HSAIL_cvt_u64_neari_f32,
                        "cvt_ftz_neari_u64_f32", GPR32, f32, GPR64, i64>;
def cvt_u64_downi_f32 : ConvertIntr<int_HSAIL_cvt_u64_downi_f32,
                        "cvt_ftz_downi_u64_f32", GPR32, f32, GPR64, i64>;
def cvt_u64_upi_f32   : ConvertIntr<int_HSAIL_cvt_u64_upi_f32,
                        "cvt_ftz_upi_u64_f32", GPR32, f32, GPR64, i64>;
def cvt_u64_zeroi_f32 : ConvertIntr<int_HSAIL_cvt_u64_zeroi_f32,
                        "cvt_ftz_zeroi_u64_f32", GPR32, f32, GPR64, i64>;

// double to int
def cvt_s32_neari_f64 : ConvertIntr<int_HSAIL_cvt_s32_neari_f64,
                        "cvt_neari_s32_f64", GPR64, f64, GPR32, i32>;
def cvt_s32_downi_f64 : ConvertIntr<int_HSAIL_cvt_s32_downi_f64,
                        "cvt_downi_s32_f64", GPR64, f64, GPR32, i32>;
def cvt_s32_upi_f64   : ConvertIntr<int_HSAIL_cvt_s32_upi_f64,
                        "cvt_upi_s32_f64", GPR64, f64, GPR32, i32>;
def cvt_s32_zeroi_f64 : ConvertIntr<int_HSAIL_cvt_s32_zeroi_f64,
                        "cvt_zeroi_s32_f64", GPR64, f64, GPR32, i32>;

// double to unsigned int
def cvt_u32_neari_f64 : ConvertIntr<int_HSAIL_cvt_u32_neari_f64,
                        "cvt_neari_u32_f64", GPR64, f64, GPR32, i32>;
def cvt_u32_downi_f64 : ConvertIntr<int_HSAIL_cvt_u32_downi_f64,
                        "cvt_downi_u32_f64", GPR64, f64, GPR32, i32>;
def cvt_u32_upi_f64   : ConvertIntr<int_HSAIL_cvt_u32_upi_f64,
                        "cvt_upi_u32_f64", GPR64, f64, GPR32, i32>;
def cvt_u32_zeroi_f64 : ConvertIntr<int_HSAIL_cvt_u32_zeroi_f64,
                        "cvt_zeroi_u32_f64", GPR64, f64, GPR32, i32>;

// double to long
def cvt_s64_neari_f64 : ConvertIntr<int_HSAIL_cvt_s64_neari_f64,
                        "cvt_neari_s64_f64", GPR64, f64, GPR64, i64>;
def cvt_s64_downi_f64 : ConvertIntr<int_HSAIL_cvt_s64_downi_f64,
                        "cvt_downi_s64_f64", GPR64, f64, GPR64, i64>;
def cvt_s64_upi_f64   : ConvertIntr<int_HSAIL_cvt_s64_upi_f64,
                        "cvt_upi_s64_f64", GPR64, f64, GPR64, i64>;
def cvt_s64_zeroi_f64 : ConvertIntr<int_HSAIL_cvt_s64_zeroi_f64,
                        "cvt_zeroi_s64_f64", GPR64, f64, GPR64, i64>;

// double to unsigned long
def cvt_u64_neari_f64 : ConvertIntr<int_HSAIL_cvt_u64_neari_f64,
                        "cvt_neari_u64_f64", GPR64, f64, GPR64, i64>;
def cvt_u64_downi_f64 : ConvertIntr<int_HSAIL_cvt_u64_downi_f64,
                        "cvt_downi_u64_f64", GPR64, f64, GPR64, i64>;
def cvt_u64_upi_f64   : ConvertIntr<int_HSAIL_cvt_u64_upi_f64,
                        "cvt_upi_u64_f64", GPR64, f64, GPR64, i64>;
def cvt_u64_zeroi_f64 : ConvertIntr<int_HSAIL_cvt_u64_zeroi_f64,
                        "cvt_zeroi_u64_f64", GPR64, f64, GPR64, i64>;

// half to float
def cvt_f32_f16       : ConvertIntr<int_HSAIL_cvt_f32_f16,
                        "cvt_f32_f16", GPR32, i32, GPR32, f32>;

// float to half
def cvt_zero_f16_f32  : ConvertIntr<int_HSAIL_cvt_zero_f16_f32,
                        "cvt_zero_f16_f32", GPR32, f32, GPR32, f32>;
def cvt_near_f16_f32  : ConvertIntr<int_HSAIL_cvt_near_f16_f32,
                        "cvt_near_f16_f32", GPR32, f32, GPR32, f32>;
def cvt_down_f16_f32  : ConvertIntr<int_HSAIL_cvt_down_f16_f32,
                        "cvt_down_f16_f32", GPR32, f32, GPR32, f32>;
def cvt_up_f16_f32    : ConvertIntr<int_HSAIL_cvt_up_f16_f32,
                        "cvt_up_f16_f32", GPR32, f32, GPR32, f32>;

// double to half
def cvt_zero_f16_f64  : ConvertIntr<int_HSAIL_cvt_zero_f16_f64,
                        "cvt_zero_f16_f64", GPR64, f64, GPR32, f32>;
def cvt_near_f16_f64  : ConvertIntr<int_HSAIL_cvt_near_f16_f64,
                        "cvt_near_f16_f64", GPR64, f64, GPR32, f32>;
def cvt_down_f16_f64  : ConvertIntr<int_HSAIL_cvt_down_f16_f64,
                        "cvt_down_f16_f64", GPR64, f64, GPR32, f32>;
def cvt_up_f16_f64    : ConvertIntr<int_HSAIL_cvt_up_f16_f64,
                        "cvt_up_f16_f64", GPR64, f64, GPR32, f32>;

// int to float
def cvt_down_f32_s32  : ConvertIntr<int_HSAIL_cvt_f32_down_i32,
                        "cvt_down_f32_s32", GPR32, i32, GPR32, f32>;
def cvt_up_f32_s32    : ConvertIntr<int_HSAIL_cvt_f32_up_i32,
                        "cvt_up_f32_s32", GPR32, i32, GPR32, f32>;
def cvt_zero_f32_s32  : ConvertIntr<int_HSAIL_cvt_f32_zero_i32,
                        "cvt_zero_f32_s32", GPR32, i32, GPR32, f32>;

// unsigned int to float
def cvt_down_f32_u32  : ConvertIntr<int_HSAIL_cvt_f32_down_u32,
                        "cvt_down_f32_u32", GPR32, i32, GPR32, f32>;
def cvt_up_f32_u32    : ConvertIntr<int_HSAIL_cvt_f32_up_u32,
                        "cvt_up_f32_u32", GPR32, i32, GPR32, f32>;
def cvt_zero_f32_u32  : ConvertIntr<int_HSAIL_cvt_f32_zero_u32,
                        "cvt_zero_f32_u32", GPR32, i32, GPR32, f32>;

// long to float
def cvt_down_f32_s64  : ConvertIntr<int_HSAIL_cvt_f32_down_i64,
                        "cvt_down_f32_s64", GPR64, i64, GPR32, f32>;
def cvt_up_f32_s64    : ConvertIntr<int_HSAIL_cvt_f32_up_i64,
                        "cvt_up_f32_s64", GPR64, i64, GPR32, f32>;
def cvt_zero_f32_s64  : ConvertIntr<int_HSAIL_cvt_f32_zero_i64,
                        "cvt_zero_f32_s64", GPR64, i64, GPR32, f32>;

// unsigned long to float
def cvt_down_f32_u64  : ConvertIntr<int_HSAIL_cvt_f32_down_u64,
                        "cvt_down_f32_u64", GPR64, i64, GPR32, f32>;
def cvt_up_f32_u64    : ConvertIntr<int_HSAIL_cvt_f32_up_u64,
                        "cvt_up_f32_u64", GPR64, i64, GPR32, f32>;
def cvt_zero_f32_u64  : ConvertIntr<int_HSAIL_cvt_f32_zero_u64,
                        "cvt_zero_f32_u64", GPR64, i64, GPR32, f32>;

// long to double
def cvt_down_f64_s64  : ConvertIntr<int_HSAIL_cvt_f64_down_i64,
                        "cvt_down_f64_s64", GPR64, i64, GPR64, f64>;
def cvt_up_f64_s64    : ConvertIntr<int_HSAIL_cvt_f64_up_i64,
                        "cvt_up_f64_s64", GPR64, i64, GPR64, f64>;
def cvt_zero_f64_s64  : ConvertIntr<int_HSAIL_cvt_f64_zero_i64,
                        "cvt_zero_f64_s64", GPR64, i64, GPR64, f64>;

// unsigned long to double
def cvt_down_f64_u64  : ConvertIntr<int_HSAIL_cvt_f64_down_u64,
                        "cvt_down_f64_u64", GPR64, i64, GPR64, f64>;
def cvt_up_f64_u64    : ConvertIntr<int_HSAIL_cvt_f64_up_u64,
                        "cvt_up_f64_u64", GPR64, i64, GPR64, f64>;
def cvt_zero_f64_u64  : ConvertIntr<int_HSAIL_cvt_f64_zero_u64,
                        "cvt_zero_f64_u64", GPR64, i64, GPR64, f64>;

// double to float
def cvt_down_f32_f64  : ConvertIntr<int_HSAIL_cvt_f32_down_f64,
                        "cvt_ftz_down_f32_f64", GPR64, f64, GPR32, f32>;
def cvt_up_f32_f64    : ConvertIntr<int_HSAIL_cvt_f32_up_f64,
                        "cvt_ftz_up_f32_f64", GPR64, f64, GPR32, f32>;
def cvt_zero_f32_f64  : ConvertIntr<int_HSAIL_cvt_f32_zero_f64,
                        "cvt_ftz_zero_f32_f64", GPR64, f64, GPR32, f32>;

////////////////////////////////////////////////////////////////////////////////
// rounding operations
// ceil
defm ceil   : UnaryIntrF32<int_HSAIL_ceil_f32, "ceil_ftz_f32">;
defm ceil   : UnaryIntrF64<int_HSAIL_ceil_f64, "ceil_f64">;

// floor
defm floor  : UnaryIntrF32<int_HSAIL_floor_f32, "floor_ftz_f32">;
defm floor  : UnaryIntrF64<int_HSAIL_floor_f64, "floor_f64">;

// truncate
defm trunc  : UnaryIntrF32<int_HSAIL_trunc_f32, "trunc_ftz_f32">;
defm trunc  : UnaryIntrF64<int_HSAIL_trunc_f64, "trunc_f64">;

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
