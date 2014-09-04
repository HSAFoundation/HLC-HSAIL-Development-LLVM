//===---------------- HSAILILProfiles.td - HSAIL Profiles -----------------===//
//  These are used for custom selection dag type profiles
//===----------------------------------------------------------------------===//


//===----------------------------------------------------------------------===//
// Flow Control Profile Types
//===----------------------------------------------------------------------===//
// Profile for Normal Call
def SDTIL_Call : SDTypeProfile<0, 1, [
    SDTCisVT<0, i32>
    ]>;

//===----------------------------------------------------------------------===//
// Call Sequence Profiles
//===----------------------------------------------------------------------===//
def SDTIL_CallSeqStart : SDCallSeqStart<[
    SDTCisVT<0, i32>
    ]>;
def SDTIL_CallSeqEnd : SDCallSeqEnd<[
    SDTCisVT<0, i32>, SDTCisVT<1, i32>
    ]>;

