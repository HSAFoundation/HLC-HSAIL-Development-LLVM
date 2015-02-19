//===------ HSAILInstrFormats.td ---------------------------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Instruction format superclass
//===----------------------------------------------------------------------===//

// TODO HSA : fix so that a space is not emitted prior to end of
// statement semi-colon

class HSAILInst<dag outs, dag ins,
                string asmstr,
                list<dag> pattern,
                bits<16> BrigVal = 0>
  : Instruction {
  field bits<32> Inst;
  let Namespace = "HSAIL";
  dag OutOperandList = outs;
  dag InOperandList = ins;
  let AsmString   = !strconcat(asmstr, ";");
  let Pattern = pattern;

  let UseNamedOperandTable = 1;
  let Inst{15-0} = BrigVal;

  // Target specific flags
  // Important! Keep in sync with HSAIL.h::HSAILTSFLAG

  // Instruction classes. See BrigKind.
  bit InstAddr = 0;
  bit InstAtomic = 0;
  bit InstBasic = 0;
  bit InstBr = 0;
  bit InstCmp = 0;
  bit InstCvt = 0;
  bit InstImage = 0;
  bit InstLane = 0;
  bit InstMem = 0;
  bit InstMemFence = 0;
  bit InstMod = 0;
  bit InstQueryImage = 0;
  bit InstQuerySampler = 0;
  bit InstQueue = 0;
  bit InstSeg = 0;
  bit InstSegCvt = 0;
  bit InstSignal = 0;
  bit InstSourceType = 0;

  // FIXME: Remove these
  bit isLoad = 0;
  bit isStore = 0;
  bit isConv = 0;
  bit isImageInst = 0;


  let TSFlags{3} = InstAddr;
  let TSFlags{4} = InstAtomic;
  let TSFlags{5} = InstBasic;
  let TSFlags{6} = InstBr;
  let TSFlags{7} = InstCmp;
  let TSFlags{8} = InstCvt;
  let TSFlags{9} = InstImage;
  let TSFlags{10} = InstLane;
  let TSFlags{11} = InstMem;
  let TSFlags{12} = InstMemFence;
  let TSFlags{13} = InstMod;
  let TSFlags{14} = InstQueryImage;
  let TSFlags{15} = InstQuerySampler;
  let TSFlags{16} = InstQueue;
  let TSFlags{17} = InstSeg;
  let TSFlags{18} = InstSegCvt;
  let TSFlags{19} = InstSignal;
  let TSFlags{20} = InstSourceType;

  let TSFlags{21} = isLoad;
  let TSFlags{22} = isStore;
  let TSFlags{23} = isConv;
  let TSFlags{24} = isImageInst;
}

////////////////////////////////////////////////////////////////////////////////
// Basic instruction formats
////////////////////////////////////////////////////////////////////////////////
// InstBasic
class HSAILInstBasic<bits<16> BrigVal,
                     dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let hasSideEffects = 0;
  let InstBasic = 1;
}

class HSAILInstBasic_0Op_NoRet<string opName, bits<16> BrigVal> :
  HSAILInstBasic<BrigVal,
                 (outs),
                 (ins BrigTypeX:$TypeLength),
  opName#"$TypeLength"
>;

class HSAILInstBasic_0Op<string opName, bits<16> BrigVal> :
  HSAILInstBasic<BrigVal,
                 (outs unknown:$dest),
                 (ins BrigTypeX:$TypeLength),
  opName#"$TypeLength\t$dest"
>;

class HSAILInstBasic_1Op<string opName, bits<16> BrigVal> :
  HSAILInstBasic<BrigVal,
                 (outs unknown:$dest),
                 (ins unknown:$src0, BrigTypeX:$TypeLength),
  opName#"$TypeLength\t$dest, $src0"
>;

class HSAILInstBasic_2Op<string opName, bits<16> BrigVal> :
  HSAILInstBasic<BrigVal,
                 (outs unknown:$dest),
                 (ins unknown:$src0, unknown:$src1,
                      BrigTypeX:$TypeLength),
  opName#"$TypeLength\t$dest, $src0, $src1"
>;

class HSAILInstBasic_3Op<string opName, bits<16> BrigVal> :
  HSAILInstBasic<BrigVal,
                 (outs unknown:$dest),
                 (ins unknown:$src0, unknown:$src1, unknown:$src2,
                      BrigTypeX:$TypeLength),
  opName#"$TypeLength\t$dest, $src0, $src1, $src2"
