////////////////////////////////////////////////////////////////////////////////
// multiclass definitions that make code generation easier
////////////////////////////////////////////////////////////////////////////////
// 32bit floating point multiclasses
multiclass UnaryIntrF32<Intrinsic intr, string asm> {
  def _f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (f32 GPR32:$dst), (intr (f32 GPR32:$src)))]>;

  def _i_f32 : HSAILInst<(outs GPR32:$dst), (ins f32imm:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (f32 GPR32:$dst), (intr (f32 fpimm:$src)))]>;
}

multiclass BinaryIntrF32<Intrinsic intr, string asm> {
  def _f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, GPR32:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (f32 GPR32:$dst), (intr (f32 GPR32:$src1), (f32 GPR32:$src2)))]>;

  def _ri_f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, f32imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (f32 GPR32:$dst), (intr (f32 GPR32:$src1), (f32 fpimm:$src2)))]>;

  def _ir_f32 : HSAILInst<(outs GPR32:$dst), (ins f32imm:$src1, GPR32:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (f32 GPR32:$dst), (intr (f32 fpimm:$src1), (f32 GPR32:$src2)))]>;
}

multiclass TernaryIntrF32<Intrinsic intr, string asm> {
  def _f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, GPR32:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f32 GPR32:$dst), (intr (f32 GPR32:$src1), (f32 GPR32:$src2), (f32 GPR32:$src3)))]>;

  def _rri_f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, GPR32:$src2, f32imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f32 GPR32:$dst), (intr (f32 GPR32:$src1), (f32 GPR32:$src2), (f32 fpimm:$src3)))]>;

  def _rir_f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, f32imm:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f32 GPR32:$dst), (intr (f32 GPR32:$src1), (f32 fpimm:$src2), (f32 GPR32:$src3)))]>;

  def _rii_f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, f32imm:$src2, f32imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f32 GPR32:$dst), (intr (f32 GPR32:$src1), (f32 fpimm:$src2), (f32 fpimm:$src3)))]>;

  def _irr_f32 : HSAILInst<(outs GPR32:$dst), (ins f32imm:$src1, GPR32:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f32 GPR32:$dst), (intr (f32 fpimm:$src1), (f32 GPR32:$src2), (f32 GPR32:$src3)))]>;

  def _iir_f32 : HSAILInst<(outs GPR32:$dst), (ins f32imm:$src1, f32imm:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f32 GPR32:$dst), (intr (f32 fpimm:$src1), (f32 fpimm:$src2), (f32 GPR32:$src3)))]>;

  def _iri_f32 : HSAILInst<(outs GPR32:$dst), (ins f32imm:$src1, GPR32:$src2, f32imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f32 GPR32:$dst), (intr (f32 fpimm:$src1), (f32 GPR32:$src2), (f32 fpimm:$src3)))]>;
}

////////////////////////////////////////////////////////////////////////////////
// 64bit floating point multiclasses
multiclass UnaryIntrF64<Intrinsic intr, string asm> {
  def _f64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (f64 GPR64:$dst), (intr (f64 GPR64:$src)))]>;

  def _i_f64 : HSAILInst<(outs GPR64:$dst), (ins f64imm:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (f64 GPR64:$dst), (intr (f64 fpimm:$src)))]>;
}

multiclass BinaryIntrF64<Intrinsic intr, string asm> {
  def _f64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR64:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (f64 GPR64:$dst), (intr (f64 GPR64:$src1), (f64 GPR64:$src2)))]>;

  def _ri_f64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, f64imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (f64 GPR64:$dst), (intr (f64 GPR64:$src1), (f64 fpimm:$src2)))]>;

  def _ir_f64 : HSAILInst<(outs GPR64:$dst), (ins f64imm:$src1, GPR64:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (f64 GPR64:$dst), (intr (f64 fpimm:$src1), (f64 GPR64:$src2)))]>;
}

multiclass TernaryIntrF64<Intrinsic intr, string asm> {
  def _f64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR64:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f64 GPR64:$dst), (intr (f64 GPR64:$src1), (f64 GPR64:$src2), (f64 GPR64:$src3)))]>;

  def _rri_f64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR64:$src2, f64imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f64 GPR64:$dst), (intr (f64 GPR64:$src1), (f64 GPR64:$src2), (f64 fpimm:$src3)))]>;

  def _rir_f64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, f64imm:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f64 GPR64:$dst), (intr (f64 GPR64:$src1), (f64 fpimm:$src2), (f64 GPR64:$src3)))]>;

  def _rii_f64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, f64imm:$src2, f64imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f64 GPR64:$dst), (intr (f64 GPR64:$src1), (f64 fpimm:$src2), (f64 fpimm:$src3)))]>;

  def _irr_f64 : HSAILInst<(outs GPR64:$dst), (ins f64imm:$src1, GPR64:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f64 GPR64:$dst), (intr (f64 fpimm:$src1), (f64 GPR64:$src2), (f64 GPR64:$src3)))]>;

  def _iir_f64 : HSAILInst<(outs GPR64:$dst), (ins f64imm:$src1, f64imm:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f64 GPR64:$dst), (intr (f64 fpimm:$src1), (f64 fpimm:$src2), (f64 GPR64:$src3)))]>;

  def _iri_f64 : HSAILInst<(outs GPR64:$dst), (ins f64imm:$src1, GPR64:$src2, f64imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f64 GPR64:$dst), (intr (f64 fpimm:$src1), (f64 GPR64:$src2), (f64 fpimm:$src3)))]>;
}

////////////////////////////////////////////////////////////////////////////////
// 32bit unsigned integer multiclasses
multiclass UnaryIntrU32<Intrinsic intr, string asm> {
  def _u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i32 GPR32:$dst), (intr (i32 GPR32:$src)))]>;

  def _i_u32 : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i32 GPR32:$dst), (intr (i32 imm:$src)))]>;
}

multiclass BinaryIntrU32<Intrinsic intr, string asm> {
  def _u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, GPR32:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i32 GPR32:$dst), (intr (i32 GPR32:$src1), (i32 GPR32:$src2)))]>;

  def _ri_u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, i32imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i32 GPR32:$dst), (intr (i32 GPR32:$src1), (i32 imm:$src2)))]>;

  def _ir_u32 : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src1, GPR32:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i32 GPR32:$dst), (intr (i32 imm:$src1), (i32 GPR32:$src2)))]>;
}

