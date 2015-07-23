//===-- HSAILISelLowering.cpp - HSAIL DAG Lowering Implementation ---------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the interfaces that HSAIL uses to lower LLVM code into a
// selection DAG.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "hsail-isel"
#include "HSAIL.h"
#include "HSAILBrigDefs.h"
#include "HSAILInstrInfo.h"
#include "HSAILISelLowering.h"
#include "HSAILMachineFunctionInfo.h"
#include "HSAILSubtarget.h"
#include "HSAILTargetMachine.h"
#include "HSAILUtilityFunctions.h"
#include "HSAILOpaqueTypes.h"

#include "llvm/ADT/StringExtras.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/Mangler.h"
#include "llvm/IR/MDBuilder.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineJumpTableInfo.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/Dwarf.h"
#include "llvm/Support/raw_ostream.h"

#include "HSAILGenInstrInfo.inc"

using namespace llvm;
using namespace dwarf;

HSAILTargetLowering::HSAILTargetLowering(HSAILTargetMachine &TM)
    : TargetLowering(TM) {
  // HSAIL uses a -1 to store a Boolean value as an int. For example,
  // see the return values of the cmp instructions. This also requires
  // that we never use a cvt instruction for converting a Boolean to a
  // larger integer, because HSAIL cvt uses a zext when the source is
  // b1. Due to the setting below, LLVM will ensure that all such
  // conversions are done with the sext instruction.
  setBooleanContents(ZeroOrNegativeOneBooleanContent);

  Subtarget = &TM.getSubtarget<HSAILSubtarget>();

  RegInfo = Subtarget->getRegisterInfo();
  DL = getDataLayout();

  // Set up the register classes.
  addRegisterClass(MVT::i32, &HSAIL::GPR32RegClass);
  addRegisterClass(MVT::i64, &HSAIL::GPR64RegClass);
  addRegisterClass(MVT::f32, &HSAIL::GPR32RegClass);
  addRegisterClass(MVT::f64, &HSAIL::GPR64RegClass);
  addRegisterClass(MVT::i1, &HSAIL::CRRegClass);

  setOperationAction(ISD::FRINT, MVT::f32, Legal);
  setOperationAction(ISD::FRINT, MVT::f64, Legal);
  setOperationAction(ISD::FFLOOR, MVT::f32, Legal);
  setOperationAction(ISD::FFLOOR, MVT::f64, Legal);
  setOperationAction(ISD::FCEIL, MVT::f32, Legal);
  setOperationAction(ISD::FCEIL, MVT::f64, Legal);
  setOperationAction(ISD::FTRUNC, MVT::f32, Legal);
  setOperationAction(ISD::FTRUNC, MVT::f64, Legal);
  setOperationAction(ISD::FMINNUM, MVT::f32, Legal);
  setOperationAction(ISD::FMINNUM, MVT::f64, Legal);
  setOperationAction(ISD::FMAXNUM, MVT::f32, Legal);
  setOperationAction(ISD::FMAXNUM, MVT::f64, Legal);

  setOperationAction(ISD::BSWAP, MVT::i32, Custom);
  setOperationAction(ISD::BSWAP, MVT::i64, Expand);
  setOperationAction(ISD::ADD, MVT::i1, Custom);
  setOperationAction(ISD::ROTL, MVT::i1, Expand);
  setOperationAction(ISD::ROTL, MVT::i32, Custom);
  setOperationAction(ISD::ROTL, MVT::i64, Expand);
  setOperationAction(ISD::ROTR, MVT::i1, Expand);
  setOperationAction(ISD::ROTR, MVT::i32, Custom);
  setOperationAction(ISD::ROTR, MVT::i64, Expand);

  setOperationAction(ISD::CTTZ_ZERO_UNDEF, MVT::i32, Expand);
  setOperationAction(ISD::CTTZ_ZERO_UNDEF, MVT::i64, Expand);
  setOperationAction(ISD::CTLZ_ZERO_UNDEF, MVT::i32, Expand);
  setOperationAction(ISD::CTLZ_ZERO_UNDEF, MVT::i64, Expand);

  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::Other, Expand);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i1, Expand);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i8, Expand);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i16, Expand);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i32, Expand);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i64, Expand);

  setOperationAction(ISD::BR_CC, MVT::i32, Expand);
  setOperationAction(ISD::BR_CC, MVT::i64, Expand);
  setOperationAction(ISD::BR_CC, MVT::f32, Expand);
  setOperationAction(ISD::BR_CC, MVT::f64, Expand);
  setOperationAction(ISD::BR_CC, MVT::i1, Expand);

  setOperationAction(ISD::SELECT_CC, MVT::i32, Expand);
  setOperationAction(ISD::SELECT_CC, MVT::i64, Expand);
  setOperationAction(ISD::SELECT_CC, MVT::f32, Expand);
  setOperationAction(ISD::SELECT_CC, MVT::f64, Expand);
  setOperationAction(ISD::SELECT_CC, MVT::i1, Expand);

  setOperationAction(ISD::SELECT, MVT::f64, Promote);
  AddPromotedToType(ISD::SELECT, MVT::f64, MVT::i64);

  setOperationAction(ISD::SELECT, MVT::f32, Promote);
  AddPromotedToType(ISD::SELECT, MVT::f32, MVT::i32);

  setOperationAction(ISD::GlobalAddress, MVT::i32, Legal);
  setOperationAction(ISD::GlobalAddress, MVT::i64, Legal);

  setOperationAction(ISD::ConstantFP, MVT::f64, Legal);
  setOperationAction(ISD::ConstantFP, MVT::f32, Legal);
  setOperationAction(ISD::Constant, MVT::i32, Legal);
  setOperationAction(ISD::Constant, MVT::i64, Legal);

  setOperationAction(ISD::INTRINSIC_WO_CHAIN, MVT::Other, Custom);
  setOperationAction(ISD::INTRINSIC_W_CHAIN, MVT::Other, Custom);

  for (MVT VT : MVT::fp_valuetypes())
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::f32, Expand);

  for (MVT VT : MVT::fp_vector_valuetypes()) {
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v2f32, Expand);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v4f32, Expand);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v8f32, Expand);
  }

  for (MVT VT : MVT::integer_valuetypes()) {
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::i32, Expand);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::i1, Promote);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::i8, Custom);

    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::i16, Custom);
    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::i1, Promote);
    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::i8, Custom);
    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::i32, Expand);

    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::i32, Expand);
    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::i16, Custom);
    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::i1, Promote);
    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::i8, Custom);
  }

  for (MVT VT : MVT::integer_vector_valuetypes()) {
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v1i32, Expand);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v2i32, Expand);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v4i32, Expand);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v8i32, Expand);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v16i32, Expand);

    setLoadExtAction(ISD::EXTLOAD, VT, MVT::i16, Custom);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v1i16, Expand);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v2i16, Expand);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v4i16, Expand);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v8i16, Expand);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v16i16, Expand);

    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v2i8, Expand);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v4i8, Expand);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v8i8, Expand);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v16i8, Expand);

    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::v1i16, Expand);
    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::v2i16, Expand);
    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::v4i16, Expand);
    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::v4i16, Expand);
    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::v8i16, Expand);
    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::v16i16, Expand);

    setLoadExtAction(ISD::EXTLOAD, VT, MVT::i16, Custom);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v1i16, Expand);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v2i16, Expand);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v4i16, Expand);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v8i16, Expand);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v16i16, Expand);

    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v2i8, Expand);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v4i8, Expand);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v8i8, Expand);
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::v16i8, Expand);

    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::v1i16, Expand);
    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::v2i16, Expand);
    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::v4i16, Expand);
    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::v8i16, Expand);
    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::v16i16, Expand);

    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::v2i8, Expand);
    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::v4i8, Expand);
    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::v8i8, Expand);
    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::v16i8, Expand);

    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::v1i32, Expand);
    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::v2i32, Expand);
    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::v4i32, Expand);
    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::v8i32, Expand);
    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::v16i32, Expand);

    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::v1i32, Expand);
    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::v2i32, Expand);
    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::v4i32, Expand);
    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::v8i32, Expand);
    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::v16i32, Expand);

    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::v1i16, Expand);
    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::v2i16, Expand);
    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::v4i16, Expand);
    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::v8i16, Expand);
    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::v16i16, Expand);

    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::v2i8, Expand);
    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::v4i8, Expand);
    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::v8i8, Expand);
    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::v16i8, Expand);
  }

  setTruncStoreAction(MVT::f64, MVT::f32, Expand);
  setTruncStoreAction(MVT::v2f64, MVT::v2f32, Expand);
  setTruncStoreAction(MVT::v4f64, MVT::v4f32, Expand);

  setOperationAction(ISD::STORE, MVT::i1, Custom);
  setOperationAction(ISD::LOAD, MVT::i1, Custom);

  setOperationAction(ISD::ATOMIC_LOAD, MVT::i32, Custom);
  setOperationAction(ISD::ATOMIC_LOAD, MVT::i64, Custom);
  setOperationAction(ISD::ATOMIC_STORE, MVT::i32, Custom);
  setOperationAction(ISD::ATOMIC_STORE, MVT::i64, Custom);

  setTargetDAGCombine(ISD::INTRINSIC_WO_CHAIN);

  setJumpIsExpensive(true);
  setSelectIsExpensive(true);
  setPow2SDivIsCheap(false);
  setPrefLoopAlignment(0);
  setSchedulingPreference((CodeGenOpt::None == TM.getOptLevel()) ? Sched::Source
                                                                 : Sched::ILP);
#ifdef _DEBUG
  const char *pScheduler = std::getenv("AMD_DEBUG_HSAIL_PRE_RA_SCHEDULER");
  if (pScheduler) {
    if (strcmp(pScheduler, "ilp") == 0) {
      printf("Overriding pre-RA scheduler with %s\n", pScheduler);
      setSchedulingPreference(Sched::ILP);
    } else if (strcmp(pScheduler, "regpressure") == 0) {
      printf("Overriding pre-RA scheduler with %s\n", pScheduler);
      setSchedulingPreference(Sched::RegPressure);
    } else if (strcmp(pScheduler, "hybrid") == 0) {
      printf("Overriding pre-RA scheduler with %s\n", pScheduler);
      setSchedulingPreference(Sched::Hybrid);
    }
  }
#endif

  computeRegisterProperties();
  MaxStoresPerMemcpy = 4096;
  MaxStoresPerMemmove = 4096;
  MaxStoresPerMemset = 4096;
}

HSAILTargetLowering::~HSAILTargetLowering() {}

EVT HSAILTargetLowering::getSetCCResultType(LLVMContext &Context,
                                            EVT VT) const {
  return MVT::i1;
}

