////////////////////////////////////////////////////////////////////////////////
// atomics

class AtomicRetMap {
  string AtomicRetBaseOpcode;
  string AtomicIsRet;
}

def getAtomicNoretVersion : InstrMapping {
  let FilterClass = "AtomicRetMap";
  let RowFields = ["AtomicRetBaseOpcode"];
  let ColFields = ["AtomicIsRet"];
  let KeyCol = ["true"];
  let ValueCols = [["false"]];
}

let mayLoad = 1, mayStore = 1 in {

// gcn atomic append/consume
class AtomicCounter32<Intrinsic intr, string asm>:
    HSAILInst<(outs GPR32:$dst), (ins MEMOP:$src),
          !strconcat(asm, "\t $dst, [$src]"),
          [(set (i32 GPR32:$dst), (intr ADDR:$src))]>
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

multiclass AtomicMaybeRet<dag OutList, dag InList> {
  let addressOpNum = 6, hasPostISelHook = 1 in {
    def NAME#_ret   : AtomicRetMap, HSAILInst<OutList, InList, "", []> {
      let AtomicRetBaseOpcode = NAME;
      let AtomicIsRet = "true";
    }
  }

  let addressOpNum = 5 in {
    def NAME#_noret : AtomicRetMap, HSAILInst<(outs), InList, "", []> {
      let AtomicRetBaseOpcode = NAME;
      let AtomicIsRet = "false";
    }
  }
}

let hasAddress = 1, isAtomic = 1 in {
  multiclass AtomicRRInst<dag OutList, RegisterClass inRC, Operand immTy> {
    let addressOpNum = 6 in {
      def NAME#_unary     :      HSAILInst<OutList,
                                      (ins i32imm:$op, i32imm:$as, i32imm:$mo, i32imm:$ms,
                                           i32imm:$ty, MEMOP:$ptr), "", []>;
    }

    defm NAME#_binary_i   : AtomicMaybeRet<OutList,
                                      (ins i32imm:$op, i32imm:$as, i32imm:$mo, i32imm:$ms,
                                           i32imm:$ty, MEMOP:$ptr, immTy:$val0)>;
    defm NAME#_binary_r   : AtomicMaybeRet<OutList,
                                      (ins i32imm:$op, i32imm:$as, i32imm:$mo, i32imm:$ms,
                                           i32imm:$ty, MEMOP:$ptr, inRC:$val0)>;
    defm NAME#_ternary_ii : AtomicMaybeRet<OutList,
                                      (ins i32imm:$op, i32imm:$as, i32imm:$mo, i32imm:$ms,
                                           i32imm:$ty, MEMOP:$ptr, immTy:$val0, immTy:$val1)>;
    defm NAME#_ternary_ir : AtomicMaybeRet<OutList,
                                      (ins i32imm:$op, i32imm:$as, i32imm:$mo, i32imm:$ms,
                                           i32imm:$ty, MEMOP:$ptr, immTy:$val0, inRC:$val1)>;
    defm NAME#_ternary_ri : AtomicMaybeRet<OutList,
                                      (ins i32imm:$op, i32imm:$as, i32imm:$mo, i32imm:$ms,
                                           i32imm:$ty, MEMOP:$ptr, inRC:$val0, immTy:$val1)>;
    defm NAME#_ternary_rr : AtomicMaybeRet<OutList,
                                      (ins i32imm:$op, i32imm:$as, i32imm:$mo, i32imm:$ms,
                                           i32imm:$ty, MEMOP:$ptr, inRC:$val0, inRC:$val1)>;
  }
}

defm atomic_b32 : AtomicRRInst<(outs GPR32:$dst), GPR32, i32imm>;
defm atomic_b64 : AtomicRRInst<(outs GPR64:$dst), GPR64, i64imm>;

}
