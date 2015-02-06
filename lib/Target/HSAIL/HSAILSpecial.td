////////////////////////////////////////////////////////////////////////////////
// special operations

let isAsCheapAsAMove = 1 in {
  let isReMaterializable = 1 in {
    def workitemabsid_inst : HSAILInstBasic_1Op<"workitemabsid", BrigOpcode.WORKITEMABSID>;
    def workgroupid_inst : HSAILInstBasic_1Op<"workgroupid", BrigOpcode.WORKGROUPID>;
    def workitemid_inst : HSAILInstBasic_1Op<"workitemid", BrigOpcode.WORKITEMID>;
    def workgroupsize_inst : HSAILInstBasic_1Op<"workgroupsize", BrigOpcode.WORKGROUPSIZE>;
    def currentworkgroupsize_inst : HSAILInstBasic_1Op<"currentworkgroupsize", BrigOpcode.CURRENTWORKGROUPSIZE>;
    def gridgroups_inst : HSAILInstBasic_1Op<"gridgroups", BrigOpcode.GRIDGROUPS>;
    def gridsize_inst : HSAILInstBasic_1Op<"gridsize", BrigOpcode.GRIDSIZE>;
  }

  def dim_inst : HSAILInstBasic_0Op<"dim", BrigOpcode.DIM>;
  def workitemflatid_inst : HSAILInstBasic_0Op<"workitemflatid", BrigOpcode.WORKITEMFLATID>;
  def workitemflatabsid_inst : HSAILInstBasic_0Op<"workitemflatabsid", BrigOpcode.WORKITEMFLATABSID>;
  def laneid_inst : HSAILInstBasic_0Op<"laneid", BrigOpcode.LANEID>;
  def waveid_inst : HSAILInstBasic_0Op<"waveid", BrigOpcode.WAVEID>;
  def maxwaveid_inst : HSAILInstBasic_0Op<"maxwaveid", BrigOpcode.MAXWAVEID>;

  let hasSideEffects = 1 in {
    def clock_inst : HSAILInstBasic_0Op<"clock", BrigOpcode.CLOCK>;
    def cuid_inst : HSAILInstBasic_0Op<"cuid", BrigOpcode.CUID>;
  }
}

def : InstBasic_1Op_Pat<workitemabsid_inst, int_HSAIL_get_global_id, i32, BrigTypeX.U32>;
def : InstBasic_1Op_Pat<workgroupid_inst, int_HSAIL_get_group_id, i32, BrigTypeX.U32>;
def : InstBasic_1Op_Pat<workitemid_inst, int_HSAIL_get_local_id, i32, BrigTypeX.U32>;
def : InstBasic_1Op_Pat<workgroupsize_inst, int_HSAIL_workgroup_size, i32, BrigTypeX.U32>;
def : InstBasic_1Op_Pat<currentworkgroupsize_inst, int_HSAIL_currentworkgroup_size, i32, BrigTypeX.U32>;
def : InstBasic_1Op_Pat<gridgroups_inst, int_HSAIL_get_num_groups, i32, BrigTypeX.U32>;
def : InstBasic_1Op_Pat<gridsize_inst, int_HSAIL_get_global_size, i32, BrigTypeX.U32>;

def : InstBasic_0Op_Pat<dim_inst, int_HSAIL_get_work_dim, i32, BrigTypeX.U32>;
def : InstBasic_0Op_Pat<workitemflatid_inst, int_HSAIL_workitemid_flat, i32, BrigTypeX.U32>;
def : InstBasic_0Op_Pat<workitemflatabsid_inst, int_HSAIL_workitemid_flatabs, i32, BrigTypeX.U32>;
def : InstBasic_0Op_Pat<laneid_inst, int_HSAIL_get_lane_id, i32, BrigTypeX.U32>;
def : InstBasic_0Op_Pat<waveid_inst, int_HSAIL_get_dynwave_id, i32, BrigTypeX.U32>;
def : InstBasic_0Op_Pat<maxwaveid_inst, int_HSAIL_get_maxdynwave_id, i32, BrigTypeX.U32>;


def : InstBasic_0Op_Pat<clock_inst, int_HSAIL_get_clock, i64, BrigTypeX.U64>;
def : InstBasic_0Op_Pat<cuid_inst, int_HSAIL_get_cu, i32, BrigTypeX.U32>;



let isNotDuplicable = 1, isBarrier = 1 in {
  def barrier_inst : HSAILInstBr_0Op_NoRet<"barrier", BrigOpcode.BARRIER>;
  def wavebarrier_inst : HSAILInstBr_0Op_NoRet<"wavebarrier", BrigOpcode.WAVEBARRIER>;
}

