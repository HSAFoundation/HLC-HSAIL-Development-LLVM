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

let mayLoad = 1, mayStore = 1, hasSideEffects = 1 in {
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

let hasPostISelHook = 1 in {
  def ATOMIC : InstAtomic<"atomic", BrigOpcode.ATOMIC>;
}

// atomic is replaced by atomicnoret in the post-isel hook if there
// are no uses of the returned value.
def ATOMICNORET : InstAtomic_NoRet<"atomicnoret", BrigOpcode.ATOMICNORET>;


// def atomic_load_inc : PatFrag<
//   (ops node:$ptr),
//   (atomic_load_add node:$ptr, 1)
// >;

// def atomic_load_dec : PatFrag<
//   (ops node:$ptr),
//   (atomic_load_sub node:$ptr, 1)
// >;


// FIXME: We may need to define a separate opcode for each atomic
// operation. The mayLoad / mayStore flags conflict for atomic_load
// and atomic_store.

// defm : AtomicPat_0Op_IntTypes<atomic_inst, atomic_load, BrigAtomicOperation.LD>;
// defm : AtomicPat_1Op_IntTypes<atomic_inst, atomic_store, BrigAtomicOperation.ST>;

// let AddedComplexity = 1 in {
//   defm : AtomicPat_0Op_IntTypes<atomic_inst, atomic_load_inc, BrigAtomicOperation.WRAPINC>;
//   defm : AtomicPat_0Op_IntTypes<atomic_inst, atomic_load_dec, BrigAtomicOperation.WRAPDEC>;
// }

defm : AtomicPat_1Op_BitTypes<ATOMIC, atomic_swap, BrigAtomicOperation.EXCH>;
defm : AtomicPat_1Op_IntTypes<ATOMIC, atomic_load_add, BrigAtomicOperation.ADD>;
defm : AtomicPat_1Op_IntTypes<ATOMIC, atomic_load_sub, BrigAtomicOperation.SUB>;
defm : AtomicPat_1Op_BitTypes<ATOMIC, atomic_load_and, BrigAtomicOperation.AND>;
defm : AtomicPat_1Op_BitTypes<ATOMIC, atomic_load_or, BrigAtomicOperation.OR>;
defm : AtomicPat_1Op_BitTypes<ATOMIC, atomic_load_xor, BrigAtomicOperation.XOR>;
defm : AtomicPat_1Op_IntTypes<ATOMIC, atomic_load_min, BrigAtomicOperation.MIN, 1>;
defm : AtomicPat_1Op_IntTypes<ATOMIC, atomic_load_max, BrigAtomicOperation.MAX, 1>;
defm : AtomicPat_1Op_IntTypes<ATOMIC, atomic_load_umin, BrigAtomicOperation.MIN>;
defm : AtomicPat_1Op_IntTypes<ATOMIC, atomic_load_umax, BrigAtomicOperation.MAX>;

defm : AtomicPat_2Op_BitTypes<ATOMIC, atomic_cmp_swap, BrigAtomicOperation.CAS>;
