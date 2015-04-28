//===-- HSAILUtilityFunctions.cpp - HSAIL Utility Functions ---------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
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

uint64_t getNumElementsInHSAILType(Type *type, const DataLayout &dataLayout) {
  switch (type->getTypeID()) {
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
  default:
    llvm_unreachable("Unhandled type");
  }
  return 0;
}

BrigType getBrigType(Type *type, const DataLayout &DL, bool Signed) {
  switch (type->getTypeID()) {
  case Type::VoidTyID:
    return BRIG_TYPE_NONE; // TODO_HSA: FIXME: void
  case Type::FloatTyID:
    return BRIG_TYPE_F32;
  case Type::DoubleTyID:
    return BRIG_TYPE_F64;
  case Type::IntegerTyID:
    if (type->isIntegerTy(8)) {
      return Signed ? BRIG_TYPE_S8 : BRIG_TYPE_U8;
    } else if (type->isIntegerTy(16)) {
      return Signed ? BRIG_TYPE_S16 : BRIG_TYPE_U16;
    } else if (type->isIntegerTy(32)) {
      return Signed ? BRIG_TYPE_S32 : BRIG_TYPE_U32;
    } else if (type->isIntegerTy(64)) {
      return Signed ? BRIG_TYPE_S64 : BRIG_TYPE_U64;
    } else if (type->isIntegerTy(1)) {
      return BRIG_TYPE_B1;
    } else
      llvm_unreachable("Unhandled type");
    break;
  case Type::PointerTyID: {
    if (OpaqueType OT = GetOpaqueType(type)) {
      if (IsImage(OT))
        return BRIG_TYPE_RWIMG;
      if (OT == Sampler)
        return BRIG_TYPE_SAMP;
    }
    unsigned AS = cast<PointerType>(type)->getAddressSpace();
    return DL.getPointerSize(AS) == 8 ? BRIG_TYPE_U64 : BRIG_TYPE_U32;
  }
  case Type::StructTyID:
    // Treat struct as array of bytes.
    return BRIG_TYPE_U8_ARRAY;
  case Type::VectorTyID:
    return static_cast<BrigType>(
        getBrigType(type->getScalarType(), DL, Signed) | BRIG_TYPE_ARRAY);
  case Type::ArrayTyID:
    return static_cast<BrigType>(
        getBrigType(cast<ArrayType>(type)->getElementType(), DL, Signed) |
        BRIG_TYPE_ARRAY);
  default:
    type->dump();
    llvm_unreachable("Unhandled type");
  }
}

Type *analyzeType(Type *Ty, unsigned &NElts, const DataLayout &DL) {
  // Scan through levels of nested arrays until we get to something that can't
  // be expressed as a simple array element.
  if (ArrayType *AT = dyn_cast<ArrayType>(Ty)) {
    Type *EltTy;
    NElts = 1;

    while (AT) {
      NElts *= AT->getNumElements();
      EltTy = AT->getElementType();
      AT = dyn_cast<ArrayType>(EltTy);
    }

    unsigned EltElts = ~0u;

    // We could have arrays of vectors or structs.
    Type *Tmp = analyzeType(EltTy, EltElts, DL);

    // We only need to multiply if this was a nested vector type.
    if (EltElts != 0)
      NElts *= EltElts;

    return Tmp;
  }

  if (VectorType *VT = dyn_cast<VectorType>(Ty)) {
    Type *EltTy = VT->getElementType();

    // We need to correct the number of elements in the case of 3x vectors since
    // in memory they occupy 4 elements.
    NElts = DL.getTypeAllocSize(Ty) / DL.getTypeAllocSize(EltTy);
    assert(NElts >= VT->getNumElements());

    // FIXME: It's not clear what the behavior of these is supposed to be and
    // aren't consistently handled.
    if (EltTy->isIntegerTy(1))
      report_fatal_error("i1 vector initializers not handled");

    return EltTy;
  }

  if (isa<StructType>(Ty)) {
    NElts = DL.getTypeAllocSize(Ty);
    return Type::getInt8Ty(Ty->getContext());
  }

  assert(!Ty->isAggregateType());

  NElts = 0;

  // Arrays of i1 are not supported, and must be replaced with byte sized
  // elements.
  if (Ty->isIntegerTy(1))
    return Type::getInt8Ty(Ty->getContext());

  return Ty;
}

unsigned getAlignTypeQualifier(Type *ty, const DataLayout &DL,
                               bool isPreferred) {
  unsigned align = 0;

  if (ArrayType *ATy = dyn_cast<ArrayType>(ty))
    ty = ATy->getElementType();

  if (IsImage(ty) || IsSampler(ty))
    return 8;

  align =
      isPreferred ? DL.getPrefTypeAlignment(ty) : DL.getABITypeAlignment(ty);

  unsigned max_align = (1 << (BRIG_ALIGNMENT_MAX - BRIG_ALIGNMENT_1));
  if (align > max_align)
    align = max_align;

  assert(align && (align & (align - 1)) == 0);

  return align;
}

