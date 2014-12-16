//===-- AMDSymbolName.h - Handling special symbols for AMD ----*- C++ -*-===//
//
//  This header file defines functions that recognize special symbols
//===--------------------------------------------------------------------===//

#ifndef AMDSymbolName_H
#define AMDSymbolName_H

#include "llvm/ADT/StringRef.h"

namespace llvm {

class AMDSymbolNames {
public:
  //===----------------------------------------------------------------------===//
  /// isKernelFunctionName - return true if FunctionName is a OpenCL kernel
  /// function.
  ///
  static bool isKernelFunctionName (const StringRef FunctionName) {
    return (FunctionName.startswith("__OpenCL_") &&
            (FunctionName.endswith("_kernel") || FunctionName.endswith("_stub")))
           ? true : false;
  }

  //===----------------------------------------------------------------------===//
  /// undecorateKernelFunctionName - return the actual undecorated name of the
  /// OpenCL kernel function.
  ///
  static StringRef undecorateKernelFunctionName (const StringRef FunctionName) {
    return FunctionName.substr(strlen("__OpenCL_"),
             FunctionName.size() - strlen("_kernel") - strlen("__OpenCL_"));
  }

  static std::string decorateKernelFunctionName (const StringRef FunctionName) {
    return std::string("__OpenCL_") + FunctionName.str() + std::string("_kernel");
  }

#if 1 || defined (AMD_OPENCL_MEMCOMBINE)
  //===----------------------------------------------------------------------===//
  /// isStubFunctionName - return true if FunctionName is a stub generated from
  /// an OpenCL kernel function.
  ///
  static bool isStubFunctionName (const StringRef FunctionName) {
    return (FunctionName.startswith("__OpenCL_") &&
            FunctionName.endswith("_stub"))
           ? true : false;
  }

  //===----------------------------------------------------------------------===//
  /// undecorateKernelFunctionName - return the actual undecorated name of the
  /// OpenCL kernel function corresponding to this stub function name.
  ///
  static StringRef undecorateStubFunctionName (const StringRef FunctionName) {
    return FunctionName.substr(strlen("__OpenCL_"),
             FunctionName.size() - strlen("_stub") - strlen("__OpenCL_"));
  }

  static std::string decorateStubFunctionName (const StringRef FunctionName) {
    return std::string("__OpenCL_") + FunctionName.str() + std::string("_stub");
  }
#endif

  //===----------------------------------------------------------------------===//
  /// isReservedFunctionName - return true if FunctionName is reserved and
  /// thus cannot be deleted.
  ///
  static bool isReservedFunctionName(const StringRef FunctionName) {
    if (FunctionName.startswith("___") || FunctionName.startswith("llvm.") ||
        FunctionName.startswith("__amdrt_")) {
      return true;
    }
    return false;
  }

  //===----------------------------------------------------------------------===//
  /// isReservedGlobalName - return true if GlobalName is reserved and
  /// thus cannot be deleted.
  ///
  static bool isReservedGlobalName(const StringRef GlobalName) {
    if ( GlobalName.startswith("llvm.") ||
         GlobalName.startswith("___")   ||
         (GlobalName.startswith("__OpenCL_") && (
           GlobalName.endswith("_metadata") ||
           GlobalName.endswith("_nature"))) ) {
      return true;
    } else {
      return false;
    }
  }

  static std::string decorateNatureName (const StringRef FunctionName) {
    return std::string("__OpenCL_") + FunctionName.str() + std::string("_nature");
  }
};

} // End llvm namespace
#endif
