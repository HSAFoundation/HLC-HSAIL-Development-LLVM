////////////////////////////////////////////////////////////////////////////////
// stof, ftos -- not matched, inserted in MachineInstr lowering 
// 32 bit
def global_stof_u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
                     "stof_global_u32\t$dst, $src",
                     []>;

def group_stof_u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
                     "stof_group_u32\t$dst, $src",
                     []>;

def constant_stof_u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
                     "stof_readonly_u32\t$dst, $src",
                     []>;

def private_stof_u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
                     "stof_private_u32\t$dst, $src",
                     []>;

def global_ftos_u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
                     "ftos_global_u32\t$dst, $src",
                     []>;

def group_ftos_u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
                     "ftos_group_u32\t$dst, $src",
                     []>;

def constant_ftos_u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
                     "ftos_readonly_u32\t$dst, $src",
                     []>;

def private_ftos_u32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
                     "ftos_private_u32\t$dst, $src",
                     []>;
// 64 bit
def global_stof_u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
                     "stof_global_u64\t$dst, $src",
                     []>;

def group_stof_u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
                     "stof_group_u64\t$dst, $src",
                     []>;

def constant_stof_u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
                     "stof_readonly_u64\t$dst, $src",
                     []>;

def private_stof_u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
                     "stof_private_u64\t$dst, $src",
                     []>;

def global_ftos_u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
                     "ftos_global_u64\t$dst, $src",
                     []>;

def group_ftos_u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
                     "ftos_group_u64\t$dst, $src",
                     []>;

def constant_ftos_u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
                     "ftos_readonly_u64\t$dst, $src",
                     []>;

def private_ftos_u64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
                     "ftos_private_u64\t$dst, $src",
                     []>;


// stof/ftos for address space casting.
multiclass AddrSpaceCastInst<Intrinsic intr, string asm> {
  def _r_addr32 : HSAILInst<(outs GPR32:$dst), (ins GPR32:$src),
      asm#"_u32_u32"#"\t $dst, $src",
      [(set (i32 GPR32:$dst), (intr (i32 GPR32:$src)))]>;

  def _i_addr32 : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src),
      asm#"_u32_u32"#"\t $dst, $src",
      [(set (i32 GPR32:$dst), (intr (i32 imm:$src)))]>;

  def _r_addr64 : HSAILInst<(outs GPR64:$dst), (ins GPR64:$src),
      asm#"_u64_u64"#"\t $dst, $src",
      [(set (i64 GPR64:$dst), (intr (i64 GPR64:$src)))]>;

  def _i_addr64 : HSAILInst<(outs GPR64:$dst), (ins i64imm:$src),
      asm#"_u64_u64"#"\t $dst, $src",
      [(set (i64 GPR64:$dst), (intr (i64 imm:$src)))]>;
}

defm stof_global  : AddrSpaceCastInst<int_HSAIL_addrspacecast_g2f, "stof_global">;
defm stof_local   : AddrSpaceCastInst<int_HSAIL_addrspacecast_l2f, "stof_group">;
defm stof_private : AddrSpaceCastInst<int_HSAIL_addrspacecast_p2f, "stof_private">;
defm ftos_global  : AddrSpaceCastInst<int_HSAIL_addrspacecast_f2g, "ftos_global">;
defm ftos_local   : AddrSpaceCastInst<int_HSAIL_addrspacecast_f2l, "ftos_group">;
defm ftos_private : AddrSpaceCastInst<int_HSAIL_addrspacecast_f2p, "ftos_private">;


// segmentp
multiclass SegmentPInst<Intrinsic intr, string asm> {
  def _r_addr32 : HSAILInst<(outs CR:$dst), (ins GPR32:$src),
      asm#"_b1_u32"#"\t $dst, $src",
      [(set (i1 CR:$dst), (intr (i32 GPR32:$src)))]>;

  def _i_addr32 : HSAILInst<(outs CR:$dst), (ins i32imm:$src),
      asm#"_b1_u32"#"\t $dst, $src",
      [(set (i1 CR:$dst), (intr (i32 imm:$src)))]>;

  def _r : HSAILInst<(outs CR:$dst), (ins GPR64:$src),
      asm#"_b1_u64"#"\t $dst, $src",
      [(set (i1 CR:$dst), (intr (i64 GPR64:$src)))]>;

  def _i : HSAILInst<(outs CR:$dst), (ins i64imm:$src),
      asm#"_b1_u64"#"\t $dst, $src",
      [(set (i1 CR:$dst), (intr (i64 imm:$src)))]>;
}