const TargetRegisterClass *
HSAILTargetLowering::getRepRegClassFor(MVT VT) const {
  switch (VT.SimpleTy) {
  case MVT::i64:
  case MVT::f64:
    return &HSAIL::GPR64RegClass;
  case MVT::i8:
  case MVT::i16:
  case MVT::i32:
  case MVT::f32:
    return &HSAIL::GPR32RegClass;
  case MVT::i1:
    return &HSAIL::CRRegClass;
  default:
    llvm_unreachable("Cannot find register class for value type");
    break;
  }
  return nullptr;
}

uint8_t HSAILTargetLowering::getRepRegClassCostFor(MVT VT) const {
  return 1;
}

bool HSAILTargetLowering::isFPImmLegal(const APFloat &Imm, EVT VT) const {
  // All floating point types are legal for 32bit and 64bit types.
  return (VT == EVT(MVT::f32) || VT == EVT(MVT::f64));
}

bool HSAILTargetLowering::allowsMisalignedMemoryAccesses(EVT,
                                                         unsigned AddrSpace,
                                                         unsigned Align,
                                                         bool *Fast) const {
  return true;
}

unsigned HSAILTargetLowering::getJumpTableEncoding() const {
  return MachineJumpTableInfo::EK_BlockAddress;
}

bool HSAILTargetLowering::isOffsetFoldingLegal(
  const GlobalAddressSDNode *GA) const {
  return true;
}

unsigned HSAILTargetLowering::ComputeNumSignBitsForTargetNode(
    SDValue Op, const SelectionDAG &DAG, unsigned Depth) const {
  return 1;
}

static SDValue PerformBitalignCombine(SDNode *N,
                                      TargetLowering::DAGCombinerInfo &DCI,
                                      unsigned IID) {
  assert(IID == HSAILIntrinsic::HSAIL_bitalign_b32 ||
         IID == HSAILIntrinsic::HSAIL_bytealign_b32);
  SDValue Opr0 = N->getOperand(1);
  SDValue Opr1 = N->getOperand(2);
  SDValue Opr2 = N->getOperand(3);
  ConstantSDNode *SHR = dyn_cast<ConstantSDNode>(Opr2);
  SelectionDAG &DAG = DCI.DAG;
  SDLoc dl = SDLoc(N);
  EVT VT = N->getValueType(0);
  // fold bitalign_b32(x & c1, x & c1, c2) -> bitalign_b32(x, x, c2) & rotr(c1,
  // c2)
  if (SHR && (Opr0 == Opr1) && (Opr0.getOpcode() == ISD::AND)) {
    if (ConstantSDNode *AndMask =
            dyn_cast<ConstantSDNode>(Opr0.getOperand(1))) {
      uint64_t and_mask = AndMask->getZExtValue();
      uint64_t shr_val = SHR->getZExtValue() & 31U;
      if (IID == HSAILIntrinsic::HSAIL_bytealign_b32)
        shr_val = (shr_val & 3U) << 3U;
      and_mask =
          ((and_mask >> shr_val) | (and_mask << (32U - shr_val))) & 0xffffffffu;
      Opr0 = Opr0->getOperand(0);
      return DAG.getNode(ISD::AND, SDLoc(Opr1), Opr1.getValueType(),
                         DAG.getNode(ISD::INTRINSIC_WO_CHAIN, dl, VT,
                                     DAG.getConstant(IID, MVT::i32), Opr0, Opr0,
                                     Opr2),
                         DAG.getConstant(and_mask, MVT::i32));
    }
  }
  // fold bitalign_b32(x, y, c) -> bytealign_b32(x, y, c/8) if c & 7 == 0
  if (SHR && (IID == HSAILIntrinsic::HSAIL_bitalign_b32)) {
    uint64_t shr_val = SHR->getZExtValue() & 31U;
    if ((shr_val & 7U) == 0)
      return DAG.getNode(
          ISD::INTRINSIC_WO_CHAIN, dl, VT,
          DAG.getConstant(HSAILIntrinsic::HSAIL_bytealign_b32, MVT::i32), Opr0,
          Opr1, DAG.getConstant(shr_val >> 3U, MVT::i32));
  }
  return SDValue();
}

static SDValue
PerformIntrinsic_Wo_ChainCombine(SDNode *N,
                                 TargetLowering::DAGCombinerInfo &DCI) {
  assert(N->getOpcode() == ISD::INTRINSIC_WO_CHAIN);
  unsigned IID = cast<ConstantSDNode>(N->getOperand(0))->getZExtValue();
  switch (IID) {
  case HSAILIntrinsic::HSAIL_bitalign_b32: // fall-through
  case HSAILIntrinsic::HSAIL_bytealign_b32:
    return PerformBitalignCombine(N, DCI, IID);
  }
  return SDValue();
}

SDValue HSAILTargetLowering::PerformDAGCombine(SDNode *N,
                                               DAGCombinerInfo &DCI) const {
  switch (N->getOpcode()) {
  case ISD::INTRINSIC_WO_CHAIN:
    return PerformIntrinsic_Wo_ChainCombine(N, DCI);
  default:
    break;
  }

  return SDValue();
}

bool HSAILTargetLowering::isDesirableToTransformToIntegerOp(unsigned Opc,
                                                            EVT VT) const {
  return (Opc == ISD::LOAD || Opc == ISD::STORE) &&
         (VT.getSimpleVT() == MVT::f32 || VT.getSimpleVT() == MVT::f64);
}

//===--------------------------------------------------------------------===//

/// n-th element of a vector has different alignment than a base.
/// This function returns alignment for n-th alement.

// FIXME: It is probably not correct to use this.
static unsigned getElementAlignment(const DataLayout *DL, Type *Ty,
                                    unsigned n) {
  if (Ty->isArrayTy()) // FIXME
    return getElementAlignment(DL, Ty->getArrayElementType(), 0);

  unsigned Alignment = DL->getABITypeAlignment(Ty);
  if (n && (Alignment > 1)) {
    Type *EltTy = Ty->getScalarType();
    unsigned ffs = 0;
    while (((n >> ffs) & 1) == 0)
      ffs++;
    Alignment = (DL->getABITypeAlignment(EltTy) * (1 << ffs)) & (Alignment - 1);
  } else {
    if (OpaqueType OT = GetOpaqueType(Ty)) {
      if (IsImage(OT) || OT == Sampler)
        Alignment = 8;
    }
  }
  return Alignment;
}

SDValue
HSAILTargetLowering::LowerReturn(SDValue Chain, CallingConv::ID CallConv,
                                 bool isVarArg,
                                 const SmallVectorImpl<ISD::OutputArg> &Outs,
                                 const SmallVectorImpl<SDValue> &OutVals,
                                 SDLoc dl, SelectionDAG &DAG) const {
  MachineFunction &MF = DAG.getMachineFunction();
  HSAILMachineFunctionInfo *FuncInfo = MF.getInfo<HSAILMachineFunctionInfo>();
  HSAILParamManager &PM = FuncInfo->getParamManager();
  const Function *F = MF.getFunction();
  const FunctionType *funcType = F->getFunctionType();

  SmallVector<SDValue, 6> RetOps;
  RetOps.push_back(Chain);

  Type *type = funcType->getReturnType();
  if (!type->isVoidTy()) {
    Mangler Mang(getDataLayout());

    // FIXME: The ParamManager here is only used for making sure the built
    // string's name survives until code emission. We can't rely on the name
    // here being added because unreachable functions with return values may not
    // have return instructions.
    const char *SymName = PM.getParamName(
        PM.addReturnParam(type, PM.mangleArg(&Mang, F->getName())));

    MVT ArgPtrVT = getPointerTy(HSAILAS::ARG_ADDRESS);
    SDValue RetVariable = DAG.getTargetExternalSymbol(SymName, ArgPtrVT);

    AAMDNodes MD; // FIXME: What is this for?
    // Value *mdops[] = { const_cast<Function*>(F) };
    // MDNode *MD = MDNode::get(F->getContext(), mdops);

    unsigned ArgNo = 0;
    LowerArgument(Chain, SDValue(), false, nullptr, &Outs, dl, DAG, &RetOps, ArgNo,
                  type, HSAILAS::ARG_ADDRESS, nullptr, RetVariable, &OutVals,
                  false, MD);
    Chain = DAG.getNode(ISD::TokenFactor, dl, MVT::Other, RetOps);
  }

  return DAG.getNode(HSAILISD::RET, dl, MVT::Other, Chain);
}

/// Create kernel or function parameter scalar load and return its
/// value. AddressSpace used to determine if that is a kernel or function
/// argument. ArgVT specifies expected value type where 'Ty' refers to the real
/// argument type from function's signature.
///
/// If the call sequence is not glued we may have unrelated to call instructions
/// scheduled into the argscope if intent was argscope use. This function
/// inserts a load or store argument instruction with glue. If InFlag contains
/// glue it is used for inbound glue. Glue is produced as a last result and can
/// be consumed at will of the caller. Offset operand is added to the offset
/// value calculated from index.
SDValue HSAILTargetLowering::getArgLoad(SelectionDAG &DAG, SDLoc SL, EVT ArgVT,
                                        Type *Ty, bool isSExt,
                                        unsigned AddressSpace, SDValue Chain,
                                        SDValue Ptr, SDValue InFlag,
                                        unsigned Index, bool IsRetArgLoad,
                                        uint64_t Offset) const {
  Type *EltTy = Ty;

  if (Ty->isArrayTy())
    EltTy = Ty->getArrayElementType();
  EltTy = EltTy->getScalarType();

  MVT PtrVT = getPointerTy(AddressSpace);
  PointerType *ArgPT = PointerType::get(EltTy, AddressSpace);

  // TODO_HSA: check if that works with packed structs, it can happen
  //           we would need to inhibit alignment calculation in that case.
  Offset += DL->getTypeStoreSize(EltTy) * Index;

  EVT MemVT = ArgVT;
  if (ArgVT == MVT::i1)
    MemVT = MVT::i8;

  if (!Ptr && AddressSpace == HSAILAS::KERNARG_ADDRESS) {
    // If the argument symbol is unknown, generate a kernargbaseptr instruction.
    Ptr = DAG.getNode(HSAILISD::KERNARGBASEPTR, SL, PtrVT);
  }

  unsigned Align = getElementAlignment(DL, Ty, Index);
  unsigned Width = BRIG_WIDTH_1;

  // TODO_HSA: Due to problems with RT alignment of vectors we have to
  //           use element size instead of vector size for alignment.
  //           Fix when RT is fixed.
  if (AddressSpace == HSAILAS::KERNARG_ADDRESS) {
    Align = DL->getABITypeAlignment(EltTy);
    Width = BRIG_WIDTH_ALL;
  }

  SDValue PtrOffs =
      DAG.getNode(ISD::ADD, SL, PtrVT, Ptr, DAG.getConstant(Offset, PtrVT));

  const SDValue Ops[] = {Chain, PtrOffs, DAG.getTargetConstant(Width, MVT::i32),
                         DAG.getTargetConstant(IsRetArgLoad, MVT::i1),
                         DAG.getTargetConstant(isSExt, MVT::i1), InFlag};

  ArrayRef<SDValue> OpsArr = makeArrayRef(Ops);
  if (!InFlag)
    OpsArr = OpsArr.drop_back(1);

  EVT VT = (MemVT.getStoreSize() < 4) ? MVT::i32 : ArgVT;
  SDVTList VTs = DAG.getVTList(VT, MVT::Other, MVT::Glue);

  MachinePointerInfo PtrInfo(UndefValue::get(ArgPT), Offset);

  SDValue Arg = DAG.getMemIntrinsicNode(HSAILISD::ARG_LD, SL, VTs, OpsArr,
                                        MemVT, PtrInfo, Align,
                                        false,                 // isVolatile
                                        true,                  // ReadMem
                                        false,                 // WriteMem
                                        MemVT.getStoreSize()); // Size

  if (ArgVT == MVT::i1) {
    const SDValue Ops[] = {DAG.getNode(ISD::TRUNCATE, SL, MVT::i1, Arg),
                           Arg.getValue(1), Arg.getValue(2)};

    return DAG.getMergeValues(Ops, SL);
  }

  return Arg;
}

