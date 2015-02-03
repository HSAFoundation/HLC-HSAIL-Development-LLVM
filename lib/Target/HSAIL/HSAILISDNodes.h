#ifndef HSAILISDNODES_H
#define HSAILISDNODES_H

namespace llvm {
  namespace HSAILISD {
    // HSAIL Specific DAG Nodes
    enum NodeType {
      // Start the numbering where the builtin ops leave off.
      FIRST_NUMBER = ISD::BUILTIN_OP_END,
      CALL,        // Function call based on a single integer
      RET,
      SMAX,
      UMAX,
      SMIN,
      UMIN,
      FRACT,
      NFMA,
      UMAD,
      SMAD,
      UMUL24,
      SMUL24,
      UMAD24,
      SMAD24,
      BITSELECT,
      SBITEXTRACT,
      UBITEXTRACT,
      FLDEXP,
      CLASS,
      LDA,
      ACTIVELANESHUFFLE,
      ACTIVELANEID,
      ACTIVELANECOUNT,
      KERNARGBASEPTR
    };
  }
}
#endif
