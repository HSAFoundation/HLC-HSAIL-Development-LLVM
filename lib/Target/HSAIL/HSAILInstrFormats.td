//===------ HSAILInstrFormats.td ---------------------------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Instruction format superclass
//===----------------------------------------------------------------------===//

// TODO HSA : fix so that a space is not emitted prior to end of
// statement semi-colon

// TODO_HSA: Once we have InstrMappings in llvm 
// reimplement our scalar to vector maps using core llvm functionality
class VectorOperation;

class HSAILInst<dag outs, dag ins, string asmstr, list<dag> pattern>
  : Instruction {
  field bits<32> Inst;
  bit hasWidthOperand = 0;
  bit needSpecialProcessing = 0;
  bit isImageInst = 0;
  bit isCrossLaneInst = 0;
  let Namespace = "HSAIL";
  dag OutOperandList = outs;
  dag InOperandList = ins;
  let AsmString   = !strconcat(asmstr, " ;");
  let Pattern = pattern;

  // Vector relations
  int VectorSize = 0;

  // Target specific flags
  // Important! Keep in sync with HSAIL.h::HSAILTSFLAG
  bit hasAddress = 0;
  let TSFlags{0} = hasAddress;
  bits<3> addressOpNum = 0;
  let TSFlags{3-1} = addressOpNum;
  bit isLoad = 0;
  let TSFlags{4} = isLoad;
  bit isStore = 0;
  let TSFlags{5} = isStore;
  bit isConv = 0;
  let TSFlags{6} = isConv;
}

