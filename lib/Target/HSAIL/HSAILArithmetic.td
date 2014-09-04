defm add : BinaryOpU32<add, "add_u32">;
defm add : BinaryOpU64<add, "add_u64">;
defm add : BinaryOpF32<fadd, "add_ftz_f32">;
defm add : BinaryOpF64<fadd, "add_f64">;

defm sub : BinaryNCOpU32<sub, "sub_u32">;
defm sub : BinaryNCOpU64<sub, "sub_u64">;
defm sub : BinaryNCOpF32<fsub, "sub_ftz_f32">;
defm sub : BinaryNCOpF64<fsub, "sub_f64">;

defm mul : BinaryOpU32< mul, "mul_u32">;
defm mul : BinaryOpU64< mul, "mul_u64">;
defm mul : BinaryOpF32<fmul, "mul_ftz_f32">;
defm mul : BinaryOpF64<fmul, "mul_f64">;

defm mulhi : BinaryOpU32<mulhu, "mulhi_u32">;
defm mulhi : BinaryOpS32<mulhs, "mulhi_s32">;
defm mulhi : BinaryOpU64<mulhu, "mulhi_u64">;
defm mulhi : BinaryOpS64<mulhs, "mulhi_s64">;

defm div : BinaryNCOpU32<udiv, "div_u32">;
defm div : BinaryNCOpU64<udiv, "div_u64">;
defm div : BinaryNCOpS32<sdiv, "div_s32">;
defm div : BinaryNCOpS64<sdiv, "div_s64">;
defm div : BinaryNCOpF32<fdiv, "div_ftz_f32">;
defm div : BinaryNCOpF64<fdiv, "div_f64">;

defm rem : BinaryNCOpU32<urem, "rem_u32">;
defm rem : BinaryNCOpU64<urem, "rem_u64">;
defm rem : BinaryNCOpS32<srem, "rem_s32">;
defm rem : BinaryNCOpS64<srem, "rem_s64">;

// mulhi intrinsic
defm mulhi_intrn : BinaryIntrS32<int_HSAIL_mulhi_s32, "mulhi_s32">;
defm mulhi_intrn : BinaryIntrU32<int_HSAIL_mulhi_u32, "mulhi_u32">;

defm mulhi_intrn : BinaryIntrS64<int_HSAIL_mulhi_s64, "mulhi_s64">;
defm mulhi_intrn : BinaryIntrU64<int_HSAIL_mulhi_u64, "mulhi_u64">;

defm imad  : TernaryIntrS32<int_HSAIL_mad_s32, "mad_s32">;
defm umad  : TernaryIntrU32<int_HSAIL_mad_u32, "mad_u32">;

// u[32,64] forms illegal in HSAIL
defm neg : UnaryPatS32<ineg, "neg_s32">;
defm neg : UnaryPatS64<ineg, "neg_s64">;
defm neg : UnaryOpF32<fneg, "neg_f32">;
defm neg : UnaryOpF64<fneg, "neg_f64">;

defm abs : UnaryIntrU32<int_HSAIL_abs_u32, "abs_u32">;
defm abs : UnaryIntrS32<int_HSAIL_abs_s32, "abs_s32">;
defm abs : UnaryIntrU64<int_HSAIL_abs_u64, "abs_u64">;
defm abs : UnaryIntrS64<int_HSAIL_abs_s64, "abs_s64">;
defm fabs : UnaryIntrF32<int_HSAIL_abs_f32, "abs_f32">;
defm fabs : UnaryIntrF64<int_HSAIL_abs_f64, "abs_f64">;

defm copysign : BinaryIntrF32<int_HSAIL_copysign_f32, "copysign_f32">;
defm copysign : BinaryIntrF64<int_HSAIL_copysign_f64, "copysign_f64">;

defm fma : TernaryIntrF32<int_HSAIL_fma_f32, "fma_ftz_f32">;
defm fma : TernaryIntrF64<int_HSAIL_fma_f64, "fma_f64">;
defm nfma : TernaryIntrF32<int_HSAIL_nfma_f32, "nfma_f32">;
defm nfma : TernaryIntrF64<int_HSAIL_nfma_f64, "nfma_f64">;

