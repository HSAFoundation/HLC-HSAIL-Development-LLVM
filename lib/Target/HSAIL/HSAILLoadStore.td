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
  let mayLoad = 1 in {
    def ld_arg_64 : HSAILInst<(outs GPR64:$d), (ins MEMOP:$a, i32imm:$brig_type), "", []>;
  }
  let mayStore = 1 in {
    def st_arg_64 : HSAILInst<(outs ), (ins GPR64:$s, MEMOP:$a, i32imm:$brig_type), "", []>;
  }
  def arg_decl : HSAILInst<(outs ), (ins PtrRC:$v, i32imm:$brig_type, i32imm:$size), "", []>;
}

// For sampler/image load from readonly segment for 0.98+ hsail spec
let needSpecialProcessing = 1, hasAddress = 1, addressOpNum = 1 in {
class LD_ROSAMP<Intrinsic intr, string asm, RegisterClass RC, ValueType vt> :
  HSAILInst<(outs RC:$dst), (ins i32imm:$a),
      !strconcat("ld_",!strconcat(asm, "\t $dst, $a")),
      [(set (vt RC:$dst), (intr imm:$a))]>;
}
def ld_readonly_samp : LD_ROSAMP<int_HSAIL_ld_readonly_samp, "readonly_samp", GPR64, i64>;

////////////////////////////////////////////////////////////////////////////////
// ld (integer, singed and unsigned, 32-bit and 64-bit;
//     float, 32-bit and 64-bit; addr, 32bit and 64-bit)
multiclass HSAIL_LD<PatFrag op, RegisterClass RC, ValueType Ty, string asm>
{
  let needSpecialProcessing = 1, hasAddress = 1, isLoad = 1 in {
    let VectorSize = 1, addressOpNum = 1 in {
      def _v1: HSAILInst<(outs RC:$dst), (ins MEMOP:$ptr, WIDTH_OPND:$w, ALIGN_OPND:$alignnment, CONST_OPERAND:$isConst),
                       "ld_"#asm#"\t$dst, $ptr",
                       [(set (Ty RC:$dst), (op ADDR:$ptr))]>,
                     VectorOperation;
    }

    let mayLoad = 1 in {
      let VectorSize = 2, addressOpNum = 2 in {
        def _v2 : HSAILInst<(outs RC:$dst1, RC:$dst2), (ins MEMOP:$ptr, WIDTH_OPND:$w, ALIGN_OPND:$alignnment, CONST_OPERAND:$isConst),
                             "ld_v2_"#asm#"\t($dst1, $dst2 ), $ptr", []>,
                           VectorOperation;
      }
      let VectorSize = 3, addressOpNum = 3 in {
        def _v3 : HSAILInst<(outs RC:$dst1, RC:$dst2, RC:$dst3), (ins MEMOP:$ptr, WIDTH_OPND:$w, ALIGN_OPND:$alignnment, CONST_OPERAND:$isConst),
                             "ld_v3_"#asm#"\t($dst1, $dst2, $dst3 ), $ptr", []>,
                           VectorOperation;
      }
      let VectorSize = 4, addressOpNum = 4 in {
        def _v4 : HSAILInst<(outs RC:$dst1, RC:$dst2, RC:$dst3, RC:$dst4), (ins MEMOP:$ptr, WIDTH_OPND:$w, ALIGN_OPND:$alignnment, CONST_OPERAND:$isConst),
                             "ld_v4_"#asm#"\t($dst1, $dst2, $dst3, $dst4 ), $ptr", []>,
                           VectorOperation;
      }
    }
  }
}

defm flat_ld_u32 : HSAIL_LD<flat_load, GPR32, i32, "u32">;
defm flat_ld_u64 : HSAIL_LD<flat_load, GPR64, i64, "u64">;
defm flat_ld_f32 : HSAIL_LD<flat_load, GPR32, f32, "f32">;
defm flat_ld_f64 : HSAIL_LD<flat_load, GPR64, f64, "f64">;

