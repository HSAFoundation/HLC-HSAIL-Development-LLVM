//==- HSAILInstrInfo.td - Main HSAIL Instruction Definition -*- tablegen -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file describes the HSAIL instruction set, defining the instructions, and
// properties of the instructions which are needed for code generation, machine
// code emission, and analysis.
//
//===----------------------------------------------------------------------===//

def SmallModel : Predicate<"Subtarget->isSmallModel()">;
def LargeModel : Predicate<"Subtarget->isLargeModel()">;
def EnableOpt    : Predicate<"CodeGenOpt::None != TM.getOptLevel()">;

// Mark the default value for a width modifier. This only effects how
// the instruction is printed in the non-BRIG path.
class WidthAttrValues_ {
  bits<2> NONE = 0;
  bits<2> ALL = 1;
  bits<2> WAVESIZE = 2;
  bits<2> ONE = 3;
}

def WidthAttrValues : WidthAttrValues_;


class AtomicNoRet <string noRetOp, bit isRet> {
  string NoRetOp = noRetOp;
  bit IsRet = isRet;
}

// Maps an atomic opcode to its version with a return value.
def getAtomicRetOp : InstrMapping {
  let FilterClass = "AtomicNoRet";
  let RowFields = ["NoRetOp"];
  let ColFields = ["IsRet"];
  let KeyCol = ["0"];
  let ValueCols = [["1"]];
}

// Maps an atomic opcode to its returnless version.
def getAtomicNoRetOp : InstrMapping {
  let FilterClass = "AtomicNoRet";
  let RowFields = ["NoRetOp"];
  let ColFields = ["IsRet"];
  let KeyCol = ["1"];
  let ValueCols = [["0"]];
}

class LdStVectorMap<string op, int size> {
  string opcode   = op;
  int    vec_size = size;
}

def getLdStVectorOpcode : InstrMapping {
  let FilterClass = "LdStVectorMap";
  let RowFields   = ["opcode"];
  let ColFields   = ["vec_size"];
  let KeyCol      = ["1"];
  let ValueCols   = [["1"], ["2"], ["3"], ["4"]];
}

class HSAILDestOperand <RegisterClass rc> : RegisterOperand <rc>;

// Normal source operand which can be an immediate or a register.
class HSAILSrcOperand <RegisterClass rc> : RegisterOperand <rc> {
  let OperandNamespace = "HSAIL";
  let OperandType = "OPERAND_REG_IMM";
}

def HSAILDest1Operand : HSAILDestOperand<CR>;
def HSAILDest32Operand : HSAILDestOperand<GPR32>;
def HSAILDest64Operand : HSAILDestOperand<GPR64>;

def HSAILSrc1Operand : HSAILSrcOperand<CR>;
def HSAILSrc32Operand : HSAILSrcOperand<GPR32>;
def HSAILSrc64Operand : HSAILSrcOperand<GPR64>;


class getRegOpForVT<ValueType VT> {
  RegisterOperand ret = !if(!eq(VT.Size, 32), HSAILSrc32Operand,
                          !if(!eq(VT.Size, 64), HSAILSrc64Operand,
                              HSAILSrc1Operand)); // else VT == i1
}

class getDestRegOpForVT<ValueType VT> {
  RegisterOperand ret = !if(!eq(VT.Size, 32), HSAILDest32Operand,
                          !if(!eq(VT.Size, 64), HSAILDest64Operand,
                              HSAILDest1Operand)); // else VT == i1
}

class getRegClassForVT<ValueType VT> {
  RegisterClass ret = !if(!eq(VT.Size, 32), GPR32,
                          !if(!eq(VT.Size, 64), GPR64,
                              CR)); // else VT == i1
}

class getDestRegClassForVT<ValueType VT> {
  RegisterClass ret = !if(!eq(VT.Size, 32), GPR32,
                          !if(!eq(VT.Size, 64), GPR64,
                              CR)); // else VT == i1
}

class BRIGType<int bt, ValueType vt, string name, string instName> {
  field int BT = bt;
  field ValueType VT = vt;
  field string Name = name;
  field string InstName = instName;
  field RegisterClass SrcRC = getRegClassForVT<vt>.ret;
}

