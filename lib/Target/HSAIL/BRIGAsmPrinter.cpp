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

#include "libHSAIL/HSAILDisassembler.h"
#include "libHSAIL/HSAILDump.h"
#include "libHSAIL/HSAILParser.h"
#include "libHSAIL/HSAILValidator.h"

#include <memory>

using namespace llvm;

#include "HSAILGenMnemonicMapper.inc"
#define GET_LLVM_INTRINSIC_FOR_GCC_BUILTIN
#include "HSAILGenIntrinsics.inc"
#undef GET_LLVM_INTRINSIC_FOR_GCC_BUILTIN

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


static HSAIL_ASM::SRef makeSRef(const SmallVectorImpl<char> &Str) {
  return HSAIL_ASM::SRef(Str.begin(), Str.end());
}

static HSAIL_ASM::SRef makeSRef(StringRef Str) {
  return HSAIL_ASM::SRef(Str.begin(), Str.end());
}

BrigAtomicOperation
BRIGAsmPrinter::getAtomicOpcode(const MachineInstr *MI) const {
  int64_t Val = TII->getNamedModifierOperand(*MI, HSAIL::OpName::op);
  assert(Val >= BRIG_ATOMIC_ADD && Val <= BRIG_ATOMIC_XOR);
  return static_cast<BrigAtomicOperation>(Val);
}

BrigSegment
BRIGAsmPrinter::getAtomicSegment(const MachineInstr *MI) const {
  int64_t Val = TII->getNamedModifierOperand(*MI, HSAIL::OpName::segment);
  assert(Val > 0 && Val < BRIG_SEGMENT_AMD_GCN);
  return static_cast<BrigSegment>(Val);
}

BrigMemoryOrder
BRIGAsmPrinter::getAtomicOrder(const MachineInstr *MI) const {
  int64_t Val = TII->getNamedModifierOperand(*MI, HSAIL::OpName::order);
  assert(Val > 0 && Val <= BRIG_MEMORY_ORDER_SC_ACQUIRE_RELEASE);
  return static_cast<BrigMemoryOrder>(Val);
}

BrigMemoryScope
BRIGAsmPrinter::getAtomicScope(const MachineInstr *MI) const {
  int64_t Val = TII->getNamedModifierOperand(*MI, HSAIL::OpName::scope);
  assert(Val > 0 && Val <= BRIG_MEMORY_SCOPE_SYSTEM);
  return static_cast<BrigMemoryScope>(Val);
}

