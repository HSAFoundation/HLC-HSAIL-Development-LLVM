////////////////////////////////////////////////////////////////////////////////
// special operations

let isAsCheapAsAMove = 1 in {
  let isReMaterializable = 1 in {
    def WORKITEMABSID : HSAILInstBasic_1Op<"workitemabsid", BrigOpcode.WORKITEMABSID>;
    def WORKGROUPID : HSAILInstBasic_1Op<"workgroupid", BrigOpcode.WORKGROUPID>;
    def WORKITEMID : HSAILInstBasic_1Op<"workitemid", BrigOpcode.WORKITEMID>;
    def WORKGROUPSIZE : HSAILInstBasic_1Op<"workgroupsize", BrigOpcode.WORKGROUPSIZE>;
    def CURRENTWORKGROUPSIZE : HSAILInstBasic_1Op<"currentworkgroupsize", BrigOpcode.CURRENTWORKGROUPSIZE>;
    def GRIDGROUPS : HSAILInstBasic_1Op<"gridgroups", BrigOpcode.GRIDGROUPS>;
    def GRIDSIZE : HSAILInstBasic_1Op<"gridsize", BrigOpcode.GRIDSIZE>;
  }

  def DIM : HSAILInstBasic_0Op<"dim", BrigOpcode.DIM>;
  def WORKITEMFLATID : HSAILInstBasic_0Op<"workitemflatid", BrigOpcode.WORKITEMFLATID>;
  def WORKITEMFLATABSID : HSAILInstBasic_0Op<"workitemflatabsid", BrigOpcode.WORKITEMFLATABSID>;
  def LANEID : HSAILInstBasic_0Op<"laneid", BrigOpcode.LANEID>;
  def WAVEID : HSAILInstBasic_0Op<"waveid", BrigOpcode.WAVEID>;
  def MAXWAVEID : HSAILInstBasic_0Op<"maxwaveid", BrigOpcode.MAXWAVEID>;

  let hasSideEffects = 1 in {
    def CLOCK : HSAILInstBasic_0Op<"clock", BrigOpcode.CLOCK>;
    def CUID : HSAILInstBasic_0Op<"cuid", BrigOpcode.CUID>;
  }
}

def : InstBasic_1Op_Pat<WORKITEMABSID, int_HSAIL_get_global_id, i32, BrigTypeX.U32>;
def : InstBasic_1Op_Pat<WORKGROUPID, int_HSAIL_get_group_id, i32, BrigTypeX.U32>;
def : InstBasic_1Op_Pat<WORKITEMID, int_HSAIL_get_local_id, i32, BrigTypeX.U32>;
def : InstBasic_1Op_Pat<WORKGROUPSIZE, int_HSAIL_workgroup_size, i32, BrigTypeX.U32>;
def : InstBasic_1Op_Pat<CURRENTWORKGROUPSIZE, int_HSAIL_currentworkgroup_size, i32, BrigTypeX.U32>;
def : InstBasic_1Op_Pat<GRIDGROUPS, int_HSAIL_get_num_groups, i32, BrigTypeX.U32>;
def : InstBasic_1Op_Pat<GRIDSIZE, int_HSAIL_get_global_size, i32, BrigTypeX.U32>;

def : InstBasic_0Op_Pat<DIM, int_HSAIL_get_work_dim, i32, BrigTypeX.U32>;
def : InstBasic_0Op_Pat<WORKITEMFLATID, int_HSAIL_workitemid_flat, i32, BrigTypeX.U32>;
def : InstBasic_0Op_Pat<WORKITEMFLATABSID, int_HSAIL_workitemid_flatabs, i32, BrigTypeX.U32>;
def : InstBasic_0Op_Pat<LANEID, int_HSAIL_get_lane_id, i32, BrigTypeX.U32>;
def : InstBasic_0Op_Pat<WAVEID, int_HSAIL_get_dynwave_id, i32, BrigTypeX.U32>;
def : InstBasic_0Op_Pat<MAXWAVEID, int_HSAIL_get_maxdynwave_id, i32, BrigTypeX.U32>;


def : InstBasic_0Op_Pat<CLOCK, int_HSAIL_get_clock, i64, BrigTypeX.U64>;
def : InstBasic_0Op_Pat<CUID, int_HSAIL_get_cu, i32, BrigTypeX.U32>;



let isNotDuplicable = 1, isBarrier = 1 in {
  def BARRIER : HSAILInstBr_0Op_NoRet<"barrier", BrigOpcode.BARRIER>;
  def WAVEBARRIER : HSAILInstBr_0Op_NoRet<"wavebarrier", BrigOpcode.WAVEBARRIER>;
}

