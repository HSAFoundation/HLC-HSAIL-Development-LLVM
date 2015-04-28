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

#ifndef RAW_VECTOR_OSTREAM_H
#define RAW_VECTOR_OSTREAM_H

#include "llvm/Support/raw_ostream.h"
#include <vector>

namespace llvm {

class RawVectorOstream : public raw_ostream {
  static const size_t allocation_chunk = 1024;
  std::vector<char> _data;
  std::vector<char>::size_type _position;
  raw_ostream *_other;

  void write_impl(const char *Ptr, size_t Size) override;

  uint64_t current_pos() const override;

public:
  explicit RawVectorOstream(raw_ostream *other);
  virtual ~RawVectorOstream();

  const std::vector<char> &getData() const;
  void releaseStream();

  /* other stream is the stream that is used to forward all data written
   * to the instance of RawVectorOstream. If other stream is NULL then
   * RawVectorOstream does not forward captured data to any other stream,
   * it just stores captured data in the internal memory buffer */
  raw_ostream *getOtherStream();
  void setOtherStream(raw_ostream *other);
};
}

#endif // RAW_VECTOR_OSTREAM_H