let TargetPrefix = "HSAIL", isTarget = 1 in {

    class UnaryIntIntr : Intrinsic<[llvm_anyint_ty],
      [LLVMMatchType<0>], []>;

    class UnaryFloatIntr : Intrinsic<[llvm_anyfloat_ty],
      [LLVMMatchType<0>], []>;

    class BinaryIntIntr : Intrinsic<[llvm_anyint_ty],
      [LLVMMatchType<0>, LLVMMatchType<0>], []>;

    class BinaryFloatIntr : Intrinsic<[llvm_anyfloat_ty],
      [LLVMMatchType<0>, LLVMMatchType<0>], []>;

    class TernaryIntIntr : Intrinsic<[llvm_anyint_ty],
      [LLVMMatchType<0>, LLVMMatchType<0>, LLVMMatchType<0>], []>;

    class TernaryFloatIntr : Intrinsic<[llvm_anyfloat_ty],
      [LLVMMatchType<0>, LLVMMatchType<0>, LLVMMatchType<0>], []>;

    // Cross-Lane
	class CrossLaneVecIntr :
	  Intrinsic<[llvm_i64_ty, llvm_i64_ty, llvm_i64_ty, llvm_i64_ty],
      [llvm_i1_ty], []>;

    class ClassIntr : Intrinsic<[llvm_i1_ty], 
      [llvm_anyfloat_ty, llvm_anyint_ty], []>;

    class UnaryIntFloatIntr : Intrinsic<[llvm_anyint_ty],
      [llvm_anyfloat_ty], []>;

    class UnaryFloatIntIntr : Intrinsic<[llvm_anyfloat_ty],
      [llvm_anyint_ty], []>;

    // Read image intrinsic classes
    class ReadImage1DIntr<string name, LLVMType DestType, LLVMType CoordType>
          : GCCBuiltin<name>,
            Intrinsic<[DestType, DestType, DestType, DestType], 
                      [llvm_ptr_ty, llvm_ptr_ty, CoordType],
                      [IntrReadArgMem, NoCapture<4>, NoCapture<5>]>;

    class ReadImage2DIntr<string name, LLVMType DestType, LLVMType CoordType>
          : GCCBuiltin<name>,
            Intrinsic<[DestType, DestType, DestType, DestType], 
                      [llvm_ptr_ty, llvm_ptr_ty, CoordType, CoordType],
                      [IntrReadArgMem, NoCapture<4>, NoCapture<5>]>;

    class ReadImage3DIntr<string name, LLVMType DestType, LLVMType CoordType>
          : GCCBuiltin<name>,
            Intrinsic<[DestType, DestType, DestType, DestType], 
                      [llvm_ptr_ty, llvm_ptr_ty, CoordType, CoordType, CoordType],
                      [IntrReadArgMem, NoCapture<4>, NoCapture<5>]>;

    // OpenCL 2.0 image 2D Depth
    class ReadImage2DDepthIntr<string name, LLVMType DestType, LLVMType CoordType>
          : GCCBuiltin<name>,
            Intrinsic<[DestType],
                      [llvm_ptr_ty, llvm_ptr_ty, CoordType, CoordType],
                      [IntrReadArgMem, NoCapture<1>, NoCapture<2>]>;

	// OpenCL 2.0 image 2D Array Depth
    class ReadImage2DArrayDepthIntr<string name, LLVMType DestType, LLVMType CoordType>
          : GCCBuiltin<name>,
            Intrinsic<[DestType],
                      [llvm_ptr_ty, llvm_ptr_ty, CoordType, CoordType, CoordType],
                      [IntrReadArgMem, NoCapture<1>, NoCapture<2>]>;

    // Load Image intrinsic classes
    class LoadImage1DIntr<string name, LLVMType DestType, LLVMType CoordType>
          : GCCBuiltin<name>,
            Intrinsic<[DestType, DestType, DestType, DestType], 
                      [llvm_ptr_ty, CoordType],
                      [IntrReadArgMem, NoCapture<4>]>;

    class LoadImage2DIntr<string name, LLVMType DestType, LLVMType CoordType>
          : GCCBuiltin<name>,
            Intrinsic<[DestType, DestType, DestType, DestType], 
                      [llvm_ptr_ty, CoordType, CoordType],
                      [IntrReadArgMem, NoCapture<4>]>;

    class LoadImage3DIntr<string name, LLVMType DestType, LLVMType CoordType>
          : GCCBuiltin<name>,
            Intrinsic<[DestType, DestType, DestType, DestType], 
                      [llvm_ptr_ty, CoordType, CoordType, CoordType],
                      [IntrReadArgMem, NoCapture<4>]>;

    class LoadImage2DDepthIntr<string name, LLVMType DestType, LLVMType CoordType>
	      : GCCBuiltin<name>,
            Intrinsic<[DestType],
                      [llvm_ptr_ty, CoordType, CoordType],
                      [IntrReadArgMem, NoCapture<1>]>;

	class LoadImage2DArrayDepthIntr<string name, LLVMType DestType, LLVMType CoordType>
	      :GCCBuiltin<name>,
           Intrinsic<[DestType],
                     [llvm_ptr_ty, CoordType, CoordType, CoordType],
                     [IntrReadArgMem, NoCapture<1>]>;

    // Store image intrinsic classes 
    class StoreImage1dInt :
      Intrinsic<[], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty,
        llvm_ptr_ty, 
        llvm_i32_ty], []>;

    class StoreImage1dFloat :
      Intrinsic<[], [llvm_float_ty, llvm_float_ty, llvm_float_ty, llvm_float_ty,
        llvm_ptr_ty, 
        llvm_i32_ty], []>;

    class StoreImage2dInt :
      Intrinsic<[], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty,
        llvm_ptr_ty, 
        llvm_i32_ty, llvm_i32_ty], []>;

    class StoreImage2dFloat :
      Intrinsic<[], [llvm_float_ty, llvm_float_ty, llvm_float_ty, llvm_float_ty,
        llvm_ptr_ty, 
        llvm_i32_ty, llvm_i32_ty], []>;

    class StoreImage3dInt :
      Intrinsic<[], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty,
        llvm_ptr_ty, 
        llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], []>;
 
    class StoreImage3dFloat :
      Intrinsic<[], [llvm_float_ty, llvm_float_ty, llvm_float_ty, llvm_float_ty,
        llvm_ptr_ty, 
        llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], []>;

    class StoreImage2dDepthFloat :
      Intrinsic<[], [llvm_float_ty,
	llvm_ptr_ty,
	llvm_i32_ty, llvm_i32_ty], []>;

    class StoreImage2dArrayDepthFloat :
      Intrinsic<[], [llvm_float_ty,
        llvm_ptr_ty,
        llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty], []>;
}

def target : Operand<OtherVT> {}
