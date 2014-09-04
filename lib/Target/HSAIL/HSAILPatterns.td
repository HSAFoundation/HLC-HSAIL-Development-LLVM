//===---------- HSAILPatterns.td - HSAIL Target Patterns ---*-tablegen-*---===//
//
// Store pattern fragments
//
//===----------------------------------------------------------------------===//


def ADDR : ComplexPattern<iPTR, 3, "SelectAddr", [], []>;

def flat_load : PatFrag<(ops node:$ptr),
                  (load node:$ptr),
                  [{return isFlatLoad(dyn_cast<LoadSDNode>(N));}]>;

def global_load : PatFrag<(ops node:$ptr),
                  (load node:$ptr),
                  [{return isGlobalLoad(dyn_cast<LoadSDNode>(N));}]>;

def constant_load : PatFrag<(ops node:$ptr),
                    (load node:$ptr),
                    [{return isConstantLoad(dyn_cast<LoadSDNode>(N), -1);}]>;

def private_load : PatFrag<(ops node:$ptr),
                   (load node:$ptr),
                   [{return isPrivateLoad(dyn_cast<LoadSDNode>(N));}]>;

def spill_load : PatFrag<(ops node:$ptr),
                   (load node:$ptr),
                   [{return isSpillLoad(dyn_cast<LoadSDNode>(N));}]>;

def group_load : PatFrag<(ops node:$ptr),
                 (load node:$ptr),
                 [{return isGroupLoad(dyn_cast<LoadSDNode>(N));}]>;

def kernarg_load : PatFrag<(ops node:$ptr),
                 (load node:$ptr),
                 [{return isKernargLoad(dyn_cast<LoadSDNode>(N));}]>;

def arg_load     : PatFrag<(ops node:$ptr),
                 (load node:$ptr),
                 [{return isArgLoad(dyn_cast<LoadSDNode>(N));}]>;

def flat_store : PatFrag<(ops node:$val, node:$ptr),
                   (store node:$val, node:$ptr),
                   [{return isFlatStore(dyn_cast<StoreSDNode>(N));}]>;

def global_store : PatFrag<(ops node:$val, node:$ptr),
                   (store node:$val, node:$ptr),
                   [{return isGlobalStore(dyn_cast<StoreSDNode>(N));}]>;

def private_store : PatFrag<(ops node:$val, node:$ptr),
                    (store node:$val, node:$ptr),
                    [{return isPrivateStore(dyn_cast<StoreSDNode>(N));}]>;

def spill_store : PatFrag<(ops node:$val, node:$ptr),
                    (store node:$val, node:$ptr),
                    [{return isSpillStore(dyn_cast<StoreSDNode>(N));}]>;

def group_store : PatFrag<(ops node:$val, node:$ptr),
                  (store node:$val, node:$ptr),
                  [{return isGroupStore(dyn_cast<StoreSDNode>(N));}]>;

def arg_store : PatFrag<(ops node:$val, node:$ptr),
                  (store node:$val, node:$ptr),
                  [{return isArgStore(dyn_cast<StoreSDNode>(N));}]>;

// Extending loads
multiclass ExtLoadPat<PatFrag extloadpat> {
  def _flat     : PatFrag<(ops node:$ptr), 
                          (extloadpat node:$ptr),
                          [{return isFlatLoad(dyn_cast<LoadSDNode>(N));}]>;

  def _global   : PatFrag<(ops node:$ptr), 
                          (extloadpat node:$ptr),
                          [{return isGlobalLoad(dyn_cast<LoadSDNode>(N));}]>;

  def _constant : PatFrag<(ops node:$ptr), 
                          (extloadpat node:$ptr),
                          [{return isConstantLoad(dyn_cast<LoadSDNode>(N), -1);}]>;

  def _group    : PatFrag<(ops node:$ptr), 
                          (extloadpat node:$ptr),
                          [{return isGroupLoad(dyn_cast<LoadSDNode>(N));}]>;
  
  def _private  : PatFrag<(ops node:$ptr), 
                          (extloadpat node:$ptr),
                          [{return isPrivateLoad(dyn_cast<LoadSDNode>(N));}]>;

  def _kernarg  : PatFrag<(ops node:$ptr),
                          (extloadpat node:$ptr),
                          [{return isKernargLoad(dyn_cast<LoadSDNode>(N));}]>;

  def _arg      : PatFrag<(ops node:$ptr),
                          (extloadpat node:$ptr),
                          [{return isArgLoad(dyn_cast<LoadSDNode>(N));}]>;

  def _spill  : PatFrag<(ops node:$ptr), 
                          (extloadpat node:$ptr),
                          [{return isSpilllLoad(dyn_cast<LoadSDNode>(N));}]>;
}

defm extloadi8   : ExtLoadPat<extloadi8>;
defm sextloadi8  : ExtLoadPat<sextloadi8>;
defm zextloadi8  : ExtLoadPat<zextloadi8>;
defm extloadi16  : ExtLoadPat<extloadi16>;
defm sextloadi16 : ExtLoadPat<sextloadi16>;
defm zextloadi16 : ExtLoadPat<zextloadi16>;
defm extloadi32  : ExtLoadPat<extloadi32>;
defm sextloadi32 : ExtLoadPat<sextloadi32>;
defm zextloadi32 : ExtLoadPat<zextloadi32>;

// Truncating stores
multiclass TruncStorePat<PatFrag truncstorepat> {
  def _flat    : PatFrag<(ops node:$val, node:$ptr), 
                         (truncstorepat node:$val, node:$ptr),
                         [{return isFlatStore(dyn_cast<StoreSDNode>(N));}]>;

  def _global  : PatFrag<(ops node:$val, node:$ptr),
                         (truncstorepat node:$val, node:$ptr),
                         [{return isGlobalStore(dyn_cast<StoreSDNode>(N));}]>;

  def _group   : PatFrag<(ops node:$val, node:$ptr),
                         (truncstorepat node:$val, node:$ptr),
                         [{return isGroupStore(dyn_cast<StoreSDNode>(N));}]>;
  
  def _private : PatFrag<(ops node:$val, node:$ptr),
                         (truncstorepat node:$val, node:$ptr),
                         [{return isPrivateStore(dyn_cast<StoreSDNode>(N));}]>;

  def _spill   : PatFrag<(ops node:$val, node:$ptr),
                         (truncstorepat node:$val, node:$ptr),
                         [{return isSpillStore(dyn_cast<StoreSDNode>(N));}]>;

  def _arg     : PatFrag<(ops node:$val, node:$ptr),
                         (truncstorepat node:$val, node:$ptr),
                         [{return isArgStore(dyn_cast<StoreSDNode>(N));}]>;
}

defm truncstorei8  : TruncStorePat<truncstorei8>;
defm truncstorei16 : TruncStorePat<truncstorei16>;
defm truncstorei32 : TruncStorePat<truncstorei32>;
