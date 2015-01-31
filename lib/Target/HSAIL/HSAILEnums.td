// University of Illinois/NCSA
// Open Source License
//
// Copyright (c) 2013, Advanced Micro Devices, Inc.
// All rights reserved.
//
// Developed by:
//
//     HSA Team
//
//     Advanced Micro Devices, Inc
//
//     www.amd.com
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal with
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
//     * Redistributions of source code must retain the above copyright notice,
//       this list of conditions and the following disclaimers.
//
//     * Redistributions in binary form must reproduce the above copyright notice,
//       this list of conditions and the following disclaimers in the
//       documentation and/or other materials provided with the distribution.
//
//     * Neither the names of the LLVM Team, University of Illinois at
//       Urbana-Champaign, nor the names of its contributors may be used to
//       endorse or promote products derived from this Software without specific
//       prior written permission.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
// CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS WITH THE
// SOFTWARE.

def BrigAlignment : Operand<i32> {
  let PrintMethod = "printBrigAlignment";
  int _NONE = 0;
  int _1 = 1;
  int _2 = 2;
  int _4 = 3;
  int _8 = 4;
  int _16 = 5;
  int _32 = 6;
  int _64 = 7;
  int _128 = 8;
  int _256 = 9;
  int _LAST = 10;
  int _MAX = 9;
}

def BrigAllocation : Operand<i32> {
  let PrintMethod = "printBrigAllocation";
  int NONE = 0;
  int PROGRAM = 1;
  int AGENT = 2;
  int AUTOMATIC = 3;
}

def BrigAluModifierMask : Operand<i32> {
  let PrintMethod = "printBrigAluModifierMask";
  int ROUND = 31;
  int FTZ = 32;
}

def BrigAtomicOperation : Operand<i32> {
  let PrintMethod = "printBrigAtomicOperation";
  int ADD = 0;
  int AND = 1;
  int CAS = 2;
  int EXCH = 3;
  int LD = 4;
  int MAX = 5;
  int MIN = 6;
  int OR = 7;
  int ST = 8;
  int SUB = 9;
  int WRAPDEC = 10;
  int WRAPINC = 11;
  int XOR = 12;
  int WAIT_EQ = 13;
  int WAIT_NE = 14;
  int WAIT_LT = 15;
  int WAIT_GTE = 16;
  int WAITTIMEOUT_EQ = 17;
  int WAITTIMEOUT_NE = 18;
  int WAITTIMEOUT_LT = 19;
  int WAITTIMEOUT_GTE = 20;
}

def BrigCompareOperation : Operand<i32> {
  let PrintMethod = "printBrigCompareOperation";
  int EQ = 0;
  int NE = 1;
  int LT = 2;
  int LE = 3;
  int GT = 4;
  int GE = 5;
  int EQU = 6;
  int NEU = 7;
  int LTU = 8;
  int LEU = 9;
  int GTU = 10;
  int GEU = 11;
  int NUM = 12;
  int NAN = 13;
  int SEQ = 14;
  int SNE = 15;
  int SLT = 16;
  int SLE = 17;
  int SGT = 18;
  int SGE = 19;
  int SGEU = 20;
  int SEQU = 21;
  int SNEU = 22;
  int SLTU = 23;
  int SLEU = 24;
  int SNUM = 25;
  int SNAN = 26;
  int SGTU = 27;
}

def BrigControlDirective : Operand<i32> {
  let PrintMethod = "printBrigControlDirective";
  int NONE = 0;
  int ENABLEBREAKEXCEPTIONS = 1;
  int ENABLEDETECTEXCEPTIONS = 2;
  int MAXDYNAMICGROUPSIZE = 3;
  int MAXFLATGRIDSIZE = 4;
  int MAXFLATWORKGROUPSIZE = 5;
  int REQUESTEDWORKGROUPSPERCU = 6;
  int REQUIREDDIM = 7;
  int REQUIREDGRIDSIZE = 8;
  int REQUIREDWORKGROUPSIZE = 9;
  int REQUIRENOPARTIALWORKGROUPS = 10;
}

def BrigExecutableModifierMask : Operand<i32> {
  let PrintMethod = "printBrigExecutableModifierMask";
  int DEFINITION = 1;
}

