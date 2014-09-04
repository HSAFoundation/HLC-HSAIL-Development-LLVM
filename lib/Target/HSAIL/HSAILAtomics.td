////////////////////////////////////////////////////////////////////////////////
// atomics

// gcn atomic append/consume
class AtomicCounter32<Intrinsic intr, string asm>:
    HSAILInst<(outs GPR32:$dst), (ins MEMOP:$src),
          !strconcat(asm, "\t $dst, [$src]"),
          [(set (i32 GPR32:$dst), (intr ADDR:$src))]>
{
}

let needSpecialProcessing = 1, hasAddress = 1, addressOpNum = 1 in {
  def gcn_atomic_append : AtomicCounter32<int_HSAIL_gcn_atomic_append_u32, 
      "gcn_atomic_append_u32">;
  def gcn_atomic_consume : AtomicCounter32<int_HSAIL_gcn_atomic_consume_u32, 
      "gcn_atomic_consume_u32">;
}

/// Atomics have the following instruction format
/// atomic_unary <atomic opcode, address space, memory order, memory scope, ptr>
/// atomic_binary <atomic opcode, address space, memory order, memory scope, ptr, val>
/// atomic_ternary <atomic opcode, address space, memory order, memory scope, ptr, val1, val2>

let needSpecialProcessing = 1, hasAddress = 1, addressOpNum = 5, hasPostISelHook = 1 in {
  def atomic_unary_b32 : HSAILInst<(outs GPR32:$dst), (ins i32imm:$op,
                                    i32imm:$as, i32imm:$mo, i32imm:$ms,
                                    MEMOP:$ptr) , "",[]>;
  def atomic_binary_b32_i : HSAILInst<(outs GPR32:$dst), (ins i32imm:$op,
                                      i32imm:$as, i32imm:$mo, i32imm:$ms,
                                      MEMOP:$ptr, i32imm:$src0) , "",[]>;
  def atomic_binary_b32_r : HSAILInst<(outs GPR32:$dst), (ins i32imm:$op,
                                       i32imm:$as, i32imm:$mo, i32imm:$ms,
                                       MEMOP:$ptr, GPR32:$src0) , "",[]>;
  def atomic_binary_s32_i : HSAILInst<(outs GPR32:$dst), (ins i32imm:$op,
                                       i32imm:$as, i32imm:$mo, i32imm:$ms,
                                       MEMOP:$ptr, i32imm:$src0) , "",[]>;
  def atomic_binary_s32_r : HSAILInst<(outs GPR32:$dst), (ins i32imm:$op,
                                       i32imm:$as, i32imm:$mo, i32imm:$ms,
                                       MEMOP:$ptr, GPR32:$src0) , "",[]>;
  def atomic_binary_u32_i : HSAILInst<(outs GPR32:$dst), (ins i32imm:$op,
                                       i32imm:$as, i32imm:$mo, i32imm:$ms,
                                       MEMOP:$ptr, i32imm:$src0) , "",[]>;
  def atomic_binary_u32_r : HSAILInst<(outs GPR32:$dst), (ins i32imm:$op,
                                       i32imm:$as, i32imm:$mo, i32imm:$ms,
                                       MEMOP:$ptr, GPR32:$src0) , "",[]>;
  def atomic_ternary_b32_ii : HSAILInst<(outs GPR32:$dst), (ins i32imm:$op,
                                        i32imm:$as, i32imm:$mo, i32imm:$ms,
                                        MEMOP:$ptr, i32imm:$src0, i32imm:$src1), "",[]>;
  def atomic_ternary_b32_ir : HSAILInst<(outs GPR32:$dst), (ins i32imm:$op,
                                        i32imm:$as, i32imm:$mo, i32imm:$ms,
                                        MEMOP:$ptr, i32imm:$src0, GPR32:$src1) , "",[]>;
  def atomic_ternary_b32_ri : HSAILInst<(outs GPR32:$dst), (ins i32imm:$op,
                                        i32imm:$as, i32imm:$mo, i32imm:$ms,
                                        MEMOP:$ptr, GPR32:$src0, i32imm:$src1) , "",[]>;
  def atomic_ternary_b32_rr : HSAILInst<(outs GPR32:$dst), (ins i32imm:$op,
                                        i32imm:$as, i32imm:$mo, i32imm:$ms,
                                        MEMOP:$ptr, GPR32:$src0, GPR32:$src1) , "",[]>;
}

