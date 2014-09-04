let isCompare = 1 in {

  // Two versions of compare instructions: with and without immediate
  // second operand.
  multiclass CmpRRInst<PatFrag op, string asm
                      , ValueType outTy, RegisterClass outRC
                      , ValueType inTy, RegisterClass inRC, Operand immTy, SDNode immSDTy> {
    def _rr : HSAILInst<(outs outRC:$dst), (ins inRC:$src1, inRC:$src2),
        !strconcat(asm, "\t $dst, $src1, $src2"),
        [(set (outTy outRC:$dst), (op (inTy inRC:$src1), (inTy inRC:$src2)))]>;

    def _ri : HSAILInst<(outs outRC:$dst), (ins inRC:$src1, immTy:$src2),
        !strconcat(asm, "\t $dst, $src1, $src2"),
        [(set (outTy outRC:$dst), (op (inTy inRC:$src1), (inTy immSDTy:$src2)))]>;
  }

  // Floating point comparisons instantiated for different precisions.
  multiclass CmpFloat<PatFrag op, string cmpOp, string outSuffix
                   , ValueType outTy, RegisterClass outRC> {
    defm _f32 : CmpRRInst<op, cmpOp#"ftz_"#outSuffix#"_f32", outTy, outRC, f32, GPR32, f32imm, fpimm>;
    defm _f64 : CmpRRInst<op, cmpOp#outSuffix#"_f64", outTy, outRC, f64, GPR64, f64imm, fpimm>;
  }

  // Floating point comparisons.
  multiclass CmpFloatOps<string outSuffix, ValueType outTy, RegisterClass outRC> {
    // Arranged in the same order as ISD::CondCode enum in ISDOpcodes.h
    // The defm names reflect LLVM codes.
    defm _oeq : CmpFloat<setoeq, "cmp_eq_", outSuffix,  outTy, outRC>;
    defm _ogt : CmpFloat<setogt, "cmp_gt_", outSuffix,  outTy, outRC>;
    defm _oge : CmpFloat<setoge, "cmp_ge_", outSuffix,  outTy, outRC>;
    defm _olt : CmpFloat<setolt, "cmp_lt_", outSuffix,  outTy, outRC>;
    defm _ole : CmpFloat<setole, "cmp_le_", outSuffix,  outTy, outRC>;
    defm _one : CmpFloat<setone, "cmp_ne_", outSuffix,  outTy, outRC>;

    defm _o   : CmpFloat<seto,   "cmp_num_", outSuffix, outTy, outRC>;
    defm _uo  : CmpFloat<setuo,  "cmp_nan_", outSuffix, outTy, outRC>;

    defm _ueq : CmpFloat<setueq, "cmp_equ_", outSuffix, outTy, outRC>;
    defm _ugt : CmpFloat<setugt, "cmp_gtu_", outSuffix, outTy, outRC>;
    defm _uge : CmpFloat<setuge, "cmp_geu_", outSuffix, outTy, outRC>;
    defm _ult : CmpFloat<setult, "cmp_ltu_", outSuffix, outTy, outRC>;
    defm _ule : CmpFloat<setule, "cmp_leu_", outSuffix, outTy, outRC>;
    defm _une : CmpFloat<setune, "cmp_neu_", outSuffix, outTy, outRC>;

    // Undefined when input is a NaN:
    // Our implementation shall use ordered comparisons
    defm _eq  : CmpFloat<seteq,  "cmp_eq_", outSuffix,  outTy, outRC>;
    defm _gt  : CmpFloat<setgt,  "cmp_gt_", outSuffix,  outTy, outRC>;
    defm _ge  : CmpFloat<setge,  "cmp_ge_", outSuffix,  outTy, outRC>;
    defm _lt  : CmpFloat<setlt,  "cmp_lt_", outSuffix,  outTy, outRC>;
    defm _le  : CmpFloat<setle,  "cmp_le_", outSuffix,  outTy, outRC>;
    defm _ne  : CmpFloat<setne,  "cmp_ne_", outSuffix,  outTy, outRC>;
  }

  // Integer comparisons instantiated for different precisions.
  multiclass CmpInt<PatFrag op, string asm
                    , ValueType outTy, RegisterClass outRC> {
    defm _i32 : CmpRRInst<op, asm#"32", outTy, outRC, i32, GPR32, i32imm, imm>;
    defm _i64 : CmpRRInst<op, asm#"64", outTy, outRC, i64, GPR64, i64imm, imm>;
  }

  // Comparison of unsigned integers.
  //
  // Equality operators are implemented using signed operations. See below.
  multiclass CmpIntUnsigned<string outSuffix, ValueType outTy, RegisterClass outRC> {
    defm _ugt : CmpInt<setugt, "cmp_gt_"#outSuffix#"_u", outTy, outRC>;
    defm _uge : CmpInt<setuge, "cmp_ge_"#outSuffix#"_u", outTy, outRC>;
    defm _ult : CmpInt<setult, "cmp_lt_"#outSuffix#"_u", outTy, outRC>;
    defm _ule : CmpInt<setule, "cmp_le_"#outSuffix#"_u", outTy, outRC>;
  }

  // Comparison of signed integers.
  // 
  // Equality operators are independent of sign in LLVM. We choose to
  // implement them using signed HSAIL operations, simply because the
  // pattern names fit in with others in the list!
  multiclass CmpIntSigned<string outSuffix, ValueType outTy, RegisterClass outRC> {
    defm _eq  : CmpInt<seteq,  "cmp_eq_"#outSuffix#"_s",  outTy, outRC>;
    defm _gt  : CmpInt<setgt,  "cmp_gt_"#outSuffix#"_s",  outTy, outRC>;
    defm _ge  : CmpInt<setge,  "cmp_ge_"#outSuffix#"_s",  outTy, outRC>;
    defm _lt  : CmpInt<setlt,  "cmp_lt_"#outSuffix#"_s",  outTy, outRC>;
    defm _le  : CmpInt<setle,  "cmp_le_"#outSuffix#"_s",  outTy, outRC>;
    defm _ne  : CmpInt<setne,  "cmp_ne_"#outSuffix#"_s",  outTy, outRC>;
  }

  // Only two operations are defined on Boolean inputs.
  multiclass CmpBool<string outSuffix, ValueType outTy, RegisterClass outRC> {
    defm _eq_i1 : CmpRRInst<seteq, "cmp_eq_"#outSuffix#"_b1", outTy, outRC, i1, CR, i1imm, imm>;
    defm _ne_i1 : CmpRRInst<setne, "cmp_ne_"#outSuffix#"_b1", outTy, outRC, i1, CR, i1imm, imm>;
  }

  // The defm names reflect LLVM type names for the return value.
  // HSAIL operations with signed/unsigned return values generate
  // identical results. We choose to implement them using unsigned
  // integer as return type.
  //
  // Note the resulting mapping of TD records to HSAIL instructions
  // for cmp. Examples:
  // 
  // TD record "cmp_i1_eq_i1_rr"   --> HSAIL instruction "cmp_eq_b1_b1"
  // TD record "cmp_i32_eq_f32_ri" --> HSAIL instruction "cmp_eq_u32_f32"
  // TD record "cmp_i1_eq_i32_ri"  --> HSAIL instruction "cmp_eq_b1_s32"
  //
  // TD record names show up as enum elements in TableGen'erated code.
  // e.g., HSAIL::cmp_i1_eq_i1_rr

  defm cmp_i1  : CmpFloatOps<"b1", i1, CR>
               , CmpBool<"b1", i1, CR>
               , CmpIntSigned<"b1", i1, CR>
               , CmpIntUnsigned<"b1", i1, CR>;

  defm cmp_i32 : CmpFloatOps<"u32", i32, GPR32>
               , CmpBool<"u32", i32, GPR32>
               , CmpIntSigned<"u32", i32, GPR32>
               , CmpIntUnsigned<"u32", i32, GPR32>;

  defm cmp_i64 : CmpFloatOps<"u64", i64, GPR64>
               , CmpBool<"u64", i64, GPR64>
               , CmpIntSigned<"u64", i64, GPR64>
               , CmpIntUnsigned<"u64", i64, GPR64>;
}