SDValue HSAILTargetLowering::getArgStore(
    SelectionDAG &DAG, SDLoc SL, EVT ArgVT, Type *Ty, unsigned AddressSpace,
    SDValue Chain, SDValue Ptr, SDValue Value, unsigned Index, SDValue InFlag,
    const AAMDNodes &AAInfo, uint64_t Offset) const {

  Type *EltTy = Ty;
  if (Ty->isArrayTy())
    EltTy = Ty->getArrayElementType();
  EltTy = EltTy->getScalarType();
  MVT PtrVT = getPointerTy(AddressSpace);
  PointerType *ArgPT = PointerType::get(EltTy, AddressSpace);
  // TODO_HSA: check if that works with packed structs, it can happen
  //           we would need to inhibit alignment calculation in that case.
  Offset += DL->getTypeStoreSize(EltTy) * Index;

  EVT MemVT = ArgVT;

  if (ArgVT == MVT::i1) {
    MemVT = MVT::i8;
    Value = DAG.getNode(ISD::ZERO_EXTEND, SL, MVT::i32, Value);
  }

  SDValue PtrOffs =
      DAG.getNode(ISD::ADD, SL, PtrVT, Ptr, DAG.getConstant(Offset, PtrVT));

  unsigned Align = getElementAlignment(DL, Ty, Index);
  // TODO_HSA: Due to problems with RT alignment of vectors we have to
  //           use element size instead of vector size for alignment.
  //           Fix when RT is fixed.
  if (AddressSpace == HSAILAS::KERNARG_ADDRESS)
    Align = DL->getABITypeAlignment(EltTy);

  SDValue Ops[] = {Chain, Value, PtrOffs, InFlag};

  ArrayRef<SDValue> OpsArr = makeArrayRef(Ops);
  if (!InFlag)
    OpsArr = OpsArr.drop_back(1);

  SDVTList VTs = DAG.getVTList(MVT::Other, MVT::Glue);
  MachinePointerInfo PtrInfo(UndefValue::get(ArgPT), Offset);

  return DAG.getMemIntrinsicNode(HSAILISD::ARG_ST, SL, VTs, OpsArr, MemVT,
                                 PtrInfo, Align,
                                 false, // isVolatile
                                 false, // ReadMem
                                 true,  // WriteMem
                                 MemVT.getStoreSize());
}

/// Recursively lower a single argument or its element.
/// Either Ins or Outs must non-zero, which means we are doing argument load
/// or store.
/// ArgNo is an index to InVals and OutVals, which is advanced after the call.
/// AS is an address space of argument, either arg or kernarg
/// ParamPtr is a pointer value for argument to load from or store to.
/// Offset is a value which has to be added to the pointer.
/// If InFlag gis present lue all operations.
/// If ChainLink is true chain link all operations.
/// Returns last operation value.
SDValue HSAILTargetLowering::LowerArgument(
    SDValue Chain, SDValue InFlag, bool ChainLink,
    const SmallVectorImpl<ISD::InputArg> *Ins,
    const SmallVectorImpl<ISD::OutputArg> *Outs, SDLoc dl, SelectionDAG &DAG,
    SmallVectorImpl<SDValue> *InVals, unsigned &ArgNo, Type *type, unsigned AS,
    const char *ParamName, SDValue ParamPtr,
    const SmallVectorImpl<SDValue> *OutVals, bool isRetArgLoad,
    const AAMDNodes &AAInfo, uint64_t offset) const {
  assert((Ins == nullptr && Outs != nullptr) || (Ins != nullptr && Outs == nullptr));

  Type *sType = type->getScalarType();

  EVT argVT = Ins ? (*Ins)[ArgNo].VT : (*Outs)[ArgNo].VT;

  if (sType->isIntegerTy(8))
    argVT = MVT::i8;
  else if (sType->isIntegerTy(16))
    argVT = MVT::i16;

  bool isLoad = Ins != nullptr;
  bool hasFlag = InFlag.getNode() != nullptr;
  SDValue ArgValue;

  const VectorType *VecTy = dyn_cast<VectorType>(type);
  const ArrayType *ArrTy = dyn_cast<ArrayType>(type);
  if (VecTy || ArrTy) {
    // This assumes that char and short vector elements are unpacked in Ins.
    unsigned num_elem =
        VecTy ? VecTy->getNumElements() : ArrTy->getNumElements();
    for (unsigned i = 0; i < num_elem; ++i) {
      if (isLoad) {
        bool IsSExt = (*Ins)[ArgNo].Flags.isSExt();
        ArgValue = getArgLoad(DAG, dl, argVT, type, IsSExt, AS, Chain, ParamPtr,
                              InFlag, i, isRetArgLoad, offset);
      } else {
        ArgValue = getArgStore(DAG, dl, argVT, type, AS, Chain, ParamPtr,
                               (*OutVals)[ArgNo], i, InFlag, AAInfo, offset);
      }

      if (ChainLink)
        Chain = ArgValue.getValue(isLoad ? 1 : 0);

      // Glue next vector loads regardless of input flag to favor vectorization.
      InFlag = ArgValue.getValue(isLoad ? 2 : 1);
      if (InVals)
        InVals->push_back(ArgValue);
      ArgNo++;
    }

    return ArgValue;
  }

  if (StructType *STy = dyn_cast<StructType>(type)) {
    const StructLayout *SL = DL->getStructLayout(STy);
    unsigned num_elem = STy->getNumElements();
    for (unsigned i = 0; i < num_elem; ++i) {
      ArgValue = LowerArgument(Chain, InFlag, ChainLink, Ins, Outs, dl, DAG,
                               InVals, ArgNo, STy->getElementType(i), AS,
                               ParamName, ParamPtr, OutVals, isRetArgLoad,
                               AAInfo, offset + SL->getElementOffset(i));
      if (ChainLink)
        Chain = ArgValue.getValue(isLoad ? 1 : 0);

      if (hasFlag)
        InFlag = ArgValue.getValue(isLoad ? 2 : 1);
    }
    return ArgValue;
  }

  // Regular scalar load case.
  if (isLoad) {
    bool IsSExt = (*Ins)[ArgNo].Flags.isSExt();
    ArgValue = getArgLoad(DAG, dl, argVT, type, IsSExt, AS, Chain, ParamPtr,
                          InFlag, 0, isRetArgLoad, offset);

  } else {
    ArgValue = getArgStore(DAG, dl, argVT, type, AS, Chain, ParamPtr,
                           (*OutVals)[ArgNo], 0, InFlag, AAInfo, offset);
  }

  if (InVals)
    InVals->push_back(ArgValue);
  ArgNo++;

  return ArgValue;
}

SDValue HSAILTargetLowering::LowerFormalArguments(
    SDValue Chain, CallingConv::ID CallConv, bool isVarArg,
    const SmallVectorImpl<ISD::InputArg> &Ins, SDLoc dl, SelectionDAG &DAG,
    SmallVectorImpl<SDValue> &InVals) const {
  MachineFunction &MF = DAG.getMachineFunction();
  HSAILMachineFunctionInfo *FuncInfo = MF.getInfo<HSAILMachineFunctionInfo>();
  HSAILParamManager &PM = FuncInfo->getParamManager();
  unsigned AS = HSAIL::isKernelFunc(MF.getFunction()) ? HSAILAS::KERNARG_ADDRESS
                                                      : HSAILAS::ARG_ADDRESS;
  MVT PtrTy = getPointerTy(AS);

  Mangler Mang(DL);

  // Map function param types to Ins.
  Function::const_arg_iterator AI = MF.getFunction()->arg_begin();
  Function::const_arg_iterator AE = MF.getFunction()->arg_end();
  for (unsigned ArgNo = 0; AI != AE; ++AI) {
    unsigned Param = PM.addArgumentParam(
        AS, *AI, HSAILParamManager::mangleArg(&Mang, AI->getName()));
    const char *ParamName = PM.getParamName(Param);
    std::string md = (AI->getName() + ":" + ParamName + " ").str();
    FuncInfo->addMetadata("argmap:" + md, true);
    SDValue ParamPtr = DAG.getTargetExternalSymbol(ParamName, PtrTy);

    // FIXME: What is this for?
    // Value *mdops[] = { const_cast<Argument*>(&(*AI)) };
    // MDNode *ArgMD = MDNode::get(MF.getFunction()->getContext(), mdops);

    LowerArgument(Chain, SDValue(), false, &Ins, nullptr, dl, DAG, &InVals, ArgNo,
                  AI->getType(), AS, ParamName, ParamPtr, nullptr);
  }

  return Chain;
}

static BrigType getParamBrigType(Type *Ty, const DataLayout &DL, bool IsSExt) {
  BrigType BT = HSAIL::getBrigType(Ty, DL, IsSExt);
  if (BT == BRIG_TYPE_B1) {
    assert(!IsSExt && "When does this happen?");
    return IsSExt ? BRIG_TYPE_S8 : BRIG_TYPE_U8;
  }

  return BT;
}

