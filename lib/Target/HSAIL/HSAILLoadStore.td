////////////////////////////////////////////////////////////////////////////////
// stof, ftos -- not matched, inserted in MachineInstr lowering
// 32 bit
def global_stof_u32 : HSAILInst<(outs GPR32:$dest), (ins GPR32:$src),
                     "stof_global_u32\t$dest, $src",
                     []>;

def group_stof_u32 : HSAILInst<(outs GPR32:$dest), (ins GPR32:$src),
                     "stof_group_u32\t$dest, $src",
                     []>;

def constant_stof_u32 : HSAILInst<(outs GPR32:$dest), (ins GPR32:$src),
                     "stof_readonly_u32\t$dest, $src",
                     []>;

def private_stof_u32 : HSAILInst<(outs GPR32:$dest), (ins GPR32:$src),
                     "stof_private_u32\t$dest, $src",
                     []>;

def global_ftos_u32 : HSAILInst<(outs GPR32:$dest), (ins GPR32:$src),
                     "ftos_global_u32\t$dest, $src",
                     []>;

def group_ftos_u32 : HSAILInst<(outs GPR32:$dest), (ins GPR32:$src),
                     "ftos_group_u32\t$dest, $src",
                     []>;

def constant_ftos_u32 : HSAILInst<(outs GPR32:$dest), (ins GPR32:$src),
                     "ftos_readonly_u32\t$dest, $src",
                     []>;

def private_ftos_u32 : HSAILInst<(outs GPR32:$dest), (ins GPR32:$src),
                     "ftos_private_u32\t$dest, $src",
                     []>;
// 64 bit
def global_stof_u64 : HSAILInst<(outs GPR64:$dest), (ins GPR64:$src),
                     "stof_global_u64\t$dest, $src",
                     []>;

def group_stof_u64 : HSAILInst<(outs GPR64:$dest), (ins GPR64:$src),
                     "stof_group_u64\t$dest, $src",
                     []>;

def constant_stof_u64 : HSAILInst<(outs GPR64:$dest), (ins GPR64:$src),
                     "stof_readonly_u64\t$dest, $src",
                     []>;

def private_stof_u64 : HSAILInst<(outs GPR64:$dest), (ins GPR64:$src),
                     "stof_private_u64\t$dest, $src",
                     []>;

def global_ftos_u64 : HSAILInst<(outs GPR64:$dest), (ins GPR64:$src),
                     "ftos_global_u64\t$dest, $src",
                     []>;

def group_ftos_u64 : HSAILInst<(outs GPR64:$dest), (ins GPR64:$src),
                     "ftos_group_u64\t$dest, $src",
                     []>;

def constant_ftos_u64 : HSAILInst<(outs GPR64:$dest), (ins GPR64:$src),
                     "ftos_readonly_u64\t$dest, $src",
                     []>;

def private_ftos_u64 : HSAILInst<(outs GPR64:$dest), (ins GPR64:$src),
                     "ftos_private_u64\t$dest, $src",
                     []>;

// stof/ftos for address space casting.
multiclass AddrSpaceCastInst<Intrinsic intr, string asm> {
  def _r_addr32 : HSAILInst<(outs GPR32:$dest), (ins GPR32:$src),
      asm#"_u32_u32"#"\t $dest, $src",
      [(set (i32 GPR32:$dest), (intr (i32 GPR32:$src)))]>, Requires<[In32BitMode]>;

  def _i_addr32 : HSAILInst<(outs GPR32:$dest), (ins i32imm:$src),
      asm#"_u32_u32"#"\t $dest, $src",
      [(set (i32 GPR32:$dest), (intr (i32 imm:$src)))]>, Requires<[In32BitMode]>;

  def _r_addr64 : HSAILInst<(outs GPR64:$dest), (ins GPR64:$src),
      asm#"_u64_u64"#"\t $dest, $src",
      [(set (i64 GPR64:$dest), (intr (i64 GPR64:$src)))]>, Requires<[In64BitMode]>;

  def _i_addr64 : HSAILInst<(outs GPR64:$dest), (ins i64imm:$src),
      asm#"_u64_u64"#"\t $dest, $src",
      [(set (i64 GPR64:$dest), (intr (i64 imm:$src)))]>, Requires<[In64BitMode]>;
}

