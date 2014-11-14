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
#include "HSAILBrig.h"
#include "HSAILInstrInfo.h"
#include "HSAILELFTargetObjectFile.h"
#include "HSAILISelLowering.h"
#include "HSAILMachineFunctionInfo.h"
#include "HSAILSubtarget.h"
#include "HSAILTargetMachine.h"
#include "HSAILUtilityFunctions.h"
#include "HSAILOpaqueTypes.h"
#include "llvm/IR/CallingConv.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Mangler.h"
#include "llvm/IR/MDBuilder.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/CodeGen/IntrinsicLowering.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineJumpTableInfo.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/PseudoSourceValue.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Target/TargetLowering.h"
#include "llvm/Target/TargetOptions.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/Dwarf.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/CommandLine.h"
#include <sstream>
#include "HSAILGenInstrInfo.inc"

using namespace llvm;
using namespace dwarf;

namespace llvm {
  extern bool EnableExperimentalFeatures;
  extern enum OptimizeForTargetArch OptimizeFor;
}

static cl::opt<bool>
Flag_ampPtrFtos("mamp_ptr_ftos",
            cl::desc("Convert AMP incoming pointers to segment address"),
            cl::init(false));

static TargetLoweringObjectFile *createTLOF(HSAILTargetMachine &TM) {
  const HSAILSubtarget *Subtarget = &TM.getSubtarget<HSAILSubtarget>();
  bool is64Bit = Subtarget->is64Bit();

  if (is64Bit)
    return new HSAIL64_DwarfTargetObjectFile(TM);
  return new HSAIL32_DwarfTargetObjectFile(TM);
}


HSAILTargetLowering::HSAILTargetLowering(HSAILTargetMachine &TM)
  : TargetLowering(TM, createTLOF(TM))
{
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
  addRegisterClass(MVT::i1,  &HSAIL::CRRegClass);

  setOperationAction(ISD::BSWAP, MVT::i16, Expand);
  setOperationAction(ISD::BSWAP, MVT::i32, Custom);
  setOperationAction(ISD::BSWAP, MVT::i64, Expand);
  setOperationAction(ISD::ADD, MVT::i1, Custom);
  setOperationAction(ISD::ROTL, MVT::i1, Expand);
  setOperationAction(ISD::ROTL, MVT::i8, Expand);
  setOperationAction(ISD::ROTL, MVT::i16, Expand);
  setOperationAction(ISD::ROTL, MVT::i32, Custom);
  setOperationAction(ISD::ROTL, MVT::i64, Expand);
  setOperationAction(ISD::ROTR, MVT::i1, Expand);
  setOperationAction(ISD::ROTR, MVT::i8, Expand);
  setOperationAction(ISD::ROTR, MVT::i16, Expand);
  setOperationAction(ISD::ROTR, MVT::i32, Custom);
  setOperationAction(ISD::ROTR, MVT::i64, Expand);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::Other, Expand);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i1, Expand);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i8, Expand);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i16, Expand);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i32, Expand);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i64, Expand);

  setOperationAction(ISD::TRUNCATE, MVT::i1, Custom);

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

  setOperationAction(ISD::GlobalAddress, MVT::i32, Custom);
  setOperationAction(ISD::GlobalAddress, MVT::i64, Custom);

  setOperationAction(ISD::ConstantFP, MVT::f64, Legal);
  setOperationAction(ISD::ConstantFP, MVT::f32, Legal);
  setOperationAction(ISD::Constant, MVT::i32, Legal);
  setOperationAction(ISD::Constant, MVT::i64, Legal);

  setOperationAction(ISD::INTRINSIC_W_CHAIN, MVT::Other, Custom);

  setLoadExtAction(ISD::EXTLOAD, MVT::f32, Expand);
  setLoadExtAction(ISD::EXTLOAD, MVT::v2f32, Expand);
  setLoadExtAction(ISD::EXTLOAD, MVT::v4f32, Expand);
  setLoadExtAction(ISD::EXTLOAD, MVT::v8f32, Expand);

  setLoadExtAction(ISD::EXTLOAD, MVT::i32, Expand);
  setLoadExtAction(ISD::EXTLOAD, MVT::v1i32, Expand);
  setLoadExtAction(ISD::EXTLOAD, MVT::v2i32, Expand);
  setLoadExtAction(ISD::EXTLOAD, MVT::v4i32, Expand);
  setLoadExtAction(ISD::EXTLOAD, MVT::v8i32, Expand);
  setLoadExtAction(ISD::EXTLOAD, MVT::v16i32, Expand);

  setLoadExtAction(ISD::EXTLOAD, MVT::i16, Custom);
  setLoadExtAction(ISD::EXTLOAD, MVT::v1i16, Expand);
  setLoadExtAction(ISD::EXTLOAD, MVT::v2i16, Expand);
  setLoadExtAction(ISD::EXTLOAD, MVT::v4i16, Expand);
  setLoadExtAction(ISD::EXTLOAD, MVT::v8i16, Expand);
  setLoadExtAction(ISD::EXTLOAD, MVT::v16i16, Expand);

  setLoadExtAction(ISD::EXTLOAD, MVT::i1, Promote);
  setLoadExtAction(ISD::EXTLOAD, MVT::i8, Custom);
  setLoadExtAction(ISD::EXTLOAD, MVT::v2i8, Expand);
  setLoadExtAction(ISD::EXTLOAD, MVT::v4i8, Expand);
  setLoadExtAction(ISD::EXTLOAD, MVT::v8i8, Expand);
  setLoadExtAction(ISD::EXTLOAD, MVT::v16i8, Expand);

  setLoadExtAction(ISD::ZEXTLOAD, MVT::i16, Custom);
  setLoadExtAction(ISD::ZEXTLOAD, MVT::v1i16, Expand);
  setLoadExtAction(ISD::ZEXTLOAD, MVT::v2i16, Expand);
  setLoadExtAction(ISD::ZEXTLOAD, MVT::v4i16, Expand);
  setLoadExtAction(ISD::ZEXTLOAD, MVT::v8i16, Expand);
  setLoadExtAction(ISD::ZEXTLOAD, MVT::v16i16, Expand);

  setLoadExtAction(ISD::ZEXTLOAD, MVT::i1, Promote);
  setLoadExtAction(ISD::ZEXTLOAD, MVT::i8, Custom);
  setLoadExtAction(ISD::ZEXTLOAD, MVT::v2i8, Expand);
  setLoadExtAction(ISD::ZEXTLOAD, MVT::v4i8, Expand);
  setLoadExtAction(ISD::ZEXTLOAD, MVT::v8i8, Expand);
  setLoadExtAction(ISD::ZEXTLOAD, MVT::v16i8, Expand);

  setLoadExtAction(ISD::ZEXTLOAD, MVT::i32, Expand);
  setLoadExtAction(ISD::ZEXTLOAD, MVT::v1i32, Expand);
  setLoadExtAction(ISD::ZEXTLOAD, MVT::v2i32, Expand);
  setLoadExtAction(ISD::ZEXTLOAD, MVT::v4i32, Expand);
  setLoadExtAction(ISD::ZEXTLOAD, MVT::v8i32, Expand);
  setLoadExtAction(ISD::ZEXTLOAD, MVT::v16i32, Expand);

  setLoadExtAction(ISD::SEXTLOAD, MVT::i32, Expand);
  setLoadExtAction(ISD::SEXTLOAD, MVT::v1i32, Expand);
  setLoadExtAction(ISD::SEXTLOAD, MVT::v2i32, Expand);
  setLoadExtAction(ISD::SEXTLOAD, MVT::v4i32, Expand);
  setLoadExtAction(ISD::SEXTLOAD, MVT::v8i32, Expand);
  setLoadExtAction(ISD::SEXTLOAD, MVT::v16i32, Expand);

  setLoadExtAction(ISD::SEXTLOAD, MVT::i16, Custom);
  setLoadExtAction(ISD::SEXTLOAD, MVT::v1i16, Expand);
  setLoadExtAction(ISD::SEXTLOAD, MVT::v2i16, Expand);
  setLoadExtAction(ISD::SEXTLOAD, MVT::v4i16, Expand);
  setLoadExtAction(ISD::SEXTLOAD, MVT::v8i16, Expand);
  setLoadExtAction(ISD::SEXTLOAD, MVT::v16i16, Expand);

  setLoadExtAction(ISD::SEXTLOAD, MVT::i1, Promote);
  setLoadExtAction(ISD::SEXTLOAD, MVT::i8, Custom);
  setLoadExtAction(ISD::SEXTLOAD, MVT::v2i8, Expand);
  setLoadExtAction(ISD::SEXTLOAD, MVT::v4i8, Expand);
  setLoadExtAction(ISD::SEXTLOAD, MVT::v8i8, Expand);
  setLoadExtAction(ISD::SEXTLOAD, MVT::v16i8, Expand);

  setTruncStoreAction(MVT::f64, MVT::f32, Expand);
  setTruncStoreAction(MVT::v2f64, MVT::v2f32, Expand);
  setTruncStoreAction(MVT::v4f64, MVT::v4f32, Expand);
  setTruncStoreAction(MVT::i64, MVT::i32, Expand);
  setTruncStoreAction(MVT::i64, MVT::v1i32, Expand);
  setTruncStoreAction(MVT::i64, MVT::v2i32, Expand);
  setTruncStoreAction(MVT::i64, MVT::v4i32, Expand);
  setTruncStoreAction(MVT::i64, MVT::v8i32, Expand);
  setTruncStoreAction(MVT::i64, MVT::v16i32, Expand);
  setTruncStoreAction(MVT::i64, MVT::i16, Expand);
  setTruncStoreAction(MVT::i64, MVT::v1i16, Expand);
  setTruncStoreAction(MVT::i64, MVT::v2i16, Expand);
  setTruncStoreAction(MVT::i64, MVT::v4i16, Expand);
  setTruncStoreAction(MVT::i64, MVT::v8i16, Expand);
  setTruncStoreAction(MVT::i64, MVT::v16i16, Expand);
  setTruncStoreAction(MVT::i64, MVT::i8, Expand);
  setTruncStoreAction(MVT::i64, MVT::v2i8, Expand);
  setTruncStoreAction(MVT::i64, MVT::v4i8, Expand);
  setTruncStoreAction(MVT::i64, MVT::v8i8, Expand);
  setTruncStoreAction(MVT::i64, MVT::v16i8, Expand);

  setOperationAction(ISD::STORE, MVT::i1, Custom);
  setOperationAction(ISD::LOAD,  MVT::i1, Custom);

  setTargetDAGCombine(ISD::INTRINSIC_WO_CHAIN);

  setJumpIsExpensive(true);
  setSelectIsExpensive(true);
  setPow2SDivIsCheap(false);
  setPrefLoopAlignment(0);
  setSchedulingPreference((CodeGenOpt::None == TM.getOptLevel()) ?
    Sched::Source : Sched::ILP);
