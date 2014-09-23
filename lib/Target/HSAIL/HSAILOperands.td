//===---------- HSAILOperands.td - HSAIL Operands -----*-tablegen-*--------===//


//===----------------------------------------------------------------------===//
// Custom memory operands
//===----------------------------------------------------------------------===//
def PtrRC: Operand<iPTR>, PointerLikeRegClass<0>;
def PtrRC32: Operand<i32>, PointerLikeRegClass<32>;

// Memory operand: base, register and offset.
def MEMOP  : Operand<iPTR> {
    let MIOperandInfo = (ops PtrRC, PtrRC, PtrRC);
}

def MEMOP32  : Operand<i32> {
    let MIOperandInfo = (ops PtrRC32, PtrRC32, PtrRC32);
}

def calltarget : Operand<i32>;

def GPROrImm : ComplexPattern<untyped, 1, "SelectGPROrImm">;