defm segmentp_global  : SegmentPInst<int_HSAIL_segmentp_global, "segmentp_global">;
defm segmentp_local   : SegmentPInst<int_HSAIL_segmentp_local, "segmentp_group">;
defm segmentp_private : SegmentPInst<int_HSAIL_segmentp_private, "segmentp_private">;

let isNotDuplicable = 1, hasCtrlDep = 1, hasSideEffects = 1 in {
  def arg_decl : HSAILInst<(outs ), (ins PtrRC:$v, BRIG_TYPE_OPND:$brig_type, i32imm:$size,
                                     i32imm:$alignnment), "", []>;
}

////////////////////////////////////////////////////////////////////////////////
// ld (integer, singed and unsigned, 32-bit and 64-bit;
//     float, 32-bit and 64-bit; addr, 32bit and 64-bit)
multiclass HSAIL_LD<RegisterClass RC, DAGOperand MPtr>
{
  let hasAddress = 1, isLoad = 1, mayLoad = 1, hasSideEffects = 0 in {
    let addressOpNum = 1 in {
      def _v1: HSAILInst<(outs RC:$dst),
                         (ins MPtr:$ptr, BRIG_TYPE_OPND:$t, WIDTH_OPND:$w,
                              CONST_OPERAND:$isConst),
                        "ld\t$dst, $ptr", []>;
    }

    let addressOpNum = 2 in {
      def _v2 : HSAILInst<(outs RC:$dst1, RC:$dst2),
                          (ins MPtr:$ptr, BRIG_TYPE_OPND:$t, WIDTH_OPND:$w,
                               CONST_OPERAND:$isConst),
                           "ld_v2\t($dst1, $dst2 ), $ptr", []>;
    }
    let addressOpNum = 3 in {
      def _v3 : HSAILInst<(outs RC:$dst1, RC:$dst2, RC:$dst3),
                          (ins MPtr:$ptr, BRIG_TYPE_OPND:$t, WIDTH_OPND:$w,
                               CONST_OPERAND:$isConst),
                           "ld_v3\t($dst1, $dst2, $dst3 ), $ptr", []>;
    }
    let addressOpNum = 4 in {
      def _v4 : HSAILInst<(outs RC:$dst1, RC:$dst2, RC:$dst3, RC:$dst4),
                          (ins MPtr:$ptr, BRIG_TYPE_OPND:$t, WIDTH_OPND:$w,
                               CONST_OPERAND:$isConst),
                           "ld_v4\t($dst1, $dst2, $dst3, $dst4 ), $ptr", []>;
    }
  }
}

class LoadIsPtr32<PatFrag pf> : PatFrag<(ops node:$ptr), (pf node:$ptr),
                            [{ return MemOpHasPtr32(N); }]>;

class LoadIsPtrNN<PatFrag pf> : PatFrag<(ops node:$ptr), (pf node:$ptr),
                            [{ return !MemOpHasPtr32(N); }]>;

// For segments where the address is 32/64-bit depending on machine model.
defm ld_32 : HSAIL_LD<GPR32, MEMOP>;
defm ld_64 : HSAIL_LD<GPR64, MEMOP>;