SDValue HSAILTargetLowering::LowerCall(CallLoweringInfo &CLI,
                                       SmallVectorImpl<SDValue> &InVals) const {
  SelectionDAG &DAG = CLI.DAG;
  SDLoc &dl = CLI.DL;
  SmallVector<ISD::OutputArg, 32> &Outs = CLI.Outs;
  SmallVector<SDValue, 32> &OutVals = CLI.OutVals;
  SmallVector<ISD::InputArg, 32> &Ins = CLI.Ins;
  SDValue Chain = CLI.Chain;
  SDValue Callee = CLI.Callee;
  CLI.IsTailCall = false;

  MachineFunction &MF = DAG.getMachineFunction();
  HSAILParamManager &PM =
      MF.getInfo<HSAILMachineFunctionInfo>()->getParamManager();
  Mangler Mang(DL);

  Chain = DAG.getCALLSEQ_START(Chain, DAG.getIntPtrConstant(0, true), dl);
  SDValue InFlag = Chain.getValue(1);

  const FunctionType *funcType = nullptr;
  const Function *calleeFunc = nullptr;
  const char *FuncName = nullptr;

  // If the callee is a GlobalAddress/ExternalSymbol node (quite common,
  // every direct call is) turn it into a TargetGlobalAddress/
  // TargetExternalSymbol
  // node so that legalize doesn't hack it.
  if (GlobalAddressSDNode *G = dyn_cast<GlobalAddressSDNode>(Callee)) {
    unsigned AS = G->getAddressSpace();
    const GlobalValue *GV = G->getGlobal();
    Callee = DAG.getTargetGlobalAddress(GV, dl, getPointerTy(AS));

    if (const GlobalAlias *GA = dyn_cast<GlobalAlias>(GV))
      calleeFunc = cast<Function>(GA->getAliasee());
    else
      calleeFunc = cast<Function>(GV);

    funcType = calleeFunc->getFunctionType();
    FuncName = GV->getName().data();
  } else
    llvm_unreachable(
        "Cannot lower call to a function which is not a global address");

  assert(funcType != nullptr);

  SmallVector<SDValue, 8> Ops;
  SmallVector<SDValue, 8> VarOps;
  SDVTList VTs = DAG.getVTList(MVT::Other, MVT::Glue);

  Type *retType = funcType->getReturnType();
  SDValue RetValue;
  if (!retType->isVoidTy()) {
    MVT PtrVT = getPointerTy(HSAILAS::ARG_ADDRESS);
    RetValue = DAG.getTargetExternalSymbol(
        PM.getParamName(
            PM.addCallRetParam(retType, PM.mangleArg(&Mang, FuncName))),
        PtrVT);

    unsigned NElts;
    Type *EmitTy = HSAIL::analyzeType(retType, NElts, *DL);

    BrigType BT = getParamBrigType(EmitTy, *DL, CLI.RetSExt);

    unsigned Align = HSAIL::getAlignTypeQualifier(retType, *DL, false);

    const SDValue ArgDeclOps[] = {RetValue, DAG.getTargetConstant(BT, MVT::i32),
                                  DAG.getTargetConstant(NElts, PtrVT),
                                  DAG.getTargetConstant(Align, MVT::i32), Chain,
                                  InFlag};

    SDNode *ArgDeclNode =
        DAG.getMachineNode(HSAIL::ARG_DECL, dl, VTs, ArgDeclOps);

    SDValue ArgDecl(ArgDeclNode, 0);

    Chain = SDValue(ArgDeclNode, 0);
    InFlag = Chain.getValue(1);

    VarOps.push_back(RetValue);
  }

  // Delimit return value and parameters with 0
  VarOps.push_back(DAG.getTargetConstant(0, MVT::i32));
  unsigned FirstArg = VarOps.size();

  unsigned int j = 0, k = 0;
  Function::const_arg_iterator ai;
  Function::const_arg_iterator ae;
  if (calleeFunc) {
    ai = calleeFunc->arg_begin();
    ae = calleeFunc->arg_end();
  }

  MVT ArgPtrVT = getPointerTy(HSAILAS::ARG_ADDRESS);

  MDBuilder MDB(*DAG.getContext());
  for (FunctionType::param_iterator pb = funcType->param_begin(),
                                    pe = funcType->param_end();
       pb != pe; ++pb, ++ai, ++k) {
    Type *type = *pb;

    std::string ParamName;
    if (calleeFunc && ai != ae) {
      ParamName = PM.mangleArg(&Mang, ai->getName());
    }
    if (ParamName.empty()) {
      ParamName = "__param_p";
      ParamName.append(itostr(k));
    }
    SDValue StParamValue = DAG.getTargetExternalSymbol(
        PM.getParamName(PM.addCallArgParam(type, ParamName)), ArgPtrVT);

    unsigned NElts;
    Type *EmitTy = HSAIL::analyzeType(type, NElts, *DL);

    // START array parameter declaration
    BrigType BT = getParamBrigType(EmitTy, *DL, Outs[j].Flags.isSExt());

    unsigned Align = HSAIL::getAlignTypeQualifier(type, *DL, false);
    const SDValue ArgDeclOps[] = {
        StParamValue, DAG.getTargetConstant(BT, MVT::i32),
        DAG.getTargetConstant(NElts, ArgPtrVT),
        DAG.getTargetConstant(Align, MVT::i32), Chain, InFlag};

    SDNode *ArgDeclNode =
        DAG.getMachineNode(HSAIL::ARG_DECL, dl, VTs, ArgDeclOps);
    Chain = SDValue(ArgDeclNode, 0);
    InFlag = Chain.getValue(1);

    // END array parameter declaration
    VarOps.push_back(StParamValue);

    for (; j < Outs.size() - 1; j++) {
      if (Outs[j].OrigArgIndex != Outs[j + 1].OrigArgIndex)
        break;
    }
    j++;
  }

  j = k = 0;
  for (FunctionType::param_iterator pb = funcType->param_begin(),
                                    pe = funcType->param_end();
       pb != pe; ++pb, ++k) {
    Type *type = *pb;
    Chain = LowerArgument(Chain, InFlag, true, nullptr, &Outs, dl, DAG, nullptr, j,
                          type, HSAILAS::ARG_ADDRESS, nullptr,
                          VarOps[FirstArg + k], &OutVals);
    InFlag = Chain.getValue(1);
  }

  // If this is a direct call, pass the chain and the callee
  if (Callee.getNode()) {
    Ops.push_back(Callee);
  }

  // Add actual arguments to the end of the list
  for (unsigned int i = 0, e = VarOps.size(); i != e; ++i) {
    Ops.push_back(VarOps[i]);
  }

  Ops.push_back(Chain);
  Ops.push_back(InFlag);

  SDNode *Call = DAG.getMachineNode(HSAIL::CALL, dl, VTs, Ops);
  Chain = SDValue(Call, 0);

  InFlag = Chain.getValue(1);

  // Read return value.
  if (!Ins.empty()) {
    j = 0;
    Chain = LowerArgument(Chain, InFlag, true, &Ins, nullptr, dl, DAG, &InVals, j,
                          retType, HSAILAS::ARG_ADDRESS, nullptr, RetValue, nullptr,
                          true);
    InFlag = Chain.getValue(2);
    Chain = Chain.getValue(1);
  }

  // Create the CALLSEQ_END node
  Chain = DAG.getCALLSEQ_END(Chain, DAG.getIntPtrConstant(0, true),
                             DAG.getIntPtrConstant(0, true), InFlag, dl);
  return Chain;
}

#define LOWER(A)                                                               \
  case ISD::A:                                                                 \
    return Lower##A(Op, DAG)

SDValue HSAILTargetLowering::LowerOperation(SDValue Op,
                                            SelectionDAG &DAG) const {
  switch (Op.getOpcode()) {
    LOWER(INTRINSIC_WO_CHAIN);
    LOWER(INTRINSIC_W_CHAIN);
    LOWER(ROTL);
    LOWER(ROTR);
    LOWER(BSWAP);
    LOWER(ADD);
    LOWER(LOAD);
    LOWER(STORE);
    LOWER(ATOMIC_LOAD);
    LOWER(ATOMIC_STORE);
    break;
  default:
    Op.getNode()->dump();
    assert(0 && "Custom lowering code for this"
                "instruction is not implemented yet!");
    break;
  }
  return Op;
}

/// ReplaceNodeResults - This callback is invoked when a node result type is
/// illegal for the target, and the operation was registered to use 'custom'
/// lowering for that result type.  The target places new result values for
/// the node in Results (their number and types must exactly match those of
/// the original return values of the node), or leaves Results empty, which
/// indicates that the node is not to be custom lowered after all.
///
/// If the target has no operations that require custom lowering, it need not
/// implement this.  The default implementation aborts.
void HSAILTargetLowering::ReplaceNodeResults(SDNode *N,
                                             SmallVectorImpl<SDValue> &Results,
                                             SelectionDAG &DAG) const {
  return TargetLowering::ReplaceNodeResults(N, Results, DAG);
}

/// getTargetNodeName() - This method returns the name of a target specific
/// DAG node.
const char *HSAILTargetLowering::getTargetNodeName(unsigned Opcode) const {
  switch (Opcode) {
  default:
    llvm_unreachable("Unknown target-node");
    return nullptr;
  case HSAILISD::CALL:
    return "HSAILISD::CALL";
  case HSAILISD::RET:
    return "HSAILISD::RET";
  case HSAILISD::SMAX:
    return "HSAILISD::SMAX";
  case HSAILISD::UMAX:
    return "HSAILISD::UMAX";
  case HSAILISD::SMIN:
    return "HSAILISD::SMIN";
  case HSAILISD::UMIN:
    return "HSAILISD::UMIN";
  case HSAILISD::FRACT:
    return "HSAILISD::FRACT";
  case HSAILISD::NFMA:
    return "HSAILISD::NFMA";
  case HSAILISD::UMAD:
    return "HSAILISD::UMAD";
  case HSAILISD::SMAD:
    return "HSAILISD::SMAD";
  case HSAILISD::UMUL24:
    return "HSAILISD::UMUL24";
  case HSAILISD::SMUL24:
    return "HSAILISD::SMUL24";
  case HSAILISD::UMAD24:
    return "HSAILISD::UMAD24";
  case HSAILISD::SMAD24:
    return "HSAILISD::SMAD24";
  case HSAILISD::BITSELECT:
    return "HSAILISD::BITSELECT";
  case HSAILISD::SBITEXTRACT:
    return "HSAILISD::SBITEXTRACT";
  case HSAILISD::UBITEXTRACT:
    return "HSAILISD::UBITEXTRACT";
  case HSAILISD::FLDEXP:
    return "HSAILISD::FLDEXP";
  case HSAILISD::CLASS:
    return "HSAILISD::CLASS";
  case HSAILISD::LDA:
    return "HSAILISD::LDA";
  case HSAILISD::ACTIVELANEPERMUTE:
    return "HSAILISD::ACTIVELANEPERMUTE";
  case HSAILISD::ACTIVELANEID:
    return "HSAILISD::ACTIVELANEID";
  case HSAILISD::ACTIVELANECOUNT:
    return "HSAILISD::ACTIVELANECOUNT";
  case HSAILISD::ACTIVELANEMASK:
    return "HSAILISD::ACTIVELANEMASK";
  case HSAILISD::KERNARGBASEPTR:
    return "HSAILISD::KERNARGBASEPTR";
  case HSAILISD::SEGMENTP:
    return "HSAILISD::SEGMENTP";
  case HSAILISD::ARG_LD:
    return "HSAILISD::ARG_LD";
  case HSAILISD::ARG_ST:
    return "HSAILISD::ARG_ST";
  }
}

