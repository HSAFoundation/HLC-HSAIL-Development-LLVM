add_llvm_library(LLVMHSAILAsmPrinter
  HSAILInstPrinter.cpp
  )
target_link_libraries(LLVMHSAILAsmPrinter PRIVATE LLVMHSAILUtil)