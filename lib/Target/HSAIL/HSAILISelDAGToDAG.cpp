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
#include "HSAILInstrInfo.h"
#include "HSAILMachineFunctionInfo.h"
#include "HSAILRegisterInfo.h"
#include "HSAILSubtarget.h"
#include "HSAILTargetMachine.h"
#include "HSAILUtilityFunctions.h"
#include "llvm/Instructions.h"
#include "llvm/Intrinsics.h"
#include "llvm/Support/CFG.h"
#include "llvm/Type.h"
#include "llvm/GlobalVariable.h"
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
#include "libHSAIL/Brig.h"

using namespace llvm;

//===----------------------------------------------------------------------===//
//                      Pattern Matcher Implementation
//===----------------------------------------------------------------------===//

namespace llvm {
  extern bool EnableExperimentalFeatures;
  extern bool EnableGCNMinMax;
}

namespace {
//===--------------------------------------------------------------------===//
/// ISel - HSAIL specific code to select HSAIL machine instructions for
/// SelectionDAG operations.
///
class HSAILDAGToDAGISel : public SelectionDAGISel {
  /// HSAILLowering - This object fully describes how to lower LLVM code to an
  /// HSAIL-specific SelectionDAG.
  const HSAILTargetLowering &HSAILLowering;

  /// Subtarget - Keep a pointer to the HSAILSubtarget around so that we can
  /// make the right decision when generating code for different targets.
  const HSAILSubtarget *Subtarget;

  /// OptForSize - If true, selecto
  /// OptForSize - If true, selector should try to optimize for code size
  /// instead of performance.
  bool OptForSize;

public:
  explicit HSAILDAGToDAGISel(HSAILTargetMachine &tm, CodeGenOpt::Level OptLevel)
    : SelectionDAGISel(tm, OptLevel),
      HSAILLowering(*tm.getTargetLowering()),
      Subtarget(&tm.getSubtarget<HSAILSubtarget>()),
      OptForSize(false) {}

  // Default constructor required for Initiallizing PASS
  explicit HSAILDAGToDAGISel()
	: SelectionDAGISel(TM, OptLevel),
	  HSAILLowering(HSAILLowering) {}
	 
  virtual const char*
  getPassName() const
  {
    return "HSAIL DAG->DAG Instruction Selection";
  }

  virtual void
  EmitFunctionEntryCode();

  virtual bool
  IsProfitableToFold(SDValue N, SDNode *U, SDNode *Root) const;

  virtual void
  PreprocessISelDAG();

private:
  SDNode*
  Select(SDNode *N);

  SDNode* SelectINTRINSIC_W_CHAIN(SDNode *Node);
  SDNode* SelectINTRINSIC_WO_CHAIN(SDNode *Node);
  SDNode* SelectLdKernargIntrinsic(SDNode *Node);
#if 0
  SDNode* SelectAtomic(SDNode *Node, bool bitwiseAtomicOp = true, bool sign = false);
  SDValue getBRIGMemoryOrder(AtomicOrdering memOrder);
  SDValue getBRIGAtomicOpcode(unsigned atomicOp);
#endif
  SDValue getBRIGMemorySegment(unsigned memSeg);
  SDNode* SelectImageIntrinsic(SDNode *Node);
  SDNode* SelectCrossLaneIntrinsic(SDNode *Node);
  // Helper for SelectAddrCommon
  // Checks that OR operation is semantically equivalent to ADD
  bool IsOREquivalentToADD(SDValue Op);

  bool SelectAddrCommon(SDValue Addr, 
                        SDValue& Base, 
                        SDValue& Reg, 
                        int64_t& Offset, 
                        MVT ValueType,
                        int Depth);

  bool
  SelectAddr(SDValue N,
             SDValue &Base,
             SDValue &Reg,
             SDValue &Offset);

  bool
  TryFoldLoad(SDNode *P,
              SDValue N,
              SDValue &Base,
              SDValue &Scale,
              SDValue &Index,
              SDValue &Disp,
              SDValue &Segment);

  void
  EmitSpecialCodeForMain(MachineBasicBlock *BB, MachineFrameInfo *MFI);

  /// getGlobalBaseReg - Return an SDNode that returns the value of
  /// the global base register. Output instructions required to
  /// initialize the global base register, if necessary.
  ///
  SDNode* getGlobalBaseReg();

  /// getTargetMachine - Return a reference to the TargetMachine, casted
  /// to the target-specific type.
  const HSAILTargetMachine&
  getTargetMachine()
  {
    assert(!"When do we hit this?");
    return static_cast<const HSAILTargetMachine &>(TM);
  }

  /// getInstrInfo - Return a reference to the TargetInstrInfo, casted
  /// to the target-specific type.
  const HSAILInstrInfo*
  getInstrInfo()
  {
    assert(!"When do we hit this?");
    return NULL;
  }

  /// SelectInlineAsmMemoryOperand - Implement addressing mode selection for
  /// inline asm expressions.
  virtual bool SelectInlineAsmMemoryOperand(const SDValue &Op,
                                            char ConstraintCode,
                                            std::vector<SDValue> &OutOps);

  bool isGlobalStore(StoreSDNode *N) const;
  bool isGroupStore(StoreSDNode *N) const;
  bool isPrivateStore(StoreSDNode *N) const;
  bool isSpillStore(StoreSDNode *N) const;
  bool isArgStore(StoreSDNode *N) const;
  bool isFlatStore(StoreSDNode *N) const;

