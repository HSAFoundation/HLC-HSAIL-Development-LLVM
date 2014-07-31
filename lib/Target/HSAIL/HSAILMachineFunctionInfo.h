//== HSAILMachineFunctionInfo.h - HSA il Machine Function Info -*- C++ -*-===//
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
//
// This file declares HSAIL-specific per-machine-function information
//
//===----------------------------------------------------------------------===//
#ifndef _HSAILMACHINEFUNCTIONINFO_H_
#define _HSAILMACHINEFUNCTIONINFO_H_
#include "HSAIL.h"
#include "HSAILDevice.h"
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
namespace llvm
{
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

  enum NameDecorationStyle
  {
    NONE,
    StdCall,
    FastCall
  };
  typedef struct SamplerInfoRec {
    std::string name; // The name of the sampler
    uint32_t val; // The value of the sampler
    uint32_t idx; // The sampler resource id
  } SamplerInfo;
  // Some typedefs that will help with using the various iterators
  // of the machine function info class.
  typedef std::map<uint32_t, uint32_t>::iterator lit32_iterator;
  typedef std::map<uint64_t, uint32_t>::iterator lit64_iterator;
  typedef std::map<std::pair<uint64_t, uint64_t>, uint32_t>::iterator
    lit128_iterator;
  typedef StringMap<SamplerInfo>::iterator sampler_iterator;
  typedef DenseSet<uint32_t>::iterator func_iterator;
  typedef DenseSet<uint32_t>::iterator intr_iterator;
  typedef DenseSet<uint32_t>::iterator uav_iterator;
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
  typedef DenseSet<const Value*>::iterator read_ptr_iterator;
  typedef DenseSet<const char*>::iterator error_iterator;
  typedef std::map<std::string, HSAILPrintfInfo*>::iterator printf_iterator;
  typedef std::set<std::string>::iterator func_md_iterator;
  typedef std::vector<std::string>::iterator kernel_md_iterator;
  // HSAILMachineFunctionInfo - This class is
  // derived from MachineFunction private
  // hsail target-specific information for each MachineFunction
  class HSAILMachineFunctionInfo : public MachineFunctionInfo
  {
    // CalleeSavedFrameSize - Size of the callee-saved
    // register portion of the
    // stack frame in bytes.
    unsigned int CalleeSavedFrameSize;
    // BytesToPopOnReturn - Number of bytes function pops on return.
    // Used on windows platform for stdcall & fastcall name decoration
    unsigned int BytesToPopOnReturn;
    // DecorationStyle - If the function requires additional
    // name decoration,
    // DecorationStyle holds the right way to do so.
    NameDecorationStyle DecorationStyle;
    // ReturnAddrIndex - FrameIndex for return slot.
    int ReturnAddrIndex;

    // TailCallReturnAddrDelta - Delta the ReturnAddr stack slot is moved
    // Used for creating an area before the register spill area
    // on the stack
    // the returnaddr can be savely move to this area
    int TailCallReturnAddrDelta;

    // SRetReturnReg - Some subtargets require that sret lowering includes
    // returning the value of the returned struct in a register.
    // This field holds the virtual register into which the sret
    // argument is passed.
    unsigned int SRetReturnReg;

    // UsesLocal - Specifies that this function uses LDS memory and
    // that it needs to be allocated.
    bool UsesLDS;

    // LDSArg - Flag that specifies if this function has an Local
    // argument or not
    bool LDSArg;

    // UsesGDS - Specifies that this function uses GDS memory and
    // that it needs to be allocated.
    bool UsesGDS;

    // GDSArg - Flag that specifies if this function has an Region
    // argument or not
    bool GDSArg;

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

    /// A map of constant to literal mapping for all of the 64bit
    /// literals in the current function.
    std::map<uint64_t, uint32_t> mLongLits;

    /// A map of constant to literal mapping for all of the 128bit
    /// literals in the current function.
    std::map<std::pair<uint64_t, uint64_t>, uint32_t> mVecLits;

    /// The number of literals that should be reserved.
    /// TODO: Remove this when the wrapper emitter is added.
    uint32_t mReservedLits;

    /// A map of name to sampler information that is used to emit
    /// metadata to the IL stream that the runtimes can use for
    /// hardware setup.
    StringMap<SamplerInfo> mSamplerMap;

    /// Array of flags to specify if a specific memory type is used or not.
    bool mUsedMem[HSAILDevice::MAX_IDS];