let needSpecialProcessing = 1, hasAddress = 1, addressOpNum = 4 in {
  def atomic_binary_b32_i_noret : HSAILInst<(outs), (ins i32imm:$op,
                                            i32imm:$as, i32imm:$mo, i32imm:$ms,
                                            MEMOP:$ptr, i32imm:$src0) , "",[]>;
  def atomic_binary_b32_r_noret : HSAILInst<(outs), (ins i32imm:$op,
                                             i32imm:$as, i32imm:$mo, i32imm:$ms,
                                             MEMOP:$ptr, GPR32:$src0) , "",[]>;
  def atomic_binary_s32_i_noret : HSAILInst<(outs), (ins i32imm:$op,
                                       i32imm:$as, i32imm:$mo, i32imm:$ms,
                                       MEMOP:$ptr, i32imm:$src0) , "",[]>;
  def atomic_binary_s32_r_noret : HSAILInst<(outs), (ins i32imm:$op,
                                             i32imm:$as, i32imm:$mo, i32imm:$ms,
                                             MEMOP:$ptr, GPR32:$src0) , "",[]>;
  def atomic_binary_u32_i_noret : HSAILInst<(outs), (ins i32imm:$op,
                                             i32imm:$as, i32imm:$mo, i32imm:$ms,
                                             MEMOP:$ptr, i32imm:$src0) , "",[]>;
  def atomic_binary_u32_r_noret : HSAILInst<(outs), (ins i32imm:$op,
                                             i32imm:$as, i32imm:$mo, i32imm:$ms,
                                             MEMOP:$ptr, GPR32:$src0) , "",[]>;
  def atomic_ternary_b32_ii_noret : HSAILInst<(outs), (ins i32imm:$op,
                                              i32imm:$as, i32imm:$mo, i32imm:$ms,
                                              MEMOP:$ptr, i32imm:$src0, i32imm:$src1), "",[]>;
  def atomic_ternary_b32_ir_noret : HSAILInst<(outs), (ins i32imm:$op,
                                              i32imm:$as, i32imm:$mo, i32imm:$ms,
                                              MEMOP:$ptr, i32imm:$src0, GPR32:$src1) , "",[]>;
  def atomic_ternary_b32_ri_noret : HSAILInst<(outs), (ins i32imm:$op,
                                              i32imm:$as, i32imm:$mo, i32imm:$ms,
                                              MEMOP:$ptr, GPR32:$src0, i32imm:$src1) , "",[]>;
  def atomic_ternary_b32_rr_noret : HSAILInst<(outs), (ins i32imm:$op,
                                              i32imm:$as, i32imm:$mo, i32imm:$ms,
                                              MEMOP:$ptr, GPR32:$src0, GPR32:$src1) , "",[]>;
}

