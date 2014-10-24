//===----------------- HSAILInstrPatterns.td - HSAIL Target ---------------===//
//
// This file holds all the custom patterns that are used by the hsail backend
//
//===----------------------------------------------------------------------===//

def : Pat<(IL_call tglobaladdr:$dest), (target_call tglobaladdr:$dest)>;
def : Pat<(IL_call texternalsym:$dest), (target_call texternalsym:$dest)>;
def : Pat<(IL_call tconstpool:$dest), (target_call tconstpool:$dest)>;
