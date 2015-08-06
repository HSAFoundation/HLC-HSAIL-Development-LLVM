//===- MCBasicAsmStreamer.h - Simple AsmStreamer ----------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_MC_MCBASICASMSTREAMER_H
#define LLVM_MC_MCBASICASMSTREAMER_H

#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCAsmBackend.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCCodeEmitter.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCInstPrinter.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/FormattedStream.h"

namespace llvm {

// Simplified version of MCAsmStreamer for text formats that don't have a
// structure similar to binary formats with sections etc.
class MCBasicAsmStreamer : public MCStreamer {
protected:
  std::unique_ptr<formatted_raw_ostream> OSOwner;
  formatted_raw_ostream &OS;
  const MCAsmInfo *MAI;
  std::unique_ptr<MCInstPrinter> InstPrinter;
  std::unique_ptr<MCCodeEmitter> Emitter;
  std::unique_ptr<MCAsmBackend> AsmBackend;

  SmallString<128> CommentToEmit;
  raw_svector_ostream CommentStream;

  unsigned IsVerboseAsm : 1;
  unsigned ShowInst : 1;
  unsigned UseDwarfDirectory : 1;

public:
  MCBasicAsmStreamer(MCContext &Context, std::unique_ptr<formatted_raw_ostream> os,
                     bool isVerboseAsm, bool useDwarfDirectory,
                     MCInstPrinter *printer, MCCodeEmitter *emitter,
                     MCAsmBackend *asmbackend, bool showInst)
      : MCStreamer(Context), OSOwner(std::move(os)), OS(*OSOwner),
        MAI(Context.getAsmInfo()), InstPrinter(printer), Emitter(emitter),
        AsmBackend(asmbackend), CommentStream(CommentToEmit),
        IsVerboseAsm(isVerboseAsm), ShowInst(showInst),
        UseDwarfDirectory(useDwarfDirectory) {
    assert(InstPrinter);
    if (IsVerboseAsm)
        InstPrinter->setCommentStream(CommentStream);
  }

  inline void EmitEOL() {
    // If we don't have any comments, just emit a \n.
    if (!IsVerboseAsm) {
      OS << '\n';
      return;
    }
    EmitCommentsAndEOL();
  }

  void EmitCommentsAndEOL();

  /// Return true if this streamer supports verbose assembly at all.
  bool isVerboseAsm() const override {
    return IsVerboseAsm;
  }

  /// We support EmitRawText.
  bool hasRawTextSupport() const override {
    return true;
  }

  /// Add a comment that can be emitted to the generated .s file if applicable
  /// as a QoI issue to make the output of the compiler more readable.  This
  /// only affects the MCAsmStreamer, and only when verbose assembly output is
  /// enabled.
  void AddComment(const Twine &T) override;

  /// Add a comment showing the encoding of an instruction.
  void AddEncodingComment(const MCInst &Inst, const MCSubtargetInfo &);

  /// Return a raw_ostream that comments can be written to.  Unlike AddComment,
  /// you are required to terminate comments with \n if you use this method.
  raw_ostream &GetCommentOS() override {
    if (!IsVerboseAsm)
      return nulls();  // Discard comments unless in verbose asm mode.
    return CommentStream;
  }

  void emitRawComment(const Twine &T, bool TabPrefix = true) override {
    if (TabPrefix)
      OS << '\t';
    OS << MAI->getCommentString() << T;
    EmitEOL();
  }

  /// Emit a blank line to a .s file to pretty it up.
  void AddBlankLine() override {
    EmitEOL();
  }

  /// If this file is backed by an assembly streamer, this dumps the specified
  /// string in the output .s file.  This capability is indicated by the
  /// hasRawTextSupport() predicate.
  void EmitRawTextImpl(StringRef String) override {
    if (!String.empty() && String.back() == '\n')
      String = String.substr(0, String.size()-1);
    OS << String;
    EmitEOL();
  }

  void EmitLabel(MCSymbol *Symbol) override {
    assert(Symbol->isUndefined() && "Cannot define a symbol twice!");
    MCStreamer::EmitLabel(Symbol);

    Symbol->print(OS, MAI);
    OS << MAI->getLabelSuffix();

    EmitEOL();
  }

  void EmitInstruction(const MCInst &Inst, const MCSubtargetInfo &STI) override;
};

}

#endif