let needSpecialProcessing = 1, hasAddress = 1, addressOpNum = 5, hasPostISelHook = 1 in {
  def atomic_unary_b64 : HSAILInst<(outs GPR64:$dst), (ins i32imm:$op,
                                    i32imm:$as, i32imm:$mo, i32imm:$ms,
                                    MEMOP:$ptr) , "",[]>;
  def atomic_binary_b64_i : HSAILInst<(outs GPR64:$dst), (ins i32imm:$op,
                                      i32imm:$as, i32imm:$mo, i32imm:$ms,
                                      MEMOP:$ptr, i64imm:$src0) , "",[]>;
  def atomic_binary_b64_r : HSAILInst<(outs GPR64:$dst), (ins i32imm:$op,
                                       i32imm:$as, i32imm:$mo, i32imm:$ms,
                                       MEMOP:$ptr, GPR64:$src0) , "",[]>;
  def atomic_binary_s64_i : HSAILInst<(outs GPR64:$dst), (ins i32imm:$op,
                                       i32imm:$as, i32imm:$mo, i32imm:$ms,
                                       MEMOP:$ptr, i64imm:$src0) , "",[]>;
  def atomic_binary_s64_r : HSAILInst<(outs GPR64:$dst), (ins i32imm:$op,
                                       i32imm:$as, i32imm:$mo, i32imm:$ms,
                                       MEMOP:$ptr, GPR64:$src0) , "",[]>;
  def atomic_binary_u64_i : HSAILInst<(outs GPR64:$dst), (ins i32imm:$op,
                                       i32imm:$as, i32imm:$mo, i32imm:$ms,
                                       MEMOP:$ptr, i64imm:$src0) , "",[]>;
  def atomic_binary_u64_r : HSAILInst<(outs GPR64:$dst), (ins i32imm:$op,
                                       i32imm:$as, i32imm:$mo, i32imm:$ms,
                                       MEMOP:$ptr, GPR64:$src0) , "",[]>;
  def atomic_ternary_b64_ii : HSAILInst<(outs GPR64:$dst), (ins i32imm:$op,
                                        i32imm:$as, i32imm:$mo, i32imm:$ms,
                                        MEMOP:$ptr, i64imm:$src0, i64imm:$src1), "",[]>;
  def atomic_ternary_b64_ir : HSAILInst<(outs GPR64:$dst), (ins i32imm:$op,
                                        i32imm:$as, i32imm:$mo, i32imm:$ms,
                                        MEMOP:$ptr, i64imm:$src0, GPR64:$src1) , "",[]>;
  def atomic_ternary_b64_ri : HSAILInst<(outs GPR64:$dst), (ins i32imm:$op,
                                        i32imm:$as, i32imm:$mo, i32imm:$ms,
                                        MEMOP:$ptr, GPR64:$src0, i64imm:$src1) , "",[]>;
  def atomic_ternary_b64_rr : HSAILInst<(outs GPR64:$dst), (ins i32imm:$op,
                                        i32imm:$as, i32imm:$mo, i32imm:$ms,
                                        MEMOP:$ptr, GPR64:$src0, GPR64:$src1) , "",[]>;
}

let needSpecialProcessing = 1, hasAddress = 1, addressOpNum = 4 in {
  def atomic_binary_b64_i_noret : HSAILInst<(outs), (ins i32imm:$op,
                                            i32imm:$as, i32imm:$mo, i32imm:$ms,
                                            MEMOP:$ptr, i64imm:$src0) , "",[]>;
  def atomic_binary_b64_r_noret : HSAILInst<(outs), (ins i32imm:$op,
                                            i32imm:$as, i32imm:$mo, i32imm:$ms,
                                            MEMOP:$ptr, GPR64:$src0) , "",[]>;
  def atomic_binary_s64_i_noret : HSAILInst<(outs), (ins i32imm:$op,
                                            i32imm:$as, i32imm:$mo, i32imm:$ms,
                                            MEMOP:$ptr, i64imm:$src0) , "",[]>;
  def atomic_binary_s64_r_noret : HSAILInst<(outs), (ins i32imm:$op,
                                            i32imm:$as, i32imm:$mo, i32imm:$ms,
                                            MEMOP:$ptr, GPR64:$src0) , "",[]>;
  def atomic_binary_u64_i_noret : HSAILInst<(outs), (ins i32imm:$op,
                                            i32imm:$as, i32imm:$mo, i32imm:$ms,
                                            MEMOP:$ptr, i64imm:$src0) , "",[]>;
  def atomic_binary_u64_r_noret : HSAILInst<(outs), (ins i32imm:$op,
                                            i32imm:$as, i32imm:$mo, i32imm:$ms,
                                            MEMOP:$ptr, GPR64:$src0) , "",[]>;
  def atomic_ternary_b64_ii_noret : HSAILInst<(outs), (ins i32imm:$op,
                                              i32imm:$as, i32imm:$mo, i32imm:$ms,
                                              MEMOP:$ptr, i64imm:$src0, i64imm:$src1), "",[]>;
  def atomic_ternary_b64_ir_noret : HSAILInst<(outs), (ins i32imm:$op,
                                              i32imm:$as, i32imm:$mo, i32imm:$ms,
                                              MEMOP:$ptr, i64imm:$src0, GPR64:$src1) , "",[]>;
  def atomic_ternary_b64_ri_noret : HSAILInst<(outs), (ins i32imm:$op,
                                              i32imm:$as, i32imm:$mo, i32imm:$ms,
                                              MEMOP:$ptr, GPR64:$src0, i64imm:$src1) , "",[]>;
  def atomic_ternary_b64_rr_noret : HSAILInst<(outs), (ins i32imm:$op,
                                              i32imm:$as, i32imm:$mo, i32imm:$ms,
                                              MEMOP:$ptr, GPR64:$src0, GPR64:$src1) , "",[]>;
}