>;


// InstMod
class HSAILInstMod<bits<16> BrigVal,
                   dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let hasSideEffects = 0;
  let InstMod = 1;
}

// TODO: Needs pack operand?
class HSAILInstMod_1Op<string opName, bits<16> BrigVal> :
  HSAILInstMod<BrigVal,
               (outs unknown:$dest),
               (ins ftz:$ftz, BrigRound:$round,
                    unknown:$src0,
                    BrigTypeX:$TypeLength),
  opName#"$ftz$round$TypeLength\t$dest, $src0"
>;

class HSAILInstMod_2Op<string opName, bits<16> BrigVal> :
  HSAILInstMod<BrigVal,
               (outs unknown:$dest),
               (ins ftz:$ftz, BrigRound:$round,
                    unknown:$src0, unknown:$src1,
                    BrigTypeX:$TypeLength),
  opName#"$ftz$round$TypeLength\t$dest, $src0, $src1"
>;

class HSAILInstMod_3Op<string opName, bits<16> BrigVal> :
  HSAILInstMod<BrigVal,
               (outs unknown:$dest),
               (ins ftz:$ftz, BrigRound:$round,
                    unknown:$src0, unknown:$src1, unknown:$src2,
                    BrigTypeX:$TypeLength),
  opName#"$ftz$round$TypeLength\t$dest, $src0, $src1, $src2"
>;


// InstCvt
class InstCvt<string opName> : HSAILInst<
    (outs unknown:$dest),
    (ins ftz:$ftz,
         BrigRound:$round,
         BrigTypeX:$destTypedestLength,
         BrigTypeX:$srcTypesrcLength,
         unknown:$src),
    opName#"$ftz$round$destTypedestLength$srcTypesrcLength\t$dest, $src",
   []
> {
  let isConv = 1;
  let InstCvt = 1;
}

// InstSourceType
class HSAILInstSourceType<bits<16> BrigVal,
                          dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let hasSideEffects = 0;
  let InstSourceType = 1;
}

class HSAILInstSourceType_1Op<string opName, bits<16> BrigVal> :
  HSAILInstSourceType<BrigVal,
                 (outs unknown:$dest),
                 (ins unknown:$src0, BrigTypeX:$TypeLength, BrigTypeX:$sourceType),
  opName#"$TypeLength$sourceType\t$dest, $src0"
>;

class HSAILInstSourceType_2Op<string opName, bits<16> BrigVal> :
  HSAILInstSourceType<BrigVal,
                 (outs unknown:$dest),
                 (ins unknown:$src0, unknown:$src1,
                      BrigTypeX:$TypeLength, BrigTypeX:$sourceType),
  opName#"$TypeLength$sourceType\t$dest, $src0, $src1"
>;

class HSAILInstSourceType_3Op<string opName, bits<16> BrigVal> :
  HSAILInstSourceType<BrigVal,
                 (outs unknown:$dest),
                 (ins unknown:$src0, unknown:$src1, unknown:$src2,
                      BrigTypeX:$TypeLength, BrigTypeX:$sourceType),
  opName#"$TypeLength$sourceType\t$dest, $src0, $src1, $src2"
>;

class HSAILInstSourceType_4Op<string opName, bits<16> BrigVal> :
  HSAILInstSourceType<BrigVal,
                 (outs unknown:$dest),
                 (ins unknown:$src0, unknown:$src1, unknown:$src2, unknown:$src3,
                      BrigTypeX:$TypeLength, BrigTypeX:$sourceType),
  opName#"$TypeLength$sourceType\t$dest, $src0, $src1, $src2, $src3"
>;



// InstLane
class HSAILInstLane<bits<16> BrigVal,
                    dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let hasSideEffects = 1;
  let InstLane = 1;
}

class HSAILInstLane_0Op<string opName, bits<16> BrigVal> :
  HSAILInstLane<
    BrigVal,
    (outs unknown:$dest),
    (ins BrigWidth:$width, BrigTypeX:$TypeLength, BrigTypeX:$sourceType),
  opName#"$width$TypeLength$sourceType\t$dest"
>;

