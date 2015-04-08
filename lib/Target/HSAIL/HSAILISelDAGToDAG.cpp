//=- HSAILISelDAGToDAG.cpp - A DAG pattern matching inst selector for HSAIL -=//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines a DAG pattern matching instruction selector for HSAIL,
// converting from a legalized dag to a HSAIL dag.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "hsail-isel"
#include "HSAIL.h"
#include "HSAILBrig.h"
#include "HSAILInstrInfo.h"
#include "HSAILMachineFunctionInfo.h"
#include "HSAILRegisterInfo.h"
#include "HSAILSubtarget.h"
#include "HSAILTargetMachine.h"
#include "HSAILUtilityFunctions.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/CodeGen/MachineConstantPool.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/SelectionDAGISel.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetOptions.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;

//===----------------------------------------------------------------------===//
//                      Pattern Matcher Implementation
//===----------------------------------------------------------------------===//

namespace llvm {
  void initializeHSAILDAGToDAGISelPass(PassRegistry &);
}

namespace {
//===--------------------------------------------------------------------===//
/// ISel - HSAIL specific code to select HSAIL machine instructions for
/// SelectionDAG operations.
///
class HSAILDAGToDAGISel : public SelectionDAGISel {
  /// Subtarget - Keep a pointer to the HSAILSubtarget around so that we can
  /// make the right decision when generating code for different targets.
  const HSAILSubtarget *Subtarget;

public:
  explicit HSAILDAGToDAGISel(HSAILTargetMachine &tm, CodeGenOpt::Level OptLevel)
    : SelectionDAGISel(tm, OptLevel),
      Subtarget(&tm.getSubtarget<HSAILSubtarget>()) {}

  // Default constructor required for Initiallizing PASS
  explicit HSAILDAGToDAGISel()
	: SelectionDAGISel(TM, OptLevel) {}

  const char* getPassName() const override {
    return "HSAIL DAG->DAG Instruction Selection";
  }

  bool IsProfitableToFold(SDValue N, SDNode *U, SDNode *Root) const override;

private:
  SDNode *Select(SDNode *N) override;

  SDNode* SelectINTRINSIC_W_CHAIN(SDNode *Node);
  SDNode* SelectINTRINSIC_WO_CHAIN(SDNode *Node);
  SDNode* SelectAtomic(SDNode *Node, bool bitwise, bool isSigned);
  SDNode* SelectLdKernargIntrinsic(SDNode *Node);
  SDNode* SelectImageIntrinsic(SDNode *Node);
  SDNode *SelectActiveLaneMask(SDNode *Node);
  // Helper for SelectAddrCommon
  // Checks that OR operation is semantically equivalent to ADD
  bool IsOREquivalentToADD(SDValue Op) const;

  bool SelectAddrCommon(SDValue Addr, 
                        SDValue& Base, 
                        SDValue& Reg, 
                        int64_t& Offset, 
                        MVT ValueType,
                        int Depth) const;

  bool
  SelectAddr(SDValue N,
             SDValue &Base,
             SDValue &Reg,
             SDValue &Offset) const;

  bool SelectLoadAddr(SDNode *ParentLoad,
                      SDValue Addr,
                      SDValue &Base,
                      SDValue &Reg,
                      SDValue &Offset,
                      SDValue &Segment,
                      SDValue &Align,
                      SDValue &Type,
                      SDValue &Width,
                      SDValue &ModifierMask) const;

  bool SelectStoreAddr(SDNode *ParentStore,
                       SDValue Addr,
                       SDValue &Base,
                       SDValue &Reg,
                       SDValue &Offset,
                       SDValue &Segment,
                       SDValue &Align,
                       /*SDValue &Equiv,*/
                       SDValue &Type) const;

  bool SelectAtomicAddr(SDNode *ParentLoad,
                        SDValue Addr,
                        SDValue &Segment,
                        SDValue &Order,
                        SDValue &Scope,
                        SDValue &Equiv,

                        SDValue &Base,
                        SDValue &Reg,
                        SDValue &Offset) const;

  void SelectAddrSpaceCastCommon(const AddrSpaceCastSDNode &ASC,
                                 SDValue &NoNull,
                                 SDValue &Ptr,
                                 SDValue &DestType,
                                 SDValue &SrcType) const;

  bool SelectSTOF(SDValue Cast,
                  SDValue &Segment,
                  SDValue &NoNull,
                  SDValue &Ptr,
                  SDValue &DestType,
                  SDValue &SrcType) const;

  bool SelectFTOS(SDValue Cast,
                  SDValue &Segment,
                  SDValue &NoNull,
                  SDValue &Ptr,
                  SDValue &DestType,
                  SDValue &SrcType) const;

  bool SelectSetCC(SDValue SetCC,
                   SDValue &LHS,
                   SDValue &RHS,
                   SDValue &CmpOp,
                   SDValue &FTZ,
                   SDValue &DestType,
                   SDValue &SrcType) const;

  bool SelectGPROrImm(SDValue In, SDValue &Src) const;
  bool MemOpHasPtr32(SDNode *N) const;

  bool isKernelFunc(void) const;
  // Include the pieces autogenerated from the target description.
#include "HSAILGenDAGISel.inc"

};

}

  // Register pass in passRegistry so that the pass info gets populated for printing debug info 
  INITIALIZE_PASS(HSAILDAGToDAGISel, "hsail-isel",
                "HSAIL DAG->DAG Instruction Selection", false, false)			
bool
HSAILDAGToDAGISel::IsProfitableToFold(SDValue N,
                                      SDNode *U,
                                      SDNode *Root) const
{
  return true;
}


bool HSAILDAGToDAGISel::SelectGPROrImm(SDValue In, SDValue &Src) const {
  if (ConstantSDNode *C = dyn_cast<ConstantSDNode>(In))
    Src = CurDAG->getTargetConstant(C->getAPIntValue(), C->getValueType(0));
  else if (ConstantFPSDNode *C = dyn_cast<ConstantFPSDNode>(In))
    Src = CurDAG->getTargetConstantFP(C->getValueAPF(), C->getValueType(0));
  else
    Src = In;

  return true;
}

bool
HSAILDAGToDAGISel::isKernelFunc() const
{
  const MachineFunction &MF = CurDAG->getMachineFunction();
  return HSAIL::isKernelFunc(MF.getFunction());
}

