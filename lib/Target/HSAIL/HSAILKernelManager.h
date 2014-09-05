//==-----------------------------------------------------------------------===//
//
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
// @file HSAILKernelManager.h
// @details Class that handles the metadata/abi management for the
// ASM printer. Handles the parsing and generation of the metadata
// for each kernel and keeps track of its arguments.
//
#ifndef _HSAILKERNELMANAGER_H_
#define _HSAILKERNELMANAGER_H_
#include "HSAIL.h"
#include "HSAILDevice.h"
#include "HSAILLLVMVersion.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/IR/ValueMap.h"
#include "llvm/IR/Function.h"
#include "llvm/CodeGen/MachineBasicBlock.h"
#include <string>
#include <set>
#include <map>
#define IMAGETYPE_2D 0
#define IMAGETYPE_3D 1
#define RESERVED_LIT_COUNT 6

namespace llvm {
class HSAILSubtarget;
class HSAILMachineFunctionInfo;
class HSAILModuleInfo;
class HSAILTargetMachine;
class StructType;
class Value;
class TypeSymbolTable;
class MachineFunction;
class MachineInstr;
class ConstantFP;
class HSAILPrintfInfo;


class HSAILKernelManager {
public:
  typedef enum {
    RELEASE_ONLY,
    DEBUG_ONLY,
    ALWAYS
  } ErrorMsgEnum;
  HSAILKernelManager(HSAILTargetMachine *TM);
  virtual ~HSAILKernelManager();

  /// Clear the state of the KernelManager putting it in its most initial state.
  void clear();
  void setMF(MachineFunction *MF);

  /// Process the specific kernel parsing out the parameter information for the
  /// kernel.
  void processArgMetadata(OSTREAM_TYPE &ignored,
                          uint32_t buf, bool kernel);


  /// Prints the header for the kernel which includes the groupsize declaration
  /// and calculation of the local/group/global id's.
  void printHeader(const std::string &name);

  void brigEmitMetaData(HSAIL_ASM::Brigantine& brig, uint32_t id, bool isKernel = false);

  /// Set bool value on whether to consider the function a kernel or a normal
  /// function.
  void setKernel(bool kernel);

  /// Set the unique ID of the kernel/function.
  void setID(uint32_t id);

  /// Set the name of the kernel/function.
  void setName(const std::string &name);

  // Get the UAV id for the specific pointer value.
  uint32_t getUAVID(const Value *value);

private:

  void updatePtrArg(llvm::Function::const_arg_iterator Ip,
                    int raw_uav_buffer,
                    int counter,
                    bool isKernel,
                    const Function *F,
                    int pointerCount);
  /// Name of the current kernel.
  std::string mName;
  uint32_t mUniqueID;
  bool mIsKernel;
  bool mWasKernel;
  bool mCompilerWrite;
  /// Flag to specify if an image write has occured or not in order to not add a
  /// compiler specific write if no other writes to memory occured.
  bool mHasImageWrite;
  bool mHasOutputInst;

  /// Map from const Value * to UAV ID.
  std::map<const Value *, uint32_t> mValueIDMap;

  HSAILTargetMachine * mTM;
  const HSAILSubtarget * mSTM;
  /// This is the global offset of the printf string id's.
  MachineFunction *mMF;
  HSAILMachineFunctionInfo *mMFI;
  HSAILModuleInfo *mAMI;
}; // class HSAILKernelManager

} // llvm namespace
#endif // _HSAILKERNELMANAGER_H_