#ifdef _DEBUG
  const char* pScheduler = std::getenv("AMD_DEBUG_HSAIL_PRE_RA_SCHEDULER");
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
  MaxStoresPerMemcpy  = 4096;
  MaxStoresPerMemmove = 4096;
  MaxStoresPerMemset  = 4096;
}

HSAILTargetLowering::~HSAILTargetLowering() {}

/// getSetCCResultType - Return the ValueType of the result of SETCC
/// operations.  Also used to obtain the target's preferred type for
/// the condition operand of SELECT and BRCOND nodes.  In the case of
/// BRCOND the argument passed is MVT::Other since there are no other
/// operands to get a type hint from.
EVT
HSAILTargetLowering::getSetCCResultType(LLVMContext &Context, EVT VT) const
{
  return MVT::i1;
}

/// getSchedulingPreference - Some scheduler, e.g. hybrid, can switch to
/// different scheduling heuristics for different nodes. This function returns
/// the preference (or none) for the given node.
Sched::Preference
HSAILTargetLowering::getSchedulingPreference(SDNode *N) const
{
  return TargetLowering::getSchedulingPreference(N);
}
/// getRepRegClassFor - Return the 'representative' register class for the
/// specified value type. The 'representative' register class is the largest
/// legal super-reg register class for the register class of the value type.
/// For example, on i386 the rep register class for i8, i16, and i32 are GR32;
/// while the rep register class is GR64 on x86_64.
const TargetRegisterClass*
HSAILTargetLowering::getRepRegClassFor(MVT VT) const
{
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
  return NULL;
}

/// getRepRegClassCostFor - Return the cost of the 'representative' register
/// class for the specified value type.
uint8_t HSAILTargetLowering::getRepRegClassCostFor(MVT VT) const {
  // Micah: Is this true that the reg class cost for everything is 1 in HSAIL?
  return 1;
}

/// getTgtMemIntrinsic: Given an intrinsic, checks if on the target the
/// intrinsic will need to map to a MemIntrinsicNode (touches memory). If
/// this is the case, it returns true and store the intrinsic
/// information into the IntrinsicInfo that was passed to the function.
bool
HSAILTargetLowering::getTgtMemIntrinsic(IntrinsicInfo &Info,
                                        const CallInst &I,
                                        unsigned Intrinsic) const
{
  return false;
}

/// isFPImmLegal - Returns true if the target can instruction select the
/// specified FP immediate natively. If false, the legalizer will materialize
/// the FP immediate as a load from a constant pool.
bool
HSAILTargetLowering::isFPImmLegal(const APFloat &Imm,
                                  EVT VT) const
{
  // All floating point types are legal for 32bit and 64bit types.
  return (VT == EVT(MVT::f32) || VT == EVT(MVT::f64));
}

/// getByValTypeAlignment - Return the desired alignment for ByVal aggregate
/// function arguments in the caller parameter area.  This is the actual
/// alignment, not its logarithm.
unsigned
HSAILTargetLowering::getByValTypeAlignment(Type *Ty) const
{
  return TargetLowering::getByValTypeAlignment(Ty);
}

/// This function returns true if the target allows unaligned memory accesses.
/// of the specified type. This is used, for example, in situations where an
/// array copy/move/set is  converted to a sequence of store operations. It's
/// use helps to ensure that such replacements don't generate code that causes
/// an alignment error  (trap) on the target machine.
/// @brief Determine if the target supports unaligned memory accesses.
bool
HSAILTargetLowering::allowsUnalignedMemoryAccesses(EVT VT) const
{
  return true;
}

/// getJumpTableEncoding - Return the entry encoding for a jump table in the
/// current function.  The returned value is a member of the
/// MachineJumpTableInfo::JTEntryKind enum.
unsigned
HSAILTargetLowering::getJumpTableEncoding() const
{
    return MachineJumpTableInfo::EK_BlockAddress;
}

/// isOffsetFoldingLegal - Return true if folding a constant offset
/// with the given GlobalAddress is legal.  It is frequently not legal in
/// PIC relocation models.
bool
HSAILTargetLowering::isOffsetFoldingLegal(const GlobalAddressSDNode *GA) const
{
  // Micah: Since HSAIL does not support PIC now, we can always set this to true.
  return true;
}

/// getFunctionAlignment - Return the Log2 alignment of this function.
unsigned
HSAILTargetLowering::getFunctionAlignment(const Function *) const
{
  return 0;
}

/// ComputeNumSignBitsForTargetNode - This method can be implemented by
/// targets that want to expose additional information about sign bits to the
/// DAG Combiner.
unsigned HSAILTargetLowering::ComputeNumSignBitsForTargetNode(
  SDValue Op,
  const SelectionDAG &DAG,
  unsigned Depth) const {
  return 1;
}

/// isGAPlusOffset - Returns true (and the GlobalValue and the offset) if the
/// node is a GlobalAddress + offset.
bool
HSAILTargetLowering::isGAPlusOffset(SDNode *N,
                                    const GlobalValue* &GA,
                                    int64_t &Offset) const
{
  bool res = TargetLowering::isGAPlusOffset(N, GA, Offset);
  return res;
}

