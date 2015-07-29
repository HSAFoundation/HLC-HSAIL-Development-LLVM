
defm CMP : InstCmp_RetTypes<"cmp", BrigOpcode.CMP>;

////////////////////////////////////////////////////////////////////////////////
// floating-point classify instructions

defm CLASS : InstSourceType_2Op_Class_Types<"class", BrigOpcode.CLASS>;
def : InstSourceType_Class_Pat<CLASS_F32, HSAILclass, f32, BrigType.F32>;
def : InstSourceType_Class_Pat<CLASS_F64, HSAILclass, f64, BrigType.F64>;
