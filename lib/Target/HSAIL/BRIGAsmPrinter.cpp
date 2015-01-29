#include "BRIGAsmPrinter.h"
#include "BRIGDwarfDebug.h"
#include "MCTargetDesc/BRIGDwarfStreamer.h"
#include "HSAILKernelManager.h"
#include "HSAILMachineFunctionInfo.h"
#include "HSAILOpaqueTypes.h"
#include "HSAILStoreInitializer.h"
#include "HSAILTargetMachine.h"
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
#include "llvm/MC/MCAssembler.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/MC/MCObjectStreamer.h"
#include "llvm/MC/MCValue.h"
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

#include "HSAILGenMnemonicMapper.inc"
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


Brig::BrigAtomicOperation
BRIGAsmPrinter::getAtomicOpcode(const MachineInstr *MI) const {
  int64_t Val = TII->getNamedModifierOperand(*MI, HSAIL::OpName::op);
  assert(Val >= Brig::BRIG_ATOMIC_ADD && Val <= Brig::BRIG_ATOMIC_XOR);
  return static_cast<Brig::BrigAtomicOperation>(Val);
}

Brig::BrigSegment
BRIGAsmPrinter::getAtomicSegment(const MachineInstr *MI) const {
  int64_t Val = TII->getNamedModifierOperand(*MI, HSAIL::OpName::segment);
  assert(Val > 0 && Val < Brig::BRIG_SEGMENT_EXTSPACE0);
  return static_cast<Brig::BrigSegment>(Val);
}

Brig::BrigMemoryOrder
BRIGAsmPrinter::getAtomicOrder(const MachineInstr *MI) const {
  int64_t Val = TII->getNamedModifierOperand(*MI, HSAIL::OpName::order);
  assert(Val > 0 && Val <= Brig::BRIG_MEMORY_ORDER_SC_ACQUIRE_RELEASE);
  return static_cast<Brig::BrigMemoryOrder>(Val);
}

Brig::BrigMemoryScope
BRIGAsmPrinter::getAtomicScope(const MachineInstr *MI) const {
  int64_t Val = TII->getNamedModifierOperand(*MI, HSAIL::OpName::scope);
  assert(Val > 0 && Val <= Brig::BRIG_MEMORY_SCOPE_SYSTEM);
  return static_cast<Brig::BrigMemoryScope>(Val);
}

Brig::BrigTypeX BRIGAsmPrinter::getAtomicType(const MachineInstr *MI) const {
  int Val = TII->getNamedModifierOperand(*MI, HSAIL::OpName::TypeLength);
  switch (Val) {
  case Brig::BRIG_TYPE_B32:
  case Brig::BRIG_TYPE_S32:
  case Brig::BRIG_TYPE_U32:
  case Brig::BRIG_TYPE_B64:
  case Brig::BRIG_TYPE_S64:
  case Brig::BRIG_TYPE_U64:
    return static_cast<Brig::BrigTypeX>(Val);
  default:
    llvm_unreachable("Unknown BrigType");
  }
}

// FIXME: Doesn't make sense to rely on address space for this.
char BRIGAsmPrinter::getSymbolPrefixForAddressSpace(unsigned AS) {
  return (AS == HSAILAS::GROUP_ADDRESS ||
          AS == HSAILAS::PRIVATE_ADDRESS) ? '%' : '&';
}

char BRIGAsmPrinter::getSymbolPrefix(const MCSymbol &Sym) const {
  const GlobalVariable *GV = MMI->getModule()->getNamedGlobal(Sym.getName());
  assert(GV && "Need prefix for undefined GlobalVariable");

  unsigned AS = GV->getType()->getAddressSpace();
  return getSymbolPrefixForAddressSpace(AS);
}

void BRIGAsmPrinter::BrigEmitInitVarWithAddressPragma(StringRef VarName,
                                                      uint64_t BaseOffset,
                                                      const MCExpr *Expr,
                                                      unsigned EltSize) {
  SmallString<256> InitStr;
  raw_svector_ostream O(InitStr);

  MCValue Val;
  bool Res = Expr->EvaluateAsValue(Val, nullptr, nullptr);
  (void) Res;
  assert(Res && "Could not evaluate MCExpr");
  assert(!Val.getSymB() && "Multi-symbol expressions not handled");

  const MCSymbol &Sym = Val.getSymA()->getSymbol();

  O << "initvarwithaddress:" << VarName
    << ':' << BaseOffset // Offset into the destination.
    << ':' << EltSize
    << ':' << getSymbolPrefix(Sym) << Sym.getName()
    << ':' << Val.getConstant(); // Offset of the symbol being written.

  HSAIL_ASM::DirectivePragma pgm
    = brigantine.append<HSAIL_ASM::DirectivePragma>();

  StringRef Str(O.str());
  HSAIL_ASM::SRef BrigStr(Str.begin(), Str.end());
  HSAIL_ASM::ItemList opnds;

  opnds.push_back(brigantine.createOperandString(BrigStr));
  pgm.operands() = opnds;
}