static SDValue
PerformBitalignCombine(SDNode *N, TargetLowering::DAGCombinerInfo &DCI, unsigned IID)
{
  assert(IID == HSAILIntrinsic::HSAIL_bitalign_b32 ||
         IID == HSAILIntrinsic::HSAIL_bytealign_b32);
  SDValue Opr0 = N->getOperand(1);
  SDValue Opr1 = N->getOperand(2);
  SDValue Opr2 = N->getOperand(3);
  ConstantSDNode *SHR = dyn_cast<ConstantSDNode>(Opr2);
  SelectionDAG &DAG = DCI.DAG;
  SDLoc dl = SDLoc(N);
  EVT VT = N->getValueType(0);
  // fold bitalign_b32(x & c1, x & c1, c2) -> bitalign_b32(x, x, c2) & rotr(c1, c2)
  if (SHR && (Opr0 == Opr1) && (Opr0.getOpcode() == ISD::AND)) {
    if (ConstantSDNode *AndMask = dyn_cast<ConstantSDNode>(Opr0.getOperand(1))) {
      uint64_t and_mask = AndMask->getZExtValue();
      uint64_t shr_val = SHR->getZExtValue() & 31U;
      if (IID == HSAILIntrinsic::HSAIL_bytealign_b32)
        shr_val = (shr_val & 3U) << 3U;
      and_mask = ((and_mask >> shr_val) | (and_mask << (32U - shr_val))) & 0xffffffffu;
      Opr0 = Opr0->getOperand(0);
      return DAG.getNode(ISD::AND, SDLoc(Opr1), Opr1.getValueType(),
        DAG.getNode(ISD::INTRINSIC_WO_CHAIN, dl, VT,
          DAG.getConstant(IID, MVT::i32), Opr0, Opr0, Opr2),
        DAG.getConstant(and_mask, MVT::i32));
    }
  }
  // fold bitalign_b32(x, y, c) -> bytealign_b32(x, y, c/8) if c & 7 == 0
  if (SHR && (IID == HSAILIntrinsic::HSAIL_bitalign_b32)) {
      uint64_t shr_val = SHR->getZExtValue() & 31U;
      if ((shr_val & 7U) == 0)
        return DAG.getNode(ISD::INTRINSIC_WO_CHAIN, dl, VT,
          DAG.getConstant(HSAILIntrinsic::HSAIL_bytealign_b32, MVT::i32),
          Opr0, Opr1, DAG.getConstant(shr_val >> 3U, MVT::i32));
  }
  return SDValue();
}

static SDValue
PerformIntrinsic_Wo_ChainCombine(SDNode *N, TargetLowering::DAGCombinerInfo &DCI)
{
  assert(N->getOpcode() == ISD::INTRINSIC_WO_CHAIN);
  unsigned IID = cast<ConstantSDNode>(N->getOperand(0))->getZExtValue();
  switch (IID) {
  case HSAILIntrinsic::HSAIL_bitalign_b32: // fall-through
  case HSAILIntrinsic::HSAIL_bytealign_b32:
    return PerformBitalignCombine(N, DCI, IID);
  }
  return SDValue();
}

/// PerformDAGCombine - This method will be invoked for all target nodes and
/// for any target-independent nodes that the target has registered with
/// invoke it for.
///
/// The semantics are as follows:
/// Return Value:
///   SDValue.Val == 0   - No change was made
///   SDValue.Val == N   - N was replaced, is dead, and is already handled.
///   otherwise          - N should be replaced by the returned Operand.
///
/// In addition, methods provided by DAGCombinerInfo may be used to perform
/// more complex transformations.
SDValue
HSAILTargetLowering::PerformDAGCombine(SDNode *N,
                                       DAGCombinerInfo &DCI) const
{
  switch (N->getOpcode()) {
  case ISD::INTRINSIC_WO_CHAIN: return PerformIntrinsic_Wo_ChainCombine(N, DCI);
  default: break;
  }

  return SDValue();
}

/// isTypeDesirableForOp - Return true if the target has native support for
/// the specified value type and it is 'desirable' to use the type for the
/// given node type. e.g. On x86 i16 is legal, but undesirable since i16
/// instruction encodings are longer and some i16 instructions are slow.
bool
HSAILTargetLowering::isTypeDesirableForOp(unsigned Opc, EVT VT) const
{
  return TargetLowering::isTypeDesirableForOp(Opc, VT);
}

/// isDesirableToPromoteOp - Return true if it is profitable for dag combiner
/// to transform a floating point op of specified opcode to a equivalent op of
/// an integer type. e.g. f32 load -> i32 load can be profitable on ARM.
bool
HSAILTargetLowering::isDesirableToTransformToIntegerOp(unsigned Opc,
                                                       EVT VT) const
{
    return (Opc == ISD::LOAD || Opc == ISD::STORE)
        && (VT.getSimpleVT() == MVT::f32
        || VT.getSimpleVT() == MVT::f64);
}

/// IsDesirableToPromoteOp - This method query the target whether it is
/// beneficial for dag combiner to promote the specified node. If true, it
/// should return the desired promotion type by reference.
bool
HSAILTargetLowering::IsDesirableToPromoteOp(SDValue Op, EVT &PVT) const
{
  return TargetLowering::IsDesirableToPromoteOp(Op, PVT);
}

//===--------------------------------------------------------------------===//
// Lowering methods - These methods must be implemented by targets so that
// the SelectionDAGLowering code knows how to lower these.
//

/// n-th element of a vector has different alignment than a base.
/// This function returns alignment for n-th alement.
static unsigned getElementAlignment(const DataLayout *DL, Type *Ty, unsigned n) {
  unsigned Alignment = DL->getABITypeAlignment(Ty);
  if (n && (Alignment > 1)) {
    Type* EltTy = Ty->getScalarType();
    if (Ty->isArrayTy())
      EltTy = Ty->getArrayElementType();
    unsigned ffs = 0;
    while (((n >> ffs) & 1) == 0) ffs++;
    Alignment = (DL->getABITypeAlignment(EltTy) * (1 << ffs)) &
                (Alignment - 1);
  } else {
    if (OpaqueType OT = GetOpaqueType(Ty)) {
      if (IsImage(OT) || OT == Sampler)
        Alignment = 8;
    }
  }
  return Alignment;
}

/// LowerReturn - This hook must be implemented to lower outgoing
/// return values, described by the Outs array, into the specified
/// DAG. The implementation should return the resulting token chain
/// value.
SDValue
HSAILTargetLowering::LowerReturn(SDValue Chain,
                                 CallingConv::ID CallConv,
                                 bool isVarArg,
                                 const SmallVectorImpl<ISD::OutputArg> &Outs,
                                 const SmallVectorImpl<SDValue> &OutVals,
                                 SDLoc dl,
                                 SelectionDAG &DAG) const
{
  MachineFunction &MF = DAG.getMachineFunction();
  HSAILMachineFunctionInfo *FuncInfo = MF.getInfo<HSAILMachineFunctionInfo>();
  HSAILParamManager &PM = FuncInfo->getParamManager();
  const Function *F = MF.getFunction();
  const FunctionType *funcType = F->getFunctionType();

  SmallVector<SDValue, 6> RetOps;
  RetOps.push_back(Chain);

  Type *type  = funcType->getReturnType();
  if (type->isIntegerTy(1)) // Handle bit as DWORD
    type = Type::getInt32Ty(type->getContext());

  if(type->getTypeID() != Type::VoidTyID) {
    Mangler Mang(getDataLayout());
    SDValue RetVariable =  DAG.getTargetExternalSymbol(PM.getParamName(
      PM.addReturnParam(type, PM.mangleArg(&Mang, F->getName()))),
      getPointerTy(HSAILAS::ARG_ADDRESS));
    Value *mdops[] = { const_cast<Function*>(F) };
    MDNode *MD = MDNode::get(F->getContext(), mdops);

    unsigned ArgNo = 0;
    LowerArgument(Chain, SDValue(), false, NULL, &Outs, dl, DAG, &RetOps, ArgNo,
                  type, HSAILAS::ARG_ADDRESS, NULL, RetVariable, &OutVals, MD);
    Chain = DAG.getNode(ISD::TokenFactor, dl, MVT::Other, RetOps);
  }

  return DAG.getNode(HSAILISD::RET_FLAG, dl, MVT::Other, Chain);
}

/// getTypeForExtArgOrReturn - Return the type that should be used to zero or
/// sign extend a zeroext/signext integer argument or return value.
EVT HSAILTargetLowering::getTypeForExtArgOrReturn(LLVMContext &Context,
                                                  EVT VT,
                                                  ISD::NodeType ExtendKind)
                                                  const {
  if (VT == MVT::i1)
    return MVT::i32;
  return TargetLowering::getTypeForExtArgOrReturn(Context, VT, ExtendKind);
}

