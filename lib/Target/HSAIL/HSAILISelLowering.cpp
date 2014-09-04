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
#include "HSAILInstrInfo.h"
#include "HSAILELFTargetObjectFile.h"
#include "HSAILISelLowering.h"
#include "HSAILMachineFunctionInfo.h"
#include "HSAILSubtarget.h"
#include "HSAILTargetMachine.h"
#include "HSAILUtilityFunctions.h"
#include "HSAILOpaqueTypes.h"
#include "llvm/CallingConv.h"
#include "llvm/Constants.h"
#include "llvm/DerivedTypes.h"
#include "llvm/GlobalAlias.h"
#include "llvm/GlobalVariable.h"
#include "llvm/Function.h"
#include "llvm/Instructions.h"
#include "llvm/Intrinsics.h"
#include "llvm/LLVMContext.h"
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
#include "llvm/Target/Mangler.h"
#include "llvm/Target/TargetLowering.h"
#include "llvm/Target/TargetOptions.h"
#include "llvm/Support/CallSite.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/Dwarf.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/CommandLine.h"
#include "libHSAIL/Brig.h"
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

  RegInfo = TM.getRegisterInfo();
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

  setOperationAction(ISD::BR_JT, MVT::Other, Expand);
  setOperationAction(ISD::BR_CC, MVT::Other, Expand);
  setOperationAction(ISD::SELECT_CC, MVT::Other, Expand);

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
  setPow2DivIsCheap(false);
  setPrefLoopAlignment(0);
  setSchedulingPreference(Sched::ILP);
  setSupportJumpTables(false);
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
  maxStoresPerMemcpy  = 4096;
  maxStoresPerMemmove = 4096;
  maxStoresPerMemset  = 4096;
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

/// getCmpLibcallReturnType - Return the ValueType for comparison
/// libcalls. Comparions libcalls include floating point comparion calls,
/// and Ordered/Unordered check calls on floating point numbers.
MVT::SimpleValueType
HSAILTargetLowering::getCmpLibcallReturnType() const
{
  assert(!"When do we hit this?");
  return MVT::SimpleValueType();
}
/// getSchedulingPreference - Some scheduler, e.g. hybrid, can switch to
/// different scheduling heuristics for different nodes. This function returns
/// the preference (or none) for the given node.
Sched::Preference
HSAILTargetLowering::getSchedulingPreference(SDNode *N) const
{
  return TargetLowering::getSchedulingPreference(N);
}
/// getRegClassFor - Return the register class that should be used for the
/// specified value type.
const TargetRegisterClass*
HSAILTargetLowering::getRegClassFor(EVT VT) const
{
  return TargetLowering::getRegClassFor(VT);
}
/// getRepRegClassFor - Return the 'representative' register class for the
/// specified value type. The 'representative' register class is the largest
/// legal super-reg register class for the register class of the value type.
/// For example, on i386 the rep register class for i8, i16, and i32 are GR32;
/// while the rep register class is GR64 on x86_64.
const TargetRegisterClass*
HSAILTargetLowering::getRepRegClassFor(EVT VT) const
{
  switch (VT.getSimpleVT().SimpleTy) {
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
      assert(!"When do we hit this?");
      break;
  }
  return NULL;
}

