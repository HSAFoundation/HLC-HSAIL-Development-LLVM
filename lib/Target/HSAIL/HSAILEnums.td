//===------------------------------------------------------*- tablegen -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

let OperandType = "OPERAND_IMMEDIATE" in {

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
  int FTZ = 1;
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
  int REQUIREDDIM = 6;
  int REQUIREDGRIDSIZE = 7;
  int REQUIREDWORKGROUPSIZE = 8;
  int REQUIRENOPARTIALWORKGROUPS = 9;
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
  int FIRST_USER_DEFINED = 128;
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
  int FIRST_USER_DEFINED = 128;
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
  int _FIRST_USER_DEFINED = 128;
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
  int AGENT = 4;
  int SYSTEM = 5;
  int LAST = 6;
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
  int IMAGEFENCE = 81;
  int QUERYIMAGE = 82;
  int QUERYSAMPLER = 83;
  int CBR = 84;
  int BR = 85;
  int SBR = 86;
  int BARRIER = 87;
  int WAVEBARRIER = 88;
  int ARRIVEFBAR = 89;
  int INITFBAR = 90;
  int JOINFBAR = 91;
  int LEAVEFBAR = 92;
  int RELEASEFBAR = 93;
  int WAITFBAR = 94;
  int LDF = 95;
  int ACTIVELANECOUNT = 96;
  int ACTIVELANEID = 97;
  int ACTIVELANEMASK = 98;
  int ACTIVELANEPERMUTE = 99;
  int CALL = 100;
  int SCALL = 101;
  int ICALL = 102;
  int RET = 103;
  int ALLOCA = 104;
  int CURRENTWORKGROUPSIZE = 105;
  int CURRENTWORKITEMFLATID = 106;
  int DIM = 107;
  int GRIDGROUPS = 108;
  int GRIDSIZE = 109;
  int PACKETCOMPLETIONSIG = 110;
  int PACKETID = 111;
  int WORKGROUPID = 112;
  int WORKGROUPSIZE = 113;
  int WORKITEMABSID = 114;
  int WORKITEMFLATABSID = 115;
  int WORKITEMFLATID = 116;
  int WORKITEMID = 117;
  int CLEARDETECTEXCEPT = 118;
  int GETDETECTEXCEPT = 119;
  int SETDETECTEXCEPT = 120;
  int ADDQUEUEWRITEINDEX = 121;
  int CASQUEUEWRITEINDEX = 122;
  int LDQUEUEREADINDEX = 123;
  int LDQUEUEWRITEINDEX = 124;
  int STQUEUEREADINDEX = 125;
  int STQUEUEWRITEINDEX = 126;
  int CLOCK = 127;
  int CUID = 128;
  int DEBUGTRAP = 129;
  int GROUPBASEPTR = 130;
  int KERNARGBASEPTR = 131;
  int LANEID = 132;
  int MAXCUID = 133;
  int MAXWAVEID = 134;
  int NULLPTR = 135;
  int WAVEID = 136;
  int FIRST_USER_DEFINED = 32768;
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

def BrigProfile : Operand<i32> {
  let PrintMethod = "printBrigProfile";
  int BASE = 0;
  int FULL = 1;
  int UNDEF = 2;
}

def BrigRound : Operand<i32> {
  let PrintMethod = "printBrigRound";
  int NONE = 0;
  int FLOAT_DEFAULT = 1;
  int FLOAT_NEAR_EVEN = 2;
  int FLOAT_ZERO = 3;
  int FLOAT_PLUS_INFINITY = 4;
  int FLOAT_MINUS_INFINITY = 5;
  int INTEGER_NEAR_EVEN = 6;
  int INTEGER_ZERO = 7;
  int INTEGER_PLUS_INFINITY = 8;
  int INTEGER_MINUS_INFINITY = 9;
  int INTEGER_NEAR_EVEN_SAT = 10;
  int INTEGER_ZERO_SAT = 11;
  int INTEGER_PLUS_INFINITY_SAT = 12;
  int INTEGER_MINUS_INFINITY_SAT = 13;
  int INTEGER_SIGNALING_NEAR_EVEN = 14;
  int INTEGER_SIGNALING_ZERO = 15;
  int INTEGER_SIGNALING_PLUS_INFINITY = 16;
  int INTEGER_SIGNALING_MINUS_INFINITY = 17;
  int INTEGER_SIGNALING_NEAR_EVEN_SAT = 18;
  int INTEGER_SIGNALING_ZERO_SAT = 19;
  int INTEGER_SIGNALING_PLUS_INFINITY_SAT = 20;
  int INTEGER_SIGNALING_MINUS_INFINITY_SAT = 21;
}

def BrigSamplerAddressing : Operand<i32> {
  let PrintMethod = "printBrigSamplerAddressing";
  int UNDEFINED = 0;
  int CLAMP_TO_EDGE = 1;
  int CLAMP_TO_BORDER = 2;
  int REPEAT = 3;
  int MIRRORED_REPEAT = 4;
  int FIRST_USER_DEFINED = 128;
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
  int FIRST_USER_DEFINED = 128;
}

def BrigSamplerQuery : Operand<i32> {
  let PrintMethod = "printBrigSamplerQuery";
  int ADDRESSING = 0;
  int COORD = 1;
  int FILTER = 2;
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
  int FIRST_USER_DEFINED = 128;
  int AMD_GCN = 9;
}

def AddressSpace : Operand<i32> {
  let PrintMethod = "printBrigSegment";
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

def BrigType : Operand<i32> {
  let PrintMethod = "printBrigType";
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
  int U8_ARRAY = 129;
  int U16_ARRAY = 130;
  int U32_ARRAY = 131;
  int U64_ARRAY = 132;
  int S8_ARRAY = 133;
  int S16_ARRAY = 134;
  int S32_ARRAY = 135;
  int S64_ARRAY = 136;
  int F16_ARRAY = 137;
  int F32_ARRAY = 138;
  int F64_ARRAY = 139;
  int B8_ARRAY = 141;
  int B16_ARRAY = 142;
  int B32_ARRAY = 143;
  int B64_ARRAY = 144;
  int B128_ARRAY = 145;
  int SAMP_ARRAY = 146;
  int ROIMG_ARRAY = 147;
  int WOIMG_ARRAY = 148;
  int RWIMG_ARRAY = 149;
  int SIG32_ARRAY = 150;
  int SIG64_ARRAY = 151;
  int U8X4_ARRAY = 161;
  int U8X8_ARRAY = 193;
  int U8X16_ARRAY = 225;
  int U16X2_ARRAY = 162;
  int U16X4_ARRAY = 194;
  int U16X8_ARRAY = 226;
  int U32X2_ARRAY = 195;
  int U32X4_ARRAY = 227;
  int U64X2_ARRAY = 228;
  int S8X4_ARRAY = 165;
  int S8X8_ARRAY = 197;
  int S8X16_ARRAY = 229;
  int S16X2_ARRAY = 166;
  int S16X4_ARRAY = 198;
  int S16X8_ARRAY = 230;
  int S32X2_ARRAY = 199;
  int S32X4_ARRAY = 231;
  int S64X2_ARRAY = 232;
  int F16X2_ARRAY = 169;
  int F16X4_ARRAY = 201;
  int F16X8_ARRAY = 233;
  int F32X2_ARRAY = 202;
  int F32X4_ARRAY = 234;
  int F64X2_ARRAY = 235;
  int INVALID = -1;
}

def BrigVariableModifierMask : Operand<i32> {
  let PrintMethod = "printBrigVariableModifierMask";
  int DEFINITION = 1;
  int CONST = 2;
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
  int _LAST = 35;
}

}