defm global_ld_u32 : HSAIL_LD<global_load, GPR32, i32, "global_u32">;
defm global_ld_u64 : HSAIL_LD<global_load, GPR64, i64, "global_u64">;
defm global_ld_f32 : HSAIL_LD<global_load, GPR32, f32, "global_f32">;
defm global_ld_f64 : HSAIL_LD<global_load, GPR64, f64, "global_f64">;

defm constant_ld_u32 : HSAIL_LD<constant_load, GPR32, i32, "readonly_u32">;
defm constant_ld_u64 : HSAIL_LD<constant_load, GPR64, i64, "readonly_u64">;
defm constant_ld_f32 : HSAIL_LD<constant_load, GPR32, f32, "readonly_f32">;
defm constant_ld_f64 : HSAIL_LD<constant_load, GPR64, f64, "readonly_f64">;

defm group_ld_u32 : HSAIL_LD<group_load, GPR32, i32, "group_u32">;
defm group_ld_u64 : HSAIL_LD<group_load, GPR64, i64, "group_u64">;
defm group_ld_f32 : HSAIL_LD<group_load, GPR32, f32, "group_f32">;
defm group_ld_f64 : HSAIL_LD<group_load, GPR64, f64, "group_f64">;

defm private_ld_u32 : HSAIL_LD<private_load, GPR32, i32, "private_u32">;
defm private_ld_u64 : HSAIL_LD<private_load, GPR64, i64, "private_u64">;
defm private_ld_f32 : HSAIL_LD<private_load, GPR32, f32, "private_f32">;
defm private_ld_f64 : HSAIL_LD<private_load, GPR64, f64, "private_f64">;

defm kernarg_ld_u32 : HSAIL_LD<kernarg_load, GPR32, i32, "kernarg_u32">;
defm kernarg_ld_u64 : HSAIL_LD<kernarg_load, GPR64, i64, "kernarg_u64">;
defm kernarg_ld_f32 : HSAIL_LD<kernarg_load, GPR32, f32, "kernarg_f32">;
defm kernarg_ld_f64 : HSAIL_LD<kernarg_load, GPR64, f64, "kernarg_f64">;

let hasSideEffects = 1, hasCtrlDep = 1 in {
  // It is not safe to move ld_arg as it can be in an argscope
  defm arg_ld_u32 : HSAIL_LD<arg_load, GPR32, i32, "arg_u32">;
  defm arg_ld_u64 : HSAIL_LD<arg_load, GPR64, i64, "arg_u64">;
  defm arg_ld_f32 : HSAIL_LD<arg_load, GPR32, f32, "arg_f32">;
  defm arg_ld_f64 : HSAIL_LD<arg_load, GPR64, f64, "arg_f64">;
}

let hasAddress = 1, mayLoad = 1, isPseudo = 1 in {
  def spill_ld_b1 : HSAILInst<(outs CR:$dst), (ins MEMOP:$ptr, WIDTH_OPND:$w,
                              ALIGN_OPND:$alignnment, CONST_OPERAND:$isConst),
                              "ld_spill_b1\t$dst, $ptr", []>;
}

defm spill_ld_u32 : HSAIL_LD<spill_load, GPR32, i32, "spill_u32">;
defm spill_ld_u64 : HSAIL_LD<spill_load, GPR64, i64, "spill_u64">;
defm spill_ld_f32 : HSAIL_LD<spill_load, GPR32, f32, "spill_f32">;
defm spill_ld_f64 : HSAIL_LD<spill_load, GPR64, f64, "spill_f64">;

////////////////////////////////////////////////////////////////////////////////
// Extended loads

// extended 8-bit loads
defm flat_ext_ld_u32_u8       : HSAIL_LD<extloadi8_flat,       GPR32, i32, "u8">;
defm global_ext_ld_u32_u8     : HSAIL_LD<extloadi8_global,     GPR32, i32, "global_u8">;
defm constant_ext_ld_u32_u8   : HSAIL_LD<extloadi8_constant,   GPR32, i32, "readonly_u8">;
defm group_ext_ld_u32_u8      : HSAIL_LD<extloadi8_group,      GPR32, i32, "group_u8">;
defm private_ext_ld_u32_u8    : HSAIL_LD<extloadi8_private,    GPR32, i32, "private_u8">;
defm kernarg_ext_ld_u32_u8    : HSAIL_LD<extloadi8_kernarg,    GPR32, i32, "kernarg_u8">;
defm arg_ext_ld_u32_u8        : HSAIL_LD<extloadi8_arg,        GPR32, i32, "arg_u8">;

