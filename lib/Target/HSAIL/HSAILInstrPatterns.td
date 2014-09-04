//===----------------- HSAILInstrPatterns.td - HSAIL Target ---------------===//
//
// This file holds all the custom patterns that are used by the hsail backend
//
//===----------------------------------------------------------------------===//

def : Pat<(IL_call tglobaladdr:$dst), (target_call tglobaladdr:$dst)>;
def : Pat<(IL_call texternalsym:$dst), (target_call texternalsym:$dst)>;
def : Pat<(IL_call tconstpool:$dst), (target_call tconstpool:$dst)>;