static unsigned getImageInstr(HSAILIntrinsic::ID intr)
{
    switch(intr){
      default: llvm_unreachable("unexpected intrinsinc ID for images");
    case HSAILIntrinsic::HSAIL_rd_imgf_1d_f32: return HSAIL::rd_imgf_1d_f32;
    case HSAILIntrinsic::HSAIL_rd_imgf_1d_s32: return HSAIL::rd_imgf_1d_s32;
    case HSAILIntrinsic::HSAIL_rd_imgf_1da_f32: return HSAIL::rd_imgf_1da_f32;
    case HSAILIntrinsic::HSAIL_rd_imgf_1da_s32: return HSAIL::rd_imgf_1da_s32;
    case HSAILIntrinsic::HSAIL_rd_imgf_2d_f32: return HSAIL::rd_imgf_2d_f32;
    case HSAILIntrinsic::HSAIL_rd_imgf_2d_s32: return HSAIL::rd_imgf_2d_s32;
    case HSAILIntrinsic::HSAIL_rd_imgf_2da_f32: return HSAIL::rd_imgf_2da_f32;
    case HSAILIntrinsic::HSAIL_rd_imgf_2da_s32: return HSAIL::rd_imgf_2da_s32;
    case HSAILIntrinsic::HSAIL_rd_imgf_3d_f32: return HSAIL::rd_imgf_3d_f32;
    case HSAILIntrinsic::HSAIL_rd_imgf_3d_s32: return HSAIL::rd_imgf_3d_s32;
    case HSAILIntrinsic::HSAIL_rd_imgi_1d_f32: return HSAIL::rd_imgi_1d_f32;
    case HSAILIntrinsic::HSAIL_rd_imgi_1d_s32: return HSAIL::rd_imgi_1d_s32;
    case HSAILIntrinsic::HSAIL_rd_imgi_1da_f32: return HSAIL::rd_imgi_1da_f32;
    case HSAILIntrinsic::HSAIL_rd_imgi_1da_s32: return HSAIL::rd_imgi_1da_s32;
    case HSAILIntrinsic::HSAIL_rd_imgi_2d_f32: return HSAIL::rd_imgi_2d_f32;
    case HSAILIntrinsic::HSAIL_rd_imgi_2d_s32: return HSAIL::rd_imgi_2d_s32;
    case HSAILIntrinsic::HSAIL_rd_imgi_2da_f32: return HSAIL::rd_imgi_2da_f32;
    case HSAILIntrinsic::HSAIL_rd_imgi_2da_s32: return HSAIL::rd_imgi_2da_s32;
    case HSAILIntrinsic::HSAIL_rd_imgi_3d_f32: return HSAIL::rd_imgi_3d_f32;
    case HSAILIntrinsic::HSAIL_rd_imgi_3d_s32: return HSAIL::rd_imgi_3d_s32;
    case HSAILIntrinsic::HSAIL_rd_imgui_1d_f32: return HSAIL::rd_imgui_1d_f32;
    case HSAILIntrinsic::HSAIL_rd_imgui_1d_s32: return HSAIL::rd_imgui_1d_s32;
    case HSAILIntrinsic::HSAIL_rd_imgui_1da_f32: return HSAIL::rd_imgui_1da_f32;
    case HSAILIntrinsic::HSAIL_rd_imgui_1da_s32: return HSAIL::rd_imgui_1da_s32;
    case HSAILIntrinsic::HSAIL_rd_imgui_2d_f32: return HSAIL::rd_imgui_2d_f32;
    case HSAILIntrinsic::HSAIL_rd_imgui_2d_s32: return HSAIL::rd_imgui_2d_s32;
    case HSAILIntrinsic::HSAIL_rd_imgui_2da_f32: return HSAIL::rd_imgui_2da_f32;
    case HSAILIntrinsic::HSAIL_rd_imgui_2da_s32: return HSAIL::rd_imgui_2da_s32;
    case HSAILIntrinsic::HSAIL_rd_imgui_3d_f32: return HSAIL::rd_imgui_3d_f32;
    case HSAILIntrinsic::HSAIL_rd_imgui_3d_s32: return HSAIL::rd_imgui_3d_s32;
    case HSAILIntrinsic::HSAIL_rd_imgf_2ddepth_f32: return HSAIL::rd_imgf_2ddepth_f32;
    case HSAILIntrinsic::HSAIL_rd_imgf_2ddepth_s32: return HSAIL::rd_imgf_2ddepth_s32;
    case HSAILIntrinsic::HSAIL_rd_imgf_2dadepth_f32: return HSAIL::rd_imgf_2dadepth_f32;
    case HSAILIntrinsic::HSAIL_rd_imgf_2dadepth_s32: return HSAIL::rd_imgf_2dadepth_s32;

    case HSAILIntrinsic::HSAIL_ld_imgf_1d_u32: return HSAIL::ld_imgf_1d_u32;
    case HSAILIntrinsic::HSAIL_ld_imgf_1da_u32: return HSAIL::ld_imgf_1da_u32;
    case HSAILIntrinsic::HSAIL_ld_imgf_1db_u32: return HSAIL::ld_imgf_1db_u32;
    case HSAILIntrinsic::HSAIL_ld_imgf_2d_u32: return HSAIL::ld_imgf_2d_u32;
    case HSAILIntrinsic::HSAIL_ld_imgf_2da_u32: return HSAIL::ld_imgf_2da_u32;
    case HSAILIntrinsic::HSAIL_ld_imgf_3d_u32: return HSAIL::ld_imgf_3d_u32;
    case HSAILIntrinsic::HSAIL_ld_imgi_1d_u32: return HSAIL::ld_imgi_1d_u32;
    case HSAILIntrinsic::HSAIL_ld_imgi_1da_u32: return HSAIL::ld_imgi_1da_u32;
    case HSAILIntrinsic::HSAIL_ld_imgi_1db_u32: return HSAIL::ld_imgi_1db_u32;
    case HSAILIntrinsic::HSAIL_ld_imgi_2d_u32: return HSAIL::ld_imgi_2d_u32;
    case HSAILIntrinsic::HSAIL_ld_imgi_2da_u32: return HSAIL::ld_imgi_2da_u32;
    case HSAILIntrinsic::HSAIL_ld_imgi_3d_u32: return HSAIL::ld_imgi_3d_u32;
    case HSAILIntrinsic::HSAIL_ld_imgui_1d_u32: return HSAIL::ld_imgui_1d_u32;
    case HSAILIntrinsic::HSAIL_ld_imgui_1da_u32: return HSAIL::ld_imgui_1da_u32;
    case HSAILIntrinsic::HSAIL_ld_imgui_1db_u32: return HSAIL::ld_imgui_1db_u32;
    case HSAILIntrinsic::HSAIL_ld_imgui_2d_u32: return HSAIL::ld_imgui_2d_u32;
    case HSAILIntrinsic::HSAIL_ld_imgui_2da_u32: return HSAIL::ld_imgui_2da_u32;
    case HSAILIntrinsic::HSAIL_ld_imgui_3d_u32: return HSAIL::ld_imgui_3d_u32;
    case HSAILIntrinsic::HSAIL_ld_imgf_2ddepth_u32: return HSAIL::ld_imgf_2ddepth_u32;
    case HSAILIntrinsic::HSAIL_ld_imgf_2dadepth_u32: return HSAIL::ld_imgf_2dadepth_u32;
  }
}

SDNode* HSAILDAGToDAGISel::SelectINTRINSIC_W_CHAIN(SDNode *Node)
{
  unsigned IntNo = cast<ConstantSDNode>(Node->getOperand(1))->getZExtValue();
  if (HSAILIntrinsicInfo::isReadImage((HSAILIntrinsic::ID)IntNo) ||
      HSAILIntrinsicInfo::isLoadImage((HSAILIntrinsic::ID)IntNo ))
    return SelectImageIntrinsic(Node);
  if (IntNo == HSAILIntrinsic::HSAIL_ld_kernarg_u32 ||
      IntNo == HSAILIntrinsic::HSAIL_ld_kernarg_u64)
    return SelectLdKernargIntrinsic(Node);

  return SelectCode(Node);
}