BrigType BRIGAsmPrinter::getAtomicType(const MachineInstr *MI) const {
  int Val = TII->getNamedModifierOperand(*MI, HSAIL::OpName::TypeLength);
  switch (Val) {
  case BRIG_TYPE_B32:
  case BRIG_TYPE_S32:
  case BRIG_TYPE_U32:
  case BRIG_TYPE_B64:
  case BRIG_TYPE_S64:
  case BRIG_TYPE_U64:
    return static_cast<BrigType>(Val);
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

  HSAIL_ASM::ItemList opnds;

  opnds.push_back(brigantine.createOperandString(makeSRef(O.str())));
  pgm.operands() = opnds;
}

void BRIGAsmPrinter::BrigEmitGlobalInit(HSAIL_ASM::DirectiveVariable globalVar,
                                        Type *EltTy,
                                        Constant *CV) {
  if (isa<UndefValue>(CV)) // Don't emit anything for undefined initializers.
    return;

  BrigType EltBT
    = static_cast<BrigType>(globalVar.type() & ~BRIG_TYPE_ARRAY);

  size_t typeBytes = HSAIL_ASM::getBrigTypeNumBytes(EltBT);

  bool isArray = globalVar.type() & BRIG_TYPE_ARRAY;
  // If this is a trivially null constant, we only need to emit one zero.
  if (CV->isNullValue()) {
    unsigned NElts = globalVar.dim();
    if (NElts == 0)
      NElts = 1;

    uint64_t Size = NElts * typeBytes;
    std::unique_ptr<char[]> Zeros(new char[Size]());

    // FIXME: Should not have to allocate a zero array for this.
    HSAIL_ASM::SRef init(Zeros.get(), Zeros.get() + Size);
    globalVar.init() = brigantine.createOperandConstantBytes(init, EltBT, isArray);
    return;
  }

  unsigned EltSize = HSAIL_ASM::getBrigTypeNumBytes(EltBT);

  auto Name = globalVar.name().str();

  StoreInitializer store(EltTy, *this);
  store.append(CV, Name);

  if (store.elementCount() > 0) {
    globalVar.init()
      = brigantine.createOperandConstantBytes(makeSRef(store.str()),
                                              EltBT,
                                              isArray);
  } else {
    uint64_t Size = globalVar.dim() * typeBytes;
    std::unique_ptr<char[]> Zeros(new char[Size]());

    HSAIL_ASM::SRef init(Zeros.get(), Zeros.get() + Size);
    globalVar.init() = brigantine.createOperandConstantBytes(init, EltBT, isArray);
  }

  for (const auto &VarInit : store.varInitAddresses()) {
    BrigEmitInitVarWithAddressPragma(Name,
                                     VarInit.BaseOffset,
                                     VarInit.Expr,
                                     EltSize);
  }
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

BrigSegment8_t BRIGAsmPrinter::getHSAILSegment(unsigned AddressSpace)
                                                     const {
  switch (AddressSpace) {
  case HSAILAS::PRIVATE_ADDRESS:  return BRIG_SEGMENT_PRIVATE;
  case HSAILAS::GLOBAL_ADDRESS:   return BRIG_SEGMENT_GLOBAL;
  case HSAILAS::CONSTANT_ADDRESS: return BRIG_SEGMENT_READONLY;
  case HSAILAS::GROUP_ADDRESS:    return BRIG_SEGMENT_GROUP;
  case HSAILAS::FLAT_ADDRESS:     return BRIG_SEGMENT_FLAT;
  case HSAILAS::REGION_ADDRESS:   return BRIG_SEGMENT_AMD_GCN;
  case HSAILAS::KERNARG_ADDRESS:  return BRIG_SEGMENT_KERNARG;
  case HSAILAS::ARG_ADDRESS:      return BRIG_SEGMENT_ARG;
  case HSAILAS::SPILL_ADDRESS:    return BRIG_SEGMENT_SPILL;
  }
  llvm_unreachable("Unexpected BRIG address space value");
}

BrigSegment8_t BRIGAsmPrinter::getHSAILSegment(const GlobalVariable* gv)
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

static BrigLinkage findGlobalBrigLinkage(const GlobalValue &GV) {
  switch (GV.getLinkage()) {
  case GlobalValue::InternalLinkage:
  case GlobalValue::PrivateLinkage:
  case GlobalValue::LinkOnceODRLinkage:
  case GlobalValue::LinkOnceAnyLinkage:
  case GlobalValue::CommonLinkage:
    return BRIG_LINKAGE_MODULE;

  case GlobalValue::ExternalLinkage:
  case GlobalValue::WeakAnyLinkage:
  case GlobalValue::WeakODRLinkage:
  case GlobalValue::AvailableExternallyLinkage:
  case GlobalValue::ExternalWeakLinkage:
  case GlobalValue::AppendingLinkage:
    return BRIG_LINKAGE_PROGRAM;

  default:
    return BRIG_LINKAGE_NONE;
  }
}

/// EmitGlobalVariable - Emit the specified global variable to the .s file.
void BRIGAsmPrinter::EmitGlobalVariable(const GlobalVariable *GV)
{
  if (HSAIL::isIgnoredGV(GV))
    return;

  const DataLayout& DL = getDataLayout();

  SmallString<256> NameStr;
  unsigned AS = GV->getType()->getAddressSpace();
  NameStr += getSymbolPrefixForAddressSpace(AS);
  NameStr += GV->getName();


  // Initializer has pointer element type.
  Type *InitTy = GV->getType()->getElementType();

  unsigned NElts = 0;
  Type *EltTy = analyzeType(InitTy, NElts, DL, GV->getContext());

  HSAIL_ASM::DirectiveVariable globalVar;
  // TODO_HSA: pending BRIG_LINKAGE_STATIC implementation in the Finalizer
  if (NElts == 0) {
    globalVar = brigantine.addVariable(makeSRef(NameStr),
                                       getHSAILSegment(GV),
                                       HSAIL::getBrigType(EltTy, DL));
  } else {
    globalVar = brigantine.addArrayVariable(makeSRef(NameStr),
                                            NElts,
                                            getHSAILSegment(GV),
                                            HSAIL::getBrigType(EltTy, DL));
  }

  globalVar.linkage() = findGlobalBrigLinkage(*GV);
  globalVar.allocation() = BRIG_ALLOCATION_AGENT;
  globalVar.modifier().isDefinition() = 1;
  globalVar.dim() = NElts;

  unsigned Alignment = GV->getAlignment();
  if (Alignment == 0)
    Alignment = DL.getPrefTypeAlignment(InitTy);
  else {
    // If an alignment is specified, it must be equal to or greater than the
    // variable's natural alignment.
    Alignment = std::max(Alignment, DL.getABITypeAlignment(EltTy));
  }

  // Align arrays at least by 4 bytes
  if (Alignment == 1 && NElts != 0)
    Alignment = 4;

  globalVar.align() = getBrigAlignment(Alignment);

  globalVariableOffsets[GV] = globalVar.brigOffset();

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
  fx.linkage() = findGlobalBrigLinkage(*F);

  paramCounter = 0;
  if (!retType->isVoidTy()) {
    EmitFunctionReturn(retType, false, "ret", F->getAttributes().getRetAttributes()
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
        samplers[i]->getSym(), samplers[i]->isRO() ? BRIG_SEGMENT_READONLY
                                                   : BRIG_SEGMENT_GLOBAL);
      samplerVar.align() = BRIG_ALIGNMENT_8;
      samplerVar.allocation() = BRIG_ALLOCATION_AGENT;
      samplerVar.linkage() = BRIG_LINKAGE_MODULE;
      samplerVar.modifier().isDefinition() = 1;
      HSAIL_ASM::OperandConstantSampler samplerProps = brigantine.append<HSAIL_ASM::OperandConstantSampler>();
      // HSAIL_ASM::ItemList samplerInit;
      // samplerInit.push_back(samplerProps);
      samplerVar.init() = samplerProps;

      int ocl_init = handles->getSamplerValue(i);

      samplerProps.coord() = (ocl_init & 0x1)
            ? BRIG_COORD_NORMALIZED
            : BRIG_COORD_UNNORMALIZED;

      switch (ocl_init & 0x30) {
      default:
      case 0x10:
        samplerProps.filter() = BRIG_FILTER_NEAREST; // CLK_FILTER_NEAREST
        break;
      case 0x20:
        samplerProps.filter() = BRIG_FILTER_LINEAR; // CLK_FILTER_LINEAR
        break;
      }

      switch (ocl_init & 0xE) {
      case 0x0 : samplerProps.addressing() = BRIG_ADDRESSING_UNDEFINED;          break;  // CLK_ADDRESS_NONE
      case 0x2 : samplerProps.addressing() = BRIG_ADDRESSING_REPEAT;             break;  // CLK_ADDRESS_REPEAT
      case 0x4 : samplerProps.addressing() = BRIG_ADDRESSING_CLAMP_TO_EDGE;      break;  // CLK_ADDRESS_CLAMP_TO_EDGE
      case 0x6 : samplerProps.addressing() = BRIG_ADDRESSING_CLAMP_TO_BORDER;    break;  // CLK_ADDRESS_CLAMP
      case 0x8 : samplerProps.addressing() = BRIG_ADDRESSING_MIRRORED_REPEAT;    break;  // CLK_ADDRESS_MIRRORED_REPEAT
      }

      samplers[i]->setEmitted();
    }
  }
}

bool BRIGAsmPrinter::isMacroFunc(const MachineInstr *MI) {
  if (MI->getOpcode() != HSAIL::TARGET_CALL) {
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
    brigantine.addLabel(makeSRef(name));
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
static BrigOpcode getInstBasicBrigOpcode(unsigned Opc) {
  switch (Opc) {
  case HSAIL::MOV:
    return BRIG_OPCODE_MOV;
  case HSAIL::RET:
    return BRIG_OPCODE_RET;
  case HSAIL::SHL:
    return BRIG_OPCODE_SHL;
  case HSAIL::SHR:
    return BRIG_OPCODE_SHR;
  case HSAIL::AND:
    return BRIG_OPCODE_AND;
  case HSAIL::OR:
    return BRIG_OPCODE_OR;
  case HSAIL::XOR:
    return BRIG_OPCODE_XOR;
  case HSAIL::NOT:
    return BRIG_OPCODE_NOT;
  case HSAIL::NEG:
    return BRIG_OPCODE_NEG;
  case HSAIL::CMOV:
    return BRIG_OPCODE_CMOV;
  case HSAIL::WORKITEMABSID:
    return BRIG_OPCODE_WORKITEMABSID;
  case HSAIL::WORKGROUPID:
    return BRIG_OPCODE_WORKGROUPID;
  case HSAIL::WORKITEMID:
    return BRIG_OPCODE_WORKITEMID;
  case HSAIL::WORKGROUPSIZE:
    return BRIG_OPCODE_WORKGROUPSIZE;
  case HSAIL::CURRENTWORKGROUPSIZE:
    return BRIG_OPCODE_CURRENTWORKGROUPSIZE;
  case HSAIL::GRIDGROUPS:
    return BRIG_OPCODE_GRIDGROUPS;
  case HSAIL::GRIDSIZE:
    return BRIG_OPCODE_GRIDSIZE;
  case HSAIL::DIM:
    return BRIG_OPCODE_DIM;
  case HSAIL::WORKITEMFLATID:
    return BRIG_OPCODE_WORKITEMFLATID;
  case HSAIL::WORKITEMFLATABSID:
    return BRIG_OPCODE_WORKITEMFLATABSID;
  case HSAIL::LANEID:
    return BRIG_OPCODE_LANEID;
  case HSAIL::WAVEID:
    return BRIG_OPCODE_WAVEID;
  case HSAIL::MAXWAVEID:
    return BRIG_OPCODE_MAXWAVEID;
  case HSAIL::CLOCK:
    return BRIG_OPCODE_CLOCK;
  case HSAIL::IMAGEFENCE:
    return BRIG_OPCODE_IMAGEFENCE;
  case HSAIL::CUID:
    return BRIG_OPCODE_CUID;
  case HSAIL::REM:
    return BRIG_OPCODE_REM;
  case HSAIL::MAD:
    return BRIG_OPCODE_MAD;
  case HSAIL::MULHI:
    return BRIG_OPCODE_MULHI;
  case HSAIL::NSQRT:
    return BRIG_OPCODE_NSQRT;
  case HSAIL::NRSQRT:
    return BRIG_OPCODE_NRSQRT;
  case HSAIL::NRCP:
    return BRIG_OPCODE_NRCP;
  case HSAIL::NSIN:
    return BRIG_OPCODE_NSIN;
  case HSAIL::NCOS:
    return BRIG_OPCODE_NCOS;
  case HSAIL::NEXP2:
    return BRIG_OPCODE_NEXP2;
  case HSAIL::NLOG2:
    return BRIG_OPCODE_NLOG2;
  case HSAIL::NFMA:
    return BRIG_OPCODE_NFMA;
  case HSAIL::BITSELECT:
    return BRIG_OPCODE_BITSELECT;
  case HSAIL::BITEXTRACT:
    return BRIG_OPCODE_BITEXTRACT;
  case HSAIL::MUL24:
    return BRIG_OPCODE_MUL24;
  case HSAIL::MAD24:
    return BRIG_OPCODE_MAD24;
  case HSAIL::BITALIGN:
    return BRIG_OPCODE_BITALIGN;
  case HSAIL::BYTEALIGN:
    return BRIG_OPCODE_BYTEALIGN;
  case HSAIL::LERP:
    return BRIG_OPCODE_LERP;
  case HSAIL::KERNARGBASEPTR:
    return BRIG_OPCODE_KERNARGBASEPTR;
  case HSAIL::GCN_FLDEXP:
    return BRIG_OPCODE_GCNFLDEXP;
  case HSAIL::GCN_MQSAD:
    return BRIG_OPCODE_GCNMQSAD;
  case HSAIL::GCN_QSAD:
    return BRIG_OPCODE_GCNQSAD;
  case HSAIL::GCN_MSAD:
    return BRIG_OPCODE_GCNMSAD;
  case HSAIL::GCN_SADW:
    return BRIG_OPCODE_GCNSADW;
  case HSAIL::GCN_SADD:
    return BRIG_OPCODE_GCNSADD;
  case HSAIL::GCN_MIN3:
    return BRIG_OPCODE_GCNMIN3;
  case HSAIL::GCN_MAX3:
    return BRIG_OPCODE_GCNMAX3;
  case HSAIL::GCN_MED3:
    return BRIG_OPCODE_GCNMED3;
  case HSAIL::GCN_BFM:
    return BRIG_OPCODE_GCNBFM;
  case HSAIL::GCN_MIN:
    return BRIG_OPCODE_GCNMIN;
  case HSAIL::GCN_MAX:
    return BRIG_OPCODE_GCNMAX;
  default:
    llvm_unreachable("unhandled opcode");
  }
}

static BrigOpcode getInstModBrigOpcode(unsigned Opc) {
  switch (Opc) {
  case HSAIL::ADD:
    return BRIG_OPCODE_ADD;
  case HSAIL::SUB:
    return BRIG_OPCODE_SUB;
  case HSAIL::MUL:
    return BRIG_OPCODE_MUL;
  case HSAIL::DIV:
    return BRIG_OPCODE_DIV;
  case HSAIL::FMA:
    return BRIG_OPCODE_FMA;
  case HSAIL::ABS:
    return BRIG_OPCODE_ABS;
  case HSAIL::SQRT:
    return BRIG_OPCODE_SQRT;
  case HSAIL::FRACT:
    return BRIG_OPCODE_FRACT;
  case HSAIL::MIN:
    return BRIG_OPCODE_MIN;
  case HSAIL::MAX:
    return BRIG_OPCODE_MAX;
  case HSAIL::COPYSIGN:
    return BRIG_OPCODE_COPYSIGN;
  case HSAIL::RINT:
    return BRIG_OPCODE_RINT;
  case HSAIL::FLOOR:
    return BRIG_OPCODE_FLOOR;
  case HSAIL::CEIL:
    return BRIG_OPCODE_CEIL;
  case HSAIL::TRUNC:
    return BRIG_OPCODE_TRUNC;
  default:
    llvm_unreachable("unhandled opcode");
  }
}

static BrigOpcode getInstSourceTypeBrigOpcode(unsigned Opc) {
  switch (Opc) {
  case HSAIL::POPCOUNT:
    return BRIG_OPCODE_POPCOUNT;
  case HSAIL::FIRSTBIT:
    return BRIG_OPCODE_FIRSTBIT;
  case HSAIL::LASTBIT:
    return BRIG_OPCODE_LASTBIT;
  case HSAIL::PACKCVT:
    return BRIG_OPCODE_PACKCVT;
  case HSAIL::UNPACKCVT:
    return BRIG_OPCODE_UNPACKCVT;
  case HSAIL::SAD:
    return BRIG_OPCODE_SAD;
  case HSAIL::SADHI:
    return BRIG_OPCODE_SADHI;
  case HSAIL::PACK:
    return BRIG_OPCODE_PACK;
  case HSAIL::CLASS:
    return BRIG_OPCODE_CLASS;
  default:
    llvm_unreachable("unhandled opcode");
  }
}

static BrigOpcode getInstLaneBrigOpcode(unsigned Opc) {
  switch (Opc) {
  case HSAIL::ACTIVELANEPERMUTE:
    return BRIG_OPCODE_ACTIVELANEPERMUTE;
  case HSAIL::ACTIVELANEID:
    return BRIG_OPCODE_ACTIVELANEID;
  case HSAIL::ACTIVELANECOUNT:
    return BRIG_OPCODE_ACTIVELANECOUNT;
  case HSAIL::ACTIVELANEMASK:
    return BRIG_OPCODE_ACTIVELANEMASK;
  default:
    llvm_unreachable("unhandled opcode");
  }
}

static BrigOpcode getInstBrBrigOpcode(unsigned Opc) {
  switch (Opc) {
  case HSAIL::BR:
    return BRIG_OPCODE_BR;
  case HSAIL::CBR:
    return BRIG_OPCODE_CBR;
  case HSAIL::BARRIER:
    return BRIG_OPCODE_BARRIER;
  case HSAIL::WAVEBARRIER:
    return BRIG_OPCODE_WAVEBARRIER;
  default:
    llvm_unreachable("unhandled opcode");
  }
}

static BrigOpcode getInstSegBrigOpcode(unsigned Opc) {
  switch (Opc) {
  case HSAIL::NULLPTR:
    return BRIG_OPCODE_NULLPTR;
  default:
    llvm_unreachable("unhandled opcode");
  }
}

static BrigOpcode getInstSegCvtBrigOpcode(unsigned Opc) {
  switch (Opc) {
  case HSAIL::FTOS:
    return BRIG_OPCODE_FTOS;
  case HSAIL::STOF:
    return BRIG_OPCODE_STOF;
  case HSAIL::SEGMENTP:
    return BRIG_OPCODE_SEGMENTP;
  default:
    llvm_unreachable("unhandled opcode");
  }
}

static BrigOpcode getInstMemFenceBrigOpcode(unsigned Opc) {
  switch (Opc) {
  case HSAIL::MEMFENCE:
    return BRIG_OPCODE_MEMFENCE;
  default:
    llvm_unreachable("unhandled opcode");
  }
}

static BrigOpcode getInstAtomicBrigOpcode(unsigned Opc) {
  switch (Opc) {
  case HSAIL::ATOMIC_ADD:
  case HSAIL::ATOMIC_AND:
  case HSAIL::ATOMIC_CAS:
  case HSAIL::ATOMIC_EXCH:
  case HSAIL::ATOMIC_LD:
  case HSAIL::ATOMIC_MAX:
  case HSAIL::ATOMIC_MIN:
  case HSAIL::ATOMIC_OR:
  case HSAIL::ATOMIC_SUB:
  case HSAIL::ATOMIC_WRAPDEC:
  case HSAIL::ATOMIC_WRAPINC:
  case HSAIL::ATOMIC_XOR:
    return BRIG_OPCODE_ATOMIC;

  case HSAIL::ATOMICNORET_ADD:
  case HSAIL::ATOMICNORET_AND:
  case HSAIL::ATOMICNORET_EXCH:
  case HSAIL::ATOMICNORET_LD:
  case HSAIL::ATOMICNORET_MAX:
  case HSAIL::ATOMICNORET_MIN:
  case HSAIL::ATOMICNORET_OR:
  case HSAIL::ATOMICNORET_ST:
  case HSAIL::ATOMICNORET_SUB:
  case HSAIL::ATOMICNORET_WRAPDEC:
  case HSAIL::ATOMICNORET_WRAPINC:
  case HSAIL::ATOMICNORET_XOR:
    return BRIG_OPCODE_ATOMICNORET;
  default:
    llvm_unreachable("unhandled opcode");
  }
}

static BrigOpcode getInstCmpBrigOpcode(unsigned Opc) {
  switch (Opc) {
  case HSAIL::CMP:
    return BRIG_OPCODE_CMP;
  default:
    llvm_unreachable("unhandled opcode");
  }
}

static BrigOpcode getInstAddrBrigOpcode(unsigned Opc) {
  switch (Opc) {
  case HSAIL::LDA:
    return BRIG_OPCODE_LDA;
  case HSAIL::GCN_ATOMIC_APPEND:
    return BRIG_OPCODE_GCNAPPEND;
  case HSAIL::GCN_ATOMIC_CONSUME:
    return BRIG_OPCODE_GCNCONSUME;
  default:
    llvm_unreachable("unhandled opcode");
  }
}

static BrigOpcode getInstImageBrigOpcode(unsigned Opc) {
  switch (Opc) {
  case HSAIL::RDIMAGE:
    return BRIG_OPCODE_RDIMAGE;
  default:
    llvm_unreachable("unhandled opcode");
  }
}

static BrigOpcode getInstCvtBrigOpcode(unsigned Opc) {
  switch (Opc) {
  case HSAIL::CVT:
    return BRIG_OPCODE_CVT;
  default:
    llvm_unreachable("unhandled opcode");
  }
}

static BrigOpcode getInstMemBrigOpcode(unsigned Opc) {
  switch (Opc) {
  case HSAIL::LD_V1:
  case HSAIL::LD_V2:
  case HSAIL::LD_V3:
  case HSAIL::LD_V4:
  case HSAIL::RARG_LD_V1:
  case HSAIL::RARG_LD_V2:
  case HSAIL::RARG_LD_V3:
  case HSAIL::RARG_LD_V4:
    return BRIG_OPCODE_LD;
  case HSAIL::ST_V1:
  case HSAIL::ST_V2:
  case HSAIL::ST_V3:
  case HSAIL::ST_V4:
    return BRIG_OPCODE_ST;
  default:
    llvm_unreachable("unhandled opcode");
  }
}

HSAIL_ASM::Inst BRIGAsmPrinter::EmitInstructionImpl(const MachineInstr *II) {
  // autoCodeEmitter will emit required amount of bytes in corresponding MCSection
  autoCodeEmitter ace(&OutStreamer, &brigantine);

  unsigned Opc = II->getOpcode();

  // FIXME: We should be able to get the encoding / Brig value from MC.
  if (TII->isInstBasic(Opc))
    return BrigEmitInstBasic(*II, getInstBasicBrigOpcode(Opc));

  if (TII->isInstMod(Opc)) {
    // FIXME: We should be able to get the encoding / Brig value from MC.
    // FIXME: Some instructions are available as InstBasic if they don't use
    // modifiers.
    return BrigEmitInstMod(*II, getInstModBrigOpcode(Opc));
  }

  if (TII->isInstCmp(Opc))
    return BrigEmitInstCmp(*II, getInstCmpBrigOpcode(Opc));

  if (TII->isInstMem(Opc))
    return BrigEmitInstMem(*II, getInstMemBrigOpcode(Opc));

  if (TII->isInstCvt(Opc))
    return BrigEmitInstCvt(*II, getInstCvtBrigOpcode(Opc));

  if (TII->isInstSourceType(Opc))
    return BrigEmitInstSourceType(*II, getInstSourceTypeBrigOpcode(Opc));

  if (TII->isInstBr(Opc))
    return BrigEmitInstBr(*II, getInstBrBrigOpcode(Opc));

  if (TII->isInstMemFence(Opc))
    return BrigEmitInstMemFence(*II, getInstMemFenceBrigOpcode(Opc));

  if (TII->isInstAtomic(Opc))
    return BrigEmitInstAtomic(*II, getInstAtomicBrigOpcode(Opc));

  if (TII->isInstImage(Opc))
    return BrigEmitInstImage(*II, getInstImageBrigOpcode(Opc));

  if (TII->isInstAddr(Opc))
    return BrigEmitInstAddr(*II, getInstAddrBrigOpcode(Opc));

  if (TII->isInstLane(Opc))
    return BrigEmitInstLane(*II, getInstLaneBrigOpcode(Opc));

  if (TII->isInstSeg(Opc))
    return BrigEmitInstSeg(*II, getInstSegBrigOpcode(Opc));

  if (TII->isInstSegCvt(Opc))
    return BrigEmitInstSegCvt(*II, getInstSegCvtBrigOpcode(Opc));

  if (HSAIL::isImageInst(II)) {
    const char *AsmStr = getInstMnemonic(II);
    HSAIL_ASM::InstImage inst = HSAIL_ASM::parseMnemo(AsmStr, brigantine);
    BrigEmitImageInst(II, inst);
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
  case HSAIL::RET:
    return brigantine.addInst<HSAIL_ASM::InstBasic>(BRIG_OPCODE_RET, BRIG_TYPE_NONE);

  case HSAIL::ARG_SCOPE_START:
    brigantine.startArgScope();
    return HSAIL_ASM::Inst();

  case HSAIL::ARG_SCOPE_END:
    brigantine.endArgScope();
    return HSAIL_ASM::Inst();

  case HSAIL::TARGET_CALL:
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
                                 BRIG_OPCODE_CALL, BRIG_TYPE_NONE);
      call.width() = BRIG_WIDTH_ALL;

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
  case HSAIL::ARG_DECL:
    BrigEmitVecArgDeclaration(II);
    return HSAIL_ASM::Inst();
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
  brigantine.module(
    "&__llvm_hsail_module",
    BRIG_VERSION_HSAIL_MAJOR,
    BRIG_VERSION_HSAIL_MINOR,
    Subtarget->is64Bit() ? BRIG_MACHINE_LARGE : BRIG_MACHINE_SMALL,
    BRIG_PROFILE_FULL,
    BRIG_ROUND_FLOAT_NEAR_EVEN
  );

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
    // Actual size of captured DWARF data may be less than the size of
    // mDwarfStream's internal buffer
    const uint64_t dwarfDataSize = mDwarfStream->tell();
    assert(dwarfDataSize && "No DWARF data!"); // sanity check
    if (MMI->hasDebugInfo()) {
      // Obtain reference to data block
      HSAIL_ASM::SRef data = mDwarfStream->getData();
      // \todo1.0 get rid of data copying, stream directly into brig section
      brigantine.container().initSectionRaw(BRIG_SECTION_INDEX_IMPLEMENTATION_DEFINED, "hsa_debug");
      HSAIL_ASM::BrigSectionImpl& section = brigantine.container().sectionById(BRIG_SECTION_INDEX_IMPLEMENTATION_DEFINED);
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
    errs() << vld.getErrorMsg(NULL) << '\n';
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
  const GlobalVariable *GV, BrigSegment8_t segment) {
  const DataLayout& DL = getDataLayout();

  Type *InitTy = GV->getType()->getElementType();

  unsigned NElts = 0;
  Type *type = analyzeType(InitTy, NElts, DL, GV->getContext());

  HSAIL_ASM::DirectiveVariable var;
  if (NElts != 0) {
    BrigType BT = HSAIL::getBrigType(type, DL);

     var = brigantine.addArrayVariable(("%" + GV->getName()).str(), NElts,
                                       segment, BT & ~BRIG_TYPE_ARRAY);
    // Align arrays at least by 4 bytes
    var.align() = getBrigAlignment(std::max((var.dim() > 1) ? 4U : 0U,
                                            std::max(GV->getAlignment(),
                                                     HSAIL::getAlignTypeQualifier(type, getDataLayout(), true))));
  } else {
    var = brigantine.addVariable(("%" + GV->getName()).str(),
                                 segment,
                                 HSAIL::getBrigType(type, getDataLayout()));
    var.align() = getBrigAlignment(HSAIL::getAlignTypeQualifier(type,
                                     getDataLayout(), true));
  }
  var.allocation() = BRIG_ALLOCATION_AUTOMATIC;
  var.linkage() = BRIG_LINKAGE_FUNCTION;
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
             EmitLocalVariable(II->first, BRIG_SEGMENT_GROUP);

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
                     BRIG_SEGMENT_PRIVATE, BRIG_TYPE_U8);
      stack_for_locals.align() = getBrigAlignment(local_stack_align);
      stack_for_locals.allocation() = BRIG_ALLOCATION_AUTOMATIC;
      stack_for_locals.linkage() = BRIG_LINKAGE_FUNCTION;
      stack_for_locals.modifier().isDefinition() = 1;
      privateStackBRIGOffset = stack_for_locals.brigOffset();
    }
    if (spill_size) {
      HSAIL_ASM::DirectiveVariable spill = brigantine.addArrayVariable(
        "%__spillStack", spill_size, BRIG_SEGMENT_SPILL, BRIG_TYPE_U8);
      spill.align() = getBrigAlignment(spill_align);
      spill.allocation() = BRIG_ALLOCATION_AUTOMATIC;
      spill.linkage() = BRIG_LINKAGE_FUNCTION;
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
      BRIG_OPCODE_GCNREGIONALLOC);
    brigantine.appendOperand(gcn_region, brigantine.createImmed(4,
                             BRIG_TYPE_B32));
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
                                        StringRef RetName, bool isSExt) {
  std::string SymName("%");
  SymName += RetName;

  HSAIL_ASM::SRef ret(SymName);
  reg1Counter = 0;
  reg32Counter = 0;
  reg64Counter = 0;

  // Handle bit return as DWORD
  if (type->getScalarType()->isIntegerTy(1)) {
    assert(!type->isVectorTy() && "i1 vectors do not work");
    type = Type::getInt32Ty(type->getContext());
  }

  const DataLayout &DL = getDataLayout();

  unsigned NElts = ~0u;
  Type *EmitTy = analyzeType(type, NElts, DL, type->getContext());

  // construct return symbol
  HSAIL_ASM::DirectiveVariable retParam;
  if (NElts != 0) {
    retParam = brigantine.addArrayVariable(
      ret,
      HSAIL::getNumElementsInHSAILType(type, getDataLayout()),
      BRIG_SEGMENT_ARG,
      HSAIL::getBrigType(EmitTy, getDataLayout(), isSExt));
  } else {
    retParam = brigantine.addVariable(
      ret,
      BRIG_SEGMENT_ARG,
      HSAIL::getBrigType(EmitTy, DL, isSExt));
  }

  retParam.align() = getBrigAlignment(DL.getABITypeAlignment(type));
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

  const BrigSegment8_t symSegment = isKernel ? BRIG_SEGMENT_KERNARG
                                             : BRIG_SEGMENT_ARG;

  HSAIL_ASM::DirectiveVariable sym;

  OpaqueType OT = GetOpaqueType(type);
  // Create the symbol
  if (IsImage(OT)) {
    sym = brigantine.addImage(name, symSegment);
    sym.align() = BRIG_ALIGNMENT_8;
  } else if (OT == Sampler) {
    sym = brigantine.addSampler(name, symSegment);
    sym.align() = BRIG_ALIGNMENT_8;
  } else {
    const DataLayout &DL = getDataLayout();

    // Handle bit argument as DWORD
    // FIXME: This is incorrect.
    if (type->getScalarType()->isIntegerTy(1)) {
      assert(!type->isVectorTy() && "i1 vectors are broken");
      type = Type::getInt32Ty(type->getContext());
    }

    unsigned NElts = ~0u;
    Type *EmitTy = analyzeType(type, NElts, DL, type->getContext());

    if (NElts != 0) {
      BrigType EltTy = HSAIL::getBrigType(EmitTy, DL, isSExt);
      sym = brigantine.addArrayVariable(name, NElts, symSegment, EltTy);
    } else {
      sym = brigantine.addVariable(name, symSegment,
                          HSAIL::getBrigType(EmitTy, DL, isSExt));
    }

    sym.align() = getBrigAlignment(DL.getABITypeAlignment(type));
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
    BRIG_LINKAGE_PROGRAM :
    ( F->isInternalLinkage(F->getLinkage()) ? BRIG_LINKAGE_MODULE
                                            : BRIG_LINKAGE_NONE);

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
      unsigned AS = TII->getNamedOperand(*MI, HSAIL::OpName::segment)->getImm();
      BrigEmitOperandLdStAddress(MI, opNum, AS);
      return;
    }

    // FIXME: This shouldn't be necessary
    if ((opNum > addrStart) &&
        (opNum < addrStart + HSAILADDRESS::ADDRESS_NUM_OPS))
      // Ignore rest of address fields, already emitted.
      return;
  }

  const MachineOperand &MO = MI->getOperand(opNum);

  BrigType16_t const expType = HSAIL_ASM::getOperandType(inst, m_opndList.size(),
                                                         brigantine.getMachineModel(), brigantine.getProfile());

  switch (MO.getType()) {
  case MachineOperand::MO_Register:
    m_opndList.push_back(getBrigReg(MO));
    break;
  case MachineOperand::MO_Immediate:
    if (expType==BRIG_TYPE_B1) {
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
  default:
    llvm_unreachable("unhandled operand type");
  }
}

void BRIGAsmPrinter::BrigEmitOperandLdStAddress(const MachineInstr *MI,
                                                unsigned opNum,
                                                unsigned Segment)  {
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

    if ((MI->getOpcode() == HSAIL::LD_V1) &&
        TII->getNamedOperand(*MI, HSAIL::OpName::TypeLength)->getImm() ==
        BRIG_TYPE_SAMP) {
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

  const DataLayout &DL = getDataLayout();
  bool Is32Bit = (DL.getPointerSize(Segment) == 4);

  // Emit operand.
  m_opndList.push_back(brigantine.createRef(base_name, reg_name, offset, Is32Bit));
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

  BrigType brigType = (BrigType)brig_type.getImm();
  HSAIL_ASM::DirectiveVariable vec_arg = (num_elem > 1 ) ?
    brigantine.addArrayVariable(stream.str(), num_elem, BRIG_SEGMENT_ARG, brigType) :
    brigantine.addVariable(stream.str(), BRIG_SEGMENT_ARG, brigType);

  vec_arg.align() = getBrigAlignment(align.getImm());
  vec_arg.modifier().isDefinition() = true;
  vec_arg.allocation() = BRIG_ALLOCATION_AUTOMATIC;
  vec_arg.linkage() = BRIG_LINKAGE_ARG;

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

HSAIL_ASM::OperandRegister BRIGAsmPrinter::getBrigReg(MachineOperand s) {
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
        BrigType16_t const expType =
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

  if (inst.geometry() == BRIG_GEOMETRY_2DDEPTH ||
      inst.geometry() == BRIG_GEOMETRY_2DADEPTH)
  {
    BrigEmitOperand(MI, opCnt++, inst);
  } else {
    BrigEmitVecOperand(MI, opCnt, 4, inst);
    opCnt+=4;
  }

    switch(inst.opcode()) {
    case BRIG_OPCODE_RDIMAGE:
      BrigEmitOperand(MI, opCnt++, inst);
      BrigEmitOperand(MI, opCnt++, inst);
    break;
    case BRIG_OPCODE_LDIMAGE:
    case BRIG_OPCODE_STIMAGE:
      BrigEmitOperand(MI, opCnt++, inst);
      break;
    default: ;
    }

  switch(inst.geometry()) {
  case BRIG_GEOMETRY_1D:
  case BRIG_GEOMETRY_1DB:
    BrigEmitOperand(MI, opCnt++, inst);
    break;
  case BRIG_GEOMETRY_1DA:
  case BRIG_GEOMETRY_2D:
  case BRIG_GEOMETRY_2DDEPTH:
    BrigEmitVecOperand(MI, opCnt, 2, inst); opCnt += 2;
    break;
  case BRIG_GEOMETRY_2DA:
  case BRIG_GEOMETRY_2DADEPTH:
  case BRIG_GEOMETRY_3D:
    BrigEmitVecOperand(MI, opCnt, 3, inst); opCnt += 3;
    break;
  }
}

HSAIL_ASM::InstBasic BRIGAsmPrinter::BrigEmitInstBasic(const MachineInstr &MI,
                                                       unsigned BrigOpc) {
  HSAIL_ASM::InstBasic inst = brigantine.addInst<HSAIL_ASM::InstBasic>(BrigOpc);
  unsigned Opc = MI.getOpcode();

  inst.type() = TII->getNamedOperand(MI, HSAIL::OpName::TypeLength)->getImm();

  int DestIdx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::dest);
  if (DestIdx != -1)
    BrigEmitOperand(&MI, DestIdx, inst);

  int Src0Idx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src0);
  if (Src0Idx != -1)
    BrigEmitOperand(&MI, Src0Idx, inst);

  int Src1Idx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src1);
  if (Src1Idx != -1)
    BrigEmitOperand(&MI, Src1Idx, inst);

  int Src2Idx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src2);
  if (Src2Idx != -1)
    BrigEmitOperand(&MI, Src2Idx, inst);

  return inst;
}

