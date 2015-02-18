//===----------------- HSAILInstrPatterns.td - HSAIL Target ---------------===//
//
// This file holds all the custom patterns that are used by the hsail backend
//
//===----------------------------------------------------------------------===//

def : Pat<(IL_call tglobaladdr:$dest), (TARGET_CALL tglobaladdr:$dest)>;
def : Pat<(IL_call texternalsym:$dest), (TARGET_CALL texternalsym:$dest)>;
def : Pat<(IL_call tconstpool:$dest), (TARGET_CALL tconstpool:$dest)>;