//===--------------------------------------------------------------------===//
// Custom lowering methods
//

SDValue HSAILTargetLowering::LowerADD(SDValue Op, SelectionDAG &DAG) const {
  SDLoc dl = SDLoc(Op);
  EVT VT = Op.getValueType();

  if (VT != MVT::i1) {
    return Op;
  }
  const SDValue src = Op.getOperand(0).getOperand(0);
  EVT srcVT = src.getValueType();
  if (Op.getOperand(0).getOpcode() != ISD::TRUNCATE)
    return Op;

  SDValue Zext = DAG.getNode(ISD::ZERO_EXTEND, dl, MVT::i32, Op.getOperand(1));
  SDValue Zext1 = DAG.getNode(ISD::ZERO_EXTEND, dl, srcVT, Op.getOperand(0));
  SDValue add_p = DAG.getNode(ISD::ADD, dl, srcVT, Zext1, Zext);
  SDValue Zext2 = DAG.getNode(ISD::TRUNCATE, dl, VT, add_p);
  return Zext2;
}

static bool isRdimage(unsigned IntNo) {
  switch (IntNo) {
  case HSAILIntrinsic::HSAIL_rd_imgf_1d_s32:
  case HSAILIntrinsic::HSAIL_rd_imgf_1d_f32:
  case HSAILIntrinsic::HSAIL_rd_imgi_1d_s32:
  case HSAILIntrinsic::HSAIL_rd_imgi_1d_f32:
  case HSAILIntrinsic::HSAIL_rd_imgui_1d_s32:
  case HSAILIntrinsic::HSAIL_rd_imgui_1d_f32:
  // read image 1d array
  case HSAILIntrinsic::HSAIL_rd_imgf_1da_s32:
  case HSAILIntrinsic::HSAIL_rd_imgf_1da_f32:
  case HSAILIntrinsic::HSAIL_rd_imgi_1da_s32:
  case HSAILIntrinsic::HSAIL_rd_imgi_1da_f32:
  case HSAILIntrinsic::HSAIL_rd_imgui_1da_s32:
  case HSAILIntrinsic::HSAIL_rd_imgui_1da_f32:
  // read image 2d
  case HSAILIntrinsic::HSAIL_rd_imgf_2d_s32:
  case HSAILIntrinsic::HSAIL_rd_imgf_2d_f32:
  case HSAILIntrinsic::HSAIL_rd_imgi_2d_s32:
  case HSAILIntrinsic::HSAIL_rd_imgi_2d_f32:
  case HSAILIntrinsic::HSAIL_rd_imgui_2d_s32:
  case HSAILIntrinsic::HSAIL_rd_imgui_2d_f32:
  // read image 2d array
  case HSAILIntrinsic::HSAIL_rd_imgf_2da_s32:
  case HSAILIntrinsic::HSAIL_rd_imgf_2da_f32:
  case HSAILIntrinsic::HSAIL_rd_imgi_2da_s32:
  case HSAILIntrinsic::HSAIL_rd_imgi_2da_f32:
  case HSAILIntrinsic::HSAIL_rd_imgui_2da_s32:
  case HSAILIntrinsic::HSAIL_rd_imgui_2da_f32:
  // read image 3d
  case HSAILIntrinsic::HSAIL_rd_imgf_3d_s32:
  case HSAILIntrinsic::HSAIL_rd_imgf_3d_f32:
  case HSAILIntrinsic::HSAIL_rd_imgi_3d_s32:
  case HSAILIntrinsic::HSAIL_rd_imgi_3d_f32:
  case HSAILIntrinsic::HSAIL_rd_imgui_3d_s32:
  case HSAILIntrinsic::HSAIL_rd_imgui_3d_f32:
  // read image 2d depth
  case HSAILIntrinsic::HSAIL_rd_imgf_2ddepth_s32:
  case HSAILIntrinsic::HSAIL_rd_imgf_2ddepth_f32:
  // read image 2d array depth
  case HSAILIntrinsic::HSAIL_rd_imgf_2dadepth_s32:
  case HSAILIntrinsic::HSAIL_rd_imgf_2dadepth_f32:
    return true;
  }

  return false;
}

SDValue HSAILTargetLowering::LowerLdKernargIntrinsic(SDValue Op,
                                                     SelectionDAG &DAG) const {
  MachineFunction &MF = DAG.getMachineFunction();
  HSAILMachineFunctionInfo *FuncInfo = MF.getInfo<HSAILMachineFunctionInfo>();
  HSAILParamManager &PM = FuncInfo->getParamManager();

  EVT VT = Op.getValueType();
  Type *Ty = Type::getIntNTy(*DAG.getContext(), VT.getSizeInBits());
  SDValue Addr = Op.getOperand(1);
  int64_t Offset = 0;
  MVT PtrTy = getPointerTy(HSAILAS::KERNARG_ADDRESS);
  AAMDNodes ArgMD; // FIXME: What is this for?
  if (ConstantSDNode *CAddr = dyn_cast<ConstantSDNode>(Addr)) {
    Offset = CAddr->getSExtValue();
    // Match a constant address argument to the parameter through functions's
    // argument map (taking argument alignment into account).
    // Match is not possible if we are accesing beyond a known kernel argument
    // space, if we accessing from a non-inlined function, or if there is an
    // opaque argument with unknwon size before requested offset.
    unsigned Param = UINT_MAX;
    if (HSAIL::isKernelFunc(MF.getFunction()))
      Param = PM.getParamByOffset(Offset);

    if (Param != UINT_MAX) {
      Addr = DAG.getTargetExternalSymbol(PM.getParamName(Param), PtrTy);
      // Value *mdops[] = { const_cast<Argument*>(PM.getParamArg(param)) };
      // ArgMD = MDNode::get(MF.getFunction()->getContext(), mdops);
    } else {
      Addr = SDValue();
    }
  }

  SDValue Chain = DAG.getEntryNode();
  return getArgLoad(DAG, SDLoc(Op), VT, Ty, false, HSAILAS::KERNARG_ADDRESS,
                    Chain, Addr, SDValue(), 0, false, Offset);
}

