
add_llvm_library(LLVMHSAILDesc
  BRIGDwarfStreamer.cpp

  HSAILMCCodeEmitter.cpp
  HSAILMCTargetDesc.cpp
  HSAILTargetStreamer.cpp
  HSAILMCAsmInfo.cpp
  HSAILMCAsmStreamer.cpp
  RawVectorOstream.cpp
  )

# FIXME: How does this work for every other target? None of them need
# to specify this dependency.
target_link_libraries(LLVMHSAILDesc PRIVATE LLVMHSAILAsmPrinter)