multiclass FToSInst32<Intrinsic intr, string asm> {
  def _r_addr32 : HSAILInst<(outs GPR32:$dest), (ins GPR32:$src),
      asm#"_u32_u32"#"\t $dest, $src",
      [(set (i32 GPR32:$dest), (intr (i32 GPR32:$src)))]>, Requires<[In32BitMode]>;

  def _i_addr32 : HSAILInst<(outs GPR32:$dest), (ins i32imm:$src),
      asm#"_u32_u32"#"\t $dest, $src",
      [(set (i32 GPR32:$dest), (intr (i32 imm:$src)))]>, Requires<[In32BitMode]>;

  def _r_addr64 : HSAILInst<(outs GPR32:$dest), (ins GPR64:$src),
      asm#"_u32_u64"#"\t $dest, $src",
      [(set (i32 GPR32:$dest), (intr (i64 GPR64:$src)))]>, Requires<[In64BitMode]>;

  def _i_addr64 : HSAILInst<(outs GPR32:$dest), (ins i64imm:$src),
      asm#"_u32_u64"#"\t $dest, $src",
      [(set (i32 GPR32:$dest), (intr (i64 imm:$src)))]>, Requires<[In64BitMode]>;
}

multiclass SToFInst32<Intrinsic intr, string asm> {
  def _r_addr32 : HSAILInst<(outs GPR32:$dest), (ins GPR32:$src),
      asm#"_u32_u32"#"\t $dest, $src",
      [(set (i32 GPR32:$dest), (intr (i32 GPR32:$src)))]>, Requires<[In32BitMode]>;

  def _i_addr32 : HSAILInst<(outs GPR32:$dest), (ins i32imm:$src),
      asm#"_u32_u32"#"\t $dest, $src",
      [(set (i32 GPR32:$dest), (intr (i32 imm:$src)))]>, Requires<[In32BitMode]>;

  def _r_addr64 : HSAILInst<(outs GPR64:$dest), (ins GPR32:$src),
      asm#"_u64_u32"#"\t $dest, $src",
      [(set (i64 GPR64:$dest), (intr (i32 GPR32:$src)))]>, Requires<[In64BitMode]>;

  def _i_addr64 : HSAILInst<(outs GPR64:$dest), (ins i32imm:$src),
      asm#"_u64_u32"#"\t $dest, $src",
      [(set (i64 GPR64:$dest), (intr (i32 imm:$src)))]>, Requires<[In64BitMode]>;
}

defm stof_global  : AddrSpaceCastInst<int_HSAIL_addrspacecast_g2f, "stof_global">;
defm ftos_global  : AddrSpaceCastInst<int_HSAIL_addrspacecast_f2g, "ftos_global">;

defm stof_local   : SToFInst32<int_HSAIL_addrspacecast_l2f, "stof_group">;
defm stof_private : SToFInst32<int_HSAIL_addrspacecast_p2f, "stof_private">;

defm ftos_local   : FToSInst32<int_HSAIL_addrspacecast_f2l, "ftos_group">;
defm ftos_private : FToSInst32<int_HSAIL_addrspacecast_f2p, "ftos_private">;


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

class LD<string opName, dag outs, int vecSize> : HSAILInst<outs,
  (ins MEMOP:$address,
       BrigTypeX:$TypeLength,
       BrigSegment:$segment,
       BrigWidth:$width,
       BrigMemoryModifierMask:$mask),
    opName#"$segment$width$mask$TypeLength\t$dest, $address", []>,
    LdStVectorMap<NAME, vecSize> {
  let isLoad = 1;
  let mayLoad = 1;
  let isStore = 0;
  let mayStore = 0;
  let hasSideEffects = 0;
}

// FIXME: If the MEMOP isn't explicitly typed in output, counts as
// wrong number of operands.
class LDPat<Instruction inst, ValueType vt> : Pat <
  (vt (unindexedload (LoadAddr MEMOP:$address,
                               BrigSegment:$segment,
                               BrigTypeX:$TypeLength,
                               BrigWidth:$width,
                               BrigMemoryModifierMask:$mask))),
  (inst MEMOP:$address, $TypeLength, $segment, $width, $mask)
>;