SDNode* HSAILDAGToDAGISel::SelectINTRINSIC_WO_CHAIN(SDNode *Node)
{
  unsigned IntNo = cast<ConstantSDNode>(Node->getOperand(0))->getZExtValue();
  if (IntNo == HSAILIntrinsic::HSAIL_ld_kernarg_u32 ||
      IntNo == HSAILIntrinsic::HSAIL_ld_kernarg_u64)
    return SelectLdKernargIntrinsic(Node);

  return SelectCode(Node);
}

SDNode* HSAILDAGToDAGISel::SelectImageIntrinsic(SDNode *Node)
{
  SDValue Chain = Node->getOperand(0);
  SDNode *ResNode;

  unsigned IntNo = cast<ConstantSDNode>(Node->getOperand(1))->getZExtValue();
  bool hasSampler = false;

  if (IntNo == HSAILIntrinsic::HSAIL_rd_imgf_1d_s32) {
    const SDValue Ops[] = {
      CurDAG->getTargetConstant(1, MVT::i1),                 // v4
      CurDAG->getTargetConstant(BRIG_TYPE_ROIMG, MVT::i32),  // imageType
      CurDAG->getTargetConstant(BRIG_TYPE_S32, MVT::i32),    // coordType
      CurDAG->getTargetConstant(BRIG_GEOMETRY_1D, MVT::i32), // geometry
      CurDAG->getTargetConstant(0, MVT::i32),                // equiv
      Node->getOperand(2),                                   // image
      Node->getOperand(3),                                   // sampler
      Node->getOperand(4),                                   // coordWidth
      CurDAG->getTargetConstant(BRIG_TYPE_F32, MVT::i32),    // destType
      Chain
    };

    return CurDAG->SelectNodeTo(Node, HSAIL::RDIMAGE,
                                Node->getVTList(), Ops);
  }

  if (HSAILIntrinsicInfo::isReadImage((HSAILIntrinsic::ID)IntNo)) {
    hasSampler = true;
  } else if (!HSAILIntrinsicInfo::isLoadImage((HSAILIntrinsic::ID)IntNo)) {
    return SelectCode(Node);
  }

  if ( ((HSAILIntrinsic::ID)IntNo) == (HSAILIntrinsic::HSAIL_rd_imgf_2ddepth_f32)
      || ((HSAILIntrinsic::ID)IntNo) == (HSAILIntrinsic::HSAIL_rd_imgf_2ddepth_s32)
        || ((HSAILIntrinsic::ID)IntNo) == (HSAILIntrinsic::HSAIL_ld_imgf_2ddepth_u32)
          || ((HSAILIntrinsic::ID)IntNo) == (HSAILIntrinsic::HSAIL_rd_imgf_2dadepth_f32)
            || ((HSAILIntrinsic::ID)IntNo) == (HSAILIntrinsic::HSAIL_rd_imgf_2dadepth_s32)
              || ((HSAILIntrinsic::ID)IntNo) == (HSAILIntrinsic::HSAIL_ld_imgf_2dadepth_u32) ) {
    assert(Node->getNumValues() == 2);
  } else {
    assert(Node->getNumValues() == 5);
  }
  SmallVector<SDValue, 6> NewOps;

  unsigned OpIndex = 2;

    SDValue Img = Node->getOperand(OpIndex++);
    int ResNo = Img.getResNo();
    SDValue ImgHandle = Img.getValue(ResNo);
    NewOps.push_back(ImgHandle);

    if (hasSampler) {
      SDValue Smp = Node->getOperand(OpIndex++);
      SDValue SmpHandle = Smp.getValue(Smp.getResNo());
      NewOps.push_back(SmpHandle);
    }

  while (OpIndex < Node->getNumOperands()) {
    SDValue Coord = Node->getOperand(OpIndex++);
    NewOps.push_back(Coord);
  }

  NewOps.push_back(Chain);

  ResNode = CurDAG->SelectNodeTo(Node, getImageInstr((HSAILIntrinsic::ID)IntNo),
                                 Node->getVTList(), NewOps);
  return ResNode;
}

SDNode *HSAILDAGToDAGISel::SelectActiveLaneMask(SDNode *Node) {
  SDValue Ops[] = {
    Node->getOperand(1), // width
    Node->getOperand(2), // src0
    CurDAG->getTargetConstant(BRIG_TYPE_B64, MVT::i32), // TypeLength
    CurDAG->getTargetConstant(BRIG_TYPE_B1, MVT::i32),  // sourceType
    Node->getOperand(0) // Chain
  };

  SelectGPROrImm(Ops[1], Ops[1]);

  return CurDAG->SelectNodeTo(Node, HSAIL::ACTIVELANEMASK, Node->getVTList(), Ops);
}

SDNode* HSAILDAGToDAGISel::SelectLdKernargIntrinsic(SDNode *Node) {
  MachineFunction &MF = CurDAG->getMachineFunction();
  HSAILMachineFunctionInfo *FuncInfo = MF.getInfo<HSAILMachineFunctionInfo>();
  HSAILParamManager &PM = FuncInfo->getParamManager();
  bool hasChain = Node->getNumOperands() > 2;
  unsigned opShift = hasChain ? 1 : 0;
  const HSAILTargetLowering *TL
    = static_cast<const HSAILTargetLowering *>(getTargetLowering());

  EVT VT = Node->getValueType(0);
  Type *Ty = Type::getIntNTy(*CurDAG->getContext(), VT.getSizeInBits());
  SDValue Addr = Node->getOperand(1 + opShift);
  int64_t offset = 0;
  MVT PtrTy = TL->getPointerTy(HSAILAS::KERNARG_ADDRESS);
  AAMDNodes ArgMD; // FIXME: What is this for?
  if (isa<ConstantSDNode>(Addr)) {
    offset = Node->getConstantOperandVal(1 + opShift);
    // Match a constant address argument to the parameter through functions's
    // argument map (taking argument alignment into account).
    // Match is not possible if we are accesing beyond a known kernel argument
    // space, if we accessing from a non-inlined function, or if there is an
    // opaque argument with unknwon size before requested offset.
    unsigned param = UINT_MAX;
    if (isKernelFunc())
      param = PM.getParamByOffset(offset);
    if (param != UINT_MAX) {
      Addr = CurDAG->getTargetExternalSymbol(PM.getParamName(param), PtrTy);
      //Value *mdops[] = { const_cast<Argument*>(PM.getParamArg(param)) };
      //ArgMD = MDNode::get(MF.getFunction()->getContext(), mdops);
    } else {
      Addr = SDValue();
    }
  }

  SDValue Chain = hasChain ? Node->getOperand(0) : CurDAG->getEntryNode();
  return TL->getArgLoadOrStore(*CurDAG, VT, Ty, true, false,
                               HSAILAS::KERNARG_ADDRESS, Addr,
                               SDValue(), 0, SDLoc(Node),
                               Chain, SDValue(), ArgMD, offset).getNode();
}

