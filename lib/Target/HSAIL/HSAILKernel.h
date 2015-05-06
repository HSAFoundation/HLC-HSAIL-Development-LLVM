//===-- HSAILKernel.h - HSAIL Kernel Class ----------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
/// \file
/// Definition of a HSAILKernel object and the various subclasses that
/// are used.
//
//===----------------------------------------------------------------------===//

#ifndef _HSAIL_KERNEL_H_
#define _HSAIL_KERNEL_H_

#include "HSAIL.h"
#include "llvm/IR/Value.h"
#include "llvm/IR/Constant.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/CodeGen/MachineFunction.h"

namespace llvm {
class HSAILSubtarget;
class HSAILTargetMachine;
/// structure that holds information for a single local/region address array
typedef struct _HSAILArrayMemRec {
  uint32_t vecSize; // size of each vector
  uint32_t offset;  // offset into the memory section
  uint32_t align;   // alignment
  bool isHW;        // flag to specify if HW is used or SW is used
  bool isRegion;    // flag to specify if GDS is used or not
} HSAILArrayMem;

/// structure that holds information about a constant address
/// space pointer that is a kernel argument
typedef struct _HSAILConstPtrRec {
  const Value *base;
  uint32_t size;
  uint32_t offset;
  uint32_t align;    // alignment
  uint32_t cbNum;    // value of 0 means that it does not use hw CB
  bool isArray;      // flag to specify that this is an array
  bool isArgument;   // flag to specify that this is for a kernel argument
  bool usesHardware; // flag to specify if hardware CB is used or not
  std::string name;
} HSAILConstPtr;

/// Structure that holds information for all local/region address
/// arrays in the kernel
typedef struct _HSAILLocalPrivateArgRec {
  // SmallVector<HSAILArrayMem *, DEFAULT_VEC_SLOTS> local;
  std::string name; // Kernel Name
} HSAILLocalPrivateArg;

/// Structure that holds information for each kernel argument
typedef struct _HSAILkernelArgRec {
  uint32_t reqGroupSize[3];  // x,y,z sizes for group.
  uint32_t reqRegionSize[3]; // x,y,z sizes for region.
  SmallVector<uint32_t, DEFAULT_VEC_SLOTS>
      argInfo;  // information about argumetns.
  bool mHasRWG; // true if reqd_work_group_size is specified.
  bool mHasRWR; // true if reqd_work_region_size is specified.

  _HSAILkernelArgRec() {
    mHasRWG = false;
    mHasRWR = false;
  }
} HSAILKernelAttr;

/// Holds information for each kernel.
struct HSAILKernel {
  uint32_t curSize;    // local memory, hardware + software emulated
  uint32_t curRSize;   // region memory, hardware + software emulated
  uint32_t curHWSize;  // hardware local memory
  uint32_t curHWRSize; // hardware region memory
  uint32_t constSize;  // software constant memory

  bool mKernel; // true if this is a kernel
  std::string mName;
  HSAILKernelAttr *sgv; // kernel attributes

  // vector containing constant pointer information
  SmallVector<struct _HSAILConstPtrRec, DEFAULT_VEC_SLOTS> constPtr;

  uint32_t constSizes[HW_MAX_NUM_CB]; // Size of each constant buffer

  // set that specifies the read-only images for the kernel
  SmallSet<uint32_t, 32> readOnly;

  // set that specifies the write-only images for the kernel
  SmallSet<uint32_t, 32> writeOnly;

  // set that specifies the read-write images for the kernel
  SmallSet<uint32_t, 32> readWrite;

  // set that specifies the access type qulifiers for the kernel arguments
  std::vector<uint32_t> accessTypeQualifer;

  // Vector of constant pool offsets
  SmallVector<std::pair<uint32_t, const Constant *>, DEFAULT_VEC_SLOTS>
      CPOffsets;

  // Vector of kernel argument type names
  std::vector<std::string> ArgTypeNames;

  // Fields required for device enqueue.
  bool EnqueuesKernel;  // true if enqueues a kernel.
  uint32_t KernelIndex; // positive value which deonotes the kernel index

  HSAILKernel() {
    curSize = 0;
    curRSize = 0;
    curHWSize = 0;
    curHWRSize = 0;
    constSize = 0;

    mKernel = false;
    sgv = nullptr;

    memset(constSizes, 0, sizeof(constSizes));
    EnqueuesKernel = false;
    KernelIndex = -1;
  }
};
} // end llvm namespace

#endif // _HSAIL_KERNEL_H_
