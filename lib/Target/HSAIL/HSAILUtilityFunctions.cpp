//===-- HSAILUtilityFunctions.cpp - HSAIL Utility Functions       ---------===//
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
// This file provides the implementations of functions that are declared in the
// HSAILUtilityFUnctions.h file.
//
//===----------------------------------------------------------------------===//
#include "HSAILUtilityFunctions.h"
#include "HSAILBrig.h"
#include "HSAILInstrInfo.h"
#include "HSAILISelLowering.h"
#include "HSAILMachineFunctionInfo.h"
#include "HSAILOpaqueTypes.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/ValueMap.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/CodeGen/PseudoSourceValue.h"
#include "llvm/Support/FormattedStream.h"
#include "llvm/Support/Debug.h"
#include <cstdio>
#include <queue>
#include <list>

using namespace llvm;

namespace llvm {

namespace HSAIL {

uint64_t getNumElementsInHSAILType(Type* type, const DataLayout& dataLayout) {
  switch(type->getTypeID()) {
  case Type::IntegerTyID:
  case Type::PointerTyID:
  case Type::FloatTyID:
  case Type::DoubleTyID:
    return 1;
  case Type::VectorTyID:
    return dataLayout.getTypeAllocSize(type) /
           dataLayout.getTypeAllocSize(type->getVectorElementType());
  case Type::ArrayTyID:
    return type->getArrayNumElements() *
           getNumElementsInHSAILType(type->getArrayElementType(), dataLayout);
  case Type::StructTyID: {
    StructType *st = cast<StructType>(type);
    const StructLayout *layout = dataLayout.getStructLayout(st);
    return layout->getSizeInBytes();
  }
  default: llvm_unreachable("Unhandled type");
  }
  return 0;
}

bool HSAILrequiresArray(Type* type) {
  switch(type->getTypeID()) {
  case Type::VectorTyID:
  case Type::ArrayTyID:
  case Type::StructTyID:
    return true;
  default:
    return false;
  }
}

Brig::BrigType16_t getBrigType(Type* type, const DataLayout &DL, bool Signed) {
  switch (type->getTypeID()) {
  case Type::VoidTyID:
    return Brig::BRIG_TYPE_NONE; // TODO_HSA: FIXME: void
  case Type::FloatTyID:
    return Brig::BRIG_TYPE_F32;
  case Type::DoubleTyID:
    return Brig::BRIG_TYPE_F64;
  case Type::IntegerTyID:
    if (type->isIntegerTy(8)) {
      return Signed ? Brig::BRIG_TYPE_S8 : Brig::BRIG_TYPE_U8;
    } else if (type->isIntegerTy(16)) {
      return Signed ? Brig::BRIG_TYPE_S16 : Brig::BRIG_TYPE_U16;
    } else if (type->isIntegerTy(32)) {
      return Signed ? Brig::BRIG_TYPE_S32 : Brig::BRIG_TYPE_U32;
    } else if (type->isIntegerTy(64)) {
      return Signed ? Brig::BRIG_TYPE_S64 : Brig::BRIG_TYPE_U64;
    } else if (type->isIntegerTy(1)) {
      return Brig::BRIG_TYPE_B1;
    } else {
      type->dump();
      assert(!"Found a case we don't handle!");
    }
    break;
  case Type::PointerTyID: {
    if (OpaqueType OT = GetOpaqueType(type)) {
      if (IsImage(OT)) return Brig::BRIG_TYPE_RWIMG;
      if (OT == Sampler) return Brig::BRIG_TYPE_SAMP;
    }
    unsigned AS = cast<PointerType>(type)->getAddressSpace();
    return DL.getPointerSize(AS) == 8 ? Brig::BRIG_TYPE_U64 : Brig::BRIG_TYPE_U32;
  }
  case Type::StructTyID:
    // Treat struct as array of bytes.
    return Brig::BRIG_TYPE_U8;
  case Type::VectorTyID:
    return getBrigType(type->getScalarType(), DL, Signed);
  case Type::ArrayTyID:
    return getBrigType(cast<ArrayType>(type)->getElementType(), DL, Signed);
  default:
    type->dump();
    assert(!"Found a case we don't handle!");
    break;
  }
  return Brig::BRIG_TYPE_U8;  // FIXME needs a value here for linux release build
}

unsigned HSAILgetAlignTypeQualifier(Type *ty, const DataLayout& DL,
                                    bool isPreferred) {
  unsigned align = 0;

  if (ArrayType *ATy = dyn_cast<ArrayType>(ty))
    ty = ATy->getElementType();

  if (IsImage(ty) || IsSampler(ty))
    return 8;

  align = isPreferred ? DL.getPrefTypeAlignment(ty)
                      : DL.getABITypeAlignment(ty);

  unsigned max_align = (1 << (Brig::BRIG_ALIGNMENT_MAX -
                              Brig::BRIG_ALIGNMENT_1));
  if (align > max_align) align = max_align;

  assert(align && (align & (align - 1)) == 0);

  return align;
}

bool HSAILcommaPrint(int i, raw_ostream &O) {
  O << ":" << i;
  return false;
}

llvm::MachineOperand &getBase(llvm::MachineInstr *MI) {
  int Idx = HSAIL::getNamedOperandIdx(MI->getOpcode(), HSAIL::OpName::address);
  return MI->getOperand(Idx + HSAILADDRESS::BASE);
}

const llvm::MachineOperand &getBase(const llvm::MachineInstr *MI) {
  return getBase(const_cast<llvm::MachineInstr*>(MI));
}

llvm::MachineOperand &getIndex(llvm::MachineInstr *MI) {
  int Idx = HSAIL::getNamedOperandIdx(MI->getOpcode(), HSAIL::OpName::address);
  return MI->getOperand(Idx + HSAILADDRESS::REG);
}

const llvm::MachineOperand &getIndex(const llvm::MachineInstr *MI) {
  return getIndex(const_cast<llvm::MachineInstr*>(MI));
}

llvm::MachineOperand &getOffset(llvm::MachineInstr *MI) {
  int Idx = HSAIL::getNamedOperandIdx(MI->getOpcode(), HSAIL::OpName::address);
  return MI->getOperand(Idx + HSAILADDRESS::OFFSET);
}

const llvm::MachineOperand &getOffset(const llvm::MachineInstr *MI) {
  return getOffset(const_cast<MachineInstr*>(MI));
}

// FIXME: Remove this
llvm::MachineOperand &getBrigType(llvm::MachineInstr *MI) {
  int Idx = HSAIL::getNamedOperandIdx(MI->getOpcode(), HSAIL::OpName::TypeLength);
  assert(Idx != -1);
  return MI->getOperand(Idx);
}

const llvm::MachineOperand &getBrigType(const llvm::MachineInstr *MI)
{
  return getBrigType(const_cast<llvm::MachineInstr*>(MI));
}

// FIXME: Remove this
llvm::MachineOperand &getWidth(llvm::MachineInstr *MI) {
  int Idx = HSAIL::getNamedOperandIdx(MI->getOpcode(), HSAIL::OpName::width);
  assert(Idx != -1);
  return MI->getOperand(Idx);
}

const llvm::MachineOperand &getWidth(const llvm::MachineInstr *MI)
{
  return getWidth(const_cast<llvm::MachineInstr*>(MI));
}

// FIXME: Remove this
llvm::MachineOperand &getLoadModifierMask(llvm::MachineInstr *MI) {
  int Idx = HSAIL::getNamedOperandIdx(MI->getOpcode(), HSAIL::OpName::mask);
  assert(Idx != -1);
  return MI->getOperand(Idx);
}

const llvm::MachineOperand &getLoadModifierMask(const llvm::MachineInstr *MI)
{
  return getLoadModifierMask(const_cast<llvm::MachineInstr*>(MI));
}

bool HSAILisArgInst(const TargetMachine &TM, const llvm::MachineInstr *MI)
{
  unsigned op = MI->getOpcode();
  const TargetInstrInfo *TII = TM.getSubtarget<HSAILSubtarget>().getInstrInfo();
  const MCInstrDesc &MCID = TII->get(op);
  if (!MCID.mayLoad() || !MI->hasOneMemOperand()) return false;
  unsigned as = (*MI->memoperands_begin())->getPointerInfo().getAddrSpace();
  if (as != HSAILAS::KERNARG_ADDRESS && as != HSAILAS::ARG_ADDRESS) return false;
  return true;
}


const char *
HSAILgetTypeName(Type *ptr, const char *symTab,
                 HSAILMachineFunctionInfo *mfi, bool signedType)
{
  switch (ptr->getTypeID()) {
  case Type::StructTyID:
    {
      OpaqueType OT = GetOpaqueType(ptr);

      switch (OT) {
        case NotOpaque:     return "struct";
        case Event:         return "event";
        case Sampler:       return "sampler";
        case I1D:           return "image1d";
        case I1DB:          return "image1d_buffer";
        case I1DA:          return "image1d_array";
        case I2D:           return "image2d";
        case I2DA:          return "image2d_array";
        case I3D:           return "image3d";
        case I2DDepth:      return "image2ddepth";
        case I2DADepth:     return "image2dadepth";
        case Sema:          return "semaphore";
        case C32:           return "counter32";
        case C64:           return "counter64";
        case ReserveId:     return "reserveId";
        case CLKEventT:     return "clk_event_t";
        case QueueT:        return "queue_t";
        case UnknownOpaque: return "opaque";
      }
    }
    case Type::HalfTyID:
      return "half";
    case Type::FloatTyID:
      return "float";
    case Type::DoubleTyID:
      {
        return "double";
      }
    case Type::IntegerTyID:
      {
        LLVMContext& ctx = ptr->getContext();
        if (ptr == Type::getInt8Ty(ctx)) {
          return (signedType) ? "i8" : "u8";
        } else if (ptr == Type::getInt16Ty(ctx)) {
          return (signedType) ? "i16" : "u16";
        } else if (ptr == Type::getInt32Ty(ctx)) {
          return (signedType) ? "i32" : "u32";
        } else if(ptr == Type::getInt64Ty(ctx)) {
          return (signedType) ? "i64" : "u64";
        }
        break;
      }
    default:
      break;
  case Type::ArrayTyID:
      {
        const ArrayType *AT = cast<ArrayType>(ptr);
        ptr = AT->getElementType();
        return HSAILgetTypeName(ptr, symTab, mfi, signedType);
        break;
      }
    case Type::VectorTyID:
      {
        const VectorType *VT = cast<VectorType>(ptr);
        ptr = VT->getElementType();
        return HSAILgetTypeName(ptr, symTab, mfi, signedType);
        break;
      }
    case Type::PointerTyID:
      {
        const PointerType *PT = cast<PointerType>(ptr);
        ptr = PT->getElementType();
        return HSAILgetTypeName(ptr, symTab, mfi, signedType);
        break;
      }
    case Type::FunctionTyID:
      {
        const FunctionType *FT = cast<FunctionType>(ptr);
        ptr = FT->getReturnType();
        return HSAILgetTypeName(ptr, symTab, mfi, signedType);
        break;
      }
  }
  ptr->dump();
  if (mfi) {
#if 0
    mfi->addErrorMsg(amd::CompilerErrorMessage[UNKNOWN_TYPE_NAME]);
#endif
  }
  return "unknown";
}

static bool isKernelFunc(StringRef str) {
  if (str.startswith("__OpenCL_") && str.endswith("_kernel"))
    return true;
  return false;
}

bool isKernelFunc(const Function *F)
{
  if (CallingConv::SPIR_KERNEL == F->getCallingConv())
    return true;

  return isKernelFunc(F->getName());
}

/// \brief Check if a global variable is used in any "real" code.
///
/// We iterate over the entire tree of users, looking for any use in
/// the kernel code. The traversal ignores any use in metadata. There
/// is only one way to use a global variable in metadata --- by using
/// it in a global variable that occurs in the "llvm.metadata"
/// section. (MDNode is not a subclass of llvm::User, and hence they
/// can't occur in the user tree.) The traversal returns early if the
/// user is an instruction.
///
/// Assumption: Instructions do not occur in metadata. Also, we don't
/// worry about dead code so late in the flow.
bool notUsedInKernel(const GlobalVariable *GV)
{
  SmallVector<const User*, 32> worklist; // arbitrary choice of 32

  // We only inspect the users of GV, hence GV itself is never
  // inserted in the worklist.
  worklist.append(GV->user_begin(), GV->user_end());

  while (!worklist.empty()) {
    const User* user = worklist.pop_back_val();

    if (const GlobalValue *GUser = dyn_cast<GlobalValue>(user)) {
      if (std::string("llvm.metadata") == GUser->getSection())
        continue;
    }

    if (isa<Instruction>(user))
      return false;

    worklist.append(user->user_begin(), user->user_end());
  }

  return true;
}

/// \brief Rename a global variable to satisfy HSAIL syntax.
///
/// We simply drop all characters from the name that are disallowed by
/// HSAIL. When the resulting string is applied as a name, it will be
/// automatically modified to resolve conflicts.
bool sanitizeGlobalValueName(GlobalValue *GV)
{
  // Poor man's regexp check.
  static const std::string syntax("abcdefghijklmnopqrstuvwxyz"
          "_"
          "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
          "0123456789");
  static const std::string digit("0123456789");
  static const std::string hsa_replaced("__hsa_replaced_");
  StringRef name = GV->getName();
  SmallString<32> newname;
  size_t p = 0;
  size_t q = 0;
  while (StringRef::npos != q) {
    q = name.find_first_not_of(syntax, p);
    // If q == p, the character at p itself violates the syntax.
    if (q != p)
      // Consume everything before q, not including q (even if q == npos).
      newname += name.slice(p, q);
    // If not found, do not replace.
    if (StringRef::npos == q)
      break;
    // Replace found character with underscore.
    newname += "_";
    // Then we directly move on to the next character: skip q.
    p = q + 1;
  }
  // opt may generate empty names and names started with digit.
  if ((name.empty()) || StringRef::npos != digit.find(name[0]) || !name.equals(newname)) {
    // Add prefix to show that the name was replaced by HSA.
    // LLVM's setName adds seq num in case of name duplicating.
    GV->setName(hsa_replaced + newname.str());
    return true;
  }
  return false;
}

bool isIgnoredGV(const GlobalVariable *GV) {
  unsigned AS = GV->getType()->getAddressSpace();

  if (AS == HSAILAS::PRIVATE_ADDRESS || AS == HSAILAS::GROUP_ADDRESS)
    return true;

  if (GV->hasLocalLinkage() && notUsedInKernel(GV))
    return true;

  StringRef GVname = GV->getName();

  // FIXME: Should be removed
  return GVname.startswith("sgv") ||
    GVname.startswith("fgv") ||
    GVname.startswith("lvgv") ||
    GVname.startswith("pvgv") ||
    // TODO_HSA: suppress emitting annotations as global declarations for
    // now. These are labelled as "llvm.metadata". How should we handle these?
    GVname.startswith("llvm.argtypeconst.annotations") ||
    GVname.startswith("llvm.argtypename.annotations") ||
    GVname.startswith("llvm.constpointer.annotations") ||
    GVname.startswith("llvm.global.annotations") ||
    GVname.startswith("llvm.image.annotations") ||
    GVname.startswith("llvm.readonlypointer.annotations") ||
    GVname.startswith("llvm.restrictpointer.annotations") ||
    GVname.startswith("llvm.signedOrSignedpointee.annotations") ||
    GVname.startswith("llvm.volatilepointer.annotations") ||
    GVname.startswith("llvm.sampler.annotations");
}

/// \brief Check whether the module contains SPIR
///
/// We cannot use metadata such as "opencl.spir.version", or the
/// target triple, because these can come in via the builtins library
/// as well. Instead we rely on the fact that there are no kernels in
/// the builtins library, and hence "opencl.kernels" is absent.
bool isSPIRModule(const Module &M) {
  return M.getNamedMetadata("opencl.kernels");
}

static SDValue generateFenceIntrinsicHelper(SDValue Chain, SDLoc dl,
                unsigned brigMemoryOrder,
                unsigned brigGlobalMemoryScope, 
                unsigned brigGroupMemoryScope, 
                unsigned brigImageMemoryScope, 
                SelectionDAG &CurDAG) 
{
  unsigned fenceOp = HSAILIntrinsic::HSAIL_memfence;
  SmallVector<SDValue, 7> Ops;

  Ops.push_back(Chain);
  Ops.push_back(CurDAG.getTargetConstant(fenceOp, MVT::i64));
  Ops.push_back(CurDAG.getConstant(brigMemoryOrder, MVT::getIntegerVT(32)));
  Ops.push_back(CurDAG.getConstant(brigGlobalMemoryScope, MVT::getIntegerVT(32)));
  Ops.push_back(CurDAG.getConstant(brigGroupMemoryScope, MVT::getIntegerVT(32)));
  Ops.push_back(CurDAG.getConstant(brigImageMemoryScope, MVT::getIntegerVT(32)));
  return CurDAG.getNode(ISD::INTRINSIC_VOID, dl, MVT::Other, Ops);
}


SDValue generateFenceIntrinsic(SDValue Chain, SDLoc dl, unsigned memSeg,
        unsigned brigMemoryOrder, unsigned brigMemoryScope, SelectionDAG &CurDAG) {
  switch(memSeg) {
    case llvm::HSAILAS::GLOBAL_ADDRESS:
        return generateFenceIntrinsicHelper(Chain, dl, brigMemoryOrder, 
          brigMemoryScope, Brig::BRIG_MEMORY_SCOPE_NONE, 
          Brig::BRIG_MEMORY_SCOPE_NONE, CurDAG);

    case llvm::HSAILAS::GROUP_ADDRESS:
        return generateFenceIntrinsicHelper(Chain, dl, brigMemoryOrder, 
            Brig::BRIG_MEMORY_SCOPE_NONE, brigMemoryScope, 
            Brig::BRIG_MEMORY_SCOPE_NONE, CurDAG);

    case llvm::HSAILAS::FLAT_ADDRESS:
        return generateFenceIntrinsicHelper(Chain, dl, brigMemoryOrder, 
            brigMemoryScope, Brig::BRIG_MEMORY_SCOPE_WORKGROUP, 
            Brig::BRIG_MEMORY_SCOPE_NONE, CurDAG);
    default: llvm_unreachable("unexpected memory segment ");
  }
}

} // End namespace HSAIL

} // End namespace llvm