HSAIL_ASM::InstMod BRIGAsmPrinter::BrigEmitInstMod(const MachineInstr &MI,
                                                   unsigned BrigOpc) {
  HSAIL_ASM::InstMod inst = brigantine.addInst<HSAIL_ASM::InstMod>(BrigOpc);
  unsigned Opc = MI.getOpcode();

  inst.type() = TII->getNamedOperand(MI, HSAIL::OpName::TypeLength)->getImm();
  inst.modifier().ftz()
    = TII->getNamedOperand(MI, HSAIL::OpName::ftz)->getImm();

  inst.round()
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

HSAIL_ASM::InstCmp BRIGAsmPrinter::BrigEmitInstCmp(const MachineInstr &MI,
                                                   unsigned BrigOpc) {
  HSAIL_ASM::InstCmp inst = brigantine.addInst<HSAIL_ASM::InstCmp>(BrigOpc);
  unsigned Opc = MI.getOpcode();

  inst.compare()
    = TII->getNamedOperand(MI, HSAIL::OpName::op)->getImm();

  inst.modifier().ftz()
    = TII->getNamedOperand(MI, HSAIL::OpName::ftz)->getImm();

  inst.type()
    = TII->getNamedOperand(MI, HSAIL::OpName::destTypedestLength)->getImm();
  inst.sourceType()
    = TII->getNamedOperand(MI, HSAIL::OpName::sourceType)->getImm();


  BrigEmitOperand(&MI, HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::dest),
                  inst);
  BrigEmitOperand(&MI, HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src0),
                  inst);
  BrigEmitOperand(&MI, HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src1),
                  inst);
  return inst;
}