SDValue HSAILTargetLowering::LowerINTRINSIC_WO_CHAIN(SDValue Op,
                                                     SelectionDAG &DAG) const {
  unsigned IntrID = cast<ConstantSDNode>(Op->getOperand(0))->getZExtValue();
  SDLoc SL(Op);

  // FIXME: This is for compatability with old, custom HSAIL intrinsics. These
  // should be removed once users are updated to use the LLVM intrinsics.
  switch (IntrID) {
  case HSAILIntrinsic::HSAIL_get_global_id: {
    ConstantSDNode *Dim = dyn_cast<ConstantSDNode>(Op.getOperand(1));
    if (!Dim || Dim->getZExtValue() > 2)
      return DAG.getUNDEF(Op.getValueType());
    return Op;
  }

  case HSAILIntrinsic::HSAIL_abs_f32:
    return DAG.getNode(ISD::FABS, SL, MVT::f32, Op.getOperand(1));

  case HSAILIntrinsic::HSAIL_abs_f64:
    return DAG.getNode(ISD::FABS, SL, MVT::f64, Op.getOperand(1));

  case HSAILIntrinsic::HSAIL_rnd_f32:
    return DAG.getNode(ISD::FRINT, SL, MVT::f32, Op.getOperand(1));

  case HSAILIntrinsic::HSAIL_rnd_f64:
    return DAG.getNode(ISD::FRINT, SL, MVT::f64, Op.getOperand(1));

  case HSAILIntrinsic::HSAIL_floor_f32:
    return DAG.getNode(ISD::FFLOOR, SL, MVT::f32, Op.getOperand(1));

  case HSAILIntrinsic::HSAIL_floor_f64:
    return DAG.getNode(ISD::FFLOOR, SL, MVT::f64, Op.getOperand(1));

  case HSAILIntrinsic::HSAIL_ceil_f32:
    return DAG.getNode(ISD::FCEIL, SL, MVT::f32, Op.getOperand(1));

  case HSAILIntrinsic::HSAIL_ceil_f64:
    return DAG.getNode(ISD::FCEIL, SL, MVT::f64, Op.getOperand(1));

  case HSAILIntrinsic::HSAIL_trunc_f32:
    return DAG.getNode(ISD::FTRUNC, SL, MVT::f32, Op.getOperand(1));

  case HSAILIntrinsic::HSAIL_trunc_f64:
    return DAG.getNode(ISD::FTRUNC, SL, MVT::f64, Op.getOperand(1));

  case HSAILIntrinsic::HSAIL_fract_f32:
    return DAG.getNode(HSAILISD::FRACT, SL, MVT::f32, Op.getOperand(1));

  case HSAILIntrinsic::HSAIL_fract_f64:
    return DAG.getNode(HSAILISD::FRACT, SL, MVT::f64, Op.getOperand(1));

  case HSAILIntrinsic::HSAIL_copysign_f32:
    return DAG.getNode(ISD::FCOPYSIGN, SL, MVT::f32, Op.getOperand(1),
                       Op.getOperand(2));

  case HSAILIntrinsic::HSAIL_copysign_f64:
    return DAG.getNode(ISD::FCOPYSIGN, SL, MVT::f64, Op.getOperand(1),
                       Op.getOperand(2));

  case HSAILIntrinsic::HSAIL_min_f32:
    return DAG.getNode(ISD::FMINNUM, SL, MVT::f32, Op.getOperand(1),
                       Op.getOperand(2));

  case HSAILIntrinsic::HSAIL_min_f64:
    return DAG.getNode(ISD::FMINNUM, SL, MVT::f64, Op.getOperand(1),
                       Op.getOperand(2));

  case HSAILIntrinsic::HSAIL_max_f32:
    return DAG.getNode(ISD::FMAXNUM, SL, MVT::f32, Op.getOperand(1),
                       Op.getOperand(2));

  case HSAILIntrinsic::HSAIL_max_f64:
    return DAG.getNode(ISD::FMAXNUM, SL, MVT::f64, Op.getOperand(1),
                       Op.getOperand(2));

  case HSAILIntrinsic::HSAIL_fma_f32:
    return DAG.getNode(ISD::FMA, SL, MVT::f32, Op.getOperand(1),
                       Op.getOperand(2), Op.getOperand(3));

  case HSAILIntrinsic::HSAIL_fma_f64:
    return DAG.getNode(ISD::FMA, SL, MVT::f64, Op.getOperand(1),
                       Op.getOperand(2), Op.getOperand(3));

  case HSAILIntrinsic::HSAIL_popcount_u32_b32:
    return DAG.getNode(ISD::CTPOP, SL, MVT::i32, Op.getOperand(1));

  case HSAILIntrinsic::HSAIL_nfma_f32:
    return DAG.getNode(HSAILISD::NFMA, SL, MVT::f32, Op.getOperand(1),
                       Op.getOperand(2), Op.getOperand(3));

  case HSAILIntrinsic::HSAIL_nfma_f64:
    return DAG.getNode(HSAILISD::NFMA, SL, MVT::f64, Op.getOperand(1),
                       Op.getOperand(2), Op.getOperand(3));

  case HSAILIntrinsic::HSAIL_bitselect_u32:
    return DAG.getNode(HSAILISD::BITSELECT, SL, MVT::i32, Op.getOperand(1),
                       Op.getOperand(2), Op.getOperand(3));

  case HSAILIntrinsic::HSAIL_bitselect_u64:
    return DAG.getNode(HSAILISD::BITSELECT, SL, MVT::i64, Op.getOperand(1),
                       Op.getOperand(2), Op.getOperand(3));

  case HSAILIntrinsic::HSAIL_bfe:
    return DAG.getNode(HSAILISD::UBITEXTRACT, SL, MVT::i32, Op.getOperand(1),
                       Op.getOperand(2), Op.getOperand(3));

  case HSAILIntrinsic::HSAIL_ibfe:
    return DAG.getNode(HSAILISD::SBITEXTRACT, SL, MVT::i32, Op.getOperand(1),
                       Op.getOperand(2), Op.getOperand(3));

  // FIXME: There should be LLVM intrinsics for mulhs / mulhu.
  case HSAILIntrinsic::HSAIL_mulhi_s32:
    return DAG.getNode(ISD::MULHS, SL, MVT::i32, Op.getOperand(1),
                       Op.getOperand(2));

  case HSAILIntrinsic::HSAIL_mulhi_s64:
    return DAG.getNode(ISD::MULHS, SL, MVT::i64, Op.getOperand(1),
                       Op.getOperand(2));

  case HSAILIntrinsic::HSAIL_mulhi_u32:
    return DAG.getNode(ISD::MULHU, SL, MVT::i32, Op.getOperand(1),
                       Op.getOperand(2));

  case HSAILIntrinsic::HSAIL_mulhi_u64:
    return DAG.getNode(ISD::MULHU, SL, MVT::i64, Op.getOperand(1),
                       Op.getOperand(2));

  case HSAILIntrinsic::HSAIL_mad_u64:
    return DAG.getNode(HSAILISD::UMAD, SL, MVT::i64, Op.getOperand(1),
                       Op.getOperand(2), Op.getOperand(3));

  case HSAILIntrinsic::HSAIL_mad_u32:
    return DAG.getNode(HSAILISD::UMAD, SL, MVT::i32, Op.getOperand(1),
                       Op.getOperand(2), Op.getOperand(3));

  case HSAILIntrinsic::HSAIL_max_s32:
    return DAG.getNode(HSAILISD::SMAX, SL, MVT::i32, Op.getOperand(1),
                       Op.getOperand(2));

  case HSAILIntrinsic::HSAIL_max_u32:
    return DAG.getNode(HSAILISD::UMAX, SL, MVT::i32, Op.getOperand(1),
                       Op.getOperand(2));

  case HSAILIntrinsic::HSAIL_min_s32:
    return DAG.getNode(HSAILISD::SMIN, SL, MVT::i32, Op.getOperand(1),
                       Op.getOperand(2));

  case HSAILIntrinsic::HSAIL_min_u32:
    return DAG.getNode(HSAILISD::UMIN, SL, MVT::i32, Op.getOperand(1),
                       Op.getOperand(2));

  case HSAILIntrinsic::HSAIL_max_s64:
    return DAG.getNode(HSAILISD::SMAX, SL, MVT::i64, Op.getOperand(1),
                       Op.getOperand(2));

  case HSAILIntrinsic::HSAIL_max_u64:
    return DAG.getNode(HSAILISD::UMAX, SL, MVT::i64, Op.getOperand(1),
                       Op.getOperand(2));

  case HSAILIntrinsic::HSAIL_min_s64:
    return DAG.getNode(HSAILISD::SMIN, SL, MVT::i64, Op.getOperand(1),
                       Op.getOperand(2));

  case HSAILIntrinsic::HSAIL_min_u64:
    return DAG.getNode(HSAILISD::UMIN, SL, MVT::i64, Op.getOperand(1),
                       Op.getOperand(2));

  case HSAILIntrinsic::HSAIL_mul24_s32:
    return DAG.getNode(HSAILISD::SMUL24, SL, MVT::i32, Op.getOperand(1),
                       Op.getOperand(2));

  case HSAILIntrinsic::HSAIL_mul24_u32:
    return DAG.getNode(HSAILISD::UMUL24, SL, MVT::i32, Op.getOperand(1),
                       Op.getOperand(2));

  case HSAILIntrinsic::HSAIL_mad24_s32:
    return DAG.getNode(HSAILISD::SMAD24, SL, MVT::i32, Op.getOperand(1),
                       Op.getOperand(2), Op.getOperand(3));

  case HSAILIntrinsic::HSAIL_mad24_u32:
    return DAG.getNode(HSAILISD::UMAD24, SL, MVT::i32, Op.getOperand(1),
                       Op.getOperand(2), Op.getOperand(3));

  case HSAILIntrinsic::HSAIL_gcn_fldexp_f32:
    return DAG.getNode(HSAILISD::FLDEXP, SL, MVT::f32, Op.getOperand(1),
                       Op.getOperand(2));

  case HSAILIntrinsic::HSAIL_gcn_fldexp_f64:
    return DAG.getNode(HSAILISD::FLDEXP, SL, MVT::f64, Op.getOperand(1),
                       Op.getOperand(2));

  case HSAILIntrinsic::HSAIL_class_f32:
  case HSAILIntrinsic::HSAIL_class_f64: {
    // FIXME: The intrinsic should be i1 to begin with.
    SDValue Class = DAG.getNode(HSAILISD::CLASS, SL, MVT::i1, Op.getOperand(1),
                                Op.getOperand(2));
    return DAG.getNode(ISD::SIGN_EXTEND, SL, MVT::i32, Class);
  }

  case HSAILIntrinsic::HSAIL_segmentp_global: {
    return DAG.getNode(HSAILISD::SEGMENTP, SL, MVT::i1,
                       DAG.getTargetConstant(HSAILAS::GLOBAL_ADDRESS, MVT::i32),
                       DAG.getTargetConstant(0, MVT::i1), Op.getOperand(1));
  }
  case HSAILIntrinsic::HSAIL_segmentp_local: {
    return DAG.getNode(HSAILISD::SEGMENTP, SL, MVT::i1,
                       DAG.getTargetConstant(HSAILAS::GROUP_ADDRESS, MVT::i32),
                       DAG.getTargetConstant(0, MVT::i1), Op.getOperand(1));
  }
  case HSAILIntrinsic::HSAIL_segmentp_private: {
    return DAG.getNode(
        HSAILISD::SEGMENTP, SL, MVT::i1,
        DAG.getTargetConstant(HSAILAS::PRIVATE_ADDRESS, MVT::i32),
        DAG.getTargetConstant(0, MVT::i1), Op.getOperand(1));
  }
  case HSAILIntrinsic::HSAIL_ld_kernarg_u32:
  case HSAILIntrinsic::HSAIL_ld_kernarg_u64: {
    return LowerLdKernargIntrinsic(Op, DAG);
  }
  default:
    return Op;
  }
}