// XXX - Dummy argument since something is required for a multiclass.
multiclass HSAIL_LD<int Dummy> {
  // TODO: We should define a single ld opcode with all 4 output
  // registers. We will then just set the ones that are actually used.

  // We define the output registers to be unknown. The used register
  // class will be selected based on the used type.
  def _v1 : LD<"ld", (outs unknown:$dest), 1>;
  def _v2 : LD<"ld_v2", (outs Vec2Op:$dest), 2>;
  def _v3 : LD<"ld_v3", (outs Vec3Op:$dest), 3>;
  def _v4 : LD<"ld_v4", (outs Vec4Op:$dest), 4>;
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

let mayLoad = 1, isPseudo = 1, hasSideEffects = 0 in {
  def ld_b1 : HSAILInst<(outs CR:$dest), (ins MEMOP:$address, BrigTypeX:$TypeLength,
                                              BrigWidth:$width, BrigMemoryModifierMask:$mask),
                              "ld_b1$width$mask$TypeLength\t$dest, $address", []>;
}


class ST<string opName, dag ins, int vecSize> :
  HSAILInst<(outs),
    ins,
    opName#"$segment$TypeLength\t$src, $address",
    []>,
    LdStVectorMap<NAME, vecSize> {
  let isLoad = 0;
  let mayLoad = 0;
  let isStore = 1;
  let mayStore = 1;
  let hasSideEffects = 0;
}

class STPat<Instruction inst, ValueType vt> : Pat <
  (st (vt (GPROrImm vt:$src)),
      (StoreAddr MEMOP:$address,
                BrigSegment:$segment,
                BrigTypeX:$TypeLength)),
  (inst $src, MEMOP:$address, $TypeLength, $segment)
>;

////////////////////////////////////////////////////////////////////////////////
// st (integer, singed and unsigned, 32-bit and 64-bit;
//     float, 32-bit and 64-bit; addr, 32bit and 64-bit)
multiclass HSAIL_ST<int dummy> {
  def _v1 : ST<"st", (ins unknown:$src, MEMOP:$address, BrigTypeX:$TypeLength, BrigSegment:$segment), 1>;
  def _v2 : ST<"st_v2", (ins Vec2Op:$src, MEMOP:$address, BrigTypeX:$TypeLength, BrigSegment:$segment), 2>;
  def _v3 : ST<"st_v3", (ins Vec3Op:$src, MEMOP:$address, BrigTypeX:$TypeLength, BrigSegment:$segment), 3>;
  def _v4 : ST<"st_v4", (ins Vec4Op:$src, MEMOP:$address, BrigTypeX:$TypeLength, BrigSegment:$segment), 4>;
}

// For segments where the address is 32/64-bit depending on machine model.
defm st_32 : HSAIL_ST<0>;
defm st_64 : HSAIL_ST<0>;

// TODO: Promote float stores to integers.
def : STPat<st_32_v1, i32>;
def : STPat<st_32_v1, f32>;
def : STPat<st_64_v1, i64>;
def : STPat<st_64_v1, f64>;

// For segments where the address is 32-bit in both models.
defm st_32_ptr32 : HSAIL_ST<0>;
defm st_64_ptr32 : HSAIL_ST<0>;

let mayStore = 1, isPseudo = 1, hasSideEffects = 0 in {
  def st_b1_ptr32 : HSAILInst<(outs), (ins CR:$src0, MEMOP:$address, BrigTypeX:$TypeLength),
                              "st_b1$TypeLength\t$src0, $address", []>;
}

////////////////////////////////////////////////////////////////////////////////
// load memory address

class LdaAddr<RegisterClass RC, DAGOperand MPtr>
      : HSAILInst<(outs RC:$dest), (ins MPtr:$address, BrigSegment:$segment),
      "lda_$segment\t$dest, $address", []> {
  let neverHasSideEffects = 1;
}

def lda_32 : LdaAddr<GPR32, MEMOP>;
def lda_64 : LdaAddr<GPR64, MEMOP>;

def : Pat<(i32 (IL_lda_group    ADDR:$address)), (lda_32 ADDR:$address, BrigSegment.GROUP)>;
def : Pat<(i32 (IL_lda_private  ADDR:$address)), (lda_32 ADDR:$address, BrigSegment.PRIVATE)>;

def : Pat<(i32 (IL_lda_flat     ADDR:$address)), (lda_32 ADDR:$address, BrigSegment.FLAT)>, Requires<[In32BitMode]>;
def : Pat<(i64 (IL_lda_flat     ADDR:$address)), (lda_64 ADDR:$address, BrigSegment.FLAT)>, Requires<[In64BitMode]>;

def : Pat<(i32 (IL_lda_global   ADDR:$address)), (lda_32 ADDR:$address, BrigSegment.GLOBAL)>, Requires<[In32BitMode]>;
def : Pat<(i64 (IL_lda_global   ADDR:$address)), (lda_64 ADDR:$address, BrigSegment.GLOBAL)>, Requires<[In64BitMode]>;

def : Pat<(i32 (IL_lda_readonly ADDR:$address)), (lda_32 ADDR:$address, BrigSegment.READONLY)>, Requires<[In32BitMode]>;
def : Pat<(i64 (IL_lda_readonly ADDR:$address)), (lda_64 ADDR:$address, BrigSegment.READONLY)>, Requires<[In64BitMode]>;