HSAIL_ASM::InstCvt BRIGAsmPrinter::BrigEmitInstCvt(const MachineInstr &MI,
                                                   unsigned BrigOpc) {
  HSAIL_ASM::InstCvt inst = brigantine.addInst<HSAIL_ASM::InstCvt>(BrigOpc);
  unsigned Opc = MI.getOpcode();

  inst.type()
    = TII->getNamedOperand(MI, HSAIL::OpName::destTypedestLength)->getImm();
  inst.sourceType()
    = TII->getNamedOperand(MI, HSAIL::OpName::sourceType)->getImm();

  // XXX - sourceType, destTypedestLength - These names are awful
  inst.modifier().ftz()
    = TII->getNamedOperand(MI, HSAIL::OpName::ftz)->getImm();
  inst.round() = TII->getNamedOperand(MI, HSAIL::OpName::round)->getImm();

  BrigEmitOperand(&MI, HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::dest),
                  inst);
  BrigEmitOperand(&MI, HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src),
                  inst);
  return inst;
}

HSAIL_ASM::InstSourceType
BRIGAsmPrinter::BrigEmitInstSourceType(const MachineInstr &MI,
                                       unsigned BrigOpc) {
  HSAIL_ASM::InstSourceType inst
    = brigantine.addInst<HSAIL_ASM::InstSourceType>(BrigOpc);

  unsigned Opc = MI.getOpcode();

  inst.type() = TII->getNamedOperand(MI, HSAIL::OpName::TypeLength)->getImm();
  inst.sourceType()
    = TII->getNamedOperand(MI, HSAIL::OpName::sourceType)->getImm();

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

HSAIL_ASM::InstLane BRIGAsmPrinter::BrigEmitInstLane(const MachineInstr &MI,
                                                     unsigned BrigOpc) {
  HSAIL_ASM::InstLane inst = brigantine.addInst<HSAIL_ASM::InstLane>(BrigOpc);

  unsigned Opc = MI.getOpcode();

  inst.type() = TII->getNamedOperand(MI, HSAIL::OpName::TypeLength)->getImm();
  inst.sourceType()
    = TII->getNamedOperand(MI, HSAIL::OpName::sourceType)->getImm();

  inst.width()
    = TII->getNamedOperand(MI, HSAIL::OpName::width)->getImm();

  int DestIdx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::dest);
  if (DestIdx != -1) {
    BrigEmitOperand(&MI, DestIdx, inst);
  } else {
    // FIXME: There appears to be a bug when trying to use a custom operand with
    // multiple fields in the outs.
    int Dest0Idx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::dest0);
    BrigEmitVecOperand(&MI, Dest0Idx, 4, inst);
  }

  int Src0Idx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src0);
  if (Src0Idx != -1)
    BrigEmitOperand(&MI, Src0Idx, inst);

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