multiclass TernaryIntrU32<Intrinsic intr, string asm> {
  def _u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, GPR32:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (intr (i32 GPR32:$src1), (i32 GPR32:$src2), (i32 GPR32:$src3)))]>;

  def _rri_u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, GPR32:$src2, i32imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (intr (i32 GPR32:$src1), (i32 GPR32:$src2), (i32 imm:$src3)))]>;

  def _rir_u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, i32imm:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (intr (i32 GPR32:$src1), (i32 imm:$src2), (i32 GPR32:$src3)))]>;

  def _rii_u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, i32imm:$src2, i32imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (intr (i32 GPR32:$src1), (i32 imm:$src2), (i32 imm:$src3)))]>;

  def _irr_u32 : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src1, GPR32:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (intr (i32 imm:$src1), (i32 GPR32:$src2), (i32 GPR32:$src3)))]>;

  def _iir_u32 : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src1, i32imm:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (intr (i32 imm:$src1), (i32 imm:$src2), (i32 GPR32:$src3)))]>;

  def _iri_u32 : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src1, GPR32:$src2, i32imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (intr (i32 imm:$src1), (i32 GPR32:$src2), (i32 imm:$src3)))]>;
}

//-------------------------------------------------------------------//
// Multiclasses that deal with four operand intrinsics.
//-------------------------------------------------------------------//
multiclass CrossLaneIntrB1<Intrinsic intr, string asm> {
  let hasWidthOperand = 1 in {
    def rrrr_b1 : HSAILInst<(outs GPR32:$dst),
      (ins GPR32:$src0, GPR32:$src1, GPR32:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 GPR32:$src0), (i32 GPR32:$src1),
                  (i32 GPR32:$src2), (i1 CR:$src3)))]>;
    def iiii_b1 : HSAILInst<(outs GPR32:$dst),
      (ins i1imm:$src0, i32imm:$src1, i1imm:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i1 imm:$src0), (i32 imm:$src1),
                  (i1 imm:$src2), (i1 imm:$src3)))]>;
    def irrr_b1 : HSAILInst<(outs GPR32:$dst),
      (ins i1imm:$src0, GPR32:$src1, GPR32:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i1 imm:$src0), (i32 GPR32:$src1),
                  (i32 GPR32:$src2), (i1 CR:$src3)))]>;
    def rirr_b1 : HSAILInst<(outs GPR32:$dst),
      (ins GPR32:$src0, i32imm:$src1, GPR32:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 GPR32:$src0), (i32 imm:$src1),
                  (i32 GPR32:$src2), (i1 CR:$src3)))]>;
    def rrir_b1 : HSAILInst<(outs GPR32:$dst),
      (ins GPR32:$src0, GPR32:$src1, i1imm:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 GPR32:$src0), (i32 GPR32:$src1),
                  (i1 imm:$src2), (i1 CR:$src3)))]>;
    def rrri_b1 : HSAILInst<(outs GPR32:$dst),
      (ins GPR32:$src0, GPR32:$src1, GPR32:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 GPR32:$src0), (i32 GPR32:$src1),
                  (i32 GPR32:$src2), (i1 imm:$src3)))]>;
    def iirr_b1 : HSAILInst<(outs GPR32:$dst),
      (ins i1imm:$src0, i32imm:$src1, GPR32:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i1 imm:$src0), (i32 imm:$src1),
                  (i32 GPR32:$src2), (i1 CR:$src3)))]>;
    def rrii_b1 : HSAILInst<(outs GPR32:$dst),
      (ins GPR32:$src0, GPR32:$src1, i1imm:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 GPR32:$src0), (i32 GPR32:$src1),
                  (i1 imm:$src2), (i1 imm:$src3)))]>;
    def irir_b1 : HSAILInst<(outs GPR32:$dst),
      (ins i1imm:$src0, GPR32:$src1, i1imm:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i1 imm:$src0), (i32 GPR32:$src1),
                  (i1 imm:$src2), (i1 CR:$src3)))]>;
    def irri_b1 : HSAILInst<(outs GPR32:$dst),
      (ins i1imm:$src0, GPR32:$src1, GPR32:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i1 imm:$src0), (i32 GPR32:$src1),
                  (i32 GPR32:$src2), (i1 imm:$src3)))]>;
    def riir_b1 : HSAILInst<(outs GPR32:$dst),
      (ins GPR32:$src0, i32imm:$src1, i1imm:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 GPR32:$src0), (i32 imm:$src1),
                  (i1 imm:$src2), (i1 CR:$src3)))]>;
    def riri_b1 : HSAILInst<(outs GPR32:$dst),
      (ins GPR32:$src0, i32imm:$src1, GPR32:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 GPR32:$src0), (i32 imm:$src1),
                  (i32 GPR32:$src2), (i1 imm:$src3)))]>;
    def iiir_b1 : HSAILInst<(outs GPR32:$dst),
      (ins i1imm:$src0, i32imm:$src1, i1imm:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i1 imm:$src0), (i32 imm:$src1),
                  (i1 imm:$src2), (i1 CR:$src3)))]>;
    def iiri_b1 : HSAILInst<(outs GPR32:$dst),
      (ins i1imm:$src0, i32imm:$src1, GPR32:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i1 imm:$src0), (i32 imm:$src1),
                  (i32 GPR32:$src2), (i1 imm:$src3)))]>;
    def irii_b1 : HSAILInst<(outs GPR32:$dst),
      (ins i1imm:$src0, GPR32:$src1, i1imm:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i1 imm:$src0), (i32 GPR32:$src1),
                  (i1 imm:$src2), (i1 imm:$src3)))]>;
    def riii_b1 : HSAILInst<(outs GPR32:$dst),
      (ins GPR32:$src0, i32imm:$src1, i1imm:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 GPR32:$src0), (i32 imm:$src1),
                  (i1 imm:$src2), (i1 imm:$src3)))]>;
  }
}

