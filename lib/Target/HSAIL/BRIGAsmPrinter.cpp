#include "BRIGAsmPrinter.h"
#include "BRIGDwarfDebug.h"
#include "MCTargetDesc/BRIGDwarfStreamer.h"
#include "HSAILKernelManager.h"
#include "HSAILMachineFunctionInfo.h"
#include "HSAILOpaqueTypes.h"
#include "HSAILTargetMachine.h"
#include "HSAILLLVMVersion.h"
#include "HSAILUtilityFunctions.h"
#include "llvm/IR/Argument.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"
#include "llvm/ADT/APFloat.h"
#include "llvm/ADT/APInt.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/ADT/VariadicFunction.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/CodeGen/MachineConstantPool.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/MC/MCObjectStreamer.h"
#include "llvm/MC/MCAssembler.h"
#include "llvm/MC/MCObjectWriter.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/FormattedStream.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/IR/Mangler.h"
#include "../lib/CodeGen/AsmPrinter/DwarfDebug.h"
#include <sstream>
#include <iostream>
#include <fstream>

#include "LibHSAILAdapters.h"
#include "libHSAIL/HSAILConvertors.h"
#include "libHSAIL/HSAILValidator.h"
#include "libHSAIL/HSAILBrigObjectFile.h"
#include "libHSAIL/HSAILDisassembler.h"
#include "libHSAIL/HSAILUtilities.h"
#include "libHSAIL/HSAILDump.h"
#include "libHSAIL/HSAILFloats.h"

#include <memory>

using namespace llvm;
using std::string;

#include "HSAILGenBrigWriter.inc"
#define GET_LLVM_INTRINSIC_FOR_GCC_BUILTIN
#include "HSAILGenIntrinsics.inc"
#undef GET_LLVM_INTRINSIC_FOR_GCC_BUILTIN

namespace llvm {
  extern bool EnableExperimentalFeatures;
  extern bool EnableUniformOperations;
  inline std::ostream& operator<<(std::ostream& s, StringRef arg) {
    s.write(arg.data(), arg.size()); return s;
  }
}

static cl::opt<std::string> DebugInfoFilename("odebug",
  cl::desc("Debug Info filename"), cl::value_desc("filename"), cl::init(""));

static cl::opt<std::string> DumpOnFailFilename("dumpOnFail",
  cl::desc("Filename for the BRIG container dump if validation failed"),
  cl::value_desc("filename"), cl::init(""));

static cl::opt<bool>DisableValidator("disable-validator",
  cl::desc("Disable validation of the BRIG container"),
  cl::init(false), cl::Hidden);

static cl::opt<bool> PrintBeforeBRIG("print-before-brig",
  llvm::cl::desc("Print LLVM IR just before emitting BRIG"), cl::Hidden);


unsigned MAX(unsigned a, unsigned b) {
  return a > b ? a: b;
}

unsigned MAX(unsigned a, unsigned b, unsigned c) {
  return (a > b) ? ( (a > c ) ? a : c ) : (b > c) ? b : c;
}

namespace HSAIL_ATOMIC_OPS {
  enum {
    OPCODE_INDEX = 0,
    SEGMENT_INDEX = 1,
    ORDER_INDEX = 2,
    SCOPE_INDEX = 3
  };
}

namespace HSAIL_MEMFENCE {
  enum {
    MEMORY_ORDER_INDEX = 0,
    GLOBAL_SCOPE_INDEX = 1,
    GROUP_SCOPE_INDEX = 2,
    IMAGE_SCOPE_INDEX = 3
  };
}

Brig::BrigAtomicOperation getParametrizedAtomicOpcode(
  const llvm::MachineInstr *MI) {

  assert(HSAIL::isParametrizedAtomicOp(MI->getOpcode()));

  int offset = 0;

  //Ret versions have destination operand at 0 index, so offset parameters index by 1
  if (HSAIL::isParametrizedRetAtomicOp(MI->getOpcode()))
    offset = 1;

  llvm::MachineOperand opc = const_cast<llvm::MachineInstr*>(MI)->getOperand(
                                        HSAIL_ATOMIC_OPS::OPCODE_INDEX+offset);
  assert(opc.isImm());
  int val = opc.getImm();
  assert(val >= Brig::BRIG_ATOMIC_ADD && val <= Brig::BRIG_ATOMIC_XOR);
  return (Brig::BrigAtomicOperation)val;
}

Brig::BrigSegment getParametrizedAtomicSegment(const llvm::MachineInstr *MI) {
  assert(HSAIL::isParametrizedAtomicOp(MI->getOpcode()));

  int offset = 0;

  //Ret versions have destination operand at 0 index, so offset parameters index by 1
  if (HSAIL::isParametrizedRetAtomicOp(MI->getOpcode()))
    offset = 1;

  llvm::MachineOperand seg = const_cast<llvm::MachineInstr*>(MI)->getOperand(
                                        HSAIL_ATOMIC_OPS::SEGMENT_INDEX+offset);
  assert(seg.isImm());
  int val = seg.getImm();
  assert(val > 0 && val < Brig::BRIG_SEGMENT_EXTSPACE0);
  return (Brig::BrigSegment)val;
}

Brig::BrigMemoryOrder getParametrizedAtomicOrder(const llvm::MachineInstr *MI) {
  assert(HSAIL::isParametrizedAtomicOp(MI->getOpcode()));

  int offset = 0;

  //Ret versions have destination operand at 0 index, so offset parameters index by 1
  if (HSAIL::isParametrizedRetAtomicOp(MI->getOpcode()))
    offset = 1;

  llvm::MachineOperand ord = const_cast<llvm::MachineInstr*>(MI)->getOperand(
                                        HSAIL_ATOMIC_OPS::ORDER_INDEX+offset);
  assert(ord.isImm());
  int val = ord.getImm();
  assert(val > 0 && val <= Brig::BRIG_MEMORY_ORDER_SC_ACQUIRE_RELEASE);
  return (Brig::BrigMemoryOrder)val;
}

Brig::BrigMemoryScope getParametrizedAtomicScope(const llvm::MachineInstr *MI) {
  assert(HSAIL::isParametrizedAtomicOp(MI->getOpcode()));

  int offset = 0;

  //Ret versions have destination operand at 0 index, so offset parameters index by 1
  if (HSAIL::isParametrizedRetAtomicOp(MI->getOpcode()))
    offset = 1;

  llvm::MachineOperand scp = const_cast<llvm::MachineInstr*>(MI)->getOperand(
                                        HSAIL_ATOMIC_OPS::SCOPE_INDEX+offset);
  assert(scp.isImm());
  int val = scp.getImm();
  assert(val > 0 && val <= Brig::BRIG_MEMORY_SCOPE_SYSTEM);
  return (Brig::BrigMemoryScope)val;
}

Brig::BrigTypeX getParametrizedAtomicBrigType(int opcode) {
  switch (opcode) {
    default:
      assert(!"Invalid atomic opcode");
      return Brig::BRIG_TYPE_INVALID;

    case llvm::HSAIL::atomic_unary_b32:
    case llvm::HSAIL::atomic_binary_b32_i:
    case llvm::HSAIL::atomic_binary_b32_r:
    case llvm::HSAIL::atomic_binary_b32_i_noret:
    case llvm::HSAIL::atomic_binary_b32_r_noret:
    case llvm::HSAIL::atomic_ternary_b32_ii:
    case llvm::HSAIL::atomic_ternary_b32_ir:
    case llvm::HSAIL::atomic_ternary_b32_ri:
    case llvm::HSAIL::atomic_ternary_b32_rr:
    case llvm::HSAIL::atomic_ternary_b32_ii_noret:
    case llvm::HSAIL::atomic_ternary_b32_ir_noret:
    case llvm::HSAIL::atomic_ternary_b32_ri_noret:
    case llvm::HSAIL::atomic_ternary_b32_rr_noret:
      return Brig::BRIG_TYPE_B32;

    case llvm::HSAIL::atomic_binary_s32_i:
    case llvm::HSAIL::atomic_binary_s32_r:
    case llvm::HSAIL::atomic_binary_s32_i_noret:
    case llvm::HSAIL::atomic_binary_s32_r_noret:
      return Brig::BRIG_TYPE_S32;

    case llvm::HSAIL::atomic_binary_u32_i:
    case llvm::HSAIL::atomic_binary_u32_r:
    case llvm::HSAIL::atomic_binary_u32_i_noret:
    case llvm::HSAIL::atomic_binary_u32_r_noret:
      return Brig::BRIG_TYPE_U32;

    case llvm::HSAIL::atomic_unary_b64:
    case llvm::HSAIL::atomic_binary_b64_i:
    case llvm::HSAIL::atomic_binary_b64_r:
    case llvm::HSAIL::atomic_binary_b64_i_noret:
    case llvm::HSAIL::atomic_binary_b64_r_noret:
    case llvm::HSAIL::atomic_ternary_b64_ii:
    case llvm::HSAIL::atomic_ternary_b64_ir:
    case llvm::HSAIL::atomic_ternary_b64_ri:
    case llvm::HSAIL::atomic_ternary_b64_rr:
    case llvm::HSAIL::atomic_ternary_b64_ii_noret:
    case llvm::HSAIL::atomic_ternary_b64_ir_noret:
    case llvm::HSAIL::atomic_ternary_b64_ri_noret:
    case llvm::HSAIL::atomic_ternary_b64_rr_noret:
      return Brig::BRIG_TYPE_B64;

    case llvm::HSAIL::atomic_binary_s64_i:
    case llvm::HSAIL::atomic_binary_s64_r:
    case llvm::HSAIL::atomic_binary_s64_i_noret:
    case llvm::HSAIL::atomic_binary_s64_r_noret:
      return Brig::BRIG_TYPE_S64;

    case llvm::HSAIL::atomic_binary_u64_i:
    case llvm::HSAIL::atomic_binary_u64_r:
    case llvm::HSAIL::atomic_binary_u64_i_noret:
    case llvm::HSAIL::atomic_binary_u64_r_noret:
      return Brig::BRIG_TYPE_U64;
  }

  return Brig::BRIG_TYPE_INVALID;
}

class LLVM_LIBRARY_VISIBILITY StoreInitializer {
  Brig::BrigType16_t       m_type;
  BRIGAsmPrinter&          m_asmPrinter;
  unsigned                 m_reqNumZeroes;
  HSAIL_ASM::ArbitraryData m_data;

  template <Brig::BrigTypeX BrigTypeId>
  void pushValue(typename HSAIL_ASM::BrigType<BrigTypeId>::CType value);

  template <Brig::BrigTypeX BrigTypeId>
  void pushValueImpl(typename HSAIL_ASM::BrigType<BrigTypeId>::CType value);

  void initVarWithAddress(const Value *V, const std::string Var,
                          const APInt& Offset);

public:
  StoreInitializer(Brig::BrigType16_t type, BRIGAsmPrinter& asmPrinter)
      : m_type(type)
      , m_asmPrinter(asmPrinter)
      , m_reqNumZeroes(0) {}

  void append(const Constant* CV, const std::string Var);

  HSAIL_ASM::SRef toSRef() const { return m_data.toSRef(); }

  size_t elementCount() const {
    return m_data.numBytes() / HSAIL_ASM::getBrigTypeNumBytes(m_type);
  }

  size_t dataSizeInBytes() const {
    return m_data.numBytes();
  }

};

