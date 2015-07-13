//===-- RawVectorOstream.h --------------------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
/// \file
/// Interface for RawVectorOstream which is used for capturing DWARF data from
/// MC
/// layer
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_HSAIL_MCTARGETDESC_RAWVECTOROSTREAM_H
#define LLVM_LIB_TARGET_HSAIL_MCTARGETDESC_RAWVECTOROSTREAM_H

#include "llvm/Support/raw_ostream.h"
#include <vector>

namespace llvm {

class RawVectorOstream : public raw_pwrite_stream {
  static const size_t AllocationChunk = 1024;
  std::vector<char> Data;
  std::vector<char>::size_type Position;
  raw_pwrite_stream *Other;

  void write_impl(const char *Ptr, size_t Size) override;
  void pwrite_impl(const char *Ptr, size_t Size, uint64_t Offset) override;

  uint64_t current_pos() const override;

public:
  explicit RawVectorOstream(raw_pwrite_stream *other);
  virtual ~RawVectorOstream();

  StringRef getData() const {
    return StringRef(Data.data(), Data.size());
  }

  void releaseStream();

  // Other stream is the stream that is used to forward all data written to the
  // instance of RawVectorOstream. If other stream is NULL then RawVectorOstream
  // does not forward captured data to any other stream, it just stores captured
  // data in the internal memory buffer.
  raw_ostream *getOtherStream() {
    return Other;
  }

  void setOtherStream(raw_pwrite_stream *Other);
};
}

#endif