////////////////////////////////////////////////////////////////////////////////
// floating-point classify instructions

multiclass FPClassIntr<Intrinsic intr, string asm, RegisterClass OpRC, 
                        ValueType OpVT, Operand OpImmTy> {
  def _rr : HSAILInst<(outs CR:$dst), (ins OpRC:$src1, GPR32:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i1 CR:$dst), (intr (OpVT OpRC:$src1), (i32 GPR32:$src2)))]>;

  def _ri : HSAILInst<(outs CR:$dst), (ins OpRC:$src1, i32imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i1 CR:$dst), (intr (OpVT OpRC:$src1), (i32 imm:$src2)))]>;

  def _ir : HSAILInst<(outs CR:$dst), (ins OpImmTy:$src1, GPR32:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i1 CR:$dst), (intr (OpVT fpimm:$src1), (i32 GPR32:$src2)))]>;

  def _ii : HSAILInst<(outs CR:$dst), (ins OpImmTy:$src1, i32imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i1 CR:$dst), (intr (OpVT fpimm:$src1), (i32 imm:$src2)))]>;
}

defm class_f32 : FPClassIntr<int_HSAIL_class_f32, "class_b1_f32",
      GPR32, f32, f32imm>;
defm class_f64 : FPClassIntr<int_HSAIL_class_f64, "class_b1_f64",
      GPR64, f64, f64imm>;

