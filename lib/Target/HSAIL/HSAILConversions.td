////////////////////////////////////////////////////////////////////////////////
// conversion routines
// 1bit => 32bit
let isConv = 1 in {
def cvt_b1_u32 : HSAILInst<(outs GPR32:$dst), (ins CR:$src),
                 "cvt_u32_b1\t$dst, $src",
                 [(set (i32 GPR32:$dst),
                       (zext (i1 CR:$src)))]>;

def cvt_b1_u32_a : HSAILInst<(outs GPR32:$dst), (ins CR:$src),
                 "cvt_u32_b1\t$dst, $src",
                 [(set (i32 GPR32:$dst),
                       (anyext (i1 CR:$src)))]>;

def sext_cmov_s32_b1 : HSAILInst<(outs GPR32:$dst), (ins CR:$src),
                 "cmov_b32\t$dst, $src, -1, 0",
                 [(set (i32 GPR32:$dst),
                       (sext (i1 CR:$src)))]>;

// 1bit => 64bit
def cvt_b1_u64 : HSAILInst<(outs GPR64:$dst), (ins CR:$src),
                 "cvt_u64_b1\t$dst, $src",
                 [(set (i64 GPR64:$dst),
                       (zext (i1 CR:$src)))]>;

def sext_cmov_s64_b1 : HSAILInst<(outs GPR64:$dst), (ins CR:$src),
                "cmov_b64\t$dst, $src, -1, 0",
                 [(set (i64 GPR64:$dst),
                       (sext (i1 CR:$src)))]>;

// 32bit => 64bit
def cvt_u32_u64 : HSAILInst<(outs GPR64:$dst), (ins GPR32:$src),
                  "cvt_u64_u32\t$dst, $src",
                  [(set (i64 GPR64:$dst),
                      (zext (i32 GPR32:$src)))]>;

def cvt_u32_u64_a : HSAILInst<(outs GPR64:$dst), (ins GPR32:$src),
                  "cvt_u64_u32\t$dst, $src",
                  [(set (i64 GPR64:$dst),
                      (anyext (i32 GPR32:$src)))]>;

def cvt_s32_s64 : HSAILInst<(outs GPR64:$dst), (ins GPR32:$src),
                  "cvt_s64_s32\t$dst, $src",
                  [(set (i64 GPR64:$dst),
                      (sext (i32 GPR32:$src)))]>;
// 32bit => 1bit
def cvt_u32_b1  : HSAILInst<(outs CR:$dst), (ins GPR32:$src),
                  "cvt_b1_u32\t$dst, $src",
                  [(set (i1 CR:$dst),
                      (trunc (i32 GPR32:$src)))]>;

// 64bit => 32bit
def cvt_u64_u32 : HSAILInst<(outs GPR32:$dst), (ins GPR64:$src),
                  "cvt_u32_u64\t$dst, $src",
                  [(set (i32 GPR32:$dst),
                      (trunc (i64 GPR64:$src)))]>;

// 64bit => 1bit
def cvt_u64_b1  : HSAILInst<(outs CR:$dst), (ins GPR64:$src),
                  "cvt_b1_u64\t$dst, $src",
                  [(set (i1 CR:$dst),
                      (trunc (i64 GPR64:$src)))]>;

// f32 => [s|u]32
def cvt_f32_u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
                 "cvt_ftz_zeroi_u32_f32\t$dst, $src",
                 [(set (i32 GPR32:$dst),
                     (fp_to_uint (f32 GPR32:$src)))]>;

def cvt_f32_s32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
                 "cvt_ftz_zeroi_s32_f32\t$dst, $src",
                 [(set (i32 GPR32:$dst),
                     (fp_to_sint (f32 GPR32:$src)))]>;

// f64 => [s|u]32
def cvt_f64_u32 : HSAILInst<(outs GPR32:$dst), (ins GPR64:$src),
                 "cvt_zeroi_u32_f64\t$dst, $src",
                 [(set (i32 GPR32:$dst),
                     (fp_to_uint (f64 GPR64:$src)))]>;

def cvt_f64_s32 : HSAILInst<(outs GPR32:$dst), (ins GPR64:$src),
                 "cvt_zeroi_s32_f64\t$dst, $src",
                 [(set (i32 GPR32:$dst),
                     (fp_to_sint (f64 GPR64:$src)))]>;

// [s|u]32 => f32

def cvt_b1_f32 : HSAILInst<(outs GPR32:$dst), (ins CR:$src),
                 "cvt_f32_b1\t$dst, $src",
                 [(set (f32 GPR32:$dst),
                     (uint_to_fp (i1 CR:$src)))]>;

def cvt_u32_f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
                 "cvt_near_f32_u32\t$dst, $src",
                 [(set (f32 GPR32:$dst),
                     (uint_to_fp (i32 GPR32:$src)))]>;

def cvt_s32_f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
                 "cvt_near_f32_s32\t$dst, $src",
                 [(set (f32 GPR32:$dst),
                     (sint_to_fp (i32 GPR32:$src)))]>;

// [s|u]32 => f64
def cvt_u32_f64 : HSAILInst<(outs GPR64:$dst), (ins GPR32:$src),
                 "cvt_near_f64_u32\t$dst, $src",
                 [(set (f64 GPR64:$dst),
                     (uint_to_fp (i32 GPR32:$src)))]>;

def cvt_s32_f64 : HSAILInst<(outs GPR64:$dst), (ins GPR32:$src),
                 "cvt_near_f64_s32\t$dst, $src",
                 [(set (f64 GPR64:$dst),
                     (sint_to_fp (i32 GPR32:$src)))]>;

// f32 => f64
// ftz conversion complies our OpenCL contract wrt f64 denorms, 
// because f32->f64 would not yield f64 denorms, so whether f64 is 
// flushed or not does not really matter.
def cvt_f32_f64 : HSAILInst<(outs GPR64:$dst), (ins GPR32:$src),
                 "cvt_ftz_f64_f32\t$dst, $src",
                 [(set (f64 GPR64:$dst),
                     (fextend (f32 GPR32:$src)))]>;


// f64 => [s|u]64
def cvt_f64_u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
                 "cvt_zeroi_u64_f64\t$dst, $src",
                 [(set (i64 GPR64:$dst),
                     (fp_to_uint (f64 GPR64:$src)))]>;

def cvt_f64_s64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
                 "cvt_zeroi_s64_f64\t$dst, $src",
                 [(set (i64 GPR64:$dst),
                     (fp_to_sint (f64 GPR64:$src)))]>;

// [s|u]64 => f64
def cvt_u64_f64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
                 "cvt_near_f64_u64\t$dst, $src",
                 [(set (f64 GPR64:$dst),
                     (uint_to_fp (i64 GPR64:$src)))]>;

def cvt_s64_f64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
                 "cvt_near_f64_s64\t$dst, $src",
                 [(set (f64 GPR64:$dst),
                     (sint_to_fp (i64 GPR64:$src)))]>;

// f32 => [s|u]64
def cvt_f32_u64 : HSAILInst<(outs GPR64:$dst), (ins GPR32:$src),
                 "cvt_ftz_zeroi_u64_f32\t$dst, $src",
                 [(set (i64 GPR64:$dst),
                     (fp_to_uint (f32 GPR32:$src)))]>;

def cvt_f32_s64 : HSAILInst<(outs GPR64:$dst), (ins GPR32:$src),
                 "cvt_ftz_zeroi_s64_f32\t$dst, $src",
                 [(set (i64 GPR64:$dst),
                     (fp_to_sint (f32 GPR32:$src)))]>;

// [s|u]64 => f32
def cvt_u64_f32 : HSAILInst<(outs GPR32:$dst), (ins GPR64:$src),
                 "cvt_near_f32_u64\t$dst, $src",
                 [(set (f32 GPR32:$dst),
                     (uint_to_fp (i64 GPR64:$src)))]>;

def cvt_s64_f32 : HSAILInst<(outs GPR32:$dst), (ins GPR64:$src),
                 "cvt_near_f32_s64\t$dst, $src",
                 [(set (f32 GPR32:$dst),
                     (sint_to_fp (i64 GPR64:$src)))]>;

// f64 => f32
def cvt_f64_f32 : HSAILInst<(outs GPR32:$dst), (ins GPR64:$src),
                 "cvt_ftz_near_f32_f64\t$dst, $src",
                 [(set (f32 GPR32:$dst),
                     (fround (f64 GPR64:$src)))]>;

// truncate u32/u64 to 1 bit
def trunc_b1_u32  : HSAILInst<(outs CR:$dst), (ins GPR32:$src),
                    "cvt_b1_u32\t$dst, $src",
                    [(set (i1 CR:$dst),
                      (IL_trunc_b1 (i32 GPR32:$src)))]>;

def trunc_b1_u64  : HSAILInst<(outs CR:$dst), (ins GPR64:$src),
                    "cvt_b1_u64\t$dst, $src",
                    [(set (i1 CR:$dst),
                      (IL_trunc_b1 (i64 GPR64:$src)))]>;

// hsail conversion functions
def hsail_cvt_s32_neari_f64 : HSAILInst<(outs GPR32:$dst), (ins GPR64:$src),
                        "cvt_neari_s32_f64\t$dst,$src",
                        [(set (i32 GPR32:$dst), (fp_to_sint  (int_HSAIL_rnd_f64 GPR64:$src)))]>;

def hsail_cvt_s32_downi_f64 : HSAILInst<(outs GPR32:$dst), (ins GPR64:$src),
                        "cvt_downi_s32_f64\t$dst,$src",
                        [(set (i32 GPR32:$dst), (fp_to_sint  (int_HSAIL_floor_f64 GPR64:$src)))]>;

def hsail_cvt_s32_upi_f64 : HSAILInst<(outs GPR32:$dst), (ins GPR64:$src),
                        "cvt_upi_s32_f64\t$dst,$src",
                        [(set (i32 GPR32:$dst), (fp_to_sint  (int_HSAIL_ceil_f64 GPR64:$src)))]>;

def hsail_cvt_s32_zeroi_f64 : HSAILInst<(outs GPR32:$dst), (ins GPR64:$src),
                        "cvt_zeroi_s32_f64\t$dst,$src",
                        [(set (i32 GPR32:$dst), (fp_to_sint  (int_HSAIL_trunc_f64 GPR64:$src)))]>;

def hsail_cvt_s32_neari_f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
                        "cvt_ftz_neari_s32_f32\t$dst,$src",
                        [(set (i32 GPR32:$dst), (fp_to_sint  (int_HSAIL_rnd_f32 GPR32:$src)))]>;

def hsail_cvt_s32_downi_f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
                        "cvt_ftz_downi_s32_f32\t$dst,$src",
                        [(set (i32 GPR32:$dst), (fp_to_sint  (int_HSAIL_floor_f32 GPR32:$src)))]>;

def hsail_cvt_s32_upi_f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
                        "cvt_ftz_upi_s32_f32\t$dst,$src",
                        [(set (i32 GPR32:$dst), (fp_to_sint  (int_HSAIL_ceil_f32 GPR32:$src)))]>;

def hsail_cvt_s32_zeroi_f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
                        "cvt_ftz_zeroi_s32_f32\t$dst,$src",
                        [(set (i32 GPR32:$dst), (fp_to_sint  (int_HSAIL_trunc_f32 GPR32:$src)))]>;


////////////////////////////////////////////////////////////////////////////////
// support for explicit conversions
class ConvertIntr<Intrinsic intr, string asm, 
                  RegisterClass FromRc, ValueType FromTy, 
                  RegisterClass ToRc, ValueType ToTy> : HSAILInst<
  (outs ToRc:$dst), (ins FromRc:$src),
  !strconcat(asm, "\t $dst, $src"),
  [(set (ToTy ToRc:$dst), (intr (FromTy FromRc:$src)))]>;

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

// round
defm rnd    : UnaryIntrF32<int_HSAIL_rnd_f32, "rint_ftz_f32">;
defm rnd    : UnaryIntrF64<int_HSAIL_rnd_f64, "rint_f64">;

// truncate
defm trunc  : UnaryIntrF32<int_HSAIL_trunc_f32, "trunc_ftz_f32">;
defm trunc  : UnaryIntrF64<int_HSAIL_trunc_f64, "trunc_f64">;

////////////////////////////////////////////////////////////////////////////////
// bitconvert

def bitcvt_f32_u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
                     "mov_b32\t$dst, $src",
                     [(set (i32 GPR32:$dst), (bitconvert (f32 GPR32:$src)))]>;

def bitcvt_f64_u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
                     "mov_b64\t$dst, $src",
                     [(set (i64 GPR64:$dst), (bitconvert (f64 GPR64:$src)))]>;

def bitcvt_u32_f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
                     "mov_b32\t$dst, $src",
                     [(set (f32 GPR32:$dst), (bitconvert (i32 GPR32:$src)))]>;

def bitcvt_u64_f64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
                     "mov_b64\t$dst, $src",
                     [(set (f64 GPR64:$dst), (bitconvert (i64 GPR64:$src)))]>;
}
