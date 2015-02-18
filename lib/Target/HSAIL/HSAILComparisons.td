
def CMP : InstCmp<"cmp", BrigOpcode.CMP>;

// TODO: Conversions of the comparision should skip the conversion and
// change the destination type.
def : Pat<
  (i1 (SetCCPat untyped:$src0, untyped:$src1,
                BrigCompareOperation:$op,
                i1:$ftz,
                BrigTypeX:$destType,
                BrigTypeX:$srcType)),
  (CMP $op, $ftz, $src0, $src1, $destType, $srcType)
>;

////////////////////////////////////////////////////////////////////////////////
// floating-point classify instructions

def CLASS : HSAILInstSourceType_2Op<"class", BrigOpcode.CLASS>;
def : InstSourceType_Class_Pat<CLASS, HSAILclass, f32, BrigTypeX.F32>;
def : InstSourceType_Class_Pat<CLASS, HSAILclass, f64, BrigTypeX.F64>;