def : Pat<(i32 (LoadIsPtrNN<load>        ADDR:$ptr)), (ld_32_v1 ADDR:$ptr, 3)>;
def : Pat<(f32 (LoadIsPtrNN<load>        ADDR:$ptr)), (ld_32_v1 ADDR:$ptr, 10)>;
def : Pat<(i32 (LoadIsPtrNN<extloadi8>   ADDR:$ptr)), (ld_32_v1 ADDR:$ptr, 13)>;
def : Pat<(i32 (LoadIsPtrNN<sextloadi8>  ADDR:$ptr)), (ld_32_v1 ADDR:$ptr, 5)>;
def : Pat<(i32 (LoadIsPtrNN<zextloadi8>  ADDR:$ptr)), (ld_32_v1 ADDR:$ptr, 1)>;
def : Pat<(i32 (LoadIsPtrNN<extloadi16>  ADDR:$ptr)), (ld_32_v1 ADDR:$ptr, 14)>;
def : Pat<(i32 (LoadIsPtrNN<sextloadi16> ADDR:$ptr)), (ld_32_v1 ADDR:$ptr, 6)>;
def : Pat<(i32 (LoadIsPtrNN<zextloadi16> ADDR:$ptr)), (ld_32_v1 ADDR:$ptr, 2)>;
def : Pat<(i64 (LoadIsPtrNN<load>        ADDR:$ptr)), (ld_64_v1 ADDR:$ptr, 4)>;
def : Pat<(f64 (LoadIsPtrNN<load>        ADDR:$ptr)), (ld_64_v1 ADDR:$ptr, 11)>;

// For segments where the address is 32-bit in both models.
defm ld_32_ptr32 : HSAIL_LD<GPR32, MEMOP32>;
defm ld_64_ptr32 : HSAIL_LD<GPR64, MEMOP32>;

def : Pat<(i32 (LoadIsPtr32<load>        ADDR:$ptr)), (ld_32_ptr32_v1 ADDR:$ptr, 3)>;
def : Pat<(f32 (LoadIsPtr32<load>        ADDR:$ptr)), (ld_32_ptr32_v1 ADDR:$ptr, 10)>;
def : Pat<(i32 (LoadIsPtr32<extloadi8>   ADDR:$ptr)), (ld_32_ptr32_v1 ADDR:$ptr, 13)>;
def : Pat<(i32 (LoadIsPtr32<sextloadi8>  ADDR:$ptr)), (ld_32_ptr32_v1 ADDR:$ptr, 5)>;
def : Pat<(i32 (LoadIsPtr32<zextloadi8>  ADDR:$ptr)), (ld_32_ptr32_v1 ADDR:$ptr, 1)>;
def : Pat<(i32 (LoadIsPtr32<extloadi16>  ADDR:$ptr)), (ld_32_ptr32_v1 ADDR:$ptr, 14)>;
def : Pat<(i32 (LoadIsPtr32<sextloadi16> ADDR:$ptr)), (ld_32_ptr32_v1 ADDR:$ptr, 6)>;
def : Pat<(i32 (LoadIsPtr32<zextloadi16> ADDR:$ptr)), (ld_32_ptr32_v1 ADDR:$ptr, 2)>;
def : Pat<(i64 (LoadIsPtr32<load>        ADDR:$ptr)), (ld_64_ptr32_v1 ADDR:$ptr, 4)>;
def : Pat<(f64 (LoadIsPtr32<load>        ADDR:$ptr)), (ld_64_ptr32_v1 ADDR:$ptr, 11)>;

let hasSideEffects = 1, hasCtrlDep = 1 in {
  // It is not safe to move ld_arg as it can be in an argscope
  defm rarg_ld_32_ptr32 : HSAIL_LD<GPR32, MEMOP32>;
  defm rarg_ld_64_ptr32 : HSAIL_LD<GPR64, MEMOP32>;
}

let hasAddress = 1, mayLoad = 1, isPseudo = 1, hasSideEffects = 0 in {
  def ld_b1_ptr32 : HSAILInst<(outs CR:$dst), (ins MEMOP32:$ptr, BRIG_TYPE_OPND:$t,
                                             WIDTH_OPND:$w, CONST_OPERAND:$isConst),
                              "ld_b1\t$dst, $ptr", []>;
}