defm max : BinaryIntrU32<int_HSAIL_max_u32, "max_u32">;
defm max : BinaryIntrS32<int_HSAIL_max_s32, "max_s32">;
defm max : BinaryIntrU64<int_HSAIL_max_u64, "max_u64">;
defm max : BinaryIntrS64<int_HSAIL_max_s64, "max_s64">;
defm max : BinaryIntrF32<int_HSAIL_max_f32, "max_ftz_f32">;
defm max : BinaryIntrF64<int_HSAIL_max_f64, "max_f64">;
defm gcn_max : BinaryIntrF32<int_HSAIL_gcn_max_f32, "gcn_max_f32">;
defm gcn_max : BinaryIntrF64<int_HSAIL_gcn_max_f64, "gcn_max_f64">;

defm min : BinaryIntrU32<int_HSAIL_min_u32, "min_u32">;
defm min : BinaryIntrS32<int_HSAIL_min_s32, "min_s32">;
defm min : BinaryIntrU64<int_HSAIL_min_u64, "min_u64">;
defm min : BinaryIntrS64<int_HSAIL_min_s64, "min_s64">;
defm min : BinaryIntrF32<int_HSAIL_min_f32, "min_ftz_f32">;
defm min : BinaryIntrF64<int_HSAIL_min_f64, "min_f64">;
defm gcn_min : BinaryIntrF32<int_HSAIL_gcn_min_f32, "gcn_min_f32">;
defm gcn_min : BinaryIntrF64<int_HSAIL_gcn_min_f64, "gcn_min_f64">;

defm mad24 : TernaryIntrS32<int_HSAIL_mad24_s32, "mad24_s32">;
defm mad24 : TernaryIntrU32<int_HSAIL_mad24_u32, "mad24_u32">;

defm mul24 : BinaryIntrS32<int_HSAIL_mul24_s32, "mul24_s32">;
defm mul24 : BinaryIntrU32<int_HSAIL_mul24_u32, "mul24_u32">;

defm pdiv : BinaryIntrF32<int_HSAIL_div_f32, "div_f32">;

defm sqrt : UnaryIntrF32<int_HSAIL_sqrt_ftz_f32, "sqrt_ftz_f32">;
defm sqrt : UnaryIntrF64<int_HSAIL_sqrt_f64, "sqrt_f64">;

defm nsqrt : UnaryIntrF32<int_HSAIL_nsqrt_f32, "nsqrt_f32">;
defm nsqrt : UnaryIntrF64<int_HSAIL_nsqrt_f64, "nsqrt_f64">;

// HSAIL_SPEC_CURRENT <
defm fract : UnaryIntrF32<int_HSAIL_fract_f32, "fract_ftz_f32">;
defm fract : UnaryIntrF64<int_HSAIL_fract_f64, "fract_f64">;
// > HSAIL_SPEC_CURRENT

// Floating-Point Special Functions Operations
defm ncos : UnaryIntrF32<int_HSAIL_ncos_f32, "ncos_f32">;
defm nexp2 : UnaryIntrF32<int_HSAIL_nexp2_f32, "nexp2_f32">;
defm nlog2 : UnaryIntrF32<int_HSAIL_nlog2_f32, "nlog2_f32">;
defm nrcp : UnaryIntrF32<int_HSAIL_nrcp_f32, "nrcp_f32">;
defm nrcp : UnaryIntrF64<int_HSAIL_nrcp_f64, "nrcp_f64">;
defm nrsqrt : UnaryIntrF32<int_HSAIL_nrsqrt_f32, "nrsqrt_f32">;
defm nrsqrt : UnaryIntrF64<int_HSAIL_nrsqrt_f64, "nrsqrt_f64">;
defm nsin : UnaryIntrF32<int_HSAIL_nsin_f32, "nsin_f32">;

////////////////////////////////////////////////////////////////////////////////
// and (integer, 1-bit, 32-bit, and 64-bit)
defm and : BinaryOpB1<and, "and_b1">;
defm and : BinaryOpU32<and, "and_b32">;
defm and : BinaryOpU64<and, "and_b64">;

////////////////////////////////////////////////////////////////////////////////
// or (integer, 1-bit, 32-bit, and 64-bit)
defm or : BinaryOpB1<or, "or_b1">;
defm or : BinaryOpU32<or, "or_b32">;
defm or : BinaryOpU64<or, "or_b64">;

