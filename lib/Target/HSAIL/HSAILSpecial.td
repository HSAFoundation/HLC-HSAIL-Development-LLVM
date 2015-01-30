////////////////////////////////////////////////////////////////////////////////
// special operations

let isAsCheapAsAMove = 1 in {
  let isReMaterializable = 1 in {
    def get_global_id_i : HSAILInst<(outs GPR32:$dest), (ins i32imm:$dimNumber),
                           "workitemabsid_u32\t$dest, $dimNumber",
                           [(set (i32 GPR32:$dest),
                                 (int_HSAIL_get_global_id (i32 imm:$dimNumber)))]>;

    def get_group_id_i : HSAILInst<(outs GPR32:$dest), (ins i32imm:$dimNumber),
                        "workgroupid_u32\t$dest, $dimNumber",
                        [(set (i32 GPR32:$dest),
                              (int_HSAIL_get_group_id (i32 imm:$dimNumber)))]>;

    def get_local_id_i : HSAILInst<(outs GPR32:$dest), (ins i32imm:$dimNumber),
                         "workitemid_u32\t$dest, $dimNumber",
                         [(set (i32 GPR32:$dest),
                               (int_HSAIL_get_local_id (i32 imm:$dimNumber)))]>;

    def workgroup_size_i : HSAILInst<(outs GPR32:$dest), (ins i32imm:$dimNumber),
                         "workgroupsize_u32\t$dest, $dimNumber",
                         [(set (i32 GPR32:$dest),
                               (int_HSAIL_workgroup_size (i32 imm:$dimNumber)))]>;

    def currentworkgroup_size_i : HSAILInst<(outs GPR32:$dest), (ins i32imm:$dimNumber),
                         "currentworkgroupsize_u32\t$dest, $dimNumber",
                         [(set (i32 GPR32:$dest),
                               (int_HSAIL_currentworkgroup_size (i32 imm:$dimNumber)))]>;

    def get_num_groups_i : HSAILInst<(outs GPR32:$dest), (ins i32imm:$dimNumber),
                          "gridgroups_u32\t$dest, $dimNumber",
                          [(set (i32 GPR32:$dest),
                                (int_HSAIL_get_num_groups (i32 imm:$dimNumber)))]>;

    def get_global_size_i : HSAILInst<(outs GPR32:$dest), (ins i32imm:$dimNumber),
                          "gridsize_u32\t$dest, $dimNumber",
                          [(set (i32 GPR32:$dest),
                                (int_HSAIL_get_global_size (i32 imm:$dimNumber)))]>;
  }

  def get_work_dim: HSAILInst<(outs GPR32:$dest), (ins),
                    "dim_u32\t$dest",
                    [(set (i32 GPR32:$dest),
                      (int_HSAIL_get_work_dim))]>;

  def get_workitemid_flat : HSAILInst<(outs GPR32:$dest), (ins),
                    "workitemflatid_u32\t$dest",
                    [(set (i32 GPR32:$dest),
                      (int_HSAIL_workitemid_flat))]>;

  def get_workitemid_flatabs : HSAILInst<(outs GPR32:$dest), (ins),
                    "workitemflatabsid_u32\t$dest",
                    [(set (i32 GPR32:$dest),
                      (int_HSAIL_workitemid_flatabs))]>;

  def get_lane_id : HSAILInst<(outs GPR32:$dest), (ins),
                    "laneid_u32\t$dest",
                    [(set (i32 GPR32:$dest),
                                  (int_HSAIL_get_lane_id))]>;

  def get_dynwave_id : HSAILInst<(outs GPR32:$dest), (ins),
                       "waveid_u32\t$dest",
                       [(set (i32 GPR32:$dest),
                             (int_HSAIL_get_dynwave_id))]>;

  def get_maxdynwave_id : HSAILInst<(outs GPR32:$dest), (ins),
                          "maxwaveid_u32\t$dest",
                          [(set (i32 GPR32:$dest),
                                (int_HSAIL_get_maxdynwave_id))]>;

  def get_clock : HSAILInst<(outs GPR64:$dest), (ins),
                        "clock_u64\t$dest",
                        [(set (i64 GPR64:$dest),
                            (int_HSAIL_get_clock))]>;

  def get_cu : HSAILInst<(outs GPR32:$dest), (ins),
                        "cuid_u32\t$dest",
                        [(set (i32 GPR32:$dest),
                            (int_HSAIL_get_cu))]>;

  let isNotDuplicable = 1, isBarrier = 1 in {
    def barrier : HSAILInst<(outs), (ins),
             "barrier", [(int_HSAIL_barrier)]>;
    def wavebarrier : HSAILInst<(outs), (ins),
             "wavebarrier", [(int_HSAIL_wavebarrier)]>;

  }

}

////////////////////////////////////////////////////////////////////////////////
// SYNC OCL 2.0

let isNotDuplicable = 1, isBarrier = 1 in {
  def hsail_memfence : HSAILInst< (outs),
    (ins i32imm:$order, i32imm:$globalscope, i32imm:$groupscope, i32imm:$imagescope),
    "memfence_$order$globalscope$groupscope$imagescope",
    [(int_HSAIL_memfence (i32 imm:$order), (i32 imm:$globalscope), (i32 imm:$groupscope), (i32 imm:$imagescope))]>;
}

def activelaneshuffle_inst :
  HSAILInstLane_ActiveLaneShuffle<"activelaneshuffle",
                                   BrigOpcode.ACTIVELANESHUFFLE>;

def : ActiveLaneShufflePat<activelaneshuffle_inst,
                           HSAILactivelaneshuffle, i32, BrigTypeX.B32>;
def : ActiveLaneShufflePat<activelaneshuffle_inst,
                           HSAILactivelaneshuffle, i64, BrigTypeX.B64>;


