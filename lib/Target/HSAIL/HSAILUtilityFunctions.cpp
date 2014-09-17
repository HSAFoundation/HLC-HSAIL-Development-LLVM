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
#include "HSAILMachineFunctionInfo.h"
#include "HSAILISelLowering.h"
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

// Bring in the implementation for InstrMappings
#define GET_INSTRMAP_INFO
#include "HSAILGenInstrInfo.inc"
#undef GET_INSTRMAP_INFO

using namespace llvm;

namespace llvm {

namespace HSAIL {

int64_t HSAIL_GET_SCALAR_SIZE(Type *A) {
  return A->getScalarSizeInBits();
}

void HSAILprintSDNode(const SDNode *N) {
  printf("Opcode: %u isTargetOpcode: %d isMachineOpcode: %d\n",
         N->getOpcode(), N->isTargetOpcode(), N->isMachineOpcode());
  printf("Empty: %d OneUse: %d Size: %d NodeID: %d\n",
         N->use_empty(), N->hasOneUse(), (int)N->use_size(), N->getNodeId());
  for (unsigned int i = 0; i < N->getNumOperands(); ++i) {
    printf("OperandNum: %u ValueCount: %u ValueType: %d\n",
           i, N->getNumValues(), N->getValueType(0) .getSimpleVT().SimpleTy);
    HSAILprintSDValue(N->getOperand(i), 0);
  }
}

void HSAILprintSDValue(const SDValue &Op, int level) {
  printf("\nOp: %p OpCode: %u NumOperands: %u ", &Op, Op.getOpcode(),
         Op.getNumOperands());
  printf("IsTarget: %d IsMachine: %d ", Op.isTargetOpcode(),
         Op.isMachineOpcode());
  if (Op.isMachineOpcode()) {
    printf("MachineOpcode: %u\n", Op.getMachineOpcode());
  } else {
    printf("\n");
  }
  EVT vt = Op.getValueType();
  printf("ValueType: %d \n", vt.getSimpleVT().SimpleTy);
  printf("UseEmpty: %d OneUse: %d\n", Op.use_empty(), Op.hasOneUse());
  if (level) {
    printf("Children for %d:\n", level);
    for (unsigned int i = 0; i < Op.getNumOperands(); ++i) {
      printf("Child %d->%u:", level, i);
      HSAILprintSDValue(Op.getOperand(i), level - 1);
    }
  }
}

size_t HSAILgetTypeSize(const Type *T, bool dereferencePtr) {
  size_t size = 0;
  if (!T) {
    return size;
  }
  switch (T->getTypeID()) {
  case Type::X86_FP80TyID:
  case Type::FP128TyID:
  case Type::PPC_FP128TyID:
  case Type::LabelTyID:
    assert(0 && "These types are not supported by this backend");
  default:
  case Type::FloatTyID:
  case Type::DoubleTyID:
    size = T->getPrimitiveSizeInBits() >> 3;
    break;
  case Type::PointerTyID:
    size = HSAILgetTypeSize(dyn_cast<PointerType>(T), dereferencePtr);
    break;
  case Type::IntegerTyID:
    size = HSAILgetTypeSize(dyn_cast<IntegerType>(T), dereferencePtr);
    break;
  case Type::StructTyID:
    size = HSAILgetTypeSize(dyn_cast<StructType>(T), dereferencePtr);
    break;
  case Type::ArrayTyID:
    size = HSAILgetTypeSize(dyn_cast<ArrayType>(T), dereferencePtr);
    break;
  case Type::FunctionTyID:
    size = HSAILgetTypeSize(dyn_cast<FunctionType>(T), dereferencePtr);
    break;
  case Type::VectorTyID:
    size = HSAILgetTypeSize(dyn_cast<VectorType>(T), dereferencePtr);
    break;
  };
  return size;
}

size_t HSAILgetTypeSize(const StructType *ST, bool dereferencePtr) {
  size_t size = 0;
  if (!ST) {
    return size;
  }
  Type *curType;
  StructType::element_iterator eib;
  StructType::element_iterator eie;
  for (eib = ST->element_begin(), eie = ST->element_end(); eib != eie; ++eib) {
    curType = *eib;
    size += HSAILgetTypeSize(curType, false);
  }
  return size;
}

size_t HSAILgetTypeSize(const IntegerType *IT, bool dereferencePtr) {
  return IT ? (IT->getBitWidth() >> 3) : 0;
}

size_t HSAILgetTypeSize(const FunctionType *FT, bool dereferencePtr) {
    assert(0 && "Should not be able to calculate the size of an function type");
    return 0;
}

size_t HSAILgetTypeSize(const ArrayType *AT, bool dereferencePtr) {
  return (size_t)(AT ? (HSAILgetTypeSize(AT->getElementType(),
                                    dereferencePtr) * AT->getNumElements())
                     : 0);
}

size_t HSAILgetTypeSize(const VectorType *VT, bool dereferencePtr) {
  if (!VT) return 0;
  if (VT->getNumElements() != 3) {
    return VT->getBitWidth() >> 3;
  } 
  return HSAILgetTypeSize(VT->getElementType(), dereferencePtr) * 4;
}

size_t HSAILgetTypeSize(const PointerType *PT, bool dereferencePtr) {
  if (!PT) {
    return 0;
  }
  Type *CT = PT->getElementType();
  if (CT->getTypeID() == Type::StructTyID &&
      PT->getAddressSpace() == HSAILAS::PRIVATE_ADDRESS) {
    return HSAILgetTypeSize(dyn_cast<StructType>(CT));
  } else if (dereferencePtr) {
    size_t size = 0;
    for (size_t x = 0, y = PT->getNumContainedTypes(); x < y; ++x) {
      size += HSAILgetTypeSize(PT->getContainedType(x), dereferencePtr);
    }
    return size;
  } else {
    return HSAILDeviceInfo::is64bit?8:4;
  }
}

size_t HSAILgetTypeSize(const OpaqueType *OT, bool dereferencePtr) {
  //assert(0 && "Should not be able to calculate the size of an opaque type");
  return 4;
}

size_t HSAILgetNumElements(Type * const T) {
  size_t size = 0;
  if (!T) {
    return size;
  }
  switch (T->getTypeID()) {
  case Type::X86_FP80TyID:
  case Type::FP128TyID:
  case Type::PPC_FP128TyID:
  case Type::LabelTyID:
    assert(0 && "These types are not supported by this backend");
  default:
  case Type::FloatTyID:
  case Type::DoubleTyID:
    size = 1;
    break;
  case Type::PointerTyID:
    size = HSAILgetNumElements(dyn_cast<PointerType>(T));
    break;
  case Type::IntegerTyID:
    size = HSAILgetNumElements(dyn_cast<IntegerType>(T));
    break;
  case Type::StructTyID:
    size = HSAILgetNumElements(dyn_cast<StructType>(T));
    break;
  case Type::ArrayTyID:
    size = HSAILgetNumElements(dyn_cast<ArrayType>(T));
    break;
  case Type::FunctionTyID:
    size = HSAILgetNumElements(dyn_cast<FunctionType>(T));
    break;
  case Type::VectorTyID:
    size = HSAILgetNumElements(dyn_cast<VectorType>(T));
    break;
  };
  return size;
}

size_t HSAILgetNumElements(StructType * const ST) {
  size_t size = 0;
  if (!ST) {
    return size;
  }
  Type *curType;
  StructType::element_iterator eib;
  StructType::element_iterator eie;
  for (eib = ST->element_begin(), eie = ST->element_end();
       eib != eie; ++eib) {
    curType = *eib;
    size += HSAILgetNumElements(curType);
  }
  return size;
}

size_t HSAILgetNumElements(IntegerType * const IT) {
  return (!IT) ? 0 : 1;
}

size_t HSAILgetNumElements(FunctionType * const FT) {
  assert(0 && "Should not be able to calculate the number of "
         "elements of a function type");
  return 0;
}

size_t HSAILgetNumElements(ArrayType * const AT) {
  return (!AT) ? 0
               :  (size_t)(HSAILgetNumElements(AT->getElementType()) *
                           AT->getNumElements());
}

size_t HSAILgetNumElements(VectorType * const VT) {
  return (!VT) ? 0
               : VT->getNumElements() * HSAILgetNumElements(VT->getElementType());
}

size_t HSAILgetNumElements(PointerType * const PT) {
  size_t size = 0;
  if (!PT) {
    return size;
  }
  for (size_t x = 0, y = PT->getNumContainedTypes(); x < y; ++x) {
    size += HSAILgetNumElements(PT->getContainedType(x));
  }
  return size;
}

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

Brig::BrigType16_t HSAILgetBrigType(Type* type, bool is64Bit, bool Signed) {
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
  case Type::PointerTyID:
    if (OpaqueType OT = GetOpaqueType(type)) {
      if (IsImage(OT)) return Brig::BRIG_TYPE_RWIMG;
      if (OT == Sampler) return Brig::BRIG_TYPE_SAMP;
    }
    return is64Bit ? Brig::BRIG_TYPE_U64 : Brig::BRIG_TYPE_U32;
  case Type::StructTyID:
    // Treat struct as array of bytes.
    return Brig::BRIG_TYPE_U8;
  case Type::VectorTyID:
    return HSAILgetBrigType(type->getScalarType(), is64Bit, Signed);
  case Type::ArrayTyID:
    return HSAILgetBrigType(dyn_cast<ArrayType>(type)->getElementType(),
                            is64Bit, Signed);
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

const Value *HSAILgetBasePointerValue(const Value *V)
{
  if (!V) {
    return NULL;
  }
  const Value *ret = NULL;
  ValueMap<const Value *, bool> ValueBitMap;
  std::queue<const Value *, std::list<const Value *> > ValueQueue;
  ValueQueue.push(V);
  while (!ValueQueue.empty()) {
    V = ValueQueue.front();
    if (ValueBitMap.find(V) == ValueBitMap.end()) {
      ValueBitMap[V] = true;
      if (dyn_cast<Argument>(V) && dyn_cast<PointerType>(V->getType())) {
        ret = V;
        break;
      } else if (dyn_cast<GlobalVariable>(V)) {
        ret = V;
        break;
      } else if (dyn_cast<Constant>(V)) {
        const ConstantExpr *CE = dyn_cast<ConstantExpr>(V);
        if (CE) {
          ValueQueue.push(CE->getOperand(0));
        }
      } else if (const AllocaInst *AI = dyn_cast<AllocaInst>(V)) {
        ret = AI;
        break;
      } else if (const Instruction *I = dyn_cast<Instruction>(V)) {
        uint32_t numOps = I->getNumOperands();
        for (uint32_t x = 0; x < numOps; ++x) {
          ValueQueue.push(I->getOperand(x));
        }
      } else {
        // assert(0 && "Found a Value that we didn't know how to handle!");
      }
    }
    ValueQueue.pop();
  }
  return ret;
}

const Value *HSAILgetBasePointerValue(const MachineInstr *MI) {
  const Value *moVal = NULL;
  if (!MI->memoperands_empty()) {
    const MachineMemOperand *memOp = (*MI->memoperands_begin());
    moVal = memOp ? memOp->getValue() : NULL;
    moVal = HSAILgetBasePointerValue(moVal);
  }
  return moVal;
}

bool HSAILcommaPrint(int i, raw_ostream &O) {
  O << ":" << i;
  return false;
}

bool hasAddress(const llvm::MachineInstr *MI)
{
  return MI->getDesc().TSFlags & (1ULL << llvm::HSAILTSFLAGS::HAS_ADDRESS);
}

int addressOpNum(const llvm::MachineInstr *MI)
{
  return ((MI->getDesc().TSFlags & (1ULL << HSAILTSFLAGS::ADDRESS_OP_NUM0)) +
          (MI->getDesc().TSFlags & (1ULL << HSAILTSFLAGS::ADDRESS_OP_NUM1)) +
          (MI->getDesc().TSFlags & (1ULL << HSAILTSFLAGS::ADDRESS_OP_NUM2))) >> 
            HSAILTSFLAGS::ADDRESS_OP_NUM0;
}

llvm::MachineOperand &getBase(llvm::MachineInstr *MI)
{
  assert(hasAddress(MI));
  return MI->getOperand(addressOpNum(MI) + HSAILADDRESS::BASE);
}

const llvm::MachineOperand &getBase(const llvm::MachineInstr *MI)
{
  return getBase(const_cast<llvm::MachineInstr*>(MI));
}

llvm::MachineOperand &getIndex(llvm::MachineInstr *MI)
{
  assert(hasAddress(MI));
  return MI->getOperand(addressOpNum(MI) + HSAILADDRESS::REG);
}

const llvm::MachineOperand &getIndex(const llvm::MachineInstr *MI)
{
  return getIndex(const_cast<llvm::MachineInstr*>(MI));
}

llvm::MachineOperand &getOffset(llvm::MachineInstr *MI)
{
  assert(hasAddress(MI) && MI->getNumOperands() >= HSAILADDRESS::ADDRESS_NUM_OPS);
  return MI->getOperand(addressOpNum(MI) + HSAILADDRESS::OFFSET);
}

const llvm::MachineOperand &getOffset(const llvm::MachineInstr *MI)
{
  return getOffset(const_cast<MachineInstr*>(MI));
}

llvm::MachineOperand &getBrigType(llvm::MachineInstr *MI)
{
  assert(hasAddress(MI) && (MI->mayLoad() || MI->mayStore()) &&
         MI->getNumOperands() > HSAILADDRESS::ADDRESS_NUM_OPS);
  return MI->getOperand(addressOpNum(MI) + HSAILADDRESS::ADDRESS_NUM_OPS);
}

const llvm::MachineOperand &getBrigType(const llvm::MachineInstr *MI)
{
  return getBrigType(const_cast<llvm::MachineInstr*>(MI));
}

llvm::MachineOperand &getWidth(llvm::MachineInstr *MI)
{
  assert(hasAddress(MI) && MI->mayLoad() &&
         MI->getNumOperands() > HSAILADDRESS::ADDRESS_NUM_OPS + 1);
  return MI->getOperand(addressOpNum(MI) + HSAILADDRESS::ADDRESS_NUM_OPS + 1);
}

const llvm::MachineOperand &getWidth(const llvm::MachineInstr *MI)
{
  return getWidth(const_cast<llvm::MachineInstr*>(MI));
}

llvm::MachineOperand &getLoadConstQual(llvm::MachineInstr *MI)
{
  assert(hasAddress(MI) && MI->mayLoad() &&
         MI->getNumOperands() > HSAILADDRESS::ADDRESS_NUM_OPS + 2);
  return MI->getOperand(addressOpNum(MI) + HSAILADDRESS::ADDRESS_NUM_OPS + 2);
}

const llvm::MachineOperand &getLoadConstQual(const llvm::MachineInstr *MI)
{
  return getLoadConstQual(const_cast<llvm::MachineInstr*>(MI));
}

unsigned getAddrSpace(const llvm::MachineInstr *MI)
{
  assert(MI->hasOneMemOperand());\
  const MachineMemOperand &MMO = **MI->memoperands_begin();
  const MachinePointerInfo &MPI = MMO.getPointerInfo();
  unsigned as = MPI.getAddrSpace();
  if (as != HSAILAS::PRIVATE_ADDRESS)
    return as;

  const MachineOperand &Base = getBase(MI);
  bool isFI = false;
  int FrameIndex;
  if (Base.isFI()) {
    FrameIndex = Base.getIndex();
    isFI = true;
  } else if (Base.isImm() && MPI.V) {
    if (const FixedStackPseudoSourceValue* FSV =
          dyn_cast<FixedStackPseudoSourceValue>(MMO.getPseudoValue())) {
      FrameIndex = FSV->getFrameIndex();
      isFI = true;
    }
  }

  if (isFI) {
    const MachineFrameInfo *MFI = MI->getParent()->getParent()->getFrameInfo();
    if (MFI->isSpillSlotObjectIndex(FrameIndex))
      return HSAILAS::SPILL_ADDRESS;
  }
  return as;
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

bool isIgnoredGV(const GlobalVariable *GV)
{
  StringRef GVname = GV->getName();
  if (GVname.startswith("sgv")
      || GVname.startswith("fgv")
      || GVname.startswith("lvgv")
      || GVname.startswith("pvgv")
      // TODO_HSA: suppress emitting annotations as global declarations for
      // now. These are labelled as "llvm.metadata". How should we handle these?
      || GVname.startswith("llvm.argtypeconst.annotations")
      || GVname.startswith("llvm.argtypename.annotations")
      || GVname.startswith("llvm.constpointer.annotations")
      || GVname.startswith("llvm.global.annotations")
      || GVname.startswith("llvm.image.annotations")
      || GVname.startswith("llvm.readonlypointer.annotations")
      || GVname.startswith("llvm.restrictpointer.annotations")
      || GVname.startswith("llvm.signedOrSignedpointee.annotations")
      || GVname.startswith("llvm.volatilepointer.annotations")
      || GVname.startswith("llvm.sampler.annotations")
      || (GV->hasLocalLinkage() && notUsedInKernel(GV))
      ||  (GV->getType()->getAddressSpace() == HSAILAS::PRIVATE_ADDRESS)
      ||  (GV->getType()->getAddressSpace() == HSAILAS::GROUP_ADDRESS)
      ) {
    return true;
  }
  return false;
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

namespace {
  // This must match the declarations in HSAILAtomics.td
  enum AtomicNumOps {
    ATOMIC_UNARY_NUM_OPS = 8,
    ATOMIC_BINARY_NUM_OPS = 9,
    ATOMIC_TERNARY_NUM_OPS = 10
  };
}

bool isUnaryAtomicOp(const MachineInstr *MI)
{
  if (!HSAIL::isAtomicOp(MI)) return false;

  const MCInstrDesc &D = MI->getDesc();
  return ATOMIC_UNARY_NUM_OPS == (D.getNumOperands() - D.getNumDefs());
}

bool isBinaryAtomicOp(const MachineInstr *MI)
{
  if (!HSAIL::isAtomicOp(MI)) return false;

  const MCInstrDesc &D = MI->getDesc();
  return ATOMIC_BINARY_NUM_OPS == (D.getNumOperands() - D.getNumDefs());
}

bool isTernaryAtomicOp(const MachineInstr *MI)
{
  if (!HSAIL::isAtomicOp(MI)) return false;

  const MCInstrDesc &D = MI->getDesc();
  return ATOMIC_TERNARY_NUM_OPS == (D.getNumOperands() - D.getNumDefs());
}

bool isRetAtomicOp(const MachineInstr *MI)
{
  return isAtomicOp(MI) && MI->getDesc().getNumDefs() == 1;
}

bool isNoretAtomicOp(const MachineInstr *MI)
{
  return isAtomicOp(MI) && MI->getDesc().getNumDefs() == 0;
}

int getVectorLdStOpcode(uint16_t Opcode, unsigned vsize) {
  // HSAIL::vec_size enum is generated from instruction mappings and defined in
  // HSAILGenInstrInfo.inc. It starts with vec_size_1 value which is equal to
  // zero, so we need to subtract one from size.
  return HSAIL::getLdStVectorOpcode(Opcode, HSAIL::vec_size(vsize - 1));
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