////////////////////////////////////////////////////////////////////////////////
// xor (integer, 1-bit, 32-bit, and 64-bit)
defm xor : BinaryOpB1<xor, "xor_b1">;
defm xor : BinaryOpU32<xor, "xor_b32">;
defm xor : BinaryOpU64<xor, "xor_b64">;

////////////////////////////////////////////////////////////////////////////////
// not (integer, 1-bit, 32-bit, and 64-bit)
defm not : UnaryPatB1<not, "not_b1">;
defm not : UnaryPatU32<not, "not_b32">;
defm not : UnaryPatU64<not, "not_b64">;

////////////////////////////////////////////////////////////////////////////////
// popcount (integer, 1-bit, 32-bit, and 64-bit)
defm ctpop : UnaryOpU32<ctpop, "popcount_u32_b32">;
defm ctpop : UnaryOpU64<ctpop, "popcount_u32_b64">;

////////////////////////////////////////////////////////////////////////////////
// firstbit (integer, 1-bit, 32-bit, and 64-bit)
// HSAIL_SPEC_CURRENT <
defm ctlz : UnaryOpU32<ctlz, "firstbit_u32_u32">;
defm ctlz : UnaryOpU64<ctlz, "firstbit_u32_u64">;
// > HSAIL_SPEC_CURRENT

////////////////////////////////////////////////////////////////////////////////
// lastbit (integer, 1-bit, 32-bit, and 64-bit)
// HSAIL_SPEC_CURRENT <
defm cttz : UnaryOpU32<cttz, "lastbit_u32_u32">;
defm cttz : UnaryOpU64<cttz, "lastbit_u32_u64">;
// > HSAIL_SPEC_CURRENT

////////////////////////////////////////////////////////////////////////////////
// signbit (integer, 1-bit, 32-bit, and 64-bit)

////////////////////////////////////////////////////////////////////////////////
// shl (integer, signed and unsigned, 32-bit and 64-bit)
defm shl : BinaryNCOpU32<shl, "shl_u32">;
defm shl : ShiftOpU64<shl, "shl_u64">;

////////////////////////////////////////////////////////////////////////////////
// shr (integer, signed and unsigned, 32-bit and 64-bit)
defm shr : BinaryNCOpU32<srl, "shr_u32">;
defm shr : BinaryNCOpS32<sra, "shr_s32">;
defm shr : ShiftOpU64<srl, "shr_u64">;
defm shr : ShiftOpS64<sra, "shr_s64">;

////////////////////////////////////////////////////////////////////////////////
// cmov (1-bit, 32-bit, and 64-bit; integer and float)

def cmov_b1 : HSAILInst<(outs CR:$dst), (ins CR:$cond, CR:$tval, CR:$fval),
               "cmov_b1\t$dst, $cond, $tval, $fval",
               [(set (i1 CR:$dst),
                     (select (i1 CR:$cond), (i1 CR:$tval), (i1 CR:$fval)))]>;

multiclass cmov<string asm, ValueType Ty, Operand OpTy, SDNode ImmTy,
                RegisterClass RC> {

    def _rr : HSAILInst<(outs RC:$dst), (ins CR:$cond, RC:$tval, RC:$fval),
                        !strconcat(asm, "\t $dst, $cond, $tval, $fval"),
                        [(set (Ty RC:$dst),
                              (select (i1 CR:$cond),
                                      (Ty RC:$tval),
                                      (Ty RC:$fval)))]>;

    def _ri : HSAILInst<(outs RC:$dst), (ins CR:$cond, RC:$tval, OpTy:$fval),
                        !strconcat(asm, "\t $dst, $cond, $tval, $fval"),
                        [(set (Ty RC:$dst),
                              (select (i1 CR:$cond),
                                      (Ty RC:$tval),
                                      (Ty ImmTy:$fval)))]>;

    def _ir : HSAILInst<(outs RC:$dst), (ins CR:$cond, OpTy:$tval, RC:$fval),
                        !strconcat(asm, "\t $dst, $cond, $tval, $fval"),
                        [(set (Ty RC:$dst),
                              (select (i1 CR:$cond),
                                      (Ty ImmTy:$tval),
                                      (Ty RC:$fval)))]>;

    def _ii : HSAILInst<(outs RC:$dst), (ins CR:$cond, OpTy:$tval, OpTy:$fval),
                        !strconcat(asm, "\t $dst, $cond, $tval, $fval"),
                        [(set (Ty RC:$dst),
                              (select (i1 CR:$cond),
                                      (Ty ImmTy:$tval),
                                      (Ty ImmTy:$fval)))]>;
}

