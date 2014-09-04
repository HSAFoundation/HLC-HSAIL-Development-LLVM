//===- LibHSAIL.h - Convert HSAIL LLVM code to assembly --*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#ifndef _LIB_HSAIL_ADAPTERS_H_
#define _LIB_HSAIL_ADAPTERS_H_

#include "RawVectorOstream.h"
#include "libHSAIL/HSAILBrigObjectFile.h"

#include <iosfwd>

class RawOstreamWriteAdapter : public HSAIL_ASM::WriteAdapter {
    llvm::raw_ostream& os;
public:
    RawOstreamWriteAdapter(llvm::raw_ostream& os_, std::ostream& errs_)
    : IOAdapter(errs_)
    , WriteAdapter(errs_)
    , os(os_)
    {
    };

    virtual int write(const char* data, size_t numBytes) const {
        os.write(data, numBytes);
        return 0;
    }

    ~RawOstreamWriteAdapter() {
        os.flush();
    }
};


#endif
