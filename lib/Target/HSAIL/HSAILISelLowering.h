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

namespace llvm {

class HSAILSubtarget;

class HSAILTargetLowering : public TargetLowering {
private:
  const HSAILSubtarget *Subtarget;
  const HSAILRegisterInfo *RegInfo;
  const DataLayout *DL;

public:
  /// NOTE: The constructor takes ownership of TLOF.
  explicit HSAILTargetLowering(HSAILTargetMachine &TM);
  virtual ~HSAILTargetLowering();

  EVT getSetCCResultType(LLVMContext &Context, EVT VT) const override;

  const TargetRegisterClass *getRepRegClassFor(MVT VT) const override;

  uint8_t getRepRegClassCostFor(MVT VT) const override;

  bool isFPImmLegal(const APFloat &Imm, EVT VT) const override;

  bool allowsMisalignedMemoryAccesses(EVT, unsigned AddrSpace = 0,
                                      unsigned Align = 1,
                                      bool * /*Fast*/ = nullptr) const override;

  unsigned getJumpTableEncoding() const override;

  bool isOffsetFoldingLegal(const GlobalAddressSDNode *GA) const override;

  unsigned ComputeNumSignBitsForTargetNode(SDValue Op, const SelectionDAG &DAG,
                                           unsigned Depth = 0) const override;

  SDValue PerformDAGCombine(SDNode *N, DAGCombinerInfo &DCI) const override;

  bool isDesirableToTransformToIntegerOp(unsigned Opc, EVT VT) const override;

  bool isLoadBitCastBeneficial(EVT load, EVT bitcast) const override;

  virtual bool
  isVectorToScalarLoadStoreWidenBeneficial(unsigned Width, EVT WidenVT,
                                           const MemSDNode *N) const;

protected:
  /// Recursively lower a single argument.
  /// Either Ins or Outs must non-zero, which means we are doing argument load
  /// or store.
  /// ArgNo is an index to InVals and OutVals, which is advanced after the call.
  /// AS is an address space of argument, either arg or kernarg
  /// ParamPtr is a pointer value for argument to load from or store to.
  /// Offset is a value which has to be added to the pointer.
  /// If InFlag is present glue all operations.
  /// If ChainLink is true chain link all operations.
  /// Returns last operation value.
  SDValue LowerArgument(SDValue Chain, SDValue InFlag, bool ChainLink,
                        const SmallVectorImpl<ISD::InputArg> *Ins,
                        const SmallVectorImpl<ISD::OutputArg> *Outs, SDLoc dl,
                        SelectionDAG &DAG, SmallVectorImpl<SDValue> *InVals,
                        unsigned &ArgNo, Type *type, unsigned AS,
                        const char *ParamName, SDValue ParamPtr,
                        const SmallVectorImpl<SDValue> *OutVals = nullptr,
                        bool isRetArgLoad = false,
                        const AAMDNodes & = AAMDNodes(),
                        uint64_t offset = 0) const;

public:
  SDValue getArgLoad(SelectionDAG &DAG, SDLoc SL, EVT ArgVT, Type *Ty,
                     bool isSExt, unsigned AddressSpace, SDValue Chain,
                     SDValue Ptr, SDValue InFlag, unsigned index,
                     bool IsRetArgLoad = false, uint64_t Offset = 0) const;

  SDValue getArgStore(SelectionDAG &DAG, SDLoc SL, EVT ArgVT, Type *Ty,
                      unsigned AddressSpace, SDValue Chain, SDValue Ptr,
                      SDValue Value, unsigned Index, SDValue InFlag,
                      const AAMDNodes &AAInfo = AAMDNodes(),
                      uint64_t Offset = 0) const;

  //===--------------------------------------------------------------------===//
  // Lowering methods - These methods must be implemented by targets so that
  // the SelectionDAGLowering code knows how to lower these.

  SDValue LowerMemArgument(SDValue Chain, CallingConv::ID CallConv,
                           const SmallVectorImpl<ISD::InputArg> &ArgInfo,
                           SDLoc dl, SelectionDAG &DAG, const CCValAssign &VA,
                           MachineFrameInfo *MFI, unsigned i) const;

