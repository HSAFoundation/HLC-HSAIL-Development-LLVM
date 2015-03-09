include_directories(BEFORE ${CMAKE_CURRENT_BINARY_DIR}/..)
add_llvm_library(LLVMHSAILUtil HSAILUtil.cpp)