def BrigImageChannelOrder : Operand<i32> {
  let PrintMethod = "printBrigImageChannelOrder";
  int A = 0;
  int R = 1;
  int RX = 2;
  int RG = 3;
  int RGX = 4;
  int RA = 5;
  int RGB = 6;
  int RGBX = 7;
  int RGBA = 8;
  int BGRA = 9;
  int ARGB = 10;
  int ABGR = 11;
  int SRGB = 12;
  int SRGBX = 13;
  int SRGBA = 14;
  int SBGRA = 15;
  int INTENSITY = 16;
  int LUMINANCE = 17;
  int DEPTH = 18;
  int DEPTH_STENCIL = 19;
  int UNKNOWN = 20;
}

def BrigImageChannelType : Operand<i32> {
  let PrintMethod = "printBrigImageChannelType";
  int SNORM_INT8 = 0;
  int SNORM_INT16 = 1;
  int UNORM_INT8 = 2;
  int UNORM_INT16 = 3;
  int UNORM_INT24 = 4;
  int UNORM_SHORT_555 = 5;
  int UNORM_SHORT_565 = 6;
  int UNORM_INT_101010 = 7;
  int SIGNED_INT8 = 8;
  int SIGNED_INT16 = 9;
  int SIGNED_INT32 = 10;
  int UNSIGNED_INT8 = 11;
  int UNSIGNED_INT16 = 12;
  int UNSIGNED_INT32 = 13;
  int HALF_FLOAT = 14;
  int FLOAT = 15;
  int UNKNOWN = 16;
}

def BrigImageGeometry : Operand<i32> {
  let PrintMethod = "printBrigImageGeometry";
  int _1D = 0;
  int _2D = 1;
  int _3D = 2;
  int _1DA = 3;
  int _2DA = 4;
  int _1DB = 5;
  int _2DDEPTH = 6;
  int _2DADEPTH = 7;
  int _UNKNOWN = 8;
}

def BrigImageQuery : Operand<i32> {
  let PrintMethod = "printBrigImageQuery";
  int WIDTH = 0;
  int HEIGHT = 1;
  int DEPTH = 2;
  int ARRAY = 3;
  int CHANNELORDER = 4;
  int CHANNELTYPE = 5;
}

def BrigKinds : Operand<i32> {
  let PrintMethod = "printBrigKinds";
  int NONE = 0x0000;
  int DIRECTIVE_BEGIN = 0x1000;
  int DIRECTIVE_ARG_BLOCK_END = 0x1000;
  int DIRECTIVE_ARG_BLOCK_START = 0x1001;
  int DIRECTIVE_COMMENT = 0x1002;
  int DIRECTIVE_CONTROL = 0x1003;
  int DIRECTIVE_EXTENSION = 0x1004;
  int DIRECTIVE_FBARRIER = 0x1005;
  int DIRECTIVE_FUNCTION = 0x1006;
  int DIRECTIVE_INDIRECT_FUNCTION = 0x1007;
  int DIRECTIVE_KERNEL = 0x1008;
  int DIRECTIVE_LABEL = 0x1009;
  int DIRECTIVE_LOC = 0x100a;
  int DIRECTIVE_PRAGMA = 0x100b;
  int DIRECTIVE_SIGNATURE = 0x100c;
  int DIRECTIVE_VARIABLE = 0x100d;
  int DIRECTIVE_VERSION = 0x100e;
  int DIRECTIVE_END = 0x100f;
  int INST_BEGIN = 0x2000;
  int INST_ADDR = 0x2000;
  int INST_ATOMIC = 0x2001;
  int INST_BASIC = 0x2002;
  int INST_BR = 0x2003;
  int INST_CMP = 0x2004;
  int INST_CVT = 0x2005;
  int INST_IMAGE = 0x2006;
  int INST_LANE = 0x2007;
  int INST_MEM = 0x2008;
  int INST_MEM_FENCE = 0x2009;
  int INST_MOD = 0x200a;
  int INST_QUERY_IMAGE = 0x200b;
  int INST_QUERY_SAMPLER = 0x200c;
  int INST_QUEUE = 0x200d;
  int INST_SEG = 0x200e;
  int INST_SEG_CVT = 0x200f;
  int INST_SIGNAL = 0x2010;
  int INST_SOURCE_TYPE = 0x2011;
  int INST_END = 0x2012;
  int OPERAND_BEGIN = 0x3000;
  int OPERAND_ADDRESS = 0x3000;
  int OPERAND_DATA = 0x3001;
  int OPERAND_CODE_LIST = 0x3002;
  int OPERAND_CODE_REF = 0x3003;
  int OPERAND_IMAGE_PROPERTIES = 0x3004;
  int OPERAND_OPERAND_LIST = 0x3005;
  int OPERAND_REG = 0x3006;
  int OPERAND_SAMPLER_PROPERTIES = 0x3007;
  int OPERAND_STRING = 0x3008;
  int OPERAND_WAVESIZE = 0x3009;
  int OPERAND_END = 12298;
}