multiclass CrossLaneIntrB32<Intrinsic intr, string asm> {
  let hasWidthOperand = 1 in {
    def rrrr_b32 : HSAILInst<(outs GPR32:$dst),
      (ins GPR32:$src0, GPR32:$src1, GPR32:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 GPR32:$src0), (i32 GPR32:$src1),
                  (i32 GPR32:$src2), (i1 CR:$src3)))]>;
    def iiii_b32 : HSAILInst<(outs GPR32:$dst),
      (ins i32imm:$src0, i32imm:$src1, i32imm:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 imm:$src0), (i32 imm:$src1),
                  (i32 imm:$src2), (i1 imm:$src3)))]>;
    def irrr_b32 : HSAILInst<(outs GPR32:$dst),
      (ins i32imm:$src0, GPR32:$src1, GPR32:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 imm:$src0), (i32 GPR32:$src1),
                  (i32 GPR32:$src2), (i1 CR:$src3)))]>;
    def rirr_b32 : HSAILInst<(outs GPR32:$dst),
      (ins GPR32:$src0, i32imm:$src1, GPR32:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 GPR32:$src0), (i32 imm:$src1),
                  (i32 GPR32:$src2), (i1 CR:$src3)))]>;
    def rrir_b32 : HSAILInst<(outs GPR32:$dst),
      (ins GPR32:$src0, GPR32:$src1, i32imm:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 GPR32:$src0), (i32 GPR32:$src1),
                  (i32 imm:$src2), (i1 CR:$src3)))]>;
    def rrri_b32 : HSAILInst<(outs GPR32:$dst),
      (ins GPR32:$src0, GPR32:$src1, GPR32:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 GPR32:$src0), (i32 GPR32:$src1),
                  (i32 GPR32:$src2), (i1 imm:$src3)))]>;
    def iirr_b32 : HSAILInst<(outs GPR32:$dst),
      (ins i32imm:$src0, i32imm:$src1, GPR32:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 imm:$src0), (i32 imm:$src1),
                  (i32 GPR32:$src2), (i1 CR:$src3)))]>;
    def rrii_b32 : HSAILInst<(outs GPR32:$dst),
      (ins GPR32:$src0, GPR32:$src1, i32imm:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 GPR32:$src0), (i32 GPR32:$src1),
                  (i32 imm:$src2), (i1 imm:$src3)))]>;
    def irir_b32 : HSAILInst<(outs GPR32:$dst),
      (ins i32imm:$src0, GPR32:$src1, i32imm:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 imm:$src0), (i32 GPR32:$src1),
                  (i32 imm:$src2), (i1 CR:$src3)))]>;
    def irri_b32 : HSAILInst<(outs GPR32:$dst),
      (ins i32imm:$src0, GPR32:$src1, GPR32:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 imm:$src0), (i32 GPR32:$src1),
                  (i32 GPR32:$src2), (i1 imm:$src3)))]>;
    def riir_b32 : HSAILInst<(outs GPR32:$dst),
      (ins GPR32:$src0, i32imm:$src1, i32imm:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 GPR32:$src0), (i32 imm:$src1),
                  (i32 imm:$src2), (i1 CR:$src3)))]>;
    def riri_b32 : HSAILInst<(outs GPR32:$dst),
      (ins GPR32:$src0, i32imm:$src1, GPR32:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 GPR32:$src0), (i32 imm:$src1),
                  (i32 GPR32:$src2), (i1 imm:$src3)))]>;
    def iiir_b32 : HSAILInst<(outs GPR32:$dst),
      (ins i32imm:$src0, i32imm:$src1, i32imm:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 imm:$src0), (i32 imm:$src1),
                  (i32 imm:$src2), (i1 CR:$src3)))]>;
    def iiri_b32 : HSAILInst<(outs GPR32:$dst),
      (ins i32imm:$src0, i32imm:$src1, GPR32:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 imm:$src0), (i32 imm:$src1),
                  (i32 GPR32:$src2), (i1 imm:$src3)))]>;
    def irii_b32 : HSAILInst<(outs GPR32:$dst),
      (ins i32imm:$src0, GPR32:$src1, i32imm:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 imm:$src0), (i32 GPR32:$src1),
                  (i32 imm:$src2), (i1 imm:$src3)))]>;
    def riii_b32 : HSAILInst<(outs GPR32:$dst),
      (ins GPR32:$src0, i32imm:$src1, i32imm:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst),
            (intr (i32 GPR32:$src0), (i32 imm:$src1),
                  (i32 imm:$src2), (i1 imm:$src3)))]>;
  }
}

multiclass CrossLaneIntrB64<Intrinsic intr, string asm> {
  let hasWidthOperand = 1 in {
    def rrrr_b64 : HSAILInst<(outs GPR64:$dst),
      (ins GPR64:$src0, GPR32:$src1, GPR64:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst),
            (intr (i64 GPR64:$src0), (i32 GPR32:$src1),
                  (i64 GPR64:$src2), (i1 CR:$src3)))]>;
    def iiii_b64 : HSAILInst<(outs GPR64:$dst),
      (ins i64imm:$src0, i32imm:$src1, i64imm:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst),
            (intr (i64 imm:$src0), (i32 imm:$src1),
                  (i64 imm:$src2), (i1 imm:$src3)))]>;
    def irrr_b64 : HSAILInst<(outs GPR64:$dst),
      (ins i64imm:$src0, GPR32:$src1, GPR64:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst),
            (intr (i64 imm:$src0), (i32 GPR32:$src1),
                  (i64 GPR64:$src2), (i1 CR:$src3)))]>;
    def rirr_b64 : HSAILInst<(outs GPR64:$dst),
      (ins GPR64:$src0, i32imm:$src1, GPR64:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst),
            (intr (i64 GPR64:$src0), (i32 imm:$src1),
                  (i64 GPR64:$src2), (i1 CR:$src3)))]>;
    def rrir_b64 : HSAILInst<(outs GPR64:$dst),
      (ins GPR64:$src0, GPR32:$src1, i64imm:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst),
            (intr (i64 GPR64:$src0), (i32 GPR32:$src1),
                  (i64 imm:$src2), (i1 CR:$src3)))]>;
    def rrri_b64 : HSAILInst<(outs GPR64:$dst),
      (ins GPR64:$src0, GPR32:$src1, GPR64:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst),
            (intr (i64 GPR64:$src0), (i32 GPR32:$src1),
                  (i64 GPR64:$src2), (i1 imm:$src3)))]>;
    def iirr_b64 : HSAILInst<(outs GPR64:$dst),
      (ins i64imm:$src0, i32imm:$src1, GPR64:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst),
            (intr (i64 imm:$src0), (i32 imm:$src1),
                  (i64 GPR64:$src2), (i1 CR:$src3)))]>;
    def rrii_b64 : HSAILInst<(outs GPR64:$dst),
      (ins GPR64:$src0, GPR32:$src1, i64imm:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst),
            (intr (i64 GPR64:$src0), (i32 GPR32:$src1),
                  (i64 imm:$src2), (i1 imm:$src3)))]>;
    def irir_b64 : HSAILInst<(outs GPR64:$dst),
      (ins i64imm:$src0, GPR32:$src1, i64imm:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst),
            (intr (i64 imm:$src0), (i32 GPR32:$src1),
                  (i64 imm:$src2), (i1 CR:$src3)))]>;
    def irri_b64 : HSAILInst<(outs GPR64:$dst),
      (ins i64imm:$src0, GPR32:$src1, GPR64:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst),
            (intr (i64 imm:$src0), (i32 GPR32:$src1),
                  (i64 GPR64:$src2), (i1 imm:$src3)))]>;
    def riir_b64 : HSAILInst<(outs GPR64:$dst),
      (ins GPR64:$src0, i32imm:$src1, i64imm:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst),
            (intr (i64 GPR64:$src0), (i32 imm:$src1),
                  (i64 imm:$src2), (i1 CR:$src3)))]>;
    def riri_b64 : HSAILInst<(outs GPR64:$dst),
      (ins GPR64:$src0, i32imm:$src1, GPR64:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst),
            (intr (i64 GPR64:$src0), (i32 imm:$src1),
                  (i64 GPR64:$src2), (i1 imm:$src3)))]>;
    def iiir_b64 : HSAILInst<(outs GPR64:$dst),
      (ins i64imm:$src0, i32imm:$src1, i64imm:$src2, CR:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst),
            (intr (i64 imm:$src0), (i32 imm:$src1),
                  (i64 imm:$src2), (i1 CR:$src3)))]>;
    def iiri_b64 : HSAILInst<(outs GPR64:$dst),
      (ins i64imm:$src0, i32imm:$src1, GPR64:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst),
            (intr (i64 imm:$src0), (i32 imm:$src1),
                  (i64 GPR64:$src2), (i1 imm:$src3)))]>;
    def irii_b64 : HSAILInst<(outs GPR64:$dst),
      (ins i64imm:$src0, GPR32:$src1, i64imm:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst),
            (intr (i64 imm:$src0), (i32 GPR32:$src1),
                  (i64 imm:$src2), (i1 imm:$src3)))]>;
    def riii_b64 : HSAILInst<(outs GPR64:$dst),
      (ins GPR64:$src0, i32imm:$src1, i64imm:$src2, i1imm:$src3),
      !strconcat(asm, " $dst, $src0, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst),
            (intr (i64 GPR64:$src0), (i32 imm:$src1),
                  (i64 imm:$src2), (i1 imm:$src3)))]>;
  }
}

