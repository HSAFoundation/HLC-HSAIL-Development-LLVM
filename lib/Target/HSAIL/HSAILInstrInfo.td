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

def In32BitMode  : Predicate<"!Subtarget->is64Bit()">;
def In64BitMode  : Predicate<"Subtarget->is64Bit()">;
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


class getRegClassForVT<ValueType VT> {
  RegisterOperand ret = !if(!eq(VT.Size, 32), HSAILSrc32Operand,
                          !if(!eq(VT.Size, 64), HSAILSrc64Operand,
                              HSAILSrc1Operand)); // else VT == i1
}

class getDestRegClassForVT<ValueType VT> {
  RegisterOperand ret = !if(!eq(VT.Size, 32), HSAILDest32Operand,
                          !if(!eq(VT.Size, 64), HSAILDest64Operand,
                              HSAILDest1Operand)); // else VT == i1
}

class HSAILProfile <list<ValueType> _ArgVT, string TypeName = "", int BT = 0> {
  field list<ValueType> ArgVT = _ArgVT;

  field ValueType DestVT = ArgVT[0];
  field ValueType Src0VT = ArgVT[1];
  field ValueType Src1VT = ArgVT[2];
  field ValueType Src2VT = ArgVT[3];
  field ValueType Src3VT = ArgVT[4];

  field RegisterOperand DestRC = getDestRegClassForVT<DestVT>.ret;
  field RegisterOperand Src0RC = getRegClassForVT<Src0VT>.ret;
  field RegisterOperand Src1RC = getRegClassForVT<Src1VT>.ret;
  field RegisterOperand Src2RC = getRegClassForVT<Src2VT>.ret;
  field RegisterOperand Src3RC = getRegClassForVT<Src3VT>.ret;

  field string TypeLengthName = TypeName;
  field int BrigTypeVal = BT;
}

class BRIGType<int bt, ValueType vt, string name, string instName> {
  field int BT = bt;
  field ValueType VT = vt;
  field string Name = name;
  field string InstName = instName;
}


//===----------------------------------------------------------------------===//
// Custom Operands
//===----------------------------------------------------------------------===//
include "HSAILOperands.td"
include "HSAILEnums.td"

def B1Ty : BRIGType<BrigTypeX.B1, i1, "b1", "_B1">;
def B32Ty : BRIGType<BrigTypeX.B32, i32, "b32", "_B32">;
def B64Ty : BRIGType<BrigTypeX.B64, i64, "b64", "_B64">;

def S32Ty : BRIGType<BrigTypeX.S32, i32, "s32", "_S32">;
def S64Ty : BRIGType<BrigTypeX.S64, i64, "s64", "_S64">;

def U32Ty : BRIGType<BrigTypeX.U32, i32, "u32", "_U32">;
def U64Ty : BRIGType<BrigTypeX.U64, i64, "u64", "_U64">;

// Deal with cases that still assume f16 is an i32.
def F16Ty_i32 : BRIGType<BrigTypeX.F16, i32, "f16", "_F16">;
def F16Ty_f32 : BRIGType<BrigTypeX.F16, f32, "f16", "_F16">;

def F16Ty : BRIGType<BrigTypeX.F16, f16, "f16", "_F16">;
def F32Ty : BRIGType<BrigTypeX.F32, f32, "f32", "_F32">;
def F64Ty : BRIGType<BrigTypeX.F64, f64, "f64", "_F64">;

def U8X4Ty : BRIGType<BrigTypeX.U8X4, i32, "u8x4", "_U8X4">;
def U8X8Ty : BRIGType<BrigTypeX.U8X8, i64, "u8x8", "_U8X8">;

def S8X4Ty : BRIGType<BrigTypeX.S8X4, i32, "s8x4", "_S8X4">;
def S8X8Ty : BRIGType<BrigTypeX.S8X8, i64, "s8x8", "_S8X8">;


def Inst_Void : HSAILProfile<[untyped, untyped, untyped, untyped, untyped], "">;

def Inst_S32_S32 : HSAILProfile<[i32, i32, untyped, untyped, untyped], "s32">;
def Inst_S32_S32_S32 : HSAILProfile<[i32, i32, i32, untyped, untyped], "s32">;
def Inst_S32_S32_S32_S32 : HSAILProfile<[i32, i32, i32, i32, untyped], "s32">;

def Inst_S64_S64 : HSAILProfile<[i64, i64, untyped, untyped, untyped], "s64">;
def Inst_S64_S64_S64 : HSAILProfile<[i64, i64, i64, untyped, untyped], "s64">;
def Inst_S64_S64_S64_S64 : HSAILProfile<[i64, i64, i64, i64, untyped], "s64">;