    /// Set of all functions that this function calls.
    DenseSet<uint32_t> mFuncs;

    /// Set of all intrinsics that this function calls.
    DenseSet<uint32_t> mIntrs;

    /// Set of all the raw uavs.
    DenseSet<uint32_t> mRawUAV;
    /// Set of all the arena uavs.
    DenseSet<uint32_t> mArenaUAV;

    /// Set of all semaphores
    DenseSet<uint32_t> mSemaphore;

    /// Set of all the read-only pointers
    DenseSet<const Value*> mReadPtr;

    /// A set of all errors that occured in the backend for this function.
    DenseSet<const char *> mErrors;

    /// A mapping of printf data and the printf string
    std::map<std::string, HSAILPrintfInfo*> mPrintfMap;

    /// A set of all of the metadata that is used for the current function.
    std::set<std::string> mMetadataFunc;

    /// A set of all of the metadata that is used for the function wrapper.
    std::vector<std::string> mMetadataKernel;

    SmallVector<unsigned, 16> mArgRegs;

    /// Information about the kernel, NULL if the function is not a kernel.
    HSAILKernel *mKernel;

    /// Pointer to the machine function that this information belongs to.
    MachineFunction *mMF;

    /// Pointer to the subtarget for this function.
    const HSAILSubtarget *mSTM;
    public:

    explicit HSAILMachineFunctionInfo(MachineFunction &MF);
    virtual ~HSAILMachineFunctionInfo();

    unsigned int getCalleeSavedFrameSize() const;
    void setCalleeSavedFrameSize(unsigned int bytes);

    unsigned int getBytesToPopOnReturn() const;
    void setBytesToPopOnReturn (unsigned int bytes);

    NameDecorationStyle getDecorationStyle() const;
    void setDecorationStyle(NameDecorationStyle style);

    int getRAIndex() const;
    void setRAIndex(int Index);

    int getTCReturnAddrDelta() const;
    void setTCReturnAddrDelta(int delta);

    unsigned int getSRetReturnReg() const;
    void setSRetReturnReg(unsigned int Reg);

    void setUsesLocal();
    void setHasLocalArg();

    void setUsesRegion();
    void setHasRegionArg();

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

    /// Add a 32bit floating point value to the literal table.
    uint32_t addf32Literal(const ConstantFP *CFP);

    /// Add a 32bit floating point value to the literal table.
    uint32_t addf32Literal(uint32_t val);

    /// Add a 64bit integer value to the literal table.
    uint32_t addi64Literal(uint64_t val);

    /// Add a 128 bit integer value to the literal table.
    uint32_t addi128Literal(uint64_t val_lo, uint64_t val_hi);

    /// Add a 64bit floating point literal as a 64bit integer value.
    uint32_t addf64Literal(const ConstantFP *CFP);

    /// Add a 64bit floating point literal as a 64bit integer value.
    uint32_t addf64Literal(uint64_t val);

    /// Get the number of literals that have currently been allocated.
    size_t getNumLiterals() const;

    /// Get the literal ID of an Integer literal of the given offset.
    uint32_t getIntLits(uint32_t lit);

    /// Get the literal ID of a Long literal of the given offset.
    uint32_t getLongLits(uint64_t lit);

    /// Get the literal ID of a Long literal of the given offset.
    uint32_t getVecLits(uint64_t low64, uint64_t high64);

    /// Add some literals to the number of reserved literals.
    void addReservedLiterals(uint32_t);

    // Add a sampler to the set of known samplers for the current kernel.
    uint32_t addSampler(std::string name, uint32_t value);

    // Iterators that point to the beginning and end of the sampler map.
    sampler_iterator sampler_begin() { return mSamplerMap.begin(); }
    sampler_iterator sampler_end() { return mSamplerMap.end(); }

    /// Set the flag for the memory ID to true for the current function.
    void setUsesMem(unsigned);
    /// Retrieve the flag for the memory ID.
    bool usesMem(unsigned);

    /// Add called functions to the set of all functions this function calls.
    void addCalledFunc(uint32_t id) { mFuncs.insert(id); }
    void eraseCalledFunc(uint32_t id) { mFuncs.erase(id); }
    size_t func_size() { return mFuncs.size(); }
    bool func_empty() { return mFuncs.empty(); }
    func_iterator func_begin() { return mFuncs.begin(); }
    func_iterator func_end() { return mFuncs.end(); }