class HSAILOperand<BRIGType ty, string pm> : RegisterOperand<ty.SrcRC, pm> {
  field BRIGType BT = ty;
  field ValueType VT = ty.VT;
  let PrintMethod = pm;

  let OperandNamespace = "HSAIL";
  let OperandType = "OPERAND_REG_IMM";
}

class HSAILProfile <list<HSAILOperand> ArgBT> {
  field ValueType DestVT = ArgBT[0].VT;
  field ValueType Src0VT = ArgBT[1].VT;
  field ValueType Src1VT = ArgBT[2].VT;
  field ValueType Src2VT = ArgBT[3].VT;
  field ValueType Src3VT = ArgBT[4].VT;

  field HSAILOperand DestRC = ArgBT[0];
  field HSAILOperand Src0RC = ArgBT[1];
  field HSAILOperand Src1RC = ArgBT[2];
  field HSAILOperand Src2RC = ArgBT[3];
  field HSAILOperand Src3RC = ArgBT[4];
}

//===----------------------------------------------------------------------===//
// Custom Operands
//===----------------------------------------------------------------------===//
include "HSAILOperands.td"
include "HSAILEnums.td"

def UntypedTy : BRIGType<BrigType.NONE, untyped, "", "">;

def B1Ty : BRIGType<BrigType.B1, i1, "b1", "_B1">;
def B32Ty : BRIGType<BrigType.B32, i32, "b32", "_B32">;
def B64Ty : BRIGType<BrigType.B64, i64, "b64", "_B64">;

def S32Ty : BRIGType<BrigType.S32, i32, "s32", "_S32">;
def S64Ty : BRIGType<BrigType.S64, i64, "s64", "_S64">;

def U32Ty : BRIGType<BrigType.U32, i32, "u32", "_U32">;
def U64Ty : BRIGType<BrigType.U64, i64, "u64", "_U64">;

// Deal with cases that still assume f16 is an i32.
def F16Ty_i32 : BRIGType<BrigType.F16, i32, "f16", "_F16">;
def F16Ty_f32 : BRIGType<BrigType.F16, f32, "f16", "_F16">;

def F16Ty : BRIGType<BrigType.F16, f16, "f16", "_F16">;
def F32Ty : BRIGType<BrigType.F32, f32, "f32", "_F32">;
def F64Ty : BRIGType<BrigType.F64, f64, "f64", "_F64">;

def U8X4Ty : BRIGType<BrigType.U8X4, i32, "u8x4", "_U8X4">;
def U8X8Ty : BRIGType<BrigType.U8X8, i64, "u8x8", "_U8X8">;

def S8X4Ty : BRIGType<BrigType.S8X4, i32, "s8x4", "_S8X4">;
def S8X8Ty : BRIGType<BrigType.S8X8, i64, "s8x8", "_S8X8">;

def U16X2Ty : BRIGType<BrigType.U16X2, i32, "u16x2", "_U16X2">;

def U16X4Ty : BRIGType<BrigType.U16X4, i64, "u16x4", "_U16X4">;
def S16X4Ty : BRIGType<BrigType.S16X4, i64, "s16x4", "_S16X4">;

def U32X2Ty : BRIGType<BrigType.U32X2, i64, "u32x2", "_U32X2">;
def S32X2Ty : BRIGType<BrigType.S32X2, i64, "s32x2", "_S32X2">;

def F16X2Ty : BRIGType<BrigType.F16X2, i32, "f16x2", "_F16X2">;
def F16X4Ty : BRIGType<BrigType.F16X4, i64, "f16x4", "_F16X4">;

def UntypedOp : HSAILOperand<UntypedTy, "">;

def B1Op : HSAILOperand<B1Ty, "printB1">;
def B32Op : HSAILOperand<B32Ty, "printB32">;
def B64Op : HSAILOperand<B64Ty, "printB64">;

def F16Op : HSAILOperand<F16Ty, "printF16">;

def S32Op : HSAILOperand<S32Ty, "printS32">;
def U32Op : HSAILOperand<U32Ty, "printU32">;
def F32Op : HSAILOperand<F32Ty, "printF32">;

