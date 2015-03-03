//===---------------- HSAILILProfiles.td - HSAIL Profiles -----------------===//
//  These are used for custom selection dag type profiles
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Call Sequence Profiles
//===----------------------------------------------------------------------===//
def SDTIL_CallSeqStart : SDCallSeqStart<[
    SDTCisVT<0, i32>
    ]>;
def SDTIL_CallSeqEnd : SDCallSeqEnd<[
    SDTCisVT<0, i32>, SDTCisVT<1, i32>
    ]>;