defm cmov_b32_i : cmov<"cmov_b32", i32, i32imm, imm,   GPR32>;
defm cmov_b32_f : cmov<"cmov_b32", f32, f32imm, fpimm, GPR32>;
defm cmov_b64_i : cmov<"cmov_b64", i64, i64imm, imm,   GPR64>;
defm cmov_b64_f : cmov<"cmov_b64", f64, f64imm, fpimm, GPR64>;

////////////////////////////////////////////////////////////////////////////////
// bitrev (integer, 32-bit, and 64-bit)

////////////////////////////////////////////////////////////////////////////////
// extract (integer, 32-bit, and 64-bit)

////////////////////////////////////////////////////////////////////////////////
// insert (integer, 32-bit, and 64-bit)

////////////////////////////////////////////////////////////////////////////////
// mov

let isMoveImm = 1 in {
def mov_i_b1 : HSAILInst<(outs CR:$dst), (ins i1imm:$src),
               "mov_b1\t$dst, $src",
               [(set (i1 CR:$dst), (i1 imm:$src))]>;

def mov_i_f32 : HSAILInst<(outs GPR32:$dst), (ins f32imm:$src),
                "mov_b32\t$dst, $src",
                [(set GPR32:$dst, (f32 fpimm:$src))]>;

def mov_i_f64 : HSAILInst<(outs GPR64:$dst), (ins f64imm:$src),
                "mov_b64\t$dst, $src",
                [(set GPR64:$dst, (f64 fpimm:$src))]>;

def mov_i_u32 : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src),
                "mov_b32\t$dst, $src",
                [(set GPR32:$dst, (i32 imm:$src))]>;

def mov_i_u64 : HSAILInst<(outs GPR64:$dst), (ins i64imm:$src),
                "mov_b64\t$dst, $src",
                [(set GPR64:$dst, (i64 imm:$src))]>;
}

def mov_r_b1 : HSAILInst<(outs CR:$dst), (ins CR:$src),
            "mov_b1\t$dst, $src",
            []>;

def mov_r_b32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
              "mov_b32\t$dst, $src",
              []>;

def mov_r_b64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
              "mov_b64\t$dst, $src",
              []>;

////////////////////////////////////////////////////////////////////////////////
// misc operations
def ftz_f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
      "add_ftz_f32\t$dst, $src, 0F00000000",
      [(set (f32 GPR32:$dst), (int_HSAIL_ftz_f32 (f32 GPR32:$src)))]>;

// HSAIL_SPEC_CURRENT <
defm firstbitu :  UnaryIntrU32<int_HSAIL_firstbit_u32, "firstbit_u32_u32">;
defm lastbitu :  UnaryIntrU32<int_HSAIL_lastbit_u32, "lastbit_u32_u32">;
// > HSAIL_SPEC_CURRENT

defm bitsel : TernaryIntrU32<int_HSAIL_bitsel_u32, "bitselect_b32">;
defm bitsel : TernaryIntrU64<int_HSAIL_bitsel_u64, "bitselect_b64">;

// bytealign and bitalign
multiclass AlignIntr<Intrinsic intr, string asm> {
  def _rrr : HSAILInst<
    (outs GPR32:$dst), (ins GPR32:$src1, GPR32:$src2, GPR32:$src3),
    !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
    [(set (i32 GPR32:$dst), 
      (intr (i32 GPR32:$src2), (i32 GPR32:$src1), (i32 GPR32:$src3)))]>;

  def _rri : HSAILInst<
    (outs GPR32:$dst), (ins GPR32:$src1, GPR32:$src2, i32imm:$src3),
    !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
    [(set (i32 GPR32:$dst), 
      (intr (i32 GPR32:$src2), (i32 GPR32:$src1), (i32 imm:$src3)))]>;

  def _rir : HSAILInst<
    (outs GPR32:$dst), (ins GPR32:$src1, i32imm:$src2, GPR32:$src3),
    !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
    [(set (i32 GPR32:$dst), 
      (intr (i32 imm:$src2), (i32 GPR32:$src1), (i32 GPR32:$src3)))]>;

  def _rii : HSAILInst<
    (outs GPR32:$dst), (ins GPR32:$src1, i32imm:$src2, i32imm:$src3),
    !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
    [(set (i32 GPR32:$dst), 
      (intr (i32 imm:$src2), (i32 GPR32:$src1), (i32 imm:$src3)))]>;
}