HSAIL_ASM::InstBr BRIGAsmPrinter::BrigEmitInstBr(const MachineInstr &MI,
                                                 unsigned BrigOpc) {
  HSAIL_ASM::InstBr inst = brigantine.addInst<HSAIL_ASM::InstBr>(BrigOpc);
  unsigned Opc = MI.getOpcode();

  inst.type() = TII->getNamedOperand(MI, HSAIL::OpName::TypeLength)->getImm();
  inst.width() = TII->getNamedOperand(MI, HSAIL::OpName::width)->getImm();

  int DestIdx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::dest);
  if (DestIdx != -1)
    BrigEmitOperand(&MI, DestIdx, inst);

  int Src0Idx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src0);
  if (Src0Idx != -1)
    BrigEmitOperand(&MI, Src0Idx, inst);

  int Src1Idx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src1);
  if (Src1Idx != -1)
    BrigEmitOperand(&MI, Src1Idx, inst);

  return inst;
}

HSAIL_ASM::InstSeg BRIGAsmPrinter::BrigEmitInstSeg(const MachineInstr &MI,
                                                  unsigned BrigOpc) {
  HSAIL_ASM::InstSeg inst = brigantine.addInst<HSAIL_ASM::InstSeg>(BrigOpc);
  unsigned Opc = MI.getOpcode();

  inst.type() = TII->getNamedOperand(MI, HSAIL::OpName::TypeLength)->getImm();

  unsigned Segment = TII->getNamedOperand(MI, HSAIL::OpName::segment)->getImm();
  inst.segment() = getHSAILSegment(Segment);

  int DestIdx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::dest);
  if (DestIdx != -1)
    BrigEmitOperand(&MI, DestIdx, inst);

  return inst;
}