////////////////////////////////////////////////////////////////////////////////
// 64bit unsigned integer multiclasses
multiclass UnaryIntrU64<Intrinsic intr, string asm> {
  def _u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i64 GPR64:$dst), (intr (i64 GPR64:$src)))]>;

  def _i_u64 : HSAILInst<(outs GPR64:$dst), (ins i64imm:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i64 GPR64:$dst), (intr (i64 imm:$src)))]>;
}

multiclass BinaryIntrU64<Intrinsic intr, string asm> {
  def _u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR64:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (intr (i64 GPR64:$src1), (i64 GPR64:$src2)))]>;

  def _ri_u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, i64imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (intr (i64 GPR64:$src1), (i64 imm:$src2)))]>;

  def _ir_u64 : HSAILInst<(outs GPR64:$dst), (ins i64imm:$src1, GPR64:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (intr (i64 imm:$src1), (i64 GPR64:$src2)))]>;
}

multiclass TernaryIntrU64<Intrinsic intr, string asm> {
  def _u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR64:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (intr (i64 GPR64:$src1), (i64 GPR64:$src2), (i64 GPR64:$src3)))]>;

  def _rri_u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR64:$src2, i64imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (intr (i64 GPR64:$src1), (i64 GPR64:$src2), (i64 imm:$src3)))]>;

  def _rir_u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, i64imm:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (intr (i64 GPR64:$src1), (i64 imm:$src2), (i64 GPR64:$src3)))]>;

  def _rii_u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, i64imm:$src2, i64imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (intr (i64 GPR64:$src1), (i64 imm:$src2), (i64 imm:$src3)))]>;

  def _irr_u64 : HSAILInst<(outs GPR64:$dst), (ins i64imm:$src1, GPR64:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (intr (i64 imm:$src1), (i64 GPR64:$src2), (i64 GPR64:$src3)))]>;

  def _iir_u64 : HSAILInst<(outs GPR64:$dst), (ins i64imm:$src1, i64imm:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (intr (i64 imm:$src1), (i64 imm:$src2), (i64 GPR64:$src3)))]>;

  def _iri_u64 : HSAILInst<(outs GPR64:$dst), (ins i64imm:$src1, GPR64:$src2, i64imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (intr (i64 imm:$src1), (i64 GPR64:$src2), (i64 imm:$src3)))]>;
}

////////////////////////////////////////////////////////////////////////////////
// 32bit signed integer multiclasses
multiclass UnaryIntrS32<Intrinsic intr, string asm> {
  def _s32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i32 GPR32:$dst), (intr (i32 GPR32:$src)))]>;

  def _i_s32 : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i32 GPR32:$dst), (intr (i32 imm:$src)))]>;
}

multiclass BinaryIntrS32<Intrinsic intr, string asm> {
  def _s32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, GPR32:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i32 GPR32:$dst), (intr (i32 GPR32:$src1), (i32 GPR32:$src2)))]>;

  def _ri_s32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, i32imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i32 GPR32:$dst), (intr (i32 GPR32:$src1), (i32 imm:$src2)))]>;

  def _ir_s32 : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src1, GPR32:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i32 GPR32:$dst), (intr (i32 imm:$src1), (i32 GPR32:$src2)))]>;
}

multiclass TernaryIntrS32<Intrinsic intr, string asm> {
  def _s32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, GPR32:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (intr (i32 GPR32:$src1), (i32 GPR32:$src2), (i32 GPR32:$src3)))]>;

  def _rri_s32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, GPR32:$src2, i32imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (intr (i32 GPR32:$src1), (i32 GPR32:$src2), (i32 imm:$src3)))]>;

  def _rir_s32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, i32imm:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (intr (i32 GPR32:$src1), (i32 imm:$src2), (i32 GPR32:$src3)))]>;

  def _rii_s32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, i32imm:$src2, i32imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (intr (i32 GPR32:$src1), (i32 imm:$src2), (i32 imm:$src3)))]>;

  def _irr_s32 : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src1, GPR32:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (intr (i32 imm:$src1), (i32 GPR32:$src2), (i32 GPR32:$src3)))]>;

  def _iir_s32 : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src1, i32imm:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (intr (i32 imm:$src1), (i32 imm:$src2), (i32 GPR32:$src3)))]>;

  def _iri_s32 : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src1, GPR32:$src2, i32imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (intr (i32 imm:$src1), (i32 GPR32:$src2), (i32 imm:$src3)))]>;
}

