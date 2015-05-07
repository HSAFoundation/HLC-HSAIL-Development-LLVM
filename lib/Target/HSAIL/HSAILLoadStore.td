//===------------------------------------------------------*- tablegen -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

////////////////////////////////////////////////////////////////////////////////
// stof, ftos -- not matched, inserted in MachineInstr lowering
// 32 bit



defm STOF : InstSegCvt_1Op_PtrTypes<"stof", BrigOpcode.STOF>;
defm FTOS : InstSegCvt_1Op_PtrTypes<"ftos", BrigOpcode.FTOS>;
defm SEGMENTP : InstSegCvt_1Op_Segmentp_Types<"segmentp", BrigOpcode.SEGMENTP>;

class SegmentPPat<BRIGType srcTy> : Pat<
  (HSAILsegmentp (i32 timm:$segment),
                 (i1 timm:$nonull),
                 (srcTy.VT (GPROrImm srcTy.VT:$src0))),
  (!cast<HSAILInst>("SEGMENTP_B1"#srcTy.InstName) $segment, $nonull, $src0, BrigType.B1, srcTy.BT)
>;


let Predicates = [LargeModel] in {
  def : SegmentPPat<U64Ty>;
}

let Predicates = [SmallModel] in {
  def : SegmentPPat<U32Ty>;
}

let isNotDuplicable = 1, hasCtrlDep = 1, hasSideEffects = 1 in {
  def ARG_DECL : HSAILInst<(outs), (ins PtrRC:$symbol, BrigType:$TypeLength, ArraySize:$size,
                                    ArgDeclAlignment:$alignment),
                                    "${alignment}arg$TypeLength $symbol$size", []>;
}

// FIXME: If the MEMOP isn't explicitly typed in output, counts as
// wrong number of operands.
class LDPat<Instruction inst, SDPatternOperator ldnode, ValueType vt> : Pat <
  (vt (ldnode (LoadAddr MEMOP:$address,
                        BrigSegment:$segment,
                        BrigAlignment:$align,
                        BrigType:$TypeLength,
                        BrigWidth:$width,
                        BrigMemoryModifierMask:$mask))),
  (inst MEMOP:$address, $TypeLength, $segment, $align, $width, $mask)
>;


defm LD : LD_Types<"ld", BrigOpcode.LD>;


def : LDPat<LD_S8, sextloadi8, i32>;
def : LDPat<LD_S16, sextloadi16, i32>;
def : LDPat<LD_U8, zextloadi8, i32>;
def : LDPat<LD_U16, zextloadi16, i32>;
def : LDPat<LD_U8, extloadi8, i32>;
def : LDPat<LD_U16, extloadi16, i32>;
def : LDPat<LD_U32, load, i32>;
def : LDPat<LD_F32, load, f32>;
def : LDPat<LD_U64, load, i64>;
def : LDPat<LD_F64, load, f64>;

let hasSideEffects = 1, hasCtrlDep = 1 in {
  // It is not safe to move ld_arg as it can be in an argscope
  defm RARG_LD : LD_Types<"ld", BrigOpcode.LD>;
}

class STPat<Instruction inst, SDPatternOperator node, ValueType vt> : Pat <
  (node (vt (GPROrImm vt:$src)),
      (StoreAddr MEMOP:$address,
                 BrigSegment:$segment,
                 BrigAlignment:$alignment,
                 BrigType:$TypeLength)),
  (inst $src, MEMOP:$address, $TypeLength, $segment, $alignment)
>;

defm ST : ST_Types<"st", BrigOpcode.ST>;

// TODO: Promote float stores to integers.
def : STPat<ST_U32, store, i32>;
def : STPat<ST_F32, store, f32>;
def : STPat<ST_U64, store, i64>;
def : STPat<ST_F64, store, f64>;
def : STPat<ST_U8, truncstorei8, i32>;
def : STPat<ST_U16, truncstorei16, i32>;


// We need pseudos to implement condition register spilling due to a
// limitation storeRegToStackSlot currently has where it assumes only
// 1 instruction is created for spilling.
let isPseudo = 1 in {
  def SPILL_B1 : ST<"spill_b1", BrigOpcode.NOP,
    (ins CR:$src, MEMOP:$address,
         BrigType:$TypeLength, BrigSegment:$segment,
         BrigAlignment:$align)
  >;

  def RESTORE_B1 : LD<"restore_b1", BrigOpcode.NOP,
    (outs CR:$dest)
  >;
}

////////////////////////////////////////////////////////////////////////////////
// load memory address

defm LDA : InstAddr_1Op_PtrTypes<"lda", BrigOpcode.LDA>;
