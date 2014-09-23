// interface for RawVectorOstream which is used for capturing DWARF data from MC layer
#ifndef RAW_VECTOR_OSTREAM_H
#define RAW_VECTOR_OSTREAM_H

#include "llvm/Support/raw_ostream.h"
#include <vector>

namespace llvm {

  class RawVectorOstream: public llvm::raw_ostream {
    static const size_t allocation_chunk = 1024;
    std::vector<char>            _data;
    std::vector<char>::size_type _position;
    raw_ostream*                 _other;

    /// write_impl - The is the piece of the class that is implemented
    /// by subclasses.  This writes the \args Size bytes starting at
    /// \arg Ptr to the underlying stream.
    ///
    /// This function is guaranteed to only be called at a point at which it is
    /// safe for the subclass to install a new buffer via SetBuffer.
    ///
    /// \arg Ptr - The start of the data to be written. For buffered streams this
    /// is guaranteed to be the start of the buffer.
    /// \arg Size - The number of bytes to be written.
    ///
    /// \invariant { Size > 0 }
    virtual void write_impl(const char *Ptr, size_t Size);

    /// current_pos - Return the current position within the stream, not
    /// counting the bytes currently in the buffer.
    virtual uint64_t current_pos() const;

  public:
    explicit RawVectorOstream(raw_ostream* other);
    virtual ~RawVectorOstream();

    const std::vector<char>& getData() const;
    void releaseStream();

    /* other stream is the stream that is used to forward all data written 
     * to the instance of RawVectorOstream. If other stream is NULL then 
     * RawVectorOstream does not forward captured data to any other stream,
     * it just stores captured data in the internal memory buffer */
    raw_ostream* getOtherStream();
    void setOtherStream(raw_ostream* other);
  };

}

#else
#endif //RAW_VECTOR_OSTREAM_H

