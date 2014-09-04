//===--------------------- HSAILILNodes.td - HSAIL nodes ------------------===//

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

def IL_trunc_b1 : SDNode<"HSAILISD::TRUNC_B1", SDTypeProfile<1, 1, []>, []>;
