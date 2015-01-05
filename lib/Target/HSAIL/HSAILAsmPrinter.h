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
#include <vector>

namespace llvm {

class ConstantFP;

class HSAILAsmPrinter : public AsmPrinter {
private:
  typedef std::pair<uint64_t, const MCExpr *> AddrInit;

  StringRef getArgTypeName(Type *Ty) const;

  void EmitFunctionArgument(unsigned ParamIndex,
                            const Argument &Arg,
                            bool IsKernel,
                            raw_ostream &O) const;
  void EmitFunctionReturn(Type *Ty,
                          bool IsKernel,
                          raw_ostream &O) const;
  void EmitFunctionLabel(const Function &F, raw_ostream &O) const;

  static char getSymbolPrefixForAddressSpace(unsigned AS);
  char getSymbolPrefix(const MCSymbol &S) const;

  void printInitVarWithAddressPragma(StringRef VarName,
                                     uint64_t Offset,
                                     const MCExpr *Expr,
                                     unsigned EltSize,
                                     raw_ostream &O);

  void printFloat(uint32_t, raw_ostream &O);
  void printDouble(uint64_t, raw_ostream &O);
  void printConstantFP(const ConstantFP *CV, raw_ostream &O);
  void printScalarConstant(const Constant *CV,
                           SmallVectorImpl<AddrInit> &Addrs,
                           uint64_t &TotalSizeEmitted,
                           const DataLayout &DL,
                           raw_ostream &O);

  void printGVInitialValue(const GlobalValue &GV,
                           const Constant *CV,
                           const DataLayout &DL,
                           raw_ostream &O);

protected:
  // Returns the type to use when expressing the type in HSAIL. If this will be
  // expressed as an HSAIL array, set NElts to the number of elements, otherwise
  // 0.
  static Type *analyzeType(Type *Ty,
                           unsigned &NElts,
                           const DataLayout &DL,
                           LLVMContext &Ctx);
public:
  explicit HSAILAsmPrinter(TargetMachine &TM, MCStreamer &Streamer);

  bool doFinalization(Module &M) override;
  bool runOnMachineFunction(MachineFunction &MF) override;

  const char *getPassName() const override {
    return "HSAIL Assembly Printer";
  }

  /// Implemented in HSAILMCInstLower.cpp
  void EmitInstruction(const MachineInstr *MI) override;

  void EmitGlobalVariable(const GlobalVariable *GV) override;
  void EmitStartOfAsmFile(Module &) override;
  void EmitFunctionEntryLabel() override;
  void EmitFunctionBodyStart() override;
  void EmitFunctionBodyEnd() override;
};

} // End anonymous llvm

#endif
