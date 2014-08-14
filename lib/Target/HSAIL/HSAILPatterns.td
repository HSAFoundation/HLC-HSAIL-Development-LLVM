//===---------- HSAILPatterns.td - HSAIL Target Patterns ---*-tablegen-*---===//
//
// Store pattern fragments
//
//===----------------------------------------------------------------------===//


def ADDR : ComplexPattern<iPTR, 3, "SelectAddr", [], []>;