def Inst_U32 : HSAILProfile<[i32, untyped, untyped, untyped, untyped], "u32">;
def Inst_U32_U32 : HSAILProfile<[i32, i32, untyped, untyped, untyped], "u32">;
def Inst_U32_U32_U32 : HSAILProfile<[i32, i32, i32, untyped, untyped], "u32">;
def Inst_U32_U32_U32_U32 : HSAILProfile<[i32, i32, i32, i32, untyped], "u32">;

def Inst_U64 : HSAILProfile<[i64, untyped, untyped, untyped, untyped], "u64">;
def Inst_U64_U64 : HSAILProfile<[i64, i64, untyped, untyped, untyped], "u64">;
def Inst_U64_U64_U64 : HSAILProfile<[i64, i64, i64, untyped, untyped], "u64">;
def Inst_U64_U64_U64_U64 : HSAILProfile<[i64, i64, i64, i64, untyped], "u64">;

def Inst_B1_B1 : HSAILProfile<[i1, i1, untyped, untyped, untyped], "b1">;
def Inst_B1_B1_B1 : HSAILProfile<[i1, i1, i1, untyped, untyped], "b1">;
def Inst_B1_B1_B1_B1 : HSAILProfile<[i1, i1, i1, i1, untyped], "b1">;

def Inst_B32_B32 : HSAILProfile<[i32, i32, untyped, untyped, untyped], "b32">;
def Inst_B32_B32_B32 : HSAILProfile<[i32, i32, i32, untyped, untyped], "b32">;
def Inst_B32_B32_B32_B32 : HSAILProfile<[i32, i32, i32, i32, untyped], "b32">;

def Inst_B64_B64 : HSAILProfile<[i64, i64, untyped, untyped, untyped], "b64">;
def Inst_B64_B64_B64 : HSAILProfile<[i64, i64, i64, untyped, untyped], "b64">;
def Inst_B64_B64_B64_B64 : HSAILProfile<[i64, i64, i64, i64, untyped], "b64">;

def Inst_F32_F32 : HSAILProfile<[f32, f32, untyped, untyped, untyped], "f32", BrigTypeX.F32>;
def Inst_F32_F32_F32 : HSAILProfile<[f32, f32, f32, untyped, untyped], "f32", BrigTypeX.F32>;
def Inst_F32_F32_F32_F32 : HSAILProfile<[f32, f32, f32, f32, untyped], "f32", BrigTypeX.F32>;

def Inst_F64_F64 : HSAILProfile<[f64, f64, untyped, untyped, untyped], "f64", BrigTypeX.F64>;
def Inst_F64_F64_F64 : HSAILProfile<[f64, f64, f64, untyped, untyped], "f64", BrigTypeX.F64>;
def Inst_F64_F64_F64_F64 : HSAILProfile<[f64, f64, f64, f64, untyped], "f64", BrigTypeX.F64>;

def Inst_B32_B1_B32_B32 : HSAILProfile<[i32, i1, i32, i32, untyped, untyped], "b32">;
def Inst_B64_B1_B64_B64 : HSAILProfile<[i64, i1, i64, i64, untyped, untyped], "b64">;

def Inst_F32_B1_F32_F32 : HSAILProfile<[f32, i1, f32, f32, untyped, untyped], "f32">;
def Inst_F64_B1_F64_F64 : HSAILProfile<[f64, i1, f64, f64, untyped, untyped], "f64">;

def Inst_U8X4_U8X4_U8X4_U8X4 : HSAILProfile<[i32, i32, i32, i32, untyped], "u8x4">;
def Inst_B64_B64_B32_B64 : HSAILProfile<[i64, i64, i32, i64, untyped], "b64">;

def Inst_S64_S64_U32_U32 : HSAILProfile<[i64, i64, i32, i32, untyped], "s64">;
def Inst_U64_U64_U32_U32 : HSAILProfile<[i64, i64, i32, i32, untyped], "u64">;
def Inst_S32_S32_U32_U32 : HSAILProfile<[i32, i32, i32, i32, untyped], "s32">;

def Inst_S64_S64_U32 : HSAILProfile<[i64, i64, i32, untyped, untyped], "s64">;
def Inst_U64_U64_U32 : HSAILProfile<[i64, i64, i32, untyped, untyped], "u64">;


def Inst_F32_F32_U32 : HSAILProfile<[f32, f32, i32, untyped, untyped], "f32">;
def Inst_F64_F64_U32 : HSAILProfile<[f64, f64, i32, untyped, untyped], "f64">;

def Inst_U32_B64 : HSAILProfile<[i32, i64, untyped, untyped, untyped], "b64">;
def Inst_U32_B32 : HSAILProfile<[i32, i32, untyped, untyped, untyped], "b32">;

def Inst_U32_S64 : HSAILProfile<[i32, i64, untyped, untyped, untyped], "s64">;
def Inst_U32_U64 : HSAILProfile<[i32, i64, untyped, untyped, untyped], "u64">;
def Inst_U32_S32 : HSAILProfile<[i32, i32, untyped, untyped, untyped], "s32">;
def Inst_U64_U32 : HSAILProfile<[i64, i32, untyped, untyped, untyped], "u64">;

