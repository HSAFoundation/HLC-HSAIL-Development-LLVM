//===---------- HSAILOperands.td - HSAIL Operands -----*-tablegen-*--------===//


//===----------------------------------------------------------------------===//
// Custom memory operands
//===----------------------------------------------------------------------===//
def PtrRC: Operand<iPTR>, PointerLikeRegClass<0>;

// Memory operand: base, register and offset.
def MEMOP  : Operand<iPTR> {
    let MIOperandInfo = (ops PtrRC, PtrRC, PtrRC);
}

def BRIG_TYPE_OPND : Operand<i32>;

def WIDTH_OPND     : OperandWithDefaultOps<i32, (ops (i32 1))>;

def CONST_OPERAND  : OperandWithDefaultOps<i1,  (ops (i1 0))>;

def IMAGEMEM32  : Operand<i32>;

def calltarget : Operand<i32>;

def GPROrImm : ComplexPattern<untyped, 1, "SelectGPROrImm">;