static SDValue getBRIGMemorySegment(SelectionDAG *CurDAG,
                                    unsigned memSeg) {
  unsigned BRIGMemSegment;
  switch(memSeg) {
    case llvm::HSAILAS::GLOBAL_ADDRESS:
        BRIGMemSegment = BRIG_SEGMENT_GLOBAL; break;
    case llvm::HSAILAS::GROUP_ADDRESS:
        BRIGMemSegment = BRIG_SEGMENT_GROUP; break;
    case llvm::HSAILAS::FLAT_ADDRESS:
        BRIGMemSegment = BRIG_SEGMENT_FLAT; break;
    default: llvm_unreachable("unexpected memory segment ");
  }
  SDValue memSegSD = CurDAG->getTargetConstant(BRIGMemSegment,
                                               MVT::getIntegerVT(32));
  return memSegSD;
}

#if 0
static SDValue getBRIGMemoryOrder(SelectionDAG *CurDAG,
                                  AtomicOrdering memOrder) {
  unsigned BRIGMemOrder;
  switch(memOrder) {
    case Monotonic: BRIGMemOrder = BRIG_MEMORY_ORDER_RELAXED;break;
    case Acquire: BRIGMemOrder = BRIG_MEMORY_ORDER_SC_ACQUIRE;break;
    case Release: BRIGMemOrder = BRIG_MEMORY_ORDER_SC_RELEASE;break;
    case AcquireRelease:
    case SequentiallyConsistent: // atomic_load and atomic_store with SC
                                 // are custom lowered
                  BRIGMemOrder = BRIG_MEMORY_ORDER_SC_ACQUIRE_RELEASE; break;
    default: llvm_unreachable("unexpected memory order");
  }
  SDValue memOrderSD = CurDAG->getTargetConstant(BRIGMemOrder,
                                                 MVT::getIntegerVT(32));
  return memOrderSD;
}

static SDValue getBRIGAtomicOpcode(SelectionDAG *CurDAG,
                                   unsigned atomicOp) {
  unsigned BRIGAtomicOp;
  switch(atomicOp) {
    case ISD::ATOMIC_LOAD_ADD: BRIGAtomicOp = BRIG_ATOMIC_ADD; break;
    case ISD::ATOMIC_LOAD_SUB: BRIGAtomicOp = BRIG_ATOMIC_SUB; break;
    case ISD::ATOMIC_LOAD_OR:  BRIGAtomicOp = BRIG_ATOMIC_OR; break;
    case ISD::ATOMIC_LOAD_XOR: BRIGAtomicOp = BRIG_ATOMIC_XOR; break;
    case ISD::ATOMIC_LOAD_AND: BRIGAtomicOp = BRIG_ATOMIC_AND; break;
    case ISD::ATOMIC_LOAD_MAX:
    case ISD::ATOMIC_LOAD_UMAX:
                               BRIGAtomicOp = BRIG_ATOMIC_MAX; break;
    case ISD::ATOMIC_LOAD_MIN:
    case ISD::ATOMIC_LOAD_UMIN:
                               BRIGAtomicOp = BRIG_ATOMIC_MIN; break;
    case ISD::ATOMIC_LOAD:     BRIGAtomicOp = BRIG_ATOMIC_LD; break;
    case ISD::ATOMIC_STORE:    BRIGAtomicOp = BRIG_ATOMIC_ST; break;
    case ISD::ATOMIC_SWAP:     BRIGAtomicOp = BRIG_ATOMIC_EXCH; break;
    case ISD::ATOMIC_CMP_SWAP: BRIGAtomicOp = BRIG_ATOMIC_CAS; break;
    default: llvm_unreachable("unexpected atomic op");
  }
  SDValue atomicOpSD = CurDAG->getTargetConstant(BRIGAtomicOp,
                                                 MVT::getIntegerVT(32));
  return atomicOpSD;
}

static bool TypeIs32Bit(const MemSDNode *M) {
  unsigned size = M->getMemoryVT().getSizeInBits();
  if (size == 32) return true;
  assert(size == 64);
  return false;
}

/// Select atomic opcode based on
/// size of the compare operand and its addressing mode
static unsigned getHSAILAtomicCasOpcode (const MemSDNode *Node) {
  bool immOp1 = Node->getOperand(2).getOpcode() == ISD::Constant;
  bool immOp2 = Node->getOperand(3).getOpcode() == ISD::Constant;

  if (TypeIs32Bit(Node)) {
    return immOp1 ?
           immOp2 ? HSAIL::atomic_b32_ternary_ii_ret : HSAIL::atomic_b32_ternary_ir_ret :
           immOp2 ? HSAIL::atomic_b32_ternary_ri_ret : HSAIL::atomic_b32_ternary_rr_ret;
  }

    return immOp1 ?
         immOp2 ? HSAIL::atomic_b64_ternary_ii_ret : HSAIL::atomic_b64_ternary_ir_ret :
         immOp2 ? HSAIL::atomic_b64_ternary_ri_ret : HSAIL::atomic_b64_ternary_rr_ret;
}

/// Select atomic opcode based on
/// size of the operand, its addressing mode and signedness
static unsigned getHSAILAtomicRMWOpcode(const MemSDNode *Node) {
  bool immOp = Node->getOperand(2).getOpcode() == ISD::Constant;

  if (TypeIs32Bit(Node))
    return immOp ? HSAIL::atomic_b32_binary_i_ret :
                   HSAIL::atomic_b32_binary_r_ret;

  return immOp ? HSAIL::atomic_b64_binary_i_ret:
                 HSAIL::atomic_b64_binary_r_ret;
}

/// Select atomic opcode based on size of the loaded value
static unsigned getHSAILAtomicLoadOpcode (const MemSDNode *Node) {
  if (TypeIs32Bit(Node)) return HSAIL::atomic_b32_unary;
  return HSAIL::atomic_b64_unary;
}

/// Select atomic opcode based on
/// size of the value to be stored and its addressing mode
static unsigned getHSAILAtomicStoreOpcode (const MemSDNode *Node) {
  bool immOp = Node->getOperand(2).getOpcode() == ISD::Constant;

  if (TypeIs32Bit(Node))
    return immOp ? HSAIL::atomic_b32_binary_i_noret :
                   HSAIL::atomic_b32_binary_r_noret;

  return immOp ? HSAIL::atomic_b64_binary_i_noret :
                 HSAIL::atomic_b64_binary_r_noret;
}

static int getHSAILAtomicOpcode(const MemSDNode *Node) {
  int opcode = -1;
  switch (Node->getOpcode()) {
    case ISD::ATOMIC_LOAD:
      opcode = getHSAILAtomicLoadOpcode(Node);
      break;
    case ISD::ATOMIC_STORE:
      opcode = getHSAILAtomicStoreOpcode(Node);
      break;
    case ISD::ATOMIC_LOAD_ADD:
    case ISD::ATOMIC_LOAD_SUB:
    case ISD::ATOMIC_LOAD_AND:
    case ISD::ATOMIC_LOAD_OR:
    case ISD::ATOMIC_LOAD_XOR:
    case ISD::ATOMIC_LOAD_MAX:
    case ISD::ATOMIC_LOAD_UMAX:
    case ISD::ATOMIC_LOAD_MIN:
    case ISD::ATOMIC_LOAD_UMIN:
    case ISD::ATOMIC_SWAP:
      opcode = getHSAILAtomicRMWOpcode(Node);
      break;
    case ISD::ATOMIC_CMP_SWAP:
      opcode = getHSAILAtomicCasOpcode(Node);
      break;
    default: llvm_unreachable("unknown atomic SDNode");
  }

  if (MemOpHasPtr32(Node)) {
    opcode = HSAIL::getAtomicPtr32Version(opcode);
    assert(opcode != -1);
  }

  return opcode;
}

