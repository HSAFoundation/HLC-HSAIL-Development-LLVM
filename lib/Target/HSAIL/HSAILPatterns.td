//===---------- HSAILPatterns.td - HSAIL Target Patterns ---*-tablegen-*---===//
//
// Store pattern fragments
//
//===----------------------------------------------------------------------===//


def ADDR : ComplexPattern<iPTR, 3, "SelectAddr", [], []>;

// FIXME: This should really be a complex pattern on the root load,
// but there seem to be problems trying to use a ComplexPattern with a
// chain in a Pat.
def LoadAddr : ComplexPattern<iPTR, 8, "SelectLoadAddr", [], [SDNPWantParent]>;
def StoreAddr : ComplexPattern<iPTR, 6, "SelectStoreAddr", [], [SDNPWantParent]>;
def AtomicAddr : ComplexPattern<iPTR, 8, "SelectAtomicAddr", [], [SDNPWantParent]>;


def STOFComplexPat : ComplexPattern<iPTR, 5, "SelectSTOF", [addrspacecast], []>;
def FTOSComplexPat : ComplexPattern<iPTR, 5, "SelectFTOS", [addrspacecast], []>;

def SetCCPat : ComplexPattern<i1, 6, "SelectSetCC", [setcc], []>;