  SDValue LowerFormalArguments(SDValue Chain, CallingConv::ID CallConv,
                               bool isVarArg,
                               const SmallVectorImpl<ISD::InputArg> &Ins,
                               SDLoc dl, SelectionDAG &DAG,
                               SmallVectorImpl<SDValue> &InVals) const override;

  SDValue LowerCall(CallLoweringInfo &CLI,
                    SmallVectorImpl<SDValue> &InVals) const override;

  SDValue LowerReturn(SDValue Chain, CallingConv::ID CallConv, bool isVarArg,
                      const SmallVectorImpl<ISD::OutputArg> &Outs,
                      const SmallVectorImpl<SDValue> &OutVals, SDLoc dl,
                      SelectionDAG &DAG) const override;

  SDValue LowerOperation(SDValue Op, SelectionDAG &DAG) const override;

  void ReplaceNodeResults(SDNode *N, SmallVectorImpl<SDValue> &Results,
                          SelectionDAG &DAG) const override;

  const char *getTargetNodeName(unsigned Opcode) const override;

  /// Custom lowering methods
  SDValue LowerADD(SDValue Op, SelectionDAG &DAG) const;

  SDValue LowerLdKernargIntrinsic(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerINTRINSIC_WO_CHAIN(SDValue Op, SelectionDAG &DAG) const;

  SDValue LowerINTRINSIC_W_CHAIN(SDValue Op, SelectionDAG &DAG) const;

  SDValue lowerSamplerInitializerOperand(SDValue Op, SelectionDAG &DAG) const;

  SDValue LowerROTL(SDValue Op, SelectionDAG &DAG) const;

  SDValue LowerROTR(SDValue Op, SelectionDAG &DAG) const;

  SDValue LowerBSWAP(SDValue Op, SelectionDAG &DAG) const;

  SDValue LowerLOAD(SDValue Op, SelectionDAG &DAG) const;

  SDValue LowerSTORE(SDValue Op, SelectionDAG &DAG) const;

  SDValue LowerATOMIC_LOAD(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerATOMIC_STORE(SDValue Op, SelectionDAG &DAG) const;

  //===--------------------------------------------------------------------===//
  // Instruction Emitting Hooks
  //
  bool isLegalAddressingMode(const AddrMode &AM, Type *Ty) const override;

  bool isZExtFree(Type *Ty1, Type *Ty2) const override;

  bool isZExtFree(EVT VT1, EVT VT2) const override;

  bool isFAbsFree(EVT VT) const override;
  bool isFNegFree(EVT VT) const override;

  bool isNarrowingProfitable(EVT VT1, EVT VT2) const override;

  bool isLegalICmpImmediate(int64_t Imm) const override;

  MVT getScalarShiftAmountTy(EVT LHSTy) const override;

  bool isNoopAddrSpaceCast(unsigned SrcAS, unsigned DestAS) const override;

  void AdjustInstrPostInstrSelection(MachineInstr *MI,
                                     SDNode *Node) const override;
};

namespace HSAILISD {
// HSAIL Specific DAG Nodes
enum {
  // Start the numbering where the builtin ops leave off.
  FIRST_NUMBER = ISD::BUILTIN_OP_END,
  CALL, // Function call based on a single integer
  RET,
  SMAX,
  UMAX,
  SMIN,
  UMIN,
  FRACT,
  NFMA,
  UMAD,
  SMAD,
  UMUL24,
  SMUL24,
  UMAD24,
  SMAD24,
  BITSELECT,
  SBITEXTRACT,
  UBITEXTRACT,
  FLDEXP,
  CLASS,
  LDA,
  ACTIVELANEPERMUTE,
  ACTIVELANEID,
  ACTIVELANECOUNT,
  ACTIVELANEMASK,
  KERNARGBASEPTR,
  SEGMENTP,

  FIRST_MEM_OPCODE_NUMBER = ISD::FIRST_TARGET_MEMORY_OPCODE,

  // Load and store of arguments. Main purpose is to add glue to what would
  // be a generic load / store.
  ARG_LD,
  ARG_ST
};
}
} // end llvm namespace

#endif // _HSAIL_LOWERING_H_
