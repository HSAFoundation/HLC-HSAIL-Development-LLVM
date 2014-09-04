//===-- HSAILUtilityFunctions.h - HSAIL Utility Functions Header --------===//
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
// This file provides declarations for functions that are used across different
// classes and provide various conversions or utility to shorten the code
//
//===----------------------------------------------------------------------===//
#ifndef HSAILUTILITYFUNCTIONS_H_
#define HSAILUTILITYFUNCTIONS_H_

#include "HSAIL.h"
#include "HSAILLLVMVersion.h"
#include "HSAILTargetMachine.h"
#include "llvm/ADT/SmallVector.h"
#include "libHSAIL/Brig.h"

// Utility functions from ID
//
namespace llvm {
class TargetRegisterClass;
class SDValue;
class SDNode;
class Value;
class Type;
class TypeSymbolTable;
class StructType;
class IntegerType;
class FunctionType;
class VectorType;
class ArrayType;
class PointerType;
class MachineInstr;
class HSAILMachineFunctionInfo;
class GlobalVariable;
class SelectionDAG;
class DebugLoc;
}

// Debug functions for SDNode and SDValue.
void HSAILprintSDValue(const llvm::SDValue &Op, int level);
void HSAILprintSDNode(const llvm::SDNode *N);

// Group of functions that recursively calculate the size of a structure based
// on it's sub-types.
size_t HSAILgetTypeSize(const llvm::Type *T, bool dereferencePtr = false);
size_t HSAILgetTypeSize(const llvm::StructType *ST, bool dereferencePtr = false);
size_t HSAILgetTypeSize(const llvm::IntegerType *IT, bool dereferencePtr = false);
size_t HSAILgetTypeSize(const llvm::FunctionType *FT, bool dereferencePtr = false);
size_t HSAILgetTypeSize(const llvm::ArrayType *AT, bool dereferencePtr = false);
size_t HSAILgetTypeSize(const llvm::VectorType *VT, bool dereferencePtr = false);
size_t HSAILgetTypeSize(const llvm::PointerType *PT, bool dereferencePtr = false);

// Group of functions that recursively calculate the number of elements of a
// structure based on it's sub-types.
size_t HSAILgetNumElements(llvm::Type * const T);
size_t HSAILgetNumElements(llvm::StructType * const ST);
size_t HSAILgetNumElements(llvm::IntegerType * const IT);
size_t HSAILgetNumElements(llvm::FunctionType * const FT);
size_t HSAILgetNumElements(llvm::ArrayType * const AT);
size_t HSAILgetNumElements(llvm::VectorType * const VT);
size_t HSAILgetNumElements(llvm::PointerType * const PT);

Brig::BrigType16_t HSAILgetBrigType(llvm::Type* type, bool is64Bit, bool Signed = false);

const llvm::Value *HSAILgetBasePointerValue(const llvm::Value *V);
const llvm::Value *HSAILgetBasePointerValue(const llvm::MachineInstr *MI);

const char *
HSAILgetTypeName(llvm::Type *ptr, 
                 const char *symTab, 
                 llvm::HSAILMachineFunctionInfo *mMFI,
                 bool signedType);

int64_t HSAIL_GET_SCALAR_SIZE(llvm::Type* A);

bool HSAILcommaPrint(int i, OSTREAM_TYPE &O);

// Helper functions that check the opcode for status information
bool hasAddress(const llvm::MachineInstr *MI);
int addressOpNum(const llvm::MachineInstr *MI);
llvm::MachineOperand &getBase(llvm::MachineInstr *MI);
llvm::MachineOperand &getIndex(llvm::MachineInstr *MI);
llvm::MachineOperand &getOffset(llvm::MachineInstr *MI);
llvm::MachineOperand &getWidth(llvm::MachineInstr *MI);
llvm::MachineOperand &getWidth(const llvm::MachineInstr *MI);
llvm::MachineOperand &getLdStAlign(llvm::MachineInstr *MI);
llvm::MachineOperand &getLdStAlign(const llvm::MachineInstr *MI);
llvm::MachineOperand &getLoadConstQual(llvm::MachineInstr *MI);
llvm::MachineOperand &getLoadConstQual(const llvm::MachineInstr *MI);

bool isLoad(const llvm::MachineInstr *MI);
bool isStore(const llvm::MachineInstr *MI);
bool isConv(const llvm::MachineInstr *MI);

bool HSAILisGlobalInst(const llvm::TargetMachine &TM, const llvm::MachineInstr *MI);
bool HSAILisPrivateInst(const llvm::TargetMachine &TM, const llvm::MachineInstr *MI);
bool HSAILisConstantInst(const llvm::TargetMachine &TM, const llvm::MachineInstr *MI);
bool HSAILisGroupInst(const llvm::TargetMachine &TM, const llvm::MachineInstr *MI);
bool HSAILisArgInst(const llvm::TargetMachine &TM, const llvm::MachineInstr *MI);

bool isKernelFunc(const llvm::Function *F);
bool isSPIRModule(const llvm::Module &M);

bool notUsedInKernel(const llvm::GlobalVariable *GV);
bool isIgnoredGV(const llvm::GlobalVariable *GV);
bool sanitizeGlobalValueName(llvm::GlobalValue *GV);

bool isParametrizedUnaryRetAtomicOp(int opcode);
bool isParametrizedUnaryAtomicOp(int opcode);
bool isParametrizedBinaryRetAtomicOp(int opcode);
bool isParametrizedBinaryNoRetAtomicOp(int opcode);
bool isParametrizedBinaryAtomicOp(int opcode);
bool isParametrizedTernaryRetAtomicOp(int opcode);
bool isParametrizedTernaryNoRetAtomicOp(int opcode);
bool isParametrizedTernaryAtomicOp(int opcode);
bool isParametrizedAtomicOp(int opcode);
bool isParametrizedRetAtomicOp(int opcode);
bool hasParametrizedAtomicNoRetVersion(const llvm::MachineInstr *MI, llvm::SDNode *Node);

llvm::SDValue generateFenceIntrinsic(llvm::SDValue Chain, llvm::DebugLoc dl,
        unsigned memSeg,
        unsigned brigMemoryOrder,
        unsigned brigMemoryScope,
        llvm::SelectionDAG &CurDAG);

#endif // HSAILUTILITYFUNCTIONS_H_
