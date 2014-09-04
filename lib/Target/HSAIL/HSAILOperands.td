//===---------- HSAILOperands.td - HSAIL Operands -----*-tablegen-*--------===//


//===----------------------------------------------------------------------===//
// Custom memory operands
//===----------------------------------------------------------------------===//
def PtrRC: Operand<iPTR>, PointerLikeRegClass<0>;

def MEMOP  : Operand<iPTR> {
    let MIOperandInfo = (ops PtrRC, PtrRC, PtrRC);
}

def WIDTH_OPND  : OptionalDefOperand<i32, (ops i32), (ops (i32 1))> {
}

def ALIGN_OPND  : OptionalDefOperand<i8, (ops i8), (ops (i8 1))> {
}

def CONST_OPERAND  : OptionalDefOperand<i1, (ops i1), (ops (i1 0))> {
}

def IMAGEMEM32  : Operand<i32> {
}

def calltarget : Operand<i32>;

// Global Address node without offset
def tglobaladdr_base : PatLeaf<(i32 tglobaladdr), [{
    const GlobalAddressSDNode *GA = dyn_cast<GlobalAddressSDNode>(N);
    return GA && (GA->getOffset() == 0);
}]>;

def tglobaladdr_base64 : PatLeaf<(i64 tglobaladdr), [{
    const GlobalAddressSDNode *GA = dyn_cast<GlobalAddressSDNode>(N);
    return GA && (GA->getOffset() == 0);
}]>;

def tglobaladdr32 : PatLeaf<(i32 tglobaladdr), [{
    const GlobalAddressSDNode *GA = dyn_cast<GlobalAddressSDNode>(N);
    return GA ;
}]>;

def tglobaladdr64 : PatLeaf<(i64 tglobaladdr), [{
    const GlobalAddressSDNode *GA = dyn_cast<GlobalAddressSDNode>(N);
    return GA ;
}]>;

// Global Read&Write 32 bit address node
def tglobalrwaddr32 : PatLeaf<(i32 tglobaladdr), [{
    const GlobalAddressSDNode *GA = dyn_cast<GlobalAddressSDNode>(N);
    return GA && (GA->getAddressSpace() == Subtarget->getGlobalAS());
}]>;

// Global Read & Write 32 bit address node without offset
def tglobalrwaddr_base : PatLeaf<(i32 tglobaladdr), [{
    const GlobalAddressSDNode *GA = dyn_cast<GlobalAddressSDNode>(N);
    return GA && (GA->getOffset() == 0) 
              && (GA->getAddressSpace() == Subtarget->getGlobalAS());
}]>;

// Global Read&Write 64 bit address node
def tglobalrwaddr64 : PatLeaf<(i64 tglobaladdr), [{
    const GlobalAddressSDNode *GA = dyn_cast<GlobalAddressSDNode>(N);
    return GA && (GA->getAddressSpace() == Subtarget->getGlobalAS());
}]>;

// Global 64 bit address node without offset
def tglobalrwaddr_base64 : PatLeaf<(i64 tglobaladdr), [{
    const GlobalAddressSDNode *GA = dyn_cast<GlobalAddressSDNode>(N);
    return GA && (GA->getOffset() == 0) 
              && (GA->getAddressSpace() == Subtarget->getGlobalAS());
}]>;

//Global Readonly 32 bit address node
def tglobalroaddr32 : PatLeaf<(i32 tglobaladdr), [{
    const GlobalAddressSDNode *GA = dyn_cast<GlobalAddressSDNode>(N);
    return GA && (GA->getAddressSpace() == Subtarget->getConstantAS());
}]>;
// readonly 32 bit address node without offset
def tglobalroaddr_base : PatLeaf<(i32 tglobaladdr), [{
    const GlobalAddressSDNode *GA = dyn_cast<GlobalAddressSDNode>(N);
    return GA && (GA->getOffset() == 0) 
              && (GA->getAddressSpace() == Subtarget->getConstantAS());
}]>;

// Global readonly 64 bit address node
def tglobalroaddr64 : PatLeaf<(i64 tglobaladdr), [{
    const GlobalAddressSDNode *GA = dyn_cast<GlobalAddressSDNode>(N);
    return GA && (GA->getAddressSpace() == Subtarget->getConstantAS());
}]>;
// Global readonly 64 bit address node without offset
def tglobalroaddr_base64 : PatLeaf<(i64 tglobaladdr), [{
    const GlobalAddressSDNode *GA = dyn_cast<GlobalAddressSDNode>(N);
    return GA && (GA->getOffset() == 0) 
              && (GA->getAddressSpace() == Subtarget->getConstantAS());
}]>;