template <Brig::BrigTypeX BrigTypeId> void StoreInitializer::pushValue(
  typename HSAIL_ASM::BrigType<BrigTypeId>::CType value) {

  using namespace Brig;
  // Need to check whether BrigTypeId matches initializer type
  if (m_type == HSAIL_ASM::BrigType<BrigTypeId>::asBitType::value) {
    pushValueImpl<BrigTypeId>(value);
    return;
  }

  assert(m_type == BRIG_TYPE_B8); // struct case
  const uint8_t (&src)[ sizeof value ] =
    *reinterpret_cast<const uint8_t (*)[ sizeof value ]>(&value);

  for (unsigned int i=0; i<sizeof value; ++i) {
    pushValueImpl<BRIG_TYPE_U8>(src[i]);
  }
}

template <Brig::BrigTypeX BrigTypeId> void StoreInitializer::pushValueImpl(
  typename HSAIL_ASM::BrigType<BrigTypeId>::CType value) {

  assert(m_type == HSAIL_ASM::BrigType<BrigTypeId>::asBitType::value);
  typedef typename HSAIL_ASM::BrigType<BrigTypeId>::CType CType;
  if (m_reqNumZeroes > 0) {
    for (unsigned i = m_reqNumZeroes; i > 0; --i) {
      m_data.push_back(CType());
    }
    m_reqNumZeroes = 0;
  }
  m_data.push_back(value);
}

uint64_t getNumElementsInHSAILType(Type* type, const DataLayout& dataLayout);

void StoreInitializer::initVarWithAddress(const Value *V, const std::string Var,
                                          const APInt& Offset) {
  assert(V->hasName());
  std::stringstream initstr;
  initstr << "initvarwithaddress:" << Var << ":" << dataSizeInBytes() <<
    ":" << HSAIL_ASM::getBrigTypeNumBytes(m_type) << ":" <<
    BRIGAsmPrinter::getSymbolPrefix(*dyn_cast<GlobalVariable>(V)) <<
    V->getName().data() << ":" << Offset.toString(10, false);
  HSAIL_ASM::DirectivePragma pgm = m_asmPrinter.brigantine.append<HSAIL_ASM::DirectivePragma>();
  HSAIL_ASM::ItemList opnds;
  opnds.push_back(m_asmPrinter.brigantine.createOperandString(initstr.str()));
  pgm.operands() = opnds;
  (m_asmPrinter.getSubtarget().is64Bit()) ?
    pushValue<Brig::BRIG_TYPE_B64>(0) : pushValue<Brig::BRIG_TYPE_B32>(0);
}

void StoreInitializer::append(const Constant *CV, const std::string Var) {
  using namespace Brig;

  switch(CV->getValueID() ) {
  case Value::ConstantArrayVal: { // recursive type
    const ConstantArray *CA =  cast<ConstantArray>(CV);
    for (unsigned i = 0, e = CA->getNumOperands(); i < e; ++i) {
      append(cast<Constant>(CA->getOperand(i)), Var);
    }
    break;
  }
  case Value::ConstantDataArrayVal: {
    const ConstantDataArray *CVE = cast<ConstantDataArray>(CV);
    for (unsigned i = 0, e = CVE->getNumElements(); i < e; ++i) {
      append(cast<Constant>(CVE->getElementAsConstant(i)), Var);
    }
    break;
  }
  case Value::ConstantStructVal: { // recursive type
    const ConstantStruct * s = cast<ConstantStruct>(CV);
    const StructLayout *layout = m_asmPrinter.getDataLayout()
                                 .getStructLayout(s->getType());
    uint64_t const initStartOffset = m_data.numBytes();
    for (unsigned i = 0, e = s->getNumOperands(); i < e; ++i) {
      append(cast<Constant>(s->getOperand(i)), Var);
      // Match structure layout by padding with zeroes
      uint64_t const nextElemOffset = (i+1) < e ?
                                      layout->getElementOffset(i+1) :
                                      layout->getSizeInBytes();
      uint64_t const structInitSize = m_data.numBytes() - initStartOffset;
      assert(nextElemOffset >= structInitSize);
      m_reqNumZeroes = nextElemOffset - structInitSize;
      if (m_reqNumZeroes) {
        m_reqNumZeroes--;
        pushValue<BRIG_TYPE_U8>(0);
      }
    }
    break;
  }
  case Value::ConstantVectorVal: { // almost leaf type
    const ConstantVector *CVE = cast<ConstantVector>(CV);
    for (unsigned i = 0, e = CVE->getType()->getNumElements(); i < e; ++i) {
      append(cast<Constant>(CVE->getOperand(i)), Var);
    }
    break;
  }
  case Value::ConstantDataVectorVal: {
    const ConstantDataVector *CVE = cast<ConstantDataVector>(CV);
    for (unsigned i = 0, e = CVE->getNumElements(); i < e; ++i) {
      append(cast<Constant>(CVE->getElementAsConstant(i)), Var);
    }
    break;
  }
  case Value::ConstantIntVal: {
    const ConstantInt *CI = cast<ConstantInt>(CV);
    if (CI->getType()->isIntegerTy(1)) {
      pushValue<BRIG_TYPE_B1>(CI->getZExtValue() ? 1 : 0);
    } else {
      switch(CI->getBitWidth()) {
      case 8:  pushValue<BRIG_TYPE_U8> (*CI->getValue().getRawData()); break;
      case 16: pushValue<BRIG_TYPE_U16>(*CI->getValue().getRawData()); break;
      case 32: pushValue<BRIG_TYPE_U32>(*CI->getValue().getRawData()); break;
      case 64: pushValue<BRIG_TYPE_U64>(*CI->getValue().getRawData()); break;
      }
    }
    break;
  }
  case Value::ConstantFPVal: {
    const ConstantFP *CFP = cast<ConstantFP>(CV);
    if (CFP->getType()->isFloatTy()) {
      pushValue<BRIG_TYPE_F32>(HSAIL_ASM::f32_t::fromRawBits(
        *CFP->getValueAPF().bitcastToAPInt().getRawData()));
    } else if (CFP->getType()->isDoubleTy()) {
      pushValue<BRIG_TYPE_F64>(HSAIL_ASM::f64_t::fromRawBits(
        *CFP->getValueAPF().bitcastToAPInt().getRawData()));
    }
    break;
  }
  case Value::ConstantPointerNullVal:
    (m_asmPrinter.getSubtarget().is64Bit()) ?
      pushValue<BRIG_TYPE_B64>(0) :
      pushValue<BRIG_TYPE_B32>(0);
    break;

  case Value::ConstantAggregateZeroVal:
    m_reqNumZeroes += getNumElementsInHSAILType(CV->getType(),m_asmPrinter.getDataLayout());
    break;

  case Value::ConstantExprVal: {
    const ConstantExpr* CE;
    CE = dyn_cast<ConstantExpr>(CV);
    assert(CE != NULL);
    if (CE->isGEPWithNoNotionalOverIndexing()) {
      const GEPOperator* GO = dyn_cast<GEPOperator>(CE);
      if (GO) {
        const Value* Ptr = GO->getPointerOperand()->stripPointerCasts();
        assert(Ptr != NULL && Ptr->hasName());
        APInt Offset(m_asmPrinter.getSubtarget().is64Bit() ? 64 : 32, 0);
        if (!GO->accumulateConstantOffset(m_asmPrinter.getDataLayout(), Offset))
          llvm_unreachable("Cannot calculate initializer offset");
        initVarWithAddress(Ptr, Var, Offset);
      } else {
        llvm_unreachable("Unhandled ConstantExpr initializer instruction");
      }
    } else if (CE->getOpcode() == Instruction::BitCast) {
      append(cast<Constant>(CE->getOperand(0)), Var);
    } else {
      llvm_unreachable("Unhandled ConstantExpr initializer type");
    }
    break;
  }

  case Value::GlobalVariableVal: {
    const Value* V = CV->stripPointerCasts();
    assert(V->hasName());
    initVarWithAddress(V, Var,
      APInt(m_asmPrinter.getSubtarget().is64Bit() ? 64 : 32, 0));
    break;
  }

  default: assert(!"Unhandled initializer");
  }
}

void BRIGAsmPrinter::BrigEmitGlobalInit(HSAIL_ASM::DirectiveVariable globalVar,
                                        Constant *CV) {
  StoreInitializer store(HSAIL_ASM::convType2BitType(globalVar.type()), *this);
  store.append(CV, globalVar.name().str());
  size_t typeBytes = HSAIL_ASM::getBrigTypeNumBytes(globalVar.type());

  HSAIL_ASM::SRef init;
  char zeroes[32];
  if (store.elementCount() > 0) {
    init = store.toSRef();
  } else {
    assert(typeBytes <= sizeof zeroes);
    memset(zeroes, 0, typeBytes);
    init = HSAIL_ASM::SRef(zeroes, zeroes + typeBytes);
  }

  if (globalVar.modifier().isArray()) {
    assert(globalVar.dim() * typeBytes  >= init.length());
  } else {
    assert(globalVar.dim() == 0 && typeBytes == init.length());
  }

  globalVar.init() = brigantine.createOperandData(init);
}

BRIGAsmPrinter::BRIGAsmPrinter(HSAIL_ASM_PRINTER_ARGUMENTS)
  : AsmPrinter(ASM_PRINTER_ARGUMENTS),
    brigantine(bc) {

  Subtarget = &TM.getSubtarget<HSAILSubtarget>();
  FuncArgsStr = "";
  FuncRetValStr = "";
  retValCounter = 0;
  paramCounter = 0;
  reg1Counter = 0;
  reg32Counter = 0;
  reg64Counter = 0;
  mTM = reinterpret_cast<HSAILTargetMachine*>(&TM);
  mMeta = new HSAILKernelManager(mTM);
  mMFI = NULL;
  mBuffer = 0;
  m_bIsKernel = false;
  privateStackBRIGOffset = 0;
  spillStackBRIGOffset = 0;

  mDwarfFileStream = 0;

  // Obtain DWARF stream
  BRIGDwarfStreamer* dwarfstreamer = dyn_cast<BRIGDwarfStreamer>(&OutStreamer);
  assert(dwarfstreamer && "BRIG lowering doesn't work with this kind of streamer");
  mDwarfStream = dwarfstreamer->getDwarfStream();
  // Obtain stream for streaming BRIG that came from LLC
  mBrigStream = mDwarfStream->getOtherStream();
  // Disconnect DWARF stream from BRIG stream
  mDwarfStream->releaseStream();
  if (DebugInfoFilename.size() > 0) {
    std::error_code err;
    mDwarfFileStream = new raw_fd_ostream(DebugInfoFilename.c_str(), err,
                                          sys::fs::F_Text);
    mDwarfStream->setOtherStream(mDwarfFileStream);
  }
}

BRIGAsmPrinter::~BRIGAsmPrinter() {
  delete mMeta;
  delete mDwarfStream;
  delete mDwarfFileStream;
}

static unsigned getAlignTypeQualifier(Type *ty, const DataLayout& DL) {
  unsigned align = 0;

  if (StructType *STy = dyn_cast<StructType>(ty)) {
    // Scan members to find type with largest alignment requirement
    for (StructType::element_iterator I = STy->element_begin(),
           E = STy->element_end(); I != E; ++I) {
      Type* elemTy = *I;
      unsigned aa = getAlignTypeQualifier(elemTy, DL);
      if (aa > align) {
        align = aa;
      }
    }
  } else if (ArrayType *ATy = dyn_cast<ArrayType>(ty)) {
    align = getAlignTypeQualifier(ATy->getElementType(), DL);
  } else if (IsImage(ty) || IsSampler(ty)) {
    return 8;
  }

  align = DL.getPrefTypeAlignment(ty);

  switch (align) {
  case 1:
  case 2:
  case 4:
  case 8:
  case 16:
  case 32:
  case 64:
  case 128:
    break;

  default:
    llvm_unreachable("invalid align-type qualifier");
  }

  return align;
}