static SDValue getBRIGTypeForAtomic(SelectionDAG *CurDAG,
                                    bool is32bit, bool bitwise,
                                    bool isSigned) {
  unsigned BrigType;
  if (is32bit) {
    if (bitwise) BrigType = BRIG_TYPE_B32;
    else if (isSigned) BrigType = BRIG_TYPE_S32;
    else BrigType = BRIG_TYPE_U32;
  } else {
    if (bitwise) BrigType = BRIG_TYPE_B64;
    else if (isSigned) BrigType = BRIG_TYPE_S64;
    else BrigType = BRIG_TYPE_U64;
  }

  return CurDAG->getTargetConstant(BrigType, MVT::getIntegerVT(32));
}

static SDValue getBRIGMemoryScope(SelectionDAG *CurDAG,
                                  MemSDNode *Mn) {
  unsigned brigMemScopeVal = BRIG_MEMORY_SCOPE_WORKGROUP;
  if (Mn->getAddressSpace() != HSAILAS::GROUP_ADDRESS)
    brigMemScopeVal = Mn->getMemoryScope();

  return CurDAG->getTargetConstant(brigMemScopeVal, MVT::getIntegerVT(32));
}

/// \brief Select the appropriate MI for AtomicSDNode
///
/// Machine instructions for atomics are paramenterized with
/// additional BRIG operands along with the SDNode operands:
///
/// <atomic opcode, address space, memory order, memory scope, brig type>
///
/// For example, atomic_add_global_rlx_wg_s32 with an immediate
/// operand src0 is encoded as:
///
/// atomic_b32_binary_b32_i BRIG_ATOMIC_ADD,
///                         BRIG_SEGMENT_GLOBAL,
///                         BRIG_MEMORY_ORDER_RELAXED,
///                         BRIG_MEMORY_SCOPE_WORKGROUP,
///                         BRIG_TYPE_S32,
///                         ptr, src0
///
/// This helps reduce the number of MI's for atomics in the backend.
/// In BRIGAsmPrinter, these MI's are decoded into the appropriate
/// BRIG instructions.
///
/// BRIG type is "b" if bitwise is true, else isSigned indicates
/// whether it is "s" or "u".
SDNode* HSAILDAGToDAGISel::SelectAtomic(SDNode *Node,
                                        bool bitwise, bool isSigned)
{
  MachineFunction &MF = CurDAG->getMachineFunction();
  SDValue Chain = Node->getOperand(0);
  SDLoc dl(Node);
  SDNode *ResNode;
  MemSDNode *Mn = cast<MemSDNode>(Node);
  SDValue memOrder = getBRIGMemoryOrder(CurDAG, Mn->getOrdering());
  SDValue memScope = getBRIGMemoryScope(CurDAG, Mn);
  SDValue atomicOpcode = getBRIGAtomicOpcode(CurDAG, Node->getOpcode());
  SDValue addrSpace = getBRIGMemorySegment(CurDAG, Mn->getAddressSpace());
  SDValue brigType = getBRIGTypeForAtomic(CurDAG, TypeIs32Bit(Mn),
                                          bitwise, isSigned);
  SmallVector<SDValue, 10> NewOps;
  SDValue Base, Reg, Offset;

  SelectAddr(Node->getOperand(1), Base, Reg, Offset);

  NewOps.push_back(atomicOpcode);
  NewOps.push_back(addrSpace);
  NewOps.push_back(memOrder);
  NewOps.push_back(memScope);
  NewOps.push_back(brigType);
  NewOps.push_back(Base);
  NewOps.push_back(Reg);
  NewOps.push_back(Offset);
  for (unsigned i = 2;i < Node->getNumOperands();i++)
    NewOps.push_back(Node->getOperand(i));
  NewOps.push_back(Chain);

  ResNode = CurDAG->SelectNodeTo(Node, getHSAILAtomicOpcode(Mn),
                                 Node->getVTList(),
                                 NewOps.data(), NewOps.size());

  MachineSDNode::mmo_iterator MemOp = MF.allocateMemRefsArray(1);
  MemOp[0] = Mn->getMemOperand();
  MemOp[0]->setOffset(cast<ConstantSDNode>(Offset.getNode())->getSExtValue());
  cast<MachineSDNode>(ResNode)->setMemRefs(MemOp, MemOp + 1);

  return ResNode;
}
#endif

SDNode*
HSAILDAGToDAGISel::Select(SDNode *Node)
{
  assert(Node);

  EVT NVT = Node->getValueType(0);
  unsigned Opcode = Node->getOpcode();
  SDNode *ResNode;

  DEBUG(dbgs() << "Selecting: "; Node->dump(CurDAG); dbgs() << '\n');

  if (Node->isMachineOpcode()) {
    DEBUG(dbgs() << "== ";  Node->dump(CurDAG); dbgs() << '\n');
    return NULL;   // Already selected.
  }

  switch (Opcode) {
  default:
    ResNode = SelectCode(Node);
    break;
  case ISD::FrameIndex: {
    if (FrameIndexSDNode *FIN = dyn_cast<FrameIndexSDNode>(Node)) {
      SDValue Ops[] = {
        CurDAG->getTargetConstant(HSAILAS::PRIVATE_ADDRESS, MVT::i32),
        CurDAG->getTargetFrameIndex(FIN->getIndex(), MVT::i32),
        CurDAG->getRegister(0, NVT),
        CurDAG->getTargetConstant(0, NVT),
        CurDAG->getTargetConstant(BRIG_TYPE_U32, MVT::i32)
      };

      ResNode = CurDAG->SelectNodeTo(Node, HSAIL::LDA, NVT, Ops);
    } else {
      ResNode = Node;
    }
    break;
  }
  case ISD::GlobalAddress: {
    const GlobalAddressSDNode *GSDN = cast<GlobalAddressSDNode>(Node);
    const GlobalValue *GV = GSDN->getGlobal();
    EVT PtrVT = Node->getValueType(0);
    unsigned AS = GSDN->getAddressSpace();
    SDLoc SL(Node);

    BrigType BT
      = (PtrVT == MVT::i32) ? BRIG_TYPE_U32 : BRIG_TYPE_U64;

    const SDValue Ops[] = {
      CurDAG->getTargetConstant(AS, MVT::i32),
      CurDAG->getTargetGlobalAddress(GV, SL, PtrVT, 0),
      CurDAG->getRegister(HSAIL::NoRegister, NVT),
      CurDAG->getTargetConstant(GSDN->getOffset(), PtrVT),
      CurDAG->getTargetConstant(BT, MVT::i32)
    };

    ResNode = CurDAG->SelectNodeTo(Node, HSAIL::LDA, PtrVT, Ops);
    break;
  }
  case ISD::INTRINSIC_WO_CHAIN:
    ResNode = SelectINTRINSIC_WO_CHAIN(Node);
    break;
  case ISD::INTRINSIC_W_CHAIN:
    ResNode = SelectINTRINSIC_W_CHAIN(Node);
    break;

  case ISD::CALLSEQ_START: {
    // LLVM 3.6 unable to select start/end of call sequence chained with the
    // rest of the arg scope operations due to the WalkChainUsers check which
    // reports it may induce a cycle in the graph, so select it manually.
    ResNode = CurDAG->SelectNodeTo(Node, HSAIL::ARG_SCOPE_START,
                                   MVT::Other, MVT::Glue,
                                   Node->getOperand(1), // src0
                                   Node->getOperand(0)); // Chain
    break;
  }
  case ISD::CALLSEQ_END: {
    const SDValue Ops[] = {
      Node->getOperand(1), // src0
      Node->getOperand(2), // src1
      Node->getOperand(0), // Chain
      Node->getOperand(3)  // Glue
    };

    ResNode = CurDAG->SelectNodeTo(Node, HSAIL::ARG_SCOPE_END,
                                   MVT::Other, MVT::Glue, Ops);
    break;
  }

#if 0
  case ISD::ATOMIC_LOAD:
  case ISD::ATOMIC_STORE:
  case ISD::ATOMIC_LOAD_OR:
  case ISD::ATOMIC_LOAD_XOR:
  case ISD::ATOMIC_LOAD_AND:
  case ISD::ATOMIC_SWAP:
  case ISD::ATOMIC_CMP_SWAP:
    // Handle bitwise atomic operations
    ResNode = SelectAtomic(Node, true, false /*ignored*/);
    break;
  case ISD::ATOMIC_LOAD_ADD:
  case ISD::ATOMIC_LOAD_SUB:
  case ISD::ATOMIC_LOAD_MAX:
  case ISD::ATOMIC_LOAD_MIN:
    // Handle signed atomic operations
    ResNode = SelectAtomic(Node, false, true);
    break;
  case ISD::ATOMIC_LOAD_UMAX:
  case ISD::ATOMIC_LOAD_UMIN:
    // Handle unsigned atomic operations
    ResNode = SelectAtomic(Node, false, false);
    break;
#endif

  case HSAILISD::ACTIVELANEMASK:
    return SelectActiveLaneMask(Node);
  }

  DEBUG(dbgs() << "=> ";
      if (ResNode == NULL || ResNode == Node)
      Node->dump(CurDAG);
      else
      ResNode->dump(CurDAG);
      dbgs() << '\n');

  return ResNode;
}

