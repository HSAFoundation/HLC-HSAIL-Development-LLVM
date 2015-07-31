//===-- HSAILMCAsmStreamer.cpp --------------------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "HSAILMCAsmStreamer.h"

#include "llvm/MC/MCBasicAsmStreamer.h"
#include "llvm/MC/MCAsmBackend.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCCodeEmitter.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstPrinter.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/FormattedStream.h"

using namespace llvm;

namespace {

class HSAILMCAsmStreamer final : public MCBasicAsmStreamer {
public:
  HSAILMCAsmStreamer(MCContext &Context,
                     std::unique_ptr<formatted_raw_ostream> os,
                     bool isVerboseAsm, bool useDwarfDirectory,
                     MCInstPrinter *printer, MCCodeEmitter *emitter,
                     MCAsmBackend *asmbackend, bool showInst)
    : MCBasicAsmStreamer(Context, std::move(os),
                         isVerboseAsm, useDwarfDirectory,
                         printer, emitter, asmbackend, showInst) {}

  bool EmitSymbolAttribute(MCSymbol *Symbol,
                           MCSymbolAttr Attribute) override {
    llvm_unreachable("unimplemented");
  }

  void EmitCommonSymbol(MCSymbol *Symbol, uint64_t Size,
                        unsigned ByteAlignment) override {
    llvm_unreachable("unimplemented");
  }

  void EmitZerofill(MCSection *Section, MCSymbol *Symbol = nullptr,
                    uint64_t Size = 0, unsigned ByteAlignment = 0) override {
    llvm_unreachable("unimplemented");
  }
};

}

MCStreamer *llvm::createHSAILMCAsmStreamer(
  MCContext &Context,
  std::unique_ptr<formatted_raw_ostream> OS,
  bool IsVerboseAsm, bool UseDwarfDirectory,
  MCInstPrinter *IP, MCCodeEmitter *CE,
  MCAsmBackend *MAB, bool ShowInst) {
  return new HSAILMCAsmStreamer(Context, std::move(OS), IsVerboseAsm,
                                UseDwarfDirectory, IP, CE, MAB, ShowInst);
}
