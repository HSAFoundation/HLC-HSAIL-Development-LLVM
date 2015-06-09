//===------------------------------------------------------*- tablegen -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

////////////////////////////////////////////////////////////////////////////////
// special operations

let isAsCheapAsAMove = 1 in {
  let isReMaterializable = 1 in {
    def CURRENTWORKGROUPSIZE_U32 : HSAILInstBasic_1Op<"currentworkgroupsize", BrigOpcode.CURRENTWORKGROUPSIZE, Inst_U32_U32>;
  }

  def CURRENTWORKITEMFLATID_U32 : HSAILInstBasic_0Op<"currentworkitemflatid", BrigOpcode.CURRENTWORKITEMFLATID, Inst_U32>;
  def DIM_U32 : HSAILInstBasic_0Op<"dim", BrigOpcode.DIM, Inst_U32>;

  let isReMaterializable = 1 in {
    def GRIDGROUPS_U32 : HSAILInstBasic_1Op<"gridgroups", BrigOpcode.GRIDGROUPS, Inst_U32_U32>;
    defm GRIDSIZE : InstBasic_1Op_U32ImmSrc<"gridsize", BrigOpcode.GRIDSIZE>;
  }

  def PACKETID_U64 : HSAILInstBasic_0Op<"packetid", BrigOpcode.PACKETID, Inst_U64>;

  let isReMaterializable = 1 in {
    def WORKGROUPID_U32 : HSAILInstBasic_1Op<"workgroupid", BrigOpcode.WORKGROUPID, Inst_U32_U32>;
    def WORKGROUPSIZE_U32 : HSAILInstBasic_1Op<"workgroupsize", BrigOpcode.WORKGROUPSIZE, Inst_U32_U32>;
    defm WORKITEMABSID : InstBasic_1Op_U32ImmSrc<"workitemabsid", BrigOpcode.WORKITEMABSID>;
  }

  defm WORKITEMFLATABSID : InstBasic_0Op_UnsignedIntTypes<"workitemflatabsid", BrigOpcode.WORKITEMFLATABSID>;
  def WORKITEMFLATID_U32 : HSAILInstBasic_0Op<"workitemflatid", BrigOpcode.WORKITEMFLATID, Inst_U32>;

  let isReMaterializable = 1 in {
    def WORKITEMID_U32 : HSAILInstBasic_1Op<"workitemid", BrigOpcode.WORKITEMID, Inst_U32_U32>;
  }

  let hasSideEffects = 1 in {
    def CLOCK_U64 : HSAILInstBasic_0Op<"clock", BrigOpcode.CLOCK, Inst_U64>;
    def CUID_U32 : HSAILInstBasic_0Op<"cuid", BrigOpcode.CUID, Inst_U32>;
  }

  def LANEID_U32 : HSAILInstBasic_0Op<"laneid", BrigOpcode.LANEID, Inst_U32>;
  def MAXCUID_U32 : HSAILInstBasic_0Op<"maxcuid", BrigOpcode.MAXCUID, Inst_U32>;
  def MAXWAVEID_U32 : HSAILInstBasic_0Op<"maxwaveid", BrigOpcode.MAXWAVEID, Inst_U32>;
  def WAVEID_U32 : HSAILInstBasic_0Op<"waveid", BrigOpcode.WAVEID, Inst_U32>;
}


def : InstBasic_1Op_Pat<CURRENTWORKGROUPSIZE_U32, int_hsail_currentworkgroupsize, i32, BrigType.U32>;
def : InstBasic_0Op_Pat<CURRENTWORKITEMFLATID_U32, int_hsail_currentworkitemflatid, i32, BrigType.U32>;
def : InstBasic_0Op_Pat<DIM_U32, int_hsail_dim, i32, BrigType.U32>;
def : InstBasic_1Op_Pat<GRIDGROUPS_U32, int_hsail_gridgroups, i32, BrigType.U32>;
def : GridSize_Pat<GRIDSIZE_U32, int_hsail_gridsize, i32, BrigType.U32>;
def : GridSize_Pat<GRIDSIZE_U64, int_hsail_gridsize, i64, BrigType.U64>;
def : InstBasic_0Op_Pat<PACKETID_U64, int_hsail_packetid, i64, BrigType.U64>;
def : InstBasic_1Op_Pat<WORKGROUPID_U32, int_hsail_workgroupid, i32, BrigType.U32>;
def : InstBasic_1Op_Pat<WORKGROUPSIZE_U32, int_hsail_workgroupsize, i32, BrigType.U32>;
def : GridSize_Pat<WORKITEMABSID_U32, int_hsail_workitemabsid, i32, BrigType.U32>;
def : GridSize_Pat<WORKITEMABSID_U64, int_hsail_workitemabsid, i64, BrigType.U64>;
def : InstBasic_0Op_Pat<WORKITEMFLATABSID_U32, int_hsail_workitemflatabsid, i32, BrigType.U32>;
def : InstBasic_0Op_Pat<WORKITEMFLATABSID_U64, int_hsail_workitemflatabsid, i64, BrigType.U64>;
def : InstBasic_0Op_Pat<WORKITEMFLATID_U32, int_hsail_workitemflatid, i32, BrigType.U32>;
def : InstBasic_1Op_Pat<WORKITEMID_U32, int_hsail_workitemid, i32, BrigType.U32>;