void BRIGAsmPrinter::BrigEmitGlobalInit(HSAIL_ASM::DirectiveVariable globalVar,
                                        Type *EltTy,
                                        Constant *CV) {
  if (isa<UndefValue>(CV)) // Don't emit anything for undefined initializers.
    return;

  HSAIL_ASM::SRef init;
  char zeroes[32];

  unsigned EltBrigType = HSAIL_ASM::convType2BitType(globalVar.type());
  size_t typeBytes = HSAIL_ASM::getBrigTypeNumBytes(globalVar.type());

  assert(typeBytes <= sizeof(zeroes));

  // If this is a trivially null constant, we only need to emit one zero.
  if (CV->isNullValue()) {
    memset(zeroes, 0, typeBytes);
    init = HSAIL_ASM::SRef(zeroes, zeroes + typeBytes);
  } else {
    unsigned EltSize = HSAIL_ASM::getBrigTypeNumBytes(EltBrigType);

    auto Name = globalVar.name().str();

    StoreInitializer store(EltTy, *this);
    store.append(CV, Name);

    if (store.elementCount() > 0) {
      StringRef S = store.str();
      init = HSAIL_ASM::SRef(S.begin(), S.end());
    } else {
      memset(zeroes, 0, typeBytes);
      init = HSAIL_ASM::SRef(zeroes, zeroes + typeBytes);
    }

    for (const auto &VarInit : store.varInitAddresses()) {
      BrigEmitInitVarWithAddressPragma(Name,
                                       VarInit.BaseOffset,
                                       VarInit.Expr,
                                       EltSize);
    }
  }

  if (globalVar.modifier().isArray()) {
    assert(globalVar.dim() * typeBytes  >= init.length());
  } else {
    assert(globalVar.dim() == 0 && typeBytes == init.length());
  }

  globalVar.init() = brigantine.createOperandData(init);
}

