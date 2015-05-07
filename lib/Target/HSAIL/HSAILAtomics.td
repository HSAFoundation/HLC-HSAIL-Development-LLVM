//===------------------------------------------------------*- tablegen -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

////////////////////////////////////////////////////////////////////////////////
// atomics

let mayLoad = 1, mayStore = 1, hasSideEffects = 1, HasDefaultSegment = 1 in {
  def GCN_ATOMIC_APPEND_U32 : HSAILInstAddr_1Op<"gcn_atomic_append", BrigOpcode.GCNAPPEND, Inst_U32_U32>;
  def GCN_ATOMIC_CONSUME_U32 : HSAILInstAddr_1Op<"gcn_atomic_consume", BrigOpcode.GCNCONSUME, Inst_U32_U32>;
}

def : InstAddr_1Op_Pat<
  GCN_ATOMIC_APPEND_U32,
  int_HSAIL_gcn_atomic_append_u32,
  BrigType.U32,
  AddressSpace.REGION
>;

def : InstAddr_1Op_Pat<
  GCN_ATOMIC_CONSUME_U32,
  int_HSAIL_gcn_atomic_consume_u32,
  BrigType.U32,
  AddressSpace.REGION
>;

// We must define a new opcode for each atomic operation because we
// can't change the properties of the instruction based on the
// operation modifier operand. e.g. mayLoad must always be the same
// for different instances of the instruction.
multiclass InstAtomicOp<string opName, bits<16> brigVal> {
  defm _ADD : InstAtomic_1Op_IntTypes<opName#"_add", brigVal, BrigAtomicOperation.ADD, "atomicnoret_add">;
  defm _AND : InstAtomic_1Op_BitTypes<opName#"_and", brigVal, BrigAtomicOperation.AND, "atomicnoret_and">;
  defm _CAS : InstAtomic_2Op_BitTypes<opName#"_cas", brigVal, BrigAtomicOperation.CAS>;
  defm _EXCH : InstAtomic_1Op_BitTypes<opName#"_exch", brigVal, BrigAtomicOperation.EXCH>;

  let mayStore = 0 in {
    defm _LD : InstAtomic_0Op_BitTypes<opName#"_ld", brigVal, BrigAtomicOperation.LD>;
  }

  defm _MAX : InstAtomic_1Op_IntTypes<opName#"_max", brigVal, BrigAtomicOperation.MAX, "atomicnoret_max">;
  defm _MIN : InstAtomic_1Op_IntTypes<opName#"_min", brigVal, BrigAtomicOperation.MIN, "atomicnoret_min">;
  defm _OR : InstAtomic_1Op_BitTypes<opName#"_or", brigVal, BrigAtomicOperation.OR, "atomicnoret_or">;

  defm _SUB : InstAtomic_1Op_IntTypes<opName#"_sub", brigVal, BrigAtomicOperation.SUB, "atomicnoret_sub">;
  defm _WRAPDEC : InstAtomic_1Op_IntTypes<opName#"_wrapdec", brigVal, BrigAtomicOperation.WRAPDEC, "atomicnoret_wrapdec">;
  defm _WRAPINC : InstAtomic_1Op_IntTypes<opName#"_wrapinc", brigVal, BrigAtomicOperation.WRAPINC, "atomicnoret_wrapinc">;
  defm _XOR : InstAtomic_1Op_BitTypes<opName#"_xor", brigVal, BrigAtomicOperation.XOR, "atomicnoret_xor">;
}

let hasPostISelHook = 1 in {
  defm ATOMIC : InstAtomicOp<"atomic", BrigOpcode.ATOMIC>;
}

multiclass InstAtomicOp_NoRet<string opName, bits<16> brigVal> {
  defm _ADD : InstAtomic_1Op_NoRet_IntTypes<opName#"_add", brigVal, BrigAtomicOperation.ADD>;
  defm _AND : InstAtomic_1Op_NoRet_BitTypes<opName#"_and", brigVal, BrigAtomicOperation.AND>;
  defm _EXCH : InstAtomic_1Op_NoRet_BitTypes<opName#"_exch", brigVal, BrigAtomicOperation.EXCH>;
  defm _MAX : InstAtomic_1Op_NoRet_IntTypes<opName#"_max", brigVal, BrigAtomicOperation.MAX>;
  defm _MIN : InstAtomic_1Op_NoRet_IntTypes<opName#"_min", brigVal, BrigAtomicOperation.MIN>;
  defm _OR : InstAtomic_1Op_NoRet_BitTypes<opName#"_or", brigVal, BrigAtomicOperation.OR>;

  let mayLoad = 0 in {
    defm _ST : InstAtomic_1Op_NoRet_BitTypes<opName#"_st", brigVal, BrigAtomicOperation.ST>;
  }

  defm _SUB : InstAtomic_1Op_NoRet_IntTypes<opName#"_sub", brigVal, BrigAtomicOperation.SUB>;
  defm _WRAPDEC : InstAtomic_1Op_NoRet_IntTypes<opName#"_wrapdec", brigVal, BrigAtomicOperation.WRAPDEC>;
  defm _WRAPINC : InstAtomic_1Op_NoRet_IntTypes<opName#"_wrapinc", brigVal, BrigAtomicOperation.WRAPINC>;
  defm _XOR : InstAtomic_1Op_NoRet_BitTypes<opName#"_xor", brigVal, BrigAtomicOperation.XOR>;
}


// atomic is replaced by atomicnoret in the post-isel hook if there
// are no uses of the returned value.
defm ATOMICNORET : InstAtomicOp_NoRet<"atomicnoret", BrigOpcode.ATOMICNORET>;


// def atomic_load_inc : PatFrag<
//   (ops node:$ptr),
//   (atomic_load_add node:$ptr, 1)
// >;

// def atomic_load_dec : PatFrag<
//   (ops node:$ptr),
//   (atomic_load_sub node:$ptr, 1)
// >;


// let AddedComplexity = 1 in {
//   defm : AtomicPat_0Op_IntTypes<atomic_inst, atomic_load_inc, BrigAtomicOperation.WRAPINC>;
//   defm : AtomicPat_0Op_IntTypes<atomic_inst, atomic_load_dec, BrigAtomicOperation.WRAPDEC>;
// }

defm : AtomicPat_0Op_BitTypes<"ATOMIC_LD", atomic_load>;
defm : AtomicPat_1Op_NoRet_BitTypes<"ATOMICNORET_ST", atomic_store>;

defm : AtomicPat_1Op_BitTypes<"ATOMIC_EXCH", atomic_swap>;
defm : AtomicPat_1Op_IntTypes<"ATOMIC_ADD", atomic_load_add, 1>;
defm : AtomicPat_1Op_IntTypes<"ATOMIC_SUB", atomic_load_sub, 1>;
defm : AtomicPat_1Op_BitTypes<"ATOMIC_AND", atomic_load_and>;
defm : AtomicPat_1Op_BitTypes<"ATOMIC_OR", atomic_load_or>;
defm : AtomicPat_1Op_BitTypes<"ATOMIC_XOR", atomic_load_xor>;
defm : AtomicPat_1Op_IntTypes<"ATOMIC_MIN", atomic_load_min, 1>;
defm : AtomicPat_1Op_IntTypes<"ATOMIC_MAX", atomic_load_max, 1>;
defm : AtomicPat_1Op_IntTypes<"ATOMIC_MIN", atomic_load_umin, 0>;
defm : AtomicPat_1Op_IntTypes<"ATOMIC_MAX", atomic_load_umax, 0>;

defm : AtomicPat_2Op_BitTypes<"ATOMIC_CAS", atomic_cmp_swap>;