////////////////////////////////////////////////////////////////////////////////
// st (integer, singed and unsigned, 32-bit and 64-bit;
//     float, 32-bit and 64-bit; addr, 32bit and 64-bit)
multiclass HSAIL_ST<RegisterClass RC, DAGOperand MPtr>
{
  let hasAddress = 1, isStore = 1, mayStore = 1, hasSideEffects = 0 in {
    let addressOpNum = 1 in {
      def _v1 : HSAILInst<(outs), (ins RC:$val,
                                       MPtr:$ptr, BRIG_TYPE_OPND:$t),
                          "st_$t\t$val, $ptr", []>;
    }

    let addressOpNum = 2 in {
      def _v2 : HSAILInst<(outs), (ins RC:$val1, RC:$val2,
                                       MPtr:$ptr, BRIG_TYPE_OPND:$t),
                          "st_v2_$t\t($val1, $val2 ), $ptr", []>;
    }
    let addressOpNum = 3 in {
      def _v3 : HSAILInst<(outs), (ins RC:$val1, RC:$val2, RC:$val3,
                                       MPtr:$ptr, BRIG_TYPE_OPND:$t),
                          "st_v3_$t\t($val1, $val2, $val3 ), $ptr", []>;
    }
    let addressOpNum = 4 in {
      def _v4 : HSAILInst<(outs), (ins RC:$val1, RC:$val2, RC:$val3, RC:$val4,
                                       MPtr:$ptr, BRIG_TYPE_OPND:$t),
                          "st_v4_$t\t($val1, $val2, $val3, $val4 ), $ptr", []>;
    }
  }
}

class StoreIsPtr32<PatFrag pf> : PatFrag<(ops node:$val, node:$ptr), (pf node:$val, node:$ptr),
                            [{ return MemOpHasPtr32(N); }]>;

class StoreIsPtrNN<PatFrag pf> : PatFrag<(ops node:$val, node:$ptr), (pf node:$val, node:$ptr),
                            [{ return !MemOpHasPtr32(N); }]>;

// For segments where the address is 32/64-bit depending on machine model.
defm st_32 : HSAIL_ST<GPR32, MEMOP>;
defm st_64 : HSAIL_ST<GPR64, MEMOP>;

def : Pat<(StoreIsPtrNN<store>         (i32 GPR32:$val), ADDR:$ptr), (st_32_v1 GPR32:$val, ADDR:$ptr, 3)>;
def : Pat<(StoreIsPtrNN<store>         (f32 GPR32:$val), ADDR:$ptr), (st_32_v1 GPR32:$val, ADDR:$ptr, 10)>;
def : Pat<(StoreIsPtrNN<truncstorei8>  (i32 GPR32:$val), ADDR:$ptr), (st_32_v1 GPR32:$val, ADDR:$ptr, 1)>;
def : Pat<(StoreIsPtrNN<truncstorei16> (i32 GPR32:$val), ADDR:$ptr), (st_32_v1 GPR32:$val, ADDR:$ptr, 2)>;
def : Pat<(StoreIsPtrNN<store>         (i64 GPR64:$val), ADDR:$ptr), (st_64_v1 GPR64:$val, ADDR:$ptr, 4)>;
def : Pat<(StoreIsPtrNN<store>         (f64 GPR64:$val), ADDR:$ptr), (st_64_v1 GPR64:$val, ADDR:$ptr, 11)>;

// For segments where the address is 32-bit in both models.
defm st_32_ptr32 : HSAIL_ST<GPR32, MEMOP32>;
defm st_64_ptr32 : HSAIL_ST<GPR64, MEMOP32>;

def : Pat<(StoreIsPtr32<store>         (i32 GPR32:$val), ADDR:$ptr), (st_32_ptr32_v1 GPR32:$val, ADDR:$ptr, 3)>;
def : Pat<(StoreIsPtr32<store>         (f32 GPR32:$val), ADDR:$ptr), (st_32_ptr32_v1 GPR32:$val, ADDR:$ptr, 10)>;
def : Pat<(StoreIsPtr32<truncstorei8>  (i32 GPR32:$val), ADDR:$ptr), (st_32_ptr32_v1 GPR32:$val, ADDR:$ptr, 1)>;
def : Pat<(StoreIsPtr32<truncstorei16> (i32 GPR32:$val), ADDR:$ptr), (st_32_ptr32_v1 GPR32:$val, ADDR:$ptr, 2)>;
def : Pat<(StoreIsPtr32<store>         (i64 GPR64:$val), ADDR:$ptr), (st_64_ptr32_v1 GPR64:$val, ADDR:$ptr, 4)>;
def : Pat<(StoreIsPtr32<store>         (f64 GPR64:$val), ADDR:$ptr), (st_64_ptr32_v1 GPR64:$val, ADDR:$ptr, 11)>;

