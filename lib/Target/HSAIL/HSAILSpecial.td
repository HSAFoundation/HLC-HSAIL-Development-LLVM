////////////////////////////////////////////////////////////////////////////////
// special operations

let isAsCheapAsAMove = 1 in {
  let isReMaterializable = 1 in {
    def get_global_id_i : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src),
                           "workitemabsid_u32\t$dst, $src",
                           [(set (i32 GPR32:$dst),
                                 (int_HSAIL_get_global_id (i32 imm:$src)))]>;

    def get_group_id_i : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src),
                        "workgroupid_u32\t$dst, $src",
                        [(set (i32 GPR32:$dst),
                              (int_HSAIL_get_group_id (i32 imm:$src)))]>;

    def get_local_id_i : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src),
                         "workitemid_u32\t$dst, $src",
                         [(set (i32 GPR32:$dst),
                               (int_HSAIL_get_local_id (i32 imm:$src)))]>;

    def workgroup_size_i : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src),
                         "workgroupsize_u32\t$dst, $src",
                         [(set (i32 GPR32:$dst),
                               (int_HSAIL_workgroup_size (i32 imm:$src)))]>;

    def currentworkgroup_size_i : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src),
                         "currentworkgroupsize_u32\t$dst, $src",
                         [(set (i32 GPR32:$dst),
                               (int_HSAIL_currentworkgroup_size (i32 imm:$src)))]>;

    def get_num_groups_i : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src),
                          "gridgroups_u32\t$dst, $src",
                          [(set (i32 GPR32:$dst),
                                (int_HSAIL_get_num_groups (i32 imm:$src)))]>;

    def get_global_size_i : HSAILInst<(outs GPR32:$dst), (ins i32imm:$src),
                          "gridsize_u32\t$dst, $src",
                          [(set (i32 GPR32:$dst),
                                (int_HSAIL_get_global_size (i32 imm:$src)))]>;
  }

  def get_work_dim: HSAILInst<(outs GPR32:$dst), (ins),
                    "dim_u32\t$dst",
                    [(set (i32 GPR32:$dst), 
                      (int_HSAIL_get_work_dim))]>;

  def get_workitemid_flat : HSAILInst<(outs GPR32:$dst), (ins),
                    "workitemflatid_u32\t$dst",
                    [(set (i32 GPR32:$dst), 
                      (int_HSAIL_workitemid_flat))]>;

  def get_workitemid_flatabs : HSAILInst<(outs GPR32:$dst), (ins),
                    "workitemflatabsid_u32\t$dst",
                    [(set (i32 GPR32:$dst), 
                      (int_HSAIL_workitemid_flatabs))]>;

  def get_lane_id : HSAILInst<(outs GPR32:$dst), (ins),
                    "laneid_u32\t$dst",
                    [(set (i32 GPR32:$dst),
                                  (int_HSAIL_get_lane_id))]>;

  def get_dynwave_id : HSAILInst<(outs GPR32:$dst), (ins),
                       "waveid_u32\t$dst",
                       [(set (i32 GPR32:$dst),
                             (int_HSAIL_get_dynwave_id))]>;

  def get_maxdynwave_id : HSAILInst<(outs GPR32:$dst), (ins),
                          "maxwaveid_u32\t$dst",
                          [(set (i32 GPR32:$dst),
                                (int_HSAIL_get_maxdynwave_id))]>;

  def get_clock : HSAILInst<(outs GPR64:$dst), (ins),
                        "clock_u64\t$dst",
                        [(set (i64 GPR64:$dst),
                            (int_HSAIL_get_clock))]>;

  def get_cu : HSAILInst<(outs GPR32:$dst), (ins),
                        "cuid_u32\t$dst",
                        [(set (i32 GPR32:$dst),
                            (int_HSAIL_get_cu))]>;

  let isNotDuplicable = 1 in {
    def barrier : HSAILInst<(outs), (ins),
             "barrier", [(int_HSAIL_barrier)]>;
    def wavebarrier : HSAILInst<(outs), (ins),
             "wavebarrier", [(int_HSAIL_wavebarrier)]>;

  }

}

////////////////////////////////////////////////////////////////////////////////
// SYNC OCL 2.0

def hsail_memfence : HSAILInst< (outs),
    (ins i32imm:$order, i32imm:$globalscope, i32imm:$groupscope, i32imm:$imagescope), "",
    [(int_HSAIL_memfence (i32 imm:$order), (i32 imm:$globalscope), (i32 imm:$groupscope), (i32 imm:$imagescope))]>;

