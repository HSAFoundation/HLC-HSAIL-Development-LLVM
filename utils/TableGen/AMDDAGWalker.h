#ifndef DAG_WALKER_H
#define DAG_WALKER_H

#include "../../include/llvm/TableGen/Record.h"
#include "../../include/llvm/CodeGen/ISDOpcodes.h"
#include "../lib/Target/HSAIL/HSAILISDNodes.h"
#include "CodeGenInstruction.h"
#include <sstream>
#ifdef ANDROID
#include <stdio.h>
#endif

using namespace llvm;
using namespace llvm::ISD;
using namespace llvm::HSAILISD;

class DAGWalker {

public:
  DAGWalker(std::ostringstream & O, int vec_size = 1):
      printer(O),
      m_state(PS_START),
      m_opNum(0),
      m_vec_size(vec_size)
      {
        Node["ISD::BRCOND"] = BRCOND;
        Node["ISD::BR"] = BR;
        Node["ISD::BasicBlock"] = BasicBlock;
        Node["ISD::Constant"] = Constant;
        Node["ISD::ConstantFP"] = ConstantFP;
        Node["ISD::ExternalSymbol"] = ExternalSymbol;
        Node["ISD::GlobalAddress"] = GlobalAddress;
        Node["ISD::TargetExternalSymbol"] = TargetExternalSymbol;
        Node["ISD::TargetGlobalAddress"] = TargetGlobalAddress;
        Node["REGISTER"] = Register;
        Node["ValueType"] = VALUETYPE;

        Node["Intrinsic"] = INTRINSIC;

        Node["EOL"] = DELETED_NODE;
    };

  ~DAGWalker(){};

private:
  enum ParseState {
    PS_ERROR = -1,
    PS_START,
    PS_BR_EXPECT_COND,   // brcond ...
    PS_BR_EXPECT_BB,     // brcond cond ...  'expects address of BasicBlock to jump to'

    PS_END
  };
  //raw_ostream & printer;
  std::ostringstream & printer;
  ParseState m_state;

  unsigned m_opNum;

  void ProcessDef( DefInit * );
  void ProcessIntrinsic( DefInit * );

  void EmitVectorOrScalarOperand();

  std::map<std::string, unsigned> Node;

  int m_vec_size;

public:
  void WalkDAG( DagInit * , int& );
};

# endif // DAG_WALKER_H
