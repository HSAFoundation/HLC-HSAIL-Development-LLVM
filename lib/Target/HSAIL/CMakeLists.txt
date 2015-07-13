
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
  HSAILELFTargetObjectFile.cpp
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
endif()

add_llvm_target(HSAILCodeGen ${sources})

target_link_libraries(LLVMHSAILCodeGen PRIVATE LLVMHSAILUtil)

if(HSAIL_USE_LIBHSAIL)
  target_link_libraries(LLVMHSAILCodeGen PRIVATE ${LIBHSAIL_LIBRARIES})
endif()

add_subdirectory(InstPrinter)
add_subdirectory(TargetInfo)
add_subdirectory(MCTargetDesc)