Brig::BrigSegment8_t BRIGAsmPrinter::getHSAILSegment(unsigned AddressSpace)
                                                     const {
  switch (AddressSpace) {
  case HSAILAS::GLOBAL_ADDRESS:   return Brig::BRIG_SEGMENT_GLOBAL;
  case HSAILAS::CONSTANT_ADDRESS: return Brig::BRIG_SEGMENT_READONLY;
  case HSAILAS::GROUP_ADDRESS:    return Brig::BRIG_SEGMENT_GROUP;
  case HSAILAS::PRIVATE_ADDRESS:  return Brig::BRIG_SEGMENT_PRIVATE;
  case HSAILAS::KERNARG_ADDRESS:  return Brig::BRIG_SEGMENT_KERNARG;
  case HSAILAS::ARG_ADDRESS:      return Brig::BRIG_SEGMENT_ARG;
  // TODO_HSA: default to global until all possible actions are resolved
  default: return Brig::BRIG_SEGMENT_GLOBAL;
  }
}

Brig::BrigSegment8_t BRIGAsmPrinter::getHSAILSegment(const GlobalVariable* gv)
                                                     const {
  return getHSAILSegment(gv->getType()->getAddressSpace());
}

bool BRIGAsmPrinter::canInitHSAILAddressSpace(const GlobalVariable* gv) const {
  bool canInit;
  switch (gv->getType()->getAddressSpace()) {
  case HSAILAS::GLOBAL_ADDRESS:
  case HSAILAS::CONSTANT_ADDRESS:
    canInit = true;
    break;
  default:
    canInit = false;
    break;
  }
  return canInit;
}

uint64_t getNumElementsInHSAILType(Type* type, const DataLayout& dataLayout) {
  switch(type->getTypeID()) {
  case Type::IntegerTyID:
  case Type::PointerTyID:
  case Type::FloatTyID:
  case Type::DoubleTyID: return 1;
  case Type::VectorTyID: {
    VectorType *vt = cast<VectorType>(type);
    uint64_t allocatedSize = dataLayout.getTypeAllocSize(type);
    uint64_t elementSize = dataLayout.getTypeAllocSize(vt->getElementType());
    return (allocatedSize/elementSize);
  }
  case Type::ArrayTyID: {
    const ArrayType *at = cast<ArrayType>(type);
    return at->getNumElements() * getNumElementsInHSAILType(at->getElementType(),dataLayout);
  }
  case Type::StructTyID: {
    StructType *st= cast<StructType>(type);
    const StructLayout *layout = dataLayout.getStructLayout(st);
    return layout->getSizeInBytes();
  }
  default: assert(!"Unhandled type");
  }
  return 0;
}

bool requireHSAILArray(Type* type) {
  switch(type->getTypeID()) {
  case Type::VectorTyID:
  case Type::ArrayTyID:
  case Type::StructTyID:
    return true;
  default:
    return false;
  }
}

/// EmitGlobalVariable - Emit the specified global variable to the .s file.
void BRIGAsmPrinter::EmitGlobalVariable(const GlobalVariable *GV)
{
  if (HSAIL::isIgnoredGV(GV))
    return;

  std::stringstream ss;
  ss << getSymbolPrefix(*GV) << GV->getName();

  string nameString = ss.str();

  const DataLayout& DL = getDataLayout();
  Type *ty = GV->getType()->getElementType();
  if (ty->isIntegerTy(1)) {
   // HSAIL do not support boolean load and stores and all boolean variables
   // should have been promoted to int8. However, due to llvm optimization
   // such as shrink to boolean optimization we will still get i1 types.
   // The loads and stores of this global variables are handled in
   // selection lowering by extending to int8 types.The type of global
   // variable will be changed to i8 here.
    ty = Type::getInt8Ty(GV->getContext());
  }
  bool const isArray = requireHSAILArray(ty);

  // TODO_HSA: pending BRIG_LINKAGE_STATIC implementation in the Finalizer
  HSAIL_ASM::DirectiveVariable globalVar =
    brigantine.addVariable(nameString, getHSAILSegment(GV),
    HSAIL::HSAILgetBrigType(ty, Subtarget->is64Bit()));

  globalVar.linkage() = GV->isExternalLinkage(GV->getLinkage()) ?
      Brig::BRIG_LINKAGE_PROGRAM : ( GV->isInternalLinkage(GV->getLinkage()) ?
     Brig::BRIG_LINKAGE_MODULE : Brig::BRIG_LINKAGE_NONE );
  globalVar.allocation() = Brig::BRIG_ALLOCATION_AGENT;
  globalVar.modifier().isDefinition() = 1;

  globalVar.modifier().isArray() = isArray;
  globalVar.dim() = isArray ? getNumElementsInHSAILType(ty,DL) : 0;
  // Align arrays at least by 4 bytes
  unsigned align_value = std::max((globalVar.dim() > 1) ? 4U : 0U,
    std::max(GV->getAlignment(),
             getAlignTypeQualifier(GV->getType()->getElementType(), DL)));
  globalVar.align() = getBrigAlignment(align_value);

  globalVariableOffsets[GV] = globalVar.brigOffset();
#if 0
  printf("GV %s[%p] is at offset %lu\n", nameString.c_str(), (const void*)(GV),
         (unsigned long)(globalVar.brigOffset()));
#endif

  // TODO_HSA: if group memory has initializer, then emit instructions to
  // initialize dynamically
  if (GV->hasInitializer() && canInitHSAILAddressSpace(GV)) {
    BrigEmitGlobalInit(globalVar, (Constant *)GV->getInitializer());
  }
}

static bool isHSAILInstrinsic(StringRef str) {
  if ((HSAILIntrinsic::ID)Intrinsic::not_intrinsic !=
      getIntrinsicForGCCBuiltin("HSAIL", str.data())) return true;
  return str.startswith(StringRef("llvm.HSAIL."));
}

/// Returns true if StringRef is LLVM intrinsic function that define a mapping
/// between LLVM program objects and the source-level objects.
/// See http://llvm.org/docs/SourceLevelDebugging.html#format_common_intrinsics
/// for more details.
static bool isLLVMDebugIntrinsic(StringRef str) {
  return str.equals("llvm.dbg.declare") || str.equals("llvm.dbg.value");
}

/// NOTE: sFuncName is NOT the same as rF.getName()
/// rF may be an unnamed alias of the another function
/// sFuncName is the resolved alias name but rF.getName() is empty
void BRIGAsmPrinter::EmitFunctionLabel(const Function &rF,
                                       const llvm::StringRef sFuncName ) {
  if (isLLVMDebugIntrinsic(rF.getName())) {
    return; // Nothing to do with LLVM debug-related intrinsics
  }
  const Function *F = &rF;
  Type *retType = F->getReturnType();
  FunctionType *funcType = F->getFunctionType();

  HSAIL_ASM::DirectiveFunction fx = brigantine.declFunc(( "&" + sFuncName).str());
  // TODO_HSA: pending BRIG_LINKAGE_STATIC implementation in the Finalizer
  fx.linkage() = F->isExternalLinkage(F->getLinkage()) ?
      Brig::BRIG_LINKAGE_PROGRAM : ( F->isInternalLinkage(F->getLinkage()) ?
     Brig::BRIG_LINKAGE_MODULE : Brig::BRIG_LINKAGE_NONE );

  paramCounter = 0;
  if (retType && (retType->getTypeID() != Type::VoidTyID)) {
    EmitFunctionReturn(retType, false, StringRef(), F->getAttributes().getRetAttributes()
                       .hasAttribute(AttributeSet::ReturnIndex, Attribute::SExt));
  }
  if (funcType) {
    // Loop through all of the parameters and emit the types and
    // corresponding names.
    reg1Counter = 0;
    reg32Counter = 0;
    reg64Counter = 0;
    Function::const_arg_iterator ai = F->arg_begin();
    Function::const_arg_iterator ae = F->arg_end();
    unsigned n = 1;
    for (FunctionType::param_iterator pb = funcType->param_begin(),
         pe = funcType->param_end(); pb != pe; ++pb, ++ai, ++n) {
      assert(ai != ae);
      Type* type = *pb;
      EmitFunctionArgument(type, false, ai->getName(), F->getAttributes().getParamAttributes(n)
                           .hasAttribute(AttributeSet::FunctionIndex, Attribute::SExt));
    }
  }
}

//===------------------------------------------------------------------===//
// Overridable Hooks
//===------------------------------------------------------------------===//

/**
 *
 *
 * @param lMF MachineFunction to print the assembly for
 * @brief parse the specified machineModel function and print
 * out the assembly for all the instructions in the function
 *
 * @return
 */

bool  BRIGAsmPrinter::runOnMachineFunction(MachineFunction &lMF) {
  this->MF = &lMF;
  mMeta->setMF(&lMF);
  mMFI = lMF.getInfo<HSAILMachineFunctionInfo>();
  SetupMachineFunction(lMF);
  const Function *F = MF->getFunction();
  OutStreamer.SwitchSection(getObjFileLowering().SectionForGlobal(F, *Mang, TM));
  m_bIsKernel = HSAIL::isKernelFunc(MF->getFunction());
  mMeta->printHeader(MF->getFunction()->getName());

  // The need to define global samplers is discovered during instruction selection,
  // so we emit them at file scope just before a kernel function is emitted.
  Subtarget->getImageHandles()->finalize();
  EmitSamplerDefs();

  EmitFunctionEntryLabel();
  EmitFunctionBody();

  // Clear local handles from image handles
  Subtarget->getImageHandles()->clearImageArgs();

  return false;
}

void BRIGAsmPrinter::EmitSamplerDefs() {

  HSAILImageHandles* handles = Subtarget->getImageHandles();
  SmallVector<HSAILSamplerHandle*, 16> samplers = handles->getSamplerHandles();

  // Emit global sampler defs
  for (unsigned i = 0; i < samplers.size(); i++) {
    // All sampler defs (samplers with initializers) are global, so we emit
    // them only once.
    if (!samplers[i]->isEmitted()) {

      HSAIL_ASM::DirectiveVariable samplerVar = brigantine.addSampler("&" +
        samplers[i]->getSym(), samplers[i]->isRO() ? Brig::BRIG_SEGMENT_READONLY
                                                   : Brig::BRIG_SEGMENT_GLOBAL);
      samplerVar.align() = Brig::BRIG_ALIGNMENT_8;
      samplerVar.allocation() = Brig::BRIG_ALLOCATION_AGENT;
      samplerVar.linkage() = Brig::BRIG_LINKAGE_MODULE;
      samplerVar.modifier().isDefinition() = 1;
      HSAIL_ASM::OperandSamplerProperties samplerProps = brigantine.append<HSAIL_ASM::OperandSamplerProperties>();
      // HSAIL_ASM::ItemList samplerInit;
      // samplerInit.push_back(samplerProps);
      samplerVar.init() = samplerProps;

      int ocl_init = handles->getSamplerValue(i);

      samplerProps.coord() = (ocl_init & 0x1)
            ? Brig::BRIG_COORD_NORMALIZED
            : Brig::BRIG_COORD_UNNORMALIZED;

      switch (ocl_init & 0x30) {
      default:
      case 0x10:
        samplerProps.filter() = Brig::BRIG_FILTER_NEAREST; // CLK_FILTER_NEAREST
        break;
      case 0x20:
        samplerProps.filter() = Brig::BRIG_FILTER_LINEAR; // CLK_FILTER_LINEAR
        break;
      }

      switch (ocl_init & 0xE) {
      case 0x0 : samplerProps.addressing() = Brig::BRIG_ADDRESSING_UNDEFINED;          break;  // CLK_ADDRESS_NONE
      case 0x2 : samplerProps.addressing() = Brig::BRIG_ADDRESSING_REPEAT;             break;  // CLK_ADDRESS_REPEAT
      case 0x4 : samplerProps.addressing() = Brig::BRIG_ADDRESSING_CLAMP_TO_EDGE;      break;  // CLK_ADDRESS_CLAMP_TO_EDGE
      case 0x6 : samplerProps.addressing() = Brig::BRIG_ADDRESSING_CLAMP_TO_BORDER;    break;  // CLK_ADDRESS_CLAMP
      case 0x8 : samplerProps.addressing() = Brig::BRIG_ADDRESSING_MIRRORED_REPEAT;    break;  // CLK_ADDRESS_MIRRORED_REPEAT
      }

      samplers[i]->setEmitted();
    }
  }
}