bool HSAILDAGToDAGISel::IsOREquivalentToADD(SDValue Op) const
{
  assert(Op.getOpcode() == ISD::OR);

  SDValue N0 = Op->getOperand(0);
  SDValue N1 = Op->getOperand(1);
  EVT VT = N0.getValueType();

  // Highly inspired by (a|b) case in DAGCombiner::visitADD
  if (VT.isInteger() && !VT.isVector()) {
    APInt LHSZero, LHSOne;
    APInt RHSZero, RHSOne;
    CurDAG->computeKnownBits(N0, LHSZero, LHSOne);

    if (LHSZero.getBoolValue()) {
      CurDAG->computeKnownBits(N1, RHSZero, RHSOne);

      // If all possibly-set bits on the LHS are clear on the RHS, return yes.
      // If all possibly-set bits on the RHS are clear on the LHS, return yes.
      if ((RHSZero & ~LHSZero) == ~LHSZero || (LHSZero & ~RHSZero) == ~RHSZero)
        return true;
    }
  }

  // Fallback to the more conservative check
  return CurDAG->isBaseWithConstantOffset(Op);
}

/// \brief Return true if the pointer is 32-bit in large and small models
static bool addrSpaceHasPtr32(unsigned AS) {
  switch (AS) {
  default : return false;

  case HSAILAS::GROUP_ADDRESS:
  case HSAILAS::ARG_ADDRESS:
  case HSAILAS::PRIVATE_ADDRESS:
  case HSAILAS::SPILL_ADDRESS:
    return true;
  }
}

/// We accept an SDNode to keep things simple in the TD files. The
/// cast to MemSDNode will never assert because this predicate is only
/// used in a pattern fragment that matches load or store nodes.
bool HSAILDAGToDAGISel::MemOpHasPtr32(SDNode *N) const {
  return addrSpaceHasPtr32(cast<MemSDNode>(N)->getAddressSpace());
}

bool HSAILDAGToDAGISel::SelectAddrCommon(SDValue Addr,
  SDValue &Base,
  SDValue &Reg,
  int64_t &Offset,
  MVT ValueType,
  int Depth) const
{
  if (Depth > 5)
    return false;

  SDValue backup_base = Base,
    backup_reg = Reg;
  int64_t backup_offset = Offset;

  switch (Addr.getOpcode())
  {
  case ISD::Constant:
  {
    int64_t new_offset = cast<ConstantSDNode>(Addr)->getSExtValue();
    // No 64 bit offsets in 32 bit target
    if (!Subtarget->is64Bit() && !isInt<32>(new_offset))
      return false;
    Offset += new_offset;
    return true;
  }
  case ISD::FrameIndex:
  {
    if (Base.getNode() == 0)
    {
      Base = CurDAG->getTargetFrameIndex(
        cast<FrameIndexSDNode>(Addr)->getIndex(), 
        ValueType);
      return true;
    }
    break;
  }
  case ISD::TargetGlobalAddress:
  case ISD::GlobalAddress:
  case ISD::GlobalTLSAddress:
  case ISD::TargetGlobalTLSAddress:
  {
    if (Base.getNode() == 0)
    {
      Base = CurDAG->getTargetGlobalAddress(
        cast<GlobalAddressSDNode>(Addr)->getGlobal(), 
        SDLoc(Addr),
        ValueType);
      int64_t new_offset = Offset + cast<GlobalAddressSDNode>(Addr)->getOffset();
      if (!Subtarget->is64Bit() && !isInt<32>(new_offset))
        return false;
      Offset += new_offset;
      return true;
    }
    break;
  }  
  case ISD::TargetExternalSymbol:
  {
    if (Base.getNode() == 0)
    {
      Base = Addr;
      return true;
    }
    break;
  }
  case ISD::OR: // Treat OR as ADD when Op1 & Op2 == 0
    if (IsOREquivalentToADD(Addr))
    {
      bool can_selec_first_op = 
        SelectAddrCommon(Addr.getOperand(0), Base, Reg, Offset, 
          ValueType, Depth+1);

      if (can_selec_first_op && 
          SelectAddrCommon(Addr.getOperand(1), Base, Reg, Offset, 
            ValueType, Depth+1))
        return true;
      Base = backup_base;
      Reg = backup_reg;
      Offset = backup_offset;
    }
    break;
  case ISD::ADD:
  {
    bool can_selec_first_op = 
      SelectAddrCommon(Addr.getOperand(0), Base, Reg, Offset, 
      ValueType, Depth+1);

    if (can_selec_first_op &&
        SelectAddrCommon(Addr.getOperand(1), Base, Reg, Offset, 
          ValueType, Depth+1))
      return true;
    Base = backup_base;
    Reg = backup_reg;
    Offset = backup_offset;
    break;
  }
  case HSAILISD::LDA: {
    if (SelectAddrCommon(Addr.getOperand(1), Base, Reg, Offset,
                         ValueType, Depth + 1)) {
      return true;
    }
    Base = backup_base;
    Reg = backup_reg;
    Offset = backup_offset;
    break;
  }
  default:
    break;
  }

  // By default generate address as register
  if (Reg.getNode() == 0)
  {
    Reg = Addr;
    return true;
  }
  return false;
}