// Legacy intrinsic names
def : InstBasic_1Op_Pat<CURRENTWORKGROUPSIZE_U32, int_HSAIL_currentworkgroup_size, i32, BrigType.U32>;
def : InstBasic_0Op_Pat<DIM_U32, int_HSAIL_get_work_dim, i32, BrigType.U32>;
def : InstBasic_1Op_Pat<GRIDGROUPS_U32, int_HSAIL_get_num_groups, i32, BrigType.U32>;
def : InstBasic_1Op_Pat<GRIDSIZE_U32, int_HSAIL_get_global_size, i32, BrigType.U32>;
def : InstBasic_1Op_Pat<WORKGROUPID_U32, int_HSAIL_get_group_id, i32, BrigType.U32>;
def : InstBasic_1Op_Pat<WORKGROUPSIZE_U32, int_HSAIL_workgroup_size, i32, BrigType.U32>;
def : InstBasic_1Op_Pat<WORKITEMABSID_U32, int_HSAIL_get_global_id, i32, BrigType.U32>;
def : InstBasic_0Op_Pat<WORKITEMFLATABSID_U32, int_HSAIL_workitemid_flatabs, i32, BrigType.U32>;
def : InstBasic_0Op_Pat<WORKITEMFLATID_U32, int_HSAIL_workitemid_flat, i32, BrigType.U32>;
def : InstBasic_1Op_Pat<WORKITEMID_U32, int_HSAIL_get_local_id, i32, BrigType.U32>;


def : InstBasic_0Op_Pat<CLOCK_U64, int_hsail_clock, i64, BrigType.U64>;
def : InstBasic_0Op_Pat<CUID_U32, int_hsail_cuid, i32, BrigType.U32>;
def : InstBasic_0Op_Pat<LANEID_U32, int_hsail_laneid, i32, BrigType.U32>;
def : InstBasic_0Op_Pat<MAXCUID_U32, int_hsail_maxcuid, i32, BrigType.U32>;
def : InstBasic_0Op_Pat<MAXWAVEID_U32, int_hsail_maxwaveid, i32, BrigType.U32>;
def : InstBasic_0Op_Pat<WAVEID_U32, int_hsail_waveid, i32, BrigType.U32>;


def : InstBasic_0Op_Pat<CLOCK_U64, int_HSAIL_get_clock, i64, BrigType.U64>;
def : InstBasic_0Op_Pat<CUID_U32, int_HSAIL_get_cu, i32, BrigType.U32>;
def : InstBasic_0Op_Pat<LANEID_U32, int_HSAIL_get_lane_id, i32, BrigType.U32>;
def : InstBasic_0Op_Pat<WAVEID_U32, int_HSAIL_get_dynwave_id, i32, BrigType.U32>;
def : InstBasic_0Op_Pat<MAXWAVEID_U32, int_HSAIL_get_maxdynwave_id, i32, BrigType.U32>;


let isNotDuplicable = 1, isBarrier = 1 in {
  def BARRIER : HSAILInstBr_0Op_NoRet<"barrier", BrigOpcode.BARRIER> {
    let WidthAttr = WidthAttrValues.ALL;
  }

  def WAVEBARRIER : HSAILInstBr_0Op_NoRet<"wavebarrier", BrigOpcode.WAVEBARRIER> {
    let WidthAttr = WidthAttrValues.WAVESIZE;
  }
}

def : InstBr_0Op_NoRet_Intrin_Pat<BARRIER, int_hsail_barrier>;

def : InstBr_0Op_NoRet_Pat<BARRIER, int_HSAIL_barrier, BrigWidth._ALL>;
def : InstBr_0Op_NoRet_Pat<WAVEBARRIER, int_HSAIL_wavebarrier, BrigWidth._WAVESIZE>;
def : InstBr_0Op_NoRet_Pat<WAVEBARRIER, int_hsail_wavebarrier, BrigWidth._WAVESIZE>;


////////////////////////////////////////////////////////////////////////////////
// SYNC OCL 2.0

def MEMFENCE : InstMemFence<"memfence", BrigOpcode.MEMFENCE>;

def : Pat<
  (int_HSAIL_memfence (i32 imm:$order), (i32 imm:$scope)),
  (MEMFENCE imm:$order, imm:$scope)
