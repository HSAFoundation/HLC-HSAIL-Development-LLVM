//===---------- HSAILOperands.td - HSAIL Operands -----*-tablegen-*--------===//


//===----------------------------------------------------------------------===//
// Custom memory operands
//===----------------------------------------------------------------------===//
def PtrRC: Operand<iPTR>, PointerLikeRegClass<0>;
def PtrRC32: Operand<i32>, PointerLikeRegClass<32>;

// Memory operand: base, register and offset.
//
// FIXME: iPTR is fundamentally broken for address spaces, should use
// something else.
def MEMOP  : Operand<iPTR> {
  let MIOperandInfo = (ops iAny:$base, iAny:$reg, iAny:$offset);
  let PrintMethod = "printAddrMode3Op";
}

def calltarget : Operand<i32>;

def GPROrImm : ComplexPattern<untyped, 1, "SelectGPROrImm">;
