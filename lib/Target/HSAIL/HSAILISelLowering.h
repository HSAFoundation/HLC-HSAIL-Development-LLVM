//===---- HSAILISelLowering.h - HSAIL DAG Lowering Interface ----*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file describes how to lower LLVM code to machine code.  This has two
// main components:
//
//  1. Which ValueTypes are natively supported by the target.
//  2. Which operations are supported for supported ValueTypes.
//  3. Cost thresholds for alternative implementations of certain operations.
//
// In addition it has a few other components, like information about FP
// immediates.
//
//===----------------------------------------------------------------------===//

#ifndef _HSAIL_LOWERING_H_
#define _HSAIL_LOWERING_H_

#include "HSAILRegisterInfo.h"
#include "HSAILMachineFunctionInfo.h"
#include "llvm/CodeGen/CallingConvLower.h"
#include "llvm/CodeGen/SelectionDAG.h"
#include "llvm/Target/TargetLowering.h"
#include "HSAILISDNodes.h"

namespace llvm {

class HSAILSubtarget;

//===----------------------------------------------------------------------===//
/// HSAILLowering - This class defines information used to lower LLVM code to
/// legal SelectionDAG operators that the target instruction selector can accept
/// natively.
///
/// This class also defines callbacks that targets must implement to lower
/// target-specific constructs to SelectionDAG operators.
///
class HSAILTargetLowering : public TargetLowering {
private:
  /// Subtarget - Keep a pointer to the X86Subtarget around so that we can
  /// make the right decision when generating code for different targets.
  const HSAILSubtarget *Subtarget;
  const HSAILRegisterInfo *RegInfo;
  const DataLayout *DL;
public:
  /// NOTE: The constructor takes ownership of TLOF.
  explicit HSAILTargetLowering(HSAILTargetMachine &TM);
  virtual ~HSAILTargetLowering();

  EVT getSetCCResultType(LLVMContext &Context, EVT VT) const override;

  Sched::Preference getSchedulingPreference(SDNode *N) const override;

  const TargetRegisterClass *getRepRegClassFor(MVT VT) const override;

  uint8_t getRepRegClassCostFor(MVT VT) const override;

  bool getTgtMemIntrinsic(IntrinsicInfo &Info,
                          const CallInst &I,
                          unsigned Intrinsic) const override;

  bool isFPImmLegal(const APFloat &Imm, EVT VT) const override;

  unsigned getByValTypeAlignment(Type *Ty) const override;

  bool allowsMisalignedMemoryAccesses(EVT,
                                      unsigned AddrSpace = 0,
                                      unsigned Align = 1,
                                      bool * /*Fast*/ = nullptr) const override;

  unsigned getJumpTableEncoding() const override;

  bool isOffsetFoldingLegal(const GlobalAddressSDNode *GA) const override;

  unsigned ComputeNumSignBitsForTargetNode(SDValue Op,
                                           const SelectionDAG &DAG,
                                           unsigned Depth = 0) const override;

  bool isGAPlusOffset(SDNode *N, const GlobalValue* &GA,
                      int64_t &Offset) const override;

  SDValue PerformDAGCombine(SDNode *N, DAGCombinerInfo &DCI) const override;

  bool isTypeDesirableForOp(unsigned Opc, EVT VT) const override;

  bool isDesirableToTransformToIntegerOp(unsigned Opc, EVT VT) const override;

  bool IsDesirableToPromoteOp(SDValue Op, EVT &PVT) const override;

  bool isLoadBitCastBeneficial(EVT load, EVT bitcast) const override;

  virtual bool isVectorToScalarLoadStoreWidenBeneficial(unsigned Width, EVT WidenVT,
                                                        const MemSDNode *N) const;

protected:

  /// Recursively lower a single argument.
  /// Either Ins or Outs must non-zero, which means we are doing argument load
  /// or store.
  /// ArgNo is an index to InVals and OutVals, which is advanced after the call.
  /// AS is an address space of argument, either arg or kernarg
  /// ParamPtr is a pointer value for argument to load from or store to.
  /// Offset is a value which has to be added to the pointer.
  /// If InFlag gis present lue all operations.
  /// If ChainLink is true chain link all operations.
  /// Returns last operation value.
  SDValue LowerArgument(SDValue Chain, SDValue InFlag, bool ChainLink,
                        const SmallVectorImpl<ISD::InputArg> *Ins,
                        const SmallVectorImpl<ISD::OutputArg> *Outs,
                        SDLoc dl, SelectionDAG &DAG,
                        SmallVectorImpl<SDValue> *InVals,
                        unsigned &ArgNo,
                        Type *type,
                        unsigned AS,
                        const char *ParamName,
                        SDValue ParamPtr,
                        const SmallVectorImpl<SDValue> *OutVals = nullptr,
                        bool isRetArgLoad = false,
                        const AAMDNodes & = AAMDNodes(),
                        uint64_t offset = 0) const;

public:
  SDValue getArgLoad(SelectionDAG &DAG, SDLoc SL, EVT ArgVT, Type *Ty,
                     bool isSExt, unsigned AddressSpace,
                     SDValue Chain,
                     SDValue Ptr,
                     SDValue InFlag,
                     unsigned index,
                     bool IsRetArgLoad = false,
                     uint64_t Offset = 0) const;

  SDValue getArgStore(SelectionDAG &DAG, SDLoc SL, EVT ArgVT, Type *Ty,
                      unsigned AddressSpace,
                      SDValue Chain,
                      SDValue Ptr,
                      SDValue Value,
                      unsigned Index,
                      SDValue InFlag,
                      const AAMDNodes &AAInfo = AAMDNodes(),
                      uint64_t Offset = 0) const;