HSAIL_ASM::InstSegCvt BRIGAsmPrinter::BrigEmitInstSegCvt(const MachineInstr &MI,
                                                         unsigned BrigOpc) {
  HSAIL_ASM::InstSegCvt inst = brigantine.addInst<HSAIL_ASM::InstSegCvt>(BrigOpc);
  unsigned Opc = MI.getOpcode();

  inst.type() = TII->getNamedOperand(MI, HSAIL::OpName::destTypedestLength)->getImm();

  inst.sourceType()
    = TII->getNamedOperand(MI, HSAIL::OpName::sourceType)->getImm();

  unsigned Segment = TII->getNamedOperand(MI, HSAIL::OpName::segment)->getImm();
  inst.segment() = getHSAILSegment(Segment);

  inst.modifier().isNoNull()
    = TII->getNamedOperand(MI, HSAIL::OpName::nonull)->getImm();

  int DestIdx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::dest);
  BrigEmitOperand(&MI, DestIdx, inst);

  int Src0Idx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src0);
  BrigEmitOperand(&MI, Src0Idx, inst);

  return inst;
}

HSAIL_ASM::InstMemFence
BRIGAsmPrinter::BrigEmitInstMemFence(const MachineInstr &MI, unsigned BrigOpc) {
  HSAIL_ASM::InstMemFence inst
    = brigantine.addInst<HSAIL_ASM::InstMemFence>(BrigOpc, BRIG_TYPE_NONE);

  // FIXME: libHSAIL seems to not have been updated for change to remove
  // separate segment scope modifiers.
  inst.memoryOrder() = TII->getNamedModifierOperand(MI, HSAIL::OpName::order);
  inst.globalSegmentMemoryScope()
    = TII->getNamedModifierOperand(MI, HSAIL::OpName::scope);
  inst.groupSegmentMemoryScope() = inst.globalSegmentMemoryScope();
  inst.imageSegmentMemoryScope() = BRIG_MEMORY_SCOPE_NONE;

  return inst;
}