//Media - packcvt 
multiclass PackIntr<Intrinsic intr, string asm> {

    def _rrrr: HSAILInst<
        (outs GPR32:$dst), (ins GPR32:$src1, 
                                GPR32:$src2, 
                                GPR32:$src3, 
                                GPR32:$src4),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3,$src4"),
        [(set (i32 GPR32:$dst), 
         (intr (f32 GPR32:$src1), (f32 GPR32:$src2), 
               (f32 GPR32:$src3),(f32 GPR32:$src4) ))]>;
                
    def _irrr: HSAILInst<
        (outs GPR32:$dst), (ins f32imm:$src1, 
                                GPR32:$src2, 
                                GPR32:$src3, 
                                GPR32:$src4),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3,$src4"),
        [(set (i32 GPR32:$dst), 
         (intr (f32 fpimm:$src1), (f32 GPR32:$src2), 
               (f32 GPR32:$src3),(f32 GPR32:$src4) ))]>;
                
    def _rirr: HSAILInst<
        (outs GPR32:$dst), (ins GPR32:$src1, 
                                f32imm:$src2, 
                                GPR32:$src3, 
                                GPR32:$src4),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3,$src4"),
        [(set (i32 GPR32:$dst), 
         (intr (f32 GPR32:$src1), (f32 fpimm:$src2), 
               (f32 GPR32:$src3),(f32 GPR32:$src4) ))]>;
                
    def _rrir: HSAILInst<
        (outs GPR32:$dst), (ins GPR32:$src1, 
                                GPR32:$src2, 
                                f32imm:$src3, 
                                GPR32:$src4),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3,$src4"),
        [(set (i32 GPR32:$dst), 
         (intr (f32 GPR32:$src1), (f32 GPR32:$src2), 
               (f32 fpimm:$src3),(f32 GPR32:$src4) ))]>;
                
    def _rrri: HSAILInst<
        (outs GPR32:$dst), (ins GPR32:$src1, 
                                GPR32:$src2, 
                                GPR32:$src3, 
                                f32imm:$src4),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3,$src4"),
        [(set (i32 GPR32:$dst), 
         (intr (f32 GPR32:$src1), (f32 GPR32:$src2), 
               (f32 GPR32:$src3),(f32 fpimm:$src4) ))]>;
    
    def _iirr: HSAILInst<
        (outs GPR32:$dst), (ins f32imm:$src1, 
                                f32imm:$src2, 
                                GPR32:$src3, 
                                GPR32:$src4),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3,$src4"),
        [(set (i32 GPR32:$dst), 
         (intr (f32 fpimm:$src1), (f32 fpimm:$src2), 
               (f32 GPR32:$src3),(f32 GPR32:$src4) ))]>;
                
    def _irir: HSAILInst<
        (outs GPR32:$dst), (ins f32imm:$src1, 
                                GPR32:$src2, 
                                f32imm:$src3, 
                                GPR32:$src4),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3,$src4"),
        [(set (i32 GPR32:$dst), 
         (intr (f32 fpimm:$src1), (f32 GPR32:$src2), 
               (f32 fpimm:$src3),(f32 GPR32:$src4) ))]>;

    def _irri: HSAILInst<
        (outs GPR32:$dst), (ins f32imm:$src1, 
                                GPR32:$src2, 
                                GPR32:$src3, 
                                f32imm:$src4),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3,$src4"),
        [(set (i32 GPR32:$dst), 
         (intr (f32 fpimm:$src1), (f32 GPR32:$src2), 
               (f32 GPR32:$src3),(f32 fpimm:$src4) ))]>;                

    def _riir: HSAILInst<
        (outs GPR32:$dst), (ins GPR32:$src1, 
                                f32imm:$src2, 
                                f32imm:$src3, 
                                GPR32:$src4),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3,$src4"),
        [(set (i32 GPR32:$dst), 
         (intr (f32 GPR32:$src1), (f32 fpimm:$src2), 
               (f32 fpimm:$src3),(f32 GPR32:$src4) ))]>;                    

    def _riri: HSAILInst<
        (outs GPR32:$dst), (ins GPR32:$src1, 
                                f32imm:$src2, 
                                GPR32:$src3, 
                                f32imm:$src4),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3,$src4"),
        [(set (i32 GPR32:$dst), 
         (intr (f32 GPR32:$src1), (f32 fpimm:$src2), 
               (f32 GPR32:$src3),(f32 fpimm:$src4) ))]>;

    def _rrii: HSAILInst<
        (outs GPR32:$dst), (ins GPR32:$src1, 
                                GPR32:$src2, 
                                f32imm:$src3, 
                                f32imm:$src4),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3,$src4"),
        [(set (i32 GPR32:$dst), 
         (intr (f32 GPR32:$src1), (f32 GPR32:$src2), 
               (f32 fpimm:$src3),(f32 fpimm:$src4) ))]>;

    def _iiir: HSAILInst<
        (outs GPR32:$dst), (ins f32imm:$src1, 
                                f32imm:$src2, 
                                f32imm:$src3, 
                                GPR32:$src4),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3,$src4"),
        [(set (i32 GPR32:$dst), 
         (intr (f32 fpimm:$src1), (f32 fpimm:$src2), 
               (f32 fpimm:$src3),(f32 GPR32:$src4) ))]>;

    def _iiri: HSAILInst<
        (outs GPR32:$dst), (ins f32imm:$src1, 
                                f32imm:$src2, 
                                GPR32:$src3, 
                                f32imm:$src4),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3,$src4"),
        [(set (i32 GPR32:$dst), 
         (intr (f32 fpimm:$src1), (f32 fpimm:$src2), 
               (f32 GPR32:$src3),(f32 fpimm:$src4) ))]>;

    def _irii: HSAILInst<
        (outs GPR32:$dst), (ins f32imm:$src1, 
                                GPR32:$src2, 
                                f32imm:$src3, 
                                f32imm:$src4),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3,$src4"),
        [(set (i32 GPR32:$dst), 
         (intr (f32 fpimm:$src1), (f32 GPR32:$src2), 
               (f32 fpimm:$src3),(f32 fpimm:$src4) ))]>;
               
    def _riii: HSAILInst<
        (outs GPR32:$dst), (ins GPR32:$src1, 
                                f32imm:$src2, 
                                f32imm:$src3, 
                                f32imm:$src4),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3,$src4"),
        [(set (i32 GPR32:$dst), 
         (intr (f32 GPR32:$src1), (f32 fpimm:$src2), 
               (f32 fpimm:$src3),(f32 fpimm:$src4) ))]>;
               
    def _iiii: HSAILInst<
        (outs GPR32:$dst), (ins f32imm:$src1, 
                                f32imm:$src2, 
                                f32imm:$src3, 
                                f32imm:$src4),
        !strconcat(asm, "\t $dst, $src1, $src2, $src3,$src4"),
        [(set (i32 GPR32:$dst), 
         (intr (f32 fpimm:$src1), (f32 fpimm:$src2), 
               (f32 fpimm:$src3),(f32 fpimm:$src4) ))]>;           
}