def S64Op : HSAILOperand<S64Ty, "printS64">;
def U64Op : HSAILOperand<U64Ty, "printU64">;
def F64Op : HSAILOperand<F64Ty, "printF64">;

def U8X4Op : HSAILOperand<U8X4Ty, "printU8X4">;
def U8X8Op : HSAILOperand<U8X4Ty, "printU8X8">;

def S8X4Op : HSAILOperand<S8X4Ty, "printS8X4">;
def S8X8Op : HSAILOperand<S8X4Ty, "printS8X8">;

def U16X2Op : HSAILOperand<U16X2Ty, "printU16X2">;

def U16X4Op : HSAILOperand<U16X4Ty, "printU16X4">;
def S16X4Op : HSAILOperand<S16X4Ty, "printS16X4">;

def U32X2Op : HSAILOperand<U32X2Ty, "printU32X2">;
def S32X2Op : HSAILOperand<S32X2Ty, "printS32X2">;

def F16X2Op : HSAILOperand<F16X2Ty, "printF16X2">;
def F16X4Op : HSAILOperand<F16X4Ty, "printF16X4">;

def Vec2SrcOpU32 : Operand<untyped> {
  let MIOperandInfo = (ops U32Op, U32Op);
  let PrintMethod = "printV2U32";
}

def Vec2SrcOpF32 : Operand<untyped> {
  let MIOperandInfo = (ops F32Op, F32Op);
  let PrintMethod = "printV2F32";
}

def Vec2SrcOpU64 : Operand<untyped> {
  let MIOperandInfo = (ops U64Op, U64Op);
  let PrintMethod = "printV2U64";
}

def Vec2SrcOpF64 : Operand<untyped> {
  let MIOperandInfo = (ops F64Op, F64Op);
  let PrintMethod = "printV2F64";
}


def Vec3SrcOpU32 : Operand<untyped> {
  let MIOperandInfo = (ops U32Op, U32Op, U32Op);
  let PrintMethod = "printV3U32";
}

def Vec3SrcOpF32 : Operand<untyped> {
  let MIOperandInfo = (ops F32Op, F32Op, F32Op);
  let PrintMethod = "printV3F32";
}

def Vec3SrcOpU64 : Operand<untyped> {
  let MIOperandInfo = (ops U64Op, U64Op, U64Op);
  let PrintMethod = "printV3U64";
}

def Vec3SrcOpF64 : Operand<untyped> {
  let MIOperandInfo = (ops F64Op, F64Op, F64Op);
  let PrintMethod = "printV3F64";
}


def Vec4SrcOpU32 : Operand<untyped> {
  let MIOperandInfo = (ops U32Op, U32Op, U32Op, U32Op);
  let PrintMethod = "printV4U32";
}

def Vec4SrcOpF32 : Operand<untyped> {
  let MIOperandInfo = (ops F32Op, F32Op, F32Op, F32Op);
  let PrintMethod = "printV4F32";
}

def Vec4SrcOpU64 : Operand<untyped> {
  let MIOperandInfo = (ops U64Op, U64Op, U64Op, U64Op);
  let PrintMethod = "printV4U64";
}

def Vec4SrcOpF64 : Operand<untyped> {
  let MIOperandInfo = (ops F64Op, F64Op, F64Op, F64Op);
  let PrintMethod = "printV4F64";
}


def Inst_Void : HSAILProfile<[UntypedOp, UntypedOp, UntypedOp, UntypedOp, UntypedOp]>;

def Inst_S32_S32 : HSAILProfile<[S32Op, S32Op, UntypedOp, UntypedOp, UntypedOp]>;
def Inst_S32_S32_S32 : HSAILProfile<[S32Op, S32Op, S32Op, UntypedOp, UntypedOp]>;
def Inst_S32_S32_S32_S32 : HSAILProfile<[S32Op, S32Op, S32Op, S32Op, UntypedOp]>;

def Inst_S64_S64 : HSAILProfile<[S64Op, S64Op, UntypedOp, UntypedOp, UntypedOp]>;
def Inst_S64_S64_S64 : HSAILProfile<[S64Op, S64Op, S64Op, UntypedOp, UntypedOp]>;
def Inst_S64_S64_S64_S64 : HSAILProfile<[S64Op, S64Op, S64Op, S64Op, UntypedOp]>;