class HSAILInstLane_1Op<string opName, bits<16> BrigVal> :
  HSAILInstLane<
    BrigVal,
    (outs unknown:$dest),
    (ins BrigWidth:$width, unknown:$src0, BrigTypeX:$TypeLength, BrigTypeX:$sourceType),
  opName#"$width$TypeLength$sourceType\t$dest, $src0"
>;

class HSAILInstLane_ActiveLaneShuffle<string opName, bits<16> BrigVal> :
  HSAILInstLane<
    BrigVal,
    (outs unknown:$dest),
    (ins BrigWidth:$width,
         unknown:$src0, unknown:$src1, unknown:$src2, unknown:$src3,
         BrigTypeX:$TypeLength, BrigTypeX:$sourceType),
  opName#"$width$TypeLength$sourceType\t$dest, $src0, $src1, $src2, $src3"
>;

class HSAILInstLane_ActiveLaneMask<string opName, bits<16> BrigVal> :
  HSAILInstLane<
    BrigVal,
    // FIXME: Using compound operands as dest seems to not be selectable
  //(outs Vec4Op:$dest),
    (outs GPR64:$dest0, GPR64:$dest1,  GPR64:$dest2,  GPR64:$dest3),
    (ins BrigWidth:$width,
         unknown:$src0, BrigTypeX:$TypeLength, BrigTypeX:$sourceType),
//  opName#"$width$TypeLength$sourceType\t$dest, $src0"
  opName#"$width$TypeLength$sourceType\t($dest0, $dest1, $dest2, $dest3), $src0"
>;

// InstBr
class HSAILInstBr<bits<16> BrigVal,
                  dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let hasSideEffects = 1;
  let InstBr = 1;
}

class HSAILInstBr_0Op_NoRet<string opName, bits<16> BrigVal> :
  HSAILInstBr<BrigVal,
              (outs),
              (ins BrigWidth:$width, BrigTypeX:$TypeLength),
  opName#"$width$TypeLength"
>;

class HSAILInstBr_0Op<string opName, bits<16> BrigVal> :
  HSAILInstBr<BrigVal,
              (outs unknown:$dest),
              (ins BrigWidth:$width, BrigTypeX:$TypeLength),
  opName#"$width$TypeLength\t$dest"
>;

class HSAILInstBr_1Op<string opName, bits<16> BrigVal> :
  HSAILInstBr<BrigVal,
              (outs unknown:$dest),
              (ins BrigWidth:$width, unknown:$src0, BrigTypeX:$TypeLength),
  opName#"$width$TypeLength\t$dest, $src0"
>;


class HSAILInstBr_1Op_NoRet<string opName, bits<16> BrigVal> :
  HSAILInstBr<BrigVal,
              (outs),
              (ins BrigWidth:$width, unknown:$src0, BrigTypeX:$TypeLength),
  opName#"$width$TypeLength\t$src0"
>;

class HSAILInstBr_2Op_NoRet<string opName, bits<16> BrigVal> :
  HSAILInstBr<BrigVal,
              (outs),
              (ins BrigWidth:$width, unknown:$src0, unknown:$src1, BrigTypeX:$TypeLength),
  opName#"$width$TypeLength\t$src0, $src1"
>;

// InstSeg
class HSAILInstSeg<bits<16> BrigVal,
                  dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let hasSideEffects = 0;
  let InstSeg = 1;
}

class HSAILInstSeg_0Op<string opName, bits<16> BrigVal> :
  HSAILInstSeg<BrigVal,
               (outs unknown:$dest),
               (ins BrigSegment:$segment, BrigTypeX:$TypeLength),
  opName#"$segment$TypeLength\t$dest"
>;

// InstSegCvt
class HSAILInstSegCvt<bits<16> BrigVal,
                      dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let hasSideEffects = 0;
  let InstSegCvt = 1;
}

class HSAILInstSegCvt_1Op<string opName, bits<16> BrigVal> :
  HSAILInstSegCvt<BrigVal,
                 (outs unknown:$dest),
                 (ins BrigSegment:$segment,
                      nonull:$nonull,
                      unknown:$src0,
                      BrigTypeX:$destTypedestLength,
                      BrigTypeX:$srcTypesrcLength),
  opName#"$segment$nonull$destTypedestLength$srcTypesrcLength\t$dest, $src0"
>;