    /// Add called intrinsics to the set of all intrinscis this function calls.
    void addCalledIntr(uint32_t id) { mIntrs.insert(id); }
    size_t intr_size() { return mIntrs.size(); }
    bool intr_empty() { return mIntrs.empty(); }
    intr_iterator intr_begin() { return mIntrs.begin(); }
    intr_iterator intr_end() { return mIntrs.end(); }

    /// Add a semaphore
    void sema_insert(uint32_t id) { mSemaphore.insert(id); }
    bool sema_count(uint32_t id) { return mSemaphore.count(id); }
    size_t sema_size() { return mSemaphore.size(); }
    sema_iterator sema_begin() { return mSemaphore.begin(); }
    sema_iterator sema_end() { return mSemaphore.end(); }

    /// Add a raw uav id.
    void uav_insert(uint32_t id) { mRawUAV.insert(id); }
    bool uav_count(uint32_t id) { return mRawUAV.count(id); }
    size_t uav_size() { return mRawUAV.size(); }
    uav_iterator uav_begin() { return mRawUAV.begin(); }
    uav_iterator uav_end() { return mRawUAV.end(); }

    /// Add an arena uav id.
    void arena_insert(uint32_t id) { mArenaUAV.insert(id); }
    bool arena_count(uint32_t id) { return mArenaUAV.count(id); }
    size_t arena_size() { return mArenaUAV.size(); }
    uav_iterator arena_begin() { return mArenaUAV.begin(); }
    uav_iterator arena_end() { return mArenaUAV.end(); }

    /// Add a pointer to the known set of read-only pointers
    void add_read_ptr(const Value* ptr) { mReadPtr.insert(ptr); }
    bool read_ptr_count(const Value* ptr) { return mReadPtr.count(ptr); }
    bool read_size() { return mReadPtr.size(); }
    read_ptr_iterator read_ptr_begin() { return mReadPtr.begin(); } 
    read_ptr_iterator read_ptr_end() { return mReadPtr.end(); }

    // Add an error to the output for the current function.
    typedef enum {
      RELEASE_ONLY, /// Only emit error message in release mode.
      DEBUG_ONLY, /// Only emit error message in debug mode.
      ALWAYS /// Always emit the error message.
    } ErrorMsgEnum;
    /// Add an error message to the set of all error messages.
    void addErrorMsg(const char* msg, ErrorMsgEnum val = ALWAYS);
    bool errors_empty() { return mErrors.empty(); }
    error_iterator errors_begin() { return mErrors.begin(); }
    error_iterator errors_end() { return mErrors.end(); }

    /// Add a string to the printf map
    uint32_t addPrintfString(std::string &name, unsigned offset);
    /// Add a operand to the printf string
    void addPrintfOperand(std::string &name, size_t idx, uint32_t size);
    bool printf_empty() { return mPrintfMap.empty(); }
    size_t printf_size() { return mPrintfMap.size(); }
    printf_iterator printf_begin() { return mPrintfMap.begin(); }
    printf_iterator printf_end() { return mPrintfMap.end(); }

    /// Add a string to the metadata set for a function/kernel wrapper
    void addMetadata(const char *md, bool kernelOnly = false);
    void addMetadata(std::string md, bool kernelOnly = false);
    func_md_iterator func_md_begin() { return mMetadataFunc.begin(); }
    func_md_iterator func_md_end() { return mMetadataFunc.end(); }
    kernel_md_iterator kernel_md_begin() { return mMetadataKernel.begin(); }
    kernel_md_iterator kernel_md_end() { return mMetadataKernel.end(); }

    /// Query to find out if we are a signed or unsigned integer type.
    bool isSignedIntType(const Value* ptr);

    /// Query to find out if we are a volatile pointer.
    bool isVolatilePointer(const Value* ptr);

    /// Query to find out if we are a restrict pointer.
    bool isRestrictPointer(const Value* ptr);

    /// Query to find out if we are a constant argument.
    bool isConstantArgument(const Value* ptr);

    /// add/retrieve the argument registers numbers
    void addArgReg(unsigned arg) { mArgRegs.push_back(arg); }
    unsigned getArgReg(unsigned arg) { 
      return (arg < mArgRegs.size()) ? mArgRegs[arg] : arg; }

    HSAILParamManager& getParamManager() { return ParamManager; }
    const HSAILParamManager& getParamManager() const { return ParamManager; }

  private:
    HSAILParamManager ParamManager;

  };
} // llvm namespace
#endif // _HSAILMACHINEFUNCTIONINFO_H_