defm flat_sext_ld_s32_s8      : HSAIL_LD<sextloadi8_flat,      GPR32, i32, "s8">;
defm global_sext_ld_s32_s8    : HSAIL_LD<sextloadi8_global,    GPR32, i32, "global_s8">;
defm constant_sext_ld_s32_s8  : HSAIL_LD<sextloadi8_constant,  GPR32, i32, "readonly_s8">;
defm group_sext_ld_s32_s8     : HSAIL_LD<sextloadi8_group,     GPR32, i32, "group_s8">;
defm private_sext_ld_s32_s8   : HSAIL_LD<sextloadi8_private,   GPR32, i32, "private_s8">;
defm kernarg_sext_ld_s32_s8   : HSAIL_LD<sextloadi8_kernarg,   GPR32, i32, "kernarg_s8">;
defm arg_sext_ld_s32_s8       : HSAIL_LD<sextloadi8_arg,       GPR32, i32, "arg_s8">;

defm flat_zext_ld_u32_u8      : HSAIL_LD<zextloadi8_flat,      GPR32, i32, "u8">;
defm global_zext_ld_u32_u8    : HSAIL_LD<zextloadi8_global,    GPR32, i32, "global_u8">;
defm constant_zext_ld_u32_u8  : HSAIL_LD<zextloadi8_constant,  GPR32, i32, "readonly_u8">;
defm group_zext_ld_u32_u8     : HSAIL_LD<zextloadi8_group,     GPR32, i32, "group_u8">;
defm private_zext_ld_u32_u8   : HSAIL_LD<zextloadi8_private,   GPR32, i32, "private_u8">;
defm kernarg_zext_ld_u32_u8   : HSAIL_LD<zextloadi8_kernarg,   GPR32, i32, "kernarg_u8">;
defm arg_zext_ld_u32_u8       : HSAIL_LD<zextloadi8_arg,       GPR32, i32, "arg_u8">;

// extended 16-bit loads
defm flat_ext_ld_u32_u16      : HSAIL_LD<extloadi16_flat,      GPR32, i32, "u16">;
defm global_ext_ld_u32_u16    : HSAIL_LD<extloadi16_global,    GPR32, i32, "global_u16">;
defm constant_ext_ld_u32_u16  : HSAIL_LD<extloadi16_constant,  GPR32, i32, "readonly_u16">;
defm group_ext_ld_u32_u16     : HSAIL_LD<extloadi16_group,     GPR32, i32, "group_u16">;
defm private_ext_ld_u32_u16   : HSAIL_LD<extloadi16_private,   GPR32, i32, "private_u16">;
defm kernarg_ext_ld_u32_u16   : HSAIL_LD<extloadi16_kernarg,   GPR32, i32, "kernarg_u16">;
defm arg_ext_ld_u32_u16       : HSAIL_LD<extloadi16_arg,       GPR32, i32, "arg_u16">;

defm flat_sext_ld_s32_s16     : HSAIL_LD<sextloadi16_flat,     GPR32, i32, "s16">;
defm global_sext_ld_s32_s16   : HSAIL_LD<sextloadi16_global,   GPR32, i32, "global_s16">;
defm constant_sext_ld_s32_s16 : HSAIL_LD<sextloadi16_constant, GPR32, i32, "readonly_s16">;
defm group_sext_ld_s32_s16    : HSAIL_LD<sextloadi16_group,    GPR32, i32, "group_s16">;
defm private_sext_ld_s32_s16  : HSAIL_LD<sextloadi16_private,  GPR32, i32, "private_s16">;
defm kernarg_sext_ld_s32_s16  : HSAIL_LD<sextloadi16_kernarg,  GPR32, i32, "kernarg_s16">;
defm arg_sext_ld_s32_s16      : HSAIL_LD<sextloadi16_arg,      GPR32, i32, "arg_s16">;