// InstMemFence
class HSAILInstMemFence<bits<16> BrigVal,
                        dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let hasSideEffects = 1;
  let mayLoad = 1;
  let mayStore = 1;
  let isBarrier = 1;
  let isNotDuplicable = 1; // XXX - This seems unnecessary
  let InstMemFence = 1;
}

class InstMemFence<string opName, bits<16> BrigVal> :
  HSAILInstMemFence<
    BrigVal,
    (outs),
    (ins BrigMemoryOrder:$order,
         BrigMemoryScope:$globalscope,
         BrigMemoryScope:$groupscope,
         BrigMemoryScope:$imagescope),
    opName#"$order$globalscope$groupscope$imagescope"
>;

// InstMem
class HSAILInstMem<bits<16> BrigVal,
                   dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let mayLoad = 1;
  let mayStore = 1;
  let InstMem = 1;
}

class LD<string opName, bits<16> BrigVal, dag outs> :
  HSAILInstMem<BrigVal, outs,
    (ins MEMOP:$address,
       BrigTypeX:$TypeLength,
       BrigSegment:$segment,
       BrigAlignment:$align,
       BrigWidth:$width,
       BrigMemoryModifierMask:$mask),
    opName#"$segment$align$width$mask$TypeLength\t$dest, $address"> {
  let isLoad = 1;
  let isStore = 0;
  let mayStore = 0;
  let hasSideEffects = 0;
}

class ST<string opName, bits<16> BrigVal, dag ins> :
  HSAILInstMem<BrigVal, (outs),
    ins,
    opName#"$segment$align$TypeLength\t$src, $address"> {
  let isLoad = 0;
  let mayLoad = 0;
  let isStore = 1;
  let hasSideEffects = 0;
}

// InstAtomic
class HSAILInstAtomic<bits<16> BrigVal,
                        dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let hasSideEffects = 1;
  let mayLoad = 1;
  let mayStore = 1;
  let InstAtomic = 1;
}

// FIXME: We need to not print src0 / src1 depending on the specific
// atomic op instead of noreg.
class InstAtomic<string opName, bits<16> BrigVal> :
  HSAILInstAtomic<
    BrigVal,
    (outs unknown:$dest),
    (ins BrigAtomicOperation:$op,
         AddressSpace:$segment,
         BrigMemoryOrder:$order,
         BrigMemoryScope:$scope,
         equiv:$equiv,
         MEMOP:$address,
         unknown:$src0,
         unknown:$src1,
         BrigTypeX:$TypeLength),
    opName#"$op$segment$order$scope$equiv$TypeLength\t$dest, $address, $src0, $src1"
>;

class InstAtomic_NoRet<string opName, bits<16> BrigVal> :
  HSAILInstAtomic<
    BrigVal,
    (outs),
    (ins BrigAtomicOperation:$op,
         AddressSpace:$segment,
         BrigMemoryOrder:$order,
         BrigMemoryScope:$scope,
         equiv:$equiv,
         MEMOP:$address,
         unknown:$src0,
         unknown:$src1,
         BrigTypeX:$TypeLength),
    opName#"$op$segment$order$scope$equiv$TypeLength\t$address, $src0, $src1"
>;

// InstCmp
class HSAILInstCmp<bits<16> BrigVal,
                   dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let hasSideEffects = 0;
  let InstCmp = 1;
  let isCompare = 1;
}

class InstCmp<string opName, bits<16> BrigVal> :
  HSAILInstCmp<BrigVal,
    (outs unknown:$dest),
    (ins BrigCompareOperation:$op,
         ftz:$ftz,
         unknown:$src0,
         unknown:$src1,
         BrigTypeX:$destTypedestLength,
         BrigTypeX:$srcTypesrcLength),
    opName#"$op$ftz$destTypedestLength$srcTypesrcLength\t$dest, $src0, $src1"
>;

// InstAddr
class HSAILInstAddr<bits<16> BrigVal,
                    dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let hasSideEffects = 0;
  let InstAddr = 1;
}

class HSAILInstAddr_1Op<string opName, bits<16> BrigVal> :
  HSAILInstAddr<BrigVal,
                (outs unknown:$dest),
                (ins BrigSegment:$segment, MEMOP:$address, BrigTypeX:$TypeLength),
  opName#"$segment$TypeLength\t$dest, $address"