//Media - unpackcvt 
multiclass UnpackIntr<Intrinsic intr, string asm> {
    
    def ri:     HSAILInst<
            (outs GPR32:$dst), (ins GPR32:$src1, i32imm:$src2),
            !strconcat(asm, "\t$dst, $src1, $src2"),
            [(set (f32 GPR32:$dst), (intr (i32 GPR32:$src1), 
                                          (i32 imm:$src2)))]>;
    
    def ii:     HSAILInst<
            (outs GPR32:$dst), (ins i32imm:$src1, i32imm:$src2),
            !strconcat(asm, "\t$dst, $src1, $src2"),
            [(set (f32 GPR32:$dst), (intr (i32 imm:$src1), 
                                          (i32 imm:$src2)))]>;
}

defm media_bitalign  : AlignIntr<int_HSAIL_bitalign_b32, "bitalign_b32">;
defm media_bytealign : AlignIntr<int_HSAIL_bytealign_b32, "bytealign_b32">;
defm media_packcvt : PackIntr<int_HSAIL_packcvt_u8x4_f32, "packcvt_u8x4_f32">;
defm media_lerp : TernaryIntrU32<int_HSAIL_lerp_u8x4, "lerp_u8x4">;
defm media_sad :     TernaryIntrU32<int_HSAIL_sad_u32_u8x4, "sad_u32_u8x4">;
defm media_sadhi : TernaryIntrU32<int_HSAIL_sadhi_u16x2_u8x4, "sadhi_u16x2_u8x4">;
defm media_unpackcvt : UnpackIntr<int_HSAIL_unpackcvt_f32_u8x4, "unpackcvt_f32_u8x4">;