def BrigLinkage : Operand<i32> {
  let PrintMethod = "printBrigLinkage";
  int NONE = 0;
  int PROGRAM = 1;
  int MODULE = 2;
  int FUNCTION = 3;
  int ARG = 4;
}

def BrigMachineModel : Operand<i32> {
  let PrintMethod = "printBrigMachineModel";
  int SMALL = 0;
  int LARGE = 1;
  int UNDEF = 2;
}

def BrigMemoryFenceSegments : Operand<i32> {
  let PrintMethod = "printBrigMemoryFenceSegments";
  int GLOBAL = 0;
  int GROUP = 1;
  int IMAGE = 2;
  int LAST = 3;
}

def BrigMemoryModifierMask : Operand<i32> {
  let PrintMethod = "printBrigMemoryModifierMask";
  int CONST = 1;
}

def BrigMemoryOrder : Operand<i32> {
  let PrintMethod = "printBrigMemoryOrder";
  int NONE = 0;
  int RELAXED = 1;
  int SC_ACQUIRE = 2;
  int SC_RELEASE = 3;
  int SC_ACQUIRE_RELEASE = 4;
  int LAST = 5;
}

def BrigMemoryScope : Operand<i32> {
  let PrintMethod = "printBrigMemoryScope";
  int NONE = 0;
  int WORKITEM = 1;
  int WAVEFRONT = 2;
  int WORKGROUP = 3;
  int COMPONENT = 4;
  int SYSTEM = 5;
}

def BrigMemoryScope2 : Operand<i32> {
  let PrintMethod = "printBrigMemoryScope2";
  int NONE = 0;
  int WORKITEM = 1;
  int WAVEFRONT = 2;
  int WORKGROUP = 3;
  int COMPONENT = 4;
  int SYSTEM = 5;
}

