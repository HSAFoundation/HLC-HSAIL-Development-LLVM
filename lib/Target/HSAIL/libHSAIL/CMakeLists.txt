
# Hack: we need to include 'main' target directory to grab private headers
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/..)

set(sources
  HSAILBrigContainer.cpp
  HSAILBrigantine.cpp
  HSAILDump.cpp
  HSAILItems.cpp
  HSAILScanner.cpp
  HSAILUtilities.cpp
  HSAILValidatorBase.cpp
  HSAILBrigObjectFile.cpp
  HSAILDisassembler.cpp
  HSAILFloats.cpp
  HSAILParser.cpp
  HSAILScannerRules.cpp
  HSAILValidator.cpp
  hsail_c.cpp)

add_llvm_library(HSAIL ${sources})

