////////////////////////////////////////////////////////////////////////////////
// atomics

class AtomicRetMap<string base, bit isRet> {
  string AtomicRetBaseOpcode = base;
  bit AtomicIsRet = isRet;
}

def getAtomicNoretVersion : InstrMapping {
  let FilterClass = "AtomicRetMap";
  let RowFields = ["AtomicRetBaseOpcode"];
  let ColFields = ["AtomicIsRet"];
  let KeyCol = ["1"];
  let ValueCols = [["0"]];
}

class AtomicPtr32Map<string base, bit isPtr32> {
  string AtomicPtr32BaseOpcode = base;
  bit AtomicIsPtr32 = isPtr32;
}

def getAtomicPtr32Version : InstrMapping {
  let FilterClass = "AtomicPtr32Map";
  let RowFields = ["AtomicPtr32BaseOpcode"];
  let ColFields = ["AtomicIsPtr32"];
  let KeyCol = ["0"];
  let ValueCols = [["1"]];
}

let mayLoad = 1, mayStore = 1 in {

// gcn atomic append/consume
class AtomicCounter32<Intrinsic intr, string asm>:
    HSAILInst<(outs GPR32:$dest), (ins MEMOP32:$address),
          !strconcat(asm, "\t $dest, [$address]"),
          [(set (i32 GPR32:$dest), (intr ADDR:$address))]>
{
}

let hasAddress = 1, addressOpNum = 1 in {
  def gcn_atomic_append : AtomicCounter32<int_HSAIL_gcn_atomic_append_u32,
      "gcn_atomic_append_u32">;
  def gcn_atomic_consume : AtomicCounter32<int_HSAIL_gcn_atomic_consume_u32,
      "gcn_atomic_consume_u32">;
}

/// Declare atomic opcodes, but don't match. All atomic instructions
/// are custom-lowered in ISelDAGToDAG.
///
/// Instruction format:
/// brig operands : atomic opcode, address space, memory order, memory scope, type
/// atomic_unary  : brig operands, ptr
/// atomic_binary : brig operands, ptr, val
/// atomic_ternary: brig operands, ptr, val1, val2
///
/// enum AtomicNumOps in HSAILUtilityFunctions.cpp must be updated if
/// this format is changed.

multiclass AtomicMaybeRet<dag OutList, dag InList, bit isPtr32, string args> {
  let addressOpNum = 6, hasPostISelHook = 1 in {
    def NAME#_ret   : HSAILInst<OutList, InList,
                               "atomic_$op$segment$order$scope$ty $dest, [$address], "#args, []>,
                      AtomicRetMap<NAME, 1>,
                      AtomicPtr32Map<!subst("_ptr32", "", NAME#_ret), isPtr32>;
  }

  let addressOpNum = 5 in {
    def NAME#_noret : HSAILInst<(outs), InList,
                               "atomic_$op$segment$order$scope$ty [$address], "#args, []>,
                      AtomicRetMap<NAME, 0>,
                      AtomicPtr32Map<!subst("_ptr32", "", NAME#_noret), isPtr32>;
  }
}

let hasAddress = 1, isAtomic = 1 in {
  multiclass AtomicRRInst<dag OutList, RegisterClass inRC, Operand immTy, Operand MemTy, bit isPtr32> {
    let addressOpNum = 6 in {
      def NAME#_unary     :      HSAILInst<OutList,
                                      (ins i32imm:$op, i32imm:$segment, i32imm:$order, i32imm:$scope,
                                           i32imm:$ty, MemTy:$address),
                                      "atomic_$op$segment$order$scope$ty $dest, [$address]", []>,
                                 AtomicPtr32Map<!subst("_ptr32", "", NAME#_unary), isPtr32>;
    }

    defm NAME#_binary_i   : AtomicMaybeRet<OutList,
                                      (ins i32imm:$op, i32imm:$segment, i32imm:$order, i32imm:$scope,
                                           i32imm:$ty, MemTy:$address, immTy:$src0),
                                      isPtr32, "$src0">;
    defm NAME#_binary_r   : AtomicMaybeRet<OutList,
                                      (ins i32imm:$op, i32imm:$segment, i32imm:$order, i32imm:$scope,
                                           i32imm:$ty, MemTy:$address, inRC:$src0),
                                      isPtr32, "$src0">;
    defm NAME#_ternary_ii : AtomicMaybeRet<OutList,
                                      (ins i32imm:$op, i32imm:$segment, i32imm:$order, i32imm:$scope,
                                           i32imm:$ty, MemTy:$address, immTy:$src0, immTy:$src1),
                                      isPtr32, "$src0, $src1">;
    defm NAME#_ternary_ir : AtomicMaybeRet<OutList,
                                      (ins i32imm:$op, i32imm:$segment, i32imm:$order, i32imm:$scope,
                                           i32imm:$ty, MemTy:$address, immTy:$src0, inRC:$src1),
                                      isPtr32, "$src0, $src1">;
    defm NAME#_ternary_ri : AtomicMaybeRet<OutList,
                                      (ins i32imm:$op, i32imm:$segment, i32imm:$order, i32imm:$scope,
                                           i32imm:$ty, MemTy:$address, inRC:$src0, immTy:$src1),
                                      isPtr32, "$src0, $src1">;
    defm NAME#_ternary_rr : AtomicMaybeRet<OutList,
                                      (ins i32imm:$op, i32imm:$segment, i32imm:$order, i32imm:$scope,
                                           i32imm:$ty, MemTy:$address, inRC:$src0, inRC:$src1),
                                      isPtr32, "$src0, $src1">;
  }
}

defm atomic_b32       : AtomicRRInst<(outs GPR32:$dest), GPR32, i32imm, MEMOP, 0>;
defm atomic_b32_ptr32 : AtomicRRInst<(outs GPR32:$dest), GPR32, i32imm, MEMOP32, 1>;
defm atomic_b64       : AtomicRRInst<(outs GPR64:$dest), GPR64, i64imm, MEMOP, 0>;
defm atomic_b64_ptr32 : AtomicRRInst<(outs GPR64:$dest), GPR64, i64imm, MEMOP32, 1>;

}
