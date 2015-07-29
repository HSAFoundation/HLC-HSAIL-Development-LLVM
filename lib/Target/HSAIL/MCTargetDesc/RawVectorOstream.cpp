//===-- RawVectorOstream.cpp ----------------------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "RawVectorOstream.h"

#include "llvm/Support/raw_ostream.h"

#include <vector>

namespace llvm {

void RawVectorOstream::write_impl(const char *Ptr, size_t Size) {
  /* copy data to the internal buffer */
  if (_position + Size > _data.size()) {
    /* allocate more memory if required */
    size_t nChunks =
        (_position + Size + allocation_chunk - 1) / allocation_chunk;
    _data.resize(nChunks * allocation_chunk);
  }
  std::copy(Ptr, Ptr + Size, _data.begin() + _position);
  _position += Size;
  /* write data to the other stream, if any provided */
  if (_other) {
    _other->write(Ptr, Size);
  }
}

uint64_t RawVectorOstream::current_pos() const {
  return static_cast<uint64_t>(_position);
}

const std::vector<char> &RawVectorOstream::getData() const { return _data; }

RawVectorOstream::RawVectorOstream(raw_ostream *other)
    : _data(allocation_chunk), _position(0), _other(other) {}

RawVectorOstream::~RawVectorOstream() {
  // make sure that releaseStream has been called before RawVectorOstream is
  // deleted
  assert(!_other);
#if 0
    if(_other) {
      flush();
      _other->flush();
    }
#endif
}

void RawVectorOstream::releaseStream() {
  if (_other) {
    _other->flush();
  }
  _other = 0;
}

raw_ostream *RawVectorOstream::getOtherStream() { return _other; }

void RawVectorOstream::setOtherStream(raw_ostream *other) {
  releaseStream();
  _other = other;
}
}