>;

// InstImage
class HSAILInstImage<bits<16> BrigVal,
                     dag outs, dag ins, string asmstr> :
  HSAILInst<outs, ins, asmstr, [], BrigVal> {
  let mayLoad = 1;
  let mayStore = 1;
  let InstImage = 1;
}

class HSAILInstImage_Ld_1D<string opName, bits<16> BrigVal> :
  HSAILInstImage<BrigVal,
                (outs GPR32:$destR, GPR32:$destG, GPR32:$destB, GPR32:$destA),
                (ins v4mod:$v4,
                     BrigTypeX:$imageType,
                     BrigTypeX:$coordType,
                     BrigImageGeometry:$geometry,
                     equiv:$equiv,
                     GPR64:$image,
                     GPR64:$sampler,
                     GPR32:$coordWidth,
                     BrigTypeX:$destType),
  opName#"$v4$geometry$equiv$destType$imageType$coordType\t($destR, $destG, $destB, $destA), $image, $coordWidth"> {
  let mayStore = 0;
}

////////////////////////////////////////////////////////////////////////////////
// Basic instruction patterns
////////////////////////////////////////////////////////////////////////////////

class InstBasic_0Op_Pat<HSAILInst inst,
                        SDPatternOperator node,
                        ValueType vt,
                        int bt> : Pat <
  (vt (node)),
  (inst bt)
>;

class InstBasic_1Op_Pat<HSAILInst inst,
                        SDPatternOperator node,
                        ValueType vt,
                        int bt> : Pat <
  (vt (node (GPROrImm vt:$src0))),
  (inst $src0, bt)
>;

multiclass InstBasic_1Op_IntTypes<HSAILInst inst,
                                  SDPatternOperator node,
                                  bit signed = 0> {
  def : InstBasic_1Op_Pat<inst, node, i32,
    !if(signed, BrigTypeX.S32, BrigTypeX.U32)
  >;

  def : InstBasic_1Op_Pat<inst, node, i64,
    !if(signed, BrigTypeX.S64, BrigTypeX.U64)
  >;
}

multiclass InstBasic_1Op_BitIntTypes<HSAILInst inst,
                                     SDPatternOperator node,
                                     bit signed = 0> {
  def : InstBasic_1Op_Pat<inst, node, i32,
    BrigTypeX.B32
  >;

  def : InstBasic_1Op_Pat<inst, node, i64,
    BrigTypeX.B64
  >;

  def : InstBasic_1Op_Pat<inst, node, i1,
    BrigTypeX.B1
  >;
}

multiclass InstBasic_1Op_FPTypes<HSAILInst inst,
                                SDPatternOperator node> {
  def : InstBasic_1Op_Pat<inst, node, f32, BrigTypeX.F32>;
  def : InstBasic_1Op_Pat<inst, node, f64, BrigTypeX.F64>;
}

class InstBasic_2Op_Pat<HSAILInst inst,
                        SDPatternOperator node,
                        ValueType vt0,
                        ValueType vt1,
                        int bt> : Pat <
  (vt0 (node (GPROrImm vt0:$src0), (vt1 (GPROrImm vt1:$src1)))),
  (inst $src0, $src1, bt)
>;

multiclass InstBasic_2Op_IntTypes<HSAILInst inst,
                                  SDPatternOperator node,
                                  bit signed = 0> {
  def : InstBasic_2Op_Pat<inst, node, i32, i32,
    !if(signed, BrigTypeX.S32, BrigTypeX.U32)
  >;

  def : InstBasic_2Op_Pat<inst, node, i64, i64,
    !if(signed, BrigTypeX.S64, BrigTypeX.U64)
  >;
}

multiclass InstBasic_2Op_BitIntTypes<HSAILInst inst,
                                     SDPatternOperator node> {
  def : InstBasic_2Op_Pat<inst, node, i32, i32,
    BrigTypeX.B32
  >;

  def : InstBasic_2Op_Pat<inst, node, i64, i64,
    BrigTypeX.B64
  >;

  def : InstBasic_2Op_Pat<inst, node, i1, i1,
    BrigTypeX.B1
  >;
}

