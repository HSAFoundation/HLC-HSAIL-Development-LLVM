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

using namespace llvm;

void RawVectorOstream::write_impl(const char *Ptr, size_t Size) {
  /* copy data to the internal buffer */
  if (Position + Size > Data.size()) {
    /* allocate more memory if required */
    size_t nChunks =
        (Position + Size + AllocationChunk - 1) / AllocationChunk;
    Data.resize(nChunks * AllocationChunk);
  }

  std::copy(Ptr, Ptr + Size, Data.begin() + Position);
  Position += Size;
  /* write data to the other stream, if any provided */
  if (Other) {
    Other->write(Ptr, Size);
  }
}

void RawVectorOstream::pwrite_impl(const char *Ptr, size_t Size, uint64_t Offset) {
  flush();
  memcpy(Data.data() + Offset, Ptr, Size);

  if (Other)
    Other->pwrite(Ptr, Size, Offset);
}

uint64_t RawVectorOstream::current_pos() const {
  return static_cast<uint64_t>(Position);
}

RawVectorOstream::RawVectorOstream(raw_pwrite_stream *other)
    : Data(AllocationChunk), Position(0), Other(other) {}

RawVectorOstream::~RawVectorOstream() {
  // make sure that releaseStream has been called before RawVectorOstream is
  // deleted
  assert(!Other);
#if 0
    if(Other) {
      flush();
      Other->flush();
    }
#endif
}

void RawVectorOstream::releaseStream() {
  if (Other) {
    Other->flush();
  }
  Other = 0;
}

void RawVectorOstream::setOtherStream(raw_pwrite_stream *other) {
  releaseStream();
  Other = other;
}
