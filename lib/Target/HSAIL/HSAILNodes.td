//===--------------------- HSAILILNodes.td - HSAIL nodes ------------------===//

def HSAILDTIntTernaryOp : SDTypeProfile<1, 3, [
  SDTCisSameAs<0, 1>, SDTCisSameAs<0, 2>, SDTCisInt<0>, SDTCisInt<3>
]>;


//===----------------------------------------------------------------------===//
// Call/Return DAG Nodes
//===----------------------------------------------------------------------===//
def IL_callseq_start : SDNode<"ISD::CALLSEQ_START", SDTIL_CallSeqStart,
                       [SDNPHasChain, SDNPOutGlue]>;

def IL_callseq_end : SDNode<"ISD::CALLSEQ_END",   SDTIL_CallSeqEnd,
                     [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;

def IL_call : SDNode<"HSAILISD::CALL", SDTIL_Call,
              [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue, SDNPVariadic]>;

def IL_retflag : SDNode<"HSAILISD::RET_FLAG", SDTNone,
                 [SDNPHasChain, SDNPOptInGlue]>;

def IL_lda_flat   : SDNode<"HSAILISD::LDA_FLAT", SDTypeProfile<1, 1, []>, []>;
def IL_lda_global : SDNode<"HSAILISD::LDA_GLOBAL", SDTypeProfile<1, 1, []>, []>;
def IL_lda_group  : SDNode<"HSAILISD::LDA_GROUP", SDTypeProfile<1, 1, []>, []>;
def IL_lda_private : SDNode<"HSAILISD::LDA_PRIVATE", SDTypeProfile<1, 1, []>, []>;
def IL_lda_readonly : SDNode<"HSAILISD::LDA_READONLY", SDTypeProfile<1, 1, []>, []>;

// out = a - floor(a)
def HSAILfract : SDNode<"HSAILISD::FRACT", SDTFPUnaryOp>;

def HSAILnfma : SDNode<"HSAILISD::NFMA", SDTFPTernaryOp>;
def HSAILumad : SDNode<"HSAILISD::UMAD", HSAILDTIntTernaryOp>;
def HSAILsmad : SDNode<"HSAILISD::SMAD", HSAILDTIntTernaryOp>;
def HSAILbitselect : SDNode<"HSAILISD::BITSELECT", HSAILDTIntTernaryOp>;

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