SDValue HSAILTargetLowering::LowerINTRINSIC_W_CHAIN(SDValue Op,
                                                    SelectionDAG &DAG) const {
  unsigned IntNo = cast<ConstantSDNode>(Op->getOperand(1))->getZExtValue();
  SDLoc SL(Op);

  if (isRdimage(IntNo))
    return lowerSamplerInitializerOperand(Op, DAG);

  switch (IntNo) {
  case HSAILIntrinsic::HSAIL_activelanepermute_b32: {
    SDVTList VTs = DAG.getVTList(MVT::i32, MVT::Other);

    const SDValue Ops[] = {
        Op.getOperand(0),                              // Chain
        DAG.getTargetConstant(BRIG_WIDTH_1, MVT::i32), // width
        Op.getOperand(2),                              // src0
        Op.getOperand(3),                              // src1
        Op.getOperand(4),                              // src2
        Op.getOperand(5)                               // src3
    };

    return DAG.getNode(HSAILISD::ACTIVELANEPERMUTE, SL, VTs, Ops);
  }

  case HSAILIntrinsic::HSAIL_activelanepermute_b64: {
    SDVTList VTs = DAG.getVTList(MVT::i64, MVT::Other);

    const SDValue Ops[] = {
        Op.getOperand(0),                              // Chain
        DAG.getTargetConstant(BRIG_WIDTH_1, MVT::i32), // width
        Op.getOperand(2),                              // src0
        Op.getOperand(3),                              // src1
        Op.getOperand(4),                              // src2
        Op.getOperand(5)                               // src3
    };

    return DAG.getNode(HSAILISD::ACTIVELANEPERMUTE, SL, VTs, Ops);
  }

  case HSAILIntrinsic::HSAIL_activelanepermute_width_b32: {
    SDVTList VTs = DAG.getVTList(MVT::i32, MVT::Other);

    const SDValue Ops[] = {
        Op.getOperand(0),                                     // Chain
        DAG.getTargetConstant(BRIG_WIDTH_WAVESIZE, MVT::i32), // width
        Op.getOperand(2),                                     // src0
        Op.getOperand(3),                                     // src1
        Op.getOperand(4),                                     // src2
        Op.getOperand(5)                                      // src3
    };

    return DAG.getNode(HSAILISD::ACTIVELANEPERMUTE, SL, VTs, Ops);
  }

  case HSAILIntrinsic::HSAIL_activelanepermute_width_b64: {
    SDVTList VTs = DAG.getVTList(MVT::i64, MVT::Other);

    const SDValue Ops[] = {
        Op.getOperand(0),                                     // Chain
        DAG.getTargetConstant(BRIG_WIDTH_WAVESIZE, MVT::i32), // width
        Op.getOperand(2),                                     // src0
        Op.getOperand(3),                                     // src1
        Op.getOperand(4),                                     // src2
        Op.getOperand(5)                                      // src3
    };

    return DAG.getNode(HSAILISD::ACTIVELANEPERMUTE, SL, VTs, Ops);
  }

  case HSAILIntrinsic::HSAIL_activelaneid_u32: {
    SDVTList VTs = DAG.getVTList(MVT::i32, MVT::Other);

    const SDValue Ops[] = {
        Op.getOperand(0),                             // Chain
        DAG.getTargetConstant(BRIG_WIDTH_1, MVT::i32) // width
    };

    return DAG.getNode(HSAILISD::ACTIVELANEID, SL, VTs, Ops);
  }

  case HSAILIntrinsic::HSAIL_activelaneid_width_u32: {
    SDVTList VTs = DAG.getVTList(MVT::i32, MVT::Other);

    const SDValue Ops[] = {
        Op.getOperand(0),                                    // Chain
        DAG.getTargetConstant(BRIG_WIDTH_WAVESIZE, MVT::i32) // width
    };

    return DAG.getNode(HSAILISD::ACTIVELANEID, SL, VTs, Ops);
  }

  case HSAILIntrinsic::HSAIL_activelanecount_u32_b1: {
    SDVTList VTs = DAG.getVTList(MVT::i32, MVT::Other);

    const SDValue Ops[] = {
        Op.getOperand(0),                              // Chain
        DAG.getTargetConstant(BRIG_WIDTH_1, MVT::i32), // width
        Op.getOperand(2)};

    return DAG.getNode(HSAILISD::ACTIVELANECOUNT, SL, VTs, Ops);
  }

  case HSAILIntrinsic::HSAIL_activelanecount_width_u32_b1: {
    SDVTList VTs = DAG.getVTList(MVT::i32, MVT::Other);

    const SDValue Ops[] = {
        Op.getOperand(0),                                     // Chain
        DAG.getTargetConstant(BRIG_WIDTH_WAVESIZE, MVT::i32), // width
        Op.getOperand(2)};

    return DAG.getNode(HSAILISD::ACTIVELANECOUNT, SL, VTs, Ops);
  }

  case HSAILIntrinsic::HSAIL_activelanemask_v4_b64_b1: {
    const SDValue Ops[] = {
        Op.getOperand(0),                              // Chain
        DAG.getTargetConstant(BRIG_WIDTH_1, MVT::i32), // width
        Op.getOperand(2)};

    return DAG.getNode(HSAILISD::ACTIVELANEMASK, SL, Op->getVTList(), Ops);
  }

  case HSAILIntrinsic::HSAIL_activelanemask_v4_width_b64_b1: {
    const SDValue Ops[] = {
        Op.getOperand(0),                                     // Chain
        DAG.getTargetConstant(BRIG_WIDTH_WAVESIZE, MVT::i32), // width
        Op.getOperand(2)};

    return DAG.getNode(HSAILISD::ACTIVELANEMASK, SL, Op->getVTList(), Ops);
  }

  default:
    return Op;
  }
}

/// \brief Replace sampler initializer with sampler handle from
///        readonly segment, potentially creating a new handle.
SDValue
HSAILTargetLowering::lowerSamplerInitializerOperand(SDValue Op,
                                                    SelectionDAG &DAG) const {
  const unsigned SAMPLER_ARG = 3;
  SDValue sampler = Op.getOperand(SAMPLER_ARG);

  // The sampler operand is an initializer if it is constant and less than
  // IMAGE_ARG_BIAS.
  if (!isa<ConstantSDNode>(sampler))
    return Op;

  unsigned samplerConstant = cast<ConstantSDNode>(sampler)->getZExtValue();
  if (samplerConstant >= IMAGE_ARG_BIAS)
    return Op;

  // This is a sampler initializer.
  // Find or create sampler handle based on init val.
  unsigned samplerHandleIndex =
      Subtarget->getImageHandles()->findOrCreateSamplerHandle(samplerConstant);

  // Provided that this is simply int const we can assume it is not going to be
  // changed, so we use readonly segment for the sampler.
  // According to OpenCL spec samplers cannot be modified, so that is safe for
  // OpenCL. If we are going to support modifiable or non-OpenCL samplers most
  // likely the whole support code will need change.
  Subtarget->getImageHandles()->getSamplerHandle(samplerHandleIndex)->setRO();

  SDValue ops[16];
  for (unsigned i = 0; i < Op.getNumOperands(); i++) {
    ops[i] = Op.getOperand(i);
  }

  // FIXME: Get correct address space pointer type.
  SDValue Ops[] = {
      DAG.getTargetConstant(samplerHandleIndex, MVT::i32),
      DAG.getRegister(HSAIL::NoRegister, getPointerTy()),
      DAG.getTargetConstant(0, MVT::i32),
      DAG.getTargetConstant(BRIG_TYPE_SAMP, MVT::i32),
      DAG.getTargetConstant(BRIG_WIDTH_ALL, MVT::i32),
      DAG.getTargetConstant(1, MVT::i1), // Const
      DAG.getEntryNode()                 // Chain
  };
  EVT VT = sampler.getValueType();

  // Don't use ptr32 since this is the readonly segment.
  MachineSDNode *LDSamp =
      DAG.getMachineNode(HSAIL::LD_SAMP, SDLoc(Op), VT, MVT::Other, Ops);

  MachineFunction &MF = DAG.getMachineFunction();
  MachineSDNode::mmo_iterator MemOp = MF.allocateMemRefsArray(1);
  unsigned size = VT.getStoreSize();
  Type *PTy = VT.getTypeForEVT(*DAG.getContext());
  PointerType *PT = PointerType::get(PTy, HSAILAS::READONLY_ADDRESS);
  MachinePointerInfo MPtrInfo(UndefValue::get(PT), size * samplerHandleIndex);
  MemOp[0] =
      MF.getMachineMemOperand(MPtrInfo, MachineMemOperand::MOLoad, size, size);
  LDSamp->setMemRefs(MemOp, MemOp + 1);

  ops[SAMPLER_ARG] = SDValue(LDSamp, 0);

  DAG.UpdateNodeOperands(Op.getNode(), makeArrayRef(ops, Op.getNumOperands()));

  return Op;
}

SDValue HSAILTargetLowering::LowerROTL(SDValue Op, SelectionDAG &DAG) const {
  SDLoc dl = SDLoc(Op);
  EVT VT = Op.getValueType();

  if (VT != MVT::i32) {
    return Op;
  }
  const SDValue src0 = Op.getOperand(0);
  const SDValue src1 = Op.getOperand(1);
  const ConstantSDNode *shift = dyn_cast<ConstantSDNode>(src1);
  return DAG.getNode(
      ISD::INTRINSIC_WO_CHAIN, dl, VT,
      DAG.getConstant(HSAILIntrinsic::HSAIL_bitalign_b32, MVT::i32), src0, src0,
      shift ? DAG.getConstant(32 - (shift->getZExtValue() & 31), MVT::i32)
            : DAG.getNode(ISD::SUB, dl, VT, DAG.getConstant(0, VT), src1));
}

SDValue HSAILTargetLowering::LowerROTR(SDValue Op, SelectionDAG &DAG) const {
  SDLoc dl = SDLoc(Op);
  EVT VT = Op.getValueType();

  if (VT != MVT::i32) {
    return Op;
  }
  const SDValue src0 = Op.getOperand(0);
  const SDValue src1 = Op.getOperand(1);
  return DAG.getNode(
      ISD::INTRINSIC_WO_CHAIN, dl, VT,
      DAG.getConstant(HSAILIntrinsic::HSAIL_bitalign_b32, MVT::i32), src0, src0,
      src1);
}

SDValue HSAILTargetLowering::LowerBSWAP(SDValue Op, SelectionDAG &DAG) const {
  SDLoc dl = SDLoc(Op);
  EVT VT = Op.getValueType();

  if (VT != MVT::i32) {
    return Op;
  }
  const SDValue src = Op.getOperand(0);
  const SDValue opr0 = DAG.getNode(
      ISD::INTRINSIC_WO_CHAIN, dl, VT,
      DAG.getConstant(HSAILIntrinsic::HSAIL_bytealign_b32, MVT::i32), src, src,
      DAG.getConstant(3, MVT::i32));
  const SDValue opr1 = DAG.getNode(
      ISD::INTRINSIC_WO_CHAIN, dl, VT,
      DAG.getConstant(HSAILIntrinsic::HSAIL_bytealign_b32, MVT::i32), src, src,
      DAG.getConstant(1, MVT::i32));
  return DAG.getNode(
      ISD::INTRINSIC_WO_CHAIN, dl, VT,
      DAG.getConstant(HSAILIntrinsic::HSAIL_bitselect_u32, MVT::i32),
      DAG.getConstant(0x00ff00ff, VT), opr0, opr1);
}

