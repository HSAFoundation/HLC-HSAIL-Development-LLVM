//==-- HSAILMachineFunctionInfo.h -------------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
/// \file
/// This file declares HSAIL-specific per-machine-function information
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_HSAIL_HSAILMACHINEFUNCTIONINFO_H
#define LLVM_LIB_TARGET_HSAIL_HSAILMACHINEFUNCTIONINFO_H

#include "HSAIL.h"
#include "HSAILKernel.h"
#include "HSAILParamManager.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/IR/Function.h"
#include "llvm/CodeGen/MachineBasicBlock.h"
#include <string>
#include <set>
#include <map>

namespace llvm {
class HSAILSubtarget;
class HSAILPrintfInfo {
  uint32_t mPrintfID;
  SmallVector<uint32_t, DEFAULT_VEC_SLOTS> mOperands;

public:
  void addOperand(size_t idx, uint32_t size);
  uint32_t getPrintfID();
  void setPrintfID(uint32_t idx);
  size_t getNumOperands();
  uint32_t getOperandID(uint32_t idx);
}; // class HSAILPrintfInfo

enum NameDecorationStyle { NONE, StdCall, FastCall };
typedef struct SamplerInfoRec {
  std::string name; // The name of the sampler
  uint32_t val;     // The value of the sampler
  uint32_t idx;     // The sampler resource id
} SamplerInfo;
// Some typedefs that will help with using the various iterators
// of the machine function info class.
typedef StringMap<SamplerInfo>::iterator sampler_iterator;
typedef DenseSet<uint32_t>::iterator func_iterator;
typedef DenseSet<uint32_t>::iterator intr_iterator;
typedef DenseSet<uint32_t>::iterator sema_iterator;
typedef DenseSet<uint32_t>::iterator read_image1d_iterator;
typedef DenseSet<uint32_t>::iterator write_image1d_iterator;
typedef DenseSet<uint32_t>::iterator read_image1d_array_iterator;
typedef DenseSet<uint32_t>::iterator write_image1d_array_iterator;
typedef DenseSet<uint32_t>::iterator read_image1d_buffer_iterator;
typedef DenseSet<uint32_t>::iterator write_image1d_buffer_iterator;
typedef DenseSet<uint32_t>::iterator read_image2d_iterator;
typedef DenseSet<uint32_t>::iterator write_image2d_iterator;
typedef DenseSet<uint32_t>::iterator read_image2d_array_iterator;
typedef DenseSet<uint32_t>::iterator write_image2d_array_iterator;
typedef DenseSet<uint32_t>::iterator read_image3d_iterator;
typedef DenseSet<uint32_t>::iterator write_image3d_iterator;
typedef DenseSet<const Value *>::iterator read_ptr_iterator;
typedef DenseSet<const char *>::iterator error_iterator;
typedef std::map<std::string, HSAILPrintfInfo *>::iterator printf_iterator;
typedef std::set<std::string>::iterator func_md_iterator;
typedef std::vector<std::string>::iterator kernel_md_iterator;
// HSAILMachineFunctionInfo - This class is
// derived from MachineFunction private
// hsail target-specific information for each MachineFunction
class HSAILMachineFunctionInfo : public MachineFunctionInfo {
  // The size in bytes required to host all of the kernel arguments.
  // -1 means this value has not been determined yet.
  int32_t mArgSize;

  // The size in bytes required to host the stack and the kernel arguments
  // in private memory.
  // -1 means this value has not been determined yet.
  int32_t mScratchSize;

  // The size in bytes required to host the the kernel arguments
  // on the stack.
  // -1 means this value has not been determined yet.
  int32_t mStackSize;

  // The size in bytes required to host private variables
  // -1 means this value has not been determined yet.
  int32_t mPrivateMemSize;

  // The size in bytes required to host group variables
  // -1 means this value has not been determined yet.
  int32_t mGroupMemSize;

  /// A map of constant to literal mapping for all of the 32bit or
  /// smaller literals in the current function.
  std::map<uint32_t, uint32_t> mIntLits;

  /// A map of name to sampler information that is used to emit
  /// metadata to the IL stream that the runtimes can use for
  /// hardware setup.
  StringMap<SamplerInfo> mSamplerMap;

  /// Set of all functions that this function calls.
  DenseSet<uint32_t> mFuncs;

  /// Set of all intrinsics that this function calls.
  DenseSet<uint32_t> mIntrs;

  /// Set of all the raw uavs.
  DenseSet<uint32_t> mRawUAV;

  /// Set of all semaphores
  DenseSet<uint32_t> mSemaphore;

  /// Set of all the read-only pointers
  DenseSet<const Value *> mReadPtr;

  /// A set of all errors that occured in the backend for this function.
  DenseSet<const char *> mErrors;

  /// A set of all of the metadata that is used for the current function.
  std::set<std::string> mMetadataFunc;

  /// A set of all of the metadata that is used for the function wrapper.
  std::vector<std::string> mMetadataKernel;

  SmallVector<unsigned, 16> mArgRegs;

  /// A number of 64 bit register slots reserved for $s registers.
  unsigned RegisterPartitioning;

  /// Information about the kernel, NULL if the function is not a kernel.
  HSAILKernel *mKernel;

  /// Pointer to the machine function that this information belongs to.
  MachineFunction *mMF;

  /// Pointer to the subtarget for this function.
  const HSAILSubtarget *mSTM;