/// getRepRegClassCostFor - Return the cost of the 'representative' register
/// class for the specified value type.
uint8_t
HSAILTargetLowering::getRepRegClassCostFor(EVT VT) const
{
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

/// isShuffleMaskLegal - Targets can use this to indicate that they only
/// support *some* VECTOR_SHUFFLE operations, those with specific masks.
/// By default, if a target supports the VECTOR_SHUFFLE node, all mask values
/// are assumed to be legal.
bool
HSAILTargetLowering::isShuffleMaskLegal(const SmallVectorImpl<int> &Mask,
                                        EVT VT) const
{
  assert(!"When do we hit this?");
  return false;
}

/// canOpTrap - Returns true if the operation can trap for the value type.
/// VT must be a legal type. By default, we optimistically assume most
/// operations don't trap except for divide and remainder.
bool
HSAILTargetLowering::canOpTrap(unsigned Op, EVT VT) const
{
  assert(!"When do we hit this?");
  return false;
}

/// isVectorClearMaskLegal - Similar to isShuffleMaskLegal. This is
/// used by Targets can use this to indicate if there is a suitable
/// VECTOR_SHUFFLE that can be used to replace a VAND with a constant
/// pool entry.
bool
HSAILTargetLowering::isVectorClearMaskLegal(const SmallVectorImpl<int> &Mask,
                                            EVT VT) const
{
  assert(!"When do we hit this?");
  return false;
}

/// getByValTypeAlignment - Return the desired alignment for ByVal aggregate
/// function arguments in the caller parameter area.  This is the actual
/// alignment, not its logarithm.
unsigned
HSAILTargetLowering::getByValTypeAlignment(Type *Ty) const
{
  return TargetLowering::getByValTypeAlignment(Ty);
}

/// ShouldShrinkFPConstant - If true, then instruction selection should
/// seek to shrink the FP constant of the specified type to a smaller type
/// in order to save space and / or reduce runtime.
bool
HSAILTargetLowering::ShouldShrinkFPConstant(EVT VT) const
{
  assert(!"When do we hit this?");
  return false;
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

/// getOptimalMemOpType - Returns the target specific optimal type for load
/// and store operations as a result of memset, memcpy, and memmove
/// lowering. If DstAlign is zero that means it's safe to destination
/// alignment can satisfy any constraint. Similarly if SrcAlign is zero it
/// means there isn't a need to check it against alignment requirement,
/// probably because the source does not need to be loaded. If
/// 'NonScalarIntSafe' is true, that means it's safe to return a
/// non-scalar-integer type, e.g. empty string source, constant, or loaded
/// from memory. 'MemcpyStrSrc' indicates whether the memcpy source is
/// constant so it does not need to be loaded.
/// It returns EVT::Other if the type should be determined using generic
/// target-independent logic.
EVT
HSAILTargetLowering::getOptimalMemOpType(uint64_t Size,
                                         unsigned DstAlign,
                                         unsigned SrcAlign,
                                         bool NonScalarIntSafe,
                                         bool MemcpyStrSrc,
                                         MachineFunction &MF) const
{
  return TargetLowering::getOptimalMemOpType(Size, DstAlign, SrcAlign,
      NonScalarIntSafe, MemcpyStrSrc, MF);
}

/// getPreIndexedAddressParts - returns true by value, base pointer and
/// offset pointer and addressing mode by reference if the node's address
/// can be legally represented as pre-indexed load / store address.
bool
HSAILTargetLowering::getPreIndexedAddressParts(SDNode *N,
                                               SDValue &Base,
                                               SDValue &Offset,
                                               ISD::MemIndexedMode &AM,
                                               SelectionDAG &DAG) const
{
  assert(!"When do we hit this?");
  return false;
}

/// getPostIndexedAddressParts - returns true by value, base pointer and
/// offset pointer and addressing mode by reference if this node can be
/// combined with a load / store to form a post-indexed load / store.
bool
HSAILTargetLowering::getPostIndexedAddressParts(SDNode *N,
                                                SDNode *Op,
                                                SDValue &Base,
                                                SDValue &Offset,
                                                ISD::MemIndexedMode &AM,
                                                SelectionDAG &DAG) const
{
  assert(!"When do we hit this?");
  return false;
}

/// getJumpTableEncoding - Return the entry encoding for a jump table in the
/// current function.  The returned value is a member of the
/// MachineJumpTableInfo::JTEntryKind enum.
unsigned
HSAILTargetLowering::getJumpTableEncoding() const
{
    return MachineJumpTableInfo::EK_BlockAddress;
}

const MCExpr*
HSAILTargetLowering::LowerCustomJumpTableEntry(const MachineJumpTableInfo *MJTI,
                                               const MachineBasicBlock *MBB,
                                               unsigned uid,
                                               MCContext &Ctx) const
{
  assert(!"When do we hit this?");
  return NULL;
}

/// getPICJumpTableRelocaBase - Returns relocation base for the given PIC
/// jumptable.
SDValue
HSAILTargetLowering::getPICJumpTableRelocBase(SDValue Table,
                                              SelectionDAG &DAG) const
{
  assert(!"When do we hit this?");
  return SDValue();
}

/// getPICJumpTableRelocBaseExpr - This returns the relocation base for the
/// given PIC jumptable, the same as getPICJumpTableRelocBase, but as an
/// MCExpr.
const MCExpr*
HSAILTargetLowering::getPICJumpTableRelocBaseExpr(const MachineFunction *MF,
                                                  unsigned JTI,
                                                  MCContext &Ctx) const
{
  assert(!"When do we hit this?");
  return NULL;
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

/// getStackCookieLocation - Return true if the target stores stack
/// protector cookies at a fixed offset in some non-standard address
/// space, and populates the address space and offset as
/// appropriate.
bool
HSAILTargetLowering::getStackCookieLocation(unsigned &AddressSpace,
                                            unsigned &Offset) const
{
  assert(!"When do we hit this?");
  return false;
}

/// getMaximalGlobalOffset - Returns the maximal possible offset which can be
/// used for loads / stores from the global.
unsigned
HSAILTargetLowering::getMaximalGlobalOffset() const
{
  assert(!"When do we hit this?");
  return 0;
}

/// computeMaskedBitsForTargetNode - Determine which of the bits specified in
/// Mask are known to be either zero or one and return them in the
/// KnownZero/KnownOne bitsets.
void
HSAILTargetLowering::computeMaskedBitsForTargetNode(const SDValue Op,
                                                    const APInt &Mask,
                                                    APInt &KnownZero,
                                                    APInt &KnownOne,
                                                    const SelectionDAG &DAG,
                                                    unsigned Depth) const
{
  return TargetLowering::computeMaskedBitsForTargetNode(Op,
       KnownZero, KnownOne, DAG, Depth);
}

/// ComputeNumSignBitsForTargetNode - This method can be implemented by
/// targets that want to expose additional information about sign bits to the
/// DAG Combiner.
unsigned
HSAILTargetLowering::ComputeNumSignBitsForTargetNode(SDValue Op,
                                                     unsigned Depth) const
{
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
  DebugLoc dl = N->getDebugLoc();
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
      return DAG.getNode(ISD::AND, Opr1.getDebugLoc(), Opr1.getValueType(),
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

/// findRepresentativeClass - Return the largest legal super-reg register class
/// of the register class for the specified type and its associated "cost".
std::pair<const TargetRegisterClass*, uint8_t>
HSAILTargetLowering::findRepresentativeClass(EVT VT) const
{
  return TargetLowering::findRepresentativeClass(VT);
}

//===--------------------------------------------------------------------===//
// Lowering methods - These methods must be implemented by targets so that
// the SelectionDAGLowering code knows how to lower these.
//

/*

/// CanLowerReturn - This hook should be implemented to check whether the
/// return values described by the Outs array can fit into the return
/// registers.  If false is returned, an sret-demotion is performed.

bool
HSAILTargetLowering::CanLowerReturn(CallingConv::ID CallConv,
                                    bool isVarArg,
                                    const SmallVectorImpl<ISD::OutputArg> &Outs,
                                    LLVMContext &Context) const
{
  SmallVector<CCValAssign, 16> RVLocs;
  CCState CCInfo(CallConv, isVarArg, getTargetMachine(),
                 RVLocs, Context);
  return CCInfo.CheckReturn(Outs, RetCC_HSAIL);
}

*/

/// n-th element of a vector has different alignment than a base.
/// This function returns alignment for n-th alement.
static unsigned getElementAlignment(const DataLayout *DL, Type *Ty, unsigned n) {
  unsigned Alignment = DL->getABITypeAlignment(Ty);
  if (n) {
    Type* EltTy = Ty->getScalarType();
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
                                 DebugLoc dl,
                                 SelectionDAG &DAG) const
{
  MachineFunction &MF = DAG.getMachineFunction();
  HSAILMachineFunctionInfo *FuncInfo = MF.getInfo<HSAILMachineFunctionInfo>();
  HSAILParamManager &PM = FuncInfo->getParamManager();
  const Function *F = MF.getFunction();
  const FunctionType *funcType = F->getFunctionType();

  SmallVector<SDValue, 6> RetOps;
  RetOps.push_back(Chain); // Operand #0 = Chain (updated below)
  // Operand #1 = Bytes To Pop
  RetOps.push_back(DAG.getTargetConstant(FuncInfo->getBytesToPopOnReturn(),
                                         MVT::i16));

  Type *type  = funcType->getReturnType();
  if(type->getTypeID() != Type::VoidTyID) {
    EVT VT = Outs[0].VT;
    Type* EltTy = type->getScalarType();
    if (EltTy->isIntegerTy(8)) VT = MVT::i8;
    else if (EltTy->isIntegerTy(16)) VT = MVT::i16;
    Mangler Mang(MF.getContext(), *getDataLayout());
    SDValue retVariable =  DAG.getTargetExternalSymbol(PM.getParamName(
      PM.addReturnParam(VT.getStoreSizeInBits(),
      PM.mangleArg(&Mang, F->getName()))), getPointerTy());
    
    // Copy the result values into the output registers.
    
    if (EnableExperimentalFeatures && type->isPointerTy() &&
        (GetOpaqueType(type) == Sampler)) {
      Chain = getArgLoadOrStore(DAG, VT, type, false, false,
                                HSAILAS::ARG_ADDRESS, retVariable,
                                OutVals[0], 0, dl, Chain, SDValue());
    } else {
      MVT PtrTy = getPointerTy(HSAILAS::ARG_ADDRESS);
      PointerType *ArgPT = PointerType::get(EltTy, HSAILAS::ARG_ADDRESS);
      unsigned EltSize = (VT.getStoreSizeInBits() + 7) / 8;
      const VectorType *VecVT = dyn_cast<VectorType>(type);
      unsigned num_elems = VecVT ? VecVT->getNumElements() : 1;
      unsigned Alignment = DL->getABITypeAlignment(type);

      for (unsigned i = 0; i < num_elems; i++) {
        MachinePointerInfo MPtrInfo(UndefValue::get(ArgPT), EltSize * i);
        SDValue R = retVariable;
        unsigned Alignment = getElementAlignment(DL, type, i);

        if (i > 0)
          R = DAG.getNode(ISD::ADD, dl, PtrTy, retVariable,
                          DAG.getConstant(i * EltSize, PtrTy));

        if (EltSize < 4) {
          Chain = DAG.getTruncStore(Chain, dl, OutVals[i], R, MPtrInfo, VT,
                                    false, false, Alignment);
        } else {
          Chain = DAG.getStore(Chain, dl, OutVals[i], R, MPtrInfo,
                               false, false, Alignment);
        }
      }
    }
  }

  RetOps[0] = Chain;  // Update chain.

  return DAG.getNode(HSAILISD::RET_FLAG, dl,
                     MVT::Other, &RetOps[0], RetOps.size());
}

/// isUsedByReturnOnly - Return true if result of the specified node is used
/// by a return node only. This is used to determine whether it is possible
/// to codegen a libcall as tail call at legalization time.
bool
HSAILTargetLowering::isUsedByReturnOnly(SDNode *N) const
{
  assert(!"When do we hit this?");
  return false;
}

//===----------------------------------------------------------------------===//
//                C & StdCall & Fast Calling Convention implementation
//===----------------------------------------------------------------------===//

SDValue
HSAILTargetLowering::LowerMemArgument(SDValue Chain,
                                      CallingConv::ID CallConv,
                                      const SmallVectorImpl<ISD::InputArg> &Ins,
                                      DebugLoc dl, SelectionDAG &DAG,
                                      const CCValAssign &VA,
                                      MachineFrameInfo *MFI,
                                      unsigned i) const
{
  // Create the nodes corresponding to a load from this parameter slot.
  ISD::ArgFlagsTy Flags = Ins[i].Flags;

  bool AlwaysUseMutable = (CallConv==CallingConv::Fast) && getTargetMachine().Options.GuaranteedTailCallOpt;
  bool isImmutable = !AlwaysUseMutable && !Flags.isByVal();

  // In case of tail call optimization mark all arguments mutable. Since they
  // could be overwritten by lowering of arguments in case of a tail call.
  int FI = MFI->CreateFixedObject(VA.getValVT().getSizeInBits()/8,
                                  VA.getLocMemOffset(),
                                  isImmutable);
  SDValue FIN = DAG.getFrameIndex(FI, getPointerTy());

  if (Flags.isByVal())
    return FIN;

  return DAG.getLoad(VA.getValVT(), dl, Chain, FIN,
                     MachinePointerInfo::getFixedStack(FI),
                     false, false,false, 0);
}

static const TargetRegisterClass* getRegClassFromType(unsigned int type) {
  switch (type) {
  default:
    assert(0 && "Passed in type does not match any register classes.");
  case MVT::i1:
    return &HSAIL::CRRegClass;
  case MVT::i32:
  case MVT::f32:
    return &HSAIL::GPR32RegClass;
  case MVT::i64:
  case MVT::f64:
    return &HSAIL::GPR64RegClass;
  }
}


EVT HSAILTargetLowering::getValueType(Type *Ty, bool AllowUnknown ) const
{
    EVT VT = EVT::getEVT(Ty, AllowUnknown);

    if (!EnableExperimentalFeatures)
      return TargetLowering::getValueType(Ty, AllowUnknown);
    
    if (VT != MVT::iPTR)
      return TargetLowering::getValueType(Ty, AllowUnknown);

    OpaqueType OT = GetOpaqueType(Ty);
    if (IsImage(OT) || OT == Sampler)
      return MVT::i64;
    
    return getPointerTy();
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
                                               DebugLoc dl, SDValue Chain,
                                               SDValue InFlag) const
{
    MachineFunction &MF = DAG.getMachineFunction();
    Type* EltTy = Ty->getScalarType();
    MVT PtrTy = getPointerTy(AddressSpace);
    PointerType *ArgPT = PointerType::get(EltTy, AddressSpace);
    uint64_t offset = ((EltTy->getPrimitiveSizeInBits() + 7) / 8) * index;

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
    Brig::BrigTypeX BrigType = Brig::BRIG_TYPE_NONE;
    if (EltTy->isIntegerTy(8))
      op = isLoad ? (isSExt ? HSAIL::arg_sext_ld_s32_s8_v1
                            : HSAIL::arg_zext_ld_u32_u8_v1)
                  : HSAIL::arg_truncst_u32_u8_v1;
    else if (EltTy->isIntegerTy(16))
      op = isLoad ? (isSExt ? HSAIL::arg_sext_ld_s32_s16_v1
                            : HSAIL::arg_zext_ld_u32_u16_v1)
                  : HSAIL::arg_truncst_u32_u16_v1;
    else if (EltTy->isIntegerTy(32))
      op = isLoad ? HSAIL::arg_ld_u32_v1 : HSAIL::arg_st_u32_v1;
    else if (EltTy->isIntegerTy(64))
      op = isLoad ? HSAIL::arg_ld_u64_v1 : HSAIL::arg_st_u64_v1;
    else if (EltTy->isFloatTy())
      op = isLoad ? HSAIL::arg_ld_f32_v1 : HSAIL::arg_st_f32_v1;
    else if (EltTy->isDoubleTy())
      op = isLoad ? HSAIL::arg_ld_f64_v1 : HSAIL::arg_st_f64_v1;
    else if (EltTy->isPointerTy()) {
      if (OpaqueType OT = GetOpaqueType(EltTy)) {
        if (IsImage(OT)) {
          op = isLoad ? HSAIL::ld_arg_64 : HSAIL::st_arg_64;
          BrigType = Brig::BRIG_TYPE_RWIMG;
        }
        else if (OT == Sampler) {
          op = isLoad ? HSAIL::ld_arg_64 : HSAIL::st_arg_64;
          BrigType = Brig::BRIG_TYPE_SAMP;
        }
      }
      if (op == 0) op = Subtarget->is64Bit() ?
                        (isLoad ? HSAIL::arg_ld_u64_v1 : HSAIL::arg_st_u64_v1)
                      : (isLoad ? HSAIL::arg_ld_u32_v1 : HSAIL::arg_st_u32_v1);
    }
    else
      llvm_unreachable("Unhandled type in HSAIL argument lowering");
    assert(op != 0);

    if (AddressSpace == HSAILAS::KERNARG_ADDRESS) {
      switch (op) {
      case HSAIL::arg_sext_ld_s32_s8_v1:  op = HSAIL::kernarg_sext_ld_s32_s8_v1;  break;
      case HSAIL::arg_zext_ld_u32_u8_v1:  op = HSAIL::kernarg_zext_ld_u32_u8_v1;  break;
      case HSAIL::arg_sext_ld_s32_s16_v1: op = HSAIL::kernarg_sext_ld_s32_s16_v1; break;
      case HSAIL::arg_zext_ld_u32_u16_v1: op = HSAIL::kernarg_zext_ld_u32_u16_v1; break;
      case HSAIL::arg_ld_u32_v1: op = HSAIL::kernarg_ld_u32_v1; break;
      case HSAIL::arg_ld_u64_v1: op = HSAIL::kernarg_ld_u64_v1; break;
      case HSAIL::arg_ld_f32_v1: op = HSAIL::kernarg_ld_f32_v1; break;
      case HSAIL::arg_ld_f64_v1: op = HSAIL::kernarg_ld_f64_v1; break;
      }
    }

    unsigned opShift = isLoad ? 1 : 0;
    unsigned opNo = 4; // Value and pointer operands
    SDValue Zero = DAG.getTargetConstant(0, MVT::i32);
    SDValue Ops[] = { ParamValue,
        /* Address */ Ptr, Zero, DAG.getTargetConstant(offset, MVT::i32),
        /* Ops[5]  */ Zero, Zero, Zero, Zero, Zero };
    if (BrigType != Brig::BRIG_TYPE_NONE) {
      Ops[opNo++] = DAG.getTargetConstant((unsigned) BrigType, MVT::i32);
    } else {
      if (isLoad)
        Ops[opNo++] = DAG.getTargetConstant((AddressSpace ==
          HSAILAS::KERNARG_ADDRESS) ? Brig::BRIG_WIDTH_ALL
                                    : Brig::BRIG_WIDTH_1, MVT::i32);

      Ops[opNo++] = DAG.getTargetConstant(alignment, MVT::i32);
      if (isLoad) opNo++; // const = 0, already in the Ops[].
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

    SDNode *ArgNode = DAG.getMachineNode(op, dl, VTs, &Ops[opShift],
                                         opNo - opShift);

    // TODO_HSA: Find a better base pointer for an argument than an UndefValue.
    //           This way we could use vectorization of parameter loads.
    //           A PseudoSourceValue implementation might be suitable,
    //           though it does not provide an address space.
    //           A ConstantNullValue is a good representation of kernarg/
    //           arg segments, though have undesirable effects that we have
    //           to keep track of segment layout with respect to individual
    //           argument's alignment and have cross-parameter vectorization.
    MachinePointerInfo MPtrInfo(UndefValue::get(ArgPT), offset);
    MachineSDNode::mmo_iterator MemOp = MF.allocateMemRefsArray(1);
    MemOp[0] = MF.getMachineMemOperand(MPtrInfo,
      isLoad ? MachineMemOperand::MOLoad : MachineMemOperand::MOStore,
      ArgVT.getStoreSize(), alignment);
    cast<MachineSDNode>(ArgNode)->setMemRefs(MemOp, MemOp + 1);

    return SDValue(ArgNode, 0);
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
                                          DebugLoc dl,
                                          SelectionDAG &DAG,
                                          SmallVectorImpl<SDValue> &InVals) const
{
  MachineFunction &MF = DAG.getMachineFunction();
  HSAILMachineFunctionInfo *FuncInfo = MF.getInfo<HSAILMachineFunctionInfo>();
  HSAILParamManager &PM = FuncInfo->getParamManager();
  const FunctionType *funcType = MF.getFunction()->getFunctionType();
  unsigned int j = 0;
  SDValue InFlag;
  unsigned AS = isKernelFunc(MF.getFunction()) ? HSAILAS::KERNARG_ADDRESS
                                               : HSAILAS::ARG_ADDRESS;
  MVT PtrTy = getPointerTy(AS);

  // Map function param types to Ins.
  SmallVector<const Type*, 16> paramTypes;
  Function::const_arg_iterator AI = MF.getFunction()->arg_begin();
  Function::const_arg_iterator AE = MF.getFunction()->arg_end();
  Mangler Mang(MF.getContext(), *DL);
  for(; AI != AE; ++AI) {
      Type *type = AI->getType();
      Type *sType = type->getScalarType();
      PointerType *ArgPT = PointerType::get(sType, AS);

      EVT argVT = Ins[j].VT;
      if (sType->isIntegerTy(8)) argVT = MVT::i8;
      else if (sType->isIntegerTy(16)) argVT = MVT::i16;

      unsigned Param = PM.addArgumentParam(argVT.getStoreSizeInBits(),
        HSAILParamManager::mangleArg(&Mang, AI->getName()));
      const char* ParamName = PM.getParamName(Param);
      std::string md = (AI->getName() + ":" + ParamName + " ").str();
      FuncInfo->addMetadata("argmap:"+ md, true);
      SDValue ParamValue = DAG.getTargetExternalSymbol(ParamName, PtrTy);
      PM.addParamType(type, Param);
      SDValue ArgValue;

      if (const VectorType *VecVT = dyn_cast<VectorType>(type)) {
        // This assumes that char and short vector elements are unpacked in Ins.
        for (unsigned x = 0, y = VecVT->getNumElements(); x < y; ++x) {
          ArgValue = getArgLoadOrStore(DAG, argVT, type, true,
                                       Ins[j].Flags.isSExt(), AS, ParamValue,
                                       SDValue(), x, dl, Chain, SDValue());
          InVals.push_back(ArgValue);
          j++;
        }
        continue;
      }

      if (type->isPointerTy()) {
        if ( !EnableExperimentalFeatures ) {
          const PointerType *PT = dyn_cast<PointerType>(type);
          Type *CT = PT->getElementType();
          if (const StructType *ST = dyn_cast<StructType>(CT)) {
            OpaqueType OT = GetOpaqueType(ST);
            if (IsImage(OT) || OT == Sampler) {
              // Lower image and sampler kernel arg to image arg handle index. 
              // We bias the values of image_t and sampler_t arg indices so that 
              // we know that index values >= IMAGE_ARG_BIAS represent kernel args. 
              // Note that if either the order of processing for kernel args  
              // or the biasing of index values is changed here, these changes must be 
              // reflected in HSAILPropagateImageOperands.
              unsigned index = 
                Subtarget->getImageHandles()->findOrCreateImageHandle(ParamName);
              index += IMAGE_ARG_BIAS;
              ArgValue = DAG.getConstant((index), MVT::i32);
              InVals.push_back(ArgValue);
              j++;
              continue;
            }
          }
        }  // END !EnableExperimentalFeatures
      }

      // Regular scalar load case.
      ArgValue = getArgLoadOrStore(DAG, argVT, type, true,
                                   Ins[j].Flags.isSExt(), AS, ParamValue,
                                   SDValue(), 0, dl, Chain, SDValue());
      InVals.push_back(ArgValue);
      j++;
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
  DebugLoc &dl                          = CLI.DL;
  SmallVector<ISD::OutputArg, 32> &Outs = CLI.Outs;
  SmallVector<SDValue, 32> &OutVals     = CLI.OutVals;
  SmallVector<ISD::InputArg, 32> &Ins   = CLI.Ins;
  SDValue Chain                         = CLI.Chain;
  SDValue Callee                        = CLI.Callee;
  bool &isTailCall                      = CLI.IsTailCall;
  CallingConv::ID CallConv              = CLI.CallConv;
  bool isVarArg                         = CLI.IsVarArg;

  isTailCall = false;
  MachineFunction& MF = DAG.getMachineFunction();
  HSAILParamManager &PM = MF.getInfo<HSAILMachineFunctionInfo>()->getParamManager();
  Mangler Mang(MF.getContext(), *getDataLayout());
  // FIXME: DO we need to handle fast calling conventions and tail call
  // optimizations?? X86/PPC ISelLowering
  /*bool hasStructRet = (TheCall->getNumArgs())
    ? TheCall->getArgFlags(0).device()->isSRet()
    : false;*/

  MachineFrameInfo *MFI = MF.getFrameInfo();

  unsigned int NumBytes = 0;//CCInfo.getNextStackOffset();
  if (isTailCall) {
    assert(isTailCall && "Tail Call not handled yet!");
    // See X86/PPC ISelLowering
  }

  SDValue CallSeqStart = DAG.getCALLSEQ_START(Chain, DAG.getIntPtrConstant(NumBytes, true));
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
    Callee = DAG.getTargetGlobalAddress(G->getGlobal(), dl, getPointerTy());

    const GlobalValue *GV = G->getGlobal();
    calleeFunc = static_cast<const Function*>(GV);
    funcType = calleeFunc->getFunctionType();
    FuncName = GV->getName().data();
  } 
  else if (ExternalSymbolSDNode *S = dyn_cast<ExternalSymbolSDNode>(Callee)) {
    FuncName = S->getSymbol();
    Callee = DAG.getTargetExternalSymbol(FuncName, getPointerTy());

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
    RetValue = DAG.getTargetExternalSymbol(PM.getParamName(PM.addCallRetParam(
        retType->getPrimitiveSizeInBits(), PM.mangleArg(&Mang, FuncName))),
      getPointerTy(HSAILAS::ARG_ADDRESS));

    const VectorType *VecVT = dyn_cast<VectorType>(retType);

    unsigned BrigType = (unsigned) HSAILgetBrigType(retType,
                                     Subtarget->is64Bit(), CLI.RetSExt);
    if (BrigType == Brig::BRIG_TYPE_B1) BrigType = Brig::BRIG_TYPE_U32; // Store bit as DWORD
    SDValue SDBrigType =  DAG.getTargetConstant(BrigType, MVT::i32);
    SDValue arrSize =  DAG.getTargetConstant(VecVT ? VecVT->getNumElements() : 1, MVT::i32);
    SDValue ArgDeclOps[] = {  RetValue, SDBrigType, arrSize, Chain, InFlag };
    SDNode *ArgDeclNode = DAG.getMachineNode(HSAIL::arg_decl, dl, VTs,
                            ArgDeclOps, InFlag.getNode() ? 5 : 4);
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

  for(FunctionType::param_iterator pb = funcType->param_begin(),
    pe = funcType->param_end(); pb != pe; ++pb, ++ai, ++k) {
    Type *type = *pb;
    EVT VT = Outs[j].VT;

    std::string ParamName;
    if (calleeFunc && ai != ae) {
      ParamName = PM.mangleArg(&Mang, ai->getName());
    }
    if (ParamName.empty()) {
      ParamName = "__param_p";
      ParamName.append(itostr(k));
    }
    SDValue StParamValue = DAG.getTargetExternalSymbol(PM.getParamName(
        PM.addCallArgParam(VT.getStoreSizeInBits(), ParamName)),
      getPointerTy(HSAILAS::ARG_ADDRESS));

    VectorType *VecVT = dyn_cast<VectorType>(type);
    unsigned num_elem = VecVT ? VecVT->getNumElements() : 1;

    // START array parameter declaration
    unsigned BrigType = (unsigned) HSAILgetBrigType(type, Subtarget->is64Bit(),
                                                    Outs[j].Flags.isSExt());
    if (BrigType == Brig::BRIG_TYPE_B1) BrigType = Brig::BRIG_TYPE_U32; // Store bit as DWORD
    SDValue SDBrigType =  DAG.getTargetConstant(BrigType, MVT::i32);
    SDValue arrSize =  DAG.getTargetConstant(num_elem, MVT::i32);
    SDValue ArgDeclOps[] = { StParamValue, SDBrigType, arrSize, Chain, InFlag };
    SDNode *ArgDeclNode = DAG.getMachineNode(HSAIL::arg_decl, dl, VTs,
                            ArgDeclOps, InFlag.getNode() ? 5 : 4);
    SDValue ArgDecl(ArgDeclNode, 0);
    Chain = ArgDecl.getValue(0);
    InFlag = ArgDecl.getValue(1);
    // END array parameter declaration

    VarOps.push_back(StParamValue);

    j += num_elem;
  }

  j = k = 0;
  for(FunctionType::param_iterator pb = funcType->param_begin(),
    pe = funcType->param_end(); pb != pe; ++pb, ++ai, ++k) {
    Type *type = *pb;
    EVT VT = Outs[j].VT;
    VectorType *VecVT = dyn_cast<VectorType>(type);
    unsigned num_elem = VecVT ? VecVT->getNumElements() : 1;
    for(unsigned int x =0; x < num_elem; ++x) {
      Chain = getArgLoadOrStore(DAG, VT, type, false, false,
                                HSAILAS::ARG_ADDRESS, VarOps[FirstArg + k],
                                OutVals[j], x, dl, Chain, InFlag);
      InFlag = Chain.getValue(1);
      j++;
    }
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

  Chain = DAG.getNode(HSAILISD::CALL, dl, VTs, &Ops[0], Ops.size());
  InFlag = Chain.getValue(1);

  // Handle result values, copying them out of physregs into vregs that
  // we return
  Chain = LowerCallResult(Chain, InFlag, Ins, retType, dl, DAG, InVals,
                          RetValue);

  // Create the CALLSEQ_END node
  Chain = DAG.getCALLSEQ_END(Chain,
                             DAG.getIntPtrConstant(NumBytes, true),
                             DAG.getIntPtrConstant(0, true),
                             InFlag);
  return Chain;
}

// LowerCallResult - Lower the result values of an ISD::CALL into the
// appropriate copies out of appropriate physical registers.  This assumes that
// Chain/InFlag are the input chain/flag to use, and that TheCall is the call
// being lowered.  The returns a SDNode with the same number of values as the
// ISD::CALL.
SDValue HSAILTargetLowering::LowerCallResult(SDValue Chain,
                             SDValue& InFlag,
                             const SmallVectorImpl<ISD::InputArg> &Ins,
                             Type *type,
                             DebugLoc dl,
                             SelectionDAG &DAG,
                             SmallVectorImpl<SDValue> &InVals,
                             SDValue retVariable) const
{
  if(Ins.size() > 0) {
    // if size is more than 1, then it must be a vector
    for(unsigned i=0; i != Ins.size(); ++i) {
      SDValue ArgValue = getArgLoadOrStore(DAG, Ins[i].VT, type, true,
                                           Ins[i].Flags.isSExt(),
                                           HSAILAS::ARG_ADDRESS, retVariable,
                                           SDValue(), i, dl, Chain, InFlag);
      Chain  = ArgValue.getValue(1);
      InFlag = ArgValue.getValue(2);
      InVals.push_back(ArgValue);
    }
  }

  return Chain;
}

/// LowerOperationWrapper - This callback is invoked by the type legalizer
/// to legalize nodes with an illegal operand type but legal result types.
/// It replaces the LowerOperation callback in the type Legalizer.
/// The reason we can not do away with LowerOperation entirely is that
/// LegalizeDAG isn't yet ready to use this callback.
/// TODO: Consider merging with ReplaceNodeResults.

/// The target places new result values for the node in Results (their number
/// and types must exactly match those of the original return values of
/// the node), or leaves Results empty, which indicates that the node is not
/// to be custom lowered after all.
/// The default implementation calls LowerOperation.
void
HSAILTargetLowering::LowerOperationWrapper(SDNode *N,
                                           SmallVectorImpl<SDValue> &Results,
                                           SelectionDAG &DAG) const
{
  return TargetLowering::LowerOperationWrapper(N, Results, DAG);
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
  EVT PtrVT = getPointerTy();
  DebugLoc dl = Op.getDebugLoc();
  const GlobalAddressSDNode *GSDN = cast<GlobalAddressSDNode>(Op);
  const GlobalValue *GV = GSDN->getGlobal();
  const Type *ptrType = GV->getType();
  unsigned addrSpace = dyn_cast<PointerType>(ptrType)->getAddressSpace();
  unsigned opcode;

  if (addrSpace == Subtarget->getFlatAS()) {
    opcode = HSAILISD::LDA_FLAT;
  } else if (addrSpace == Subtarget->getGlobalAS()) {
    opcode = HSAILISD::LDA_GLOBAL;
  } else if (addrSpace == Subtarget->getGroupAS()) {
    opcode = HSAILISD::LDA_GROUP;
  } else if (addrSpace == Subtarget->getPrivateAS()) {
    opcode = HSAILISD::LDA_PRIVATE;
  } else if (addrSpace == Subtarget->getConstantAS()) {
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
  DebugLoc dl = Op.getDebugLoc();
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
  DebugLoc dl = Op.getDebugLoc();
  EVT VT = Op.getValueType();

  if (VT != MVT::i1) {
    return Op;
  }
  const SDValue src = Op.getOperand(0).getOperand(0);
  EVT srcVT = src.getValueType();
  if(Op.getOperand(0).getOpcode() != ISD::TRUNCATE) return Op;
  const SDValue dest = Op.getOperand(1);
  EVT dstcVT = dest.getValueType();
  SDValue Zext = DAG.getNode(ISD::ZERO_EXTEND, dl, MVT::i32,Op.getOperand(1));
  SDValue Zext1 = DAG.getNode(ISD::ZERO_EXTEND, dl, srcVT,Op.getOperand(0)); 
  SDValue add_p = DAG.getNode(ISD::ADD, dl, srcVT,Zext1,Zext);
  SDValue Zext2 = DAG.getNode(HSAILISD::TRUNC_B1, dl, VT,add_p);
  return Zext2;
  
}
SDValue 
HSAILTargetLowering::LowerINTRINSIC_W_CHAIN(SDValue Op, SelectionDAG &DAG) const {
  unsigned IntNo = cast<ConstantSDNode>(Op->getOperand(1))->getZExtValue();

  switch (IntNo) {
  default: 
    return Op;
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
    break;
  }

  // Replace sampler operand with index into image handle table
  SDValue ops[16];
  for (unsigned i = 0; i < Op.getNumOperands(); i++) {
    ops[i] = Op.getOperand(i);
  }

  const unsigned SAMPLER_ARG = 3;

  // Detect if sampler operand is an initializer. We do this by extracting 
  // the constant operand and analyzing it. If value of the sampler operand
  // is constant and < IMAGE_ARG_BIAS, then this is a sampler initializer. 
  // Add it to the set of sampler handlers and displace the sampler operand 
  // with a sampler handler index.
  SDValue sampler = Op.getOperand(SAMPLER_ARG);
  unsigned samplerHandleIndex;
  if (isa<ConstantSDNode>(sampler)) {
    unsigned samplerConstant = cast<ConstantSDNode>(sampler)->getZExtValue();
    if (samplerConstant < IMAGE_ARG_BIAS) {
      // This is a sampler initializer.
      // Find or create sampler handle based on init val.
      samplerHandleIndex = 
        Subtarget->getImageHandles()->findOrCreateSamplerHandle(samplerConstant);

      // Actual pointer info is already lost here, all we have is an i32 constant,
      // so we cannot check address space of original pointer. This is done with the
      // check isa<ConstantSDNode>(sampler) above.
      // Provided that this is simply int const we can assume it is not going to be
      // changed, so we could use readonly segment for the sampler.
      // According to OpenCL spec samplers cannot be modified, so that is safe for
      // OpenCL. If we are going to support modifiable or non-OpenCL samplers most
      // likely the whole support code will need change.
      Subtarget->getImageHandles()->getSamplerHandle(samplerHandleIndex)->setRO();

      if (!EnableExperimentalFeatures) {
        ops[SAMPLER_ARG] = DAG.getConstant(samplerHandleIndex, MVT::i32);
      } else {
        // Initialized sampler will be loaded with this intrinsic for 0.98+ hsail spec
        ops[SAMPLER_ARG] = DAG.getNode(ISD::INTRINSIC_WO_CHAIN,
                        Op.getDebugLoc(), sampler.getValueType(),
                        DAG.getConstant(HSAILIntrinsic::HSAIL_ld_readonly_samp,
                        MVT::i32), DAG.getConstant(samplerHandleIndex,
                        MVT::i32));
      }
    }
  }

  DAG.UpdateNodeOperands(Op.getNode(), ops, Op.getNumOperands()),
    Op.getOperand(0).getResNo();

  return Op;
}

SDValue 
HSAILTargetLowering::LowerROTL(SDValue Op, SelectionDAG &DAG) const {
  DebugLoc dl = Op.getDebugLoc();
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
  DebugLoc dl = Op.getDebugLoc();
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
  DebugLoc dl = Op.getDebugLoc();
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
  EVT VT = Op.getValueType();
  DebugLoc dl = Op.getDebugLoc();

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
                     LD->isVolatile(),  LD->isNonTemporal(), 0);

    SDValue Result = DAG.getNode(ISD::TRUNCATE, dl, MVT::i1, NewLD);
    SDValue Ops[] = { Result, SDValue(NewLD.getNode(), 1) };
    return DAG.getMergeValues(Ops, 2, dl);
  }

  // Custom lowering for extload from sub-dword size to i64. We only
  // do it because LLVM currently does not support Expand for EXTLOAD
  // with illegal types.
  // See "EXTLOAD should always be supported!" assert in LegalizeDAG.cpp.
  if (VT.getSimpleVT() != MVT::i64) return Op;
  LoadSDNode *LD = cast<LoadSDNode>(Op.getNode());
  ISD::LoadExtType extType = LD->getExtensionType();
  // Do load into 32-bit register.
  SDValue load = DAG.getLoad(ISD::UNINDEXED, extType, MVT::i32, dl,
    Op.getOperand(0), Op.getOperand(1), Op.getOperand(2),
    LD->getMemoryVT(), LD->getMemOperand());
  // Extend
  SDValue extend;
  switch (extType) {
  case ISD::SEXTLOAD:
   extend = DAG.getSExtOrTrunc(load, dl, MVT::i64); break;
  case ISD::EXTLOAD:
  case ISD::ZEXTLOAD:
    extend = DAG.getZExtOrTrunc(load, dl, MVT::i64); break;
  default:
    llvm_unreachable("Should be processing ext load");
  }
  // Replace chain in all uses.
  DAG.ReplaceAllUsesOfValueWith(Op.getValue(1), load.getValue(1));
  return extend;
}

SDValue HSAILTargetLowering::LowerSTORE(SDValue Op, SelectionDAG &DAG) const {
  assert(Op.getOperand(1).getValueType() == MVT::i1 &&
         "Custom lowering only for i1 stores");
  // Since there are no 1 bit store operations, the store operations are
  // converted to 8 bit stores.
  // First, sign extend to 32 bits, then use a truncating store to 8 bits.

  DebugLoc dl = Op.getDebugLoc();
  StoreSDNode *ST = cast<StoreSDNode>(Op);

  SDValue Chain = ST->getChain();
  SDValue BasePtr = ST->getBasePtr();
  SDValue Value = ST->getValue();
  MachineMemOperand *MMO = ST->getMemOperand();

  Value = DAG.getNode(ISD::SIGN_EXTEND, dl, MVT::i32, Value);
  return DAG.getTruncStore(Chain, dl, Value, BasePtr, MVT::i8, MMO);
}


//===--------------------------------------------------------------------===//
// Inline Asm Support hooks
//

/// ExpandInlineAsm - This hook allows the target to expand an inline asm
/// call to be explicit llvm code if it wants to.  This is useful for
/// turning simple inline asms into LLVM intrinsics, which gives the
/// compiler more information about the behavior of the code.
bool
HSAILTargetLowering::ExpandInlineAsm(CallInst *CI) const
{
  assert(!"When do we hit this?");
  return false;
}

/// ParseConstraints - Split up the constraint string from the inline
/// assembly value into the specific constraints and their prefixes,
/// and also tie in the associated operand values.
/// If this returns an empty vector, and if the constraint string itself
/// isn't empty, there was an error parsing.
TargetLowering::AsmOperandInfoVector
HSAILTargetLowering::ParseConstraints(ImmutableCallSite CS) const
{
  assert(!"When do we hit this?");
  return AsmOperandInfoVector();
}

/// Examine constraint type and operand type and determine a weight value.
/// The operand object must already have been set up with the operand type.
TargetLowering::ConstraintWeight
HSAILTargetLowering::getMultipleConstraintMatchWeight(AsmOperandInfo &info,
                                                      int maIndex) const
{
  assert(!"When do we hit this?");
  return ConstraintWeight();
}

/// Examine constraint string and operand type and determine a weight value.
/// The operand object must already have been set up with the operand type.
TargetLowering::ConstraintWeight
HSAILTargetLowering::getSingleConstraintMatchWeight(AsmOperandInfo &info,
                                                    const char *constraint) const
{
  assert(!"When do we hit this?");
  return ConstraintWeight();
}

/// ComputeConstraintToUse - Determines the constraint code and constraint
/// type to use for the specific AsmOperandInfo, setting
/// OpInfo.ConstraintCode and OpInfo.ConstraintType.  If the actual operand
/// being passed in is available, it can be passed in as Op, otherwise an
/// empty SDValue can be passed.
void
HSAILTargetLowering::ComputeConstraintToUse(AsmOperandInfo &OpInfo,
                                            SDValue Op,
                                            SelectionDAG *DAG) const
{
  assert(!"When do we hit this?");
}

/// getConstraintType - Given a constraint, return the type of constraint it
/// is for this target.
TargetLowering::ConstraintType
HSAILTargetLowering::getConstraintType(const std::string &Constraint) const
{
  assert(!"When do we hit this?");
  return ConstraintType();
}

/*
/// getRegClassForInlineAsmConstraint - Given a constraint letter (e.g. "r"),
/// return a list of registers that can be used to satisfy the constraint.
/// This should only be used for C_RegisterClass constraints.
std::vector<unsigned>
HSAILTargetLowering::getRegClassForInlineAsmConstraint(const std::string &Constraint,
                                                       EVT VT) const
{
  return TargetLowering::getRegClassForInlineAsmConstraint(Constraint, VT);
}
*/

/// getRegForInlineAsmConstraint - Given a physical register constraint (e.g.
/// {edx}), return the register number and the register class for the
/// register.
///
/// Given a register class constraint, like 'r', if this corresponds directly
/// to an LLVM register class, return a register of 0 and the register class
/// pointer.
///
/// This should only be used for C_Register constraints.  On error,
/// this returns a register number of 0 and a null register class pointer..
std::pair<unsigned, const TargetRegisterClass*>
HSAILTargetLowering::getRegForInlineAsmConstraint(const std::string &Constraint,
                                                  EVT VT) const
{
  return TargetLowering::getRegForInlineAsmConstraint(Constraint, VT);
}

/// LowerXConstraint - try to replace an X constraint, which matches anything,
/// with another that has more specific requirements based on the type of the
/// corresponding operand.  This returns null if there is no replacement to
/// make.
const char*
HSAILTargetLowering::LowerXConstraint(EVT ConstraintVT) const
{
  assert(!"When do we hit this?");
  return NULL;
}

/// LowerAsmOperandForConstraint - Lower the specified operand into the Ops
/// vector.  If it is invalid, don't add anything to Ops.
void
HSAILTargetLowering::LowerAsmOperandForConstraint(SDValue Op,
                                                  char ConstraintLetter,
                                                  std::vector<SDValue> &Ops,
                                                  SelectionDAG &DAG) const
{
  assert(!"When do we hit this?");
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
HSAILTargetLowering::isZExtFree(const Type *Ty1, const Type *Ty2) const
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

MVT
HSAILTargetLowering::getShiftAmountTy(EVT LHSTy) const
{
  // Shift amounts in registers must be in S registers
  // Restrict shift amount to 32-bits.
  return MVT::getIntegerVT(32);
}

//
#if 0
void
HSAILTargetLowering::AdjustInstrPostInstrSelection(MachineInstr *MI, SDNode *Node) const
{
  if (hasParametrizedAtomicNoRetVersion(MI, Node))
  {
    if (Node->use_size() <= 1)
    {
      DEBUG(dbgs() << "Replacing atomic ");
      DEBUG(MI->dump());
      DEBUG(dbgs() << " with no return version ");
      const TargetInstrInfo *TII = MI->getParent()->getParent()->getTarget().getInstrInfo();
      // Hack: _noret opcode is always next to corresponding atomic ret opcode in td file
      MI->setDesc(TII->get(MI->getOpcode() + 1));
      MI->RemoveOperand(0);
      DEBUG(MI->dump());
      DEBUG(dbgs() << '\n');
    }
  }
}
#endif

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