const char *getTypeName(Type *ptr, const char *symTab,
                        HSAILMachineFunctionInfo *mfi, bool signedType) {
  switch (ptr->getTypeID()) {
  case Type::StructTyID: {
    OpaqueType OT = GetOpaqueType(ptr);

    switch (OT) {
    case NotOpaque:
      return "struct";
    case Event:
      return "event";
    case Sampler:
      return "sampler";
    case I1D:
      return "image1d";
    case I1DB:
      return "image1d_buffer";
    case I1DA:
      return "image1d_array";
    case I2D:
      return "image2d";
    case I2DA:
      return "image2d_array";
    case I3D:
      return "image3d";
    case I2DDepth:
      return "image2ddepth";
    case I2DADepth:
      return "image2dadepth";
    case Sema:
      return "semaphore";
    case C32:
      return "counter32";
    case C64:
      return "counter64";
    case ReserveId:
      return "reserveId";
    case CLKEventT:
      return "clk_event_t";
    case QueueT:
      return "queue_t";
    case UnknownOpaque:
      return "opaque";
    }
  }
  case Type::HalfTyID:
    return "half";
  case Type::FloatTyID:
    return "float";
  case Type::DoubleTyID: {
    return "double";
  }
  case Type::IntegerTyID: {
    LLVMContext &ctx = ptr->getContext();
    if (ptr == Type::getInt8Ty(ctx)) {
      return (signedType) ? "i8" : "u8";
    } else if (ptr == Type::getInt16Ty(ctx)) {
      return (signedType) ? "i16" : "u16";
    } else if (ptr == Type::getInt32Ty(ctx)) {
      return (signedType) ? "i32" : "u32";
    } else if (ptr == Type::getInt64Ty(ctx)) {
      return (signedType) ? "i64" : "u64";
    }
    break;
  }
  default:
    break;
  case Type::ArrayTyID: {
    const ArrayType *AT = cast<ArrayType>(ptr);
    ptr = AT->getElementType();
    return getTypeName(ptr, symTab, mfi, signedType);
    break;
  }
  case Type::VectorTyID: {
    const VectorType *VT = cast<VectorType>(ptr);
    ptr = VT->getElementType();
    return getTypeName(ptr, symTab, mfi, signedType);
    break;
  }
  case Type::PointerTyID: {
    const PointerType *PT = cast<PointerType>(ptr);
    ptr = PT->getElementType();
    return getTypeName(ptr, symTab, mfi, signedType);
    break;
  }
  case Type::FunctionTyID: {
    const FunctionType *FT = cast<FunctionType>(ptr);
    ptr = FT->getReturnType();
    return getTypeName(ptr, symTab, mfi, signedType);
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

bool isKernelFunc(const Function *F) {
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
bool notUsedInKernel(const GlobalVariable *GV) {
  SmallVector<const User *, 32> worklist; // arbitrary choice of 32

  // We only inspect the users of GV, hence GV itself is never
  // inserted in the worklist.
  worklist.append(GV->user_begin(), GV->user_end());

  while (!worklist.empty()) {
    const User *user = worklist.pop_back_val();

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

bool sanitizedGlobalValueName(StringRef Name, SmallVectorImpl<char> &Out) {
  // Poor man's regexp check.
  static const StringRef Syntax("abcdefghijklmnopqrstuvwxyz"
                                "_."
                                "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                                "0123456789");

  static const StringRef FirstCharSyntax("abcdefghijklmnopqrstuvwxyz"
                                         "_"
                                         "ABCDEFGHIJKLMNOPQRSTUVWXYZ");

  static const StringRef Digits("0123456789");

  SmallString<32> NewName;

  // The second character (after the prefix) of an identifier must must be a
  // letter or underscore.
  if (FirstCharSyntax.find(Name[0]) == StringRef::npos) {
    NewName += '_';
    Name = Name.drop_front(1);
  }

  size_t p = 0;
  size_t q = 0;

  while (q != StringRef::npos) {
    q = Name.find_first_not_of(Syntax, p);
    // If q == p, the character at p itself violates the syntax.
    if (q != p) {
      // Consume everything before q, not including q (even if q == npos).
      NewName += Name.slice(p, q);
    }

    // If not found, do not replace.
    if (q == StringRef::npos)
      break;

    // Replace found character with underscore.
    NewName += '_';

    // Then we directly move on to the next character: skip q.
    p = q + 1;
  }

  // opt may generate empty names and names started with digit.
  if (Name.empty() || Digits.find(Name[0]) != StringRef::npos ||
      !Name.equals(NewName)) {
    // Add prefix to show that the name was replaced by HSA.
    // LLVM's setName adds seq num in case of name duplicating.
    Out.append(NewName.begin(), NewName.end());
    return true;
  }

  return false;
}

/// \brief Rename a global variable to satisfy HSAIL syntax.
///
/// We simply drop all characters from the name that are disallowed by
/// HSAIL. When the resulting string is applied as a name, it will be
/// automatically modified to resolve conflicts.
bool sanitizeGlobalValueName(GlobalValue *GV) {
  SmallString<256> NewName;

  if (sanitizedGlobalValueName(GV->getName(), NewName)) {
    // Add prefix to show that the name was replaced by HSA.
    // LLVM's setName adds seq num in case of name duplicating.
    GV->setName(Twine("__hsa_replaced_") + Twine(NewName));
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
  return GVname.startswith("sgv") || GVname.startswith("fgv") ||
         GVname.startswith("lvgv") || GVname.startswith("pvgv") ||
         // TODO_HSA: suppress emitting annotations as global declarations for
         // now. These are labelled as "llvm.metadata". How should we handle
         // these?
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

} // End namespace HSAIL

} // End namespace llvm