multiclass InstBasic_2Op_FPTypes<HSAILInst inst,
                                SDPatternOperator node> {
  def : InstBasic_2Op_Pat<inst, node, f32, f32, BrigTypeX.F32>;
  def : InstBasic_2Op_Pat<inst, node, f64, f64, BrigTypeX.F64>;
}

class InstBasic_3Op_Pat<HSAILInst inst,
                        SDPatternOperator node,
                        ValueType vt,
                        int bt> : Pat <
  (node (vt (GPROrImm vt:$src0)), (vt (GPROrImm vt:$src1)), (vt (GPROrImm vt:$src2))),
  (inst $src0, $src1, $src2, bt)
>;

multiclass InstBasic_3Op_IntTypes<HSAILInst inst,
                                  SDPatternOperator node,
                                  bit signed = 0> {
  def : InstBasic_3Op_Pat<inst, node, i32,
    !if(signed, BrigTypeX.S32, BrigTypeX.U32)
  >;

  def : InstBasic_3Op_Pat<inst, node, i64,
    !if(signed, BrigTypeX.S64, BrigTypeX.U64)
  >;
}

// XXX - b1 missing intentionally with current set of instructions.
multiclass InstBasic_3Op_BitIntTypes<HSAILInst inst,
                                    SDPatternOperator node> {
  def : InstBasic_3Op_Pat<inst, node, i32, BrigTypeX.B32>;
  def : InstBasic_3Op_Pat<inst, node, i64, BrigTypeX.B64>;
}

class InstBasic_CMov_Pat<HSAILInst inst,
                         ValueType vt,
                         int bt> : Pat <
  (select i1:$src0, (GPROrImm vt:$src1), (GPROrImm vt:$src2)),
  (vt (inst $src0, $src1, $src2, bt))
>;

multiclass InstBasic_3Op_FPTypes<HSAILInst inst,
                                SDPatternOperator node> {
  def : InstBasic_3Op_Pat<inst, node, f32, BrigTypeX.F32>;
  def : InstBasic_3Op_Pat<inst, node, f64, BrigTypeX.F64>;
}

////////////////////////////////////////////////////////////////////////////////
// Mod instruction patterns
////////////////////////////////////////////////////////////////////////////////

class InstMod_1Op_Pat<HSAILInst inst,
                      SDPatternOperator node,
                      ValueType vt,
                      int bt,
                      int round = BrigRound.NONE,
                      int ftz = 0> : Pat <
  (vt (node (GPROrImm vt:$src0))),
  (inst ftz, round, $src0, bt)
>;

class InstMod_2Op_Pat<HSAILInst inst,
                      SDPatternOperator node,
                      ValueType vt,
                      int bt,
                      int round = BrigRound.NONE,
                      int ftz = 0> : Pat <
  (vt (node (vt (GPROrImm vt:$src0)), (vt (GPROrImm vt:$src1)))),
  (inst ftz, round, $src0, $src1, bt)
>;

class InstMod_3Op_Pat<HSAILInst inst,
                      SDPatternOperator node,
                      ValueType vt,
                      int bt,
                      int round = BrigRound.NONE,
                      int ftz = 0> : Pat <
  (vt (node (GPROrImm vt:$src0), (GPROrImm vt:$src1), (GPROrImm vt:$src2))),
  (inst ftz, round, $src0, $src1, $src2, bt)
>;

multiclass InstMod_1Op_FPTypes<HSAILInst inst,
                              SDPatternOperator node,
                              int round = BrigRound.FLOAT_NEAR_EVEN> {
  def : InstMod_1Op_Pat<inst, node, f32, BrigTypeX.F32, round, 1>;
  def : InstMod_1Op_Pat<inst, node, f64, BrigTypeX.F64, round, 0>;
}

multiclass InstMod_2Op_IntTypes<HSAILInst inst,
                                SDPatternOperator node,
                                bit signed = 0> {
  def : InstMod_2Op_Pat<inst, node, i32,
    !if(signed, BrigTypeX.S32, BrigTypeX.U32)
  >;

  def : InstMod_2Op_Pat<inst, node, i64,
    !if(signed, BrigTypeX.S64, BrigTypeX.U64)
  >;
}

multiclass InstMod_2Op_FPTypes<HSAILInst inst,
                               SDPatternOperator node,
                               int round = BrigRound.FLOAT_NEAR_EVEN> {
  def : InstMod_2Op_Pat<inst, node, f32, BrigTypeX.F32, round, 1>;
  def : InstMod_2Op_Pat<inst, node, f64, BrigTypeX.F64, round, 0>;
}

