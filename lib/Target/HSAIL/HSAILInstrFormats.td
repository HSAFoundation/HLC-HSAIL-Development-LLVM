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

class HSAILInst<dag outs, dag ins, string asmstr, list<dag> pattern>
  : Instruction {
  field bits<32> Inst;
  bit hasWidthOperand = 0;
  let Namespace = "HSAIL";
  dag OutOperandList = outs;
  dag InOperandList = ins;
  let AsmString   = !strconcat(asmstr, ";");
  let Pattern = pattern;

  let UseNamedOperandTable = 1;

  // Target specific flags
  // Important! Keep in sync with HSAIL.h::HSAILTSFLAG

  // Instruction classes. See BrigKind.
  bit InstAddr = 0;
  bit InstAtomic = 0;
  bit InstBasic = 0;
  bit InstBr = 0;
  bit InstCmp = 0;
  bit InstCvt = 0;
  bit InstImage = 0;
  bit InstLane = 0;
  bit InstMem = 0;
  bit InstMemFence = 0;
  bit InstMod = 0;
  bit InstQueryImage = 0;
  bit InstQuerySampler = 0;
  bit InstQueue = 0;
  bit InstSeg = 0;
  bit InstSegCvt = 0;
  bit InstSignal = 0;
  bit InstSourceType = 0;

  // FIXME: Remove these
  bit isLoad = 0;
  bit isStore = 0;
  bit isConv = 0;
  bit isAtomic = 0;
  bit isImageInst = 0;
  bit isCrossLaneInst = 0;


  let TSFlags{3} = InstAddr;
  let TSFlags{4} = InstAtomic;
  let TSFlags{5} = InstBasic;
  let TSFlags{6} = InstBr;
  let TSFlags{7} = InstCmp;
  let TSFlags{8} = InstCvt;
  let TSFlags{9} = InstImage;
  let TSFlags{10} = InstLane;
  let TSFlags{11} = InstMem;
  let TSFlags{12} = InstMemFence;
  let TSFlags{13} = InstMod;
  let TSFlags{14} = InstQueryImage;
  let TSFlags{15} = InstQuerySampler;
  let TSFlags{16} = InstQueue;
  let TSFlags{17} = InstSeg;
  let TSFlags{18} = InstSegCvt;
  let TSFlags{19} = InstSignal;
  let TSFlags{20} = InstSourceType;

  let TSFlags{21} = isLoad;
  let TSFlags{22} = isStore;
  let TSFlags{23} = isConv;
  let TSFlags{24} = isAtomic;
  let TSFlags{25} = isImageInst;
  let TSFlags{26} = isCrossLaneInst;
}

let TargetPrefix = "HSAIL", isTarget = 1 in {

    class UnaryIntIntr : Intrinsic<[llvm_anyint_ty],
      [LLVMMatchType<0>], []>;

    class UnaryIntIntrNoMem : Intrinsic<[llvm_anyint_ty],
      [LLVMMatchType<0>], [IntrNoMem]>;

    class UnaryFloatIntr : Intrinsic<[llvm_anyfloat_ty],
      [LLVMMatchType<0>], []>;

    class UnaryFloatIntrNoMem : Intrinsic<[llvm_anyfloat_ty],
      [LLVMMatchType<0>], [IntrNoMem]>;

    class BinaryIntIntr : Intrinsic<[llvm_anyint_ty],
      [LLVMMatchType<0>, LLVMMatchType<0>], []>;

    class BinaryIntIntrNoMem : Intrinsic<[llvm_anyint_ty],
      [LLVMMatchType<0>, LLVMMatchType<0>], [IntrNoMem]>;

    class BinaryFloatIntr : Intrinsic<[llvm_anyfloat_ty],
      [LLVMMatchType<0>, LLVMMatchType<0>], []>;

    class BinaryFloatIntrNoMem : Intrinsic<[llvm_anyfloat_ty],
      [LLVMMatchType<0>, LLVMMatchType<0>], [IntrNoMem]>;

    class TernaryIntIntr : Intrinsic<[llvm_anyint_ty],
      [LLVMMatchType<0>, LLVMMatchType<0>, LLVMMatchType<0>], []>;

    class TernaryIntIntrNoMem : Intrinsic<[llvm_anyint_ty],
      [LLVMMatchType<0>, LLVMMatchType<0>, LLVMMatchType<0>], [IntrNoMem]>;

    class TernaryFloatIntr : Intrinsic<[llvm_anyfloat_ty],
      [LLVMMatchType<0>, LLVMMatchType<0>, LLVMMatchType<0>], []>;

    class TernaryFloatIntrNoMem : Intrinsic<[llvm_anyfloat_ty],
      [LLVMMatchType<0>, LLVMMatchType<0>, LLVMMatchType<0>], [IntrNoMem]>;

    // Cross-Lane
    class CrossLaneVecIntr :
      Intrinsic<[llvm_i64_ty, llvm_i64_ty, llvm_i64_ty, llvm_i64_ty],
      [llvm_i1_ty], []>;

    class ClassIntr : Intrinsic<[llvm_i1_ty], 
      [llvm_anyfloat_ty, llvm_anyint_ty], []>;

    class ClassIntrNoMem : Intrinsic<[llvm_i1_ty],
      [llvm_anyfloat_ty, llvm_anyint_ty], [IntrNoMem]>;

    class UnaryIntFloatIntr : Intrinsic<[llvm_anyint_ty],
      [llvm_anyfloat_ty], []>;

    class UnaryIntFloatIntrNoMem : Intrinsic<[llvm_anyint_ty],
      [llvm_anyfloat_ty], [IntrNoMem]>;

    class UnaryFloatIntIntr : Intrinsic<[llvm_anyfloat_ty],
      [llvm_anyint_ty], []>;

    class UnaryFloatIntIntrNoMem : Intrinsic<[llvm_anyfloat_ty],
      [llvm_anyint_ty], [IntrNoMem]>;

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