def : InstBr_0Op_NoRet_Pat<barrier_inst, int_HSAIL_barrier, BrigWidth._ALL>;
def : InstBr_0Op_NoRet_Pat<wavebarrier_inst, int_HSAIL_wavebarrier, BrigWidth._WAVESIZE>;

////////////////////////////////////////////////////////////////////////////////
// SYNC OCL 2.0

def memfence_inst : InstMemFence<"memfence", BrigOpcode.MEMFENCE>;

def : Pat<
  (int_HSAIL_memfence (i32 imm:$order),
                      (i32 imm:$globalscope),
                      (i32 imm:$groupscope),
                      (i32 imm:$imagescope)),
  (memfence_inst imm:$order,
                 imm:$globalscope,
                 imm:$groupscope,
                 imm:$imagescope)
>;



def activelaneshuffle_inst :
  HSAILInstLane_ActiveLaneShuffle<"activelaneshuffle",
                                   BrigOpcode.ACTIVELANESHUFFLE>;

def : ActiveLaneShufflePat<activelaneshuffle_inst,
                           HSAILactivelaneshuffle, i32, BrigTypeX.B32>;
def : ActiveLaneShufflePat<activelaneshuffle_inst,
                           HSAILactivelaneshuffle, i64, BrigTypeX.B64>;

def activelaneid_inst : HSAILInstLane_0Op<"activelaneid", BrigOpcode.ACTIVELANEID>;
def : ActiveLaneIdPat<activelaneid_inst, HSAILactivelaneid, i32, BrigTypeX.U32>;

def activelanecount_inst : HSAILInstLane_1Op<"activelanecount", BrigOpcode.ACTIVELANECOUNT>;
def : ActiveLaneCountPat<activelanecount_inst, HSAILactivelanecount, i32, BrigTypeX.U32>;

let isAsCheapAsAMove = 1, isReMaterializable = 1 in {
  def nullptr_inst : HSAILInstSeg_0Op<"nullptr", BrigOpcode.NULLPTR>;
}

def : InstSeg_0Op_Pat<nullptr_inst, int_HSAIL_nullptr_group, i32, BrigTypeX.U32, AddressSpace.GROUP>;
def : InstSeg_0Op_Pat<nullptr_inst, int_HSAIL_nullptr_private, i32, BrigTypeX.U32, AddressSpace.PRIVATE>;

let Predicates = [In64BitMode] in {
  def : InstSeg_0Op_Pat<nullptr_inst, int_HSAIL_nullptr_global, i64, BrigTypeX.U64, AddressSpace.GLOBAL>;
  def : InstSeg_0Op_Pat<nullptr_inst, int_HSAIL_nullptr_flat, i64, BrigTypeX.U64, AddressSpace.FLAT>;
  def : InstSeg_0Op_Pat<nullptr_inst, int_HSAIL_nullptr_readonly, i64, BrigTypeX.U64, AddressSpace.READONLY>;
  def : InstSeg_0Op_Pat<nullptr_inst, int_HSAIL_nullptr_kernarg, i64, BrigTypeX.U64, AddressSpace.KERNARG>;
}

let Predicates = [In32BitMode] in {
  def : InstSeg_0Op_Pat<nullptr_inst, int_HSAIL_nullptr_global, i32, BrigTypeX.U32, AddressSpace.GLOBAL>;
  def : InstSeg_0Op_Pat<nullptr_inst, int_HSAIL_nullptr_flat, i32, BrigTypeX.U32, AddressSpace.FLAT>;
  def : InstSeg_0Op_Pat<nullptr_inst, int_HSAIL_nullptr_readonly, i32, BrigTypeX.U32, AddressSpace.READONLY>;
  def : InstSeg_0Op_Pat<nullptr_inst, int_HSAIL_nullptr_kernarg, i32, BrigTypeX.U32, AddressSpace.KERNARG>;
}

let isAsCheapAsAMove = 1, isReMaterializable = 1 in {
  def kernargbaseptr_inst : HSAILInstBasic_0Op<"kernargbaseptr", BrigOpcode.KERNARGBASEPTR>;
}

let Predicates = [In64BitMode] in {
  def : InstBasic_0Op_Pat<kernargbaseptr_inst, HSAILkernargbaseptr, i64, BrigTypeX.U64>;
}

let Predicates = [In32BitMode] in {
  def : InstBasic_0Op_Pat<kernargbaseptr_inst, HSAILkernargbaseptr, i32, BrigTypeX.U32>;
}


// Cross-Lane Operations
def activelanemask_inst : HSAILInstLane_ActiveLaneMask<"activelanemask", BrigOpcode.ACTIVELANEMASK>;

