
include(CMakeDependentOption)

set(LLVM_TARGET_DEFINITIONS HSAIL.td)

tablegen(LLVM HSAILGenRegisterInfo.inc -gen-register-info)
tablegen(LLVM HSAILGenInstrInfo.inc -gen-instr-info)
tablegen(LLVM HSAILGenAsmWriter.inc -gen-asm-writer)
tablegen(LLVM HSAILGenCodeEmitter.inc -gen-emitter)
tablegen(LLVM HSAILGenDAGISel.inc -gen-dag-isel)
tablegen(LLVM HSAILGenSubtargetInfo.inc -gen-subtarget)
tablegen(LLVM HSAILGenCallingConv.inc -gen-callingconv)
tablegen(LLVM HSAILGenIntrinsics.inc -gen-tgt-intrinsic)

add_public_tablegen_target(HSAILCommonTableGen)

add_subdirectory(HSAILUtil)

set(sources
  HSAILAsmPrinter.cpp
  HSAILAlwaysInlinePass.cpp
  HSAILFrameLowering.cpp
  HSAILInstrInfo.cpp
  HSAILIntrinsicInfo.cpp
  HSAILISelDAGToDAG.cpp
  HSAILISelLowering.cpp
  HSAILMachineFunctionInfo.cpp
  HSAILMCInstLower.cpp
  HSAILModuleInfo.cpp
  HSAILParamManager.cpp
  HSAILRegisterInfo.cpp
  HSAILSection.cpp
  HSAILStoreInitializer.cpp
  HSAILSubtarget.cpp
  HSAILTargetMachine.cpp
  HSAILTargetObjectFile.cpp
  HSAILUtilityFunctions.cpp
  HSAILOpaqueTypes.cpp
  )

if( CMAKE_CL_64 )
  # A workaround for a bug in cmake 2.8.3. See PR 8885.
  if( CMAKE_VERSION STREQUAL "2.8.3" )
    include(CMakeDetermineCompilerId)
  endif()
endif()

add_llvm_target(HSAILCodeGen ${sources})

target_link_libraries(LLVMHSAILCodeGen PRIVATE LLVMHSAILUtil)

add_subdirectory(InstPrinter)
add_subdirectory(TargetInfo)
add_subdirectory(MCTargetDesc)