// Cross-Lane Operations
  class CrossLaneV4<string asm>
		: HSAILInst<(outs GPR64:$dest0, GPR64:$dest1,  GPR64:$dest2,  GPR64:$dest3),
					(ins CR:$src1),
					!strconcat(asm,
							   " ( $dest0, $dest1, $dest2, $dest3 ), "
							   "$src1"), []> {
    let isCrossLaneInst = 1;
  }

  def activelaneid_u32 :         HSAILInst<(outs GPR32:$dest), (ins),
                    "activelaneid_u32\t$dest",
                    [(set (i32 GPR32:$dest),
                          (int_HSAIL_activelaneid_u32))]>;

  def activelanecount_u32_b1 :   HSAILInst<(outs GPR32:$dest), (ins CR:$src),
                    "activelanecount_u32_b1\t$dest, $src",
                    [(set (i32 GPR32:$dest),
                          (int_HSAIL_activelanecount_u32_b1 (i1 CR:$src)))]>;

  def activelanecount_u32_b1_i : HSAILInst<(outs GPR32:$dest), (ins i1imm:$src),
                    "activelanecount_u32_b1\t$dest, $src",
                    [(set (i32 GPR32:$dest),
                          (int_HSAIL_activelanecount_u32_b1 (i1 imm:$src)))]>;

  let hasWidthOperand = 1 in {
    def activelaneid_width_u32 : HSAILInst<(outs GPR32:$dest), (ins),
                      "activelaneid_width(WAVESIZE)_u32\t$dest",
                      [(set (i32 GPR32:$dest),
                            (int_HSAIL_activelaneid_width_u32))]>;

    def activelanecount_width_u32_b1 : HSAILInst<(outs GPR32:$dest),
                                                 (ins CR:$src),
                      "activelanecount_width(WAVESIZE)_u32_b1\t$dest, $src",
                      [(set (i32 GPR32:$dest),
                            (int_HSAIL_activelanecount_width_u32_b1
                                (i1 CR:$src)))]>;
    def activelanecount_width_u32_b1_i : HSAILInst<(outs GPR32:$dest),
                                                   (ins i1imm:$src),
                      "activelanecount_width(WAVESIZE)_u32_b1\t$dest, $src",
                      [(set (i32 GPR32:$dest),
                            (int_HSAIL_activelanecount_width_u32_b1
                                (i1 imm:$src)))]>;
  }

  def activelanemask_v4_b64_b1 : CrossLaneV4<"activelanemask_v4_b64_b1">;
  def activelanemask_v4_width_b64_b1 : CrossLaneV4<"activelanemask_v4_width(WAVESIZE)_b64_b1">;

let isAsCheapAsAMove = 1, isReMaterializable = 1 in {
  def nullptr_flat_u64  : HSAILInst<(outs GPR64:$dest), (ins),
            "nullptr_u64\t $dest",
            [(set (i64 GPR64:$dest), (int_HSAIL_nullptr_flat))]>, Requires<[In64BitMode]>;
  def nullptr_flat_u32  : HSAILInst<(outs GPR32:$dest), (ins),
            "nullptr_u32\t $dest",
            [(set (i32 GPR32:$dest), (int_HSAIL_nullptr_flat))]>, Requires<[In32BitMode]>;
  def nullptr_global_u64  : HSAILInst<(outs GPR64:$dest), (ins),
            "nullptr_global_u64\t $dest",
            [(set (i64 GPR64:$dest), (int_HSAIL_nullptr_global))]>, Requires<[In64BitMode]>;
  def nullptr_global_u32  : HSAILInst<(outs GPR32:$dest), (ins),
            "nullptr_global_u32\t $dest",
            [(set (i32 GPR32:$dest), (int_HSAIL_nullptr_global))]>, Requires<[In32BitMode]>;
  def nullptr_group_u32  : HSAILInst<(outs GPR32:$dest), (ins),
            "nullptr_group_u32\t $dest",
            [(set (i32 GPR32:$dest), (int_HSAIL_nullptr_group))]>;
  def nullptr_private_u32  : HSAILInst<(outs GPR32:$dest), (ins),
            "nullptr_private_u32\t $dest",
            [(set (i32 GPR32:$dest), (int_HSAIL_nullptr_private))]>;
  def nullptr_readonly_u64  : HSAILInst<(outs GPR64:$dest), (ins),
            "nullptr_readonly_u64\t $dest",
            [(set (i64 GPR64:$dest), (int_HSAIL_nullptr_readonly))]>, Requires<[In64BitMode]>;
  def nullptr_readonly_u32  : HSAILInst<(outs GPR32:$dest), (ins),
            "nullptr_readonly_u32\t $dest",
            [(set (i32 GPR32:$dest), (int_HSAIL_nullptr_readonly))]>, Requires<[In32BitMode]>;
  def nullptr_kernarg_u64   : HSAILInst<(outs GPR64:$dest), (ins),
            "nullptr_kernarg_u64\t $dest",
            [(set (i64 GPR64:$dest), (int_HSAIL_nullptr_kernarg))]>, Requires<[In64BitMode]>;
  def nullptr_kernarg_u32   : HSAILInst<(outs GPR32:$dest), (ins),
            "nullptr_kernarg_u32\t $dest",
            [(set (i32 GPR32:$dest), (int_HSAIL_nullptr_kernarg))]>, Requires<[In32BitMode]>;
  def kernargbaseptr_u64 : HSAILInst<(outs GPR64:$dest), (ins ),
            "kernargbaseptr_u64 \t $dest", []>;
  def kernargbaseptr_u32 : HSAILInst<(outs GPR32:$dest), (ins ),
            "kernargbaseptr_u32 \t $dest", []>;
}
