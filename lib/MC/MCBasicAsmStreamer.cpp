//===- lib/MC/MCBasicAsmStreamer.cpp - Basic Text Assembly Output ---------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "llvm/MC/MCBasicAsmStreamer.h"
#include "llvm/MC/MCFixupKindInfo.h"

using namespace llvm;

void MCBasicAsmStreamer::EmitCommentsAndEOL() {
  if (CommentToEmit.empty() && CommentStream.GetNumBytesInBuffer() == 0) {
    OS << '\n';
    return;
  }

  StringRef Comments = CommentToEmit;

  assert(Comments.back() == '\n' &&
         "Comment array not newline terminated");
  do {
    // Emit a line of comments.
    OS.PadToColumn(MAI->getCommentColumn());
    size_t Position = Comments.find('\n');
    OS << MAI->getCommentString() << ' ' << Comments.substr(0, Position) <<'\n';

    Comments = Comments.substr(Position+1);
  } while (!Comments.empty());

  CommentToEmit.clear();
}

void MCBasicAsmStreamer::AddComment(const Twine &T) {
  if (!IsVerboseAsm)
    return;

  T.toVector(CommentToEmit);
  // Each comment goes on its own line.
  CommentToEmit.push_back('\n');
}

void MCBasicAsmStreamer::AddEncodingComment(const MCInst &Inst,
                                            const MCSubtargetInfo &STI) {
  raw_ostream &OS = GetCommentOS();
  SmallString<256> Code;
  SmallVector<MCFixup, 4> Fixups;
  raw_svector_ostream VecOS(Code);
  Emitter->encodeInstruction(Inst, VecOS, Fixups, STI);

  // If we are showing fixups, create symbolic markers in the encoded
  // representation. We do this by making a per-bit map to the fixup item index,
  // then trying to display it as nicely as possible.
  SmallVector<uint8_t, 64> FixupMap;
  FixupMap.resize(Code.size() * 8);
  for (unsigned i = 0, e = Code.size() * 8; i != e; ++i)
    FixupMap[i] = 0;

  for (unsigned i = 0, e = Fixups.size(); i != e; ++i) {
    MCFixup &F = Fixups[i];
    const MCFixupKindInfo &Info = AsmBackend->getFixupKindInfo(F.getKind());
    for (unsigned j = 0; j != Info.TargetSize; ++j) {
      unsigned Index = F.getOffset() * 8 + Info.TargetOffset + j;
      assert(Index < Code.size() * 8 && "Invalid offset in fixup!");
      FixupMap[Index] = 1 + i;
    }
  }

  // FIXME: Note the fixup comments for Thumb2 are completely bogus since the
  // high order halfword of a 32-bit Thumb2 instruction is emitted first.
  OS << "encoding: [";
  for (unsigned i = 0, e = Code.size(); i != e; ++i) {
    if (i)
      OS << ',';

    // See if all bits are the same map entry.
    uint8_t MapEntry = FixupMap[i * 8 + 0];
    for (unsigned j = 1; j != 8; ++j) {
      if (FixupMap[i * 8 + j] == MapEntry)
        continue;

      MapEntry = uint8_t(~0U);
      break;
    }

    if (MapEntry != uint8_t(~0U)) {
      if (MapEntry == 0) {
        OS << format("0x%02x", uint8_t(Code[i]));
      } else {
        if (Code[i]) {
          // FIXME: Some of the 8 bits require fix up.
          OS << format("0x%02x", uint8_t(Code[i])) << '\''
             << char('A' + MapEntry - 1) << '\'';
        } else
          OS << char('A' + MapEntry - 1);
      }
    } else {
      // Otherwise, write out in binary.
      OS << "0b";
      for (unsigned j = 8; j--;) {
        unsigned Bit = (Code[i] >> j) & 1;

        unsigned FixupBit;
        if (MAI->isLittleEndian())
          FixupBit = i * 8 + j;
        else
          FixupBit = i * 8 + (7-j);

        if (uint8_t MapEntry = FixupMap[FixupBit]) {
          assert(Bit == 0 && "Encoder wrote into fixed up bit!");
          OS << char('A' + MapEntry - 1);
        } else
          OS << Bit;
      }
    }
  }
  OS << "]\n";

  for (unsigned i = 0, e = Fixups.size(); i != e; ++i) {
    MCFixup &F = Fixups[i];
    const MCFixupKindInfo &Info = AsmBackend->getFixupKindInfo(F.getKind());
    OS << "  fixup " << char('A' + i) << " - " << "offset: " << F.getOffset()
       << ", value: " << *F.getValue() << ", kind: " << Info.Name << "\n";
  }
}

void MCBasicAsmStreamer::EmitInstruction(const MCInst &Inst,
                                         const MCSubtargetInfo &STI) {
  assert(getCurrentSection().first &&
         "Cannot emit contents before setting section!");

  // Show the encoding in a comment if we have a code emitter.
  if (Emitter)
    AddEncodingComment(Inst, STI);

  // Show the MCInst if enabled.
  if (ShowInst) {
    Inst.dump_pretty(GetCommentOS(), InstPrinter.get(), "\n ");
    GetCommentOS() << "\n";
  }

  if(getTargetStreamer())
    getTargetStreamer()->prettyPrintAsm(*InstPrinter, OS, Inst, STI);
  else
    InstPrinter->printInst(&Inst, OS, "", STI);

  EmitEOL();
}
