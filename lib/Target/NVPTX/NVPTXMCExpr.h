//===-- NVPTXMCExpr.h - NVPTX specific MC expression classes ----*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

// Modeled after ARMMCExpr

#ifndef LLVM_LIB_TARGET_NVPTX_NVPTXMCEXPR_H
#define LLVM_LIB_TARGET_NVPTX_NVPTXMCEXPR_H

#include "llvm/ADT/APFloat.h"
#include "llvm/MC/MCExpr.h"

namespace llvm {

class NVPTXFloatMCExpr : public MCTargetExpr {
public:
  enum VariantKind {
    VK_NVPTX_None,
    VK_NVPTX_SINGLE_PREC_FLOAT,   // FP constant in single-precision
    VK_NVPTX_DOUBLE_PREC_FLOAT    // FP constant in double-precision
  };

private:
  const VariantKind Kind;
  const APFloat Flt;

  explicit NVPTXFloatMCExpr(VariantKind Kind, APFloat Flt)
      : Kind(Kind), Flt(Flt) {}

public:
  /// @name Construction
  /// @{

  static const NVPTXFloatMCExpr *Create(VariantKind Kind, APFloat Flt,
                                        MCContext &Ctx);

  static const NVPTXFloatMCExpr *CreateConstantFPSingle(APFloat Flt,
                                                        MCContext &Ctx) {
    return Create(VK_NVPTX_SINGLE_PREC_FLOAT, Flt, Ctx);
  }

  static const NVPTXFloatMCExpr *CreateConstantFPDouble(APFloat Flt,
                                                        MCContext &Ctx) {
    return Create(VK_NVPTX_DOUBLE_PREC_FLOAT, Flt, Ctx);
  }

  /// @}
  /// @name Accessors
  /// @{

  /// getOpcode - Get the kind of this expression.
  VariantKind getKind() const { return Kind; }

  /// getSubExpr - Get the child of this expression.
  APFloat getAPFloat() const { return Flt; }

/// @}

  void PrintImpl(raw_ostream &OS, const MCAsmInfo *MAI) const override;
  bool EvaluateAsRelocatableImpl(MCValue &Res,
                                 const MCAsmLayout *Layout,
                                 const MCFixup *Fixup) const override {
    return false;
  }
  void visitUsedExpr(MCStreamer &Streamer) const override {};
  const MCSection *FindAssociatedSection() const override {
    return nullptr;
  }

  // There are no TLS NVPTXMCExprs at the moment.
  void fixELFSymbolsInTLSFixups(MCAssembler &Asm) const override {}

  static bool classof(const MCExpr *E) {
    return E->getKind() == MCExpr::Target;
  }
};

/// A wrapper for MCSymbolRefExpr that tells the assembly printer that the
/// symbol should be enclosed by generic().
class NVPTXGenericMCSymbolRefExpr : public MCTargetExpr {
private:
  const MCSymbolRefExpr *SymExpr;

  explicit NVPTXGenericMCSymbolRefExpr(const MCSymbolRefExpr *_SymExpr)
      : SymExpr(_SymExpr) {}

public:
  /// @name Construction
  /// @{

  static const NVPTXGenericMCSymbolRefExpr
  *Create(const MCSymbolRefExpr *SymExpr, MCContext &Ctx);

  /// @}
  /// @name Accessors
  /// @{

  /// getOpcode - Get the kind of this expression.
  const MCSymbolRefExpr *getSymbolExpr() const { return SymExpr; }

  /// @}

  void PrintImpl(raw_ostream &OS, const MCAsmInfo *MAI) const override;
  bool EvaluateAsRelocatableImpl(MCValue &Res,
                                 const MCAsmLayout *Layout,
                                 const MCFixup *Fixup) const override {
    return false;
  }
  void visitUsedExpr(MCStreamer &Streamer) const override {};
  const MCSection *FindAssociatedSection() const override {
    return nullptr;
  }

  // There are no TLS NVPTXMCExprs at the moment.
  void fixELFSymbolsInTLSFixups(MCAssembler &Asm) const override {}

  static bool classof(const MCExpr *E) {
    return E->getKind() == MCExpr::Target;
  }
  };
} // end namespace llvm

#endif
