////////////////////////////////////////////////////////////////////////////////
// stof, ftos -- not matched, inserted in MachineInstr lowering
// 32 bit

def stof_inst : HSAILInstSegCvt_1Op<"stof", BrigOpcode.STOF>;
def ftos_inst : HSAILInstSegCvt_1Op<"ftos", BrigOpcode.FTOS>;

class STOFPat<ValueType destvt> : Pat<
  (STOFComplexPat BrigSegment:$segment,
                  i1:$nonull,
                  untyped:$src0,
                  BrigTypeX:$destType,
                  BrigTypeX:$srcType),
  (destvt (stof_inst $segment, $nonull, $src0, $destType, $srcType))
>;

class FTOSPat<ValueType destvt> : Pat<
  (FTOSComplexPat BrigSegment:$segment,
                  i1:$nonull,
                  untyped:$src0,
                  BrigTypeX:$destType,
                  BrigTypeX:$srcType),
  (destvt (ftos_inst $segment, $nonull, $src0, $destType, $srcType))
>;

// TODO: Should probably just select these in HSAILISelDAGToDAG. We
// aren't really saving effort with this.
def : STOFPat<i32>;
def : STOFPat<i64>;

def : FTOSPat<i32>;
def : FTOSPat<i64>;


// segmentp
multiclass SegmentPInst<Intrinsic intr, string asm> {
  def _r_addr32 : HSAILInst<(outs CR:$dest), (ins GPR32:$src),
      asm#"_b1_u32"#"\t $dest, $src",
      [(set (i1 CR:$dest), (intr (i32 GPR32:$src)))]>;

  def _i_addr32 : HSAILInst<(outs CR:$dest), (ins i32imm:$src),
      asm#"_b1_u32"#"\t $dest, $src",
      [(set (i1 CR:$dest), (intr (i32 imm:$src)))]>;

  def _r : HSAILInst<(outs CR:$dest), (ins GPR64:$src),
      asm#"_b1_u64"#"\t $dest, $src",
      [(set (i1 CR:$dest), (intr (i64 GPR64:$src)))]>;

  def _i : HSAILInst<(outs CR:$dest), (ins i64imm:$src),
      asm#"_b1_u64"#"\t $dest, $src",
      [(set (i1 CR:$dest), (intr (i64 imm:$src)))]>;
}

defm segmentp_global  : SegmentPInst<int_HSAIL_segmentp_global, "segmentp_global">;
defm segmentp_local   : SegmentPInst<int_HSAIL_segmentp_local, "segmentp_group">;
defm segmentp_private : SegmentPInst<int_HSAIL_segmentp_private, "segmentp_private">;

let isNotDuplicable = 1, hasCtrlDep = 1, hasSideEffects = 1 in {
  def arg_decl : HSAILInst<(outs), (ins PtrRC:$symbol, BrigTypeX:$TypeLength, i32imm:$size,
                                    i32imm:$alignment),
                                    "align $alignment arg_$TypeLength\t$symbol[$size]", []>;
}

class LdStVectorMap<string op, int size> {
  string opcode   = op;
  int    vec_size = size;
}

def getLdStVectorOpcode : InstrMapping {
  let FilterClass = "LdStVectorMap";
  let RowFields   = ["opcode"];
  let ColFields   = ["vec_size"];
  let KeyCol      = ["1"];
  let ValueCols   = [["1"], ["2"], ["3"], ["4"]];
}

// FIXME: If the MEMOP isn't explicitly typed in output, counts as
// wrong number of operands.
class LDPat<Instruction inst, ValueType vt> : Pat <
  (vt (unindexedload (LoadAddr MEMOP:$address,
                               BrigSegment:$segment,
                               BrigAlignment:$align,
                               BrigTypeX:$TypeLength,
                               BrigWidth:$width,
                               BrigMemoryModifierMask:$mask))),
  (inst MEMOP:$address, $TypeLength, $segment, $align, $width, $mask)
