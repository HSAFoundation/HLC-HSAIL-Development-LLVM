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
#include "llvm/IR/DerivedTypes.h"
#include "llvm/CodeGen/SelectionDAG.h"
using namespace llvm;

HSAILSelectionDAGInfo::HSAILSelectionDAGInfo(const HSAILTargetMachine &TM)
  : TargetSelectionDAGInfo(TM.getSubtarget<HSAILSubtarget>().getDataLayout()),
    Subtarget(&TM.getSubtarget<HSAILSubtarget>())
    {}

HSAILSelectionDAGInfo::~HSAILSelectionDAGInfo() {}