def BrigOpcode : Operand<i32> {
  let PrintMethod = "printBrigOpcode";
  int NOP = 0;
  int ABS = 1;
  int ADD = 2;
  int BORROW = 3;
  int CARRY = 4;
  int CEIL = 5;
  int COPYSIGN = 6;
  int DIV = 7;
  int FLOOR = 8;
  int FMA = 9;
  int FRACT = 10;
  int MAD = 11;
  int MAX = 12;
  int MIN = 13;
  int MUL = 14;
  int MULHI = 15;
  int NEG = 16;
  int REM = 17;
  int RINT = 18;
  int SQRT = 19;
  int SUB = 20;
  int TRUNC = 21;
  int MAD24 = 22;
  int MAD24HI = 23;
  int MUL24 = 24;
  int MUL24HI = 25;
  int SHL = 26;
  int SHR = 27;
  int AND = 28;
  int NOT = 29;
  int OR = 30;
  int POPCOUNT = 31;
  int XOR = 32;
  int BITEXTRACT = 33;
  int BITINSERT = 34;
  int BITMASK = 35;
  int BITREV = 36;
  int BITSELECT = 37;
  int FIRSTBIT = 38;
  int LASTBIT = 39;
  int COMBINE = 40;
  int EXPAND = 41;
  int LDA = 42;
  int MOV = 43;
  int SHUFFLE = 44;
  int UNPACKHI = 45;
  int UNPACKLO = 46;
  int PACK = 47;
  int UNPACK = 48;
  int CMOV = 49;
  int CLASS = 50;
  int NCOS = 51;
  int NEXP2 = 52;
  int NFMA = 53;
  int NLOG2 = 54;
  int NRCP = 55;
  int NRSQRT = 56;
  int NSIN = 57;
  int NSQRT = 58;
  int BITALIGN = 59;
  int BYTEALIGN = 60;
  int PACKCVT = 61;
  int UNPACKCVT = 62;
  int LERP = 63;
  int SAD = 64;
  int SADHI = 65;
  int SEGMENTP = 66;
  int FTOS = 67;
  int STOF = 68;
  int CMP = 69;
  int CVT = 70;
  int LD = 71;
  int ST = 72;
  int ATOMIC = 73;
  int ATOMICNORET = 74;
  int SIGNAL = 75;
  int SIGNALNORET = 76;
  int MEMFENCE = 77;
  int RDIMAGE = 78;
  int LDIMAGE = 79;
  int STIMAGE = 80;
  int QUERYIMAGE = 81;
  int QUERYSAMPLER = 82;
  int CBR = 83;
  int BR = 84;
  int SBR = 85;
  int BARRIER = 86;
  int WAVEBARRIER = 87;
  int ARRIVEFBAR = 88;
  int INITFBAR = 89;
  int JOINFBAR = 90;
  int LEAVEFBAR = 91;
  int RELEASEFBAR = 92;
  int WAITFBAR = 93;
  int LDF = 94;
  int ACTIVELANECOUNT = 95;
  int ACTIVELANEID = 96;
  int ACTIVELANEMASK = 97;
  int ACTIVELANESHUFFLE = 98;
  int CALL = 99;
  int SCALL = 100;
  int ICALL = 101;
  int LDI = 102;
  int RET = 103;
  int ALLOCA = 104;
  int CURRENTWORKGROUPSIZE = 105;
  int DIM = 106;
  int GRIDGROUPS = 107;
  int GRIDSIZE = 108;
  int PACKETCOMPLETIONSIG = 109;
  int PACKETID = 110;
  int WORKGROUPID = 111;
  int WORKGROUPSIZE = 112;
  int WORKITEMABSID = 113;
  int WORKITEMFLATABSID = 114;
  int WORKITEMFLATID = 115;
  int WORKITEMID = 116;
  int CLEARDETECTEXCEPT = 117;
  int GETDETECTEXCEPT = 118;
  int SETDETECTEXCEPT = 119;
  int ADDQUEUEWRITEINDEX = 120;
  int AGENTCOUNT = 121;
  int AGENTID = 122;
  int CASQUEUEWRITEINDEX = 123;
  int LDK = 124;
  int LDQUEUEREADINDEX = 125;
  int LDQUEUEWRITEINDEX = 126;
  int QUEUEID = 127;
  int QUEUEPTR = 128;
  int STQUEUEREADINDEX = 129;
  int STQUEUEWRITEINDEX = 130;
  int CLOCK = 131;
  int CUID = 132;
  int DEBUGTRAP = 133;
  int GROUPBASEPTR = 134;
  int KERNARGBASEPTR = 135;
  int LANEID = 136;
  int MAXCUID = 137;
  int MAXWAVEID = 138;
  int NULLPTR = 139;
  int WAVEID = 140;
  int GCNMADU = 32768;
  int GCNMADS = 32769;
  int GCNMAX3 = 32770;
  int GCNMIN3 = 32771;
  int GCNMED3 = 32772;
  int GCNFLDEXP = 32773;
  int GCNFREXP_EXP = 32774;
  int GCNFREXP_MANT = 32775;
  int GCNTRIG_PREOP = 32776;
  int GCNBFM = 32777;
  int GCNLD = 32778;
  int GCNST = 32779;
  int GCNATOMIC = 32780;
  int GCNATOMICNORET = 32781;
  int GCNSLEEP = 32782;
  int GCNPRIORITY = 32783;
  int GCNREGIONALLOC = 32784;
  int GCNMSAD = 32785;
  int GCNQSAD = 32786;
  int GCNMQSAD = 32787;
  int GCNMQSAD4 = 32788;
  int GCNSADW = 32789;
  int GCNSADD = 32790;
  int GCNCONSUME = 32791;
  int GCNAPPEND = 32792;
  int GCNB4XCHG = 32793;
  int GCNB32XCHG = 32794;
  int GCNMAX = 32795;
  int GCNMIN = 32796;
  int GCNDIVRELAXED = 32797;
  int GCNDIVRELAXEDNARROW = 32798;
}

