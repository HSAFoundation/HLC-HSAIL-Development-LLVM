//===-- HSAILMCAsmInfo.cpp - HSAIL asm properties -------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declarations of the HSAILMCAsmInfo properties.
//
//===----------------------------------------------------------------------===//

#include "HSAILMCAsmInfo.h"
#include "HSAILTargetMachine.h"
#include "llvm/ADT/Triple.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCSectionELF.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ELF.h"
using namespace llvm;

HSAILELFMCAsmInfo::HSAILELFMCAsmInfo(const Triple &TT) {
  PrivateGlobalPrefix = "&";
  PrivateLabelPrefix = "@";
  GlobalDirective = "global";
  SupportsQuotedNames = false;
  HasDotTypeDotSizeDirective = false;
  HasSingleParameterDotFile = false;

  // We must set SupportsDebugInformation to true in order for debug info  to
  // be generated.  This shouldn't cause unwanted output, because if the FE
  // does not produce debug metadata (no -g option) then there won't be (much)
  // debug info generated.
  // TODO: we may need to especially ensure that when -g is not passed to the
  // FE,
  //        BRIGAsmPrinter does not create large ".text", etc., sections in
  //        order to
  //        save space and I/O time.
  //

  // FIXME: Setting SupportsDebugInformation to true causes an assertion
  // failure in the AsmPrinter() destructor.
  // Assertion `!DD && Handlers.empty() && "Debug/EH info didn't get finalized"'
  // failed.
  SupportsDebugInformation = false;

  PointerSize = TT.getArch() == Triple::hsail64 ? 8 : 4;

  ExceptionsType = ExceptionHandling::None;
  //  DwarfRequiresFrameSection = false;
  CommentString = "//";
  Data8bitsDirective = "sectiondata_b8\t";
  Data16bitsDirective = "sectiondata_b16\t";
  Data32bitsDirective = "sectiondata_b32\t";
  Data64bitsDirective = "sectiondata_b64\t";
}

MCSection *
HSAILELFMCAsmInfo::getNonexecutableStackSection(MCContext &Ctx) const {
  return nullptr;
}

static bool isValidChar(char C) {
  return (C >= 'a' && C <= 'z') || (C >= 'A' && C <= 'Z') ||
         (C >= '0' && C <= '9') || C == '_' || C == '$' || C == '.' || C == '@';
}

static bool isValidFirstChar(char C) {
  return isValidChar(C) && C != '.' && !(C >= '0' && C <= '9');
}

bool HSAILELFMCAsmInfo::isValidUnquotedName(StringRef Name) const {
  char First = Name.front();
  assert((First == '%' || First == '&' || First == '@') &&
         "Missing valid prefix character");
  Name = Name.drop_front(1);

  if (!Name.empty()) {
    if (!isValidFirstChar(Name.front()))
      return false;

    Name = Name.drop_front();
  }

  for (char C : Name) {
    if (!isValidChar(C))
      return false;
  }

  return true;
}