////////////////////////////////////////////////////////////////////////////////
// 64bit unsigned integer multiclasses
multiclass UnaryIntrS64<Intrinsic intr, string asm> {
  def _s64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i64 GPR64:$dst), (intr (i64 GPR64:$src)))]>;

  def _i_s64 : HSAILInst<(outs GPR64:$dst), (ins i64imm:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i64 GPR64:$dst), (intr (i64 imm:$src)))]>;
}

multiclass BinaryIntrS64<Intrinsic intr, string asm> {
  def _s64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR64:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (intr (i64 GPR64:$src1), (i64 GPR64:$src2)))]>;

  def _ri_s64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, i64imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (intr (i64 GPR64:$src1), (i64 imm:$src2)))]>;

  def _ir_s64 : HSAILInst<(outs GPR64:$dst), (ins i64imm:$src1, GPR64:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (intr (i64 imm:$src1), (i64 GPR64:$src2)))]>;
}

multiclass TernaryIntrS64<Intrinsic intr, string asm> {
  def _s64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR64:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (intr (i64 GPR64:$src1), (i64 GPR64:$src2), (i64 GPR64:$src3)))]>;

  def _rri_s64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR64:$src2, imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (intr (i64 GPR64:$src1), (i64 GPR64:$src2), (i64 imm:$src3)))]>;

  def _rir_s64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, imm:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (intr (i64 GPR64:$src1), (i64 imm:$src2), (i64 GPR64:$src3)))]>;

  def _rii_s64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, i64imm:$src2, i64imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (intr (i64 GPR64:$src1), (i64 imm:$src2), (i64 imm:$src3)))]>;

  def _irr_s64 : HSAILInst<(outs GPR64:$dst), (ins imm:$src1, GPR64:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (intr (i64 imm:$src1), (i64 GPR64:$src2), (i64 GPR64:$src3)))]>;

  def _iir_s64 : HSAILInst<(outs GPR64:$dst), (ins imm:$src1, imm:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (intr (i64 imm:$src1), (i64 imm:$src2), (i64 GPR64:$src3)))]>;

  def _iri_s64 : HSAILInst<(outs GPR64:$dst), (ins imm:$src1, GPR64:$src2, imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (intr (i64 imm:$src1), (i64 GPR64:$src2), (i64 imm:$src3)))]>;
}

////////////////////////////////////////////////////////////////////////////////
// 32bit floating point multiclasses
multiclass UnaryOpF32<SDNode op, string asm> {
  def _f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (f32 GPR32:$dst), (op (f32 GPR32:$src)))]>;

  def _i_f32 : HSAILInst<(outs GPR32:$dst), (ins f32imm:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (f32 GPR32:$dst), (op (f32 fpimm:$src)))]>;
}

multiclass BinaryOpF32<SDNode op, string asm> {
  def _f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, GPR32:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (f32 GPR32:$dst), (op (f32 GPR32:$src1), (f32 GPR32:$src2)))]>;

  def _ri_f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, f32imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (f32 GPR32:$dst), (op (f32 GPR32:$src1), (f32 fpimm:$src2)))]>;
}

// non-commutative ops
multiclass BinaryNCOpF32<SDNode op, string asm> {
  def _f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, GPR32:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (f32 GPR32:$dst), (op (f32 GPR32:$src1), (f32 GPR32:$src2)))]>;

  def _ri_f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, f32imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (f32 GPR32:$dst), (op (f32 GPR32:$src1), (f32 fpimm:$src2)))]>;

  def _ir_f32 : HSAILInst<(outs GPR32:$dst), (ins f32imm:$src1, GPR32:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (f32 GPR32:$dst), (op (f32 fpimm:$src1), (f32 GPR32:$src2)))]>;
}

multiclass TernaryOpF32<SDNode op, string asm> {
  def _f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, GPR32:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f32 GPR32:$dst), (op (f32 GPR32:$src1), (f32 GPR32:$src2), (f32 GPR32:$src3)))]>;

  def _rri_f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, GPR32:$src2, imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f32 GPR32:$dst), (op (f32 GPR32:$src1), (f32 GPR32:$src2), (f32 fpimm:$src3)))]>;

  def _rir_f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, imm:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f32 GPR32:$dst), (op (f32 GPR32:$src1), (f32 fpimm:$src2), (f32 GPR32:$src3)))]>;

  def _rii_f32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, f32imm:$src2, f32imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f32 GPR32:$dst), (op (f32 GPR32:$src1), (f32 fpimm:$src2), (f32 fpimm:$src3)))]>;

  def _irr_f32 : HSAILInst<(outs GPR32:$dst), (ins imm:$src1, GPR32:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f32 GPR32:$dst), (op (f32 fpimm:$src1), (f32 GPR32:$src2), (f32 GPR32:$src3)))]>;

  def _iir_f32 : HSAILInst<(outs GPR32:$dst), (ins imm:$src1, imm:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f32 GPR32:$dst), (op (f32 fpimm:$src1), (f32 fpimm:$src2), (f32 GPR32:$src3)))]>;

  def _iri_f32 : HSAILInst<(outs GPR32:$dst), (ins imm:$src1, GPR32:$src2, imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f32 GPR32:$dst), (op (f32 fpimm:$src1), (f32 GPR32:$src2), (f32 fpimm:$src3)))]>;
}

////////////////////////////////////////////////////////////////////////////////
// 64bit floating point multiclasses
multiclass UnaryOpF64<SDNode op, string asm> {
  def _f64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (f64 GPR64:$dst), (op (f64 GPR64:$src)))]>;

  def _i_f64 : HSAILInst<(outs GPR64:$dst), (ins f64imm:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (f64 GPR64:$dst), (op (f64 fpimm:$src)))]>;
}

multiclass BinaryOpF64<SDNode op, string asm> {
  def _f64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR64:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (f64 GPR64:$dst), (op (f64 GPR64:$src1), (f64 GPR64:$src2)))]>;

  def _ri_f64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, f64imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (f64 GPR64:$dst), (op (f64 GPR64:$src1), (f64 fpimm:$src2)))]>;
}