def : InstBr_0Op_NoRet_Pat<BARRIER, int_HSAIL_barrier, BrigWidth._ALL>;
def : InstBr_0Op_NoRet_Pat<WAVEBARRIER, int_HSAIL_wavebarrier, BrigWidth._WAVESIZE>;

////////////////////////////////////////////////////////////////////////////////
// SYNC OCL 2.0

def MEMFENCE : InstMemFence<"memfence", BrigOpcode.MEMFENCE>;

def : Pat<
  (int_HSAIL_memfence (i32 imm:$order),
                      (i32 imm:$globalscope),
                      (i32 imm:$groupscope),
                      (i32 imm:$imagescope)),
  (MEMFENCE imm:$order,
            imm:$globalscope,
            imm:$groupscope,
            imm:$imagescope)
>;



def ACTIVELANESHUFFLE :
  HSAILInstLane_ActiveLaneShuffle<"activelaneshuffle",
                                   BrigOpcode.ACTIVELANESHUFFLE>;

def : ActiveLaneShufflePat<ACTIVELANESHUFFLE,
                           HSAILactivelaneshuffle, i32, BrigTypeX.B32>;
def : ActiveLaneShufflePat<ACTIVELANESHUFFLE,
                           HSAILactivelaneshuffle, i64, BrigTypeX.B64>;

def ACTIVELANEID : HSAILInstLane_0Op<"activelaneid", BrigOpcode.ACTIVELANEID>;
def : ActiveLaneIdPat<ACTIVELANEID, HSAILactivelaneid, i32, BrigTypeX.U32>;

def ACTIVELANECOUNT : HSAILInstLane_1Op<"activelanecount", BrigOpcode.ACTIVELANECOUNT>;
def : ActiveLaneCountPat<ACTIVELANECOUNT, HSAILactivelanecount, i32, BrigTypeX.U32>;

let isAsCheapAsAMove = 1, isReMaterializable = 1 in {
  def NULLPTR : HSAILInstSeg_0Op<"nullptr", BrigOpcode.NULLPTR>;
}

def : InstSeg_0Op_Pat<NULLPTR, int_HSAIL_nullptr_group, i32, BrigTypeX.U32, AddressSpace.GROUP>;
def : InstSeg_0Op_Pat<NULLPTR, int_HSAIL_nullptr_private, i32, BrigTypeX.U32, AddressSpace.PRIVATE>;

let Predicates = [In64BitMode] in {
  def : InstSeg_0Op_Pat<NULLPTR, int_HSAIL_nullptr_global, i64, BrigTypeX.U64, AddressSpace.GLOBAL>;
  def : InstSeg_0Op_Pat<NULLPTR, int_HSAIL_nullptr_flat, i64, BrigTypeX.U64, AddressSpace.FLAT>;
  def : InstSeg_0Op_Pat<NULLPTR, int_HSAIL_nullptr_readonly, i64, BrigTypeX.U64, AddressSpace.READONLY>;
  def : InstSeg_0Op_Pat<NULLPTR, int_HSAIL_nullptr_kernarg, i64, BrigTypeX.U64, AddressSpace.KERNARG>;
}

let Predicates = [In32BitMode] in {
  def : InstSeg_0Op_Pat<NULLPTR, int_HSAIL_nullptr_global, i32, BrigTypeX.U32, AddressSpace.GLOBAL>;
  def : InstSeg_0Op_Pat<NULLPTR, int_HSAIL_nullptr_flat, i32, BrigTypeX.U32, AddressSpace.FLAT>;
  def : InstSeg_0Op_Pat<NULLPTR, int_HSAIL_nullptr_readonly, i32, BrigTypeX.U32, AddressSpace.READONLY>;
  def : InstSeg_0Op_Pat<NULLPTR, int_HSAIL_nullptr_kernarg, i32, BrigTypeX.U32, AddressSpace.KERNARG>;
}

let isAsCheapAsAMove = 1, isReMaterializable = 1 in {
  def KERNARGBASEPTR : HSAILInstBasic_0Op<"kernargbaseptr", BrigOpcode.KERNARGBASEPTR>;
}

let Predicates = [In64BitMode] in {
  def : InstBasic_0Op_Pat<KERNARGBASEPTR, HSAILkernargbaseptr, i64, BrigTypeX.U64>;
}

let Predicates = [In32BitMode] in {
  def : InstBasic_0Op_Pat<KERNARGBASEPTR, HSAILkernargbaseptr, i32, BrigTypeX.U32>;
}


// Cross-Lane Operations
def ACTIVELANEMASK : HSAILInstLane_ActiveLaneMask<"activelanemask", BrigOpcode.ACTIVELANEMASK>;

