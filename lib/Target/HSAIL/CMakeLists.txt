set(LLVM_TARGET_DEFINITIONS HSAIL.td)

tablegen(LLVM HSAILGenRegisterInfo.inc -gen-register-info)
tablegen(LLVM HSAILGenInstrInfo.inc -gen-instr-info)
tablegen(LLVM HSAILGenAsmWriter.inc -gen-asm-writer)
tablegen(LLVM HSAILGenCodeEmitter.inc -gen-emitter)
tablegen(LLVM HSAILGenDAGISel.inc -gen-dag-isel)
tablegen(LLVM HSAILGenSubtargetInfo.inc -gen-subtarget)
tablegen(LLVM HSAILGenCallingConv.inc -gen-callingconv)
tablegen(LLVM HSAILGenIntrinsics.inc -gen-tgt-intrinsic)
tablegen(LLVM HSAILGenMnemonicMapper.inc -gen-mnemonic-mapper)

add_public_tablegen_target(HSAILCommonTableGen)

add_subdirectory(libHSAIL)

set(sources
  HSAILAsmPrinter.cpp
  HSAILAlwaysInlinePass.cpp
  BRIGAsmPrinter.cpp
#  BRIGDwarfCompileUnit.cpp
#  BRIGDwarfDebug.cpp
  HSAILInstrInfo.cpp
  HSAILIntrinsicInfo.cpp
  HSAILISelDAGToDAG.cpp
  HSAILISelLowering.cpp
  HSAILKernelManager.cpp
  HSAILMachineFunctionInfo.cpp
  HSAILMCInstLower.cpp
  HSAILModuleInfo.cpp
  HSAILParamManager.cpp
  HSAILRegisterInfo.cpp
  HSAILStoreInitializer.cpp
  HSAILSubtarget.cpp
  HSAILTargetMachine.cpp
  HSAILUtilityFunctions.cpp
  HSAILOpaqueTypes.cpp
  )

if( CMAKE_CL_64 )
  # A workaround for a bug in cmake 2.8.3. See PR 8885.
  if( CMAKE_VERSION STREQUAL "2.8.3" )
    include(CMakeDetermineCompilerId)
  endif()
  # end of workaround.
#  enable_language(ASM_MASM)
#  ADD_CUSTOM_COMMAND(
#    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/HSAILCompilationCallback_Win64.obj
#    MAIN_DEPENDENCY HSAILCompilationCallback_Win64.asm
#    COMMAND ${CMAKE_ASM_MASM_COMPILER} /Fo ${CMAKE_CURRENT_BINARY_DIR}/HSAILCompilationCallback_Win64.obj /c ${CMAKE_CURRENT_SOURCE_DIR}/HSAILCompilationCallback_Win64.asm
#   )
#   set(sources ${sources} ${CMAKE_CURRENT_BINARY_DIR}/HSAILCompilationCallback_Win64.obj)
endif()

add_llvm_target(HSAILCodeGen ${sources})

target_link_libraries(LLVMHSAILCodeGen PRIVATE HSAIL)

# add_dependencies(LLVMHSAILCodeGen
#   LLVMAnalysis
#   LLVMAsmPrinter
#   LLVMCodeGen
#   LLVMCore
#   LLVMMC
#   LLVMSelectionDAG
#   LLVMSupport
#   LLVMTarget
#   LLVMHSAILAsmPrinter
#   )
#add_subdirectory(AsmParser)
#add_subdirectory(Disassembler)
add_subdirectory(InstPrinter)
add_subdirectory(TargetInfo)
add_subdirectory(MCTargetDesc)
