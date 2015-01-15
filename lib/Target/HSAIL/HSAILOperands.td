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

def Vec2Op : Operand<untyped> {
  let MIOperandInfo = (ops untyped, untyped);
  let PrintMethod = "printVec2Op";
}

def Vec3Op : Operand<untyped> {
  let MIOperandInfo = (ops untyped, untyped, untyped);
  let PrintMethod = "printVec3Op";
}

def Vec4Op : Operand<untyped> {
  let MIOperandInfo = (ops untyped, untyped, untyped, untyped);
  let PrintMethod = "printVec4Op";
}

def calltarget : Operand<i32>;

def GPROrImm : ComplexPattern<untyped, 1, "SelectGPROrImm">;

def ftz : Operand <i1> {
  let PrintMethod = "printFTZ";
}