HSAIL_ASM::InstMem BRIGAsmPrinter::BrigEmitInstMem(const MachineInstr &MI,
                                                   unsigned BrigOpc) {
  HSAIL_ASM::InstMem inst = brigantine.addInst<HSAIL_ASM::InstMem>(BrigOpc);

  unsigned VecSize = 1; // FIXME: Stop special casing this.
  switch (MI.getOpcode()) {
  case HSAIL::LD_V2:
  case HSAIL::ST_V2:
  case HSAIL::RARG_LD_V2:
    VecSize = 2;
    break;
  case HSAIL::LD_V3:
  case HSAIL::ST_V3:
  case HSAIL::RARG_LD_V3:
    VecSize = 3;
    break;
  case HSAIL::LD_V4:
  case HSAIL::ST_V4:
  case HSAIL::RARG_LD_V4:
    VecSize = 4;
    break;
  }

  unsigned Segment = TII->getNamedOperand(MI, HSAIL::OpName::segment)->getImm();
  unsigned Align = TII->getNamedOperand(MI, HSAIL::OpName::align)->getImm();

  inst.segment() = getHSAILSegment(Segment);
  inst.type() = TII->getNamedOperand(MI, HSAIL::OpName::TypeLength)->getImm();
  inst.align() = getBrigAlignment(Align);
  inst.equivClass() = 0;

  // FIXME: These operands should always be present.
  if (const MachineOperand *Mask = TII->getNamedOperand(MI, HSAIL::OpName::mask))
    inst.modifier().isConst() = Mask->getImm() & BRIG_MEMORY_CONST;

  if (const MachineOperand *Width = TII->getNamedOperand(MI, HSAIL::OpName::width))
    inst.width() = Width->getImm();
  else
    inst.width() = BRIG_WIDTH_NONE;

  if (VecSize == 1)
    BrigEmitOperand(&MI, 0, inst);
  else
    BrigEmitVecOperand(&MI, 0, VecSize, inst);

  BrigEmitOperandLdStAddress(&MI, VecSize, Segment);

  return inst;
}

