//===------------------------------------------------------*- tablegen -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//


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

def Vec2DestOp32 : Operand<untyped> {
  let MIOperandInfo = (ops HSAILDest32Operand, HSAILDest32Operand);
  let PrintMethod = "printVec2Op";
}

def Vec3DestOp32 : Operand<untyped> {
  let MIOperandInfo = (ops HSAILDest32Operand, HSAILDest32Operand, HSAILDest32Operand);
  let PrintMethod = "printVec3Op";
}

def Vec4DestOp32 : Operand<untyped> {
  let MIOperandInfo = (ops HSAILDest32Operand, HSAILDest32Operand, HSAILDest32Operand, HSAILDest32Operand);
  let PrintMethod = "printVec4Op";
}


def Vec2DestOp64 : Operand<untyped> {
  let MIOperandInfo = (ops HSAILDest64Operand, HSAILDest64Operand);
  let PrintMethod = "printVec2Op";
}

def Vec3DestOp64 : Operand<untyped> {
  let MIOperandInfo = (ops HSAILDest64Operand, HSAILDest64Operand, HSAILDest64Operand);
  let PrintMethod = "printVec3Op";
}

def Vec4DestOp64 : Operand<untyped> {
  let MIOperandInfo = (ops HSAILDest64Operand, HSAILDest64Operand, HSAILDest64Operand, HSAILDest64Operand);
  let PrintMethod = "printVec4Op";
}


def calltarget : Operand<iPTR>;

def GPROrImm : ComplexPattern<untyped, 1, "SelectGPROrImm">;

def ftz : Operand <i1> {
  let PrintMethod = "printFTZ";
}

def nonull : Operand <i1> {
  let PrintMethod = "printNoNull";
}

def equiv : Operand <i32> {
  let PrintMethod = "printEquiv";
}

def v4mod : Operand <i1> {
  let PrintMethod = "printV4";
}

def ArgDeclAlignment : Operand<i32> {
  let OperandType = "OPERAND_IMMEDIATE";
  let PrintMethod = "printArgDeclAlignment";
}

def ArraySize : Operand<i32> {
  let OperandType = "OPERAND_IMMEDIATE";
  let PrintMethod = "printArraySize";
}
