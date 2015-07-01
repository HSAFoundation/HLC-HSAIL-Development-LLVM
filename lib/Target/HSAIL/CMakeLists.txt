
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

find_path(LIBHSAIL_INCLUDE_DIR
  NAMES
  libHSAIL/Brig.h)

find_library(LIBHSAIL_LIBRARIES hsail)


add_subdirectory(HSAILUtil)

cmake_dependent_option(HSAIL_USE_LIBHSAIL
  "Use libHSAIL for code emission of HSAIL" ON
  "LIBHSAIL_LIBRARIES" OFF)

set(sources
  HSAILAsmPrinter.cpp
  HSAILAlwaysInlinePass.cpp
#  BRIGDwarfCompileUnit.cpp
#  BRIGDwarfDebug.cpp
  HSAILELFTargetObjectFile.cpp
  HSAILFrameLowering.cpp
  HSAILInstrInfo.cpp
  HSAILIntrinsicInfo.cpp
  HSAILISelDAGToDAG.cpp
  HSAILISelLowering.cpp
  HSAILMachineFunctionInfo.cpp
  HSAILMCInstLower.cpp
  HSAILOptimizeMemoryOps.cpp
  HSAILModuleInfo.cpp
  HSAILParamManager.cpp
  HSAILRegisterInfo.cpp
  HSAILSection.cpp
  HSAILStoreInitializer.cpp
  HSAILSubtarget.cpp
  HSAILTargetMachine.cpp
  HSAILUtilityFunctions.cpp
  HSAILOpaqueTypes.cpp
  )

if(HSAIL_USE_LIBHSAIL)
  include_directories(${LIBHSAIL_INCLUDE_DIR})
  add_definitions("-DHSAIL_USE_LIBHSAIL")

  # We keep parts with a dependency on libHSAIL in a subdirectory
  # because the LLVM build checks for and errors on "unknown" source
  # files if we don't want to build them.
  list(APPEND sources
    BRIGAsmPrinter/BRIGAsmPrinter.h
    BRIGAsmPrinter/BRIGAsmPrinter.cpp
    BRIGAsmPrinter/BRIGDwarfCompileUnit.h
    BRIGAsmPrinter/HSAILKernelManager.cpp
    BRIGAsmPrinter/HSAILKernelManager.h
    BRIGAsmPrinter/LibHSAILAdapters.h)
endif()


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

target_link_libraries(LLVMHSAILCodeGen PRIVATE LLVMHSAILUtil)

if(HSAIL_USE_LIBHSAIL)
  target_link_libraries(LLVMHSAILCodeGen PRIVATE ${LIBHSAIL_LIBRARIES})
endif()


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