bool BRIGAsmPrinter::isMacroFunc(const MachineInstr *MI) {
  if (MI->getOpcode() != HSAIL::target_call) {
    return false;
  }
  const llvm::StringRef &nameRef = MI->getOperand(0).getGlobal()->getName();
  if (nameRef.startswith("barrier")) {
    return true;
  }
  return false;
}

bool BRIGAsmPrinter::isIdentityCopy(const MachineInstr *MI) const {
  if (MI->getNumOperands() != 2) {
    return false;
  }
  switch(MI->getOpcode()) {
    // Bitconvert is a copy instruction
  case HSAIL::bitcvt_f32_u32:
  case HSAIL::bitcvt_u32_f32:
  case HSAIL::bitcvt_f64_u64:
  case HSAIL::bitcvt_u64_f64:
    return MI->getOperand(0).getReg() == MI->getOperand(1).getReg();
  default:
    return false;
  }
}

void BRIGAsmPrinter::emitMacroFunc(const MachineInstr *MI, raw_ostream &O) {
  llvm::StringRef nameRef;
  nameRef = MI->getOperand(0).getGlobal()->getName();
  if (nameRef.startswith("barrier")) {
    O << '\t';
    O << nameRef;
    O << ';';
    return;
  }
}

#define TWINE_TO_STR(_a) Twine(_a).str()
void BRIGAsmPrinter::EmitBasicBlockStart(const MachineBasicBlock &MBB) {
  std::ostringstream o;
  bool insert_spaces=false;

  if (MBB.pred_empty() || isBlockOnlyReachableByFallthrough(&MBB)) {
    o << "// BB#" << MBB.getNumber() << ":";
    insert_spaces=true;
  } else {
    StringRef name = MBB.getSymbol()->getName();
    brigantine.addLabel(HSAIL_ASM::SRef(name.begin(), name.end()));
  }
  if (const BasicBlock *BB = MBB.getBasicBlock())
    if  (BB->hasName())
      o << ( insert_spaces ? "                                ":"")
        <<"// %" << BB->getName();
  if (o.str().length()) {
    brigantine.addComment(o.str().c_str());
  }

  AsmPrinter::EmitBasicBlockStart(MBB);
}

/// Emit ld_arg or st_arg
HSAIL_ASM::Inst BRIGAsmPrinter::EmitLdStArg(const MachineInstr *MI, bool isLoad) {
  MachineInstr::const_mop_iterator oi = MI->operands_begin();
  const MachineMemOperand *MMO = *MI->memoperands_begin();
  const MachinePointerInfo &MPI = MMO->getPointerInfo();

  HSAIL_ASM::InstMem inst = brigantine.addInst<HSAIL_ASM::InstMem>(
    isLoad ? Brig::BRIG_OPCODE_LD : Brig::BRIG_OPCODE_ST);

  assert(oi->isReg());
  BrigEmitOperand(MI, 0, inst); ++oi;
  assert(oi->isSymbol());
  std::string sym("%");
  sym += oi++->getSymbolName();
  HSAIL_ASM::OperandReg reg;
  if (oi->isReg())
    reg = getBrigReg(*oi);
  oi++; oi++; // skip reg and offset (offset is taken from MMO).
  m_opndList.push_back(brigantine
        .createRef(sym, reg, MMO->getOffset()));

  assert(oi->isImm());
  Brig::BrigTypeX type = static_cast<Brig::BrigTypeX>(oi->getImm());
  inst.segment()    = getHSAILSegment(MPI.getAddrSpace());
  inst.type()       = type;
  inst.align()      = getBrigAlignment(MMO->getAlignment());
  inst.width()      = isLoad ? Brig::BRIG_WIDTH_1 : Brig::BRIG_WIDTH_NONE;
  inst.equivClass() = 0;
  inst.modifier().isConst() = 0;
  return inst;
}

namespace {
  class autoCodeEmitter {
    MCStreamer                *streamer;
    const HSAIL_ASM::Brigantine *brigantine;
    uint64_t                   lowpc;
    uint64_t                   hipc;

  public:
    autoCodeEmitter(MCStreamer *strm, const HSAIL_ASM::Brigantine *brig):
        streamer(strm), brigantine(brig) {
        lowpc = brigantine->container().code().size();
    }

    ~autoCodeEmitter() {
      hipc = brigantine->container().code().size();
#if 0
      ::printf("Instruction %p emitted to range %08X - %08X\n",
        (const void*)_instruction, (unsigned)_lowpc, (unsigned)_hipc);
#endif
      streamer->SwitchSection(streamer->getContext().getObjectFileInfo()->
        getTextSection());
      assert(lowpc <= hipc);
      // This is the only way to adjust the size of virtual ELF section
      // (type SHT_NOBITS) like .brigcode
      streamer->EmitZeros(hipc - lowpc);
    }

  };
}

bool IsKernel(const MachineInstr *II) {
  std::string sFuncName;
  const MachineBasicBlock * bb = II->getParent();
  if ( bb ) {
    const MachineFunction * mf = bb->getParent();

    if ( mf ) {
      const Function * F = mf->getFunction();
      sFuncName = "&" + F->getName().str();
      return HSAIL::isKernelFunc(F);
    }
  }
  return false;
}

void BRIGAsmPrinter::EmitInstruction(const MachineInstr *II) {
  m_opndList.clear();
  HSAIL_ASM::Inst inst = EmitInstructionImpl(II);
  if (inst) {
    inst.operands() = m_opndList;
  }
}

HSAIL_ASM::Inst BRIGAsmPrinter::EmitInstructionImpl(const MachineInstr *II) {
  // autoCodeEmitter will emit required amount of bytes in corresponding MCSection
  autoCodeEmitter ace(&OutStreamer, &brigantine);

  if (isIdentityCopy(II)) {
    return HSAIL_ASM::Inst();
  }

  if (HSAIL::isParametrizedAtomicOp(II->getOpcode())) {
    bool hasRet = HSAIL::isParametrizedRetAtomicOp(II->getOpcode());
    Brig::BrigTypeX btype = getParametrizedAtomicBrigType(II->getOpcode());
    unsigned brigAtomicOp = hasRet ? Brig::BRIG_OPCODE_ATOMIC :
                                     Brig::BRIG_OPCODE_ATOMICNORET;
    HSAIL_ASM::InstAtomic instAtomic =
        brigantine.addInst<HSAIL_ASM::InstAtomic>(brigAtomicOp, btype);

    instAtomic.atomicOperation() = getParametrizedAtomicOpcode(II);
    instAtomic.segment() = getParametrizedAtomicSegment(II);
    instAtomic.memoryOrder() = getParametrizedAtomicOrder(II);
    instAtomic.memoryScope() = getParametrizedAtomicScope(II);

    if (hasRet)
      BrigEmitOperand(II, 0, instAtomic);
    BrigEmitOperandLdStAddress(II, HSAIL_ATOMIC_OPS::SCOPE_INDEX + 1 +
                               (hasRet ? 1 : 0));
    if (HSAIL::isParametrizedTernaryAtomicOp(II->getOpcode())) {
      BrigEmitOperand(II, II->getNumOperands() - 2, instAtomic);
    }
    if (HSAIL::isParametrizedTernaryAtomicOp(II->getOpcode()) ||
        HSAIL::isParametrizedBinaryAtomicOp(II->getOpcode())) {
      BrigEmitOperand(II, II->getNumOperands() - 1, instAtomic);
    }
    return instAtomic;
  }

  if (II->getOpcode() == llvm::HSAIL::hsail_memfence) {
    HSAIL_ASM::InstMemFence memfence = 
        brigantine.addInst< HSAIL_ASM::InstMemFence >(Brig::BRIG_OPCODE_MEMFENCE,
                Brig::BRIG_TYPE_NONE);
    memfence.memoryOrder() =
        II->getOperand(HSAIL_MEMFENCE::MEMORY_ORDER_INDEX).getImm();
    memfence.globalSegmentMemoryScope() =
        II->getOperand(HSAIL_MEMFENCE::GLOBAL_SCOPE_INDEX).getImm();
    memfence.groupSegmentMemoryScope() =
        II->getOperand(HSAIL_MEMFENCE::GROUP_SCOPE_INDEX).getImm();
    memfence.imageSegmentMemoryScope() =
        II->getOperand(HSAIL_MEMFENCE::IMAGE_SCOPE_INDEX).getImm();
    return memfence;
  }

  switch(II->getOpcode()) {
  default:
    return BrigEmitInstruction(II);

  case HSAIL::ret:
    return brigantine.addInst<HSAIL_ASM::InstBasic>(Brig::BRIG_OPCODE_RET,Brig::BRIG_TYPE_NONE);

  case HSAIL::arg_scope_start:
    brigantine.startArgScope();
    return HSAIL_ASM::Inst();

  case HSAIL::arg_scope_end:
    brigantine.endArgScope();
    return HSAIL_ASM::Inst();

  case HSAIL::target_call:
    if (isMacroFunc(II)) {
      // TODO_HSA: SINCE THE 'barrier' ONLY IS CURRENTLY HANDLED WE'll SUPPORT THIS LATER
#if 0
      emitMacroFunc(II, O);
#endif
     return HSAIL_ASM::Inst();
    } else {
      MachineInstr::const_mop_iterator oi = II->operands_begin();
      MachineInstr::const_mop_iterator oe = II->operands_end();
      const GlobalValue *gv = (oi++)->getGlobal();;

      // Place a call
      HSAIL_ASM::InstBr call = brigantine.addInst<HSAIL_ASM::InstBr>(
                                 Brig::BRIG_OPCODE_CALL,Brig::BRIG_TYPE_NONE);
      call.width() = Brig::BRIG_WIDTH_ALL;

      HSAIL_ASM::ItemList ret_list;
      for (; oi != oe && oi->isSymbol() ; ++oi) {
        std::string ret("%");
        ret += oi->getSymbolName();
        ret_list.push_back(
          brigantine.findInScopes<HSAIL_ASM::DirectiveVariable>(ret));
      }

      // Return value and argument symbols are delimited with a 0 value.
      assert((oi->isImm() && (oi->getImm() == 0)) ||
             !"Unexpected target call instruction operand list!");

      HSAIL_ASM::ItemList call_paramlist;
      for (++oi; oi != oe; ++oi) {
        if (oi->isSymbol()) {
          std::string op("%");
          op += oi->getSymbolName();
          call_paramlist.push_back(
            brigantine.findInScopes<HSAIL_ASM::DirectiveVariable>(op));
        } else {
          llvm_unreachable("Unexpected target call instruction operand list!");
        }
      }

      m_opndList.push_back(
        brigantine.createCodeList(ret_list));
      m_opndList.push_back(
        brigantine.createFuncRef(std::string("&") + gv->getName().str()));
      m_opndList.push_back(
        brigantine.createCodeList(call_paramlist));

      return call;
  }
  case HSAIL::ld_arg_64:
    return EmitLdStArg(II, true);

  case HSAIL::st_arg_64:
    return EmitLdStArg(II, false);

  case HSAIL::arg_decl:
    BrigEmitVecArgDeclaration(II);
    return HSAIL_ASM::Inst();

  case HSAIL::ftz_f32: {
  // add_ftz_f32  $dst, $src, 0F00000000
    HSAIL_ASM::InstMod ftz = brigantine.addInst<HSAIL_ASM::InstMod>(
      Brig::BRIG_OPCODE_ADD, Brig::BRIG_TYPE_F32);
    MachineOperand dest = II->getOperand(0);
    MachineOperand src = II->getOperand(1);
    m_opndList.push_back(getBrigReg(dest));
    m_opndList.push_back(getBrigReg(src));
    m_opndList.push_back(brigantine.createImmed(0, Brig::BRIG_TYPE_B32));
    ftz.modifier().round() = Brig::BRIG_ROUND_FLOAT_PLUS_INFINITY;
    ftz.modifier().ftz() = true;
    return ftz;
  }
  case HSAIL::pack_u32x2lo_to_hi: {
  // pack_u32x2_u32 $dst, 0, $src, 1
    HSAIL_ASM::InstSourceType pack =
      brigantine.addInst<HSAIL_ASM::InstSourceType>(Brig::BRIG_OPCODE_PACK,
                                                    Brig::BRIG_TYPE_U32X2);
    MachineOperand dest = II->getOperand(0);
    MachineOperand src = II->getOperand(1);
    m_opndList.push_back(getBrigReg(dest));
    m_opndList.push_back(brigantine.createImmed(0, Brig::BRIG_TYPE_U32X2));
    m_opndList.push_back(getBrigReg(src));
    m_opndList.push_back(brigantine.createImmed(1, Brig::BRIG_TYPE_U32));
    pack.sourceType() = Brig::BRIG_TYPE_U32;
    return pack;
  }
  case HSAIL::unpack_u32_u8x4:
  case HSAIL::unpack_u32_u16x2: {
    HSAIL_ASM::InstSourceType unpack =
      brigantine.addInst<HSAIL_ASM::InstSourceType>(Brig::BRIG_OPCODE_UNPACK,
                                                    Brig::BRIG_TYPE_U32);
    MachineOperand dest = II->getOperand(0),
                   src = II->getOperand(1),
                   ind = II->getOperand(2);
    m_opndList.push_back(getBrigReg(dest));
    assert(ind.isImm());
    m_opndList.push_back(getBrigReg(src));
    m_opndList.push_back(brigantine.createImmed(ind.getImm(), Brig::BRIG_TYPE_U32));
    if (II->getOpcode() == HSAIL::unpack_u32_u8x4)
      unpack.sourceType() = Brig::BRIG_TYPE_U8X4;
    else
      unpack.sourceType() = Brig::BRIG_TYPE_U16X2;
    return unpack;
  }
  case HSAIL::sext_cmov_s32_b1: {
    HSAIL_ASM::InstBasic cmov = brigantine.addInst<HSAIL_ASM::InstBasic>(
      Brig::BRIG_OPCODE_CMOV, Brig::BRIG_TYPE_B32);
    MachineOperand dest = II->getOperand(0);
    MachineOperand src = II->getOperand(1);
    m_opndList.push_back(getBrigReg(dest));
    m_opndList.push_back(getBrigReg(src));
    m_opndList.push_back(brigantine.createImmed(-1, Brig::BRIG_TYPE_B32));
    m_opndList.push_back(brigantine.createImmed(0, Brig::BRIG_TYPE_B32));
    return cmov;
  }
  case HSAIL::sext_cmov_s64_b1: {
    HSAIL_ASM::InstBasic cmov = brigantine.addInst<HSAIL_ASM::InstBasic>(
      Brig::BRIG_OPCODE_CMOV, Brig::BRIG_TYPE_B64);
    MachineOperand dest = II->getOperand(0);
    MachineOperand src = II->getOperand(1);
    m_opndList.push_back(getBrigReg(dest));
    m_opndList.push_back(getBrigReg(src));
    m_opndList.push_back(brigantine.createImmed(-1, Brig::BRIG_TYPE_B64));
    m_opndList.push_back(brigantine.createImmed(0, Brig::BRIG_TYPE_B64));
    return cmov;
  }
  case HSAIL::RotateBit32_ri:
  case HSAIL::RotateByte32_ri: {
    HSAIL_ASM::InstBasic align = brigantine.addInst<HSAIL_ASM::InstBasic>(
      II->getOpcode() == HSAIL::RotateByte32_ri ? Brig::BRIG_OPCODE_BYTEALIGN : Brig::BRIG_OPCODE_BITALIGN,
      Brig::BRIG_TYPE_B32);
    MachineOperand dest = II->getOperand(0);
    MachineOperand src = II->getOperand(1);
    MachineOperand imm = II->getOperand(3);
    assert(imm.isImm());
    m_opndList.push_back(getBrigReg(dest));
    m_opndList.push_back(getBrigReg(src));
    m_opndList.push_back(getBrigReg(src));
    m_opndList.push_back(
      brigantine.createImmed(imm.getImm(), Brig::BRIG_TYPE_U32));
    return align;
  }
  }
}

