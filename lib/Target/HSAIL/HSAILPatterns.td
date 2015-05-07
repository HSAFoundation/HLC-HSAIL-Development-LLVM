//===------------------------------------------------------*- tablegen -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Store pattern fragments.
//
//===----------------------------------------------------------------------===//


def ADDR : ComplexPattern<iPTR, 3, "SelectAddr", [], []>;

// FIXME: This should really be a complex pattern on the root load,
// but there seem to be problems trying to use a ComplexPattern with a
// chain in a Pat.
def LoadAddr : ComplexPattern<iPTR, 8, "SelectLoadAddr", [], [SDNPWantParent]>;
def StoreAddr : ComplexPattern<iPTR, 6, "SelectStoreAddr", [], [SDNPWantParent]>;
def AtomicAddr : ComplexPattern<iPTR, 7, "SelectAtomicAddr", [], [SDNPWantParent]>;

def SetCCPat : ComplexPattern<i1, 6, "SelectSetCC", [setcc], []>;
