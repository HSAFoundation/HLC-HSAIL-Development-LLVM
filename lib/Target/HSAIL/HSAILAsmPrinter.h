//===-- HSAILAsmPrinter.h - Print HSAIL assembly code -----------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
/// \file
/// \brief HSAIL Assembly printer class.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_HSAIL_HSAILASMPRINTER_H
#define LLVM_LIB_TARGET_HSAIL_HSAILASMPRINTER_H

#include "llvm/CodeGen/AsmPrinter.h"

namespace llvm {

class ConstantFP;
class MachineFrameInfo;

template <unsigned> class SmallString;

class HSAILAsmPrinter : public AsmPrinter {
private:
  typedef std::pair<uint64_t, const MCExpr *> AddrInit;

  StringRef getArgTypeName(Type *Ty, bool Signed = false) const;

  void emitFunctionArgument(unsigned ParamIndex, const Argument &Arg,
                            bool IsKernel, bool IsSExt, raw_ostream &O) const;
  void emitFunctionReturn(Type *Ty, StringRef Name, bool IsKernel, bool IsSExt,
                          raw_ostream &O) const;
  void emitFunctionLabel(const Function &F, raw_ostream &O, bool IsDecl) const;

  static char getSymbolPrefixForAddressSpace(unsigned AS);
  char getSymbolPrefix(const MCSymbol &S) const;

  void printInitVarWithAddressPragma(StringRef VarName, uint64_t Offset,
                                     const MCExpr *Expr, unsigned EltSize,
                                     raw_ostream &O);

  void printFloat(uint32_t, raw_ostream &O);
  void printDouble(uint64_t, raw_ostream &O);
  void printConstantFP(const ConstantFP *CV, raw_ostream &O);
  void printScalarConstant(const Constant *CV, SmallVectorImpl<AddrInit> &Addrs,
                           uint64_t &TotalSizeEmitted, const DataLayout &DL,
                           raw_ostream &O);

  void printGVInitialValue(const GlobalValue &GV, const Constant *CV,
                           const DataLayout &DL, raw_ostream &O);

public:
  explicit HSAILAsmPrinter(TargetMachine &TM,
                           std::unique_ptr<MCStreamer> Streamer);

  bool doFinalization(Module &M) override;
  bool runOnMachineFunction(MachineFunction &MF) override;

  const char *getPassName() const override { return "HSAIL Assembly Printer"; }

  void getHSAILMangledName(SmallString<256> &Out, const GlobalValue *GV) const;
  void EmitGlobalVariable(const GlobalVariable *GV) override;
  void EmitStartOfAsmFile(Module &) override;
  void EmitFunctionHeader() override;
  void EmitFunctionEntryLabel() override;

  void checkModuleSubtargetExtensions(const Module &M,
                                      bool &IsFullProfile,
                                      bool &IsGCN,
                                      bool &HasImages) const;
  static bool isHSAILInstrinsic(StringRef str);

  void computeStackUsage(const MachineFrameInfo *MFI,
                         uint64_t &PrivateSize,
                         unsigned &PrivateAlign,
                         uint64_t &SpillSize,
                         unsigned &SpillAlign) const;

  void EmitFunctionBodyStart() override;
  void EmitFunctionBodyEnd() override;
  void EmitInstruction(const MachineInstr *MI) override;
};

}

#endif
