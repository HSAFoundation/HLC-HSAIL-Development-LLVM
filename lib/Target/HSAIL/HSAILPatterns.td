//===---------- HSAILPatterns.td - HSAIL Target Patterns ---*-tablegen-*---===//
//
// Store pattern fragments
//
//===----------------------------------------------------------------------===//


def ADDR : ComplexPattern<iPTR, 3, "SelectAddr", [], []>;

// FIXME: This should really be a complex pattern on the root load,
// but there seem to be problems trying to use a ComplexPattern with a
// chain in a Pat.
def LoadAddr : ComplexPattern<iPTR, 7, "SelectLoadAddr", [], [SDNPWantParent]>;