multiclass BinaryNCOpF64<SDNode op, string asm> {
  def _f64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR64:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (f64 GPR64:$dst), (op (f64 GPR64:$src1), (f64 GPR64:$src2)))]>;

  def _ri_f64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, f64imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (f64 GPR64:$dst), (op (f64 GPR64:$src1), (f64 fpimm:$src2)))]>;

  def _ir_f64 : HSAILInst<(outs GPR64:$dst), (ins f64imm:$src1, GPR64:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (f64 GPR64:$dst), (op (f64 fpimm:$src1), (f64 GPR64:$src2)))]>;
}

multiclass TernaryOpF64<SDNode op, string asm> {
  def _f64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR64:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f64 GPR64:$dst), (op (f64 GPR64:$src1), (f64 GPR64:$src2), (f64 GPR64:$src3)))]>;

  def _rri_f64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR64:$src2, imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f64 GPR64:$dst), (op (f64 GPR64:$src1), (f64 GPR64:$src2), (f64 fpimm:$src3)))]>;

  def _rir_f64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, imm:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f64 GPR64:$dst), (op (f64 GPR64:$src1), (f64 fpimm:$src2), (f64 GPR64:$src3)))]>;

  def _rii_f64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, f64imm:$src2, f64imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f64 GPR64:$dst), (op (f64 GPR64:$src1), (f64 fpimm:$src2), (f64 fpimm:$src3)))]>;

  def _irr_f64 : HSAILInst<(outs GPR64:$dst), (ins imm:$src1, GPR64:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f64 GPR64:$dst), (op (f64 fpimm:$src1), (f64 GPR64:$src2), (f64 GPR64:$src3)))]>;

  def _iir_f64 : HSAILInst<(outs GPR64:$dst), (ins imm:$src1, imm:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f64 GPR64:$dst), (op (f64 fpimm:$src1), (f64 fpimm:$src2), (f64 GPR64:$src3)))]>;

  def _iri_f64 : HSAILInst<(outs GPR64:$dst), (ins imm:$src1, GPR64:$src2, imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (f64 GPR64:$dst), (op (f64 fpimm:$src1), (f64 GPR64:$src2), (f64 fpimm:$src3)))]>;
}

////////////////////////////////////////////////////////////////////////////////
// 1bit unsigned integer multiclasses
multiclass UnaryOpB1<SDNode op, string asm> {
  def _b1 : HSAILInst<(outs CR:$dst), (ins CR:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i1 CR:$dst), (op (i1 CR:$src)))]>;

  def _i_b1 : HSAILInst<(outs CR:$dst), (ins i1imm:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i1 CR:$dst), (op (i1 imm:$src)))]>;
}
multiclass UnaryPatB1<PatFrag op, string asm> {
  def _b1 : HSAILInst<(outs CR:$dst), (ins CR:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i1 CR:$dst), (op (i1 CR:$src)))]>;

  def _i_b1 : HSAILInst<(outs CR:$dst), (ins i1imm:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i1 CR:$dst), (op (i1 imm:$src)))]>;
}

multiclass BinaryOpB1<SDNode op, string asm> {
  def _b1 : HSAILInst<(outs CR:$dst), (ins CR:$src1, CR:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i1 CR:$dst), (op (i1 CR:$src1), (i1 CR:$src2)))]>;

  def _ri_b1 : HSAILInst<(outs CR:$dst), (ins CR:$src1, i1imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i1 CR:$dst), (op (i1 CR:$src1), (i1 imm:$src2)))]>;
}

multiclass TernaryOpB1<SDNode op, string asm> {
  def _b1 : HSAILInst<(outs CR:$dst), (ins CR:$src1, CR:$src2, CR:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i1 CR:$dst), (op (i1 CR:$src1), (i1 CR:$src2), (i1 CR:$src3)))]>;

  def _rri_b1 : HSAILInst<(outs CR:$dst), (ins CR:$src1, CR:$src2, imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i1 CR:$dst), (op (i1 CR:$src1), (i1 CR:$src2), (i1 imm:$src3)))]>;

  def _rir_b1 : HSAILInst<(outs CR:$dst), (ins CR:$src1, imm:$src2, CR:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i1 CR:$dst), (op (i1 CR:$src1), (i1 imm:$src2), (i1 CR:$src3)))]>;

  def _rii_b1 : HSAILInst<(outs CR:$dst), (ins CR:$src1, i1imm:$src2, i1imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i1 CR:$dst), (op (i1 CR:$src1), (i1 imm:$src2), (i1 imm:$src3)))]>;

  def _irr_b1 : HSAILInst<(outs CR:$dst), (ins imm:$src1, CR:$src2, CR:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i1 CR:$dst), (op (i1 imm:$src1), (i1 CR:$src2), (i1 CR:$src3)))]>;

  def _iir_b1 : HSAILInst<(outs CR:$dst), (ins imm:$src1, imm:$src2, CR:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i1 CR:$dst), (op (i1 imm:$src1), (i1 imm:$src2), (i1 CR:$src3)))]>;

  def _iri_b1 : HSAILInst<(outs CR:$dst), (ins imm:$src1, CR:$src2, imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i1 CR:$dst), (op (i1 imm:$src1), (i1 CR:$src2), (i1 imm:$src3)))]>;
}

////////////////////////////////////////////////////////////////////////////////
// 32bit unsigned integer multiclasses
multiclass UnaryOpU32<SDNode op, string asm> {
  def _u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i32 GPR32:$dst), (op (i32 GPR32:$src)))]>;

  def _i_u32 : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i32 GPR32:$dst), (op (i32 imm:$src)))]>;
}

multiclass UnaryPatU32<PatFrag op, string asm> {
  def _u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i32 GPR32:$dst), (op (i32 GPR32:$src)))]>;

  def _i_u32 : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i32 GPR32:$dst), (op (i32 imm:$src)))]>;
}

multiclass BinaryOpU32<SDNode op, string asm> {
  def _u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, GPR32:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i32 GPR32:$dst), (op (i32 GPR32:$src1), (i32 GPR32:$src2)))]>;

  def _ri_u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, i32imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i32 GPR32:$dst), (op (i32 GPR32:$src1), (i32 imm:$src2)))]>;
}

multiclass BinaryNCOpU32<SDNode op, string asm> {
  def _u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, GPR32:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i32 GPR32:$dst), (op (i32 GPR32:$src1), (i32 GPR32:$src2)))]>;

  def _ri_u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, i32imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i32 GPR32:$dst), (op (i32 GPR32:$src1), (i32 imm:$src2)))]>;

  def _ir_u32 : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src1, GPR32:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i32 GPR32:$dst), (op (i32 imm:$src1), (i32 GPR32:$src2)))]>;
}