defm flat_zext_ld_u32_u16     : HSAIL_LD<zextloadi16_flat,     GPR32, i32, "u16">;
defm global_zext_ld_u32_u16   : HSAIL_LD<zextloadi16_global,   GPR32, i32, "global_u16">;
defm constant_zext_ld_u32_u16 : HSAIL_LD<zextloadi16_constant, GPR32, i32, "readonly_u16">;
defm group_zext_ld_u32_u16    : HSAIL_LD<zextloadi16_group,    GPR32, i32, "group_u16">;
defm private_zext_ld_u32_u16  : HSAIL_LD<zextloadi16_private,  GPR32, i32, "private_u16">;
defm kernarg_zext_ld_u32_u16  : HSAIL_LD<zextloadi16_kernarg,  GPR32, i32, "kernarg_u16">;
defm arg_zext_ld_u32_u16      : HSAIL_LD<zextloadi16_arg,      GPR32, i32, "arg_u16">;

////////////////////////////////////////////////////////////////////////////////
// st (integer, singed and unsigned, 32-bit and 64-bit;
//     float, 32-bit and 64-bit; addr, 32bit and 64-bit)
multiclass HSAIL_ST<PatFrag op, RegisterClass RC, ValueType Ty, string asm>
{
  let needSpecialProcessing = 1, hasAddress = 1, isStore = 1 in {
    let VectorSize = 1, addressOpNum = 1 in {
      def _v1 : HSAILInst<(outs), (ins RC:$val, MEMOP:$ptr, ALIGN_OPND:$alignnment),
                          "st_"#asm#"\t$val, $ptr",
                          [(op (Ty RC:$val), ADDR:$ptr)]>,
                          VectorOperation;
    }

    let mayStore = 1 in {
      let VectorSize = 2, addressOpNum = 2 in {
        def _v2 : HSAILInst<(outs), 
                            (ins RC:$val1, RC:$val2, MEMOP:$ptr, ALIGN_OPND:$alignnment),
                            "st_v2_"#asm#"\t($val1, $val2 ), $ptr",
                            []>, VectorOperation;
      }
      let VectorSize = 3, addressOpNum = 3 in {
        def _v3 : HSAILInst<(outs), 
                            (ins RC:$val1, RC:$val2, RC:$val3, MEMOP:$ptr, ALIGN_OPND:$alignnment),
                            "st_v3_"#asm#"\t($val1, $val2, $val3 ), $ptr",
                            []>, VectorOperation;
      }
      let VectorSize = 4, addressOpNum = 4 in {
        def _v4 : HSAILInst<(outs), 
                            (ins RC:$val1, RC:$val2, 
                                 RC:$val3, RC:$val4, MEMOP:$ptr, ALIGN_OPND:$alignnment),
                            "st_v4_"#asm#"\t($val1, $val2, $val3, $val4 ), $ptr",
                            []>, VectorOperation;
      }
    }
  }
}

defm flat_st_u32 : HSAIL_ST<flat_store, GPR32, i32, "u32">;
defm flat_st_u64 : HSAIL_ST<flat_store, GPR64, i64, "u64">;
defm flat_st_f32 : HSAIL_ST<flat_store, GPR32, f32, "f32">;
defm flat_st_f64 : HSAIL_ST<flat_store, GPR64, f64, "f64">;

defm global_st_u32 : HSAIL_ST<global_store, GPR32, i32, "global_u32">;
defm global_st_u64 : HSAIL_ST<global_store, GPR64, i64, "global_u64">;
defm global_st_f32 : HSAIL_ST<global_store, GPR32, f32, "global_f32">;
defm global_st_f64 : HSAIL_ST<global_store, GPR64, f64, "global_f64">;

defm group_st_u32 : HSAIL_ST<group_store, GPR32, i32, "group_u32">;
defm group_st_u64 : HSAIL_ST<group_store, GPR64, i64, "group_u64">;
defm group_st_f32 : HSAIL_ST<group_store, GPR32, f32, "group_f32">;
defm group_st_f64 : HSAIL_ST<group_store, GPR64, f64, "group_f64">;

