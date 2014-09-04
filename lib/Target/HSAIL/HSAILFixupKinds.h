//===-- HSAILFixupKinds.h - HSAIL Specific Fixup Entries --------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef _HSAIL_FIXUP_KINDS_H_
#define _HSAIL_FIXUP_KINDS_H_

#include "llvm/MC/MCFixup.h"

namespace llvm {
namespace HSAIL {
enum Fixups {
  // Marker
  LastTargetFixupKind,
  NumTargetFixupKinds = LastTargetFixupKind - FirstTargetFixupKind
};
}
}

#endif // _HSAIL_FIXUP_KINDS_H_