/// Create kernel or function parameter scalar load and return its value.
/// If isLoad = false create an argument value store.
/// AddressSpace used to determine if that is a kernel or function argument.
/// ArgVT specifies expected value type where 'Ty' refers to the real
/// argument type from function's signature.
/// We have to use machine nodes here because loads and stores must be glued
/// together with the whole call sequence, while ISD::LOAD/STORE do not have
/// a glue operand. That also skips instruction selection, so faster.
/// If the call sequence is not glued we may have unrelated to call
/// instructions scheduled into the argscope if intent was argscope use.
/// This function inserts a load or store argument instruction with glue.
/// If InFlag contains glue it is used for inbound glue. Glue is produced as a
/// last result and can be consumed at will of the caller.
SDValue HSAILTargetLowering::getArgLoadOrStore(SelectionDAG &DAG, EVT ArgVT,
                                               Type *Ty,
                                               bool isLoad, bool isSExt,
                                               unsigned AddressSpace,
                                               SDValue Ptr, SDValue ParamValue,
                                               unsigned index,
                                               SDLoc dl, SDValue Chain,
                                               SDValue InFlag,
                                               const AAMDNodes &AAInfo,
                                               uint64_t offset) const
{
    MachineFunction &MF = DAG.getMachineFunction();
    Type* EltTy = Ty;
    if (Ty->isArrayTy())
      EltTy = Ty->getArrayElementType();
    EltTy = EltTy->getScalarType();
    MVT PtrTy = getPointerTy(AddressSpace);
    PointerType *ArgPT = PointerType::get(EltTy, AddressSpace);
    // TODO_HSA: check if that works with packed structs, it can happen
    //           we would need to inhibit alignment calculation in that case.
    offset += DL->getTypeStoreSize(EltTy) * index;

    if (ArgVT == MVT::i1) {
      ArgVT = MVT::i32; // Handle a bit as DWORD;
      Ty = EltTy = Type::getInt32Ty(Ty->getContext());
      if (!isLoad) ParamValue = DAG.getZExtOrTrunc(ParamValue, dl, MVT::i32);
    }

    unsigned alignment = getElementAlignment(DL, Ty, index);
    // TODO_HSA: Due to problems with RT alignment of vectors we have to
    //           use element size instead of vector size for alignment.
    //           Fix when RT is fixed.
    if (AddressSpace == HSAILAS::KERNARG_ADDRESS)
      alignment = DL->getABITypeAlignment(EltTy);

    unsigned op = 0;
    unsigned BrigType = HSAIL::getBrigType(EltTy, *DL, isSExt);
    if (AddressSpace == HSAILAS::ARG_ADDRESS) {
      if (ArgVT.getSizeInBits() <= 32)
        op = isLoad ? HSAIL::ld_v1 : HSAIL::st_32_ptr32_v1;
      else
        op = isLoad ? HSAIL::ld_v1 : HSAIL::st_64_ptr32_v1;
    } else {
      assert(AddressSpace == HSAILAS::KERNARG_ADDRESS);
    if (ArgVT.getSizeInBits() <= 32)
      op = isLoad ? HSAIL::ld_v1 : HSAIL::st_32_v1;
    else
      op = isLoad ? HSAIL::ld_v1 : HSAIL::st_64_v1;
    }

    // Change opcode for load of return value
    if (isLoad && AddressSpace == HSAILAS::ARG_ADDRESS &&
        AAInfo.TBAA && AAInfo.TBAA->getNumOperands() >= 1) {
      if (const MDString *MDS = dyn_cast<MDString>(AAInfo.TBAA->getOperand(0))) {
        if (MDS->getString().equals("retarg")) {
          assert(op != HSAIL::ld_v1);
          op = HSAIL::rarg_ld_v1;
        }
      }
    }

    unsigned opShift = isLoad ? 1 : 0;
    unsigned opNo = 5; // Value and pointer operands
    SDValue Zero = DAG.getTargetConstant(0, MVT::i32);
    SDValue Reg = DAG.getRegister(0, PtrTy); // %noreg
    if (!Ptr.getNode()) {
      // %noreg [%noreg + offset]
      alignment = ArgVT.getStoreSize(); // Assume base pointer zero.
      if (offset & (alignment - 1))
        alignment = 1;
      if (AddressSpace == HSAILAS::KERNARG_ADDRESS) {
        // If argument symbol is unknown generate a kernargbaseptr
        // instruction for Ptr instead on %noreg value.
        Reg = SDValue(DAG.getMachineNode(
          Subtarget->is64Bit() ? HSAIL::kernargbaseptr_u64
                               : HSAIL::kernargbaseptr_u32,
          dl, PtrTy), 0);
      }
    } else if (Ptr.getOpcode() != ISD::TargetExternalSymbol) {
      // %noreg [%reg + offset]
      Reg = Ptr;
      Ptr = SDValue();
      alignment = 1; // %reg is unknown, alignment as well.
    }
    if (!Ptr.getNode())
      Ptr = DAG.getRegister(0, PtrTy);
    SDValue Ops[] = {
      ParamValue,
      /* Address */ Ptr, Reg, DAG.getTargetConstant(offset, MVT::i32),
      DAG.getTargetConstant(BrigType, MVT::i32),
      Zero,
      Zero,
      Zero,
      Zero,
      Zero
    };

    if (isLoad) {
      Ops[opNo++] = DAG.getTargetConstant(AddressSpace, MVT::i32); // segment

      // Width qualifier.
        Ops[opNo++] = DAG.getTargetConstant((AddressSpace ==
          HSAILAS::KERNARG_ADDRESS) ? Brig::BRIG_WIDTH_ALL
                                    : Brig::BRIG_WIDTH_1, MVT::i32);

      // Const qualifier.
        Ops[opNo++] = DAG.getTargetConstant(
          (AddressSpace == HSAILAS::KERNARG_ADDRESS) ? 1 : 0, MVT::i1);
    }

    Ops[opNo++] = Chain;
    if (InFlag.getNode())
      Ops[opNo++] = InFlag;

    SDVTList VTs;

    if (isLoad) {
      EVT VT = (ArgVT.getStoreSize() < 4) ? MVT::i32 : ArgVT;
      VTs = DAG.getVTList(VT, MVT::Other, MVT::Glue);
    }
    else VTs = DAG.getVTList(MVT::Other, MVT::Glue);

    SmallVector <SDValue, 8> OpArg;

    for (unsigned i = opShift; i < opNo; ++i) {
      OpArg.push_back(Ops[i]);
    }
    SDNode *ArgNode = DAG.getMachineNode(op, dl, VTs, OpArg);

    MachinePointerInfo MPtrInfo(UndefValue::get(ArgPT), offset);
    MachineSDNode::mmo_iterator MemOp = MF.allocateMemRefsArray(1);
    MemOp[0] = MF.getMachineMemOperand(MPtrInfo,
      isLoad ? MachineMemOperand::MOLoad : MachineMemOperand::MOStore,
      ArgVT.getStoreSize(), alignment, AAInfo);
    cast<MachineSDNode>(ArgNode)->setMemRefs(MemOp, MemOp + 1);

    return SDValue(ArgNode, 0);
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
SDValue HSAILTargetLowering::LowerArgument(SDValue Chain, SDValue InFlag,
                                           bool ChainLink,
                                           const SmallVectorImpl<ISD::InputArg> *Ins,
                                           const SmallVectorImpl<ISD::OutputArg> *Outs,
                                           SDLoc dl,
                                           SelectionDAG &DAG,
                                           SmallVectorImpl<SDValue> *InVals,
                                           unsigned &ArgNo,
                                           Type *type,
                                           unsigned AS,
                                           const char *ParamName,
                                           SDValue ParamPtr,
                                           const SmallVectorImpl<SDValue> *OutVals,
                                           const AAMDNodes & AAInfo,
                                           uint64_t offset) const {
  assert((Ins == NULL && Outs != NULL) || (Ins != NULL && Outs == NULL));

      Type *sType = type->getScalarType();

  EVT argVT = Ins ? (*Ins)[ArgNo].VT : (*Outs)[ArgNo].VT;
      if (sType->isIntegerTy(8)) argVT = MVT::i8;
      else if (sType->isIntegerTy(16)) argVT = MVT::i16;

  bool isLoad = Ins != NULL;
  bool hasFlag = InFlag.getNode() != NULL;
      SDValue ArgValue;

  const VectorType *VecTy = dyn_cast<VectorType>(type);
  const ArrayType  *ArrTy = dyn_cast<ArrayType>(type);
  if (VecTy || ArrTy) {
        // This assumes that char and short vector elements are unpacked in Ins.
    unsigned num_elem = VecTy ? VecTy->getNumElements() : ArrTy->getNumElements();
    for (unsigned i = 0; i < num_elem; ++i) {
      bool isSExt = isLoad ? (*Ins)[ArgNo].Flags.isSExt()
                           : (*Outs)[ArgNo].Flags.isSExt();
      ArgValue = getArgLoadOrStore(DAG, argVT, type, isLoad, isSExt, AS, ParamPtr,
                                   isLoad ? SDValue() : (*OutVals)[ArgNo],
                                   i, dl, Chain, InFlag, AAInfo, offset);

      if (ChainLink) Chain  = ArgValue.getValue(isLoad ? 1 : 0);
      // Glue next vector loads regardless of input flag to favor vectorization.
      InFlag = ArgValue.getValue(isLoad ? 2 : 1);
      if (InVals) InVals->push_back(ArgValue);
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
                               ParamName, ParamPtr, OutVals, AAInfo,
                               offset + SL->getElementOffset(i));
      if (ChainLink) Chain  = ArgValue.getValue(isLoad ? 1 : 0);
      if (hasFlag) InFlag = ArgValue.getValue(isLoad ? 2 : 1);
    }
    return ArgValue;
  }

      // Regular scalar load case.
  bool isSExt = isLoad ? (*Ins)[ArgNo].Flags.isSExt()
                       : (*Outs)[ArgNo].Flags.isSExt();
  ArgValue = getArgLoadOrStore(DAG, argVT, type, isLoad, isSExt, AS, ParamPtr,
                               isLoad ? SDValue() : (*OutVals)[ArgNo], 0, dl,
                               Chain, InFlag, AAInfo, offset);
  if (InVals) InVals->push_back(ArgValue);
  ArgNo++;

  return ArgValue;
}