bool BRIGAsmPrinter::doFinalization(Module &M) {

#if 0
  if (getDwarfDebug()) {
    // NamedRegionTimer T(DbgTimerName, DWARFGroupName, TimePassesIsEnabled);
    // Adjust size of fake .brigdirectives section to match actual size of
    // BRIG .directives section
    OutStreamer.SwitchSection(OutStreamer.getContext().getObjectFileInfo()->
                                getDataSection());
    OutStreamer.EmitZeros(brigantine.container().directives().size(), 0);
    // This is not needed at this time, because dwarflinker expects
    // .brigdirectives size to be zero
    DwarfDebug *mDD = getDwarfDebug();
    mDD->endModule();
    delete mDD;
    setDwarfDebug(NULL);
  }
#endif

  // LLVM Bug 9761. Nothing should be emitted after EmitEndOfAsmFile()
  OutStreamer.FinishImpl();

  // Allow the target to emit any magic that it wants at the end of the file,
  // after everything else has gone out.
  EmitEndOfAsmFile(M);

  return false;
}

/// EmitStartOfAsmFile - This virtual method can be overridden by targets
/// that want to emit something at the start of their file.
void BRIGAsmPrinter::EmitStartOfAsmFile(Module &M) {
  if (PrintBeforeBRIG) {
    dbgs() << std::string("*** IR Dump Before ") + getPassName() + " ***";
    M.dump();
  }
  // Clear global variable map
  globalVariableOffsets.clear();

  brigantine.startProgram();
  brigantine.version(Brig::BRIG_VERSION_HSAIL_MAJOR,
    Brig::BRIG_VERSION_HSAIL_MINOR,
    Subtarget->is64Bit() ? Brig::BRIG_MACHINE_LARGE : Brig::BRIG_MACHINE_SMALL,
    Brig::BRIG_PROFILE_FULL);

  //if (usesGCNAtomicCounter()) {
    brigantine.addExtension("amd:gcn");
  //}

  brigantine.addExtension("IMAGE");

  // If we are emitting first instruction that occupied some place in BRIG
  // we should also emit 4 reserved bytes to the MCSection, so that offsets
  // of instructions are the same in the BRIG .code section and MCSection
  OutStreamer.SwitchSection(OutStreamer.getContext().getObjectFileInfo()->
                              getTextSection());
  OutStreamer.EmitZeros(brigantine.container().code().secHeader()->headerByteCount);

  for(Module::const_alias_iterator I = M.alias_begin(), E = M.alias_end();
      I != E; ++I) {
    const Function * F = dyn_cast<Function>(I->getAliasee());
    if (F) {
      funcAliases[F].push_back(I->getName());
    }
  }

  for (Module::const_global_iterator I = M.global_begin(), E = M.global_end();
       I != E; ++I)
    EmitGlobalVariable(I);

  // Emit function declarations
  for (Module::const_iterator I = M.begin(), E = M.end(); I != E; ++I) {
    const Function &F = *I;

    // No declaration for kernels.
    if (HSAIL::isKernelFunc(&F))
      continue;

    std::vector<llvm::StringRef> aliasList;

    if(F.hasName()) {
      aliasList.push_back(F.getName());
    }

    std::vector<llvm::StringRef> aliases = funcAliases[&F];
    if ( !aliases.empty()) {
      aliasList.insert(aliasList.end(), aliases.begin(), aliases.end());
    }

    for (std::vector<llvm::StringRef>::const_iterator AI = aliasList.begin(),
         AE = aliasList.end(); AI != AE; ++AI ) {
      std::string sFuncName = (*AI).str();
      // No declaration for HSAIL instrinsic
      if (!isHSAILInstrinsic(sFuncName) && !F.isIntrinsic()) {
        EmitFunctionLabel(F, sFuncName);
      }
    }
  }
}

/// EmitEndOfAsmFile - This virtual method can be overridden by targets that
/// want to emit something at the end of their file.
void BRIGAsmPrinter::EmitEndOfAsmFile(Module &M) {
  brigantine.endProgram();
  // Clear global variable map
  globalVariableOffsets.clear();
  if(mDwarfStream) {
    // Flush all DWARF data captured
    mDwarfStream->flush();
    // Stop writing to another stream, if any provided
    mDwarfStream->releaseStream();
#if 0
    errs() << "BRIGAsmPrinter: captured " << pos << " DWARF bytes\n";
#endif
    // Actual size of captured DWARF data may be less than the size of
    // mDwarfStream's internal buffer
    const uint64_t dwarfDataSize = mDwarfStream->tell();
    assert(dwarfDataSize && "No DWARF data!"); // sanity check
    if (MMI->hasDebugInfo()) {
      // Obtain reference to data block
      HSAIL_ASM::SRef data = mDwarfStream->getData();
      // \todo1.0 get rid of data copying, stream directly into brig section
      brigantine.container().initSectionRaw(Brig::BRIG_SECTION_INDEX_IMPLEMENTATION_DEFINED, "hsa_debug");
      HSAIL_ASM::BrigSectionImpl& section = brigantine.container().sectionById(Brig::BRIG_SECTION_INDEX_IMPLEMENTATION_DEFINED);
      section.insertData(section.size(), data.begin, data.end);
    }
  }
#if 0
  HSAIL_ASM::dump(bc);
#endif
  // optimizeOperands is not functional as of now
  // bc.optimizeOperands();
  HSAIL_ASM::Validator vld(bc);

  bool isValid=true;
  if (!DisableValidator) {
    isValid= vld.validate();
  }

  if (!isValid) {
    std::cerr << vld.getErrorMsg(NULL) << '\n';
    HSAIL_ASM::dump(bc);
    if(DumpOnFailFilename.size() > 0) {
      std::string info;

      std::ofstream dumpStream(DumpOnFailFilename.c_str());
      HSAIL_ASM::dump(bc,dumpStream);
    }
    report_fatal_error(
      "\n Brig container validation has failed in BRIGAsmPrinter.cpp\n");
    return;
  }

  if (mBrigStream) {
    if (mTM->HSAILFileType == TargetMachine::CGFT_ObjectFile) {
      // Common case
      // TBD err stream
      RawOstreamWriteAdapter brigAdapter(*mBrigStream, std::cerr);
      HSAIL_ASM::BrigIO::save(bc, HSAIL_ASM::FILE_FORMAT_BRIG, brigAdapter);
    } else {
      HSAIL_ASM::Disassembler disasm(bc);
      disasm.log(std::cerr); // TBD err stream
      // TBD this is incredibly inefficient
      std::stringstream ss;
      int result=disasm.run(ss);
      if (result) {
        assert(!"disasm should not fail if container was validated above");
      }
      const std::string &s = ss.str();
      if (!s.empty()) {
        mBrigStream->write(s.data(), s.size());
      }
    }
  }
  else {
    HSAIL_ASM::BrigStreamer::save(bc, "test_output.brig");
  }
}