def Inst_U32 : HSAILProfile<[U32Op, UntypedOp, UntypedOp, UntypedOp, UntypedOp]>;
def Inst_U32_U32 : HSAILProfile<[U32Op, U32Op, UntypedOp, UntypedOp, UntypedOp]>;
def Inst_U32_U32_U32 : HSAILProfile<[U32Op, U32Op, U32Op, UntypedOp, UntypedOp]>;
def Inst_U32_U32_U32_U32 : HSAILProfile<[U32Op, U32Op, U32Op, U32Op, UntypedOp]>;

def Inst_U64 : HSAILProfile<[U64Op, UntypedOp, UntypedOp, UntypedOp, UntypedOp]>;
def Inst_U64_U64 : HSAILProfile<[U64Op, U64Op, UntypedOp, UntypedOp, UntypedOp]>;
def Inst_U64_U64_U64 : HSAILProfile<[U64Op, U64Op, U64Op, UntypedOp, UntypedOp]>;
def Inst_U64_U64_U64_U64 : HSAILProfile<[U64Op, U64Op, U64Op, U64Op, UntypedOp]>;

def Inst_B1_B1 : HSAILProfile<[B1Op, B1Op, UntypedOp, UntypedOp, UntypedOp]>;
def Inst_B1_B1_B1 : HSAILProfile<[B1Op, B1Op, B1Op, UntypedOp, UntypedOp]>;
def Inst_B1_B1_B1_B1 : HSAILProfile<[B1Op, B1Op, B1Op, B1Op, UntypedOp]>;

def Inst_B32_B32 : HSAILProfile<[B32Op, B32Op, UntypedOp, UntypedOp, UntypedOp]>;
def Inst_B32_B32_B32 : HSAILProfile<[B32Op, B32Op, B32Op, UntypedOp, UntypedOp]>;
def Inst_B32_B32_B32_B32 : HSAILProfile<[B32Op, B32Op, B32Op, B32Op, UntypedOp]>;

def Inst_B64_B64 : HSAILProfile<[B64Op, B64Op, UntypedOp, UntypedOp, UntypedOp]>;
def Inst_B64_B64_B64 : HSAILProfile<[B64Op, B64Op, B64Op, UntypedOp, UntypedOp]>;
def Inst_B64_B64_B64_B64 : HSAILProfile<[B64Op, B64Op, B64Op, B64Op, UntypedOp]>;

def Inst_F32_F32 : HSAILProfile<[F32Op, F32Op, UntypedOp, UntypedOp, UntypedOp]>;
def Inst_F32_F32_F32 : HSAILProfile<[F32Op, F32Op, F32Op, UntypedOp, UntypedOp]>;
def Inst_F32_F32_F32_F32 : HSAILProfile<[F32Op, F32Op, F32Op, F32Op, UntypedOp]>;

def Inst_F64_F64 : HSAILProfile<[F64Op, F64Op, UntypedOp, UntypedOp, UntypedOp]>;
def Inst_F64_F64_F64 : HSAILProfile<[F64Op, F64Op, F64Op, UntypedOp, UntypedOp]>;
def Inst_F64_F64_F64_F64 : HSAILProfile<[F64Op, F64Op, F64Op, F64Op, UntypedOp]>;

def Inst_B32_B1_B32_B32 : HSAILProfile<[B32Op, B1Op, B32Op, B32Op, UntypedOp, UntypedOp]>;
def Inst_B64_B1_B64_B64 : HSAILProfile<[B64Op, B1Op, B64Op, B64Op, UntypedOp, UntypedOp]>;

def Inst_F32_B1_F32_F32 : HSAILProfile<[F32Op, B1Op, F32Op, F32Op, UntypedOp, UntypedOp]>;
def Inst_F64_B1_F64_F64 : HSAILProfile<[F64Op, B1Op, F64Op, F64Op, UntypedOp, UntypedOp]>;

def Inst_U8X4_U8X4_U8X4_U8X4 : HSAILProfile<[U8X4Op, U8X4Op, U8X4Op, U8X4Op, UntypedOp]>;
def Inst_B64_B64_B32_B64 : HSAILProfile<[B64Op, B64Op, B32Op, B64Op, UntypedOp]>;