defm popcount  : UnaryIntrS32<int_HSAIL_popcount_u32_b32, "popcount_u32_b32">;

//media_ops2

multiclass GCNMediaOps64<Intrinsic intr, string asm> {
  def _i64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1,GPR32:$src2,GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (intr (i64 GPR64:$src1),(i32 GPR32:$src2),(i64 GPR64:$src3)))]>;

}

defm media_msad        :  TernaryIntrU32<int_HSAIL_msad, "gcn_msad_b32">;
defm media_sadw        :  TernaryIntrU32<int_HSAIL_sadw, "gcn_sadw_b32">;
defm media_sadd        :  TernaryIntrU32<int_HSAIL_sadd, "gcn_sadd_b32">;
defm media_umin3        :  TernaryIntrU32<int_HSAIL_umin3, "gcn_min3_u32">;
defm media_imin3        :  TernaryIntrS32<int_HSAIL_imin3, "gcn_min3_s32">;
defm media_f32_min3    :  TernaryIntrF32<int_HSAIL_f32_min3, "gcn_min3_f32">;
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
defm media_mqsad64    :   GCNMediaOps64<int_HSAIL_mqsad, "gcn_mqsad_b64">;

multiclass GcnFldexp<Intrinsic intr, string asm, ValueType Ty, Operand OpTy,
                        SDNode ImmTy, RegisterClass RC> {
  def _rr  : HSAILInst<
      (outs RC:$dst), (ins RC:$src1, GPR32:$src2),
      !strconcat(asm, "\t$dst, $src1, $src2"),
      [(set (Ty RC:$dst), (intr (Ty RC:$src1), (i32 GPR32:$src2)))]>;

  def _ri  : HSAILInst<
      (outs RC:$dst), (ins RC:$src1, i32imm:$src2),
      !strconcat(asm, "\t$dst, $src1, $src2"),
      [(set (Ty RC:$dst), (intr (Ty RC:$src1), (i32 imm:$src2)))]>;

  def _ir  : HSAILInst<
      (outs RC:$dst), (ins OpTy:$src1, GPR32:$src2),
      !strconcat(asm, "\t$dst, $src1, $src2"),
      [(set (Ty RC:$dst), (intr (Ty ImmTy:$src1), (i32 GPR32:$src2)))]>;

  def _ii  : HSAILInst<
      (outs RC:$dst), (ins OpTy:$src1, i32imm:$src2),
      !strconcat(asm, "\t$dst, $src1, $src2"),
      [(set (Ty RC:$dst), (intr (Ty ImmTy:$src1), (i32 imm:$src2)))]>;
}

defm gcn_fldexp_f32 : GcnFldexp<int_HSAIL_gcn_fldexp_f32, "gcn_fldexp_f32", f32, f32imm, fpimm, GPR32>;
defm gcn_fldexp_f64 : GcnFldexp<int_HSAIL_gcn_fldexp_f64, "gcn_fldexp_f64", f64, f64imm, fpimm, GPR64>;

def unpack_u32_u8x4: HSAILInst<(outs GPR32:$dst), (ins GPR32:$src, i32imm:$ind),
                                 "unpack_u32_u8x4\t $dst, $src, $ind",
                                 []>;
def unpack_u32_u16x2: HSAILInst<(outs GPR32:$dst), (ins GPR32:$src, i32imm:$ind),
                                 "unpack_u32_u8x4\t $dst, $src, $ind",
                                 []>;
