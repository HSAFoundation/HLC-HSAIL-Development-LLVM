
add_llvm_library(LLVMHSAILDesc
  BRIGDwarfStreamer.cpp

  HSAILAsmBackend.cpp
  HSAILELFObjectWriter.cpp
  HSAILMCCodeEmitter.cpp
  HSAILMCTargetDesc.cpp
  HSAILMCAsmInfo.cpp
  RawVectorOstream.cpp
  )