def Inst_U32_B1 : HSAILProfile<[i32, i1, untyped, untyped, untyped], "u32">;
def Inst_B1_U32 : HSAILProfile<[i1, i32, untyped, untyped, untyped], "u32">;
def Inst_B1_U64 : HSAILProfile<[i1, i64, untyped, untyped, untyped], "u64">;


def Inst_U8X4_U8X4_U32_U32 : HSAILProfile<[i32, i32, i32, i32, untyped], "u8x4">;
def Inst_S8X4_S8X4_S32_U32 : HSAILProfile<[i32, i32, i32, i32, untyped], "s8x4">;

def Inst_U8X8_U8X8_U32_U32 : HSAILProfile<[i64, i64, i32, i32, untyped], "u8x8">;
def Inst_S8X8_S8X8_S32_U32 : HSAILProfile<[i64, i64, i32, i32, untyped], "s8x8">;

def Inst_U16X4_U16X4_U32_U32 : HSAILProfile<[i64, i64, i32, i32, untyped], "u16x4">;
def Inst_S16X4_S16X4_S32_U32 : HSAILProfile<[i64, i64, i32, i32, untyped], "s16x4">;

def Inst_U32X2_U32X2_U32_U32 : HSAILProfile<[i64, i64, i32, i32, untyped], "u32x2">;
def Inst_S32X2_S32X2_S32_U32 : HSAILProfile<[i64, i64, i32, i32, untyped], "s32x2">;

def Inst_F16X2_F16X2_F16_U32 : HSAILProfile<[i32, i32, i32, i32, untyped], "f16x2">;
def Inst_F16X4_F16X4_F16_U32 : HSAILProfile<[i64, i64, i32, i32, untyped], "f16x4">;


def Inst_U8X4_F32_F32_F32_F32 : HSAILProfile<[i32, f32, f32, f32, f32], "u8x4">;
def Inst_F32_U8X4_U32 : HSAILProfile<[f32, i32, i32, untyped, untyped], "f32">;

def Inst_U32_U16X2_U16X2_U32 : HSAILProfile<[i32, i32, i32, i32, untyped], "u32">;
def Inst_U32_U8X4_U8X4_U32 : HSAILProfile<[i32, i32, i32, i32, untyped], "u32">;
def Inst_U16X2_U8X4_U8X4_U16X2 : HSAILProfile<[i32, i32, i32, i32, untyped], "u16x2">;

def Inst_B1_F32_U32 : HSAILProfile<[i1, f32, i32, untyped, untyped], "b1">;
def Inst_B1_F64_U32 : HSAILProfile<[i1, f64, i32, untyped, untyped], "b1">;

def Inst_B1_B1_U32_B1_B1 : HSAILProfile<[i1, i1, i32, i1, i1], "b1">;
def Inst_B32_B32_U32_B32_B1 : HSAILProfile<[i32, i32, i32, i32, i1], "b32">;
def Inst_B64_B64_U32_B64_B1 : HSAILProfile<[i64, i64, i32, i64, i1], "b64">;


// Compare profiles.
def Inst_B1_S32_S32 : HSAILProfile<[i1, i32, i32, untyped, untyped], "">;
def Inst_B1_S64_S64 : HSAILProfile<[i1, i64, i64, untyped, untyped], "">;

def Inst_B1_U32_U32 : HSAILProfile<[i1, i32, i32, untyped, untyped], "">;
def Inst_B1_U64_U64 : HSAILProfile<[i1, i64, i64, untyped, untyped], "">;

def Inst_B1_F32_F32 : HSAILProfile<[i1, f32, f32, untyped, untyped], "">;
def Inst_B1_F64_F64 : HSAILProfile<[i1, f64, f64, untyped, untyped], "">;

// Atomic profiles.
def Inst_Void_B32 : HSAILProfile<[untyped, i32, untyped, untyped, untyped], "b32">;
def Inst_Void_B64 : HSAILProfile<[untyped, i64, untyped, untyped, untyped], "b64">;

def Inst_Void_S32 : HSAILProfile<[untyped, i32, untyped, untyped, untyped], "s32">;
def Inst_Void_S64 : HSAILProfile<[untyped, i64, untyped, untyped, untyped], "s64">;

def Inst_Void_U32 : HSAILProfile<[untyped, i32, untyped, untyped, untyped], "u32">;
def Inst_Void_U64 : HSAILProfile<[untyped, i64, untyped, untyped, untyped], "u64">;

def Inst_B32 : HSAILProfile<[i32, untyped, untyped, untyped, untyped], "b32">;
def Inst_B64 : HSAILProfile<[i64, untyped, untyped, untyped, untyped], "b64">;


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