multiclass InstMod_3Op_FPTypes<HSAILInst inst,
                               SDPatternOperator node> {
  def : InstMod_3Op_Pat<inst, node, f32, BrigTypeX.F32, BrigRound.FLOAT_NEAR_EVEN, 1>;
  def : InstMod_3Op_Pat<inst, node, f64, BrigTypeX.F64, BrigRound.FLOAT_NEAR_EVEN, 0>;
}

////////////////////////////////////////////////////////////////////////////////
// SourceType instruction patterns
////////////////////////////////////////////////////////////////////////////////

class InstSourceType_1Op_Pat<HSAILInst inst,
                             SDPatternOperator node,
                             ValueType vt,
                             int destbt,
                             int srcbt> : Pat <
  (vt (node (GPROrImm vt:$src0))),
  (inst $src0, destbt, srcbt)
>;

class InstSourceType_2Op_Pat<HSAILInst inst,
                             SDPatternOperator node,
                             ValueType vt,
                             int destbt,
                             int srcbt> : Pat <
  (vt (node (GPROrImm vt:$src0), (GPROrImm vt:$src1))),
  (inst $src0, $src1, destbt, srcbt)
>;

class InstSourceType_Class_Pat<HSAILInst inst,
                              SDPatternOperator node,
                              ValueType vt,
                              int srcbt> : Pat <
  (i1 (node (vt (GPROrImm vt:$src0)), (i32 (GPROrImm i32:$src1)))),
  (inst $src0, $src1, BrigTypeX.B1, srcbt)
>;

class InstSourceType_3Op_Pat<HSAILInst inst,
                             SDPatternOperator node,
                             ValueType vt,
                             int destbt,
                             int srcbt> : Pat <
  (vt (node (GPROrImm vt:$src0), (GPROrImm vt:$src1), (GPROrImm vt:$src2))),
  (inst $src0, $src1, $src2, destbt, srcbt)
>;

class InstSourceType_4Op_Pat<HSAILInst inst,
                             SDPatternOperator node,
                             ValueType vt,
                             int destbt,
                             int srcbt> : Pat <
  (node (GPROrImm vt:$src0),
        (GPROrImm vt:$src1),
        (GPROrImm vt:$src2),
        (GPROrImm vt:$src3)),
  (inst $src0, $src1, $src2, $src3, destbt, srcbt)
>;

////////////////////////////////////////////////////////////////////////////////
// Lane instruction patterns
////////////////////////////////////////////////////////////////////////////////

class ActiveLaneShufflePat<Instruction inst,
                           SDPatternOperator node,
                           ValueType vt,
                           int bt> : Pat<
  (vt (node (i32 timm:$width),
            (vt (GPROrImm vt:$src0)),
            (i32 (GPROrImm i32:$src1)),
            (vt (GPROrImm vt:$src2)),
            (i1 (GPROrImm i1:$src3)))),
  (inst (i32 $width), $src0, $src1, $src2, $src3, bt, BrigTypeX.NONE)
>;

class ActiveLaneIdPat<Instruction inst,
                      SDPatternOperator node,
                      ValueType vt,
                      int bt> : Pat<
  (vt (node (i32 timm:$width))),
  (inst $width, bt, BrigTypeX.NONE)
>;

class ActiveLaneCountPat<Instruction inst,
                      SDPatternOperator node,
                      ValueType vt,
                      int bt> : Pat<
  (vt (node (i32 timm:$width), (i1 (GPROrImm i1:$src0)))),
  (inst $width, $src0, bt, BrigTypeX.B1)
>;

////////////////////////////////////////////////////////////////////////////////
// Br instruction patterns
////////////////////////////////////////////////////////////////////////////////

class InstBr_0Op_NoRet_Pat<HSAILInst inst,
                           SDPatternOperator node,
                           int width = BrigWidth._1> : Pat <
  (node),
  (inst width, BrigTypeX.NONE)
>;

class InstBr_0Op_Pat<HSAILInst inst,
                     SDPatternOperator node,
                     int bt,
                     int width = BrigWidth._1> : Pat <
  (vt (node)),
  (inst width, bt)
>;