static const Type* GetBasicType(const Type* pType) {
  do {
    if(isa<VectorType>(pType)) {
      pType = cast<VectorType>(pType)->getElementType();
      continue;
    }
    if (isa<ArrayType>(pType)) {
      pType = cast<ArrayType>(pType)->getElementType();
      continue;
    }
    if (isa<StructType>(pType)) {
      // 8 bits since getBrigType treats struct as array of bytes
      return llvm::IntegerType::get(pType->getContext(),8);
    }
    break;
  } while(1);
  return pType;
}

HSAIL_ASM::DirectiveVariable BRIGAsmPrinter::EmitLocalVariable(
  const GlobalVariable *GV, Brig::BrigSegment8_t segment) {

  const Type *pElType = GetBasicType(GV->getType()->getElementType());
  uint64_t num_elem = 1;
  OpaqueType OT = GetOpaqueType(pElType);
  Type  *type = GV->getType()->getElementType();
  const DataLayout& DL = getDataLayout();
  if (type->isIntegerTy(1)) {
   // convert boolean variables generated by llvm optimizations
   // to i32 type.
    type = Type::getInt32Ty(GV->getContext());
  }
  if (OT == NotOpaque)
    num_elem = getNumElementsInHSAILType(type, DL);
  HSAIL_ASM::DirectiveVariable var;
  if (num_elem > 1) {
     var = brigantine.addArrayVariable(("%" + GV->getName()).str(),num_elem,
           segment, HSAIL::HSAILgetBrigType(type, Subtarget->is64Bit()));
    // Align arrays at least by 4 bytes
    var.align() = getBrigAlignment(std::max((var.dim() > 1) ? 4U : 0U,
                      std::max(GV->getAlignment(),
                      getAlignTypeQualifier(type, getDataLayout()))));
  } else {
    var = brigantine.addVariable(("%" + GV->getName()).str(),
           segment, HSAIL::HSAILgetBrigType(type, Subtarget->is64Bit()));
    var.align() = getBrigAlignment(getAlignTypeQualifier(type,getDataLayout()));
  }
  var.allocation() = Brig::BRIG_ALLOCATION_AUTOMATIC;
  var.linkage() = Brig::BRIG_LINKAGE_FUNCTION;
  var.modifier().isDefinition() = 1;

  return var;
}

/// EmitFunctionBodyStart - Targets can override this to emit stuff before
/// the first basic block in the function.
void BRIGAsmPrinter::EmitFunctionBodyStart() {
#if 0
  DwarfDebug *mDD = getDwarfDebug();
  if (mDD) {
    //NamedRegionTimer T(DbgTimerName, DWARFGroupName, TimePassesIsEnabled);
    mDD->beginFunction(MF);
  }
#endif

  brigantine.startBody();

  const Function *F = MF->getFunction();

  {
    bool isKernel = HSAIL::isKernelFunc(F);
    if (isKernel) {
      // Emitting block data inside of kernel
      uint32_t id = 0;
      mMeta->setID(id);
      mMeta->setKernel(isKernel);
      ++mBuffer;
      // Preserved this ostream for compatibility only
      std::string ignored_FunStr;
      raw_string_ostream ignored_OFunStr(ignored_FunStr);
      formatted_raw_ostream ignored(ignored_OFunStr);
// D2 does not need to report kernel args info
//      mMeta->processArgMetadata(ignored, mBuffer, isKernel);
      // We have to call processArgMetadata with ostream before we can emit something
      mMeta->brigEmitMetaData(brigantine, id, isKernel);
    }
  }

  // Clear the lists of group variables
  groupVariablesOffsets.clear();

  // Record private/group variable references
  for (MachineFunction::const_iterator block = MF->begin(),
     endBlock = MF->end();  block != endBlock; ++block) {
    for (MachineBasicBlock::const_iterator inst = block->begin(),
      instEnd = block->end(); inst != instEnd; ++inst ) {
      const MachineInstr *MI = inst;
      for (unsigned int opNum = 0; opNum < MI->getNumOperands(); opNum++) {
        const MachineOperand &MO = MI->getOperand(opNum);
        if (MO.getType() == MachineOperand::MO_GlobalAddress) {
          if (const GlobalVariable *GV =
              dyn_cast<GlobalVariable>(MO.getGlobal())) {
            switch(GV->getType()->getAddressSpace()) {
            case HSAILAS::GROUP_ADDRESS:
              groupVariablesOffsets.insert(pvgvo_record(GV, 0));
              break;
            }
          }
        }
      }
    }
  }

  // Fix names for GROUP_ADDRESS
  for (PVGVOffsetMap::iterator i=groupVariablesOffsets.begin(),
                               e=groupVariablesOffsets.end(); i!=e; ++i)
    HSAIL::sanitizeGlobalValueName(const_cast<GlobalVariable*>(i->first));

  // Emit recorded
  for (Module::const_global_iterator I = F->getParent()->global_begin(),
       E = F->getParent()->global_end(); I != E; ++I) {
    pvgvo_iterator II = groupVariablesOffsets.find(I);
    if (II != groupVariablesOffsets.end()) {
         HSAIL_ASM::DirectiveVariable var =
             EmitLocalVariable(II->first, Brig::BRIG_SEGMENT_GROUP);

      II->second = var.brigOffset();
    }
  }

  DataLayout DL = getDataLayout();

  const MachineFrameInfo *MFI = MF->getFrameInfo();
  size_t stack_size = MFI->getOffsetAdjustment() + MFI->getStackSize();

  size_t spill_size =0;
  size_t local_stack_size =0;

  spillMapforStack.clear();
  LocalVarMapforStack.clear();

  int stk_dim = MFI->getNumObjects();
  int stk_object_indx_begin = MFI->getObjectIndexBegin();
  for (int stk_indx = 0; stk_indx < stk_dim; stk_indx++) {
    int obj_index = stk_object_indx_begin + stk_indx;
    if (!MFI->isDeadObjectIndex(obj_index)) {
      if (MFI->isSpillSlotObjectIndex(obj_index)) {
        int obj_align = MFI->getObjectAlignment(obj_index);
        spill_size = (spill_size + obj_align - 1) / obj_align * obj_align;
        spillMapforStack[MFI->getObjectOffset(obj_index)] = spill_size;
        spill_size += MFI->getObjectSize(obj_index);
      }
      else {
        int obj_offset = MFI->getObjectOffset(obj_index);
        int obj_align = MFI->getObjectAlignment(obj_index);
        local_stack_size = (local_stack_size + obj_align - 1) /
                           obj_align * obj_align;
        LocalVarMapforStack[obj_offset] = local_stack_size;
        int obj_size = MFI->getObjectSize(obj_index);
        for (int cnt = 1 ; cnt < obj_size; cnt++)
          LocalVarMapforStack[obj_offset+cnt] = local_stack_size + cnt;
        local_stack_size  += obj_size;
      }
    }
  }
  local_stack_size = local_stack_size + MFI->getOffsetAdjustment();
  spill_size = spill_size + MFI->getOffsetAdjustment();

  if (stack_size) {
    int const align = DL.getABIIntegerTypeAlignment(32);
    // Dimension is in units of type length
    if (local_stack_size) {
      HSAIL_ASM::DirectiveVariable stack_for_locals =
        brigantine.addArrayVariable("%privateStack", local_stack_size,
                     Brig::BRIG_SEGMENT_PRIVATE, Brig::BRIG_TYPE_U8);
      stack_for_locals.align() = getBrigAlignment(align);
      stack_for_locals.allocation() = Brig::BRIG_ALLOCATION_AUTOMATIC;
      stack_for_locals.linkage() = Brig::BRIG_LINKAGE_FUNCTION;
      stack_for_locals.modifier().isDefinition() = 1;
      privateStackBRIGOffset = stack_for_locals.brigOffset();
    }
    if (spill_size) {
      HSAIL_ASM::DirectiveVariable spill = brigantine.addArrayVariable(
        "%spillStack", spill_size, Brig::BRIG_SEGMENT_SPILL, Brig::BRIG_TYPE_U8);
      spill.align() = getBrigAlignment(align);
      spill.allocation() = Brig::BRIG_ALLOCATION_AUTOMATIC;
      spill.linkage() = Brig::BRIG_LINKAGE_FUNCTION;
      spill.modifier().isDefinition() = 1;
      spillStackBRIGOffset = spill.brigOffset();
    }
  }

  std::string sLabel = "@" + std::string(F->getName()) + "_entry";
  brigantine.addLabel(sLabel);

  retValCounter = 0;
  paramCounter = 0;

#if 0
  if (usesGCNAtomicCounter()) { // TBD095
    HSAIL_ASM::InstBase gcn_region = brigantine.addInst<HSAIL_ASM::InstBase>(
      Brig::BRIG_OPCODE_GCNREGIONALLOC);
    brigantine.appendOperand(gcn_region, brigantine.createImmed(4,
                             Brig::BRIG_TYPE_B32));
  }
#endif
}

/// EmitFunctionBodyEnd - Targets can override this to emit stuff after
/// the last basic block in the function.
void BRIGAsmPrinter::EmitFunctionBodyEnd() {
  autoCodeEmitter ace(&OutStreamer, &brigantine);
  brigantine.endBody();
}

void BRIGAsmPrinter::EmitFunctionReturn(Type* type, bool isKernel,
                                        const StringRef RetName, bool isSExt) {
  std::string SymName("%");
  SymName += RetName.empty() ? "ret" : RetName;
  HSAIL_ASM::SRef ret = SymName;
  reg1Counter = 0;
  reg32Counter = 0;
  reg64Counter = 0;

  // Handle bit return as DWORD
  Type* memType = type->getScalarType();
  if (memType->isIntegerTy(1))
    memType = Type::getInt32Ty(type->getContext());

  // construct return symbol
  HSAIL_ASM::DirectiveVariable retParam;
  if (const VectorType *VT = dyn_cast<VectorType>(type)) {
    retParam = brigantine.addArrayVariable(ret, VT->getNumElements(),
      Brig::BRIG_SEGMENT_ARG, HSAIL::HSAILgetBrigType(memType, Subtarget->is64Bit(),
                                               isSExt));
  } else {
    retParam = brigantine.addVariable(ret, Brig::BRIG_SEGMENT_ARG,
                      HSAIL::HSAILgetBrigType(memType, Subtarget->is64Bit(), isSExt));
  }
  retParam.align() = getBrigAlignment(std::max(
    getAlignTypeQualifier(memType, getDataLayout()),
    getAlignTypeQualifier(type, getDataLayout())));
  brigantine.addOutputParameter(retParam);
}

