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

def HSAILumad : SDNode<"HSAILISD::UMAD", HSAILDTIntTernaryOp>;
def HSAILsmad : SDNode<"HSAILISD::SMAD", HSAILDTIntTernaryOp>;
