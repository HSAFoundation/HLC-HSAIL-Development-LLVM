#ifndef HSAILISDNODES_H
#define HSAILISDNODES_H

namespace llvm {
  namespace HSAILISD {
    // HSAIL Specific DAG Nodes
    enum NodeType {
      // Start the numbering where the builtin ops leave off.
      FIRST_NUMBER = ISD::BUILTIN_OP_END,
      CALL,        // Function call based on a single integer
      /// Return with a flag operand. Operand 0 is the chain operand, operand
      /// 1 is the number of bytes of stack to pop.
      RET_FLAG,
      LDA_FLAT,
      LDA_GLOBAL,
      LDA_GROUP,
      LDA_PRIVATE,
      LDA_READONLY,
      TRUNC_B1,
      INTRINSIC
    };
  }
}
#endif