////////////////////////////////////////////////////////////////////////////////
// Seg instruction patterns
////////////////////////////////////////////////////////////////////////////////


class InstSeg_0Op_Pat<HSAILInst inst,
                      SDPatternOperator node,
                      ValueType vt,
                      int bt,
                      int segment> : Pat <
  (vt (node)),
  (inst segment, bt)
>;

////////////////////////////////////////////////////////////////////////////////
// Addr instruction patterns
////////////////////////////////////////////////////////////////////////////////

class InstAddr_1Op_Pat<HSAILInst inst,
                      SDPatternOperator node,
                      int bt,
                      int segment> : Pat <
  (node ADDR:$address),
  (inst segment, MEMOP:$address, bt)
>;

////////////////////////////////////////////////////////////////////////////////
// Atomic instruction patterns
////////////////////////////////////////////////////////////////////////////////

class AtomicPat_0Op_Pat<Instruction inst, SDPatternOperator node,
                        int op, ValueType vt, int bt> : Pat<
  (node (AtomicAddr AddressSpace:$segment,
                    BrigMemoryOrder:$order,
                    BrigMemoryScope:$scope,
                    equiv:$equiv,
                    MEMOP:$address)),
  (vt (inst op,
            $segment,
            $order,
            $scope,
            $equiv,
            MEMOP:$address,
            (vt zero_reg),
            (vt zero_reg),
            bt))
>;

class AtomicPat_1Op_Pat<Instruction inst, SDPatternOperator node,
                        int op, ValueType vt, int bt> : Pat<
  (node (AtomicAddr AddressSpace:$segment,
                    BrigMemoryOrder:$order,
                    BrigMemoryScope:$scope,
                    equiv:$equiv,
                    MEMOP:$address),
         (GPROrImm vt:$src0)),
  (vt (inst op,
            $segment,
            $order,
            $scope,
            $equiv,
            MEMOP:$address,
            $src0,
            (vt zero_reg),
            bt))
>;

class AtomicPat_2Op_Pat<Instruction inst, SDPatternOperator node,
                        int op, ValueType vt, int bt> : Pat<
  (node (AtomicAddr AddressSpace:$segment,
                    BrigMemoryOrder:$order,
                    BrigMemoryScope:$scope,
                    equiv:$equiv,
                    MEMOP:$address),
         (GPROrImm vt:$src0),
         (GPROrImm vt:$src1)),
  (vt (inst op,
            $segment,
            $order,
            $scope,
            $equiv,
            MEMOP:$address,
            vt:$src0,
            vt:$src1,
            bt))
>;

multiclass AtomicPat_0Op_IntTypes<Instruction inst,
                                  SDPatternOperator node,
                                  int op,
                                  bit signed = 0> {
  def : AtomicPat_0Op_Pat<
    inst, node, op, i32, !if(signed, BrigTypeX.S32, BrigTypeX.U32)
  >;

  def : AtomicPat_0Op_Pat<
    inst, node, op, i64, !if(signed, BrigTypeX.S64, BrigTypeX.U64)
  >;
}

multiclass AtomicPat_1Op_IntTypes<Instruction inst,
                                  SDPatternOperator node,
                                  int op,
                                  bit signed = 0> {
  def : AtomicPat_1Op_Pat<
    inst, node, op, i32, !if(signed, BrigTypeX.S32, BrigTypeX.U32)
  >;

  def : AtomicPat_1Op_Pat<
    inst, node, op, i64, !if(signed, BrigTypeX.S64, BrigTypeX.U64)
  >;
}

multiclass AtomicPat_1Op_BitTypes<Instruction inst,
                                  SDPatternOperator node,
                                  int op> {
  def : AtomicPat_1Op_Pat<
    inst, node, op, i32, BrigTypeX.B32
  >;

  def : AtomicPat_1Op_Pat<
    inst, node, op, i64, BrigTypeX.B64
  >;
}

multiclass AtomicPat_2Op_BitTypes<Instruction inst,
                                  SDPatternOperator node,
                                  int op> {
  def : AtomicPat_2Op_Pat<
    inst, node, op, i32, BrigTypeX.B32
  >;

  def : AtomicPat_2Op_Pat<
    inst, node, op, i64, BrigTypeX.B64
  >;
}

def target : Operand<OtherVT> {}