>;


// XXX - Dummy argument since something is required for a multiclass.
multiclass HSAIL_LD<int Dummy> {
  // TODO: We should define a single ld opcode with all 4 output
  // registers. We will then just set the ones that are actually used.

  // We define the output registers to be unknown. The used register
  // class will be selected based on the used type.
  def _v1 : LD<"ld", BrigOpcode.LD, (outs unknown:$dest)>, LdStVectorMap<NAME, 1>;
  def _v2 : LD<"ld_v2", BrigOpcode.LD, (outs Vec2Op:$dest)>, LdStVectorMap<NAME, 2>;
  def _v3 : LD<"ld_v3", BrigOpcode.LD, (outs Vec3Op:$dest)>, LdStVectorMap<NAME, 3>;
  def _v4 : LD<"ld_v4", BrigOpcode.LD, (outs Vec4Op:$dest)>, LdStVectorMap<NAME, 4>;
}

defm ld : HSAIL_LD<0>;

// TODO: Promote float loads to integers.
def : LDPat<ld_v1, i32>;
def : LDPat<ld_v1, f32>;
def : LDPat<ld_v1, i64>;
def : LDPat<ld_v1, f64>;



let hasSideEffects = 1, hasCtrlDep = 1 in {
  // It is not safe to move ld_arg as it can be in an argscope
  defm rarg_ld : HSAIL_LD<0>;
}

class STPat<Instruction inst, ValueType vt> : Pat <
  (st (vt (GPROrImm vt:$src)),
      (StoreAddr MEMOP:$address,
                 BrigSegment:$segment,
                 BrigAlignment:$alignment,
                 BrigTypeX:$TypeLength)),
  (inst $src, MEMOP:$address, $TypeLength, $segment, $alignment)
>;

multiclass HSAIL_ST<int dummy> {
  def _v1 : ST<"st", BrigOpcode.ST,
    (ins unknown:$src, MEMOP:$address, BrigTypeX:$TypeLength,
         BrigSegment:$segment, BrigAlignment:$align)>,
    LdStVectorMap<NAME, 1>;
  def _v2 : ST<"st_v2", BrigOpcode.ST,
    (ins Vec2Op:$src, MEMOP:$address, BrigTypeX:$TypeLength,
         BrigSegment:$segment, BrigAlignment:$align)>,
    LdStVectorMap<NAME, 2>;
  def _v3 : ST<"st_v3", BrigOpcode.ST,
    (ins Vec3Op:$src, MEMOP:$address, BrigTypeX:$TypeLength,
         BrigSegment:$segment, BrigAlignment:$align)>,
    LdStVectorMap<NAME, 3>;
  def _v4 : ST<"st_v4", BrigOpcode.ST,
    (ins Vec4Op:$src, MEMOP:$address, BrigTypeX:$TypeLength,
      BrigSegment:$segment, BrigAlignment:$align)>,
    LdStVectorMap<NAME, 4>;
}

defm st : HSAIL_ST<0>;

// TODO: Promote float stores to integers.
def : STPat<st_v1, i32>;
def : STPat<st_v1, f32>;
def : STPat<st_v1, i64>;
def : STPat<st_v1, f64>;


// We need pseudos to implement condition register spilling due to a
// limitation storeRegToStackSlot currently has where it assumes only
// 1 instruction is created for spilling.
let isPseudo = 1 in {
  def spill_b1 : ST<"spill_b1", BrigOpcode.NOP,
    (ins CR:$src, MEMOP:$address,
         BrigTypeX:$TypeLength, BrigSegment:$segment,
         BrigAlignment:$align)
  >;

  def restore_b1 : LD<"restore_b1", BrigOpcode.NOP,
    (outs CR:$dest)
  >;
}

////////////////////////////////////////////////////////////////////////////////
// load memory address

def lda_inst : HSAILInstAddr_1Op<"lda", BrigOpcode.LDA>;
