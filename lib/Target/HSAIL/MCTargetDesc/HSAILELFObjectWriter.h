//===-- HSAILELFObjectWriter.h - HSAIL ELF Object Writer --------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#ifndef _HSAIL_ELF_OBJECT_WRITER_H_
#define _HSAIL_ELF_OBJECT_WRITER_H_

#include "llvm/MC/MCELFObjectWriter.h"

namespace llvm {
class HSAILELFObjectWriter : public MCELFObjectTargetWriter {
public:
  HSAILELFObjectWriter(bool is64Bit, uint16_t EMachine,
                       bool HasRelocationAddend);

protected:
  unsigned GetRelocType(const MCValue &Target, const MCFixup &Fixup,
                        bool IsPCRel) const override {
    return 0; // currently return 0, which means no relocation
  }
};
}

#endif // _HSAIL_ELF_OBJECT_WRITER_H_