BRIGAsmPrinter::BRIGAsmPrinter(TargetMachine& TM, MCStreamer &Streamer)
  : HSAILAsmPrinter(TM, Streamer),
    Subtarget(&TM.getSubtarget<HSAILSubtarget>()),
    FuncArgsStr(),
    FuncRetValStr(),
    retValCounter(0),
    paramCounter(0),
    reg1Counter(0),
    reg32Counter(0),
    reg64Counter(0),
    mTM(reinterpret_cast<HSAILTargetMachine*>(&TM)),
    TII(Subtarget->getInstrInfo()),
    mMeta(new HSAILKernelManager(mTM)),
    mMFI(nullptr),
    m_bIsKernel(false),
    brigantine(bc),
    mDwarfStream(nullptr),
    mBrigStream(nullptr),
    mDwarfFileStream(nullptr),
    privateStackBRIGOffset(0),
    spillStackBRIGOffset(0),
    mBuffer(0) {

  // Obtain DWARF stream.
  BRIGDwarfStreamer *DwarfStreamer = dyn_cast<BRIGDwarfStreamer>(&OutStreamer);
  assert(DwarfStreamer &&
         "BRIG lowering doesn't work with this kind of streamer");
  mDwarfStream = DwarfStreamer->getDwarfStream();

  // Obtain stream for streaming BRIG that came from llc.
  mBrigStream = mDwarfStream->getOtherStream();

  // Disconnect DWARF stream from BRIG stream.
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

Brig::BrigSegment8_t BRIGAsmPrinter::getHSAILSegment(unsigned AddressSpace)
                                                     const {
  switch (AddressSpace) {
  case HSAILAS::PRIVATE_ADDRESS:  return Brig::BRIG_SEGMENT_PRIVATE;
  case HSAILAS::GLOBAL_ADDRESS:   return Brig::BRIG_SEGMENT_GLOBAL;
  case HSAILAS::CONSTANT_ADDRESS: return Brig::BRIG_SEGMENT_READONLY;
  case HSAILAS::GROUP_ADDRESS:    return Brig::BRIG_SEGMENT_GROUP;
  case HSAILAS::FLAT_ADDRESS:     return Brig::BRIG_SEGMENT_FLAT;
  case HSAILAS::REGION_ADDRESS:   return Brig::BRIG_SEGMENT_EXTSPACE0;
  case HSAILAS::KERNARG_ADDRESS:  return Brig::BRIG_SEGMENT_KERNARG;
  case HSAILAS::ARG_ADDRESS:      return Brig::BRIG_SEGMENT_ARG;
  case HSAILAS::SPILL_ADDRESS:    return Brig::BRIG_SEGMENT_SPILL;
  }
  llvm_unreachable("Unexpected BRIG address space value");
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

/// EmitGlobalVariable - Emit the specified global variable to the .s file.
void BRIGAsmPrinter::EmitGlobalVariable(const GlobalVariable *GV)
{
  if (HSAIL::isIgnoredGV(GV))
    return;

  const DataLayout& DL = getDataLayout();
  std::stringstream ss;

  unsigned AS = GV->getType()->getAddressSpace();
  ss << getSymbolPrefixForAddressSpace(AS) << GV->getName();

  string nameString = ss.str();


  // Initializer has pointer element type.
  Type *InitTy = GV->getType()->getElementType();

  unsigned NElts = 0;
  Type *EltTy = analyzeType(InitTy, NElts, DL, GV->getContext());

  // TODO_HSA: pending BRIG_LINKAGE_STATIC implementation in the Finalizer
  HSAIL_ASM::DirectiveVariable globalVar =
    brigantine.addVariable(nameString, getHSAILSegment(GV),
                           HSAIL::getBrigType(EltTy, DL));

  globalVar.linkage() = GV->isExternalLinkage(GV->getLinkage()) ?
      Brig::BRIG_LINKAGE_PROGRAM : ( GV->isInternalLinkage(GV->getLinkage()) ?
     Brig::BRIG_LINKAGE_MODULE : Brig::BRIG_LINKAGE_NONE );
  globalVar.allocation() = Brig::BRIG_ALLOCATION_AGENT;
  globalVar.modifier().isDefinition() = 1;

  globalVar.modifier().isArray() = (NElts != 0);
  globalVar.dim() = NElts;

  // Align arrays at least by 4 bytes
  unsigned align_value = std::max((globalVar.dim() > 1) ? 4U : 0U,
    std::max(GV->getAlignment(),
             HSAIL::HSAILgetAlignTypeQualifier(GV->getType()->getElementType(), DL, true)));
  globalVar.align() = getBrigAlignment(align_value);

  globalVariableOffsets[GV] = globalVar.brigOffset();
#if 0
  printf("GV %s[%p] is at offset %lu\n", nameString.c_str(), (const void*)(GV),
         (unsigned long)(globalVar.brigOffset()));
#endif

  // TODO_HSA: if group memory has initializer, then emit instructions to
  // initialize dynamically
  if (GV->hasInitializer() && canInitHSAILAddressSpace(GV)) {
    BrigEmitGlobalInit(globalVar, EltTy, (Constant *)GV->getInitializer());
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

void BRIGAsmPrinter::EmitBasicBlockStart(const MachineBasicBlock &MBB) {
  std::string StrStorage;
  raw_string_ostream o(StrStorage);
  bool insert_spaces = false;

  if (MBB.pred_empty() || isBlockOnlyReachableByFallthrough(&MBB)) {
    o << "// BB#" << MBB.getNumber() << ":";
    insert_spaces = true;
  } else {
    StringRef name = MBB.getSymbol()->getName();
    brigantine.addLabel(HSAIL_ASM::SRef(name.begin(), name.end()));
  }

  if (const BasicBlock *BB = MBB.getBasicBlock()) {
    if (BB->hasName()) {
      if (insert_spaces)
        o << "                                ";
      o << "// %" << BB->getName();
    }
  }

  const std::string &Str = o.str();
  if (!Str.empty())
    brigantine.addComment(Str.c_str());

  AsmPrinter::EmitBasicBlockStart(MBB);
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

// FIXME: Should get encoding from getBinaryCodeForInstr
static Brig::BrigOpcode getInstBasicBrigOpcode(unsigned Opc) {
  switch (Opc) {
  case HSAIL::mov:
    return Brig::BRIG_OPCODE_MOV;
  case HSAIL::shl_inst:
    return Brig::BRIG_OPCODE_SHL;
  case HSAIL::shr_inst:
    return Brig::BRIG_OPCODE_SHR;
  case HSAIL::and_inst:
    return Brig::BRIG_OPCODE_AND;
  case HSAIL::or_inst:
    return Brig::BRIG_OPCODE_OR;
  case HSAIL::xor_inst:
    return Brig::BRIG_OPCODE_XOR;
  case HSAIL::not_inst:
    return Brig::BRIG_OPCODE_NOT;
  case HSAIL::neg:
    return Brig::BRIG_OPCODE_NEG;
  case HSAIL::cmov_inst:
    return Brig::BRIG_OPCODE_CMOV;
  case HSAIL::rem_inst:
    return Brig::BRIG_OPCODE_REM;
  case HSAIL::mad_inst:
    return Brig::BRIG_OPCODE_MAD;
  case HSAIL::mulhi_inst:
    return Brig::BRIG_OPCODE_MULHI;
  case HSAIL::nsqrt_inst:
    return Brig::BRIG_OPCODE_NSQRT;
  case HSAIL::nrsqrt_inst:
    return Brig::BRIG_OPCODE_NRSQRT;
  case HSAIL::nrcp_inst:
    return Brig::BRIG_OPCODE_NRCP;
  case HSAIL::nsin_inst:
    return Brig::BRIG_OPCODE_NSIN;
  case HSAIL::ncos_inst:
    return Brig::BRIG_OPCODE_NCOS;
  case HSAIL::nexp2_inst:
    return Brig::BRIG_OPCODE_NEXP2;
  case HSAIL::nlog2_inst:
    return Brig::BRIG_OPCODE_NLOG2;
  case HSAIL::nfma_inst:
    return Brig::BRIG_OPCODE_NFMA;
  case HSAIL::bitselect_inst:
    return Brig::BRIG_OPCODE_BITSELECT;
  case HSAIL::bitextract_inst:
    return Brig::BRIG_OPCODE_BITEXTRACT;
  case HSAIL::mul24_inst:
    return Brig::BRIG_OPCODE_MUL24;
  case HSAIL::mad24_inst:
    return Brig::BRIG_OPCODE_MAD24;
  case HSAIL::bitalign_inst:
    return Brig::BRIG_OPCODE_BITALIGN;
  case HSAIL::bytealign_inst:
    return Brig::BRIG_OPCODE_BYTEALIGN;
  case HSAIL::lerp_inst:
    return Brig::BRIG_OPCODE_LERP;
  case HSAIL::gcn_fldexp_inst:
    return Brig::BRIG_OPCODE_GCNFLDEXP;
  case HSAIL::gcn_mqsad_inst:
    return Brig::BRIG_OPCODE_GCNMQSAD;
  case HSAIL::gcn_msad_inst:
    return Brig::BRIG_OPCODE_GCNMSAD;
  case HSAIL::gcn_sadw_inst:
    return Brig::BRIG_OPCODE_GCNSADW;
  case HSAIL::gcn_sadd_inst:
    return Brig::BRIG_OPCODE_GCNSADD;
  case HSAIL::gcn_min3_inst:
    return Brig::BRIG_OPCODE_GCNMIN3;
  case HSAIL::gcn_max3_inst:
    return Brig::BRIG_OPCODE_GCNMAX3;
  case HSAIL::gcn_med3_inst:
    return Brig::BRIG_OPCODE_GCNMED3;
  default:
    llvm_unreachable("unhandled opcode");
  }
}

static Brig::BrigOpcode getInstModBrigOpcode(unsigned Opc) {
  switch (Opc) {
  case HSAIL::add_inst:
    return Brig::BRIG_OPCODE_ADD;
  case HSAIL::sub_inst:
    return Brig::BRIG_OPCODE_SUB;
  case HSAIL::mul_inst:
    return Brig::BRIG_OPCODE_MUL;
  case HSAIL::div_inst:
    return Brig::BRIG_OPCODE_DIV;
  case HSAIL::fma_inst:
    return Brig::BRIG_OPCODE_FMA;
  case HSAIL::abs_inst:
    return Brig::BRIG_OPCODE_ABS;
  case HSAIL::sqrt_inst:
    return Brig::BRIG_OPCODE_SQRT;
  case HSAIL::fract_inst:
    return Brig::BRIG_OPCODE_FRACT;
  case HSAIL::min_inst:
    return Brig::BRIG_OPCODE_MIN;
  case HSAIL::max_inst:
    return Brig::BRIG_OPCODE_MAX;
  case HSAIL::copysign_inst:
    return Brig::BRIG_OPCODE_COPYSIGN;
  default:
    llvm_unreachable("unhandled opcode");
  }
}

static Brig::BrigOpcode getInstSourceTypeBrigOpcode(unsigned Opc) {
  switch (Opc) {
  case HSAIL::popcount_inst:
    return Brig::BRIG_OPCODE_POPCOUNT;
  case HSAIL::firstbit_inst:
    return Brig::BRIG_OPCODE_FIRSTBIT;
  case HSAIL::lastbit_inst:
    return Brig::BRIG_OPCODE_LASTBIT;
  case HSAIL::packcvt_inst:
    return Brig::BRIG_OPCODE_PACKCVT;
  case HSAIL::unpackcvt_inst:
    return Brig::BRIG_OPCODE_UNPACKCVT;
  case HSAIL::sad_inst:
    return Brig::BRIG_OPCODE_SAD;
  case HSAIL::sadhi_inst:
    return Brig::BRIG_OPCODE_SADHI;
  case HSAIL::pack_inst:
    return Brig::BRIG_OPCODE_PACK;
  default:
    llvm_unreachable("unhandled opcode");
  }
}

HSAIL_ASM::Inst BRIGAsmPrinter::EmitInstructionImpl(const MachineInstr *II) {
  // autoCodeEmitter will emit required amount of bytes in corresponding MCSection
  autoCodeEmitter ace(&OutStreamer, &brigantine);

  unsigned Opc = II->getOpcode();

  if (TII->isInstBasic(Opc)) {
    // FIXME: We should be able to get the encoding / Brig value from MC.
    Brig::BrigOpcode Encoding = getInstBasicBrigOpcode(Opc);

    HSAIL_ASM::InstBasic inst
      = brigantine.addInst<HSAIL_ASM::InstBasic>(Encoding);

    inst.type() = TII->getNamedOperand(*II, HSAIL::OpName::TypeLength)->getImm();

    // All have dest as first operand.
    BrigEmitOperand(II, 0, inst);

    int Src0Idx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src0);
    BrigEmitOperand(II, Src0Idx, inst);

    int Src1Idx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src1);
    if (Src1Idx != -1)
      BrigEmitOperand(II, Src1Idx, inst);

    int Src2Idx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src2);
    if (Src2Idx != -1)
      BrigEmitOperand(II, Src2Idx, inst);

    return inst;
  }

  if (TII->isInstMod(Opc)) {
    // FIXME: We should be able to get the encoding / Brig value from MC.
    // FIXME: Some instructions are available as InstBasic if they don't use
    // modifiers.
    return BrigEmitModInst(*II, getInstModBrigOpcode(Opc));
  }

  if (TII->isInstSourceType(Opc))
    return BrigEmitSourceTypeInst(*II, getInstSourceTypeBrigOpcode(Opc));

  if (HSAIL::isAtomicOp(II)) {
    bool hasRet = HSAIL::isRetAtomicOp(II);
    Brig::BrigTypeX btype = getAtomicType(II);
    unsigned brigAtomicOp = hasRet ? Brig::BRIG_OPCODE_ATOMIC :
                                     Brig::BRIG_OPCODE_ATOMICNORET;
    HSAIL_ASM::InstAtomic instAtomic =
        brigantine.addInst<HSAIL_ASM::InstAtomic>(brigAtomicOp, btype);

    instAtomic.atomicOperation() = getAtomicOpcode(II);
    instAtomic.segment() = getAtomicSegment(II);
    instAtomic.memoryOrder() = getAtomicOrder(II);
    instAtomic.memoryScope() = getAtomicScope(II);
    instAtomic.equivClass() = 0;

    if (hasRet)
      BrigEmitOperand(II, 0, instAtomic);

    int AddressIdx = HSAIL::getNamedOperandIdx(II->getOpcode(),
                                               HSAIL::OpName::address);
    BrigEmitOperandLdStAddress(II, AddressIdx);
    if (HSAIL::isTernaryAtomicOp(II)) {
      BrigEmitOperand(II, II->getNumOperands() - 2, instAtomic);
    }
    if (HSAIL::isTernaryAtomicOp(II) ||
        HSAIL::isBinaryAtomicOp(II)) {
      BrigEmitOperand(II, II->getNumOperands() - 1, instAtomic);
    }
    return instAtomic;
  }

  if (HSAIL::isImageInst(II)) {
    const char *AsmStr = getInstMnemonic(II);
    HSAIL_ASM::InstImage inst = HSAIL_ASM::parseMnemo(AsmStr, brigantine);
    BrigEmitImageInst(II, inst);
    return inst;
  }

  if (HSAIL::isCrosslaneInst(II)) {
    const char *AsmStr = getInstMnemonic(II);
    HSAIL_ASM::Inst inst = HSAIL_ASM::parseMnemo(AsmStr, brigantine);
    BrigEmitVecOperand(II, 0, 4, inst);
    BrigEmitOperand(II, 4, inst);
    return inst;
  }

  switch(II->getOpcode()) {
  default: {
    const char *AsmStr = getInstMnemonic(II);
    HSAIL_ASM::Inst inst = HSAIL_ASM::parseMnemo(AsmStr, brigantine);
    unsigned NumOperands = II->getNumOperands();
    for (unsigned OpNum=0; OpNum != NumOperands; ++OpNum) {
      BrigEmitOperand(II, OpNum, inst);
    }
    return inst;
  }
  case HSAIL::cvt: {
    HSAIL_ASM::InstCvt cvt
      = brigantine.addInst<HSAIL_ASM::InstCvt>(Brig::BRIG_OPCODE_CVT);

    cvt.type()
      = TII->getNamedOperand(*II, HSAIL::OpName::destTypedestLength)->getImm();
    cvt.sourceType()
      = TII->getNamedOperand(*II, HSAIL::OpName::srcTypesrcLength)->getImm();

    // XXX - srcTypesrcLength, destTypedestLength - These names are awful
    cvt.modifier().ftz()
      = TII->getNamedOperand(*II, HSAIL::OpName::ftz)->getImm();
    cvt.modifier().round()
      = TII->getNamedOperand(*II, HSAIL::OpName::round)->getImm();

    assert(HSAIL::getNamedOperandIdx(II->getOpcode(), HSAIL::OpName::dest) == 0);
    BrigEmitOperand(II,
                    HSAIL::getNamedOperandIdx(II->getOpcode(), HSAIL::OpName::dest),
                    cvt);

    BrigEmitOperand(II,
                    HSAIL::getNamedOperandIdx(II->getOpcode(), HSAIL::OpName::src),
                    cvt);
    return cvt;
  }
  case HSAIL::rint:
    return BrigEmitModInst(*II, Brig::BRIG_OPCODE_RINT);
  case HSAIL::floor:
    return BrigEmitModInst(*II, Brig::BRIG_OPCODE_FLOOR);
  case HSAIL::ceil:
    return BrigEmitModInst(*II, Brig::BRIG_OPCODE_CEIL);
  case HSAIL::trunc_hsail:
    return BrigEmitModInst(*II, Brig::BRIG_OPCODE_TRUNC);
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
        brigantine.createExecutableRef(std::string("&") + gv->getName().str()));
      m_opndList.push_back(
        brigantine.createCodeList(call_paramlist));

      return call;
  }

  case HSAIL::lda_32:
  case HSAIL::lda_64: {
    HSAIL_ASM::InstAddr lda = brigantine
      .addInst<HSAIL_ASM::InstAddr>(Brig::BRIG_OPCODE_LDA);
    BrigEmitOperand(II, 0, lda);
    BrigEmitOperandLdStAddress(II, 1);
    lda.segment() = TII->getNamedOperand(*II, HSAIL::OpName::segment)->getImm();
    lda.type() = (II->getOpcode() == HSAIL::lda_32) ? Brig::BRIG_TYPE_U32
                                                    : Brig::BRIG_TYPE_U64;
    return lda;
  }

  case HSAIL::ld_v1:
  case HSAIL::rarg_ld_v1:
    return EmitLoadOrStore(II, true, 1);

  case HSAIL::ld_v2:
  case HSAIL::rarg_ld_v2:
    return EmitLoadOrStore(II, true, 2);

  case HSAIL::ld_v3:
  case HSAIL::rarg_ld_v3:
    return EmitLoadOrStore(II, true, 3);

  case HSAIL::ld_v4:
  case HSAIL::rarg_ld_v4:
    return EmitLoadOrStore(II, true, 4);

  case HSAIL::st_v1:
    return EmitLoadOrStore(II, false, 1);

  case HSAIL::st_v2:
    return EmitLoadOrStore(II, false, 2);

  case HSAIL::st_v3:
    return EmitLoadOrStore(II, false, 3);

  case HSAIL::st_v4:
    return EmitLoadOrStore(II, false, 4);

  case HSAIL::arg_decl:
    BrigEmitVecArgDeclaration(II);
    return HSAIL_ASM::Inst();

  case HSAIL::hsail_memfence: {
    HSAIL_ASM::InstMemFence memfence =
        brigantine.addInst<HSAIL_ASM::InstMemFence>(Brig::BRIG_OPCODE_MEMFENCE,
                                                    Brig::BRIG_TYPE_NONE);
    memfence.memoryOrder() =
      TII->getNamedModifierOperand(*II, HSAIL::OpName::order);
    memfence.globalSegmentMemoryScope() =
      TII->getNamedModifierOperand(*II, HSAIL::OpName::globalscope);
    memfence.groupSegmentMemoryScope() =
      TII->getNamedModifierOperand(*II, HSAIL::OpName::groupscope);
    memfence.imageSegmentMemoryScope() =
      TII->getNamedModifierOperand(*II, HSAIL::OpName::imagescope);

    return memfence;
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
//    HSAIL_ASM::dump(bc);
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

HSAIL_ASM::DirectiveVariable BRIGAsmPrinter::EmitLocalVariable(
  const GlobalVariable *GV, Brig::BrigSegment8_t segment) {
  const DataLayout& DL = getDataLayout();

  Type *InitTy = GV->getType()->getElementType();

  unsigned NElts = 0;
  Type *type = analyzeType(InitTy, NElts, DL, GV->getContext());


  HSAIL_ASM::DirectiveVariable var;
  if (NElts != 0) {
     var = brigantine.addArrayVariable(("%" + GV->getName()).str(), NElts,
                 segment, HSAIL::getBrigType(type, getDataLayout()));
    // Align arrays at least by 4 bytes
    var.align() = getBrigAlignment(std::max((var.dim() > 1) ? 4U : 0U,
                                            std::max(GV->getAlignment(),
                                                     HSAIL::HSAILgetAlignTypeQualifier(type, getDataLayout(), true))));
  } else {
    var = brigantine.addVariable(("%" + GV->getName()).str(),
                                 segment,
                                 HSAIL::getBrigType(type, getDataLayout()));
    var.align() = getBrigAlignment(HSAIL::HSAILgetAlignTypeQualifier(type,
                                     getDataLayout(), true));
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
  unsigned local_stack_align, spill_align;
  local_stack_align = spill_align = DL.getABIIntegerTypeAlignment(32);

  spillMapforStack.clear();
  LocalVarMapforStack.clear();

  int stk_dim = MFI->getNumObjects();
  int stk_object_indx_begin = MFI->getObjectIndexBegin();
  for (int stk_indx = 0; stk_indx < stk_dim; stk_indx++) {
    int obj_index = stk_object_indx_begin + stk_indx;
    if (!MFI->isDeadObjectIndex(obj_index)) {
      if (MFI->isSpillSlotObjectIndex(obj_index)) {
        unsigned obj_align = MFI->getObjectAlignment(obj_index);
        spill_size = (spill_size + obj_align - 1) / obj_align * obj_align;
        spillMapforStack[MFI->getObjectOffset(obj_index)] = spill_size;
        spill_size += MFI->getObjectSize(obj_index);
        spill_align = std::max(spill_align, obj_align);
      }
      else {
        unsigned obj_offset = MFI->getObjectOffset(obj_index);
        unsigned obj_align = MFI->getObjectAlignment(obj_index);
        local_stack_size = (local_stack_size + obj_align - 1) /
                           obj_align * obj_align;
        LocalVarMapforStack[obj_offset] = local_stack_size;
        unsigned obj_size = MFI->getObjectSize(obj_index);
        for (unsigned cnt = 1 ; cnt < obj_size; cnt++)
          LocalVarMapforStack[obj_offset+cnt] = local_stack_size + cnt;
        local_stack_size  += obj_size;
        local_stack_align = std::max(local_stack_align, obj_align);
      }
    }
  }
  local_stack_size = local_stack_size + MFI->getOffsetAdjustment();
  spill_size = spill_size + MFI->getOffsetAdjustment();

  if (stack_size) {
    // Dimension is in units of type length
    if (local_stack_size) {
      HSAIL_ASM::DirectiveVariable stack_for_locals =
        brigantine.addArrayVariable("%__privateStack", local_stack_size,
                     Brig::BRIG_SEGMENT_PRIVATE, Brig::BRIG_TYPE_U8);
      stack_for_locals.align() = getBrigAlignment(local_stack_align);
      stack_for_locals.allocation() = Brig::BRIG_ALLOCATION_AUTOMATIC;
      stack_for_locals.linkage() = Brig::BRIG_LINKAGE_FUNCTION;
      stack_for_locals.modifier().isDefinition() = 1;
      privateStackBRIGOffset = stack_for_locals.brigOffset();
    }
    if (spill_size) {
      HSAIL_ASM::DirectiveVariable spill = brigantine.addArrayVariable(
        "%__spillStack", spill_size, Brig::BRIG_SEGMENT_SPILL, Brig::BRIG_TYPE_U8);
      spill.align() = getBrigAlignment(spill_align);
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
  if (HSAIL::HSAILrequiresArray(type)) {
    retParam = brigantine.addArrayVariable(
      ret,
      HSAIL::getNumElementsInHSAILType(type, getDataLayout()),
      Brig::BRIG_SEGMENT_ARG,
      HSAIL::getBrigType(memType, getDataLayout(), isSExt));
  } else {
    retParam = brigantine.addVariable(
      ret,
      Brig::BRIG_SEGMENT_ARG,
      HSAIL::getBrigType(memType, getDataLayout(), isSExt));
  }
  retParam.align() = getBrigAlignment(std::max(
    HSAIL::HSAILgetAlignTypeQualifier(memType, getDataLayout(), false),
    HSAIL::HSAILgetAlignTypeQualifier(type, getDataLayout(), false)));
  brigantine.addOutputParameter(retParam);
}

uint64_t BRIGAsmPrinter::EmitFunctionArgument(Type* type, bool isKernel,
                                              const StringRef argName,
                                              bool isSExt) {
  std::string name;
  {
    raw_string_ostream stream(name);

    if (argName.empty()) {
      stream << "%arg_p" << paramCounter;
    } else {
      std::string Str = HSAILParamManager::mangleArg(Mang, argName);
      stream << '%' << Str;
    }
  }

  paramCounter++;

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
    // Handle bit argument as DWORD
    Type* memType = type->getScalarType();
    if (memType->isIntegerTy(1))
      memType = Type::getInt32Ty(type->getContext());
    if (HSAIL::HSAILrequiresArray(type)) {
      uint64_t num_elem = HSAIL::getNumElementsInHSAILType(type, getDataLayout());
      // TODO_HSA: w/a for RT bug, remove when RT is fixed.
      // RT passes vec3 as 3 elements, not vec4 as required by OpenCL spec.
      if (isKernel && type->isVectorTy())
        num_elem = type->getVectorNumElements();

      sym = brigantine.addArrayVariable(
        name, num_elem, symSegment,
        HSAIL::getBrigType(memType, getDataLayout(), isSExt));
      // TODO_HSA: workaround for RT bug.
      // RT does not read argument alignment from BRIG, so if we align vectors
      // on a full vector size that will cause mismatch between kernarg offsets
      // in RT and finalizer.
      // The line below has to be removed as soon as RT is fixed.
      if (isKernel && type->isVectorTy())
        type = type->getVectorElementType();
    } else {
      sym = brigantine.addVariable(name, symSegment,
                          HSAIL::getBrigType(memType, getDataLayout(), isSExt));
    }
    sym.align() = getBrigAlignment(
      std::max(HSAIL::HSAILgetAlignTypeQualifier(type, getDataLayout(), false),
               HSAIL::HSAILgetAlignTypeQualifier(memType, getDataLayout(), false)));
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

  std::string NameWithPrefix;

  {
    raw_string_ostream ss(NameWithPrefix);
    ss << '&' << F->getName();
  }

  HSAIL_ASM::DirectiveExecutable fx;
  if (isKernel)
    fx = brigantine.declKernel(NameWithPrefix);
  else
    fx = brigantine.declFunc(NameWithPrefix);

  fx.linkage() = F->isExternalLinkage(F->getLinkage()) ?
    Brig::BRIG_LINKAGE_PROGRAM :
    ( F->isInternalLinkage(F->getLinkage()) ? Brig::BRIG_LINKAGE_MODULE
                                            : Brig::BRIG_LINKAGE_NONE);

  // Functions with kernel linkage cannot have output args
  if (!isKernel) {
    if (!retType->isVoidTy()) {
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

std::string BRIGAsmPrinter::getHSAILReg(Type* type) {
  std::stringstream stream;

  switch (getDataLayout().getTypeSizeInBits(type)) {
  case 32:
    stream << "$s" << reg32Counter++;
    break;
  case 64:
    stream << "$d" << reg64Counter++;
    break;
  case 1:
    stream << "$c" << reg1Counter++;
    break;
  default:
    llvm_unreachable("Unhandled type size for register");
  }

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

  int AddressIndex = HSAIL::getNamedOperandIdx(MI->getOpcode(),
                                               HSAIL::OpName::address);
  if (AddressIndex != -1) {
    unsigned addrStart = AddressIndex;
    if (opNum == addrStart) {
      BrigEmitOperandLdStAddress(MI, opNum);
      return;
    }

    // FIXME: This shouldn't be necessary
    if ((opNum > addrStart) &&
        (opNum < addrStart + HSAILADDRESS::ADDRESS_NUM_OPS))
      // Ignore rest of address fields, already emitted.
      return;
  }

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
  case MachineOperand::MO_MachineBasicBlock: {
    std::string sLabel = MO.getMBB()->getSymbol()->getName();
    m_opndList.push_back(brigantine.createLabelRef(sLabel));
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

    unsigned AS = gv->getType()->getAddressSpace();
    ss << getSymbolPrefixForAddressSpace(AS) << gv->getName().str();
    // Do not add offset since it will already be in offset field
    // see 'HSAILDAGToDAGISel::SelectAddrCommon'

    base_name = ss.str();
  }
  // Special cases for spill and private stack
  else if (base.isImm()) {
    int64_t addr = base.getImm();
    assert(isInt<32>(addr));

    if ((MI->getOpcode() == HSAIL::ld_v1) &&
        HSAIL::getBrigType(MI).getImm() == Brig::BRIG_TYPE_SAMP) {
      BrigEmitOperandImage(MI, opNum); // Constant sampler.
      return;
    }
    else if (spillMapforStack.find(addr) != spillMapforStack.end()) {
      base_name = "%__spillStack";
      offset += spillMapforStack[addr];
    }
    else if (LocalVarMapforStack.find(addr) != LocalVarMapforStack.end()) {
      base_name = "%__privateStack";
      offset += LocalVarMapforStack[addr];
    }
    else
      llvm_unreachable(
        "Immediate base address: neither spill, private stack nor sampler handle");
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

HSAIL_ASM::Inst BRIGAsmPrinter::EmitLoadOrStore(const MachineInstr *MI,
                                                bool isLoad,
                                                unsigned vec_size) {
  const MachineMemOperand *MMO = *MI->memoperands_begin();
  unsigned Segment = TII->getNamedOperand(*MI, HSAIL::OpName::segment)->getImm();

  HSAIL_ASM::InstMem inst = brigantine.addInst<HSAIL_ASM::InstMem>
    (isLoad ? Brig::BRIG_OPCODE_LD : Brig::BRIG_OPCODE_ST);

  inst.segment()    = getHSAILSegment(Segment);
  inst.type() = TII->getNamedOperand(*MI, HSAIL::OpName::TypeLength)->getImm();
  inst.align()      = getBrigAlignment(MMO->getAlignment());
  inst.width()      = isLoad ? Brig::BRIG_WIDTH_1 : Brig::BRIG_WIDTH_NONE;
  inst.equivClass() = 0;
  inst.modifier().isConst() = 0;

  if (vec_size == 1)
    BrigEmitOperand(MI, 0, inst);
  else
    BrigEmitVecOperand(MI, 0, vec_size, inst);
  BrigEmitOperandLdStAddress(MI, vec_size);

  if (EnableUniformOperations && isLoad) {
    // Emit width
    const MachineOperand &width_op = HSAIL::getWidth(MI);
    assert( width_op.isImm());
    unsigned int width  = width_op.getImm();
    assert( width == Brig::BRIG_WIDTH_1        ||
            width == Brig::BRIG_WIDTH_WAVESIZE ||
            width == Brig::BRIG_WIDTH_ALL);
    inst.width() = width;

    // Emit const
    if (Segment == HSAILAS::GLOBAL_ADDRESS) {
      const MachineOperand &Modifier = HSAIL::getLoadModifierMask(MI);
      assert(Modifier.isImm());
      inst.modifier().isConst() = Modifier.getImm() & Brig::BRIG_MEMORY_CONST;
    }
  }

  return inst;
}

void BRIGAsmPrinter::BrigEmitVecArgDeclaration(const MachineInstr *MI) {
  const MachineOperand &symb
    = *TII->getNamedOperand(*MI, HSAIL::OpName::symbol);
  const MachineOperand &brig_type
    = *TII->getNamedOperand(*MI, HSAIL::OpName::TypeLength);
  const MachineOperand &size
    = *TII->getNamedOperand(*MI, HSAIL::OpName::size);
  const MachineOperand &align
    = *TII->getNamedOperand(*MI, HSAIL::OpName::alignment);

  assert( symb.getType()      == MachineOperand::MO_ExternalSymbol );
  assert( brig_type.getType() == MachineOperand::MO_Immediate );
  assert( size.getType()      == MachineOperand::MO_Immediate );
  assert( align.getType()     == MachineOperand::MO_Immediate );

  std::ostringstream stream;
  stream << "%" << symb.getSymbolName();

  unsigned num_elem = size.getImm();

  Brig::BrigTypeX brigType = (Brig::BrigTypeX)brig_type.getImm();
  HSAIL_ASM::DirectiveVariable vec_arg = (num_elem > 1 ) ?
    brigantine.addArrayVariable(stream.str(), num_elem, Brig::BRIG_SEGMENT_ARG, brigType) :
    brigantine.addVariable(stream.str(), Brig::BRIG_SEGMENT_ARG, brigType);

  vec_arg.align() = getBrigAlignment(align.getImm());
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
                            unsigned numRegs, HSAIL_ASM::Inst inst) {
  assert(numRegs >=2 && numRegs <= 4);
  HSAIL_ASM::ItemList list;
  for(unsigned i=opStart; i<opStart + numRegs; ++i) {
      const MachineOperand &MO = MI->getOperand(i);
      if (MO.isReg()) {
        list.push_back(getBrigReg(MO));
      } else if (MO.isImm()) {
        Brig::BrigType16_t const expType =
          HSAIL_ASM::getOperandType(inst, m_opndList.size(),
            brigantine.getMachineModel(), brigantine.getProfile());
        list.push_back(brigantine.createImmed(MO.getImm(), expType));
      }
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
    BrigEmitVecOperand(MI, opCnt, 4, inst);
    opCnt+=4;
  }

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

  switch(inst.geometry()) {
  case Brig::BRIG_GEOMETRY_1D:
  case Brig::BRIG_GEOMETRY_1DB:
    BrigEmitOperand(MI, opCnt++, inst);
    break;
  case Brig::BRIG_GEOMETRY_1DA:
  case Brig::BRIG_GEOMETRY_2D:
  case Brig::BRIG_GEOMETRY_2DDEPTH:
    BrigEmitVecOperand(MI, opCnt, 2, inst); opCnt += 2;
    break;
  case Brig::BRIG_GEOMETRY_2DA:
  case Brig::BRIG_GEOMETRY_2DADEPTH:
  case Brig::BRIG_GEOMETRY_3D:
    BrigEmitVecOperand(MI, opCnt, 3, inst); opCnt += 3;
    break;
  }
}

HSAIL_ASM::InstMod BRIGAsmPrinter::BrigEmitModInst(const MachineInstr &MI,
                                                   unsigned BrigOpc) {
  HSAIL_ASM::InstMod inst = brigantine.addInst<HSAIL_ASM::InstMod>(BrigOpc);
  unsigned Opc = MI.getOpcode();

  inst.type() = TII->getNamedOperand(MI, HSAIL::OpName::TypeLength)->getImm();
  inst.modifier().ftz()
    = TII->getNamedOperand(MI, HSAIL::OpName::ftz)->getImm();
  inst.modifier().round()
    = TII->getNamedOperand(MI, HSAIL::OpName::round)->getImm();

  BrigEmitOperand(&MI, HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::dest),
                  inst);
  BrigEmitOperand(&MI, HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src0),
                  inst);

  int Src1Idx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src1);
  if (Src1Idx != -1)
    BrigEmitOperand(&MI, Src1Idx, inst);

  int Src2Idx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src2);
  if (Src2Idx != -1)
    BrigEmitOperand(&MI, Src2Idx, inst);

  return inst;
}

HSAIL_ASM::InstSourceType
BRIGAsmPrinter::BrigEmitSourceTypeInst(const MachineInstr &MI,
                                       unsigned BrigOpc) {
  HSAIL_ASM::InstSourceType inst
    = brigantine.addInst<HSAIL_ASM::InstSourceType>(BrigOpc);

  unsigned Opc = MI.getOpcode();

  inst.type() = TII->getNamedOperand(MI, HSAIL::OpName::TypeLength)->getImm();
  inst.sourceType()
    = TII->getNamedOperand(MI, HSAIL::OpName::sourceType)->getImm();

  assert(HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::dest) == 0);
  assert(HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src0) == 1);

  BrigEmitOperand(&MI, HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::dest),
                  inst);
  BrigEmitOperand(&MI, HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src0),
                  inst);

  int Src1Idx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src1);
  if (Src1Idx != -1)
    BrigEmitOperand(&MI, Src1Idx, inst);

  int Src2Idx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src2);
  if (Src2Idx != -1)
    BrigEmitOperand(&MI, Src2Idx, inst);

  int Src3Idx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src3);
  if (Src3Idx != -1)
    BrigEmitOperand(&MI, Src3Idx, inst);

  return inst;
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

Brig::BrigAlignment8_t BRIGAsmPrinter::getBrigAlignment(unsigned AlignVal) {
  // Round to the next power of 2.
  unsigned Rounded = RoundUpToAlignment(AlignVal, NextPowerOf2(AlignVal - 1));

  Brig::BrigAlignment8_t ret = HSAIL_ASM::num2align(Rounded);
  assert(ret != Brig::BRIG_ALIGNMENT_LAST && "invalid alignment value");
  return ret;
}

// Force static initialization.
extern "C" void LLVMInitializeBRIGAsmPrinter() {
  RegisterAsmPrinter<BRIGAsmPrinter> X(TheHSAIL_32Target);
  RegisterAsmPrinter<BRIGAsmPrinter> Y(TheHSAIL_64Target);
}