  //===--------------------------------------------------------------------===//
  // Lowering methods - These methods must be implemented by targets so that
  // the SelectionDAGLowering code knows how to lower these.

  SDValue LowerMemArgument(SDValue Chain,
                           CallingConv::ID CallConv,
                           const SmallVectorImpl<ISD::InputArg> &ArgInfo,
                           SDLoc dl, SelectionDAG &DAG,
                           const CCValAssign &VA,  MachineFrameInfo *MFI,
                           unsigned i) const;

  SDValue LowerFormalArguments(SDValue Chain,
                               CallingConv::ID CallConv,
                               bool isVarArg,
                               const SmallVectorImpl<ISD::InputArg> &Ins,
                               SDLoc dl,
                               SelectionDAG &DAG,
                               SmallVectorImpl<SDValue> &InVals) const override;

  SDValue LowerCall(CallLoweringInfo &CLI,
                    SmallVectorImpl<SDValue> &InVals) const override;

  SDValue LowerReturn(SDValue Chain,
                      CallingConv::ID CallConv,
                      bool isVarArg,
                      const SmallVectorImpl<ISD::OutputArg> &Outs,
                      const SmallVectorImpl<SDValue> &OutVals,
                      SDLoc dl,
                      SelectionDAG &DAG) const override;

  SDValue LowerOperation(SDValue Op, SelectionDAG &DAG) const override;

  void ReplaceNodeResults(SDNode *N,
                          SmallVectorImpl<SDValue> &Results,
                          SelectionDAG &DAG) const override;

  const char *getTargetNodeName(unsigned Opcode) const override;

  /// Custom lowering methods
 SDValue
  LowerADD(SDValue Op, SelectionDAG &DAG) const;

  SDValue LowerLdKernargIntrinsic(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerINTRINSIC_WO_CHAIN(SDValue Op, SelectionDAG &DAG) const;

  SDValue
  LowerINTRINSIC_W_CHAIN(SDValue Op, SelectionDAG &DAG) const;

  SDValue 
  lowerSamplerInitializerOperand(SDValue Op, SelectionDAG &DAG) const;

  SDValue 
  LowerROTL(SDValue Op, SelectionDAG &DAG) const;

  SDValue
  LowerROTR(SDValue Op, SelectionDAG &DAG) const;

  SDValue
  LowerBSWAP(SDValue Op, SelectionDAG &DAG) const;

  SDValue
  LowerLOAD(SDValue Op, SelectionDAG &DAG) const;

  SDValue
  LowerSTORE(SDValue Op, SelectionDAG &DAG) const;

  SDValue LowerATOMIC_LOAD(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerATOMIC_STORE(SDValue Op, SelectionDAG &DAG) const;

  //===--------------------------------------------------------------------===//
  // Instruction Emitting Hooks
  //

  //===--------------------------------------------------------------------===//
  // Addressing mode description hooks (used by LSR etc).
  //
  /// isLegalAddressingMode - Return true if the addressing mode represented by
  /// AM is legal for this target, for a load/store of the specified type.
  /// The type may be VoidTy, in which case only return true if the addressing
  /// mode is legal for a load/store of any legal type.
  /// TODO: Handle pre/postinc as well.
  bool isLegalAddressingMode(const AddrMode &AM, Type *Ty) const override;


  /// isTruncateFree - Return true if it's free to truncate a value of
  /// type Ty1 to type Ty2. e.g. On x86 it's free to truncate a i32 value in
  /// register EAX to i16 by referencing its sub-register AX.
  bool isTruncateFree(Type *Ty1, Type *Ty2) const override;

  bool isTruncateFree(EVT VT1, EVT VT2) const override;

  /// isZExtFree - Return true if any actual instruction that defines a
  /// value of type Ty1 implicitly zero-extends the value to Ty2 in the result
  /// register. This does not necessarily include registers defined in
  /// unknown ways, such as incoming arguments, or copies from unknown
  /// virtual registers. Also, if isTruncateFree(Ty2, Ty1) is true, this
  /// does not necessarily apply to truncate instructions. e.g. on x86-64,
  /// all instructions that define 32-bit values implicit zero-extend the
  /// result out to 64 bits.
  bool isZExtFree(Type *Ty1, Type *Ty2) const override;

  bool isZExtFree(EVT VT1, EVT VT2) const override;

  bool isFAbsFree(EVT VT) const override;
  bool isFNegFree(EVT VT) const override;

  /// isNarrowingProfitable - Return true if it's profitable to narrow
  /// operations of type VT1 to VT2. e.g. on x86, it's profitable to narrow
  /// from i32 to i8 but not from i32 to i16.
  bool isNarrowingProfitable(EVT VT1, EVT VT2) const override;

  /// isLegalICmpImmediate - Return true if the specified immediate is legal
  /// icmp immediate, that is the target has icmp instructions which can compare
  /// a register against the immediate without having to materialize the
  /// immediate into a register.
  bool isLegalICmpImmediate(int64_t Imm) const override;

  MVT getScalarShiftAmountTy(EVT LHSTy) const override;

  bool isNoopAddrSpaceCast(unsigned SrcAS, unsigned DestAS) const override;

  void AdjustInstrPostInstrSelection(MachineInstr *MI,
                                     SDNode *Node) const override;
};

} // end llvm namespace

#endif // _HSAIL_LOWERING_H_