/// SelectAddr - returns true if it is able pattern match an addressing mode.
/// It returns the operands which make up the maximal addressing mode it can
/// match by reference.
///
/// Parent is the parent node of the addr operand that is being matched.  It
/// is always a load, store, atomic node, or null.  It is only null when
/// checking memory operands for inline asm nodes.
bool
HSAILDAGToDAGISel::SelectAddr(SDValue Addr,
  SDValue& Base,
  SDValue& Reg,
  SDValue& Offset) const
{
  MVT VT = Addr.getValueType().getSimpleVT();
  assert(VT == MVT::i32 || VT == MVT::i64);

  int64_t disp = 0;
  if (!SelectAddrCommon(Addr, Base, Reg, disp, VT, 0))
    return false;

  Offset = CurDAG->getTargetConstant(disp, VT);
  if (Base.getNode() == 0)
    Base = CurDAG->getRegister(0, VT);
  if (Reg.getNode() == 0)
    Reg = CurDAG->getRegister(0, VT);
  return true;
}

static BrigType getBrigType(MVT::SimpleValueType VT, bool Signed) {
  switch (VT) {
  case MVT::i32:
    return Signed ? BRIG_TYPE_S32 : BRIG_TYPE_U32;
  case MVT::f32:
    return BRIG_TYPE_F32;
  case MVT::i8:
    return Signed ? BRIG_TYPE_S8 : BRIG_TYPE_U8;
  case MVT::i16:
    return Signed ? BRIG_TYPE_S16 : BRIG_TYPE_U16;
  case MVT::i64:
    return Signed ? BRIG_TYPE_S64 : BRIG_TYPE_U64;
  case MVT::f64:
    return BRIG_TYPE_F64;
  case MVT::i1:
    return BRIG_TYPE_B1;
  default:
    llvm_unreachable("Unhandled type for MVT -> BRIG");
  }
}

static BrigType getBrigTypeFromStoreType(MVT::SimpleValueType VT) {
  switch (VT) {
  case MVT::i32:
    return BRIG_TYPE_U32;
  case MVT::f32:
    return BRIG_TYPE_F32;
  case MVT::i8:
    return BRIG_TYPE_U8;
  case MVT::i16:
    return BRIG_TYPE_U16;
  case MVT::i64:
    return BRIG_TYPE_U64;
  case MVT::f64:
    return BRIG_TYPE_F64;
  default:
    llvm_unreachable("Unhandled type for MVT -> BRIG");
  }
}

bool HSAILDAGToDAGISel::SelectLoadAddr(SDNode *ParentLoad,
                                       SDValue Addr,
                                       SDValue &Base,
                                       SDValue &Reg,
                                       SDValue &Offset,
                                       SDValue &Segment,
                                       SDValue &Align,
                                       SDValue &Type,
                                       SDValue &Width,
                                       SDValue &ModifierMask) const {
  const LoadSDNode *Load = cast<LoadSDNode>(ParentLoad);
  assert(!Load->isIndexed());

  if (!SelectAddr(Addr, Base, Reg, Offset))
    return false;

  unsigned AS = Load->getAddressSpace();

  MVT MemVT = Load->getMemoryVT().getSimpleVT();
  ISD::LoadExtType ExtTy = Load->getExtensionType();
  unsigned BrigType = getBrigType(MemVT.SimpleTy, ExtTy == ISD::SEXTLOAD);

  Segment = CurDAG->getTargetConstant(AS, MVT::i32);
  Align = CurDAG->getTargetConstant(Load->getAlignment(), MVT::i32);
  Type = CurDAG->getTargetConstant(BrigType, MVT::i32);
  Width = CurDAG->getTargetConstant(BRIG_WIDTH_1, MVT::i32);
  ModifierMask = CurDAG->getTargetConstant(0, MVT::i32); // TODO: Set if invariant
  return true;
}

bool HSAILDAGToDAGISel::SelectStoreAddr(SDNode *ParentStore,
                                        SDValue Addr,
                                        SDValue &Base,
                                        SDValue &Reg,
                                        SDValue &Offset,
                                        SDValue &Segment,
                                        SDValue &Align,
                                        /*SDValue &Equiv,*/
                                        SDValue &Type) const {
  const StoreSDNode *Store = cast<StoreSDNode>(ParentStore);
  assert(!Store->isIndexed());

  if (!SelectAddr(Addr, Base, Reg, Offset))
    return false;

  unsigned AS = Store->getAddressSpace();

  MVT MemVT = Store->getMemoryVT().getSimpleVT();
  unsigned BrigType = getBrigTypeFromStoreType(MemVT.SimpleTy);

  Segment = CurDAG->getTargetConstant(AS, MVT::i32);
  Align = CurDAG->getTargetConstant(Store->getAlignment(), MVT::i32);
  //Equiv = CurDAG->getTargetConstant(0, MVT::i32);
  Type = CurDAG->getTargetConstant(BrigType, MVT::i32);
  return true;
}

static BrigMemoryOrder getBrigMemoryOrder(AtomicOrdering Order) {
  switch (Order) {
  case Monotonic:
    return BRIG_MEMORY_ORDER_RELAXED;
  case Acquire:
    return BRIG_MEMORY_ORDER_SC_ACQUIRE;
  case Release:
    return BRIG_MEMORY_ORDER_SC_RELEASE;
  case AcquireRelease:
  case SequentiallyConsistent:
    return BRIG_MEMORY_ORDER_SC_ACQUIRE_RELEASE;
  default:
    llvm_unreachable("unhandled memory order");
  }
}

static BrigMemoryScope getBrigMemoryScope(SynchronizationScope Scope,
                                          unsigned AS) {
  switch (Scope) {
  case SingleThread:
    return BRIG_MEMORY_SCOPE_WORKITEM;
  case CrossThread:
    // FIXME: This needs to be fixed when LLVM support other scope values.
    switch (AS) {
    case HSAILAS::GROUP_ADDRESS:
      return BRIG_MEMORY_SCOPE_WORKGROUP;
    case HSAILAS::REGION_ADDRESS:
      return BRIG_MEMORY_SCOPE_AGENT;
    default:
      return BRIG_MEMORY_SCOPE_SYSTEM;
    }
  }
}

bool HSAILDAGToDAGISel::SelectAtomicAddr(SDNode *ParentAtomic,
                                         SDValue Addr,
                                         SDValue &Segment,
                                         SDValue &Order,
                                         SDValue &Scope,
                                         SDValue &Equiv,

                                         SDValue &Base,
                                         SDValue &Reg,
                                         SDValue &Offset) const {
  if (!SelectAddr(Addr, Base, Reg, Offset))
    return false;

  const AtomicSDNode *Atomic = cast<AtomicSDNode>(ParentAtomic);

  // XXX - What do we do with the failure ordering?
  AtomicOrdering SuccOrder = Atomic->getSuccessOrdering();
  SynchronizationScope SyncScope = Atomic->getSynchScope();

  unsigned AS = Atomic->getAddressSpace();

  Segment = CurDAG->getTargetConstant(AS, MVT::i32);
  Order = CurDAG->getTargetConstant(getBrigMemoryOrder(SuccOrder), MVT::i32);
  Scope = CurDAG->getTargetConstant(getBrigMemoryScope(SyncScope, AS), MVT::i32);
  Equiv = CurDAG->getTargetConstant(0, MVT::i32);

  return true;
}