uint64_t BRIGAsmPrinter::EmitFunctionArgument(Type* type, bool isKernel,
                                              const StringRef argName,
                                              bool isSExt) {
  std::ostringstream stream;
  if (argName.empty()) {
    stream << "%arg_p" << paramCounter;
  } else {
    stream << "%" << HSAILParamManager::mangleArg(Mang, argName);
  }
  paramCounter++;

  std::string const name = stream.str();
  const Brig::BrigSegment8_t symSegment = isKernel ? Brig::BRIG_SEGMENT_KERNARG
                                                   : Brig::BRIG_SEGMENT_ARG;

  HSAIL_ASM::DirectiveVariable sym;

  OpaqueType OT = GetOpaqueType(type);
  // Create the symbol
  if (IsImage(OT)) {
    sym = brigantine.addImage(name, symSegment);
    sym.align() = Brig::BRIG_ALIGNMENT_8;
  } else if (OT == Sampler) {
    sym = brigantine.addSampler(name, symSegment);
    sym.align() = Brig::BRIG_ALIGNMENT_8;
  } else {
    const VectorType *VT = dyn_cast<VectorType>(type);
    // Handle bit argument as DWORD
    Type* memType = type->getScalarType();
    if (memType->isIntegerTy(1))
      memType = Type::getInt32Ty(type->getContext());
    if (VT) {
      sym = brigantine.addArrayVariable(name, VT->getNumElements(), symSegment,
        HSAIL::HSAILgetBrigType(memType, Subtarget->is64Bit(), isSExt));
      // TODO_HSA: workaround for RT bug.
      // RT does not read argument alignment from BRIG, so if we align vectors
      // on a full vector size that will cause mismatch between kernarg offsets
      // in RT and finalizer.
      // The line below has to be removed as soon as RT is fixed.
      if (isKernel) type = VT->getElementType();
    } else {
      sym = brigantine.addVariable(name, symSegment,
                      HSAIL::HSAILgetBrigType(memType, Subtarget->is64Bit(), isSExt));
    }
    sym.align() = getBrigAlignment(
      std::max(getAlignTypeQualifier(type, getDataLayout()),
               getAlignTypeQualifier(memType, getDataLayout())));
  }

  uint64_t rv = sym.brigOffset();
  brigantine.addInputParameter(sym);
  return rv;
}

/// Emit the function signature
void BRIGAsmPrinter::EmitFunctionEntryLabel() {
  // Emit function start
  const Function *F = MF->getFunction();
  Type *retType = F->getReturnType();
  FunctionType *funcType = F->getFunctionType();
  bool isKernel = HSAIL::isKernelFunc(F);
  const HSAILParamManager &PM = MF->getInfo<HSAILMachineFunctionInfo>()->
        getParamManager();
  std::stringstream ss;
  ss << "&" << F->getName();
  HSAIL_ASM::DirectiveExecutable fx;
  if (isKernel) {
    fx = brigantine.declKernel(ss.str());
  } else {
    fx = brigantine.declFunc(ss.str());
  }

  fx.linkage() = F->isExternalLinkage(F->getLinkage()) ?
    Brig::BRIG_LINKAGE_PROGRAM :
    ( F->isInternalLinkage(F->getLinkage()) ? Brig::BRIG_LINKAGE_MODULE
                                            : Brig::BRIG_LINKAGE_NONE);

  // Functions with kernel linkage cannot have output args
  if (!isKernel) {
    if (retType && (retType->getTypeID() != Type::VoidTyID)) {
      EmitFunctionReturn(retType, isKernel, PM.getParamName(*(PM.ret_begin())),
        F->getAttributes().getRetAttributes().hasAttribute(AttributeSet::ReturnIndex, Attribute::SExt));
    }
  }
  if (funcType) {
    // Loop through all of the parameters and emit the types and
    // corresponding names.
    reg1Counter = 0;
    reg32Counter = 0;
    reg64Counter = 0;
    paramCounter = 0;

    // clear arguments mapping
    functionScalarArgumentOffsets.clear();
    functionVectorArgumentOffsets.clear();

    HSAILParamManager::param_iterator Ip = PM.arg_begin();
    HSAILParamManager::param_iterator Ep = PM.arg_end();

    FunctionType::param_iterator pb = funcType->param_begin(),
                                 pe = funcType->param_end();

    if (isKernel && F->hasStructRetAttr()) {
      assert(Ip != Ep && "Invalid struct return fucntion!");
      // If this is a struct-return function, don't process the hidden
      // struct-return argument.
      ++Ip;
      ++pb;
    }

    for (unsigned n = 1; pb != pe; ++pb, ++Ip, ++n) {
      Type* type = *pb;
      assert(Ip != Ep);
      // Obtain argument name
      const char* argName = PM.getParamName(*Ip);
      // Here we will store an offset of DirectiveVariable
      uint64_t argDirectiveOffset = 0;
      argDirectiveOffset = EmitFunctionArgument(type, isKernel, argName,
        F->getAttributes().getParamAttributes(n).hasAttribute(AttributeSet::FunctionIndex, Attribute::SExt));
      functionScalarArgumentOffsets[argName] = argDirectiveOffset;
    }
  }

  // DO NOT need to call endFunc() here it'll be called later on
  // in EmitFunctionBodyEnd().
}

int BRIGAsmPrinter::getHSAILParameterSize(Type* type, HSAIL_ARG_TYPE arg_type) {
  int type_size = 0;

  switch (type->getTypeID()) {
  case Type::VoidTyID:
    break;
  case Type::FloatTyID:
    type_size = 4;
    break;
  case Type::DoubleTyID:
    type_size = 8;
    break;
  case Type::IntegerTyID:
    if (type->isIntegerTy(8)) {
      type_size = 1;
    } else if (type->isIntegerTy(16)) {
      type_size = 2;
    } else if (type->isIntegerTy(32)) {
      type_size = 4;
    } else if (type->isIntegerTy(64)) {
      type_size = 8;
    } else if (type->isIntegerTy(1)) {
      type_size = 1;
    } else {
      type->dump();
      assert(!"Found a case we don't handle!");
    }
    break;
  case Type::PointerTyID:
    if (Subtarget->is64Bit())
      type_size = 8;
    else
      type_size = 4;
    break;
  case Type::VectorTyID:
    type_size = getHSAILParameterSize(type->getScalarType(), arg_type);
    break;
  default:
    type->dump();
    assert(!"Found a case we don't handle!");
    break;
  }
  return type_size;
}

std::string BRIGAsmPrinter::getHSAILReg(Type* type) {
  std::stringstream stream;

  switch (type->getTypeID()) {
  case Type::VoidTyID:
    break;
  case Type::FloatTyID:
    stream << "$s" << reg32Counter++;
    break;
  case Type::DoubleTyID:
    stream << "$d" << reg64Counter++;
    break;
  case Type::IntegerTyID:
    if (type->isIntegerTy(1)) {
      stream << "$c" << reg1Counter++;
    } else if (type->isIntegerTy()
        && type->getScalarSizeInBits() <= 32) {
      stream << "$s" << reg32Counter++;
    } else if (type->isIntegerTy()
        && type->getScalarSizeInBits() <= 64) {
      stream << "$d" << reg64Counter++;
    } else {
      type->dump();
      assert(!"Found a case we don't handle!");
    }
    break;
  case Type::PointerTyID:
    if (Subtarget->is64Bit())
      stream << "$d" << reg64Counter++;
    else
      stream << "$s" << reg32Counter++;
    break;
  default:
    type->dump();
    assert(!"Found a case we don't handle!");
    break;
  };

  return stream.str();
}

/// isBlockOnlyReachableByFallthough - Return true if the basic block has
/// exactly one predecessor and the control transfer mechanism between
/// the predecessor and this block is a fall-through.
bool BRIGAsmPrinter::isBlockOnlyReachableByFallthrough(
     const MachineBasicBlock *MBB) const {
  return AsmPrinter::isBlockOnlyReachableByFallthrough(MBB);
}

//===------------------------------------------------------------------===//
// Dwarf Emission Helper Routines
//===------------------------------------------------------------------===//

/// getDebugValueLocation - Get location information encoded by DBG_VALUE
/// operands.
MachineLocation BRIGAsmPrinter::getDebugValueLocation(const MachineInstr *MI)
                                                      const {
  MachineLocation Location;
  assert(!"When do we hit this?");
  return Location;
}

/// getISAEncoding - Get the value for DW_AT_APPLE_isa. Zero if no isa
/// encoding specified.
unsigned BRIGAsmPrinter::getISAEncoding() {
  return 0;
}

/// Returns true and the offset of %privateStack BRIG variable, or false
/// if there is no local stack
bool BRIGAsmPrinter::getPrivateStackOffset(uint64_t *privateStackOffset) const {
  if (privateStackBRIGOffset != 0) {
    *privateStackOffset = privateStackBRIGOffset;
    return true;
  }
  return false;
}

/// Returns true and the offset of %spillStack BRIG variable, or false
/// if there is no stack for spills
bool BRIGAsmPrinter::getSpillStackOffset(uint64_t *spillStackOffset) const {
  if (spillStackBRIGOffset != 0) {
    *spillStackOffset = spillStackBRIGOffset;
    return true;
  }
  return false;
}

/// This function is used to translate stack objects' offsets reported by
/// MachineFrameInfo to actual offsets in the %privateStack array
bool BRIGAsmPrinter::getLocalVariableStackOffset(int varOffset,
                                                 int *stackOffset) const {
  stack_map_iterator i = LocalVarMapforStack.find(varOffset);
  if (i != LocalVarMapforStack.end()) {
    *stackOffset = i->second;
    return true;
  }
  return false;
}

/// This function is used to translate stack objects' offsets reported by
/// MachineFrameInfo to actual offsets in the %spill array
bool BRIGAsmPrinter::getSpillVariableStackOffset(int varOffset, int *stackOffset) const {
  stack_map_iterator i =  spillMapforStack.find(varOffset);
  if (i != spillMapforStack.end()) {
    *stackOffset = i->second;
    return true;
  }
  return false;
}

bool BRIGAsmPrinter::getGlobalVariableOffset(const GlobalVariable* GV,
                                             uint64_t *result) const {
  gvo_iterator i = globalVariableOffsets.find(GV);
  if (i == globalVariableOffsets.end()) {
    assert(!"Unknown global variable");
    return false;
  }
  *result =  i->second;
  return true;
}

bool BRIGAsmPrinter::getGroupVariableOffset(const GlobalVariable* GV,
                                            uint64_t *result) const {
  pvgvo_const_iterator i = groupVariablesOffsets.find(GV);
  if (i == groupVariablesOffsets.end()) {
    return false;
  }
  *result =  i->second;
  return true;
}

bool BRIGAsmPrinter::getFunctionScalarArgumentOffset(const std::string& argName,
                                                     uint64_t *result) const {
  fao_iterator i = functionScalarArgumentOffsets.find(argName);
  if (i == functionScalarArgumentOffsets.end()) {
    return false;
  }
  *result = i->second;
  return true;
}

bool BRIGAsmPrinter::getFunctionVectorArgumentOffsets(const std::string& argName,
     VectorArgumentOffsets& result) const {
  fvo_iterator i = functionVectorArgumentOffsets.find(argName);
  if (i == functionVectorArgumentOffsets.end()) {
    return false;
  }
  result = i->second;
  return true;
}

void BRIGAsmPrinter::BrigEmitOperand(const MachineInstr *MI, unsigned opNum, HSAIL_ASM::Inst inst) {
  const MachineOperand &MO = MI->getOperand(opNum);

  Brig::BrigType16_t const expType = HSAIL_ASM::getOperandType(inst, m_opndList.size(),
                                       brigantine.getMachineModel(), brigantine.getProfile());

  switch (MO.getType()) {
  default:
    printf("<unknown operand type>"); break;
  case MachineOperand::MO_Register:
    m_opndList.push_back(getBrigReg(MO));
    break;
  case MachineOperand::MO_Immediate:
    if (expType==Brig::BRIG_TYPE_B1) {
      m_opndList.push_back(brigantine.createImmed(MO.getImm() != 0 ? 1 : 0, expType));
    } else {
      m_opndList.push_back(brigantine.createImmed(MO.getImm(), expType));
    }
    break;
  case MachineOperand::MO_FPImmediate: {
    const ConstantFP * CFP = MO.getFPImm();
    if (CFP->getType()->isFloatTy()) {
      m_opndList.push_back(
        brigantine.createImmed(HSAIL_ASM::f32_t::fromRawBits(
          *CFP->getValueAPF().bitcastToAPInt().getRawData()), expType));
    } else if (CFP->getType()->isDoubleTy()) {
      m_opndList.push_back(
        brigantine.createImmed(HSAIL_ASM::f64_t::fromRawBits(
          *CFP->getValueAPF().bitcastToAPInt().getRawData()), expType));
    }
    break;
  }
  }
}

