//===-- HSAILBrig.h - Definitions for BRIG files --------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the HSAIL specific subclass of TargetMachine.
//
//===----------------------------------------------------------------------===//

#ifndef HSAILBRIG_H_
#define HSAILBRIG_H_

namespace Brig {

typedef uint16_t BrigType16_t;

enum BrigSegment {
  BRIG_SEGMENT_FLAT   = 1,
  BRIG_SEGMENT_GLOBAL = 2,
  BRIG_SEGMENT_GROUP  = 5,
};

enum BrigTypeX {

  BRIG_TYPE_NONE = 0, //.mnemo=""
  BRIG_TYPE_U8 = 1, //.ctype=uint8_t // unsigned integer 8 bits
  BRIG_TYPE_U16 = 2, //.ctype=uint16_t // unsigned integer 16 bits
  BRIG_TYPE_U32 = 3, //.ctype=uint32_t // unsigned integer 32 bits
  BRIG_TYPE_U64 = 4, //.ctype=uint64_t // unsigned integer 64 bits
  BRIG_TYPE_S8 = 5, //.ctype=int8_t // signed integer 8 bits
  BRIG_TYPE_S16 = 6, //.ctype=int16_t // signed integer 16 bits
  BRIG_TYPE_S32 = 7, //.ctype=int32_t // signed integer 32 bits
  BRIG_TYPE_S64 = 8, //.ctype=int64_t // signed integer 64 bits
  BRIG_TYPE_F16 = 9, //.ctype=f16_t // floating-point 16 bits
  BRIG_TYPE_F32 = 10, //.ctype=float // floating-point 32 bits
  BRIG_TYPE_F64 = 11, //.ctype=double // floating-point 64 bits
  BRIG_TYPE_B1 = 12, //.ctype=bool //.numBytes=1 // uninterpreted bit string of length 1 bit
  BRIG_TYPE_B8 = 13, //.ctype=uint8_t // uninterpreted bit string of length 8 bits
  BRIG_TYPE_B16 = 14, //.ctype=uint16_t // uninterpreted bit string of length 16 bits
  BRIG_TYPE_B32 = 15, //.ctype=uint32_t // uninterpreted bit string of length 32 bits
  BRIG_TYPE_B64 = 16, //.ctype=uint64_t // uninterpreted bit string of length 64 bits
  BRIG_TYPE_B128 = 17, //.ctype=b128_t // uninterpreted bit string of length 128 bits
  BRIG_TYPE_SAMP = 18, //.mnemo=samp //.numBits=64 // sampler object
  BRIG_TYPE_ROIMG = 19, //.mnemo=roimg //.numBits=64 // read-only image object
  BRIG_TYPE_WOIMG = 20, //.mnemo=woimg //.numBits=64 // write-only image object
  BRIG_TYPE_RWIMG = 21, //.mnemo=rwimg //.numBits=64 // read/write image object
  BRIG_TYPE_SIG32 = 22, //.mnemo=sig32 //.numBits=64 // signal handle to signal object with 32 bit signal value
  BRIG_TYPE_SIG64 = 23, //.mnemo=sig64 //.numBits=64 // signal handle to signal object with 64 bit signal value

  BRIG_TYPE_INVALID = -1 //.skip

};

enum BrigWidth {
  BRIG_WIDTH_NONE = 0,
  BRIG_WIDTH_1 = 1,
  BRIG_WIDTH_2 = 2,
  BRIG_WIDTH_4 = 3,
  BRIG_WIDTH_8 = 4,
  BRIG_WIDTH_16 = 5,
  BRIG_WIDTH_32 = 6,
  BRIG_WIDTH_64 = 7,
  BRIG_WIDTH_128 = 8,
  BRIG_WIDTH_256 = 9,
  BRIG_WIDTH_512 = 10,
  BRIG_WIDTH_1024 = 11,
  BRIG_WIDTH_2048 = 12,
  BRIG_WIDTH_4096 = 13,
  BRIG_WIDTH_8192 = 14,
  BRIG_WIDTH_16384 = 15,
  BRIG_WIDTH_32768 = 16,
  BRIG_WIDTH_65536 = 17,
  BRIG_WIDTH_131072 = 18,
  BRIG_WIDTH_262144 = 19,
  BRIG_WIDTH_524288 = 20,
  BRIG_WIDTH_1048576 = 21,
  BRIG_WIDTH_2097152 = 22,
  BRIG_WIDTH_4194304 = 23,
  BRIG_WIDTH_8388608 = 24,
  BRIG_WIDTH_16777216 = 25,
  BRIG_WIDTH_33554432 = 26,
  BRIG_WIDTH_67108864 = 27,
  BRIG_WIDTH_134217728 = 28,
  BRIG_WIDTH_268435456 = 29,
  BRIG_WIDTH_536870912 = 30,
  BRIG_WIDTH_1073741824 = 31,
  BRIG_WIDTH_2147483648 = 32,
  BRIG_WIDTH_WAVESIZE = 33,
  BRIG_WIDTH_ALL = 34
};


}

#endif //HSAILBRIG_H_