multiclass TernaryOpU32<SDNode op, string asm> {
  def _u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, GPR32:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (op (i32 GPR32:$src1), (i32 GPR32:$src2), (i32 GPR32:$src3)))]>;

  def _rri_u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, GPR32:$src2, imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (op (i32 GPR32:$src1), (i32 GPR32:$src2), (i32 imm:$src3)))]>;

  def _rir_u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, imm:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (op (i32 GPR32:$src1), (i32 imm:$src2), (i32 GPR32:$src3)))]>;

  def _rii_u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, i32imm:$src2, i32imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (op (i32 GPR32:$src1), (i32 imm:$src2), (i32 imm:$src3)))]>;

  def _irr_u32 : HSAILInst<(outs GPR32:$dst), (ins imm:$src1, GPR32:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (op (i32 imm:$src1), (i32 GPR32:$src2), (i32 GPR32:$src3)))]>;

  def _iir_u32 : HSAILInst<(outs GPR32:$dst), (ins imm:$src1, imm:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (op (i32 imm:$src1), (i32 imm:$src2), (i32 GPR32:$src3)))]>;

  def _iri_u32 : HSAILInst<(outs GPR32:$dst), (ins imm:$src1, GPR32:$src2, imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (op (i32 imm:$src1), (i32 GPR32:$src2), (i32 imm:$src3)))]>;
}

////////////////////////////////////////////////////////////////////////////////
// 32bit unsigned integer multiclasses
multiclass UnaryOpS32<SDNode op, string asm> {
  def _s32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i32 GPR32:$dst), (op (i32 GPR32:$src)))]>;

  def _i_s32 : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i32 GPR32:$dst), (op (i32 imm:$src)))]>;
}

multiclass UnaryPatS32<PatFrag op, string asm> {
  def _s32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i32 GPR32:$dst), (op (i32 GPR32:$src)))]>;

  def _i_s32 : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i32 GPR32:$dst), (op (i32 imm:$src)))]>;
}

multiclass BinaryOpS32<SDNode op, string asm> {
  def _s32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, GPR32:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i32 GPR32:$dst), (op (i32 GPR32:$src1), (i32 GPR32:$src2)))]>;

  def _ri_s32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, i32imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i32 GPR32:$dst), (op (i32 GPR32:$src1), (i32 imm:$src2)))]>;
}

multiclass BinaryNCOpS32<SDNode op, string asm> {
  def _s32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, GPR32:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i32 GPR32:$dst), (op (i32 GPR32:$src1), (i32 GPR32:$src2)))]>;

  def _ri_s32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, i32imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i32 GPR32:$dst), (op (i32 GPR32:$src1), (i32 imm:$src2)))]>;

  def _ir_s32 : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src1, GPR32:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i32 GPR32:$dst), (op (i32 imm:$src1), (i32 GPR32:$src2)))]>;
}

multiclass TernaryOpS32<SDNode op, string asm> {
  def _s32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, GPR32:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (op (i32 GPR32:$src1), (i32 GPR32:$src2), (i32 GPR32:$src3)))]>;

  def _rri_s32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, GPR32:$src2, imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (op (i32 GPR32:$src1), (i32 GPR32:$src2), (i32 imm:$src3)))]>;

  def _rir_s32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, imm:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (op (i32 GPR32:$src1), (i32 imm:$src2), (i32 GPR32:$src3)))]>;

  def _rii_s32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src1, i32imm:$src2, i32imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (op (i32 GPR32:$src1), (i32 imm:$src2), (i32 imm:$src3)))]>;

  def _irr_s32 : HSAILInst<(outs GPR32:$dst), (ins imm:$src1, GPR32:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (op (i32 imm:$src1), (i32 GPR32:$src2), (i32 GPR32:$src3)))]>;

  def _iir_s32 : HSAILInst<(outs GPR32:$dst), (ins imm:$src1, imm:$src2, GPR32:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (op (i32 imm:$src1), (i32 imm:$src2), (i32 GPR32:$src3)))]>;

  def _iri_s32 : HSAILInst<(outs GPR32:$dst), (ins imm:$src1, GPR32:$src2, imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i32 GPR32:$dst), (op (i32 imm:$src1), (i32 GPR32:$src2), (i32 imm:$src3)))]>;
}

////////////////////////////////////////////////////////////////////////////////
// 64bit unsigned integer multiclasses
multiclass UnaryOpU64<SDNode op, string asm> {
  def _u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src)))]>;

  def _i_u64 : HSAILInst<(outs GPR64:$dst), (ins i64imm:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i64 GPR64:$dst), (op (i64 imm:$src)))]>;
}

multiclass UnaryPatU64<PatFrag op, string asm> {
  def _u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src)))]>;

  def _i_u64 : HSAILInst<(outs GPR64:$dst), (ins i64imm:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i64 GPR64:$dst), (op (i64 imm:$src)))]>;
}

multiclass BinaryOpU64<SDNode op, string asm> {
  def _u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR64:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src1), (i64 GPR64:$src2)))]>;

  def _ri_u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, i64imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src1), (i64 imm:$src2)))]>;
}

multiclass BinaryNCOpU64<SDNode op, string asm> {
  def _u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR64:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src1), (i64 GPR64:$src2)))]>;

  def _ri_u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, i64imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src1), (i64 imm:$src2)))]>;

  def _ir_u64 : HSAILInst<(outs GPR64:$dst), (ins i64imm:$src1, GPR64:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (op (i64 imm:$src1), (i64 GPR64:$src2)))]>;
}

multiclass ShiftOpU64<SDNode op, string asm> {
  def _u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR32:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src1), (i32 GPR32:$src2)))]>;

  def _ri_u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, i32imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src1), (i32 imm:$src2)))]>;

  def _ir_u64 : HSAILInst<(outs GPR64:$dst), (ins i64imm:$src1, GPR32:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (op (i64 imm:$src1), (i32 GPR32:$src2)))]>;

  def _ri64_u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, i64imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src1), (i64 imm:$src2)))]>;
}