// Cross-Lane Operations
  class CrossLaneV4<string asm>
		: HSAILInst<(outs GPR64:$dst1, GPR64:$dst2,  GPR64:$dst3,  GPR64:$dst4),
					(ins CR:$src1),
					!strconcat(asm,
							   " ( $dst1, $dst2, $dst3, $dst4 ), "
							   "$src1"), []>;

  def activelaneid_u32 :         HSAILInst<(outs GPR32:$dst), (ins),
                    "activelaneid_u32\t$dst",
                    [(set (i32 GPR32:$dst),
                          (int_HSAIL_activelaneid_u32))]>;

  def activelanecount_u32_b1 :   HSAILInst<(outs GPR32:$dst), (ins CR:$src),
                    "activelanecount_u32_b1\t$dst",
                    [(set (i32 GPR32:$dst),
                          (int_HSAIL_activelanecount_u32_b1 (i1 CR:$src)))]>;

  def activelanecount_u32_b1_i : HSAILInst<(outs GPR32:$dst), (ins i1imm:$src),
                    "activelanecount_u32_b1\t$dst",
                    [(set (i32 GPR32:$dst),
                          (int_HSAIL_activelanecount_u32_b1 (i1 imm:$src)))]>;

  defm activelaneshuffle_b1 :        CrossLaneIntrB1<
                    int_HSAIL_activelaneshuffle_b1,"activelaneshuffle_b1">;

  defm activelaneshuffle_b32 :       CrossLaneIntrB32<
                    int_HSAIL_activelaneshuffle_b32, "activelaneshuffle_b32">;

  defm activelaneshuffle_b64 :       CrossLaneIntrB64<
                    int_HSAIL_activelaneshuffle_b64, "activelaneshuffle_b64">;

  defm activelaneshuffle_width_b1 :  CrossLaneIntrB1<
                    int_HSAIL_activelaneshuffle_width_b1,
                                      "activelaneshuffle_width(WAVESIZE)_b1">;

  defm activelaneshuffle_width_b32 : CrossLaneIntrB32<
                    int_HSAIL_activelaneshuffle_width_b32,
                                      "activelaneshuffle_width(WAVESIZE)_b32">;

  defm activelaneshuffle_width_b64 : CrossLaneIntrB64<
                    int_HSAIL_activelaneshuffle_width_b64,
                                      "activelaneshuffle_width(WAVESIZE)_b64">;

  let hasWidthOperand = 1 in {
    def activelaneid_width_u32 : HSAILInst<(outs GPR32:$dst), (ins),
                      "activelaneid_width(WAVESIZE)_u32\t$dst",
                      [(set (i32 GPR32:$dst),
                            (int_HSAIL_activelaneid_width_u32))]>;

    def activelanecount_width_u32_b1 : HSAILInst<(outs GPR32:$dst),
                                                 (ins CR:$src),
                      "activelanecount_width(WAVESIZE)_u32_b1\t$dst",
                      [(set (i32 GPR32:$dst),
                            (int_HSAIL_activelanecount_width_u32_b1
                                (i1 CR:$src)))]>;
    def activelanecount_width_u32_b1_i : HSAILInst<(outs GPR32:$dst),
                                                   (ins i1imm:$src),
                      "activelanecount_width(WAVESIZE)_u32_b1\t$dst",
                      [(set (i32 GPR32:$dst),
                            (int_HSAIL_activelanecount_width_u32_b1
                                (i1 imm:$src)))]>;
  }

  let isCrossLaneInst = 1 in {
    def activelanemask_v4_b64_b1 : CrossLaneV4<"activelanemask_v4_b64_b1">;
    def activelanemask_v4_width_b64_b1 : CrossLaneV4<"activelanemask_v4_width(WAVESIZE)_b64_b1">;
  }

def nullptr_flat_u64  : HSAILInst<(outs GPR64:$dst), (ins),
          "nullptr_u64\t $dst",
          [(set (i64 GPR64:$dst), (int_HSAIL_nullptr_flat))]>;
def nullptr_flat_u32  : HSAILInst<(outs GPR32:$dst), (ins),
          "nullptr_u32\t $dst",
          [(set (i32 GPR32:$dst), (int_HSAIL_nullptr_flat))]>;
def nullptr_global_u64  : HSAILInst<(outs GPR64:$dst), (ins),
          "nullptr_global_u64\t $dst",
          [(set (i64 GPR64:$dst), (int_HSAIL_nullptr_global))]>;
def nullptr_global_u32  : HSAILInst<(outs GPR32:$dst), (ins),
          "nullptr_global_u32\t $dst",
          [(set (i32 GPR32:$dst), (int_HSAIL_nullptr_global))]>;
def nullptr_group_u32  : HSAILInst<(outs GPR32:$dst), (ins),
          "nullptr_group_u32\t $dst",
          [(set (i32 GPR32:$dst), (int_HSAIL_nullptr_group))]>;
def nullptr_private_u32  : HSAILInst<(outs GPR32:$dst), (ins),
          "nullptr_private_u32\t $dst",
          [(set (i32 GPR32:$dst), (int_HSAIL_nullptr_private))]>;