/// LowerFormalArguments - This hook must be implemented to lower the
/// incoming (formal) arguments, described by the Ins array, into the
/// specified DAG. The implementation should fill in the InVals array
/// with legal-type argument values, and return the resulting token
/// chain value.
///
SDValue
HSAILTargetLowering::LowerFormalArguments(SDValue Chain,
                                          CallingConv::ID CallConv,
                                          bool isVarArg,
                                          const SmallVectorImpl<ISD::InputArg> &Ins,
                                          SDLoc dl,
                                          SelectionDAG &DAG,
                                          SmallVectorImpl<SDValue> &InVals) const
{
  MachineFunction &MF = DAG.getMachineFunction();
  HSAILMachineFunctionInfo *FuncInfo = MF.getInfo<HSAILMachineFunctionInfo>();
  HSAILParamManager &PM = FuncInfo->getParamManager();
  const FunctionType *funcType = MF.getFunction()->getFunctionType();
  unsigned AS = HSAIL::isKernelFunc(MF.getFunction()) ? HSAILAS::KERNARG_ADDRESS
                                                      : HSAILAS::ARG_ADDRESS;
  MVT PtrTy = getPointerTy(AS);

  Mangler Mang(DL);

  // Map function param types to Ins.
  Function::const_arg_iterator AI = MF.getFunction()->arg_begin();
  Function::const_arg_iterator AE = MF.getFunction()->arg_end();
  for(unsigned ArgNo = 0; AI != AE; ++AI) {
    unsigned Param = PM.addArgumentParam(AS, *AI,
                        HSAILParamManager::mangleArg(&Mang, AI->getName()));
    const char* ParamName = PM.getParamName(Param);
    std::string md = (AI->getName() + ":" + ParamName + " ").str();
    FuncInfo->addMetadata("argmap:"+ md, true);
    SDValue ParamPtr = DAG.getTargetExternalSymbol(ParamName, PtrTy);
    Value *mdops[] = { const_cast<Argument*>(&(*AI)) };
    MDNode *ArgMD = MDNode::get(MF.getFunction()->getContext(), mdops);

    LowerArgument(Chain, SDValue(), false, &Ins, NULL, dl, DAG, &InVals, ArgNo,
                  AI->getType(), AS, ParamName, ParamPtr, NULL, ArgMD);
  }

  return Chain;
}

/// LowerCall - This hook must be implemented to lower calls into the
/// the specified DAG. The outgoing arguments to the call are described
/// by the Outs array, and the values to be returned by the call are
/// described by the Ins array. The implementation should fill in the
/// InVals array with legal-type return values from the call, and return
/// the resulting token chain value.

