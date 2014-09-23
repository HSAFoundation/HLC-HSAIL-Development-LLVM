//===-- HSAILELFObjectFile.h - HSAIL ELF Object Info ------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef _HSAIL_ELF_OBJECT_FILE_H_
#define _HSAIL_ELF_OBJECT_FILE_H_

#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetLoweringObjectFile.h"

namespace llvm {
class HSAILTargetMachine;

class HSAIL32_DwarfTargetObjectFile : public TargetLoweringObjectFileELF {
public:
  HSAIL32_DwarfTargetObjectFile(const HSAILTargetMachine &tm);

};

class HSAIL64_DwarfTargetObjectFile : public TargetLoweringObjectFileELF {
public:
  HSAIL64_DwarfTargetObjectFile(const HSAILTargetMachine &tm);
};

} // end namespace llvm

#endif // _HSAIL_ELF_OBJECT_FILE_H_