defm private_st_u32 : HSAIL_ST<private_store, GPR32, i32, "private_u32">;
defm private_st_u64 : HSAIL_ST<private_store, GPR64, i64, "private_u64">;
defm private_st_f32 : HSAIL_ST<private_store, GPR32, f32, "private_f32">;
defm private_st_f64 : HSAIL_ST<private_store, GPR64, f64, "private_f64">;

// spill stores
let hasAddress = 1, mayStore = 1, isPseudo = 1 in {
  def spill_st_b1 : HSAILInst<(outs), (ins CR:$val, MEMOP:$ptr,
                                       ALIGN_OPND:$alignnment),
                              "st_spill_b1\t$val, $ptr", []>;
}

defm spill_st_u32 : HSAIL_ST<spill_store, GPR32, i32, "spill_u32">;
defm spill_st_u64 : HSAIL_ST<spill_store, GPR64, i64, "spill_u64">;
defm spill_st_f32 : HSAIL_ST<spill_store, GPR32, f32, "spill_f32">;
defm spill_st_f64 : HSAIL_ST<spill_store, GPR64, f64, "spill_f64">;

defm arg_st_u32 : HSAIL_ST<arg_store, GPR32, i32, "arg_u32">;
defm arg_st_u64 : HSAIL_ST<arg_store, GPR64, i64, "arg_u64">;
defm arg_st_f32 : HSAIL_ST<arg_store, GPR32, f32, "arg_f32">;
defm arg_st_f64 : HSAIL_ST<arg_store, GPR64, f64, "arg_f64">;

////////////////////////////////////////////////////////////////////////////////
// Truncating stores

// truncating 8-bit stores
defm flat_truncst_u32_u8     : HSAIL_ST<truncstorei8_flat,    GPR32, i32, "u8">;
defm global_truncst_u32_u8   : HSAIL_ST<truncstorei8_global,  GPR32, i32, "global_u8">;
defm group_truncst_u32_u8    : HSAIL_ST<truncstorei8_group,   GPR32, i32, "group_u8">;
defm private_truncst_u32_u8  : HSAIL_ST<truncstorei8_private, GPR32, i32, "private_u8">;
defm arg_truncst_u32_u8      : HSAIL_ST<truncstorei8_arg,     GPR32, i32, "arg_u8">;

// truncating 16-bit stores
defm flat_truncst_u32_u16    : HSAIL_ST<truncstorei16_flat,    GPR32, i32, "u16">;
defm global_truncst_u32_u16  : HSAIL_ST<truncstorei16_global,  GPR32, i32, "global_u16">;
defm group_truncst_u32_u16   : HSAIL_ST<truncstorei16_group,   GPR32, i32, "group_u16">;
defm private_truncst_u32_u16 : HSAIL_ST<truncstorei16_private, GPR32, i32, "private_u16">;
defm arg_truncst_u32_u16     : HSAIL_ST<truncstorei16_arg,     GPR32, i32, "arg_u16">;

////////////////////////////////////////////////////////////////////////////////
// load memory address

//LDA flat and Group address
multiclass LdaAddr<SDNode op, string asm>
{
  let hasAddress = 1, addressOpNum = 1 in {
    def _addr32 : HSAILInst<(outs GPR32:$dst), (ins MEMOP:$addr), 
        asm#"_u32"#"\t$dst, $addr",
        [(set (i32 GPR32:$dst), (op ADDR:$addr))]>,
        Requires<[In32BitMode]>;

    def _addr64 : HSAILInst<(outs GPR64:$dst), (ins MEMOP:$addr), 
        asm#"_u64"#"\t$dst, $addr",
        [(set (i64 GPR64:$dst), (op ADDR:$addr))]>,
        Requires<[In64BitMode]>;
  }
}

let needSpecialProcessing = 1 in {
  // TODO_HSA: is lda_flat legal? See Spec "Additional Information About lda"
  defm lda_flat      : LdaAddr<IL_lda_flat, "lda">;
  defm ldas_group    : LdaAddr<IL_lda_group, "lda_group">;
  defm ldas_global : LdaAddr<IL_lda_global,"lda_global">;
  defm ldas_constant : LdaAddr<IL_lda_readonly, "lda_readonly">;
  defm ldas_private  : LdaAddr<IL_lda_private, "lda_private">;
}