def BrigPack : Operand<i32> {
  let PrintMethod = "printBrigPack";
  int NONE = 0;
  int PP = 1;
  int PS = 2;
  int SP = 3;
  int SS = 4;
  int S = 5;
  int P = 6;
  int PPSAT = 7;
  int PSSAT = 8;
  int SPSAT = 9;
  int SSSAT = 10;
  int SSAT = 11;
  int PSAT = 12;
}

def BrigPackedTypeBits : Operand<i32> {
  let PrintMethod = "printBrigPackedTypeBits";
  int PACK_SHIFT = 5;
  int BASE_MASK = 31;
  int PACK_MASK = 96;
  int PACK_NONE = 0;
  int PACK_32 = 32;
  int PACK_64 = 64;
  int PACK_128 = 96;
}

def BrigProfile : Operand<i32> {
  let PrintMethod = "printBrigProfile";
  int BASE = 0;
  int FULL = 1;
  int UNDEF = 2;
}

def BrigRegisterKind : Operand<i32> {
  let PrintMethod = "printBrigRegisterKind";
  int CONTROL = 0;
  int SINGLE = 1;
  int DOUBLE = 2;
  int QUAD = 3;
}

def BrigRound : Operand<i32> {
  let PrintMethod = "printBrigRound";
  int NONE = 0;
  int FLOAT_NEAR_EVEN = 1;
  int FLOAT_ZERO = 2;
  int FLOAT_PLUS_INFINITY = 3;
  int FLOAT_MINUS_INFINITY = 4;
  int INTEGER_NEAR_EVEN = 5;
  int INTEGER_ZERO = 6;
  int INTEGER_PLUS_INFINITY = 7;
  int INTEGER_MINUS_INFINITY = 8;
  int INTEGER_NEAR_EVEN_SAT = 9;
  int INTEGER_ZERO_SAT = 10;
  int INTEGER_PLUS_INFINITY_SAT = 11;
  int INTEGER_MINUS_INFINITY_SAT = 12;
  int INTEGER_SIGNALLING_NEAR_EVEN = 13;
  int INTEGER_SIGNALLING_ZERO = 14;
  int INTEGER_SIGNALLING_PLUS_INFINITY = 15;
  int INTEGER_SIGNALLING_MINUS_INFINITY = 16;
  int INTEGER_SIGNALLING_NEAR_EVEN_SAT = 17;
  int INTEGER_SIGNALLING_ZERO_SAT = 18;
  int INTEGER_SIGNALLING_PLUS_INFINITY_SAT = 19;
  int INTEGER_SIGNALLING_MINUS_INFINITY_SAT = 20;
}

def BrigSamplerAddressing : Operand<i32> {
  let PrintMethod = "printBrigSamplerAddressing";
  int UNDEFINED = 0;
  int CLAMP_TO_EDGE = 1;
  int CLAMP_TO_BORDER = 2;
  int REPEAT = 3;
  int MIRRORED_REPEAT = 4;
}

def BrigSamplerCoordNormalization : Operand<i32> {
  let PrintMethod = "printBrigSamplerCoordNormalization";
  int UNNORMALIZED = 0;
  int NORMALIZED = 1;
}

def BrigSamplerFilter : Operand<i32> {
  let PrintMethod = "printBrigSamplerFilter";
  int NEAREST = 0;
  int LINEAR = 1;
}

def BrigSamplerQuery : Operand<i32> {
  let PrintMethod = "printBrigSamplerQuery";
  int ADDRESSING = 0;
  int COORD = 1;
  int FILTER = 2;
}

