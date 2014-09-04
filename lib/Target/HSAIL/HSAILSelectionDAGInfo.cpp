//===-- HSAILSelectionDAGInfo.cpp - HSAIL SelectionDAG Info ---------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the HSAILSelectionDAGInfo class.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "HSAIL-selectiondag-info"
#include "HSAILSelectionDAGInfo.h"
#include "HSAILTargetMachine.h"
#include "llvm/DerivedTypes.h"
#include "llvm/CodeGen/SelectionDAG.h"
using namespace llvm;

HSAILSelectionDAGInfo::HSAILSelectionDAGInfo(const HSAILTargetMachine &TM)
  : TargetSelectionDAGInfo(TM),
    Subtarget(&TM.getSubtarget<HSAILSubtarget>()),
    TLI(*TM.getTargetLowering()) {}

HSAILSelectionDAGInfo::~HSAILSelectionDAGInfo() {}

SDValue
HSAILSelectionDAGInfo::EmitTargetCodeForMemset(SelectionDAG &DAG,
                                               DebugLoc dl,
                                               SDValue Chain,
                                               SDValue Dst,
                                               SDValue Src,
                                               SDValue Size,
                                               unsigned Align,
                                               bool isVolatile,
                                               MachinePointerInfo DstPtrInfo) const
{
  assert(!"When do we hit this?");
  return SDValue();
}

SDValue
HSAILSelectionDAGInfo::EmitTargetCodeForMemmove(SelectionDAG &DAG,
                                                DebugLoc dl,
                                                SDValue Chain,
                                                SDValue Op1,
                                                SDValue Op2,
                                                SDValue Op3,
                                                unsigned Align,
                                                bool isVolatile,
                                                MachinePointerInfo DstPtrInfo,
                                                MachinePointerInfo SrcPtrInfo) const
{
  assert(!"When do we hit this?");
  return SDValue();
}

SDValue
HSAILSelectionDAGInfo::EmitTargetCodeForMemcpy(SelectionDAG &DAG,
                                                DebugLoc dl,
                                                SDValue Chain,
                                                SDValue Op1,
                                                SDValue Op2,
                                                SDValue Op3,
                                                unsigned Align,
                                                bool isVolatile,
                                                bool AlwaysInline,
                                                MachinePointerInfo DstPtrInfo,
                                                MachinePointerInfo SrcPtrInfo) const
{
  assert(!"When do we hit this?");
  return SDValue();
}