  bool HasSpilledCRs;
  bool HasScavengerSpill;

public:
  explicit HSAILMachineFunctionInfo(MachineFunction &MF);

  // FIXME: Remove these
  void setUsesLocal() {}
  void setUsesRegion() {}

  bool usesHWConstant(std::string name) const;
  bool isKernel() const;
  HSAILKernel *getKernel();

  /// Get the size in bytes that are required to host all of
  /// arguments and stack memory in scratch.
  uint32_t getScratchSize();

  /// Get the size in bytes that are required to host all of
  /// private memory in scratch.
  size_t getPrivateSize();

  /// Get the size in bytes that are required to host all of
  /// group memory.
  size_t getGroupSize();

  /// Get the size in bytes that is required to host all of
  /// the arguments on the stack.
  uint32_t getStackSize();

  ///
  /// @param val value to add the lookup table
  /// @param Opcode opcode of the literal instruction
  /// @brief adds the specified value of the type represented by the
  /// Opcode
  /// to the literal to integer and integer to literal mappings.
  ///
  /// Add a 32bit integer value to the literal table.
  // uint32_t addi32Literal(uint32_t val, int Opcode = HSAIL::LOADCONST_i32);
  uint32_t addi32Literal(uint32_t val, int Opcode = 0);

  // Iterators that point to the beginning and end of the sampler map.
  sampler_iterator sampler_begin() { return mSamplerMap.begin(); }
  sampler_iterator sampler_end() { return mSamplerMap.end(); }

  /// Add called functions to the set of all functions this function calls.
  void addCalledFunc(uint32_t id) { mFuncs.insert(id); }
  void eraseCalledFunc(uint32_t id) { mFuncs.erase(id); }
  size_t func_size() { return mFuncs.size(); }
  bool func_empty() { return mFuncs.empty(); }
  func_iterator func_begin() { return mFuncs.begin(); }
  func_iterator func_end() { return mFuncs.end(); }

  inline iterator_range<func_iterator> funcs() {
    return iterator_range<func_iterator>(func_begin(), func_end());
  }

  /// Add a semaphore
  void sema_insert(uint32_t id) { mSemaphore.insert(id); }
  bool sema_count(uint32_t id) { return mSemaphore.count(id); }
  size_t sema_size() { return mSemaphore.size(); }
  sema_iterator sema_begin() { return mSemaphore.begin(); }
  sema_iterator sema_end() { return mSemaphore.end(); }

  /// Add a raw uav id.
  void uav_insert(uint32_t id) { mRawUAV.insert(id); }

  /// Add a pointer to the known set of read-only pointers
  void add_read_ptr(const Value *ptr) { mReadPtr.insert(ptr); }
  bool read_ptr_count(const Value *ptr) { return mReadPtr.count(ptr); }
  bool read_size() { return mReadPtr.size(); }

  // Add an error to the output for the current function.
  typedef enum {
    RELEASE_ONLY, /// Only emit error message in release mode.
    DEBUG_ONLY,   /// Only emit error message in debug mode.
    ALWAYS        /// Always emit the error message.
  } ErrorMsgEnum;

  // FIXME: Remove these and use normal error reporting mechanism.
  /// Add an error message to the set of all error messages.
  void addErrorMsg(const char *msg, ErrorMsgEnum val = ALWAYS);
  bool errors_empty() { return mErrors.empty(); }
  error_iterator errors_begin() { return mErrors.begin(); }
  error_iterator errors_end() { return mErrors.end(); }

  /// Add a string to the metadata set for a function/kernel wrapper
  void addMetadata(const char *md, bool kernelOnly = false);
  void addMetadata(std::string md, bool kernelOnly = false);
  func_md_iterator func_md_begin() { return mMetadataFunc.begin(); }
  func_md_iterator func_md_end() { return mMetadataFunc.end(); }
  kernel_md_iterator kernel_md_begin() { return mMetadataKernel.begin(); }
  kernel_md_iterator kernel_md_end() { return mMetadataKernel.end(); }

  /// Query to find out if we are a signed or unsigned integer type.
  bool isSignedIntType(const Value *ptr);

  /// Query to find out if we are a volatile pointer.
  bool isVolatilePointer(const Value *ptr);

  /// Query to find out if we are a restrict pointer.
  bool isRestrictPointer(const Value *ptr);

  /// Query to find out if we are a constant argument.
  bool isConstantArgument(const Value *ptr);

  /// add/retrieve the argument registers numbers
  void addArgReg(unsigned arg) { mArgRegs.push_back(arg); }
  unsigned getArgReg(unsigned arg) {
    return (arg < mArgRegs.size()) ? mArgRegs[arg] : arg;
  }

  void setRegisterPartitioning(unsigned RegSlots) {
    RegisterPartitioning = RegSlots;
  }
  unsigned getRegisterPartitioning() const { return RegisterPartitioning; }

  HSAILParamManager &getParamManager() { return ParamManager; }
  const HSAILParamManager &getParamManager() const { return ParamManager; }


  bool hasSpilledCRs() const {
    return HasSpilledCRs;
  }

  void setHasSpilledCRs(bool Spill = true) {
    HasSpilledCRs = Spill;
  }

  bool hasScavengerSpill() const {
    return HasScavengerSpill;
  }

  void setHasScavengerSpill(bool Spill = true) {
    HasScavengerSpill = Spill;
  }

private:
  HSAILParamManager ParamManager;
};
} // llvm namespace

#endif