SDValue HSAILTargetLowering::LowerLOAD(SDValue Op, SelectionDAG &DAG) const {
  SDLoc dl(Op);

  EVT VT = Op.getValueType();
  LoadSDNode *LD = cast<LoadSDNode>(Op);

  if (VT.getSimpleVT() == MVT::i1) {
    // Since there are no 1 bit load operations, the load operations are
    // converted to 8 bit loads.
    // First, do 8 bit load into 32 bits with sign extension, then
    // truncate to 1 bit.
    LoadSDNode *LD = cast<LoadSDNode>(Op);
    SDValue NewLD =
        DAG.getExtLoad(ISD::ZEXTLOAD, dl, MVT::i32, LD->getChain(),
                       LD->getBasePtr(), MVT::i8, LD->getMemOperand());

    SDValue Result = DAG.getNode(ISD::TRUNCATE, dl, MVT::i1, NewLD);
    SDValue Ops[] = {Result, NewLD.getValue(1)};

    return DAG.getMergeValues(Ops, dl);
  }

  // Custom lowering for extload from sub-dword size to i64. We only
  // do it because LLVM currently does not support Expand for EXTLOAD
  // with illegal types.
  // See "EXTLOAD should always be supported!" assert in LegalizeDAG.cpp.
  if (VT.getSimpleVT() != MVT::i64)
    return Op;
  ISD::LoadExtType extType = LD->getExtensionType();

  if (extType == ISD::SEXTLOAD && LD->hasNUsesOfValue(1, 0)) {
    // Check if the only use is a truncation to the size of loaded memory.
    // In this case produce zext instead of sext. Note, that load chain
    // has its own use.
    SDNode::use_iterator UI = LD->use_begin(), UE = LD->use_end();
    for (; UI != UE; ++UI) {
      if (UI.getUse().getResNo() == 0) {
        // User of a loaded value.
        if (UI->getOpcode() == ISD::AND &&
            isa<ConstantSDNode>(UI->getOperand(1))) {
          EVT MemVT = LD->getMemoryVT();
          uint64_t Mask = UI->getConstantOperandVal(1);
          if ((MemVT == MVT::i8 && Mask == 0xFFul) ||
              (MemVT == MVT::i16 && Mask == 0xFFFFul)) {
            // The AND operator was not really needed. Produce zextload as it
            // does
            // not change the result and let AND node silintly die.
            extType = ISD::ZEXTLOAD;
          }
        }
        break;
      }
    }
  }

  // Do extload into 32-bit register, then extend that.
  SDValue NewLD =
      DAG.getExtLoad(extType, dl, MVT::i32, LD->getChain(), LD->getBasePtr(),
                     MVT::i8, LD->getMemOperand());

  SDValue Ops[] = {
    DAG.getNode(ISD::getExtForLoadExtType(false, extType), dl, MVT::i64, NewLD),
    NewLD.getValue(1)};

  // Replace chain in all uses.
  // XXX: Do we really need to do this?
  DAG.ReplaceAllUsesOfValueWith(Op.getValue(1), NewLD.getValue(1));

  return DAG.getMergeValues(Ops, dl);
}

SDValue HSAILTargetLowering::LowerSTORE(SDValue Op, SelectionDAG &DAG) const {
  // Since there are no 1 bit store operations, the store operations are
  // converted to 8 bit stores.
  // First, sign extend to 32 bits, then use a truncating store to 8 bits.

  SDLoc dl = SDLoc(Op);
  StoreSDNode *ST = cast<StoreSDNode>(Op);

  SDValue Chain = ST->getChain();
  SDValue BasePtr = ST->getBasePtr();
  SDValue Value = ST->getValue();
  MachineMemOperand *MMO = ST->getMemOperand();

  assert(Value.getValueType() == MVT::i1 &&
         "Custom lowering only for i1 stores");

  Value = DAG.getNode(ISD::SIGN_EXTEND, dl, MVT::i32, Value);
  return DAG.getTruncStore(Chain, dl, Value, BasePtr, MVT::i8, MMO);
}

static SDValue getMemFenceImpl(SDValue Chain, SDLoc SL, unsigned MemoryOrder,
                               unsigned GlobalMemoryScope,
                               unsigned GroupMemoryScope,
                               unsigned ImageMemoryScope,
                               SelectionDAG &CurDAG) {
  const SDValue Ops[] = {
      Chain, CurDAG.getTargetConstant(HSAILIntrinsic::HSAIL_memfence, MVT::i64),
      CurDAG.getConstant(MemoryOrder, MVT::i32),
      CurDAG.getConstant(GlobalMemoryScope, MVT::i32),
      CurDAG.getConstant(GroupMemoryScope, MVT::i32),
      CurDAG.getConstant(ImageMemoryScope, MVT::i32)};

  return CurDAG.getNode(ISD::INTRINSIC_VOID, SL, MVT::Other, Ops);
}

static SDValue getMemFence(SDValue Chain, SDLoc SL, unsigned AS,
                           unsigned MemoryOrder, unsigned MemoryScope,
                           SelectionDAG &CurDAG) {
  switch (AS) {
  case HSAILAS::GLOBAL_ADDRESS:
    return getMemFenceImpl(Chain, SL, MemoryOrder, MemoryScope,
                           BRIG_MEMORY_SCOPE_NONE, BRIG_MEMORY_SCOPE_NONE,
                           CurDAG);

  case HSAILAS::GROUP_ADDRESS:
    return getMemFenceImpl(Chain, SL, MemoryOrder, MemoryScope, MemoryScope,
                           BRIG_MEMORY_SCOPE_NONE, CurDAG);

  case HSAILAS::FLAT_ADDRESS:
    return getMemFenceImpl(Chain, SL, MemoryOrder, MemoryScope,
                           BRIG_MEMORY_SCOPE_WORKGROUP, BRIG_MEMORY_SCOPE_NONE,
                           CurDAG);

  default:
    llvm_unreachable("unexpected memory segment");
  }
}

SDValue HSAILTargetLowering::LowerATOMIC_LOAD(SDValue Op,
                                              SelectionDAG &DAG) const {
  // HSAIL doesnt support SequentiallyConsistent,
  // lower an atomic load with SequentiallyConsistent memory order
  // to a Release memfence and Acquire atomic load
  AtomicSDNode *Node = cast<AtomicSDNode>(Op);

  if (Node->getOrdering() != SequentiallyConsistent)
    return Op;

  unsigned brigMemoryOrder = BRIG_MEMORY_ORDER_SC_RELEASE;
  unsigned brigMemoryScope = Node->getAddressSpace() == HSAILAS::GROUP_ADDRESS
                                 ? BRIG_MEMORY_SCOPE_WORKGROUP
                                 : BRIG_MEMORY_SCOPE_SYSTEM;

  SDLoc SL(Op);

  SDValue Chain = getMemFence(Op.getOperand(0), Op, Node->getAddressSpace(),
                              brigMemoryOrder, brigMemoryScope, DAG);

  return DAG.getAtomic(ISD::ATOMIC_LOAD, SL, Node->getMemoryVT(),
                       Op.getValueType(), Chain, Node->getBasePtr(),
                       Node->getMemOperand(), Acquire, Node->getSynchScope());
}

SDValue HSAILTargetLowering::LowerATOMIC_STORE(SDValue Op,
                                               SelectionDAG &DAG) const {
  // HSAIL doesnt support SequentiallyConsistent,
  // lower an atomic store with SequentiallyConsistent memory order
  // to Release atomic store and Acquire memfence
  AtomicSDNode *Node = cast<AtomicSDNode>(Op);

  if (Node->getOrdering() != SequentiallyConsistent)
    return Op;

  unsigned MemoryOrder = BRIG_MEMORY_ORDER_SC_ACQUIRE;
  unsigned MemoryScope = Node->getAddressSpace() == HSAILAS::GROUP_ADDRESS
                             ? BRIG_MEMORY_SCOPE_WORKGROUP
                             : BRIG_MEMORY_SCOPE_SYSTEM;

  SDLoc SL(Op);

  SDValue ResNode =
      DAG.getAtomic(ISD::ATOMIC_STORE, SL, Node->getMemoryVT(),
                    Node->getOperand(0), // Chain
                    Node->getBasePtr(), Node->getVal(), Node->getMemOperand(),
                    Release, Node->getSynchScope());
  return getMemFence(ResNode, Op, Node->getAddressSpace(), MemoryOrder,
                     MemoryScope, DAG);
}

//===--------------------------------------------------------------------===//
bool HSAILTargetLowering::isLegalAddressingMode(const AddrMode &AM,
                                                Type *Ty) const {
  if (Subtarget->isGCN()) {
    // Do not generate negative offsets as they can not be folded into
    // instructions.
    if (AM.BaseOffs < 0 || AM.Scale < 0)
      return false;
  }

  return TargetLowering::isLegalAddressingMode(AM, Ty);
}

bool HSAILTargetLowering::isZExtFree(Type *Ty1, Type *Ty2) const {
  return false;
}

bool HSAILTargetLowering::isZExtFree(EVT VT1, EVT VT2) const { return false; }

bool HSAILTargetLowering::isFAbsFree(EVT VT) const { return true; }

bool HSAILTargetLowering::isFNegFree(EVT VT) const { return true; }

bool HSAILTargetLowering::isNarrowingProfitable(EVT VT1, EVT VT2) const {
  // This is only profitable in HSAIL to go from a 64bit type to
  // a 32bit type, but not to a 8 or 16bit type.
  return (VT1 == EVT(MVT::i64) && VT2 == EVT(MVT::i32)) ||
         (VT1 == EVT(MVT::f64) && VT2 == EVT(MVT::f32));
}

bool HSAILTargetLowering::isLegalICmpImmediate(int64_t Imm) const {
  // HSAIL doesn't have any restrictions on this.
  return true;
}

MVT HSAILTargetLowering::getScalarShiftAmountTy(EVT LHSTy) const {
  // Shift amounts in registers must be in S registers
  // Restrict shift amount to 32-bits.
  return MVT::i32;
}

bool HSAILTargetLowering::isNoopAddrSpaceCast(unsigned SrcAS,
                                              unsigned DestAS) const {
  return (SrcAS == HSAILAS::FLAT_ADDRESS &&
          DestAS == HSAILAS::GLOBAL_ADDRESS) ||
         (SrcAS == HSAILAS::GLOBAL_ADDRESS && DestAS == HSAILAS::FLAT_ADDRESS);
}

void HSAILTargetLowering::AdjustInstrPostInstrSelection(MachineInstr *MI,
                                                        SDNode *Node) const {
  const HSAILInstrInfo *TII =
      static_cast<const HSAILInstrInfo *>(Subtarget->getInstrInfo());

  if (TII->isInstAtomic(MI->getOpcode()) && !Node->hasAnyUseOfValue(0)) {
    int NoRetAtomicOp = HSAIL::getAtomicNoRetOp(MI->getOpcode());
    if (NoRetAtomicOp != -1) {
      MI->setDesc(TII->get(NoRetAtomicOp));
      MI->RemoveOperand(0);
    }

    return;
  }
}

bool HSAILTargetLowering::isLoadBitCastBeneficial(EVT lVT, EVT bVT) const {
  return !(lVT.getSizeInBits() == bVT.getSizeInBits() &&
           lVT.getScalarType().getSizeInBits() >
               bVT.getScalarType().getSizeInBits() &&
           bVT.getScalarType().getSizeInBits() < 32 &&
           lVT.getScalarType().getSizeInBits() >= 32);
}

bool HSAILTargetLowering::isVectorToScalarLoadStoreWidenBeneficial(
    unsigned Width, EVT WidenVT, const MemSDNode *N) const {
  unsigned WidenWidth = WidenVT.getSizeInBits();

  // In HSAIL we have _v3 loads and stores, and in case of uneven vector size
  // it is more effective to use one _v3 load instead of several _v1 loads
  // For example for vector load of 3 integers:
  //   ld_v1_u64
  //   ld_v1_u32
  // Is worse than:
  //   ld_v3_u32
  if ((Width * 4 / 3) == WidenWidth)
    return false;
  return true;
}