void BRIGAsmPrinter::BrigEmitOperandLdStAddress(const MachineInstr *MI, unsigned opNum) 
{
  assert(opNum + 2 < MI->getNumOperands());
  const MachineOperand &base = MI->getOperand(opNum),
    &reg  = MI->getOperand(opNum+1),
    &offset_op  = MI->getOperand(opNum+2);

  // Get offset
  assert(offset_op.isImm());
  int64_t offset = offset_op.getImm();

  // Get [%name]
  std::string base_name;
  if (base.isGlobal()) {
    const GlobalValue *gv = base.getGlobal();
    std::stringstream ss;

    ss << getSymbolPrefix(*gv) << gv->getName().str();
    // Do not add offset since it will already be in offset field
    // see 'HSAILDAGToDAGISel::SelectAddrCommon'

    base_name = ss.str();
  }
  // Special cases for spill and private stack
  else if (base.isImm()) {
    int64_t addr = base.getImm();
    assert(isInt<32>(addr));

    if (spillMapforStack.find(addr) != spillMapforStack.end()) {
      base_name = "%spillStack";
      offset += spillMapforStack[addr];
    }
    else if (LocalVarMapforStack.find(addr) != LocalVarMapforStack.end()) {
      base_name = "%privateStack";
      offset += LocalVarMapforStack[addr];
    }
    else
      assert("Immediate base address: neither spill nor private stack" && 0);
  }
  // Kernel or function argument
  else if (base.isSymbol()) {
    base_name = "%";
    base_name.append(base.getSymbolName());
  }
  // Get [$reg]
  HSAIL_ASM::SRef reg_name;
  if (reg.isReg() && reg.getReg() != 0) {
    reg_name = HSAIL_ASM::SRef(getRegisterName(reg.getReg()));
  }

  // Emit operand
  m_opndList.push_back(brigantine.createRef(base_name, reg_name, offset));
}

void BRIGAsmPrinter::BrigEmitQualifiers(const MachineInstr *MI, unsigned opNum,
                                        HSAIL_ASM::Inst inst_) {
  HSAIL_ASM::InstMem inst = inst_;
  assert(inst);

  if (EnableUniformOperations && HSAIL::isLoad(MI)) {
    assert(opNum + 2 < MI->getNumOperands());

    // Emit width
    const MachineOperand &width_op = HSAIL::getWidth(MI);
    assert( width_op.isImm());
    unsigned int width  = width_op.getImm();
    assert( width == Brig::BRIG_WIDTH_1        ||
            width == Brig::BRIG_WIDTH_WAVESIZE ||
            width == Brig::BRIG_WIDTH_ALL
          );
    inst.width() = width;

    // Emit const
    unsigned AS = (*(MI->memoperands_begin()))->getPointerInfo().getAddrSpace();
    if(HSAILAS::GLOBAL_ADDRESS == AS) {
      const MachineOperand &const_op = HSAIL::getLoadConstQual(MI);
      assert( const_op.isImm());
      bool isConst = const_op.getImm();
      inst.modifier().isConst() = isConst;
    }
  }

  // Emit _align(n) attribute for loads and stores
  if (HSAIL::isLoad(MI) || HSAIL::isStore(MI)) {
    inst.align() = getBrigAlignment(HSAIL::getLdStAlign(MI).getImm());
  }
}

void BRIGAsmPrinter::BrigEmitOperandAddress(const MachineInstr *MI, unsigned opNum) 
{
  const MachineOperand &MO = MI->getOperand(opNum);

  switch (MO.getType()) {
  default:
    printf("<unknown operand type>"); break;
  case MachineOperand::MO_MachineBasicBlock: {
    std::string sLabel = MO.getMBB()->getSymbol()->getName();
    m_opndList.push_back(brigantine.createLabelRef(sLabel));
    break;
  }
  case MachineOperand::MO_ExternalSymbol: {
    std::stringstream ss;
    ss << "%" << MO.getSymbolName();
    uint64_t off = MO.getOffset();
    assert( off < INT_MAX );
    m_opndList.push_back(brigantine.createRef(ss.str(), (int)off));
    break;
  }
  }
}

void BRIGAsmPrinter::BrigEmitVecArgDeclaration(const MachineInstr *MI) {
  MachineOperand symb      = MI->getOperand(0);
  MachineOperand brig_type = MI->getOperand(1);
  MachineOperand size      = MI->getOperand(2);

  assert( symb.getType()      == MachineOperand::MO_ExternalSymbol );
  assert( brig_type.getType() == MachineOperand::MO_Immediate );
  assert( size.getType()      == MachineOperand::MO_Immediate );

  std::ostringstream stream;
  stream << "%" << symb.getSymbolName();

  unsigned num_elem = size.getImm();

  Brig::BrigTypeX brigType = (Brig::BrigTypeX)brig_type.getImm();
  HSAIL_ASM::DirectiveVariable vec_arg = (num_elem > 1 ) ?
    brigantine.addArrayVariable(stream.str(), num_elem, Brig::BRIG_SEGMENT_ARG, brigType) :
    brigantine.addVariable(stream.str(), Brig::BRIG_SEGMENT_ARG, brigType);

  vec_arg.align() = getBrigAlignment(HSAIL_ASM::getBrigTypeNumBytes(brigType) * num_elem);
  vec_arg.modifier().isDefinition() = true;
  vec_arg.allocation() = Brig::BRIG_ALLOCATION_AUTOMATIC;
  vec_arg.linkage() = Brig::BRIG_LINKAGE_ARG;

  return;
}

void BRIGAsmPrinter::BrigEmitOperandImage(const MachineInstr *MI, unsigned opNum) {
  MachineOperand object = MI->getOperand(opNum);
  unsigned idx = object.getImm();
  std::string sOp;
  // Indices for image_t and sampler_t args are biased, so now we un-bias them.
  // Note that the biased values rely on biasing performed by
  // HSAILPropagateImageOperands and HSAILISelLowering::LowerFormalArguments.
  if (idx < IMAGE_ARG_BIAS) {
    // This is the initialized sampler.
    HSAILSamplerHandle* hSampler = Subtarget->getImageHandles()->
                                     getSamplerHandle(idx);
    assert(hSampler && "Invalid sampler handle");
    std::string samplerName = hSampler->getSym();
    assert(!samplerName.empty() && "Expected symbol here");
    sOp = "&" + samplerName;
  } else {
    // This is the image
    std::string sym = Subtarget->getImageHandles()->
                        getImageSymbol(idx-IMAGE_ARG_BIAS);
    assert(!sym.empty() && "Expected symbol here");
    sOp = "%" + sym;
  }

  m_opndList.push_back(brigantine.createRef(sOp));
}

HSAIL_ASM::OperandReg BRIGAsmPrinter::getBrigReg(MachineOperand s) {
  assert(s.getType() == MachineOperand::MO_Register);
  return brigantine.createOperandReg(HSAIL_ASM::SRef(
                                       getRegisterName(s.getReg())));
}

void BRIGAsmPrinter::BrigEmitVecOperand(
                            const MachineInstr *MI, unsigned opStart,
                            unsigned numRegs) {
  assert(numRegs >=2 && numRegs <= 4);
  HSAIL_ASM::ItemList list;
  for(unsigned i=opStart; i<opStart + numRegs; ++i) {
      // \todo olsemenov 20140331 should we support immediates here?
      list.push_back(getBrigReg(MI->getOperand(i)));
  }
  m_opndList.push_back(brigantine.createOperandList(list));
}

void BRIGAsmPrinter::BrigEmitImageInst(const MachineInstr *MI,
                                       HSAIL_ASM::InstImage inst) {
  unsigned opCnt = 0;

  if (inst.geometry() == Brig::BRIG_GEOMETRY_2DDEPTH ||
      inst.geometry() == Brig::BRIG_GEOMETRY_2DADEPTH) 
  {
    BrigEmitOperand(MI, opCnt++, inst);
  } else {
    BrigEmitVecOperand(MI, opCnt, 4);
    opCnt+=4;
  }

  if (!EnableExperimentalFeatures) {
    switch(inst.opcode()) {
    case Brig::BRIG_OPCODE_RDIMAGE:
      BrigEmitOperandImage(MI, opCnt++);  // Image object itself
      BrigEmitOperandImage(MI, opCnt++);  // Sampler object
    break;
    case Brig::BRIG_OPCODE_LDIMAGE:
    case Brig::BRIG_OPCODE_STIMAGE:
      BrigEmitOperandImage(MI, opCnt++);  // Image only
    break;
    default: ;
    }
  } else { // EnableExperimentalFeatures
    switch(inst.opcode()) {
    case Brig::BRIG_OPCODE_RDIMAGE:
      BrigEmitOperand(MI, opCnt++, inst);
      BrigEmitOperand(MI, opCnt++, inst);
    break;
    case Brig::BRIG_OPCODE_LDIMAGE:
    case Brig::BRIG_OPCODE_STIMAGE:
      BrigEmitOperand(MI, opCnt++, inst);
      break;
    default: ;
    }
  }

  switch(inst.geometry()) {
  case Brig::BRIG_GEOMETRY_1D:
  case Brig::BRIG_GEOMETRY_1DB:
    BrigEmitOperand(MI, opCnt++, inst);
    break;
  case Brig::BRIG_GEOMETRY_1DA:
  case Brig::BRIG_GEOMETRY_2D:
  case Brig::BRIG_GEOMETRY_2DDEPTH:
    BrigEmitVecOperand(MI, opCnt, 2); opCnt += 2;
    break;
  case Brig::BRIG_GEOMETRY_2DA:
  case Brig::BRIG_GEOMETRY_2DADEPTH:
  case Brig::BRIG_GEOMETRY_3D:
    BrigEmitVecOperand(MI, opCnt, 3); opCnt += 3;
    break;
  }
}

bool BRIGAsmPrinter::usesGCNAtomicCounter(void) {
  // TODO_HSA: This introduces another pass over all the instrs in the
  // kernel. Need to find a more efficient way to get this info.
  for (MachineFunction::const_iterator I = MF->begin(), E = MF->end();
       I != E; ++I) {
    for (MachineBasicBlock::const_iterator II = I->begin(), IE = I->end();
         II != IE; ++II) {
      switch (II->getOpcode()) {
      default:
        continue;
      case HSAIL::gcn_atomic_append:
      case HSAIL::gcn_atomic_consume:
        return true;
      }
    }
  }
  return false;
}

char BRIGAsmPrinter::getSymbolPrefix(const GlobalValue& gv) {
  const unsigned AddrSpace = gv.getType()->getAddressSpace();
  return (HSAILAS::PRIVATE_ADDRESS==AddrSpace||
          HSAILAS::GROUP_ADDRESS==AddrSpace) ? '%' : '&';
}

Brig::BrigAlignment8_t BRIGAsmPrinter::getBrigAlignment(unsigned align_value) {
  if (align_value & (align_value-1)) {
    // Round to the next power of 2
    unsigned int i = 1;
    while (i < align_value) i <<= 1;
    align_value = i;
  }
  Brig::BrigAlignment8_t ret = HSAIL_ASM::num2align(align_value);
  assert(ret != Brig::BRIG_ALIGNMENT_LAST && "invalid alignment value");
  return ret;
}

// Force static initialization.
extern "C" void LLVMInitializeBRIGAsmPrinter() {
  RegisterAsmPrinter<BRIGAsmPrinter> X(TheHSAIL_32Target);
  RegisterAsmPrinter<BRIGAsmPrinter> Y(TheHSAIL_64Target);
}

extern "C" void LLVMInitializeHSAILAsmPrinter() {
  LLVMInitializeBRIGAsmPrinter();
}
