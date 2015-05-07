//===------------------------------------------------------*- tablegen -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

def HSAILDTIntTernaryOp : SDTypeProfile<1, 3, [
  SDTCisSameAs<0, 1>, SDTCisSameAs<0, 2>, SDTCisInt<0>, SDTCisInt<3>
]>;

def HSAILDTBitExtractOp : SDTypeProfile<1, 3, [
  SDTCisSameAs<0, 1>, SDTCisInt<0>, SDTCisSameAs<2, 3>, SDTCisInt<2>
]>;

def HSAILLdExpOp : SDTypeProfile<1, 2,
  [SDTCisSameAs<0, 1>, SDTCisFP<0>, SDTCisInt<2>]
>;

def HSAILActiveLanePermuteOp : SDTypeProfile<1, 5,
  [SDTCisInt<0>, SDTCisInt<1>,
   SDTCisSameAs<0, 2>, SDTCisInt<3>, SDTCisSameAs<0, 4>, SDTCisInt<5>]
>;

def HSAILActiveLaneIdOp : SDTypeProfile<1, 1,
  [SDTCisInt<0>, SDTCisInt<1>]
>;

def HSAILActiveLaneCountOp : SDTypeProfile<1, 2,
  [SDTCisInt<0>, SDTCisInt<1>, SDTCisInt<2>]
>;

def HSAILActiveLaneMaskOp : SDTypeProfile<4, 2,
  [SDTCisInt<0>, SDTCisSameAs<0, 1>, SDTCisSameAs<0, 2>, SDTCisSameAs<0, 3>,
   SDTCisInt<4>, SDTCisInt<5>]
>;

def HSAILFPClassOp : SDTypeProfile<1, 2,
  [SDTCisInt<0>, SDTCisFP<1>, SDTCisInt<2>]
>;

def HSAILLdaOp : SDTypeProfile<1, 2,
  [SDTCisInt<0>, SDTCisInt<1>, SDTCisSameAs<0, 2>]
>;

// i1 = segment, i1:nonull, ptr
def HSAILSegmentPOp : SDTypeProfile<1, 3,
  [SDTCisInt<0>, SDTCisInt<1>, SDTCisSameAs<0, 2>, SDTCisInt<3>]
>;

def HSAILArgLdOp : SDTypeProfile<1, 4,
  [SDTCisInt<1>, SDTCisInt<2>, SDTCisSameAs<2, 3>]
>;

def HSAILArgStOp : SDTypeProfile<0, 4,
  [SDTCisInt<1>, SDTCisInt<2>, SDTCisInt<3>]
>;

//===----------------------------------------------------------------------===//
// Call/Return DAG Nodes
//===----------------------------------------------------------------------===//
def IL_callseq_start : SDNode<"ISD::CALLSEQ_START", SDTIL_CallSeqStart,
                       [SDNPHasChain, SDNPOutGlue, SDNPSideEffect]>;

def IL_callseq_end : SDNode<"ISD::CALLSEQ_END",   SDTIL_CallSeqEnd,
                     [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue, SDNPSideEffect]>;

def HSAILret : SDNode<"HSAILISD::RET", SDTNone,
  [SDNPHasChain, SDNPOptInGlue]
>;

def HSAILArgLd : SDNode<"HSAILISD::ARG_LD", HSAILArgLdOp,
  [SDNPHasChain, SDNPMayLoad, SDNPOutGlue, SDNPInGlue]
>;

def HSAILArgSt : SDNode<"HSAILISD::ARG_ST", HSAILArgStOp,
  [SDNPHasChain, SDNPMayStore, SDNPOutGlue, SDNPInGlue]
>;

def HSAILlda : SDNode<"HSAILISD::LDA", HSAILLdaOp>;

// out = a - floor(a)
def HSAILfract : SDNode<"HSAILISD::FRACT", SDTFPUnaryOp>;

def HSAILnfma : SDNode<"HSAILISD::NFMA", SDTFPTernaryOp>;
def HSAILumad : SDNode<"HSAILISD::UMAD", HSAILDTIntTernaryOp>;
def HSAILsmad : SDNode<"HSAILISD::SMAD", HSAILDTIntTernaryOp>;
def HSAILbitselect : SDNode<"HSAILISD::BITSELECT", HSAILDTIntTernaryOp>;
def HSAILsbitextract : SDNode<"HSAILISD::SBITEXTRACT", HSAILDTBitExtractOp>;
def HSAILubitextract : SDNode<"HSAILISD::UBITEXTRACT", HSAILDTBitExtractOp>;

// out = max(a, b) a and b are signed ints
def HSAILsmax : SDNode<"HSAILISD::SMAX", SDTIntBinOp,
  [SDNPCommutative, SDNPAssociative]
>;

// out = max(a, b) a and b are unsigned ints
def HSAILumax : SDNode<"HSAILISD::UMAX", SDTIntBinOp,
  [SDNPCommutative, SDNPAssociative]
>;

// out = min(a, b) a and b are signed ints
def HSAILsmin : SDNode<"HSAILISD::SMIN", SDTIntBinOp,
  [SDNPCommutative, SDNPAssociative]
>;

// out = min(a, b) a and b are unsigned ints
def HSAILumin : SDNode<"HSAILISD::UMIN", SDTIntBinOp,
  [SDNPCommutative, SDNPAssociative]
>;

// Signed and unsigned 24-bit mulitply.  The highest 8-bits are ignore when
// performing the mulitply.  The result is a 32-bit value.
def HSAILumul24 : SDNode<"HSAILISD::UMUL24", SDTIntBinOp,
  [SDNPCommutative]
>;
def HSAILsmul24 : SDNode<"HSAILISD::SMUL24", SDTIntBinOp,
  [SDNPCommutative]
>;

def HSAILumad24 : SDNode<"HSAILISD::UMAD24", HSAILDTIntTernaryOp,
  []
>;
def HSAILsmad24 : SDNode<"HSAILISD::SMAD24", HSAILDTIntTernaryOp,
  []
>;

def HSAILfldexp : SDNode<"HSAILISD::FLDEXP", HSAILLdExpOp>;

def HSAILactivelanepermute : SDNode<"HSAILISD::ACTIVELANEPERMUTE",
  HSAILActiveLanePermuteOp, [SDNPHasChain, SDNPSideEffect]
>;

def HSAILactivelaneid : SDNode<"HSAILISD::ACTIVELANEID",
  HSAILActiveLaneIdOp, [SDNPHasChain, SDNPSideEffect]
>;

def HSAILactivelanecount : SDNode<"HSAILISD::ACTIVELANECOUNT",
  HSAILActiveLaneCountOp, [SDNPHasChain, SDNPSideEffect]
>;

def HSAILactivelanemask : SDNode<"HSAILISD::ACTIVELANEMASK",
  HSAILActiveLaneMaskOp, [SDNPHasChain, SDNPSideEffect]
>;

def HSAILclass : SDNode<"HSAILISD::CLASS", HSAILFPClassOp>;

def HSAILkernargbaseptr : SDNode<"HSAILISD::KERNARGBASEPTR", SDTIntLeaf>;

def HSAILsegmentp : SDNode<"HSAILISD::SEGMENTP", HSAILSegmentPOp>;
