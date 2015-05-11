//===- MCSymbol.h - Machine Code Symbols ------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declaration of the MCSymbol class.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_MC_MCSYMBOL_H
#define LLVM_MC_MCSYMBOL_H

#include "llvm/ADT/StringRef.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/Support/Compiler.h"

namespace llvm {
  class MCAsmInfo;
  class MCExpr;
  class MCSection;
  class MCContext;
  class raw_ostream;

  /// MCSymbol - Instances of this class represent a symbol name in the MC file,
  /// and MCSymbols are created and uniqued by the MCContext class.  MCSymbols
  /// should only be constructed with valid names for the object file.
  ///
  /// If the symbol is defined/emitted into the current translation unit, the
  /// Section member is set to indicate what section it lives in.  Otherwise, if
  /// it is a reference to an external entity, it has a null section.
  class MCSymbol {
    // Special sentinal value for the absolute pseudo section.
    //
    // FIXME: Use a PointerInt wrapper for this?
    static const MCSection *AbsolutePseudoSection;

    /// Name - The name of the symbol.  The referred-to string data is actually
    /// held by the StringMap that lives in MCContext.
    StringRef Name;

    /// Section - The section the symbol is defined in. This is null for
    /// undefined symbols, and the special AbsolutePseudoSection value for
    /// absolute symbols. If this is a variable symbol, this caches the
    /// variable value's section.
    mutable const MCSection *Section;

    /// Value - If non-null, the value for a variable symbol.
    const MCExpr *Value;

    /// IsTemporary - True if this is an assembler temporary label, which
    /// typically does not survive in the .o file's symbol table.  Usually
    /// "Lfoo" or ".foo".
    unsigned IsTemporary : 1;

    /// \brief True if this symbol can be redefined.
    unsigned IsRedefinable : 1;

    /// IsUsed - True if this symbol has been used.
    mutable unsigned IsUsed : 1;

  private:  // MCContext creates and uniques these.
    friend class MCExpr;
    friend class MCContext;
    MCSymbol(StringRef name, bool isTemporary)
      : Name(name), Section(nullptr), Value(nullptr),
        IsTemporary(isTemporary), IsRedefinable(false), IsUsed(false) {}

    MCSymbol(const MCSymbol&) = delete;
    void operator=(const MCSymbol&) = delete;
    const MCSection *getSectionPtr() const {
      if (Section || !Value)
        return Section;
      return Section = Value->FindAssociatedSection();
    }

  public:
    /// getName - Get the symbol name.
    StringRef getName() const { return Name; }

    /// \name Accessors
    /// @{

    /// isTemporary - Check if this is an assembler temporary symbol.
    bool isTemporary() const { return IsTemporary; }

    /// isUsed - Check if this is used.
    bool isUsed() const { return IsUsed; }
    void setUsed(bool Value) const { IsUsed = Value; }

    /// \brief Check if this symbol is redefinable.
    bool isRedefinable() const { return IsRedefinable; }
    /// \brief Mark this symbol as redefinable.
    void setRedefinable(bool Value) { IsRedefinable = Value; }
    /// \brief Prepare this symbol to be redefined.
    void redefineIfPossible() {
      if (IsRedefinable) {
        Value = nullptr;
        Section = nullptr;
        IsRedefinable = false;
      }
    }

    /// @}
    /// \name Associated Sections
    /// @{

    /// isDefined - Check if this symbol is defined (i.e., it has an address).
    ///
    /// Defined symbols are either absolute or in some section.
    bool isDefined() const {
      return getSectionPtr() != nullptr;
    }

    /// isInSection - Check if this symbol is defined in some section (i.e., it
    /// is defined but not absolute).
    bool isInSection() const {
      return isDefined() && !isAbsolute();
    }

    /// isUndefined - Check if this symbol undefined (i.e., implicitly defined).
    bool isUndefined() const {
      return !isDefined();
    }

    /// isAbsolute - Check if this is an absolute symbol.
    bool isAbsolute() const {
      return getSectionPtr() == AbsolutePseudoSection;
    }

    /// getSection - Get the section associated with a defined, non-absolute
    /// symbol.
    const MCSection &getSection() const {
      assert(isInSection() && "Invalid accessor!");
      return *getSectionPtr();
    }

    /// setSection - Mark the symbol as defined in the section \p S.
    void setSection(const MCSection &S) {
      assert(!isVariable() && "Cannot set section of variable");
      Section = &S;
    }

    /// setUndefined - Mark the symbol as undefined.
    void setUndefined() {
      Section = nullptr;
    }

    /// @}
    /// \name Variable Symbols
    /// @{

    /// isVariable - Check if this is a variable symbol.
    bool isVariable() const {
      return Value != nullptr;
    }

    /// getVariableValue() - Get the value for variable symbols.
    const MCExpr *getVariableValue() const {
      assert(isVariable() && "Invalid accessor!");
      IsUsed = true;
      return Value;
    }

    void setVariableValue(const MCExpr *Value);

    /// @}

    /// print - Print the value to the stream \p OS.
    void print(raw_ostream &OS, const MCAsmInfo *) const;

    /// dump - Print the value to stderr.
    void dump() const;
  };
} // end namespace llvm

#endif
