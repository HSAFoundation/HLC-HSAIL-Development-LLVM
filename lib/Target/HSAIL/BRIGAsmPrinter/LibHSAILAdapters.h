//===- LibHSAIL.h - Convert HSAIL LLVM code to assembly ---------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#ifndef LLVM_LIB_TARGET_HSAIL_BRIGASMPRINTER_LIBHSAILADAPTERS_H
#define LLVM_LIB_TARGET_HSAIL_BRIGASMPRINTER_LIBHSAILADAPTERS_H

#include "libHSAIL/HSAILBrigObjectFile.h"

class RawOstreamWriteAdapter : public HSAIL_ASM::WriteAdapter {
  llvm::raw_ostream &os;

public:
  RawOstreamWriteAdapter(llvm::raw_ostream &os_, std::ostream &errs_)
      : IOAdapter(errs_), WriteAdapter(errs_), os(os_){};

  int write(const char *data, size_t numBytes) const override {
    os.write(data, numBytes);
    return 0;
  }

  Position getPos() const override { return os.tell(); }

  void setPos(Position) override { llvm_unreachable("Unimplemented"); }

  ~RawOstreamWriteAdapter() { os.flush(); }
};

#endif