def Inst_S64_S64_U32_U32 : HSAILProfile<[S64Op, S64Op, U32Op, U32Op, UntypedOp]>;
def Inst_U64_U64_U32_U32 : HSAILProfile<[U64Op, U64Op, U32Op, U32Op, UntypedOp]>;
def Inst_S32_S32_U32_U32 : HSAILProfile<[S32Op, S32Op, U32Op, U32Op, UntypedOp]>;

def Inst_S64_S64_U32 : HSAILProfile<[S64Op, S64Op, U32Op, UntypedOp, UntypedOp]>;
def Inst_U64_U64_U32 : HSAILProfile<[U64Op, U64Op, U32Op, UntypedOp, UntypedOp]>;

def Inst_F32_F32_U32 : HSAILProfile<[F32Op, F32Op, U32Op, UntypedOp, UntypedOp]>;
def Inst_F64_F64_U32 : HSAILProfile<[F64Op, F64Op, U32Op, UntypedOp, UntypedOp]>;

def Inst_U32_B64 : HSAILProfile<[U32Op, B64Op, UntypedOp, UntypedOp, UntypedOp]>;
def Inst_U32_B32 : HSAILProfile<[U32Op, B32Op, UntypedOp, UntypedOp, UntypedOp]>;

def Inst_U32_S64 : HSAILProfile<[U32Op, S64Op, UntypedOp, UntypedOp, UntypedOp]>;
def Inst_U32_U64 : HSAILProfile<[U32Op, U64Op, UntypedOp, UntypedOp, UntypedOp]>;
def Inst_U32_S32 : HSAILProfile<[U32Op, S32Op, UntypedOp, UntypedOp, UntypedOp]>;
def Inst_U64_U32 : HSAILProfile<[U64Op, U32Op, UntypedOp, UntypedOp, UntypedOp]>;

def Inst_U32_B1 : HSAILProfile<[U32Op, B1Op, UntypedOp, UntypedOp, UntypedOp]>;
def Inst_B1_U32 : HSAILProfile<[B1Op, U32Op, UntypedOp, UntypedOp, UntypedOp]>;
def Inst_B1_U64 : HSAILProfile<[B1Op, U64Op, UntypedOp, UntypedOp, UntypedOp]>;


def Inst_U8X4_U8X4_U32_U32 : HSAILProfile<[U8X4Op, U8X4Op, U32Op, U32Op, UntypedOp]>;
def Inst_S8X4_S8X4_S32_U32 : HSAILProfile<[S8X4Op, S8X4Op, S32Op, U32Op, UntypedOp]>;

def Inst_U8X8_U8X8_U32_U32 : HSAILProfile<[U8X8Op, U8X8Op, U32Op, U32Op, UntypedOp]>;
def Inst_S8X8_S8X8_S32_U32 : HSAILProfile<[S8X8Op, S8X8Op, S32Op, U32Op, UntypedOp]>;

def Inst_U16X4_U16X4_U32_U32 : HSAILProfile<[U16X4Op, U16X4Op, U32Op, U32Op, UntypedOp]>;
def Inst_S16X4_S16X4_S32_U32 : HSAILProfile<[S16X4Op, S16X4Op, S32Op, U32Op, UntypedOp]>;

def Inst_U32X2_U32X2_U32_U32 : HSAILProfile<[U32X2Op, U32X2Op, U32Op, U32Op, UntypedOp]>;
def Inst_S32X2_S32X2_S32_U32 : HSAILProfile<[S32X2Op, S32X2Op, S32Op, U32Op, UntypedOp]>;

def Inst_F16X2_F16X2_F16_U32 : HSAILProfile<[F16X2Op, F16X2Op, F16Op, U32Op, UntypedOp]>;
def Inst_F16X4_F16X4_F16_U32 : HSAILProfile<[F16X4Op, F16X4Op, F16Op, U32Op, UntypedOp]>;


def Inst_U8X4_F32_F32_F32_F32 : HSAILProfile<[U8X4Op, F32Op, F32Op, F32Op, F32Op]>;
def Inst_F32_U8X4_U32 : HSAILProfile<[F32Op, U8X4Op, U32Op, UntypedOp, UntypedOp]>;