void HSAILDAGToDAGISel::SelectAddrSpaceCastCommon(const AddrSpaceCastSDNode &ASC,
                                                  SDValue &NoNull,
                                                  SDValue &Ptr,
                                                  SDValue &DestType,
                                                  SDValue &SrcType) const {
  SelectGPROrImm(ASC.getOperand(0), Ptr);
  NoNull = CurDAG->getTargetConstant(0, MVT::i1);

  BrigType DestBT
    = getBrigType(ASC.getValueType(0).getSimpleVT().SimpleTy, false);
  BrigType SrcBT
    = getBrigType(Ptr.getValueType().getSimpleVT().SimpleTy, false);

  DestType = CurDAG->getTargetConstant(DestBT, MVT::i32);
  SrcType = CurDAG->getTargetConstant(SrcBT, MVT::i32);
}


bool HSAILDAGToDAGISel::SelectSTOF(SDValue Cast,
                                   SDValue &Segment,
                                   SDValue &NoNull,
                                   SDValue &Ptr,
                                   SDValue &DestType,
                                   SDValue &SrcType) const {
  const AddrSpaceCastSDNode *ASC = cast<AddrSpaceCastSDNode>(Cast);
  if (ASC->getDestAddressSpace() != HSAILAS::FLAT_ADDRESS)
    return false;

  Segment = CurDAG->getTargetConstant(ASC->getSrcAddressSpace(), MVT::i32);

  SelectAddrSpaceCastCommon(*ASC, NoNull, Ptr, DestType, SrcType);
  return true;
}

bool HSAILDAGToDAGISel::SelectFTOS(SDValue Cast,
                                   SDValue &Segment,
                                   SDValue &NoNull,
                                   SDValue &Ptr,
                                   SDValue &DestType,
                                   SDValue &SrcType) const {
  const AddrSpaceCastSDNode *ASC = cast<AddrSpaceCastSDNode>(Cast);
  if (ASC->getSrcAddressSpace() != HSAILAS::FLAT_ADDRESS)
    return false;

  Segment = CurDAG->getTargetConstant(ASC->getDestAddressSpace(), MVT::i32);
  SelectAddrSpaceCastCommon(*ASC, NoNull, Ptr, DestType, SrcType);
  return true;
}

static BrigCompareOperation getBrigIntCompare(ISD::CondCode CC,
                                              bool &Signed) {
  switch (CC) {
  case ISD::SETUEQ:
    Signed = true; // Sign is irrelevant, use to be consistent.
    return BRIG_COMPARE_EQ;
  case ISD::SETUGT:
    return BRIG_COMPARE_GT;
  case ISD::SETUGE:
    return BRIG_COMPARE_GE;
  case ISD::SETULT:
    return BRIG_COMPARE_LT;
  case ISD::SETULE:
    return BRIG_COMPARE_LE;
  case ISD::SETUNE:
    Signed = true; // Sign is irrelevant, use to be consistent.
    return BRIG_COMPARE_NE;
  case ISD::SETEQ:
    Signed = true;
    return BRIG_COMPARE_EQ;
  case ISD::SETGT:
    Signed = true;
    return BRIG_COMPARE_GT;
  case ISD::SETGE:
    Signed = true;
    return BRIG_COMPARE_GE;
  case ISD::SETLT:
    Signed = true;
    return BRIG_COMPARE_LT;
  case ISD::SETLE:
    Signed = true;
    return BRIG_COMPARE_LE;
  case ISD::SETNE:
    Signed = true;
    return BRIG_COMPARE_NE;
  default:
    llvm_unreachable("unhandled cond code");
  }
}

static BrigCompareOperation getBrigFPCompare(ISD::CondCode CC) {
  switch (CC) {
  case ISD::SETOEQ:
  case ISD::SETEQ:
    return BRIG_COMPARE_EQ;
  case ISD::SETOGT:
  case ISD::SETGT:
    return BRIG_COMPARE_GT;
  case ISD::SETOGE:
  case ISD::SETGE:
    return BRIG_COMPARE_GE;
  case ISD::SETOLT:
  case ISD::SETLT:
    return BRIG_COMPARE_LT;
  case ISD::SETOLE:
  case ISD::SETLE:
    return BRIG_COMPARE_LE;
  case ISD::SETONE:
  case ISD::SETNE:
    return BRIG_COMPARE_NE;
  case ISD::SETO:
    return BRIG_COMPARE_NUM;
  case ISD::SETUO:
    return BRIG_COMPARE_NAN;
  case ISD::SETUEQ:
    return BRIG_COMPARE_EQU;
  case ISD::SETUGT:
    return BRIG_COMPARE_GTU;
  case ISD::SETUGE:
    return BRIG_COMPARE_GEU;
  case ISD::SETULT:
    return BRIG_COMPARE_LTU;
  case ISD::SETULE:
    return BRIG_COMPARE_LEU;
  case ISD::SETUNE:
    return BRIG_COMPARE_NEU;
  default:
    llvm_unreachable("unhandled cond code");
  }
}

bool HSAILDAGToDAGISel::SelectSetCC(SDValue SetCC,
                                    SDValue &LHS,
                                    SDValue &RHS,
                                    SDValue &CmpOp,
                                    SDValue &FTZ,
                                    SDValue &DestType,
                                    SDValue &SrcType) const {
  if (!SelectGPROrImm(SetCC.getOperand(0), LHS))
    return false;

  if (!SelectGPROrImm(SetCC.getOperand(1), RHS))
    return false;

  MVT VT = LHS.getValueType().getSimpleVT();
  ISD::CondCode CC = cast<CondCodeSDNode>(SetCC.getOperand(2))->get();
  bool Signed = false;
  BrigCompareOperation BrigCmp;

  if (VT.isFloatingPoint())
    BrigCmp = getBrigFPCompare(CC);
  else
    BrigCmp = getBrigIntCompare(CC, Signed);

  CmpOp = CurDAG->getTargetConstant(BrigCmp, MVT::i32);
  FTZ = CurDAG->getTargetConstant(VT == MVT::f32, MVT::i1);


  // TODO: Should be able to fold conversions into this instead.
  DestType = CurDAG->getTargetConstant(BRIG_TYPE_B1, MVT::i32);


  BrigType SrcBT = getBrigType(VT.SimpleTy, Signed);
  SrcType = CurDAG->getTargetConstant(SrcBT, MVT::i32);

  return true;
}

/// createHSAILISelDag - This pass converts a legalized DAG into a
/// HSAIL-specific DAG, ready for instruction scheduling.
FunctionPass*
llvm::createHSAILISelDag(HSAILTargetMachine &TM,
    llvm::CodeGenOpt::Level OptLevel)
{
  return new HSAILDAGToDAGISel(TM, OptLevel);
}
