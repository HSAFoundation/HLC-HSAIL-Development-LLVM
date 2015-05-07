//===------------------------------------------------------*- tablegen -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

////////////////////////////////////////////////////////////////////////////////
// conversion routines


class CvtPat<BRIGType destTy,
             BRIGType srcTy,
             SDPatternOperator node,
             int roundmode = BrigRound.NONE,
             int ftz = 0> : Pat<
  (destTy.VT (node srcTy.VT:$src)),
  (!cast<HSAILInst>("CVT"#destTy.InstName#srcTy.InstName) ftz, roundmode, destTy.BT, srcTy.BT, $src)
>;

class CvtSInt32RoundPat<BRIGType srcTy,
                        SDPatternOperator roundop,
                        int roundmode,
                        int ftz = 0> : Pat<
  (i32 (fp_to_sint (roundop srcTy.VT:$src))),
  (!cast<HSAILInst>("CVT_S32"#srcTy.InstName) ftz, roundmode, BrigType.S32, srcTy.BT, $src)
>;

let isConv = 1 in {
  defm RINT : InstMod_1Op_FPTypes<"rint", BrigOpcode.RINT>;
  defm FLOOR : InstMod_1Op_FPTypes<"floor", BrigOpcode.FLOOR>;
  defm CEIL : InstMod_1Op_FPTypes<"ceil", BrigOpcode.CEIL>;
  defm TRUNC : InstMod_1Op_FPTypes<"trunc", BrigOpcode.TRUNC>;
}


def : CvtPat<F64Ty, S64Ty, sint_to_fp, BrigRound.FLOAT_DEFAULT>;
def : CvtPat<F64Ty, U64Ty, uint_to_fp, BrigRound.FLOAT_DEFAULT>;
def : CvtPat<F64Ty, S32Ty, sint_to_fp, BrigRound.FLOAT_DEFAULT>;
def : CvtPat<F64Ty, U32Ty, uint_to_fp, BrigRound.FLOAT_DEFAULT>;
//def : CvtPat<F64Ty, B1Ty, sint_to_fp, BrigRound.FLOAT_DEFAULT>; // FIXME
def : CvtPat<F64Ty, B1Ty, uint_to_fp, BrigRound.FLOAT_DEFAULT>;

def : CvtPat<F32Ty, S64Ty, sint_to_fp, BrigRound.FLOAT_DEFAULT>;
def : CvtPat<F32Ty, U64Ty, uint_to_fp, BrigRound.FLOAT_DEFAULT>;
def : CvtPat<F32Ty, S32Ty, sint_to_fp, BrigRound.FLOAT_DEFAULT>;
def : CvtPat<F32Ty, U32Ty, uint_to_fp, BrigRound.FLOAT_DEFAULT>;
//def : CvtPat<F32Ty, B1Ty, sint_to_fp, BrigRound.FLOAT_DEFAULT>; // FIXME
def : CvtPat<F32Ty, B1Ty, uint_to_fp, BrigRound.FLOAT_DEFAULT>;

def : CvtPat<S32Ty, F64Ty, fp_to_sint, BrigRound.INTEGER_ZERO>;
def : CvtPat<U32Ty, F64Ty, fp_to_uint, BrigRound.INTEGER_ZERO>;
def : CvtPat<S64Ty, F64Ty, fp_to_sint, BrigRound.INTEGER_ZERO>;
def : CvtPat<U64Ty, F64Ty, fp_to_uint, BrigRound.INTEGER_ZERO>;

def : CvtPat<S32Ty, F32Ty, fp_to_sint, BrigRound.INTEGER_ZERO, 1>;
def : CvtPat<U32Ty, F32Ty, fp_to_uint, BrigRound.INTEGER_ZERO, 1>;
def : CvtPat<S64Ty, F32Ty, fp_to_sint, BrigRound.INTEGER_ZERO, 1>;
def : CvtPat<U64Ty, F32Ty, fp_to_uint, BrigRound.INTEGER_ZERO, 1>;

def : CvtPat<S64Ty, S32Ty, sext>;
def : CvtPat<U64Ty, U32Ty, zext>;
def : CvtPat<U64Ty, U32Ty, anyext>;

def : CvtPat<S64Ty, B1Ty, sext>;
def : CvtPat<U64Ty, B1Ty, zext>;
def : CvtPat<U64Ty, B1Ty, anyext>;

def : CvtPat<S32Ty, B1Ty, sext>;
def : CvtPat<U32Ty, B1Ty, zext>;
def : CvtPat<U32Ty, B1Ty, anyext>;

def : CvtPat<B1Ty, U64Ty, trunc>;
def : CvtPat<B1Ty, U32Ty, trunc>;
def : CvtPat<U32Ty, U64Ty, trunc>;

// ftz conversion complies our OpenCL contract wrt f64 denorms,
// because f32->f64 would not yield f64 denorms, so whether f64 is
// flushed or not does not really matter.
def : CvtPat<F64Ty, F32Ty, fextend, BrigRound.NONE, 1>;
def : CvtPat<F32Ty, F64Ty, fround, BrigRound.FLOAT_DEFAULT, 1>;

def : CvtSInt32RoundPat<F64Ty, frint, BrigRound.INTEGER_NEAR_EVEN>;
def : CvtSInt32RoundPat<F64Ty, ffloor, BrigRound.INTEGER_MINUS_INFINITY>;
def : CvtSInt32RoundPat<F64Ty, fceil, BrigRound.INTEGER_PLUS_INFINITY>;
def : CvtSInt32RoundPat<F64Ty, ftrunc, BrigRound.INTEGER_ZERO>;

def : CvtSInt32RoundPat<F32Ty, frint, BrigRound.INTEGER_NEAR_EVEN, 1>;
def : CvtSInt32RoundPat<F32Ty, ffloor, BrigRound.INTEGER_MINUS_INFINITY, 1>;
def : CvtSInt32RoundPat<F32Ty, fceil, BrigRound.INTEGER_PLUS_INFINITY, 1>;
def : CvtSInt32RoundPat<F32Ty, ftrunc, BrigRound.INTEGER_ZERO, 1>;


////////////////////////////////////////////////////////////////////////////////
// support for explicit conversions

// float to int
def : CvtPat<S32Ty, F32Ty,
             int_HSAIL_cvt_s32_neari_f32,
             BrigRound.INTEGER_NEAR_EVEN, 1>;
def : CvtPat<S32Ty, F32Ty,
             int_HSAIL_cvt_s32_downi_f32,
             BrigRound.INTEGER_MINUS_INFINITY, 1>;
def : CvtPat<S32Ty, F32Ty,
             int_HSAIL_cvt_s32_upi_f32,
             BrigRound.INTEGER_PLUS_INFINITY, 1>;
def : CvtPat<S32Ty, F32Ty,
             int_HSAIL_cvt_s32_zeroi_f32,
             BrigRound.INTEGER_ZERO, 1>;

// float to uint
def : CvtPat<U32Ty, F32Ty,
             int_HSAIL_cvt_u32_neari_f32,
             BrigRound.INTEGER_NEAR_EVEN, 1>;
def : CvtPat<U32Ty, F32Ty,
             int_HSAIL_cvt_u32_downi_f32,
             BrigRound.INTEGER_MINUS_INFINITY, 1>;
def : CvtPat<U32Ty, F32Ty,
             int_HSAIL_cvt_u32_upi_f32,
             BrigRound.INTEGER_PLUS_INFINITY, 1>;
def : CvtPat<U32Ty, F32Ty,
             int_HSAIL_cvt_u32_zeroi_f32,
             BrigRound.INTEGER_ZERO, 1>;


// float to long
def : CvtPat<S64Ty, F32Ty,
             int_HSAIL_cvt_s64_neari_f32,
             BrigRound.INTEGER_NEAR_EVEN, 1>;
def : CvtPat<S64Ty, F32Ty,
             int_HSAIL_cvt_s64_downi_f32,
             BrigRound.INTEGER_MINUS_INFINITY, 1>;
def : CvtPat<S64Ty, F32Ty,
             int_HSAIL_cvt_s64_upi_f32,
             BrigRound.INTEGER_PLUS_INFINITY, 1>;
def : CvtPat<S64Ty, F32Ty,
             int_HSAIL_cvt_s64_zeroi_f32,
             BrigRound.INTEGER_ZERO, 1>;

// float to ulong
def : CvtPat<U64Ty, F32Ty,
             int_HSAIL_cvt_u64_neari_f32,
             BrigRound.INTEGER_NEAR_EVEN, 1>;
def : CvtPat<U64Ty, F32Ty,
             int_HSAIL_cvt_u64_downi_f32,
             BrigRound.INTEGER_MINUS_INFINITY, 1>;
def : CvtPat<U64Ty, F32Ty,
             int_HSAIL_cvt_u64_upi_f32,
             BrigRound.INTEGER_PLUS_INFINITY, 1>;
def : CvtPat<U64Ty, F32Ty,
             int_HSAIL_cvt_u64_zeroi_f32,
             BrigRound.INTEGER_ZERO, 1>;



// double to int
def : CvtPat<S32Ty, F64Ty,
             int_HSAIL_cvt_s32_neari_f64,
             BrigRound.INTEGER_NEAR_EVEN>;
def : CvtPat<S32Ty, F64Ty,
             int_HSAIL_cvt_s32_downi_f64,
             BrigRound.INTEGER_MINUS_INFINITY>;
def : CvtPat<S32Ty, F64Ty,
             int_HSAIL_cvt_s32_upi_f64,
             BrigRound.INTEGER_PLUS_INFINITY>;
def : CvtPat<S32Ty, F64Ty,
             int_HSAIL_cvt_s32_zeroi_f64,
             BrigRound.INTEGER_ZERO>;

// double to uint
def : CvtPat<U32Ty, F64Ty,
             int_HSAIL_cvt_u32_neari_f64,
             BrigRound.INTEGER_NEAR_EVEN>;
def : CvtPat<U32Ty, F64Ty,
             int_HSAIL_cvt_u32_downi_f64,
             BrigRound.INTEGER_MINUS_INFINITY>;
def : CvtPat<U32Ty, F64Ty,
             int_HSAIL_cvt_u32_upi_f64,
             BrigRound.INTEGER_PLUS_INFINITY>;
def : CvtPat<U32Ty, F64Ty,
             int_HSAIL_cvt_u32_zeroi_f64,
             BrigRound.INTEGER_ZERO>;


// double to long
def : CvtPat<S64Ty, F64Ty,
             int_HSAIL_cvt_s64_neari_f64,
             BrigRound.INTEGER_NEAR_EVEN>;
def : CvtPat<S64Ty, F64Ty,
             int_HSAIL_cvt_s64_downi_f64,
             BrigRound.INTEGER_MINUS_INFINITY>;
def : CvtPat<S64Ty, F64Ty,
             int_HSAIL_cvt_s64_upi_f64,
             BrigRound.INTEGER_PLUS_INFINITY>;
def : CvtPat<S64Ty, F64Ty,
             int_HSAIL_cvt_s64_zeroi_f64,
             BrigRound.INTEGER_ZERO>;

// double to ulong
def : CvtPat<U64Ty, F64Ty,
             int_HSAIL_cvt_u64_neari_f64,
             BrigRound.INTEGER_NEAR_EVEN>;
def : CvtPat<U64Ty, F64Ty,
             int_HSAIL_cvt_u64_downi_f64,
             BrigRound.INTEGER_MINUS_INFINITY>;
def : CvtPat<U64Ty, F64Ty,
             int_HSAIL_cvt_u64_upi_f64,
             BrigRound.INTEGER_PLUS_INFINITY>;
def : CvtPat<U64Ty, F64Ty,
             int_HSAIL_cvt_u64_zeroi_f64,
             BrigRound.INTEGER_ZERO>;

// half to float
def : CvtPat<F32Ty, F16Ty_i32,
             int_HSAIL_cvt_f32_f16
>;

// float to half
def : CvtPat<F16Ty_f32, F32Ty,
  int_HSAIL_cvt_zero_f16_f32, BrigRound.FLOAT_ZERO
>;
def : CvtPat<F16Ty_f32, F32Ty,
  int_HSAIL_cvt_near_f16_f32, BrigRound.FLOAT_DEFAULT
>;
def : CvtPat<F16Ty_f32, F32Ty,
  int_HSAIL_cvt_down_f16_f32, BrigRound.FLOAT_MINUS_INFINITY
>;
def : CvtPat<F16Ty_f32, F32Ty,
  int_HSAIL_cvt_up_f16_f32, BrigRound.FLOAT_PLUS_INFINITY
>;

// double to half
def : CvtPat<F16Ty_f32, F64Ty,
  int_HSAIL_cvt_zero_f16_f64, BrigRound.FLOAT_ZERO
>;
def : CvtPat<F16Ty_f32, F64Ty,
  int_HSAIL_cvt_near_f16_f64, BrigRound.FLOAT_DEFAULT
>;
def : CvtPat<F16Ty_f32, F64Ty,
  int_HSAIL_cvt_down_f16_f64, BrigRound.FLOAT_MINUS_INFINITY
>;
def : CvtPat<F16Ty_f32, F64Ty,
  int_HSAIL_cvt_up_f16_f64, BrigRound.FLOAT_PLUS_INFINITY
>;

// int to float
def : CvtPat<F32Ty, S32Ty,
  int_HSAIL_cvt_f32_down_i32, BrigRound.FLOAT_MINUS_INFINITY
>;
def : CvtPat<F32Ty, S32Ty,
  int_HSAIL_cvt_f32_up_i32, BrigRound.FLOAT_PLUS_INFINITY
>;
def : CvtPat<F32Ty, S32Ty,
  int_HSAIL_cvt_f32_zero_i32, BrigRound.FLOAT_ZERO
>;

// uint to float
def : CvtPat<F32Ty, U32Ty,
  int_HSAIL_cvt_f32_down_u32, BrigRound.FLOAT_MINUS_INFINITY
>;
def : CvtPat<F32Ty, U32Ty,
  int_HSAIL_cvt_f32_up_u32, BrigRound.FLOAT_PLUS_INFINITY
>;
def : CvtPat<F32Ty, U32Ty,
  int_HSAIL_cvt_f32_zero_u32, BrigRound.FLOAT_ZERO
>;

// long to float
def : CvtPat<F32Ty, S64Ty,
  int_HSAIL_cvt_f32_down_i64, BrigRound.FLOAT_MINUS_INFINITY
>;
def : CvtPat<F32Ty, S64Ty,
  int_HSAIL_cvt_f32_up_i64, BrigRound.FLOAT_PLUS_INFINITY
>;
def : CvtPat<F32Ty, S64Ty,
  int_HSAIL_cvt_f32_zero_i64, BrigRound.FLOAT_ZERO
>;

// ulong to float
def : CvtPat<F32Ty, U64Ty,
  int_HSAIL_cvt_f32_down_u64, BrigRound.FLOAT_MINUS_INFINITY
>;
def : CvtPat<F32Ty, U64Ty,
  int_HSAIL_cvt_f32_up_u64, BrigRound.FLOAT_PLUS_INFINITY
>;
def : CvtPat<F32Ty, U64Ty,
  int_HSAIL_cvt_f32_zero_u64, BrigRound.FLOAT_ZERO
>;

// long to double
def : CvtPat<F64Ty, S64Ty,
  int_HSAIL_cvt_f64_down_i64, BrigRound.FLOAT_MINUS_INFINITY
>;
def : CvtPat<F64Ty, S64Ty,
  int_HSAIL_cvt_f64_up_i64, BrigRound.FLOAT_PLUS_INFINITY
>;
def : CvtPat<F64Ty, S64Ty,
  int_HSAIL_cvt_f64_zero_i64, BrigRound.FLOAT_ZERO
>;

// ulong to double
def : CvtPat<F64Ty, U64Ty,
  int_HSAIL_cvt_f64_down_u64, BrigRound.FLOAT_MINUS_INFINITY
>;
def : CvtPat<F64Ty, U64Ty,
  int_HSAIL_cvt_f64_up_u64, BrigRound.FLOAT_PLUS_INFINITY
>;
def : CvtPat<F64Ty, U64Ty,
  int_HSAIL_cvt_f64_zero_u64, BrigRound.FLOAT_ZERO
>;

// double to float
def : CvtPat<F32Ty, F64Ty,
  int_HSAIL_cvt_f32_down_f64, BrigRound.FLOAT_MINUS_INFINITY, 1
>;
def : CvtPat<F32Ty, F64Ty,
  int_HSAIL_cvt_f32_up_f64, BrigRound.FLOAT_PLUS_INFINITY, 1
>;
def : CvtPat<F32Ty, F64Ty,
  int_HSAIL_cvt_f32_zero_f64, BrigRound.FLOAT_ZERO, 1
>;

def : InstMod_1Op_Pat<RINT_F32, frint, f32, BrigType.F32, BrigRound.NONE, 1>;
def : InstMod_1Op_Pat<RINT_F64, frint, f64, BrigType.F64>;

def : InstMod_1Op_Pat<FLOOR_F32, ffloor, f32, BrigType.F32, BrigRound.NONE, 1>;
def : InstMod_1Op_Pat<FLOOR_F64, ffloor, f64, BrigType.F64>;

def : InstMod_1Op_Pat<CEIL_F32, fceil, f32, BrigType.F32, BrigRound.NONE, 1>;
def : InstMod_1Op_Pat<CEIL_F64, fceil, f64, BrigType.F64>;

def : InstMod_1Op_Pat<TRUNC_F32, ftrunc, f32, BrigType.F32, BrigRound.NONE, 1>;
def : InstMod_1Op_Pat<TRUNC_F64, ftrunc, f64, BrigType.F64>;
