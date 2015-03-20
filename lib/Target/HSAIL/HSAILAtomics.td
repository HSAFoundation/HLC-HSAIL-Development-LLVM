////////////////////////////////////////////////////////////////////////////////
// atomics

let mayLoad = 1, mayStore = 1, hasSideEffects = 1, HasDefaultSegment = 1 in {
  def GCN_ATOMIC_APPEND : HSAILInstAddr_1Op<"gcn_atomic_append", BrigOpcode.GCNAPPEND>;
  def GCN_ATOMIC_CONSUME : HSAILInstAddr_1Op<"gcn_atomic_consume", BrigOpcode.GCNCONSUME>;
}

def : InstAddr_1Op_Pat<
  GCN_ATOMIC_APPEND,
  int_HSAIL_gcn_atomic_append_u32,
  BrigTypeX.U32,
  AddressSpace.REGION
>;

def : InstAddr_1Op_Pat<
  GCN_ATOMIC_CONSUME,
  int_HSAIL_gcn_atomic_consume_u32,
  BrigTypeX.U32,
  AddressSpace.REGION
>;

// We must define a new opcode for each atomic operation because we
// can't change the properties of the instruction based on the
// operation modifier operand. e.g. mayLoad must always be the same
// for different instances of the instruction.
multiclass InstAtomicOp<string opName, bits<16> brigVal> {
  def _ADD : InstAtomic<opName#"_add", brigVal, BrigAtomicOperation.ADD, "atomicnoret_add">;
  def _AND : InstAtomic<opName#"_and", brigVal, BrigAtomicOperation.AND, "atomicnoret_and">;
  def _CAS : InstAtomic<opName#"_cas", brigVal, BrigAtomicOperation.CAS, "atomicnoret_cas">;
  def _EXCH : InstAtomic<opName#"_exch", brigVal, BrigAtomicOperation.EXCH>;

  let mayStore = 0 in {
    def _LD : InstAtomic<opName#"_ld", brigVal, BrigAtomicOperation.LD>;
  }

  def _MAX : InstAtomic<opName#"_max", brigVal, BrigAtomicOperation.MAX, "atomicnoret_max">;
  def _MIN : InstAtomic<opName#"_min", brigVal, BrigAtomicOperation.MIN, "atomicnoret_min">;
  def _OR : InstAtomic<opName#"_or", brigVal, BrigAtomicOperation.OR, "atomicnoret_or">;

  def _SUB : InstAtomic<opName#"_sub", brigVal, BrigAtomicOperation.SUB, "atomicnoret_sub">;
  def _WRAPDEC : InstAtomic<opName#"_wrapdec", brigVal, BrigAtomicOperation.WRAPDEC, "atomicnoret_wrapdec">;
  def _WRAPINC : InstAtomic<opName#"_wrapinc", brigVal, BrigAtomicOperation.WRAPINC, "atomicnoret_wrapinc">;
  def _XOR : InstAtomic<opName#"_xor", brigVal, BrigAtomicOperation.XOR, "atomicnoret_xor">;
}

let hasPostISelHook = 1 in {
  defm ATOMIC : InstAtomicOp<"atomic", BrigOpcode.ATOMIC>;
}

multiclass InstAtomicOp_NoRet<string opName, bits<16> brigVal> {
  def _ADD : InstAtomic_NoRet<opName#"_add", brigVal, BrigAtomicOperation.ADD>;
  def _AND : InstAtomic_NoRet<opName#"_and", brigVal, BrigAtomicOperation.AND>;
  def _CAS : InstAtomic_NoRet<opName#"_cas", brigVal, BrigAtomicOperation.CAS>;
  def _EXCH : InstAtomic_NoRet<opName#"_exch", brigVal, BrigAtomicOperation.EXCH>;
  def _LD : InstAtomic_NoRet<opName#"_ld", brigVal, BrigAtomicOperation.LD>;
  def _MAX : InstAtomic_NoRet<opName#"_max", brigVal, BrigAtomicOperation.MAX>;
  def _MIN : InstAtomic_NoRet<opName#"_min", brigVal, BrigAtomicOperation.MIN>;
  def _OR : InstAtomic_NoRet<opName#"_or", brigVal, BrigAtomicOperation.OR>;

  let mayLoad = 0 in {
    def _ST : InstAtomic_NoRet<opName#"_st", brigVal, BrigAtomicOperation.ST>;
  }

  def _SUB : InstAtomic_NoRet<opName#"_sub", brigVal, BrigAtomicOperation.SUB>;
  def _WRAPDEC : InstAtomic_NoRet<opName#"_wrapdec", brigVal, BrigAtomicOperation.WRAPDEC>;
  def _WRAPINC : InstAtomic_NoRet<opName#"_wrapinc", brigVal, BrigAtomicOperation.WRAPINC>;
  def _XOR : InstAtomic_NoRet<opName#"_xor", brigVal, BrigAtomicOperation.XOR>;
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

defm : AtomicPat_0Op_BitTypes<ATOMIC_LD, atomic_load>;
defm : AtomicPat_1Op_NoRet_BitTypes<ATOMICNORET_ST, atomic_store>;

defm : AtomicPat_1Op_BitTypes<ATOMIC_EXCH, atomic_swap>;
defm : AtomicPat_1Op_IntTypes<ATOMIC_ADD, atomic_load_add>;
defm : AtomicPat_1Op_IntTypes<ATOMIC_SUB, atomic_load_sub>;
defm : AtomicPat_1Op_BitTypes<ATOMIC_AND, atomic_load_and>;
defm : AtomicPat_1Op_BitTypes<ATOMIC_OR, atomic_load_or>;
defm : AtomicPat_1Op_BitTypes<ATOMIC_XOR, atomic_load_xor>;
defm : AtomicPat_1Op_IntTypes<ATOMIC_MIN, atomic_load_min, 1>;
defm : AtomicPat_1Op_IntTypes<ATOMIC_MAX, atomic_load_max, 1>;
defm : AtomicPat_1Op_IntTypes<ATOMIC_MIN, atomic_load_umin>;
defm : AtomicPat_1Op_IntTypes<ATOMIC_MAX, atomic_load_umax>;

defm : AtomicPat_2Op_BitTypes<ATOMIC_CAS, atomic_cmp_swap>;