let hasAddress = 1, mayStore = 1, isPseudo = 1, hasSideEffects = 0 in {
  def st_b1_ptr32 : HSAILInst<(outs), (ins CR:$val, MEMOP32:$ptr, BRIG_TYPE_OPND:$t),
                              "st_b1\t$val, $ptr", []>;
}

////////////////////////////////////////////////////////////////////////////////
// load memory address

class LdaAddr<RegisterClass RC, DAGOperand MPtr>
      : HSAILInst<(outs RC:$dst), (ins MPtr:$addr, i32imm:$segment),
      "lda\t$dst, $addr", []> {
  let hasAddress = 1;
  let addressOpNum = 1;
  let neverHasSideEffects = 1;
}

def lda_32 : LdaAddr<GPR32, MEMOP>;
def lda_64 : LdaAddr<GPR64, MEMOP>;

def : Pat<(i32 (IL_lda_group    ADDR:$ptr)), (lda_32 ADDR:$ptr, 5)>, Requires<[In32BitMode]>;
def : Pat<(i32 (IL_lda_private  ADDR:$ptr)), (lda_32 ADDR:$ptr, 6)>, Requires<[In32BitMode]>;
/*
// Commented block produces suboptimal but correct 32 bit pointers in 64 bit mode, though
// results in finalizer assertion:
// Error: GetDstSize(i) == out_width || ( GetDstSize(i) == 4 && out_width < 4) at .../SCInst.cpp:3505
// The assertion is fixed in staging, but not yet promoted.

// Additionally, the use of MEMOP32 in lda_32 causes the following error.
//
//     Error in hsa_operand section, at offset XXX:
//     Operand 0 size does not match operation size
//
// In PropValidator::validateOperandReg(), operation size is wrongly reported as 64.
// Note that even in large model, the operation size of lda_group and lda_private
// should be 32.
//
// Strangely this error shows up only when we change the source operand type to 32!

// Patterns for 64 bit mode with conversion of loaded 32 bit address.
// TODO_HSA: remove these patterns as soon as we stop producing 64 bit private and group pointers.
def lda_32 : LdaAddr<GPR32, MEMOP32>;
def : Pat<(i64 (IL_lda_group    ADDR:$ptr)), (cvt_u32_u64 (lda_32 ADDR:$ptr, 5))>, Requires<[In64BitMode]>;
def : Pat<(i64 (IL_lda_private  ADDR:$ptr)), (cvt_u32_u64 (lda_32 ADDR:$ptr, 6))>, Requires<[In64BitMode]>;
*/
// Create 64 bit pointers for now
// Remove the next three lines when the above issues are resolved
def lda_64_ptr32 : LdaAddr<GPR64, MEMOP32>;
def : Pat<(i64 (IL_lda_group    ADDR:$ptr)), (lda_64_ptr32 ADDR:$ptr, 5)>, Requires<[In64BitMode]>;
def : Pat<(i64 (IL_lda_private  ADDR:$ptr)), (lda_64_ptr32 ADDR:$ptr, 6)>, Requires<[In64BitMode]>;

def : Pat<(i32 (IL_lda_flat     ADDR:$ptr)), (lda_32 ADDR:$ptr, 1)>, Requires<[In32BitMode]>;
def : Pat<(i64 (IL_lda_flat     ADDR:$ptr)), (lda_64 ADDR:$ptr, 1)>, Requires<[In64BitMode]>;
def : Pat<(i32 (IL_lda_global   ADDR:$ptr)), (lda_32 ADDR:$ptr, 2)>, Requires<[In32BitMode]>;
def : Pat<(i64 (IL_lda_global   ADDR:$ptr)), (lda_64 ADDR:$ptr, 2)>, Requires<[In64BitMode]>;
def : Pat<(i32 (IL_lda_readonly ADDR:$ptr)), (lda_32 ADDR:$ptr, 3)>, Requires<[In32BitMode]>;
def : Pat<(i64 (IL_lda_readonly ADDR:$ptr)), (lda_64 ADDR:$ptr, 3)>, Requires<[In64BitMode]>;
