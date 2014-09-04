//===------------- HSAILKernel.h - HSAIL Kernel Class ----------*- C++ -*--===//
// Copyright (c) 2011, Advanced Micro Devices, Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the copyright holder nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
// If you use the software (in whole or in part), you shall adhere to all
// applicable U.S., European, and other export laws, including but not limited
// to the U.S. Export Administration Regulations (“EAR”), (15 C.F.R. Sections
// 730 through 774), and E.U. Council Regulation (EC) No 1334/2000 of 22 June
// 2000.  Further, pursuant to Section 740.6 of the EAR, you hereby certify
// that, except pursuant to a license granted by the United States Department
// of Commerce Bureau of Industry and Security or as otherwise permitted
// pursuant to a License Exception under the U.S. Export Administration
// Regulations ("EAR"), you will not (1) export, re-export or release to a
// national of a country in Country Groups D:1, E:1 or E:2 any restricted
// technology, software, or source code you receive hereunder, or (2) export to
// Country Groups D:1, E:1 or E:2 the direct product of such technology or
// software, if such foreign produced direct product is subject to national
// security controls as identified on the Commerce Control List (currently
// found in Supplement 1 to Part 774 of EAR).  For the most current Country
// Group listings, or for additional information about the EAR or your
// obligations under those regulations, please refer to the U.S. Bureau of
// Industry and Security’s website at http://www.bis.doc.gov/.
//
//==-----------------------------------------------------------------------===//
// Definition of a HSAILKernel object and the various subclasses that 
// are used.
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
    const llvm::Value *base;
    uint32_t size;
    uint32_t offset;
    uint32_t align; // alignment
    uint32_t cbNum; // value of 0 means that it does not use hw CB
    bool isArray; // flag to specify that this is an array
    bool isArgument; // flag to specify that this is for a kernel argument
    bool usesHardware; // flag to specify if hardware CB is used or not
    std::string name;
  } HSAILConstPtr;
 
  /// Structure that holds information for all local/region address
  /// arrays in the kernel
  typedef struct _HSAILLocalPrivateArgRec {
    // llvm::SmallVector<HSAILArrayMem *, DEFAULT_VEC_SLOTS> local;
    std::string name; // Kernel Name
  } HSAILLocalPrivateArg;

  /// Structure that holds information for each kernel argument
  typedef struct _HSAILkernelArgRec {
    uint32_t reqGroupSize[3]; // x,y,z sizes for group.
    uint32_t reqRegionSize[3]; // x,y,z sizes for region.
    llvm::SmallVector<uint32_t, DEFAULT_VEC_SLOTS> argInfo; // information about argumetns.
    bool mHasRWG; // true if reqd_work_group_size is specified.
    bool mHasRWR; // true if reqd_work_region_size is specified.

    _HSAILkernelArgRec() {
      mHasRWG = false;
      mHasRWR = false;
    }
  } HSAILKernelAttr;

  /// Holds information for each kernel.
  struct HSAILKernel {
    uint32_t curSize;      // local memory, hardware + software emulated
    uint32_t curRSize;     // region memory, hardware + software emulated
    uint32_t curHWSize;    // hardware local memory
    uint32_t curHWRSize;   // hardware region memory
    uint32_t constSize;    // software constant memory

    bool mKernel;          // true if this is a kernel
    std::string mName;     
    HSAILKernelAttr *sgv;  // kernel attributes

    // vector containing constant pointer information
    llvm::SmallVector<struct _HSAILConstPtrRec, DEFAULT_VEC_SLOTS> constPtr;

    uint32_t constSizes[HW_MAX_NUM_CB]; // Size of each constant buffer

    // set that specifies the read-only images for the kernel
    llvm::SmallSet<uint32_t, 32> readOnly;

    // set that specifies the write-only images for the kernel
    llvm::SmallSet<uint32_t, 32> writeOnly;

    // set that specifies the read-write images for the kernel
    llvm::SmallSet<uint32_t, 32> readWrite;

    // set that specifies the access type qulifiers for the kernel arguments
    std::vector<uint32_t> accessTypeQualifer;

    // Vector of constant pool offsets
    llvm::SmallVector<std::pair<uint32_t, const llvm::Constant *>, DEFAULT_VEC_SLOTS> CPOffsets;

    // Vector of kernel argument type names
    std::vector<std::string> ArgTypeNames;

    // Fields required for device enqueue.
    bool EnqueuesKernel;   // true if enqueues a kernel.
    uint32_t KernelIndex;  // positive value which deonotes the kernel index

    HSAILKernel() {
      curSize = 0;
      curRSize = 0;
      curHWSize = 0;
      curHWRSize = 0;
      constSize = 0;

      mKernel = false;
      sgv = NULL;

      memset(constSizes, 0, sizeof(constSizes));
      EnqueuesKernel =false;
      KernelIndex = -1;
    }
  };

} // end llvm namespace
#endif // _HSAIL_KERNEL_H_