  bool isGlobalLoad(LoadSDNode *N) const;
  bool isConstantLoad(LoadSDNode *N, int cbID) const;
  bool isGroupLoad(LoadSDNode *N) const;
  LoadSDNode* getAncestorLoad(SDNode *N) const;
  bool isPrivateLoad(LoadSDNode *N) const;
  bool isSpillLoad(LoadSDNode *N) const;
  bool isKernargLoad(LoadSDNode *N) const;
  bool isArgLoad(LoadSDNode *N) const;
  bool isFlatLoad(LoadSDNode *N) const;
  unsigned getPointerSize(void) const;
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

void
HSAILDAGToDAGISel::PreprocessISelDAG()
{
  return;
}

/// EmitSpecialCodeForMain - Emit any code that needs to be executed only in
/// the main function.
void
HSAILDAGToDAGISel::EmitSpecialCodeForMain(MachineBasicBlock *BB,
                                          MachineFrameInfo *MFI)
{
  assert(!"When do we hit this?");
}

void
HSAILDAGToDAGISel::EmitFunctionEntryCode() {
  // If this is main, emit special code for main.
  if (const Function *Fn = MF->getFunction())
    if (Fn->hasExternalLinkage() && Fn->getName() == "main")
      EmitSpecialCodeForMain(MF->begin(), MF->getFrameInfo());
}

bool
HSAILDAGToDAGISel::TryFoldLoad(SDNode *P,
                               SDValue N,
                               SDValue &Base,
                               SDValue &Scale,
                               SDValue &Index,
                               SDValue &Disp,
                               SDValue &Segment)
{
  assert(!"When do we hit this?");
  return false;
}

/// getGlobalBaseReg - Return an SDNode that returns the value of
/// the global base register. Output instructions required to
/// initialize the global base register, if necessary.
SDNode*
HSAILDAGToDAGISel::getGlobalBaseReg()
{
  assert(!"When do we hit this?");
  return NULL;
}

bool
HSAILDAGToDAGISel::isKernelFunc() const
{
  MachineFunction &MF = CurDAG->getMachineFunction();
  return ::isKernelFunc(MF.getFunction());
}

static unsigned getImageInstr(HSAILIntrinsic::ID intr, bool is095 )
{

  if ( is095 ) {
    switch(intr){
      default: llvm_unreachable("unexpected intrinsinc ID for images");
        case HSAILIntrinsic::HSAIL_rd_imgf_1d_f32: return HSAIL::rd_imgf_1d_f32_095;
        case HSAILIntrinsic::HSAIL_rd_imgf_1d_s32: return HSAIL::rd_imgf_1d_s32_095;
        case HSAILIntrinsic::HSAIL_rd_imgf_1da_f32: return HSAIL::rd_imgf_1da_f32_095;
        case HSAILIntrinsic::HSAIL_rd_imgf_1da_s32: return HSAIL::rd_imgf_1da_s32_095;
        case HSAILIntrinsic::HSAIL_rd_imgf_2d_f32: return HSAIL::rd_imgf_2d_f32_095;
        case HSAILIntrinsic::HSAIL_rd_imgf_2d_s32: return HSAIL::rd_imgf_2d_s32_095;
        case HSAILIntrinsic::HSAIL_rd_imgf_2da_f32: return HSAIL::rd_imgf_2da_f32_095;
        case HSAILIntrinsic::HSAIL_rd_imgf_2da_s32: return HSAIL::rd_imgf_2da_s32_095;
        case HSAILIntrinsic::HSAIL_rd_imgf_3d_f32: return HSAIL::rd_imgf_3d_f32_095;
        case HSAILIntrinsic::HSAIL_rd_imgf_3d_s32: return HSAIL::rd_imgf_3d_s32_095;
        case HSAILIntrinsic::HSAIL_rd_imgi_1d_f32: return HSAIL::rd_imgi_1d_f32_095;
        case HSAILIntrinsic::HSAIL_rd_imgi_1d_s32: return HSAIL::rd_imgi_1d_s32_095;
        case HSAILIntrinsic::HSAIL_rd_imgi_1da_f32: return HSAIL::rd_imgi_1da_f32_095;
        case HSAILIntrinsic::HSAIL_rd_imgi_1da_s32: return HSAIL::rd_imgi_1da_s32_095;
        case HSAILIntrinsic::HSAIL_rd_imgi_2d_f32: return HSAIL::rd_imgi_2d_f32_095;
        case HSAILIntrinsic::HSAIL_rd_imgi_2d_s32: return HSAIL::rd_imgi_2d_s32_095;
        case HSAILIntrinsic::HSAIL_rd_imgi_2da_f32: return HSAIL::rd_imgi_2da_f32_095;
        case HSAILIntrinsic::HSAIL_rd_imgi_2da_s32: return HSAIL::rd_imgi_2da_s32_095;
        case HSAILIntrinsic::HSAIL_rd_imgi_3d_f32: return HSAIL::rd_imgi_3d_f32_095;
        case HSAILIntrinsic::HSAIL_rd_imgi_3d_s32: return HSAIL::rd_imgi_3d_s32_095;
        case HSAILIntrinsic::HSAIL_rd_imgui_1d_f32: return HSAIL::rd_imgui_1d_f32_095;
        case HSAILIntrinsic::HSAIL_rd_imgui_1d_s32: return HSAIL::rd_imgui_1d_s32_095;
        case HSAILIntrinsic::HSAIL_rd_imgui_1da_f32: return HSAIL::rd_imgui_1da_f32_095;
        case HSAILIntrinsic::HSAIL_rd_imgui_1da_s32: return HSAIL::rd_imgui_1da_s32_095;
        case HSAILIntrinsic::HSAIL_rd_imgui_2d_f32: return HSAIL::rd_imgui_2d_f32_095;
        case HSAILIntrinsic::HSAIL_rd_imgui_2d_s32: return HSAIL::rd_imgui_2d_s32_095;
        case HSAILIntrinsic::HSAIL_rd_imgui_2da_f32: return HSAIL::rd_imgui_2da_f32_095;
        case HSAILIntrinsic::HSAIL_rd_imgui_2da_s32: return HSAIL::rd_imgui_2da_s32_095;
        case HSAILIntrinsic::HSAIL_rd_imgui_3d_f32: return HSAIL::rd_imgui_3d_f32_095;
        case HSAILIntrinsic::HSAIL_rd_imgui_3d_s32: return HSAIL::rd_imgui_3d_s32_095;
        case HSAILIntrinsic::HSAIL_rd_imgf_2ddepth_f32: return HSAIL::rd_imgf_2ddepth_f32_095;
        case HSAILIntrinsic::HSAIL_rd_imgf_2ddepth_s32: return HSAIL::rd_imgf_2ddepth_s32_095;
        case HSAILIntrinsic::HSAIL_rd_imgf_2dadepth_f32: return HSAIL::rd_imgf_2dadepth_f32_095;
        case HSAILIntrinsic::HSAIL_rd_imgf_2dadepth_s32: return HSAIL::rd_imgf_2dadepth_s32_095;

        case HSAILIntrinsic::HSAIL_ld_imgf_1d_u32: return HSAIL::ld_imgf_1d_u32_095;
        case HSAILIntrinsic::HSAIL_ld_imgf_1da_u32: return HSAIL::ld_imgf_1da_u32_095;
        case HSAILIntrinsic::HSAIL_ld_imgf_1db_u32: return HSAIL::ld_imgf_1db_u32_095;
        case HSAILIntrinsic::HSAIL_ld_imgf_2d_u32: return HSAIL::ld_imgf_2d_u32_095;
        case HSAILIntrinsic::HSAIL_ld_imgf_2da_u32: return HSAIL::ld_imgf_2da_u32_095;
        case HSAILIntrinsic::HSAIL_ld_imgf_3d_u32: return HSAIL::ld_imgf_3d_u32_095;
        case HSAILIntrinsic::HSAIL_ld_imgi_1d_u32: return HSAIL::ld_imgi_1d_u32_095;
        case HSAILIntrinsic::HSAIL_ld_imgi_1da_u32: return HSAIL::ld_imgi_1da_u32_095;
        case HSAILIntrinsic::HSAIL_ld_imgi_1db_u32: return HSAIL::ld_imgi_1db_u32_095;
        case HSAILIntrinsic::HSAIL_ld_imgi_2d_u32: return HSAIL::ld_imgi_2d_u32_095;
        case HSAILIntrinsic::HSAIL_ld_imgi_2da_u32: return HSAIL::ld_imgi_2da_u32_095;
        case HSAILIntrinsic::HSAIL_ld_imgi_3d_u32: return HSAIL::ld_imgi_3d_u32_095;
        case HSAILIntrinsic::HSAIL_ld_imgui_1d_u32: return HSAIL::ld_imgui_1d_u32_095;
        case HSAILIntrinsic::HSAIL_ld_imgui_1da_u32: return HSAIL::ld_imgui_1da_u32_095;
        case HSAILIntrinsic::HSAIL_ld_imgui_1db_u32: return HSAIL::ld_imgui_1db_u32_095;
        case HSAILIntrinsic::HSAIL_ld_imgui_2d_u32: return HSAIL::ld_imgui_2d_u32_095;
        case HSAILIntrinsic::HSAIL_ld_imgui_2da_u32: return HSAIL::ld_imgui_2da_u32_095;
        case HSAILIntrinsic::HSAIL_ld_imgui_3d_u32: return HSAIL::ld_imgui_3d_u32_095;
        case HSAILIntrinsic::HSAIL_ld_imgf_2ddepth_u32: return HSAIL::ld_imgf_2ddepth_u32_095;
        case HSAILIntrinsic::HSAIL_ld_imgf_2dadepth_u32: return HSAIL::ld_imgf_2dadepth_u32_095;


    }
  } else {
    switch (intr) {
      default: llvm_unreachable("unexpected intrinsinc ID for images");
      case HSAILIntrinsic::HSAIL_rd_imgf_1d_f32:  return HSAIL::rd_imgf_1d_f32;
      case HSAILIntrinsic::HSAIL_rd_imgf_1d_s32:  return HSAIL::rd_imgf_1d_s32;
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
}

static unsigned getCrossLaneInstr(HSAILIntrinsic::ID intr)
{
  switch (intr) {
      default: llvm_unreachable("unexpected intrinsinc ID for Cross Lane Ops");
      case HSAILIntrinsic::HSAIL_activelanemask_v4_b64_b1:  return HSAIL::activelanemask_v4_b64_b1;
      case HSAILIntrinsic::HSAIL_activelanemask_v4_width_b64_b1:  return HSAIL::activelanemask_v4_width_b64_b1;
  }
}

SDNode* HSAILDAGToDAGISel::SelectINTRINSIC_W_CHAIN(SDNode *Node)
{
  unsigned IntNo = cast<ConstantSDNode>(Node->getOperand(1))->getZExtValue();
  if (HSAILIntrinsicInfo::isReadImage((HSAILIntrinsic::ID)IntNo) ||
      HSAILIntrinsicInfo::isLoadImage((HSAILIntrinsic::ID)IntNo ))
    return SelectImageIntrinsic(Node);
  if (HSAILIntrinsicInfo::isCrossLane((HSAILIntrinsic::ID)IntNo))
    return SelectCrossLaneIntrinsic(Node);
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
  DebugLoc dl = Node->getDebugLoc();
  SDNode *ResNode;

  unsigned IntNo = cast<ConstantSDNode>(Node->getOperand(1))->getZExtValue();
  bool hasSampler = false;

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

  if ( !EnableExperimentalFeatures ) {
    SDValue ImgPtrImm = Node->getOperand(OpIndex++);
    int64_t ImgPtrVal = cast<ConstantSDNode>(ImgPtrImm)->getZExtValue();
    SDValue ImgPtr = CurDAG->getTargetConstant(ImgPtrVal, ImgPtrImm.getValueType());
    NewOps.push_back(ImgPtr);

    if (hasSampler) {
      SDValue SmpPtrImm = Node->getOperand(OpIndex++);
      int64_t SmpPtrVal = cast<ConstantSDNode>(SmpPtrImm)->getZExtValue();
      SDValue SmpPtr = CurDAG->getTargetConstant(SmpPtrVal, SmpPtrImm.getValueType());
      NewOps.push_back(SmpPtr);
    }
  } else {
    SDValue Img = Node->getOperand(OpIndex++);
    int ResNo = Img.getResNo();
    SDValue ImgHandle = Img.getValue(ResNo);
    NewOps.push_back(ImgHandle);

    if (hasSampler) {
      SDValue Smp = Node->getOperand(OpIndex++);
      SDValue SmpHandle = Smp.getValue(Smp.getResNo());
      NewOps.push_back(SmpHandle);
    }
  }

  while (OpIndex < Node->getNumOperands()) {
    SDValue Coord = Node->getOperand(OpIndex++);
    NewOps.push_back(Coord);
  }

  NewOps.push_back(Chain);

  ResNode = CurDAG->SelectNodeTo(Node, getImageInstr((HSAILIntrinsic::ID)IntNo, EnableExperimentalFeatures),
                                 Node->getVTList(), NewOps.data(), NewOps.size());
  return ResNode;
}

SDNode* HSAILDAGToDAGISel::SelectCrossLaneIntrinsic(SDNode *Node)
{
  SDValue Chain = Node->getOperand(0);
  DebugLoc dl = Node->getDebugLoc();
  SDNode *ResNode;

  unsigned IntNo = cast<ConstantSDNode>(Node->getOperand(1))->getZExtValue();

  if (!HSAILIntrinsicInfo::isCrossLane((HSAILIntrinsic::ID)IntNo)) {
    return SelectCode(Node);
  }

  assert(Node->getNumValues() > 4);

  SmallVector<SDValue, 6> NewOps;

  unsigned OpIndex = 2;

  SDValue ActiveWI = Node->getOperand(OpIndex++);
  NewOps.push_back(ActiveWI);

  NewOps.push_back(Chain);

  ResNode = CurDAG->SelectNodeTo(Node, getCrossLaneInstr((HSAILIntrinsic::ID)IntNo),
                                 Node->getVTList(), NewOps.data(), NewOps.size());
  return ResNode;
}

SDNode* HSAILDAGToDAGISel::SelectLdKernargIntrinsic(SDNode *Node) {
  bool hasChain = Node->getNumOperands() > 2;
  unsigned opShift = hasChain ? 1 : 0;
  unsigned IntNo = (unsigned) Node->getConstantOperandVal(opShift);

  unsigned opc;
  EVT VT;
  Type *Ty;
  if (IntNo == HSAILIntrinsic::HSAIL_ld_kernarg_u32) {
    opc = HSAIL::kernarg_ld_u32_v1;
    VT = MVT::i32;
    Ty = Type::getInt32Ty(*CurDAG->getContext());
  } else {
    opc = HSAIL::kernarg_ld_u64_v1;
    VT = MVT::i64;
    Ty = Type::getInt64Ty(*CurDAG->getContext());
  }
  SDValue Addr = Node->getOperand(1 + opShift);
  unsigned size = VT.getStoreSize();
  unsigned alignment = size;
  int64_t offset = 0;
  SDValue Base = CurDAG->getRegister(0, HSAILLowering.getPointerTy());
  SDValue Reg  = Base;
  // TODO_HSA: match a constant address argument to the parameter through
  //           functions's argument map (taking argument alignment into account).
  //           Match is not possible if we are accesing beyond a known kernel
  //           argument space, or if we accessing from a non-inlined function.
  //           If no match is possible a kernargbaseptr instruction has to be
  //           used as a base address instead on NoReg value.
  if (isa<ConstantSDNode>(Addr)) {
    offset = Node->getConstantOperandVal(1 + opShift);
    if (offset & (size - 1))
      alignment = 1;
  }
  else if (Addr.isTargetOpcode())
    Base = Addr;
  else
    Reg = Addr;
  SDValue Offset = CurDAG->getTargetConstant(offset, VT);
  SDValue OneDw = CurDAG->getTargetConstant(1, MVT::i1);
  SDValue OneBit = CurDAG->getTargetConstant(1, MVT::i1);
  SDValue Align = CurDAG->getTargetConstant(alignment, MVT::i32);
  SDValue Ops[] = { Base, Reg, Offset,              /* Address */
                    OneDw, Align, OneBit,           /* Width, Align, Const */
                    hasChain ? Node->getOperand(0) : CurDAG->getEntryNode()  };
  SDNode *Load = CurDAG->SelectNodeTo(Node, opc, VT, MVT::Other, Ops,
                                      array_lengthof(Ops));

  // Set machine memory operand
  PointerType *ArgPT = PointerType::get(Ty, HSAILAS::KERNARG_ADDRESS);
  MachinePointerInfo MPtrInfo(UndefValue::get(ArgPT));
  MachineFunction &MF = CurDAG->getMachineFunction();
  MachineSDNode::mmo_iterator MemOp = MF.allocateMemRefsArray(1);
  MemOp[0] = MF.getMachineMemOperand(MPtrInfo, MachineMemOperand::MOLoad,
                                     size, alignment);
  cast<MachineSDNode>(Load)->setMemRefs(MemOp, MemOp + 1);
  return Load;
}

SDValue HSAILDAGToDAGISel::getBRIGMemorySegment(unsigned memSeg) {
  unsigned BRIGMemSegment;
  switch(memSeg) {
    case llvm::HSAILAS::GLOBAL_ADDRESS:
        BRIGMemSegment = Brig::BRIG_SEGMENT_GLOBAL; break;
    case llvm::HSAILAS::GROUP_ADDRESS:
        BRIGMemSegment = Brig::BRIG_SEGMENT_GROUP; break;
    case llvm::HSAILAS::FLAT_ADDRESS:
        BRIGMemSegment = Brig::BRIG_SEGMENT_FLAT; break;
    default: llvm_unreachable("unexpected memory segment ");
  }
  SDValue memSegSD = CurDAG->getTargetConstant(BRIGMemSegment,
                                               MVT::getIntegerVT(32));
  return memSegSD;
}

#if 0
SDValue HSAILDAGToDAGISel::getBRIGMemoryOrder(AtomicOrdering memOrder) {
  unsigned BRIGMemOrder;
  switch(memOrder) {
    case Monotonic: BRIGMemOrder = Brig::BRIG_MEMORY_ORDER_RELAXED;break;
    case Acquire: BRIGMemOrder = Brig::BRIG_MEMORY_ORDER_SC_ACQUIRE;break;
    case Release: BRIGMemOrder = Brig::BRIG_MEMORY_ORDER_SC_RELEASE;break;
    case AcquireRelease:
    case SequentiallyConsistent: // atomic_load and atomic_store with SC
                                 // are custom lowered
                  BRIGMemOrder = Brig::BRIG_MEMORY_ORDER_SC_ACQUIRE_RELEASE; break;
    default: llvm_unreachable("unexpected memory order");
  }
  SDValue memOrderSD = CurDAG->getTargetConstant(BRIGMemOrder,
                                                 MVT::getIntegerVT(32));
  return memOrderSD;
}

SDValue HSAILDAGToDAGISel::getBRIGAtomicOpcode(unsigned atomicOp) {
  unsigned BRIGAtomicOp;
  switch(atomicOp) {
    case ISD::ATOMIC_LOAD_ADD: BRIGAtomicOp = Brig::BRIG_ATOMIC_ADD; break;
    case ISD::ATOMIC_LOAD_SUB: BRIGAtomicOp = Brig::BRIG_ATOMIC_SUB; break;
    case ISD::ATOMIC_LOAD_OR:  BRIGAtomicOp = Brig::BRIG_ATOMIC_OR; break;
    case ISD::ATOMIC_LOAD_XOR: BRIGAtomicOp = Brig::BRIG_ATOMIC_XOR; break;
    case ISD::ATOMIC_LOAD_AND: BRIGAtomicOp = Brig::BRIG_ATOMIC_AND; break;
    case ISD::ATOMIC_LOAD_MAX:
    case ISD::ATOMIC_LOAD_UMAX:
                               BRIGAtomicOp = Brig::BRIG_ATOMIC_MAX; break;
    case ISD::ATOMIC_LOAD_MIN:
    case ISD::ATOMIC_LOAD_UMIN:
                               BRIGAtomicOp = Brig::BRIG_ATOMIC_MIN; break;
    case ISD::ATOMIC_LOAD:     BRIGAtomicOp = Brig::BRIG_ATOMIC_LD; break;
    case ISD::ATOMIC_STORE:    BRIGAtomicOp = Brig::BRIG_ATOMIC_ST; break;
    case ISD::ATOMIC_SWAP:     BRIGAtomicOp = Brig::BRIG_ATOMIC_EXCH; break;
    case ISD::ATOMIC_CMP_SWAP: BRIGAtomicOp = Brig::BRIG_ATOMIC_CAS; break;
    default: llvm_unreachable("unexpected atomic op");
  }
  SDValue atomicOpSD = CurDAG->getTargetConstant(BRIGAtomicOp,
                                                 MVT::getIntegerVT(32));
  return atomicOpSD;
}

/// Select atomic opcode based on
/// size of the compare operand and its addressing mode
static unsigned getHSAILAtomicCasOpcode (SDNode *Node) {
  SDValue cmpOp = Node->getOperand(2);
  unsigned size = cmpOp.getValueSizeInBits();
  bool immOp1 = cmpOp.getNode()->getOpcode() == ISD::Constant ?
                true : false;
  bool immOp2 = Node->getOperand(3).getNode()->getOpcode() == ISD::Constant ?
                true : false;
  if (size == 32)
    return immOp1 ?
           immOp2 ? HSAIL::atomic_ternary_b32_ii : HSAIL::atomic_ternary_b32_ir :
           immOp2 ? HSAIL::atomic_ternary_b32_ri : HSAIL::atomic_ternary_b32_rr;
  if (size == 64)
    return immOp1 ?
           immOp2 ? HSAIL::atomic_ternary_b64_ii : HSAIL::atomic_ternary_b64_ir :
           immOp2 ? HSAIL::atomic_ternary_b64_ri : HSAIL::atomic_ternary_b64_rr;
  llvm_unreachable("unexpected operand size for atomic op");
}

/// Select atomic opcode based on
/// size of the operand, its addressing mode and signedness
static unsigned getHSAILAtomicRMWOpcode(SDNode *Node, bool bitwiseAtomicOp = true,
                                        bool isSignedOp = false) {
  SDValue rmwValOp = Node->getOperand(2);
  unsigned size = rmwValOp.getValueSizeInBits();
  bool immOp = rmwValOp.getNode()->getOpcode() == ISD::Constant ?
               true : false;
  if (size == 32) {
    if (bitwiseAtomicOp)
      return immOp ? HSAIL::atomic_binary_b32_i :
             HSAIL::atomic_binary_b32_r;
     else {
      if (isSignedOp)
        return immOp ? HSAIL::atomic_binary_s32_i :
               HSAIL::atomic_binary_s32_r;
       else
         return immOp ? HSAIL::atomic_binary_u32_i:
                HSAIL::atomic_binary_u32_r;
     }
  }
  if (size == 64) {
    if (bitwiseAtomicOp)
      return immOp ? HSAIL::atomic_binary_b64_i:
             HSAIL::atomic_binary_b64_r;
    else {
      if (isSignedOp)
        return immOp ? HSAIL::atomic_binary_s64_i:
               HSAIL::atomic_binary_s64_r;
      else
        return immOp ? HSAIL::atomic_binary_u64_i:
               HSAIL::atomic_binary_u64_r;
    }
  }
  llvm_unreachable("unexpected operand size for atomic op");
}

/// Select atomic opcode based on size of the loaded value
static unsigned getHSAILAtomicLoadOpcode (SDNode *Node) {
  // fetch the size of the loaded value
  unsigned size = Node->getValueSizeInBits(0);
  if (size == 32) return HSAIL::atomic_unary_b32;
  if (size == 64) return HSAIL::atomic_unary_b64;
  llvm_unreachable("unexpected operand size for atomic op");
}

/// Select atomic opcode based on
/// size of the value to be stored and its addressing mode
static unsigned getHSAILAtomicStoreOpcode (SDNode *Node) {
  SDValue storeValue = Node->getOperand(2);
  unsigned size = storeValue.getValueSizeInBits();
  bool immOp = storeValue.getNode()->getOpcode() == ISD::Constant ?
               true : false;
  if (size == 32)
    return immOp ? HSAIL::atomic_binary_b32_i_noret :
                   HSAIL::atomic_binary_b32_r_noret;
  if (size == 64)
    return immOp ? HSAIL::atomic_binary_b64_i_noret :
                   HSAIL::atomic_binary_b64_r_noret;
  llvm_unreachable("unexpected operand size for atomic op");
}

static unsigned getHSAILAtomicOpcode(SDNode *Node, bool bitwiseAtomicOp = true,
                                     bool isSignedOp = false) {
  switch(Node->getOpcode()) {
    case ISD::ATOMIC_LOAD: return getHSAILAtomicLoadOpcode(Node);
    case ISD::ATOMIC_STORE: return getHSAILAtomicStoreOpcode(Node);
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
         return getHSAILAtomicRMWOpcode(Node, bitwiseAtomicOp, isSignedOp);
    case ISD::ATOMIC_CMP_SWAP:  return getHSAILAtomicCasOpcode(Node);
    default: llvm_unreachable("unknown atomic SDNode");
  }
}

/// SelectAtomic - Selects the appropriate Machine Instruction for AtomicSDNode
/// Machine IR for atomics is paramenterized with
/// <atomic opcode, address space, memory order, memory scope>
/// along with the SDNode operands.
/// e.g: atomic_binary_s32_i BRIG_ATOMIC_ADD, BRIG_SEGMENT_GLOBAL,
///                    BRIG_MEMORY_ORDER_RELAXED, BRIG_MEMORY_SCOPE_WORKGROUP,
///                    arg1, arg2
/// This is done inorder to reduce the number of Machine Instructions for atomics.
/// In BRIGAsmPrinter::EmitInstruction, these Machine Instructions
/// are custom lowered into appropriate BRIG.
///
/// bitwiseAtomicOp - true for bitwise atomic ops,
///                        - false for signed/unsigned ops
/// isSignedOp - true for signed atomic op
///          - false for unsigned atomic op
///
SDNode* HSAILDAGToDAGISel::SelectAtomic(SDNode *Node, bool bitwiseAtomicOp,
                                        bool isSignedOp)
{
  SDValue Chain = Node->getOperand(0);
  DebugLoc dl = Node->getDebugLoc();
  SDNode *ResNode;
  MemSDNode *Mn = dyn_cast<MemSDNode>(Node);
  SDValue memOrder = getBRIGMemoryOrder(Mn->getOrdering());
  unsigned brigMemScopeVal = Mn->getAddressSpace() == HSAILAS::GROUP_ADDRESS ?
      Brig::BRIG_MEMORY_SCOPE_WORKGROUP : Mn->getMemoryScope();
  SDValue memScope = CurDAG->getTargetConstant(brigMemScopeVal,
                                               MVT::getIntegerVT(32));
  SDValue atomicOpcode = getBRIGAtomicOpcode(Node->getOpcode());
  SDValue addrSpace = getBRIGMemorySegment(Mn->getAddressSpace());
  SmallVector<SDValue, 9> NewOps;
  SDValue Base, Reg, Offset;

  SelectAddr(Node->getOperand(1), Base, Reg, Offset);

  NewOps.push_back(atomicOpcode);
  NewOps.push_back(addrSpace);
  NewOps.push_back(memOrder);
  NewOps.push_back(memScope);
  NewOps.push_back(Base);
  NewOps.push_back(Reg);
  NewOps.push_back(Offset);
  for (unsigned i = 2;i < Node->getNumOperands();i++)
    NewOps.push_back(Node->getOperand(i));
  NewOps.push_back(Chain);

  ResNode = CurDAG->SelectNodeTo(Node,
                                 getHSAILAtomicOpcode(Node, bitwiseAtomicOp,
                                 isSignedOp), Node->getVTList(), NewOps.data(),
                                 NewOps.size());
  return ResNode;
}
#endif

SDNode*
HSAILDAGToDAGISel::Select(SDNode *Node)
{
  assert(Node);

  EVT NVT = Node->getValueType(0);
  unsigned Opcode = Node->getOpcode();
  DebugLoc dl = Node->getDebugLoc();
  SDNode *ResNode;
  bool isKernel = isKernelFunc();

  DEBUG(dbgs() << "Selecting: "; Node->dump(CurDAG); dbgs() << '\n');

  if (Node->isMachineOpcode()) {
    DEBUG(dbgs() << "== ";  Node->dump(CurDAG); dbgs() << '\n');
    return NULL;   // Already selected.
  }

  switch (Opcode) {
  default:
    ResNode = SelectCode(Node);
    break;
  case ISD::FrameIndex:
    {
      unsigned int NewOpc;
      if (FrameIndexSDNode *FIN = dyn_cast<FrameIndexSDNode>(Node)) {
        unsigned int FI = FIN->getIndex();
        NewOpc = HSAIL::ldas_private_addr32;
        SDValue TFI = CurDAG->getTargetFrameIndex(FI, MVT::i32);
        ResNode = CurDAG->SelectNodeTo(Node, NewOpc, NVT, TFI, 
          CurDAG->getRegister(0, NVT),
          CurDAG->getTargetConstant(0, NVT));
       } else {
          ResNode = Node;
       }
    }
    break;

  case ISD::INTRINSIC_WO_CHAIN:
    ResNode = SelectINTRINSIC_WO_CHAIN(Node);
    break;
  case ISD::INTRINSIC_W_CHAIN:
    ResNode = SelectINTRINSIC_W_CHAIN(Node);
    break;
#if 0
  case ISD::ATOMIC_LOAD:
  case ISD::ATOMIC_STORE:
  case ISD::ATOMIC_LOAD_OR:
  case ISD::ATOMIC_LOAD_XOR:
  case ISD::ATOMIC_LOAD_AND:
  case ISD::ATOMIC_SWAP:
  case ISD::ATOMIC_CMP_SWAP:
    // Handle bitwise atomic operations
    ResNode = SelectAtomic(Node);
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
  }

  DEBUG(dbgs() << "=> ";
      if (ResNode == NULL || ResNode == Node)
      Node->dump(CurDAG);
      else
      ResNode->dump(CurDAG);
      dbgs() << '\n');

  return ResNode;
}

bool
HSAILDAGToDAGISel::SelectInlineAsmMemoryOperand(const SDValue &Op,
    char ConstraintCode,
    std::vector<SDValue> &OutOps)
{
  assert(!"When do we hit this?");
  return false;
}

bool HSAILDAGToDAGISel::IsOREquivalentToADD(SDValue Op)
{
  assert(Op.getOpcode() == ISD::OR);

  SDValue N0 = Op->getOperand(0);
  SDValue N1 = Op->getOperand(1);
  EVT VT = N0.getValueType();

  // Highly inspired by (a|b) case in DAGCombiner::visitADD
  if (VT.isInteger() && !VT.isVector()) {
    APInt LHSZero, LHSOne;
    APInt RHSZero, RHSOne;
    CurDAG->ComputeMaskedBits(N0, LHSZero, LHSOne);

    if (LHSZero.getBoolValue()) {
      CurDAG->ComputeMaskedBits(N1, RHSZero, RHSOne);

      // If all possibly-set bits on the LHS are clear on the RHS, return yes.
      // If all possibly-set bits on the RHS are clear on the LHS, return yes.
      if ((RHSZero & ~LHSZero) == ~LHSZero || (LHSZero & ~RHSZero) == ~RHSZero)
        return true;
    }
  }

  // Fallback to the more conservative check
  return CurDAG->isBaseWithConstantOffset(Op);
}

bool  HSAILDAGToDAGISel::SelectAddrCommon(SDValue Addr,
  SDValue &Base,
  SDValue &Reg,
  int64_t &Offset,
  MVT ValueType,
  int Depth)
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
    int64_t new_offset = cast<ConstantSDNode>(Addr)->getSExtValue() + Offset;
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
        Addr.getDebugLoc(), 
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
  case HSAILISD::LDA_FLAT:
  case HSAILISD::LDA_GLOBAL:
  case HSAILISD::LDA_GROUP:
  case HSAILISD::LDA_PRIVATE:
  case HSAILISD::LDA_READONLY:
  {
    if (SelectAddrCommon(Addr.getOperand(0), Base, Reg, Offset, 
                         ValueType, Depth+1))
    {
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
  SDValue& Offset)
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

static bool check_type(const Value *ptr, unsigned int addrspace) {
  if (!ptr)
    return false;

  const Type *ptrType = ptr->getType();
  return dyn_cast<PointerType>(ptrType)->getAddressSpace() == addrspace;
}


static bool check_attribute(const Value *ptr, unsigned int addrspace) {
  if (!ptr)
    return false;

  const Type *ptrType = ptr->getType();
  if (ptrType->isPointerTy()) {
    const PointerType *PT = dyn_cast<PointerType>(ptrType);
    Type *CT = PT->getElementType();
    const StructType *ST = dyn_cast<StructType>(CT);
    unsigned as = PT->getAddressSpace();
    
    if (ST && (as == addrspace)) {
      return true;
    }
    else return false;
  }
  return false;
}

bool HSAILDAGToDAGISel::isGlobalStore(StoreSDNode *N) const {
  const Value *V = N->getSrcValue();
  if (V == NULL) return false;

  return check_type(V, Subtarget->getGlobalAS());
}

bool HSAILDAGToDAGISel::isGroupStore(StoreSDNode *N) const {
  return check_type(N->getSrcValue(), Subtarget->getGroupAS());
}

bool HSAILDAGToDAGISel::isPrivateStore(StoreSDNode *N) const {
  return check_type(N->getSrcValue(), Subtarget->getPrivateAS());
}

bool HSAILDAGToDAGISel::isSpillStore(StoreSDNode *N) const {
  return check_type(N->getSrcValue(), Subtarget->getSpillAS());
}

bool HSAILDAGToDAGISel::isArgStore(StoreSDNode *N) const {
  return check_type(N->getSrcValue(), Subtarget->getArgAS());
}

bool HSAILDAGToDAGISel::isFlatStore(StoreSDNode *N) const {
  return !check_type(N->getSrcValue(), Subtarget->getGlobalAS()) &&
         !check_type(N->getSrcValue(), Subtarget->getConstantAS()) &&
         !check_type(N->getSrcValue(), Subtarget->getGroupAS()) &&
         !check_type(N->getSrcValue(), Subtarget->getPrivateAS()) &&
         !check_type(N->getSrcValue(), Subtarget->getSpillAS()) &&
         !check_type(N->getSrcValue(), Subtarget->getArgAS());
}

LoadSDNode* HSAILDAGToDAGISel::getAncestorLoad(SDNode *N) const{

  LoadSDNode *N1;
  N1 = dyn_cast<LoadSDNode>(N);
  if (N1) return N1;
  for (unsigned i =0; i < N->getNumOperands(); i++) {
    N1 = dyn_cast<LoadSDNode>(N->getOperand(i).getNode());
    if (N1) return N1;
  }
  return NULL;
}

bool HSAILDAGToDAGISel::isGlobalLoad(LoadSDNode *N) const {
  const Value *V = N->getSrcValue();
  if (V == NULL) return false;

  return check_type(V, Subtarget->getGlobalAS());
}

bool HSAILDAGToDAGISel::isConstantLoad(LoadSDNode *N, int cbID) const {
  const Value *V = N->getSrcValue();
  if (V == NULL) return false;

  if (check_type(V, Subtarget->getConstantAS()))
    return true;

  return false;
}

bool HSAILDAGToDAGISel::isGroupLoad(LoadSDNode *N) const {
  return check_type(N->getSrcValue(), Subtarget->getGroupAS());
}

bool HSAILDAGToDAGISel::isPrivateLoad(LoadSDNode *N) const {
  return check_type(N->getSrcValue(), Subtarget->getPrivateAS());
}

bool HSAILDAGToDAGISel::isSpillLoad(LoadSDNode *N) const {
  return check_type(N->getSrcValue(), Subtarget->getSpillAS());
}

bool HSAILDAGToDAGISel::isKernargLoad(LoadSDNode *N) const {
  return check_type(N->getSrcValue(), Subtarget->getKernargAS());
}

bool HSAILDAGToDAGISel::isArgLoad(LoadSDNode *N) const {
  return check_type(N->getSrcValue(), Subtarget->getArgAS());
}

bool HSAILDAGToDAGISel::isFlatLoad(LoadSDNode *N) const {
  return !check_type(N->getSrcValue(), Subtarget->getGlobalAS()) &&
         !check_type(N->getSrcValue(), Subtarget->getConstantAS()) &&
         !check_type(N->getSrcValue(), Subtarget->getGroupAS()) &&
         !check_type(N->getSrcValue(), Subtarget->getPrivateAS()) &&
         !check_type(N->getSrcValue(), Subtarget->getSpillAS()) &&
         !check_type(N->getSrcValue(), Subtarget->getKernargAS()) &&
         !check_type(N->getSrcValue(), Subtarget->getArgAS());
}

/// Query the target data for target pointer size as defined in datalayout
///
unsigned 
HSAILDAGToDAGISel::getPointerSize(void) const {
  const HSAILTargetMachine &HTM = static_cast<const HSAILTargetMachine &>(TM);
  unsigned res = HTM.getDataLayout()->getPointerSize();
  return res; 
}

/// createHSAILISelDag - This pass converts a legalized DAG into a
/// HSAIL-specific DAG, ready for instruction scheduling.
FunctionPass*
llvm::createHSAILISelDag(HSAILTargetMachine &TM,
    llvm::CodeGenOpt::Level OptLevel)
{
  return new HSAILDAGToDAGISel(TM, OptLevel);
}