SDValue HSAILTargetLowering::LowerCall(CallLoweringInfo &CLI,
                               SmallVectorImpl<SDValue> &InVals) const {
  SelectionDAG &DAG                     = CLI.DAG;
  SDLoc &dl                          = CLI.DL;
  SmallVector<ISD::OutputArg, 32> &Outs = CLI.Outs;
  SmallVector<SDValue, 32> &OutVals     = CLI.OutVals;
  SmallVector<ISD::InputArg, 32> &Ins   = CLI.Ins;
  SDValue Chain                         = CLI.Chain;
  SDValue Callee                        = CLI.Callee;
  bool &isTailCall                      = CLI.IsTailCall;

  isTailCall = false;
  MachineFunction& MF = DAG.getMachineFunction();
  HSAILParamManager &PM = MF.getInfo<HSAILMachineFunctionInfo>()->getParamManager();
  Mangler Mang(getDataLayout());
  // FIXME: DO we need to handle fast calling conventions and tail call
  // optimizations?? X86/PPC ISelLowering
  /*bool hasStructRet = (TheCall->getNumArgs())
    ? TheCall->getArgFlags(0).device()->isSRet()
    : false;*/

  unsigned int NumBytes = 0;//CCInfo.getNextStackOffset();
  if (isTailCall) {
    assert(isTailCall && "Tail Call not handled yet!");
    // See X86/PPC ISelLowering
  }

  SDValue CallSeqStart = DAG.getCALLSEQ_START(Chain, DAG.getIntPtrConstant(NumBytes, true), dl);
  Chain = CallSeqStart.getValue(0);

  SmallVector<std::pair<unsigned int, SDValue>, 8> RegsToPass;
  SmallVector<SDValue, 8> MemOpChains;
  SDValue StackPtr;

  const FunctionType * funcType = NULL;
  const Function *calleeFunc = NULL;
  const char *FuncName = NULL;

  // If the callee is a GlobalAddress/ExternalSymbol node (quite common,
  // every direct call is) turn it into a TargetGlobalAddress/
  // TargetExternalSymbol
  // node so that legalize doesn't hack it.
  if (GlobalAddressSDNode *G = dyn_cast<GlobalAddressSDNode>(Callee))  {
    unsigned AS = G->getAddressSpace();
    Callee = DAG.getTargetGlobalAddress(G->getGlobal(), dl, getPointerTy(AS));

    const GlobalValue *GV = G->getGlobal();
    calleeFunc = static_cast<const Function*>(GV);
    funcType = calleeFunc->getFunctionType();
    FuncName = GV->getName().data();
  }
  else if (ExternalSymbolSDNode *S = dyn_cast<ExternalSymbolSDNode>(Callee)) {
    unsigned AS = G->getAddressSpace();
    FuncName = S->getSymbol();
    Callee = DAG.getTargetExternalSymbol(FuncName, getPointerTy(AS));

    // HSA_TODO: Use `Outs` and `Ins` instead of funcType in the rest of this function
    assert(!"Not implemented");
  }

  assert(funcType != NULL);

  SmallVector<SDValue, 8> Ops;
  SmallVector<SDValue, 8> VarOps;
  SDVTList VTs = DAG.getVTList(MVT::Other, MVT::Glue);

  SDValue InFlag = CallSeqStart.getValue(1);
  Type *retType = funcType->getReturnType();
  SDValue RetValue;
  if (retType->getTypeID() != Type::VoidTyID) {
    if (retType->isIntegerTy(1)) // Handle bit as DWORD
      retType = Type::getInt32Ty(retType->getContext());
    RetValue = DAG.getTargetExternalSymbol(PM.getParamName(
      PM.addCallRetParam(retType, PM.mangleArg(&Mang, FuncName))),
      getPointerTy(HSAILAS::ARG_ADDRESS));

    unsigned BrigType = (unsigned) HSAIL::getBrigType(retType, *DL, CLI.RetSExt);
    if (BrigType == Brig::BRIG_TYPE_B1)
      BrigType = Brig::BRIG_TYPE_U32; // Store bit as DWORD
    SDValue SDBrigType =  DAG.getTargetConstant(BrigType, MVT::i32);
    SDValue arrSize = DAG.getTargetConstant(
      HSAIL::getNumElementsInHSAILType(retType, *DL), MVT::i32);
    unsigned alignment = HSAIL::HSAILgetAlignTypeQualifier(retType, *DL, false);
    SDValue Align = DAG.getTargetConstant(alignment, MVT::i32);
    SDValue ArgDeclOps[] = { RetValue, SDBrigType, arrSize, Align,
                             Chain, InFlag };
    SDNode *ArgDeclNode = DAG.getMachineNode(HSAIL::arg_decl, dl, VTs,
                  makeArrayRef(ArgDeclOps).drop_back(InFlag.getNode() ? 0 : 1));
    
    SDValue ArgDecl(ArgDeclNode, 0);

    Chain = ArgDecl.getValue(0);
    InFlag = ArgDecl.getValue(1);
    VarOps.push_back(RetValue);
  }
  // Delimit return value and parameters with 0
  VarOps.push_back(DAG.getTargetConstant(0, MVT::i32));
  unsigned FirstArg = VarOps.size();

  unsigned int j=0, k=0;
  Function::const_arg_iterator ai;
  Function::const_arg_iterator ae;
  if (calleeFunc) {
    ai = calleeFunc->arg_begin();
    ae = calleeFunc->arg_end();
  }

  MDBuilder MDB(*DAG.getContext());
  for(FunctionType::param_iterator pb = funcType->param_begin(),
    pe = funcType->param_end(); pb != pe; ++pb, ++ai, ++k) {
    Type *type = *pb;
    if (type->isIntegerTy(1)) // Handle bit as DWORD
      type = Type::getInt32Ty(type->getContext());
    EVT VT = Outs[j].VT;

    std::string ParamName;
    if (calleeFunc && ai != ae) {
      ParamName = PM.mangleArg(&Mang, ai->getName());
    }
    if (ParamName.empty()) {
      ParamName = "__param_p";
      ParamName.append(itostr(k));
    }
    SDValue StParamValue = DAG.getTargetExternalSymbol(
      PM.getParamName(PM.addCallArgParam(type, ParamName)),
      getPointerTy(HSAILAS::ARG_ADDRESS));

    // START array parameter declaration
    unsigned BrigType
      = (unsigned) HSAIL::getBrigType(type, *DL, Outs[j].Flags.isSExt());
    if (BrigType == Brig::BRIG_TYPE_B1)
      BrigType = Brig::BRIG_TYPE_U32; // Store bit as DWORD
    SDValue SDBrigType =  DAG.getTargetConstant(BrigType, MVT::i32);
    SDValue arrSize =  DAG.getTargetConstant(
      HSAIL::getNumElementsInHSAILType(type, *DL), MVT::i32);
    unsigned alignment = HSAIL::HSAILgetAlignTypeQualifier(type, *DL, false);
    SDValue Align = DAG.getTargetConstant(alignment, MVT::i32);
    SDValue ArgDeclOps[] = { StParamValue, SDBrigType, arrSize, Align,
                             Chain, InFlag };
    SDNode *ArgDeclNode = DAG.getMachineNode(HSAIL::arg_decl, dl, VTs,
                  makeArrayRef(ArgDeclOps).drop_back(InFlag.getNode() ? 0 : 1));
    SDValue ArgDecl(ArgDeclNode, 0);
    Chain = ArgDecl.getValue(0);
    InFlag = ArgDecl.getValue(1);
    // END array parameter declaration

    VarOps.push_back(StParamValue);

    for ( ; j < Outs.size() - 1; j++) {
      if (Outs[j].OrigArgIndex != Outs[j + 1].OrigArgIndex)
        break;
    }
    j++;
  }

  j = k = 0;
  for(FunctionType::param_iterator pb = funcType->param_begin(),
    pe = funcType->param_end(); pb != pe; ++pb, ++k) {
    Type *type = *pb;
    if (type->isIntegerTy(1)) // Handle bit as DWORD
      type = Type::getInt32Ty(type->getContext());
    Chain = LowerArgument(Chain, InFlag, true, NULL, &Outs, dl, DAG, NULL, j,
                          type, HSAILAS::ARG_ADDRESS, NULL,
                          VarOps[FirstArg + k], &OutVals,
                          MDB.createAnonymousTBAARoot());
      InFlag = Chain.getValue(1);
  }

  // If this is a direct call, pass the chain and the callee
  if (Callee.getNode()) {
    Ops.push_back(Chain);
    Ops.push_back(Callee);
  }

  // Add actual arguments to the end of the list
  for (unsigned int i = 0, e = VarOps.size(); i != e; ++i) {
    Ops.push_back(VarOps[i]);
  }

  if (InFlag.getNode()) {
    Ops.push_back(InFlag);
  }

  Chain = DAG.getNode(HSAILISD::CALL, dl, VTs, Ops);
  InFlag = Chain.getValue(1);

  // Read return value.
  if(Ins.size() > 0) {
    j = 0;
    MDNode *TBAA = MDB.createTBAANode("retarg", MDB.createAnonymousTBAARoot());
    Chain = LowerArgument(Chain, InFlag, true, &Ins, NULL, dl, DAG, &InVals, j,
                          retType, HSAILAS::ARG_ADDRESS, NULL, RetValue, NULL,
                          TBAA);
    InFlag = Chain.getValue(2);
    Chain  = Chain.getValue(1);
  }

  // Create the CALLSEQ_END node
  Chain = DAG.getCALLSEQ_END(Chain,
                             DAG.getIntPtrConstant(NumBytes, true),
                             DAG.getIntPtrConstant(0, true),
                             InFlag, dl);
  return Chain;
}

#define LOWER(A) \
  case ISD:: A: \
  return Lower##A(Op, DAG)