def Inst_U32_U16X2_U16X2_U32 : HSAILProfile<[U32Op, U16X2Op, U16X2Op, U32Op, UntypedOp]>;
def Inst_U32_U8X4_U8X4_U32 : HSAILProfile<[U32Op, U8X4Op, U8X4Op, U32Op, UntypedOp]>;
def Inst_U16X2_U8X4_U8X4_U16X2 : HSAILProfile<[U16X2Op, U8X4Op, U8X4Op, U16X2Op, UntypedOp]>;

def Inst_B1_F32_U32 : HSAILProfile<[B1Op, F32Op, U32Op, UntypedOp, UntypedOp]>;
def Inst_B1_F64_U32 : HSAILProfile<[B1Op, F64Op, U32Op, UntypedOp, UntypedOp]>;

def Inst_B1_B1_U32_B1_B1 : HSAILProfile<[B1Op, B1Op, U32Op, B1Op, B1Op]>;
def Inst_B32_B32_U32_B32_B1 : HSAILProfile<[B32Op, B32Op, U32Op, B32Op, B1Op]>;
def Inst_B64_B64_U32_B64_B1 : HSAILProfile<[B64Op, B64Op, U32Op, B64Op, B1Op]>;


// Compare profiles.
def Inst_B1_S32_S32 : HSAILProfile<[B1Op, S32Op, S32Op, UntypedOp, UntypedOp]>;
def Inst_B1_S64_S64 : HSAILProfile<[B1Op, S64Op, S64Op, UntypedOp, UntypedOp]>;

def Inst_B1_U32_U32 : HSAILProfile<[B1Op, U32Op, U32Op, UntypedOp, UntypedOp]>;
def Inst_B1_U64_U64 : HSAILProfile<[B1Op, U64Op, U64Op, UntypedOp, UntypedOp]>;

def Inst_B1_F32_F32 : HSAILProfile<[B1Op, F32Op, F32Op, UntypedOp, UntypedOp]>;
def Inst_B1_F64_F64 : HSAILProfile<[B1Op, F64Op, F64Op, UntypedOp, UntypedOp]>;

// Atomic profiles.
def Inst_Void_B32 : HSAILProfile<[UntypedOp, B32Op, UntypedOp, UntypedOp, UntypedOp]>;
def Inst_Void_B64 : HSAILProfile<[UntypedOp, B64Op, UntypedOp, UntypedOp, UntypedOp]>;

def Inst_Void_S32 : HSAILProfile<[UntypedOp, S32Op, UntypedOp, UntypedOp, UntypedOp]>;
def Inst_Void_S64 : HSAILProfile<[UntypedOp, S64Op, UntypedOp, UntypedOp, UntypedOp]>;

def Inst_Void_U32 : HSAILProfile<[UntypedOp, U32Op, UntypedOp, UntypedOp, UntypedOp]>;
def Inst_Void_U64 : HSAILProfile<[UntypedOp, U64Op, UntypedOp, UntypedOp, UntypedOp]>;

def Inst_B32 : HSAILProfile<[B32Op, UntypedOp, UntypedOp, UntypedOp, UntypedOp]>;
def Inst_B64 : HSAILProfile<[B64Op, UntypedOp, UntypedOp, UntypedOp, UntypedOp]>;


//===----------------------------------------------------------------------===//
// Custom Selection DAG Type Profiles
//===----------------------------------------------------------------------===//
include "HSAILProfiles.td"

//===----------------------------------------------------------------------===//
// Custom Selection DAG Nodes
//===----------------------------------------------------------------------===//
include "HSAILNodes.td"

//===----------------------------------------------------------------------===//
// Custom Pattern DAG Nodes
//===----------------------------------------------------------------------===//
include "HSAILPatterns.td"

//===----------------------------------------------------------------------===//
// Instruction format classes
//===----------------------------------------------------------------------===//
include "HSAILInstrFormats.td"

//===----------------------------------------------------------------------===//
// Intrinsics support
//===----------------------------------------------------------------------===//
include "HSAILIntrinsics.td"

//===----------------------------------------------------------------------===//
// Instructions support
//===----------------------------------------------------------------------===//
include "HSAILInstructions.td"