>;

def : Pat<
  (int_hsail_memfence (i32 imm:$order), (i32 imm:$scope)),
  (MEMFENCE imm:$order, imm:$scope)
>;


def IMAGEFENCE : HSAILInstBasic_0Op_NoRet<"imagefence", BrigOpcode.IMAGEFENCE, Inst_Void>;
def : InstBasic_0Op_NoRet_Pat<IMAGEFENCE, int_hsail_imagefence>;


defm ACTIVELANEPERMUTE :
  InstLane_ActiveLanePermute_Types<"activelanepermute",
                                   BrigOpcode.ACTIVELANEPERMUTE>;

def : ActiveLanePermutePat<ACTIVELANEPERMUTE_B32,
                           HSAILactivelanepermute, i32, BrigType.B32>;
def : ActiveLanePermutePat<ACTIVELANEPERMUTE_B64,
                           HSAILactivelanepermute, i64, BrigType.B64>;

def ACTIVELANEID_U32 : HSAILInstLane_0Op<"activelaneid", BrigOpcode.ACTIVELANEID, Inst_U32>;
def : ActiveLaneIdPat<ACTIVELANEID_U32, HSAILactivelaneid, i32, BrigType.U32>;

def ACTIVELANECOUNT_U32_B1 : HSAILInstLane_1Op<"activelanecount", BrigOpcode.ACTIVELANECOUNT, Inst_U32_B1>;
def : ActiveLaneCountPat<ACTIVELANECOUNT_U32_B1, HSAILactivelanecount, i32, BrigType.U32>;

let isAsCheapAsAMove = 1, isReMaterializable = 1 in {
  defm NULLPTR : InstSeg_0Op_PtrTypes<"nullptr", BrigOpcode.NULLPTR>;
}

def : InstSeg_0Op_Pat<NULLPTR_U32, int_HSAIL_nullptr_group, i32, BrigType.U32, AddressSpace.GROUP>;
def : InstSeg_0Op_Pat<NULLPTR_U32, int_HSAIL_nullptr_private, i32, BrigType.U32, AddressSpace.PRIVATE>;

let Predicates = [LargeModel] in {
  def : InstSeg_0Op_Pat<NULLPTR_U64, int_HSAIL_nullptr_global, i64, BrigType.U64, AddressSpace.FLAT>; // Same as flat.
  def : InstSeg_0Op_Pat<NULLPTR_U64, int_HSAIL_nullptr_flat, i64, BrigType.U64, AddressSpace.FLAT>;
  def : InstSeg_0Op_Pat<NULLPTR_U64, int_HSAIL_nullptr_readonly, i64, BrigType.U64, AddressSpace.FLAT>; // Same as flat.
  def : InstSeg_0Op_Pat<NULLPTR_U64, int_HSAIL_nullptr_kernarg, i64, BrigType.U64, AddressSpace.KERNARG>;
}

let Predicates = [SmallModel] in {
  def : InstSeg_0Op_Pat<NULLPTR_U32, int_HSAIL_nullptr_global, i32, BrigType.U32, AddressSpace.FLAT>; // Same as flat.
  def : InstSeg_0Op_Pat<NULLPTR_U32, int_HSAIL_nullptr_flat, i32, BrigType.U32, AddressSpace.FLAT>;
  def : InstSeg_0Op_Pat<NULLPTR_U32, int_HSAIL_nullptr_readonly, i32, BrigType.U32, AddressSpace.FLAT>; // Same as flat.
  def : InstSeg_0Op_Pat<NULLPTR_U32, int_HSAIL_nullptr_kernarg, i32, BrigType.U32, AddressSpace.KERNARG>;
}

let isAsCheapAsAMove = 1, isReMaterializable = 1 in {
  def GROUPBASEPTR_U32 : HSAILInstBasic_0Op<"groupbaseptr", BrigOpcode.GROUPBASEPTR, Inst_U32>;
  defm KERNARGBASEPTR : InstBasic_0Op_UnsignedIntTypes<"kernargbaseptr", BrigOpcode.KERNARGBASEPTR>;

}

def : InstBasic_0Op_Pat<GROUPBASEPTR_U32, int_hsail_groupbaseptr, i32, BrigType.U32>;
def : InstBasic_0Op_Pat<KERNARGBASEPTR_U64, HSAILkernargbaseptr, i64, BrigType.U64>;
def : InstBasic_0Op_Pat<KERNARGBASEPTR_U32, HSAILkernargbaseptr, i32, BrigType.U32>;

// Cross-Lane Operations
def ACTIVELANEMASK_V4_B64_B1 : HSAILInstLane_ActiveLaneMask<"activelanemask", BrigOpcode.ACTIVELANEMASK>;