multiclass TernaryOpU64<SDNode op, string asm> {
  def _u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR64:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src1), (i64 GPR64:$src2), (i64 GPR64:$src3)))]>;

  def _rri_u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR64:$src2, imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src1), (i64 GPR64:$src2), (i64 imm:$src3)))]>;

  def _rir_u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, imm:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src1), (i64 imm:$src2), (i64 GPR64:$src3)))]>;

  def _rii_u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, i64imm:$src2, i64imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src1), (i64 imm:$src2), (i64 imm:$src3)))]>;

  def _irr_u64 : HSAILInst<(outs GPR64:$dst), (ins imm:$src1, GPR64:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (op (i64 imm:$src1), (i64 GPR64:$src2), (i64 GPR64:$src3)))]>;

  def _iir_u64 : HSAILInst<(outs GPR64:$dst), (ins imm:$src1, imm:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (op (i64 imm:$src1), (i64 imm:$src2), (i64 GPR64:$src3)))]>;

  def _iri_u64 : HSAILInst<(outs GPR64:$dst), (ins imm:$src1, GPR64:$src2, imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (op (i64 imm:$src1), (i64 GPR64:$src2), (i64 imm:$src3)))]>;
}

////////////////////////////////////////////////////////////////////////////////
// 64bit unsigned integer multiclasses
multiclass UnaryOpS64<SDNode op, string asm> {
  def _s64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src)))]>;

  def _i_s64 : HSAILInst<(outs GPR64:$dst), (ins i64imm:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i64 GPR64:$dst), (op (i64 imm:$src)))]>;
}

multiclass UnaryPatS64<PatFrag op, string asm> {
  def _s64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src)))]>;

  def _i_s64 : HSAILInst<(outs GPR64:$dst), (ins i64imm:$src),
      !strconcat(asm, "\t $dst, $src"),
      [(set (i64 GPR64:$dst), (op (i64 imm:$src)))]>;
}

multiclass BinaryOpS64<SDNode op, string asm> {
  def _s64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR64:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src1), (i64 GPR64:$src2)))]>;

  def _ri_s64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, i64imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src1), (i64 imm:$src2)))]>;
}

multiclass BinaryNCOpS64<SDNode op, string asm> {
  def _s64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR64:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src1), (i64 GPR64:$src2)))]>;

  def _ri_s64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, i64imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src1), (i64 imm:$src2)))]>;

  def _ir_s64 : HSAILInst<(outs GPR64:$dst), (ins i64imm:$src1, GPR64:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (op (i64 imm:$src1), (i64 GPR64:$src2)))]>;
}

multiclass ShiftOpS64<SDNode op, string asm> {
  def _s64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR32:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src1), (i32 GPR32:$src2)))]>;

  def _ri_s64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, i32imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src1), (i32 imm:$src2)))]>;

  def _64_s64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR64:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src1), (i64 GPR64:$src2)))]>;

  def _ri64_s64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, i64imm:$src2),
      !strconcat(asm, "\t $dst, $src1, $src2"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src1), (i64 imm:$src2)))]>;
}

multiclass TernaryOpS64<SDNode op, string asm> {
  def _s64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR64:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src1), (i64 GPR64:$src2), (i64 GPR64:$src3)))]>;

  def _rri_s64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, GPR64:$src2, imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src1), (i64 GPR64:$src2), (i64 imm:$src3)))]>;

  def _rir_s64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, imm:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src1), (i64 imm:$src2), (i64 GPR64:$src3)))]>;

  def _rii_s64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src1, i64imm:$src2, i64imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (op (i64 GPR64:$src1), (i64 imm:$src2), (i64 imm:$src3)))]>;

  def _irr_s64 : HSAILInst<(outs GPR64:$dst), (ins imm:$src1, GPR64:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (op (i64 imm:$src1), (i64 GPR64:$src2), (i64 GPR64:$src3)))]>;

  def _iir_s64 : HSAILInst<(outs GPR64:$dst), (ins imm:$src1, imm:$src2, GPR64:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (op (i64 imm:$src1), (i64 imm:$src2), (i64 GPR64:$src3)))]>;

  def _iri_s64 : HSAILInst<(outs GPR64:$dst), (ins imm:$src1, GPR64:$src2, imm:$src3),
      !strconcat(asm, "\t $dst, $src1, $src2, $src3"),
      [(set (i64 GPR64:$dst), (op (i64 imm:$src1), (i64 GPR64:$src2), (i64 imm:$src3)))]>;
}

// Begin pointer param loads/stores
// Utility string concat class
class AsmStr<string a="", string b="", string c="", string d="", string e=""> {
  string s =  !strconcat(a,!strconcat(b,!strconcat(c,!strconcat(d,e))));
}

// Predicate defs
def HSAILisKernel         : Predicate<"isKernelFunc()">;
def HSAILisNotKernel      : Predicate<"!isKernelFunc()">;

////////////////////////////////////////////////////////////////////////////////
// All basic int and fp arithmetic instructions, shifts, bit manipulation,
// moves, cmoves and multimedia like unpack.
// If we have full support of multimedia we would need to extract latter into a
// separate file.
include "HSAILArithmetic.td"

////////////////////////////////////////////////////////////////////////////////
// All comparisons and testing, including class_f32|64
include "HSAILComparisons.td"

////////////////////////////////////////////////////////////////////////////////
// All atomic operations
include "HSAILAtomics.td"

////////////////////////////////////////////////////////////////////////////////
// Special HSAIL operations like NDRange queries, barriers, syncs etc
include "HSAILSpecial.td"

////////////////////////////////////////////////////////////////////////////////
// All control transfer instructions including call, ret and branches
include "HSAILControlFlow.td"

////////////////////////////////////////////////////////////////////////////////
// All conversions including bitcasts resulting in plain moves
include "HSAILConversions.td" 

////////////////////////////////////////////////////////////////////////////////
// All loads and stores including kernarg and arg operations, argscopes and
// params. Image and sampler parameter manipulation operations are also here.
// stof and ftos operations are here as well.
include "HSAILLoadStore.td"

////////////////////////////////////////////////////////////////////////////////
// All image operations except image parameters handling
include "HSAILImages.td"

////////////////////////////////////////////////////////////////////////////////
// Fused opcodes folding a complex dag into a single instruction or a short
// instruction sequence, like fma or rsqrt.
// This file is for optimization purposes. Its inclusion is not required for
// valid code generation. For example, rsqrt is defined twice - first time in
// the HSAILArithmetic.td to be used with intrinsic expansion and second time
// here, but with a pattern folding div and sqrt into a single instruction.
// For that reason HSAILFusion.td is always last, so no other pattern would
// accidentally refer any of its opcodes.
include "HSAILFusion.td"
