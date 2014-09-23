//===- HSAILSelectionDAGInfo.h - HSAIL SelectionDAG Info --------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the HSAIL subclass for TargetSelectionDAGInfo.
//
//===----------------------------------------------------------------------===//

#ifndef _HSAIL_SELECTION_DAG_INFO_H_
#define _HSAIL_SELECTION_DAG_INFO_H_

#include "llvm/Target/TargetSelectionDAGInfo.h"

namespace llvm {

class HSAILTargetLowering;
class HSAILTargetMachine;
class HSAILSubtarget;

class HSAILSelectionDAGInfo : public TargetSelectionDAGInfo {
  /// Subtarget - Keep a pointer to the HSAILSubtarget around so that we can
  /// make the right decision when generating code for different targets.
  const HSAILSubtarget *Subtarget;

public:
  explicit HSAILSelectionDAGInfo(const HSAILTargetMachine &TM);
  ~HSAILSelectionDAGInfo();
};

} // end llvm namespace

#endif // _HSAIL_SELECTION_DAG_INFO_H_