HSAIL_ASM::InstAtomic BRIGAsmPrinter::BrigEmitInstAtomic(const MachineInstr &MI,
                                                         unsigned BrigOpc) {
  HSAIL_ASM::InstAtomic inst = brigantine.addInst<HSAIL_ASM::InstAtomic>(BrigOpc);
  unsigned Opc = MI.getOpcode();

  unsigned Segment = TII->getNamedOperand(MI, HSAIL::OpName::segment)->getImm();
  inst.segment() = getHSAILSegment(Segment);
  inst.memoryOrder() = TII->getNamedModifierOperand(MI, HSAIL::OpName::order);
  inst.memoryScope() = TII->getNamedModifierOperand(MI, HSAIL::OpName::scope);
  inst.atomicOperation() = TII->getNamedModifierOperand(MI, HSAIL::OpName::op);
  inst.equivClass() = TII->getNamedOperand(MI, HSAIL::OpName::equiv)->getImm();
  inst.type() = TII->getNamedOperand(MI, HSAIL::OpName::TypeLength)->getImm();

  int DestIdx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::dest);
  if (DestIdx != -1)
    BrigEmitOperand(&MI, DestIdx, inst);

  int AddressIdx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::address);
  BrigEmitOperandLdStAddress(&MI, AddressIdx, Segment);

  // InstAtomic is unusual in that the number of operands differs with the same
  // instruction opcode depending on the atomicOperation modifier. We always
  // have these operands in the MachineInstr, and must not emit them if they are
  // unused for this operation.

  int Src0Idx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src0);
  const MachineOperand &Src0 = MI.getOperand(Src0Idx);
  if (!Src0.isReg() || Src0.getReg() != HSAIL::NoRegister)
    BrigEmitOperand(&MI, Src0Idx, inst);

  int Src1Idx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src1);
  const MachineOperand &Src1 = MI.getOperand(Src1Idx);
  if (!Src1.isReg() || Src1.getReg() != HSAIL::NoRegister)
    BrigEmitOperand(&MI, Src1Idx, inst);

  return inst;
}

HSAIL_ASM::InstImage BRIGAsmPrinter::BrigEmitInstImage(const MachineInstr &MI,
                                                       unsigned BrigOpc) {
  HSAIL_ASM::InstImage inst = brigantine.addInst<HSAIL_ASM::InstImage>(BrigOpc);
  unsigned Opc = MI.getOpcode();

  inst.imageType() = TII->getNamedOperand(MI, HSAIL::OpName::imageType)->getImm();
  inst.coordType() = TII->getNamedOperand(MI, HSAIL::OpName::coordType)->getImm();
  inst.geometry() = TII->getNamedOperand(MI, HSAIL::OpName::geometry)->getImm();
  inst.equivClass() = TII->getNamedOperand(MI, HSAIL::OpName::equiv)->getImm();

  inst.type() = TII->getNamedOperand(MI, HSAIL::OpName::destType)->getImm();


  int DestRIdx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::destR);
  if (DestRIdx != -1) {
    int DestGIdx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::destG);
    if (DestGIdx == -1) // 1 component.
      BrigEmitOperand(&MI, DestRIdx, inst);
    else
      BrigEmitVecOperand(&MI, DestRIdx, 4, inst);
  }

  int ImageIdx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::image);
  BrigEmitOperand(&MI, ImageIdx, inst);

  int SamplerIdx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::sampler);
  BrigEmitOperand(&MI, SamplerIdx, inst);

  int CoordWidthIdx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::coordWidth);
  BrigEmitOperand(&MI, CoordWidthIdx, inst);

  return inst;
}

HSAIL_ASM::InstAddr BRIGAsmPrinter::BrigEmitInstAddr(const MachineInstr &MI,
                                                     unsigned BrigOpc) {
  HSAIL_ASM::InstAddr inst = brigantine.addInst<HSAIL_ASM::InstAddr>(BrigOpc);
  unsigned Opc = MI.getOpcode();

  inst.type() = TII->getNamedOperand(MI, HSAIL::OpName::TypeLength)->getImm();

  unsigned Segment = TII->getNamedOperand(MI, HSAIL::OpName::segment)->getImm();
  inst.segment() = getHSAILSegment(Segment);

  int DestIdx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::dest);
  int AddressIdx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::address);

  BrigEmitOperand(&MI, DestIdx, inst);
  BrigEmitOperandLdStAddress(&MI, AddressIdx, Segment);

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
      case HSAIL::GCN_ATOMIC_APPEND:
      case HSAIL::GCN_ATOMIC_CONSUME:
        return true;
      }
    }
  }
  return false;
}

BrigAlignment8_t BRIGAsmPrinter::getBrigAlignment(unsigned AlignVal) {
  // Round to the next power of 2.
  unsigned Rounded = RoundUpToAlignment(AlignVal, NextPowerOf2(AlignVal - 1));

  BrigAlignment8_t ret = HSAIL_ASM::num2align(Rounded);
  assert(ret != BRIG_ALIGNMENT_LAST && "invalid alignment value");
  return ret;
}

// Force static initialization.
extern "C" void LLVMInitializeBRIGAsmPrinter() {
  RegisterAsmPrinter<BRIGAsmPrinter> X(TheHSAIL_32Target);
  RegisterAsmPrinter<BRIGAsmPrinter> Y(TheHSAIL_64Target);
}