/// LowerOperation - This callback is invoked for operations that are
/// unsupported by the target, which are registered to use 'custom' lowering,
/// and whose defined values are all legal.
/// If the target has no operations that require custom lowering, it need not
/// implement this.  The default implementation of this aborts.
SDValue
HSAILTargetLowering::LowerOperation(SDValue Op,
                                    SelectionDAG &DAG) const
{
  switch (Op.getOpcode()) {
    LOWER(GlobalAddress);
    LOWER(TRUNCATE);
    LOWER(INTRINSIC_W_CHAIN);
    LOWER(ROTL);
    LOWER(ROTR);
    LOWER(BSWAP);
    LOWER(ADD);
    LOWER(LOAD);
    LOWER(STORE);
#if 0
    LOWER(ATOMIC_LOAD);
    LOWER(ATOMIC_STORE);
#endif
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
void
HSAILTargetLowering::ReplaceNodeResults(SDNode *N,
                                        SmallVectorImpl<SDValue> &Results,
                                        SelectionDAG &DAG) const
{
  return TargetLowering::ReplaceNodeResults(N, Results, DAG);
}

/// getTargetNodeName() - This method returns the name of a target specific
/// DAG node.
const char*
HSAILTargetLowering::getTargetNodeName(unsigned Opcode) const
{
  switch (Opcode) {
  default:
    llvm_unreachable("Unknown target-node");
    return NULL;
  case HSAILISD::CALL:
    return "HSAILISD::CALL";
  case HSAILISD::RET_FLAG:
    return "HSAILISD::RET_FLAG";
  case HSAILISD::LDA_FLAT:
    return "HSAILISD::LDA_FLAT";
  case HSAILISD::LDA_GLOBAL:
    return "HSAILISD::LDA_GLOBAL";
  case HSAILISD::LDA_GROUP:
    return "HSAILISD::LDA_GROUP";
  case HSAILISD::LDA_PRIVATE:
    return "HSAILISD::LDA_PRIVATE";
  case HSAILISD::LDA_READONLY:
    return "HSAILISD::LDA_READONLY";
  case HSAILISD::TRUNC_B1:
    return "HSAILISD::TRUNC_B1";
  }
}

//===--------------------------------------------------------------------===//
// Custom lowering methods
//

/// LowerGlobalAddress - Lowers a global address ref to a target global address lda.
SDValue
HSAILTargetLowering::LowerGlobalAddress(SDValue Op, SelectionDAG &DAG) const {
  const GlobalAddressSDNode *GSDN = cast<GlobalAddressSDNode>(Op);
  const GlobalValue *GV = GSDN->getGlobal();

  unsigned addrSpace = GSDN->getAddressSpace();
  EVT PtrVT = getPointerTy(addrSpace);
  SDLoc dl = SDLoc(Op);
  unsigned opcode;

  if (addrSpace == HSAILAS::FLAT_ADDRESS) {
    opcode = HSAILISD::LDA_FLAT;
  } else if (addrSpace == HSAILAS::GLOBAL_ADDRESS) {
    opcode = HSAILISD::LDA_GLOBAL;
  } else if (addrSpace == HSAILAS::GROUP_ADDRESS) {
    opcode = HSAILISD::LDA_GROUP;
  } else if (addrSpace == HSAILAS::PRIVATE_ADDRESS) {
    opcode = HSAILISD::LDA_PRIVATE;
  } else if (addrSpace == HSAILAS::CONSTANT_ADDRESS) {
    opcode = HSAILISD::LDA_READONLY;
  } else {
    assert(!"cannot lower GlobalAddress");
  }
  SDValue targetGlobal = DAG.getTargetGlobalAddress(GV, dl, PtrVT,
                                                    GSDN->getOffset());
  return DAG.getNode(opcode, dl, PtrVT.getSimpleVT(), targetGlobal);
}

SDValue 
HSAILTargetLowering::LowerTRUNCATE(SDValue Op, SelectionDAG &DAG) const {
  SDLoc dl = SDLoc(Op);
  EVT VT = Op.getValueType();

  if (VT != MVT::i1) {
    return Op;
  }
  // Generate a custom truncate operation that clears all but the
  // least-significant bit in the source operand before truncating to i1.
  const SDValue src = Op.getOperand(0);
  EVT srcVT = src.getValueType();
  const SDValue trunc =  DAG.getNode(ISD::AND, dl, srcVT, src, 
                          DAG.getConstant(1, srcVT));
  return DAG.getNode(HSAILISD::TRUNC_B1, dl, VT, trunc);
}
SDValue 
HSAILTargetLowering::LowerADD(SDValue Op, SelectionDAG &DAG) const {
  SDLoc dl = SDLoc(Op);
  EVT VT = Op.getValueType();

  if (VT != MVT::i1) {
    return Op;
  }
  const SDValue src = Op.getOperand(0).getOperand(0);
  EVT srcVT = src.getValueType();
  if(Op.getOperand(0).getOpcode() != ISD::TRUNCATE) return Op;

  SDValue Zext = DAG.getNode(ISD::ZERO_EXTEND, dl, MVT::i32,Op.getOperand(1));
  SDValue Zext1 = DAG.getNode(ISD::ZERO_EXTEND, dl, srcVT,Op.getOperand(0)); 
  SDValue add_p = DAG.getNode(ISD::ADD, dl, srcVT,Zext1,Zext);
  SDValue Zext2 = DAG.getNode(HSAILISD::TRUNC_B1, dl, VT,add_p);
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

SDValue
HSAILTargetLowering::LowerINTRINSIC_W_CHAIN(SDValue Op, SelectionDAG &DAG) const {
  unsigned IntNo = cast<ConstantSDNode>(Op->getOperand(1))->getZExtValue();
  if (!isRdimage(IntNo)) return Op;
  return lowerSamplerInitializerOperand(Op, DAG);
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
  if (!isa<ConstantSDNode>(sampler)) return Op;

    unsigned samplerConstant = cast<ConstantSDNode>(sampler)->getZExtValue();
  if (samplerConstant >= IMAGE_ARG_BIAS) return Op;

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
          DAG.getRegister(0, getPointerTy()), DAG.getTargetConstant(0, MVT::i32),
          DAG.getTargetConstant(Brig::BRIG_TYPE_SAMP, MVT::i32),
          DAG.getTargetConstant(Brig::BRIG_WIDTH_ALL, MVT::i32),
          DAG.getTargetConstant(1, MVT::i1), // Const
          DAG.getEntryNode() // Chain
        };
        EVT VT = sampler.getValueType();

    // Don't use ptr32 since this is the readonly segment.
        MachineSDNode *LDSamp = DAG
          .getMachineNode(HSAIL::ld_v1, SDLoc(Op), VT, MVT::Other, Ops);

        MachineFunction &MF = DAG.getMachineFunction();
        MachineSDNode::mmo_iterator MemOp = MF.allocateMemRefsArray(1);
        unsigned size = VT.getStoreSize();
        Type *PTy = VT.getTypeForEVT(*DAG.getContext());
        PointerType *PT = PointerType::get(PTy, HSAILAS::CONSTANT_ADDRESS);
        MachinePointerInfo MPtrInfo(UndefValue::get(PT),
                                    size * samplerHandleIndex);
        MemOp[0] = MF.getMachineMemOperand(MPtrInfo, MachineMemOperand::MOLoad,
                                           size, size);
        LDSamp->setMemRefs(MemOp, MemOp + 1);

        ops[SAMPLER_ARG] = SDValue(LDSamp, 0);

      DAG.UpdateNodeOperands(Op.getNode(),
                             makeArrayRef(ops, Op.getNumOperands()));

  return Op;
}

SDValue 
HSAILTargetLowering::LowerROTL(SDValue Op, SelectionDAG &DAG) const {
  SDLoc dl = SDLoc(Op);
  EVT VT = Op.getValueType();

  if (VT != MVT::i32) {
    return Op;
  }
  const SDValue src0 = Op.getOperand(0);
  const SDValue src1 = Op.getOperand(1);
  const ConstantSDNode* shift = dyn_cast<ConstantSDNode>(src1);
  return DAG.getNode(ISD::INTRINSIC_WO_CHAIN, dl, VT,
           DAG.getConstant(HSAILIntrinsic::HSAIL_bitalign_b32, MVT::i32),
           src0, src0,
           shift ?
             DAG.getConstant(32 - (shift->getZExtValue() & 31), MVT::i32) :
             DAG.getNode(ISD::SUB, dl, VT, DAG.getConstant(0, VT), src1));  
}

SDValue 
HSAILTargetLowering::LowerROTR(SDValue Op, SelectionDAG &DAG) const {
  SDLoc dl = SDLoc(Op);
  EVT VT = Op.getValueType();

  if (VT != MVT::i32) {
    return Op;
  }
  const SDValue src0 = Op.getOperand(0);
  const SDValue src1 = Op.getOperand(1);
  return DAG.getNode(ISD::INTRINSIC_WO_CHAIN, dl, VT,
           DAG.getConstant(HSAILIntrinsic::HSAIL_bitalign_b32, MVT::i32),
           src0, src0, src1);  
}

SDValue
HSAILTargetLowering::LowerBSWAP(SDValue Op, SelectionDAG &DAG) const {
  SDLoc dl = SDLoc(Op);
  EVT VT = Op.getValueType();

  if (VT != MVT::i32) {
    return Op;
  }
  const SDValue src = Op.getOperand(0);
  const SDValue opr0 = DAG.getNode(ISD::INTRINSIC_WO_CHAIN, dl, VT,
           DAG.getConstant(HSAILIntrinsic::HSAIL_bytealign_b32, MVT::i32),
           src, src, DAG.getConstant(3, MVT::i32));
  const SDValue opr1 = DAG.getNode(ISD::INTRINSIC_WO_CHAIN, dl, VT,
           DAG.getConstant(HSAILIntrinsic::HSAIL_bytealign_b32, MVT::i32),
           src, src, DAG.getConstant(1, MVT::i32));
  return DAG.getNode(ISD::INTRINSIC_WO_CHAIN, dl, VT,
           DAG.getConstant(HSAILIntrinsic::HSAIL_bitsel_u32, MVT::i32),
           DAG.getConstant(0x00ff00ff, VT), opr0, opr1);
}

SDValue
HSAILTargetLowering::LowerLOAD(SDValue Op, SelectionDAG &DAG) const {
  SDLoc dl(Op);

  EVT VT = Op.getValueType();
  LoadSDNode *LD = cast<LoadSDNode>(Op);

  if (VT.getSimpleVT() == MVT::i1) {
    // Since there are no 1 bit load operations, the load operations are
    // converted to 8 bit loads.
    // First, do 8 bit load into 32 bits with sign extension, then
    // truncate to 1 bit.
    LoadSDNode *LD = cast<LoadSDNode>(Op);
    SDValue Chain = LD->getChain();
    SDValue BasePtr = LD->getBasePtr();
    MachineMemOperand *MMO = LD->getMemOperand();

    SDValue NewLD = DAG.getExtLoad(ISD::SEXTLOAD, dl,
                     MVT::i32, Chain, BasePtr, MMO->getPointerInfo(), MVT::i8,
                     LD->isVolatile(),  LD->isNonTemporal(), LD->isInvariant(), 0);

    SDValue Result = DAG.getNode(ISD::TRUNCATE, dl, MVT::i1, NewLD);
    SDValue Ops[] = {
      Result,
      NewLD.getValue(1)
    };

    return DAG.getMergeValues(Ops, dl);
  }

  // Custom lowering for extload from sub-dword size to i64. We only
  // do it because LLVM currently does not support Expand for EXTLOAD
  // with illegal types.
  // See "EXTLOAD should always be supported!" assert in LegalizeDAG.cpp.
  if (VT.getSimpleVT() != MVT::i64) return Op;
  ISD::LoadExtType extType = LD->getExtensionType();

  if (extType == ISD::SEXTLOAD && LD->hasNUsesOfValue(1, 0)) {
    // Check if the only use is a truncation to the size of loaded memory.
    // In this case produce zext instead of sext. Note, that load chain
    // has its own use.
    SDNode::use_iterator UI = LD->use_begin(), UE = LD->use_end();
    for ( ; UI != UE; ++UI) {
      if (UI.getUse().getResNo() == 0) {
        // User of a loaded value.
        if (UI->getOpcode() == ISD::AND && isa<ConstantSDNode>(UI->getOperand(1))) {
          EVT MemVT = LD->getMemoryVT();
          uint64_t Mask = UI->getConstantOperandVal(1);
          if ((MemVT == MVT::i8  && Mask == 0xFFul) ||
              (MemVT == MVT::i16 && Mask == 0xFFFFul)) {
            // The AND operator was not really needed. Produce zextload as it does
            // not change the result and let AND node silintly die.
            extType = ISD::ZEXTLOAD;
          }
        }
        break;
      }
    }
  }

  // Do extload into 32-bit register, then extend that.
  SDValue NewLD = DAG.getExtLoad(extType, dl, MVT::i32, LD->getChain(),
                                 LD->getBasePtr(), MVT::i8, LD->getMemOperand());

  SDValue Ops[] = {
    DAG.getNode(ISD::getExtForLoadExtType(extType), dl, MVT::i64, NewLD),
    NewLD.getValue(1)
  };

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

//===--------------------------------------------------------------------===//
// Addressing mode description hooks (used by LSR etc).
//
/// isLegalAddressingMode - Return true if the addressing mode represented by
/// AM is legal for this target, for a load/store of the specified type.
/// The type may be VoidTy, in which case only return true if the addressing
/// mode is legal for a load/store of any legal type.
/// TODO: Handle pre/postinc as well.
bool
HSAILTargetLowering::isLegalAddressingMode(const AddrMode &AM,
                                           Type *Ty) const
{
  if (OptimizeFor == SI)
  {
    // Do not generate negative offsets as they can not be folded
    // into instruction
    if (AM.BaseOffs < 0 ||
        AM.Scale < 0)
    {
      return false;
    }
  }
  
  return TargetLowering::isLegalAddressingMode(AM, Ty);
}
/// isTruncateFree - Return true if it's free to truncate a value of
/// type Ty1 to type Ty2. e.g. On x86 it's free to truncate a i32 value in
/// register EAX to i16 by referencing its sub-register AX.
bool
HSAILTargetLowering::isTruncateFree(Type *Ty1, Type *Ty2) const
{
  return TargetLowering::isTruncateFree(Ty1, Ty2);
}

bool
HSAILTargetLowering::isTruncateFree(EVT VT1, EVT VT2) const
{
  return TargetLowering::isTruncateFree(VT1, VT2);
}
/// isZExtFree - Return true if any actual instruction that defines a
/// value of type Ty1 implicitly zero-extends the value to Ty2 in the result
/// register. This does not necessarily include registers defined in
/// unknown ways, such as incoming arguments, or copies from unknown
/// registers. Also, if isTruncateFree(Ty2, Ty1) is true, this
/// does not necessarily apply to truncate instructions. e.g. on x86-64,
/// all instructions that define 32-bit values implicit zero-extend the
/// result out to 64 bits.
bool
HSAILTargetLowering::isZExtFree(Type *Ty1, Type *Ty2) const
{
  return false;
}

bool
HSAILTargetLowering::isZExtFree(EVT VT1, EVT VT2) const
{
  return false;
}

/// isNarrowingProfitable - Return true if it's profitable to narrow
/// operations of type VT1 to VT2. e.g. on x86, it's profitable to narrow
/// from i32 to i8 but not from i32 to i16.
bool
HSAILTargetLowering::isNarrowingProfitable(EVT VT1, EVT VT2) const
{
  // This is only profitable in HSAIL to go from a 64bit type to
  // a 32bit type, but not to a 8 or 16bit type.
  return (VT1 == EVT(MVT::i64) && VT2 == EVT(MVT::i32))
    || (VT1 == EVT(MVT::f64) && VT2 == EVT(MVT::f32));
}

/// isLegalICmpImmediate - Return true if the specified immediate is legal
/// icmp immediate, that is the target has icmp instructions which can compare
/// a register against the immediate without having to materialize the
/// immediate into a register.
bool
HSAILTargetLowering::isLegalICmpImmediate(int64_t Imm) const
{
  // HSAIL doesn't have any restrictions on this.
  return true;
}

MVT HSAILTargetLowering::getScalarShiftAmountTy(EVT LHSTy) const {
  // Shift amounts in registers must be in S registers
  // Restrict shift amount to 32-bits.
  return MVT::i32;
}

//#if 0
void HSAILTargetLowering::replaceUnusedAtomicRetInst(MachineInstr *MI,
                                                     SDNode *Node) const {
  unsigned BrigOp = cast<ConstantSDNode>(Node->getOperand(0))->getZExtValue();
  if (BrigOp == Brig::BRIG_ATOMIC_EXCH ||
      BrigOp == Brig::BRIG_ATOMIC_LD) return;

  int NoretOp = HSAIL::getAtomicNoretVersion(MI->getOpcode());
  assert(NoretOp != -1);

      DEBUG(dbgs() << "Replacing atomic ");
      DEBUG(MI->dump());
      DEBUG(dbgs() << " with no return version ");
      const HSAILInstrInfo *TII = static_cast<const HSAILInstrInfo *>(
        getTargetMachine().getSubtargetImpl()->getInstrInfo());
      MI->setDesc(TII->get(NoretOp));
      MI->RemoveOperand(0);
      DEBUG(MI->dump());
      DEBUG(dbgs() << '\n');
}

void
HSAILTargetLowering::AdjustInstrPostInstrSelection(MachineInstr *MI, SDNode *Node) const
{
  if (HSAIL::isRetAtomicOp(MI) && Node->use_size() <= 1)
    replaceUnusedAtomicRetInst(MI, Node);
}
//#endif

bool
HSAILTargetLowering::isLoadBitCastBeneficial(EVT lVT, EVT bVT) const
{
  return !(lVT.getSizeInBits() == bVT.getSizeInBits()
      && lVT.getScalarType().getSizeInBits() > bVT.getScalarType().getSizeInBits()
      && bVT.getScalarType().getSizeInBits() < 32
      && lVT.getScalarType().getSizeInBits() >= 32);
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
  if ((Width * 4 / 3) == WidenWidth) return false;
  return true;
}