def BrigSectionIndex : Operand<i32> {
  let PrintMethod = "printBrigSectionIndex";
  int DATA = 0;
  int CODE = 1;
  int OPERAND = 2;
  int BEGIN_IMPLEMENTATION_DEFINED = 3;
  int IMPLEMENTATION_DEFINED = 3;
}

def BrigSegCvtModifierMask : Operand<i32> {
  let PrintMethod = "printBrigSegCvtModifierMask";
  int NONULL = 1;
}

def BrigSegment : Operand<i32> {
  let PrintMethod = "printBrigSegment";
  int NONE = 0;
  int FLAT = 1;
  int GLOBAL = 2;
  int READONLY = 3;
  int KERNARG = 4;
  int GROUP = 5;
  int PRIVATE = 6;
  int SPILL = 7;
  int ARG = 8;
  int EXTSPACE0 = 9;
}

def AddressSpace : Operand<i32> {
  int PRIVATE = 0;
  int GLOBAL = 1;
  int READONLY = 2;
  int GROUP = 3;
  int FLAT = 4;
  int REGION = 5;
  int SPILL = 6;
  int KERNARG = 7;
  int ARG = 8;
}

def BrigTypeX : Operand<i32> {
  let PrintMethod = "printBrigTypeX";
  int NONE = 0;
  int U8 = 1;
  int U16 = 2;
  int U32 = 3;
  int U64 = 4;
  int S8 = 5;
  int S16 = 6;
  int S32 = 7;
  int S64 = 8;
  int F16 = 9;
  int F32 = 10;
  int F64 = 11;
  int B1 = 12;
  int B8 = 13;
  int B16 = 14;
  int B32 = 15;
  int B64 = 16;
  int B128 = 17;
  int SAMP = 18;
  int ROIMG = 19;
  int WOIMG = 20;
  int RWIMG = 21;
  int SIG32 = 22;
  int SIG64 = 23;
  int U8X4 = 33;
  int U8X8 = 65;
  int U8X16 = 97;
  int U16X2 = 34;
  int U16X4 = 66;
  int U16X8 = 98;
  int U32X2 = 67;
  int U32X4 = 99;
  int U64X2 = 100;
  int S8X4 = 37;
  int S8X8 = 69;
  int S8X16 = 101;
  int S16X2 = 38;
  int S16X4 = 70;
  int S16X8 = 102;
  int S32X2 = 71;
  int S32X4 = 103;
  int S64X2 = 104;
  int F16X2 = 41;
  int F16X4 = 73;
  int F16X8 = 105;
  int F32X2 = 74;
  int F32X4 = 106;
  int F64X2 = 107;
  int INVALID = -1;
}

def BrigVariableModifierMask : Operand<i32> {
  let PrintMethod = "printBrigVariableModifierMask";
  int DEFINITION = 1;
  int CONST = 2;
  int ARRAY = 4;
  int FLEX_ARRAY = 8;
}

def BrigVersion : Operand<i32> {
  let PrintMethod = "printBrigVersion";
  int HSAIL_MAJOR = 0;
  int HSAIL_MINOR = 20140528;
  int BRIG_MAJOR = 0;
  int BRIG_MINOR = 20140528;
}

def BrigWidth : Operand<i32> {
  let PrintMethod = "printBrigWidth";
  int _NONE = 0;
  int _1 = 1;
  int _2 = 2;
  int _4 = 3;
  int _8 = 4;
  int _16 = 5;
  int _32 = 6;
  int _64 = 7;
  int _128 = 8;
  int _256 = 9;
  int _512 = 10;
  int _1024 = 11;
  int _2048 = 12;
  int _4096 = 13;
  int _8192 = 14;
  int _16384 = 15;
  int _32768 = 16;
  int _65536 = 17;
  int _131072 = 18;
  int _262144 = 19;
  int _524288 = 20;
  int _1048576 = 21;
  int _2097152 = 22;
  int _4194304 = 23;
  int _8388608 = 24;
  int _16777216 = 25;
  int _33554432 = 26;
  int _67108864 = 27;
  int _134217728 = 28;
  int _268435456 = 29;
  int _536870912 = 30;
  int _1073741824 = 31;
  int _2147483648 = 32;
  int _WAVESIZE = 33;
  int _ALL = 34;
}

