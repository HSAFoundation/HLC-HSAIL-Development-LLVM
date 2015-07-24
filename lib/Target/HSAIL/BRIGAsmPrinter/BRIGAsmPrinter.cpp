//===-- BRIGAsmPrinter.cpp - BRIG object emitter via libHSAIL -------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
/// \file
///
/// The BRIGAsmPrinter is used to emit BRIG object code or HSAIL text (via
/// dissembling) using libHSAIL
//
//===----------------------------------------------------------------------===//
//

#include "BRIGAsmPrinter.h"
#include "BRIGDwarfDebug.h"
#include "MCTargetDesc/BRIGDwarfStreamer.h"
#include "HSAILKernelManager.h"
#include "HSAILOpaqueTypes.h"
#include "HSAILStoreInitializer.h"
#include "HSAILTargetMachine.h"
#include "HSAILUtilityFunctions.h"
#include "InstPrinter/HSAILInstPrinter.h"

#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/MC/MCValue.h"

#include "llvm/Support/CommandLine.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/TargetRegistry.h"

#include "../lib/CodeGen/AsmPrinter/DwarfDebug.h"

#include "LibHSAILAdapters.h"

#include "libHSAIL/HSAILDisassembler.h"
#include "libHSAIL/HSAILDump.h"
#include "libHSAIL/HSAILParser.h"
#include "libHSAIL/HSAILValidator.h"

#include <fstream>
#include <iostream>
#include <memory>

using namespace llvm;

#define GET_LLVM_INTRINSIC_FOR_GCC_BUILTIN
#include "HSAILGenIntrinsics.inc"
#undef GET_LLVM_INTRINSIC_FOR_GCC_BUILTIN

static cl::opt<std::string> DebugInfoFilename("odebug",
                                              cl::desc("Debug Info filename"),
                                              cl::value_desc("filename"),
                                              cl::init(""));

static cl::opt<std::string> DumpOnFailFilename(
    "dumpOnFail",
    cl::desc("Filename for the BRIG container dump if validation failed"),
    cl::value_desc("filename"), cl::init(""));

static cl::opt<bool>
    DisableValidator("disable-validator",
                     cl::desc("Disable validation of the BRIG container"),
                     cl::init(false), cl::Hidden);

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

BrigSegment BRIGAsmPrinter::getAtomicSegment(const MachineInstr *MI) const {
  int64_t Val = TII->getNamedModifierOperand(*MI, HSAIL::OpName::segment);
  assert(Val > 0 && Val < BRIG_SEGMENT_AMD_GCN);
  return static_cast<BrigSegment>(Val);
}

BrigMemoryOrder BRIGAsmPrinter::getAtomicOrder(const MachineInstr *MI) const {
  int64_t Val = TII->getNamedModifierOperand(*MI, HSAIL::OpName::order);
  assert(Val > 0 && Val <= BRIG_MEMORY_ORDER_SC_ACQUIRE_RELEASE);
  return static_cast<BrigMemoryOrder>(Val);
}

BrigMemoryScope BRIGAsmPrinter::getAtomicScope(const MachineInstr *MI) const {
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
  return (AS == HSAILAS::GROUP_ADDRESS || AS == HSAILAS::PRIVATE_ADDRESS) ? '%'
                                                                          : '&';
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
  (void)Res;
  assert(Res && "Could not evaluate MCExpr");
  assert(!Val.getSymB() && "Multi-symbol expressions not handled");

  const MCSymbol &Sym = Val.getSymA()->getSymbol();

  O << "initvarwithaddress:" << VarName << ':'
    << BaseOffset // Offset into the destination.
    << ':' << EltSize << ':' << getSymbolPrefix(Sym) << Sym.getName() << ':'
    << Val.getConstant(); // Offset of the symbol being written.

  HSAIL_ASM::DirectivePragma pgm =
      brigantine.append<HSAIL_ASM::DirectivePragma>();

  HSAIL_ASM::ItemList opnds;

  opnds.push_back(brigantine.createOperandString(makeSRef(O.str())));
  pgm.operands() = opnds;
}

void BRIGAsmPrinter::BrigEmitGlobalInit(HSAIL_ASM::DirectiveVariable globalVar,
                                        Type *EltTy, Constant *CV) {
  if (isa<UndefValue>(CV)) // Don't emit anything for undefined initializers.
    return;

  BrigType EltBT = static_cast<BrigType>(globalVar.type() & ~BRIG_TYPE_ARRAY);

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
    globalVar.init() =
        brigantine.createOperandConstantBytes(init, EltBT, isArray);
    return;
  }

  unsigned EltSize = HSAIL_ASM::getBrigTypeNumBytes(EltBT);

  auto Name = globalVar.name().str();

  StoreInitializer store(EltTy, *this);
  store.append(CV, Name);

  if (store.elementCount() > 0) {
    globalVar.init() = brigantine.createOperandConstantBytes(
        makeSRef(store.str()), EltBT, isArray);
  } else {
    uint64_t Size = globalVar.dim() * typeBytes;
    std::unique_ptr<char[]> Zeros(new char[Size]());

    HSAIL_ASM::SRef init(Zeros.get(), Zeros.get() + Size);
    globalVar.init() =
        brigantine.createOperandConstantBytes(init, EltBT, isArray);
  }

  for (const auto &VarInit : store.varInitAddresses()) {
    BrigEmitInitVarWithAddressPragma(Name, VarInit.BaseOffset, VarInit.Expr,
                                     EltSize);
  }
}

BRIGAsmPrinter::BRIGAsmPrinter(TargetMachine &TM, MCStreamer &Streamer)
    : HSAILAsmPrinter(TM, Streamer),
      Subtarget(&TM.getSubtarget<HSAILSubtarget>()), FuncArgsStr(),
      FuncRetValStr(), retValCounter(0), paramCounter(0),
      mTM(reinterpret_cast<HSAILTargetMachine *>(&TM)),
      TII(Subtarget->getInstrInfo()), mMeta(new HSAILKernelManager(mTM)),
      mMFI(nullptr), m_bIsKernel(false), brigantine(bc), mDwarfStream(nullptr),
      mBrigStream(nullptr), mDwarfFileStream(nullptr),
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
    mDwarfFileStream =
        new raw_fd_ostream(DebugInfoFilename.c_str(), err, sys::fs::F_Text);
    mDwarfStream->setOtherStream(mDwarfFileStream);
  }
}

BRIGAsmPrinter::~BRIGAsmPrinter() {
  delete mMeta;
  delete mDwarfStream;
  delete mDwarfFileStream;
}

BrigSegment8_t BRIGAsmPrinter::getHSAILSegment(unsigned AddressSpace) const {
  switch (AddressSpace) {
  case HSAILAS::PRIVATE_ADDRESS:
    return BRIG_SEGMENT_PRIVATE;
  case HSAILAS::GLOBAL_ADDRESS:
    return BRIG_SEGMENT_GLOBAL;
  case HSAILAS::READONLY_ADDRESS:
    return BRIG_SEGMENT_READONLY;
  case HSAILAS::GROUP_ADDRESS:
    return BRIG_SEGMENT_GROUP;
  case HSAILAS::FLAT_ADDRESS:
    return BRIG_SEGMENT_FLAT;
  case HSAILAS::REGION_ADDRESS:
    return BRIG_SEGMENT_AMD_GCN;
  case HSAILAS::KERNARG_ADDRESS:
    return BRIG_SEGMENT_KERNARG;
  case HSAILAS::ARG_ADDRESS:
    return BRIG_SEGMENT_ARG;
  case HSAILAS::SPILL_ADDRESS:
    return BRIG_SEGMENT_SPILL;
  }
  llvm_unreachable("Unexpected BRIG address space value");
}

BrigSegment8_t BRIGAsmPrinter::getHSAILSegment(const GlobalVariable *gv) const {
  return getHSAILSegment(gv->getType()->getAddressSpace());
}

bool BRIGAsmPrinter::canInitHSAILAddressSpace(const GlobalVariable *gv) const {
  bool canInit;
  switch (gv->getType()->getAddressSpace()) {
  case HSAILAS::GLOBAL_ADDRESS:
  case HSAILAS::READONLY_ADDRESS:
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
  }

  llvm_unreachable("Invalid linkage type");
}

static unsigned getGVAlignment(const GlobalVariable &GV, const DataLayout &DL,
                               Type *InitTy, Type *EltTy, unsigned NElts,
                               bool IsLocal) {
  unsigned Alignment = GV.getAlignment();
  if (Alignment == 0)
    Alignment = DL.getPrefTypeAlignment(InitTy);
  else {
    // If an alignment is specified, it must be equal to or greater than the
    // variable's natural alignment.

    unsigned NaturalAlign = IsLocal ? DL.getPrefTypeAlignment(EltTy)
                                    : DL.getABITypeAlignment(EltTy);
    Alignment = std::max(Alignment, NaturalAlign);
  }

  // Align arrays at least by 4 bytes.
  if (Alignment < 4 && NElts != 0)
    Alignment = 4;

  return Alignment;
}

/// EmitGlobalVariable - Emit the specified global variable to the .s file.
void BRIGAsmPrinter::EmitGlobalVariable(const GlobalVariable *GV) {
  if (HSAIL::isIgnoredGV(GV))
    return;

  const DataLayout &DL = getDataLayout();

  SmallString<256> NameStr;
  getHSAILMangledName(NameStr, GV);

  // Initializer has pointer element type.
  Type *InitTy = GV->getType()->getElementType();

  unsigned NElts = 0;
  Type *EltTy = HSAIL::analyzeType(InitTy, NElts, DL);

  HSAIL_ASM::DirectiveVariable globalVar;
  // TODO_HSA: pending BRIG_LINKAGE_STATIC implementation in the Finalizer
  if (NElts == 0) {
    globalVar = brigantine.addVariable(makeSRef(NameStr), getHSAILSegment(GV),
                                       HSAIL::getBrigType(EltTy, DL));
  } else {
    globalVar = brigantine.addArrayVariable(makeSRef(NameStr), NElts,
                                            getHSAILSegment(GV),
                                            HSAIL::getBrigType(EltTy, DL));
  }

  globalVar.linkage() = findGlobalBrigLinkage(*GV);
  globalVar.allocation() = BRIG_ALLOCATION_AGENT;
  globalVar.modifier().isDefinition() = 1;
  globalVar.dim() = NElts;

  unsigned Align = getGVAlignment(*GV, DL, InitTy, EltTy, NElts, false);
  globalVar.align() = getBrigAlignment(Align);

  globalVariableOffsets[GV] = globalVar.brigOffset();

  // TODO_HSA: if group memory has initializer, then emit instructions to
  // initialize dynamically
  if (GV->hasInitializer() && canInitHSAILAddressSpace(GV)) {
    BrigEmitGlobalInit(globalVar, EltTy, (Constant *)GV->getInitializer());
  }
}

static bool isHSAILInstrinsic(StringRef str) {
  if ((HSAILIntrinsic::ID)Intrinsic::not_intrinsic !=
      getIntrinsicForGCCBuiltin("HSAIL", str.data()))
    return true;
  return str.startswith(StringRef("llvm.HSAIL."));
}

/// Returns true if StringRef is LLVM intrinsic function that define a mapping
/// between LLVM program objects and the source-level objects.
/// See http://llvm.org/docs/SourceLevelDebugging.html#format_common_intrinsics
/// for more details.
static bool isLLVMDebugIntrinsic(StringRef str) {
  return str.equals("llvm.dbg.declare") || str.equals("llvm.dbg.value");
}

// Emit a declaration of function F, optionally using the name of alias GA.
void BRIGAsmPrinter::EmitFunctionLabel(const Function &F,
                                       const GlobalAlias *GA) {
  if (isLLVMDebugIntrinsic(F.getName())) {
    return; // Nothing to do with LLVM debug-related intrinsics
  }

  FunctionType *funcType = F.getFunctionType();
  Type *retType = funcType->getReturnType();

  SmallString<256> Name;

  if (GA)
    getHSAILMangledName(Name, GA);
  else
    getHSAILMangledName(Name, &F);

  HSAIL_ASM::DirectiveFunction fx = brigantine.declFunc(makeSRef(Name));
  // TODO_HSA: pending BRIG_LINKAGE_STATIC implementation in the Finalizer
  fx.linkage() = findGlobalBrigLinkage(F);

  const auto &Attrs = F.getAttributes();

  paramCounter = 0;
  if (!retType->isVoidTy()) {
    bool IsSExt =
        Attrs.hasAttribute(AttributeSet::ReturnIndex, Attribute::SExt);
    bool IsZExt =
        Attrs.hasAttribute(AttributeSet::ReturnIndex, Attribute::ZExt);

    if (IsSExt || IsZExt) {
      EmitFunctionReturn(Type::getInt32Ty(retType->getContext()), false, "ret",
                         IsSExt);
    } else
      EmitFunctionReturn(retType, false, "ret", IsSExt);
  }

  // Loop through all of the parameters and emit the types and
  // corresponding names.
  Function::const_arg_iterator ai = F.arg_begin();
  Function::const_arg_iterator ae = F.arg_end();
  unsigned n = 1;

  for (FunctionType::param_iterator pb = funcType->param_begin(),
                                    pe = funcType->param_end();
       pb != pe; ++pb, ++ai, ++n) {
    assert(ai != ae);
    Type *type = *pb;
    bool IsSExt = Attrs.hasAttribute(n, Attribute::SExt);
    EmitFunctionArgument(type, false, ai->getName(), IsSExt);
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

bool BRIGAsmPrinter::runOnMachineFunction(MachineFunction &lMF) {
  this->MF = &lMF;
  mMeta->setMF(&lMF);
  mMFI = lMF.getInfo<HSAILMachineFunctionInfo>();
  SetupMachineFunction(lMF);
  const Function *F = MF->getFunction();
  OutStreamer.SwitchSection(
      getObjFileLowering().SectionForGlobal(F, *Mang, TM));
  m_bIsKernel = HSAIL::isKernelFunc(MF->getFunction());
  mMeta->printHeader(MF->getFunction()->getName());

  // The need to define global samplers is discovered during instruction
  // selection,
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

  HSAILImageHandles *handles = Subtarget->getImageHandles();
  SmallVector<HSAILSamplerHandle *, 16> samplers = handles->getSamplerHandles();

  // Emit global sampler defs
  for (unsigned i = 0; i < samplers.size(); i++) {
    // All sampler defs (samplers with initializers) are global, so we emit
    // them only once.
    if (!samplers[i]->isEmitted()) {

      HSAIL_ASM::DirectiveVariable samplerVar = brigantine.addSampler(
          "&" + samplers[i]->getSym(),
          samplers[i]->isRO() ? BRIG_SEGMENT_READONLY : BRIG_SEGMENT_GLOBAL);
      samplerVar.align() = BRIG_ALIGNMENT_8;
      samplerVar.allocation() = BRIG_ALLOCATION_AGENT;
      samplerVar.linkage() = BRIG_LINKAGE_MODULE;
      samplerVar.modifier().isDefinition() = 1;
      HSAIL_ASM::OperandConstantSampler samplerProps =
          brigantine.append<HSAIL_ASM::OperandConstantSampler>();
      // HSAIL_ASM::ItemList samplerInit;
      // samplerInit.push_back(samplerProps);
      samplerVar.init() = samplerProps;

      int ocl_init = handles->getSamplerValue(i);

      samplerProps.coord() =
          (ocl_init & 0x1) ? BRIG_COORD_NORMALIZED : BRIG_COORD_UNNORMALIZED;

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
      case 0x0:
        samplerProps.addressing() = BRIG_ADDRESSING_UNDEFINED;
        break; // CLK_ADDRESS_NONE
      case 0x2:
        samplerProps.addressing() = BRIG_ADDRESSING_REPEAT;
        break; // CLK_ADDRESS_REPEAT
      case 0x4:
        samplerProps.addressing() = BRIG_ADDRESSING_CLAMP_TO_EDGE;
        break; // CLK_ADDRESS_CLAMP_TO_EDGE
      case 0x6:
        samplerProps.addressing() = BRIG_ADDRESSING_CLAMP_TO_BORDER;
        break; // CLK_ADDRESS_CLAMP
      case 0x8:
        samplerProps.addressing() = BRIG_ADDRESSING_MIRRORED_REPEAT;
        break; // CLK_ADDRESS_MIRRORED_REPEAT
      }

      samplers[i]->setEmitted();
    }
  }
}

void BRIGAsmPrinter::emitMacroFunc(const MachineInstr *MI, raw_ostream &O) {
  StringRef nameRef;
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
  MCStreamer *streamer;
  const HSAIL_ASM::Brigantine *brigantine;
  uint64_t lowpc;
  uint64_t hipc;

public:
  autoCodeEmitter(MCStreamer *strm, const HSAIL_ASM::Brigantine *brig)
      : streamer(strm), brigantine(brig) {
    lowpc = brigantine->container().code().size();
  }

  ~autoCodeEmitter() {
    hipc = brigantine->container().code().size();
    streamer->SwitchSection(
        streamer->getContext().getObjectFileInfo()->getTextSection());
    assert(lowpc <= hipc);
    // This is the only way to adjust the size of virtual ELF section
    // (type SHT_NOBITS) like .brigcode
    streamer->EmitZeros(hipc - lowpc);
  }
};
}

void BRIGAsmPrinter::EmitInstruction(const MachineInstr *II) {
  m_opndList.clear();
  HSAIL_ASM::Inst inst = EmitInstructionImpl(II);
  if (inst) {
    inst.operands() = m_opndList;
  }
}

HSAIL_ASM::Inst BRIGAsmPrinter::EmitInstructionImpl(const MachineInstr *II) {
  // autoCodeEmitter will emit required amount of bytes in corresponding
  // MCSection
  autoCodeEmitter ace(&OutStreamer, &brigantine);

  unsigned Opc = II->getOpcode();
  uint16_t BrigOpc = TII->getBrigOpcode(Opc);

  if (TII->isInstBasic(Opc))
    return BrigEmitInstBasic(*II, BrigOpc);

  if (TII->isInstMod(Opc)) {
    // FIXME: Some instructions are available as InstBasic if they don't use
    // modifiers.
    return BrigEmitInstMod(*II, BrigOpc);
  }

  if (TII->isInstCmp(Opc))
    return BrigEmitInstCmp(*II, BrigOpc);

  if (TII->isInstMem(Opc))
    return BrigEmitInstMem(*II, BrigOpc);

  if (TII->isInstCvt(Opc))
    return BrigEmitInstCvt(*II, BrigOpc);

  if (TII->isInstSourceType(Opc))
    return BrigEmitInstSourceType(*II, BrigOpc);

  if (TII->isInstBr(Opc))
    return BrigEmitInstBr(*II, BrigOpc);

  if (TII->isInstMemFence(Opc))
    return BrigEmitInstMemFence(*II, BrigOpc);

  if (TII->isInstAtomic(Opc))
    return BrigEmitInstAtomic(*II, BrigOpc);

  if (TII->isInstImage(Opc))
    return BrigEmitInstImage(*II, BrigOpc);

  if (TII->isInstAddr(Opc))
    return BrigEmitInstAddr(*II, BrigOpc);

  if (TII->isInstLane(Opc))
    return BrigEmitInstLane(*II, BrigOpc);

  if (TII->isInstSeg(Opc))
    return BrigEmitInstSeg(*II, BrigOpc);

  if (TII->isInstSegCvt(Opc))
    return BrigEmitInstSegCvt(*II, BrigOpc);

  switch (II->getOpcode()) {
  case HSAIL::RET:
    return brigantine.addInst<HSAIL_ASM::InstBasic>(BRIG_OPCODE_RET,
                                                    BRIG_TYPE_NONE);

  case HSAIL::ARG_SCOPE_START:
    brigantine.startArgScope();
    return HSAIL_ASM::Inst();

  case HSAIL::ARG_SCOPE_END:
    brigantine.endArgScope();
    return HSAIL_ASM::Inst();

  case HSAIL::CALL: {
    MachineInstr::const_mop_iterator oi = II->operands_begin();
    MachineInstr::const_mop_iterator oe = II->operands_end();
    const GlobalValue *gv = (oi++)->getGlobal();

    // Place a call
    HSAIL_ASM::InstBr call =
        brigantine.addInst<HSAIL_ASM::InstBr>(BRIG_OPCODE_CALL, BRIG_TYPE_NONE);
    call.width() = BRIG_WIDTH_ALL;

    HSAIL_ASM::ItemList ret_list;
    for (; oi != oe && oi->isSymbol(); ++oi) {
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

    SmallString<256> Name;
    getHSAILMangledName(Name, gv);

    m_opndList.push_back(brigantine.createCodeList(ret_list));
    m_opndList.push_back(brigantine.createExecutableRef(makeSRef(Name)));
    m_opndList.push_back(brigantine.createCodeList(call_paramlist));

    return call;
  }
  case HSAIL::ARG_DECL:
    BrigEmitVecArgDeclaration(II);
    return HSAIL_ASM::Inst();
  default:
    llvm_unreachable("unhandled instruction");
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
    setDwarfDebug(nullptr);
  }
#endif

  // LLVM Bug 9761. Nothing should be emitted after EmitEndOfAsmFile()
  OutStreamer.FinishImpl();

  // Allow the target to emit any magic that it wants at the end of the file,
  // after everything else has gone out.
  EmitEndOfAsmFile(M);

  return false;
}

void BRIGAsmPrinter::EmitStartOfAsmFile(Module &M) {
  // Clear global variable map.
  globalVariableOffsets.clear();

  brigantine.startProgram();
  brigantine.module("&__llvm_hsail_module", BRIG_VERSION_HSAIL_MAJOR,
                    BRIG_VERSION_HSAIL_MINOR,
                    Subtarget->isLargeModel() ? BRIG_MACHINE_LARGE :
                                                BRIG_MACHINE_SMALL,
                    BRIG_PROFILE_FULL, BRIG_ROUND_FLOAT_NEAR_EVEN);


  if (Subtarget->isGCN())
    brigantine.addExtension("amd:gcn");

  if (Subtarget->hasImages())
    brigantine.addExtension("IMAGE");

  // If we are emitting first instruction that occupied some place in BRIG
  // we should also emit 4 reserved bytes to the MCSection, so that offsets
  // of instructions are the same in the BRIG .code section and MCSection
  OutStreamer.SwitchSection(
      OutStreamer.getContext().getObjectFileInfo()->getTextSection());
  OutStreamer.EmitZeros(
      brigantine.container().code().secHeader()->headerByteCount);

  for (GlobalAlias &GA : M.aliases()) {
    if (const Function *F = dyn_cast<Function>(GA.getAliasee()))
      EmitFunctionLabel(*F, &GA);
    else if (isa<GlobalVariable>(GA.getAliasee())) {
      llvm_unreachable("Use of alias globals not yet implemented");
    } else
      llvm_unreachable("Unhandled alias type");
  }

  for (const GlobalVariable &GV : M.globals())
    EmitGlobalVariable(&GV);

  // Emit function declarations.
  for (const Function &F : M.functions()) {
    // No declaration for kernels or intrinsics.
    if (F.isIntrinsic() || HSAIL::isKernelFunc(&F) ||
        isHSAILInstrinsic(F.getName()))
      continue;

    EmitFunctionLabel(F, nullptr);
  }
}

void BRIGAsmPrinter::EmitEndOfAsmFile(Module &M) {
  brigantine.endProgram();
  // Clear global variable map
  globalVariableOffsets.clear();
  if (mDwarfStream) {
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
      brigantine.container().initSectionRaw(
          BRIG_SECTION_INDEX_IMPLEMENTATION_DEFINED, "hsa_debug");
      HSAIL_ASM::BrigSectionImpl &section = brigantine.container().sectionById(
          BRIG_SECTION_INDEX_IMPLEMENTATION_DEFINED);
      section.insertData(section.size(), data.begin, data.end);
    }
  }

  // optimizeOperands is not functional as of now
  // bc.optimizeOperands();
  HSAIL_ASM::Validator vld(bc);

  bool isValid = true;
  if (!DisableValidator) {
    isValid = vld.validate();
  }

  if (!isValid) {
    errs() << vld.getErrorMsg(nullptr) << '\n';
    //    HSAIL_ASM::dump(bc);
    if (DumpOnFailFilename.size() > 0) {
      std::string info;

      std::ofstream dumpStream(DumpOnFailFilename.c_str());
      HSAIL_ASM::dump(bc, dumpStream);
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
      int result = disasm.run(ss);
      if (result) {
        assert(!"disasm should not fail if container was validated above");
      }
      const std::string &s = ss.str();
      if (!s.empty()) {
        mBrigStream->write(s.data(), s.size());
      }
    }
  } else {
    HSAIL_ASM::BrigStreamer::save(bc, "test_output.brig");
  }
}

HSAIL_ASM::DirectiveVariable
BRIGAsmPrinter::EmitLocalVariable(const GlobalVariable *GV,
                                  BrigSegment8_t segment) {
  const DataLayout &DL = getDataLayout();

  SmallString<256> NameStr;
  getHSAILMangledName(NameStr, GV);

  Type *InitTy = GV->getType()->getElementType();

  unsigned NElts = 0;
  Type *EltTy = HSAIL::analyzeType(InitTy, NElts, DL);
  unsigned Align = getGVAlignment(*GV, DL, InitTy, EltTy, NElts, true);

  HSAIL_ASM::DirectiveVariable var;
  if (NElts != 0) {
    BrigType BT = HSAIL::getBrigType(EltTy, DL);
    var = brigantine.addArrayVariable(makeSRef(NameStr), NElts, segment,
                                      BT & ~BRIG_TYPE_ARRAY);
  } else {
    var = brigantine.addVariable(makeSRef(NameStr), segment,
                                 HSAIL::getBrigType(EltTy, getDataLayout()));
  }

  var.align() = getBrigAlignment(Align);

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
      // We have to call processArgMetadata with ostream before we can emit
      // something
      mMeta->brigEmitMetaData(brigantine, id, isKernel);
    }
  }

  // Clear the lists of group variables
  groupVariablesOffsets.clear();

  // Record private/group variable references
  for (MachineFunction::const_iterator block = MF->begin(),
                                       endBlock = MF->end();
       block != endBlock; ++block) {
    for (MachineBasicBlock::const_iterator inst = block->begin(),
                                           instEnd = block->end();
         inst != instEnd; ++inst) {
      const MachineInstr *MI = inst;
      for (unsigned int opNum = 0; opNum < MI->getNumOperands(); opNum++) {
        const MachineOperand &MO = MI->getOperand(opNum);
        if (MO.getType() == MachineOperand::MO_GlobalAddress) {
          if (const GlobalVariable *GV =
                  dyn_cast<GlobalVariable>(MO.getGlobal())) {
            switch (GV->getType()->getAddressSpace()) {
            case HSAILAS::GROUP_ADDRESS:
              groupVariablesOffsets.insert(std::make_pair(GV, 0));
              break;
            }
          }
        }
      }
    }
  }

  // Emit recorded
  for (Module::const_global_iterator I = F->getParent()->global_begin(),
                                     E = F->getParent()->global_end();
       I != E; ++I) {
    pvgvo_iterator II = groupVariablesOffsets.find(I);
    if (II != groupVariablesOffsets.end()) {
      HSAIL_ASM::DirectiveVariable var =
          EmitLocalVariable(II->first, BRIG_SEGMENT_GROUP);

      II->second = var.brigOffset();
    }
  }

  const MachineFrameInfo *MFI = MF->getFrameInfo();

  uint64_t SpillSize, PrivateSize;
  unsigned PrivateAlign, SpillAlign;
  computeStackUsage(MFI, PrivateSize, PrivateAlign, SpillSize, SpillAlign);

  if (PrivateSize != 0) {
    HSAIL_ASM::DirectiveVariable PrivateStack =
      brigantine.addArrayVariable("%__privateStack", PrivateSize,
                                  BRIG_SEGMENT_PRIVATE, BRIG_TYPE_U8);
    PrivateStack.align() = getBrigAlignment(PrivateAlign);
    PrivateStack.allocation() = BRIG_ALLOCATION_AUTOMATIC;
    PrivateStack.linkage() = BRIG_LINKAGE_FUNCTION;
    PrivateStack.modifier().isDefinition() = 1;
  }

  if (SpillSize != 0) {
    HSAIL_ASM::DirectiveVariable SpillStack = brigantine.addArrayVariable(
      "%__spillStack", SpillSize, BRIG_SEGMENT_SPILL, BRIG_TYPE_U8);
    SpillStack.align() = getBrigAlignment(SpillAlign);
    SpillStack.allocation() = BRIG_ALLOCATION_AUTOMATIC;
    SpillStack.linkage() = BRIG_LINKAGE_FUNCTION;
    SpillStack.modifier().isDefinition() = 1;
  }

  const HSAILMachineFunctionInfo *Info = MF->getInfo<HSAILMachineFunctionInfo>();
  if (Info->hasScavengerSpill()) {
    HSAIL_ASM::DirectiveVariable SpillScavenge =
      brigantine.addVariable("%___spillScavenge",
                             BRIG_SEGMENT_SPILL, BRIG_TYPE_U32);
    SpillScavenge.align() = getBrigAlignment(4);
    SpillScavenge.allocation() = BRIG_ALLOCATION_AUTOMATIC;
    SpillScavenge.linkage() = BRIG_LINKAGE_FUNCTION;
    SpillScavenge.modifier().isDefinition() = 1;
  }

  retValCounter = 0;
  paramCounter = 0;

#if 0
  if (usesGCNAtomicCounter()) {
    HSAIL_ASM::InstBase gcn_region = brigantine.addInst<HSAIL_ASM::InstBase>(
      BRIG_OPCODE_GCNREGIONALLOC);
    brigantine.appendOperand(gcn_region, brigantine.createImmed(4,
                             BRIG_TYPE_B32));
  }
#endif
}

void BRIGAsmPrinter::EmitFunctionBodyEnd() {
  autoCodeEmitter ace(&OutStreamer, &brigantine);
  brigantine.endBody();
}

void BRIGAsmPrinter::EmitFunctionReturn(Type *Ty, bool IsKernel,
                                        StringRef RetName, bool IsSExt) {
  std::string SymName("%");
  SymName += RetName;

  assert((!Ty->isVectorTy() || !Ty->getScalarType()->isIntegerTy(1)) &&
         "i1 vectors do not work");

  const DataLayout &DL = getDataLayout();

  unsigned NElts = ~0u;
  Type *EmitTy = HSAIL::analyzeType(Ty, NElts, DL);

  // Construct return symbol.
  HSAIL_ASM::DirectiveVariable RetParam;
  if (NElts != 0) {
    RetParam = brigantine.addArrayVariable(
      SymName, NElts, BRIG_SEGMENT_ARG,
        HSAIL::getBrigType(EmitTy, DL, IsSExt));
  } else {
    RetParam = brigantine.addVariable(SymName, BRIG_SEGMENT_ARG,
                                      HSAIL::getBrigType(EmitTy, DL, IsSExt));
  }

  RetParam.align() = getBrigAlignment(DL.getABITypeAlignment(Ty));
  brigantine.addOutputParameter(RetParam);
}

uint64_t BRIGAsmPrinter::EmitFunctionArgument(Type *Ty, bool IsKernel,
                                              StringRef ArgName,
                                              bool IsSExt) {
  std::string Name;
  {
    raw_string_ostream Stream(Name);

    if (ArgName.empty())
      Stream << "%arg_p" << paramCounter;
    else
      Stream << '%' << HSAILParamManager::mangleArg(Mang, ArgName);
  }

  paramCounter++;

  const BrigSegment8_t SymSegment =
      IsKernel ? BRIG_SEGMENT_KERNARG : BRIG_SEGMENT_ARG;

  HSAIL_ASM::DirectiveVariable Sym;

  OpaqueType OT = GetOpaqueType(Ty);

  // Create the symbol.
  if (IsImage(OT)) {
    Sym = brigantine.addImage(Name, SymSegment);
    Sym.align() = BRIG_ALIGNMENT_8;
  } else if (OT == Sampler) {
    Sym = brigantine.addSampler(Name, SymSegment);
    Sym.align() = BRIG_ALIGNMENT_8;
  } else {
    const DataLayout &DL = getDataLayout();

    assert((!Ty->isVectorTy() || !Ty->getScalarType()->isIntegerTy(1)) &&
           "i1 vectors are broken");

    unsigned NElts = ~0u;
    Type *EmitTy = HSAIL::analyzeType(Ty, NElts, DL);

    if (NElts != 0) {
      BrigType EltTy = HSAIL::getBrigType(EmitTy, DL, IsSExt);
      Sym = brigantine.addArrayVariable(Name, NElts, SymSegment, EltTy);
    } else {
      Sym = brigantine.addVariable(Name, SymSegment,
                                   HSAIL::getBrigType(EmitTy, DL, IsSExt));
    }

    Sym.align() = getBrigAlignment(DL.getABITypeAlignment(Ty));
  }

  uint64_t Offset = Sym.brigOffset();
  brigantine.addInputParameter(Sym);
  return Offset;
}

/// Emit the function signature
void BRIGAsmPrinter::EmitFunctionEntryLabel() {
  const Function *F = MF->getFunction();
  bool IsKernel = HSAIL::isKernelFunc(F);
  const HSAILParamManager &PM =
      MF->getInfo<HSAILMachineFunctionInfo>()->getParamManager();

  SmallString<256> NameWithPrefix;
  getHSAILMangledName(NameWithPrefix, F);

  HSAIL_ASM::DirectiveExecutable Directive;
  if (IsKernel)
    Directive = brigantine.declKernel(makeSRef(NameWithPrefix));
  else
    Directive = brigantine.declFunc(makeSRef(NameWithPrefix));

  Directive.linkage() = findGlobalBrigLinkage(*F);

  const auto &Attrs = F->getAttributes();

  Type *RetType = F->getReturnType();
  if (!RetType->isVoidTy()) {
    bool IsSExt =
        Attrs.hasAttribute(AttributeSet::ReturnIndex, Attribute::SExt);
    bool IsZExt =
        Attrs.hasAttribute(AttributeSet::ReturnIndex, Attribute::ZExt);

    SmallString<256> ReturnName;
    getNameWithPrefix(ReturnName, F);

    if (IsSExt || IsZExt) {
      EmitFunctionReturn(Type::getInt32Ty(RetType->getContext()), IsKernel,
                         ReturnName, IsSExt);
    } else {
      EmitFunctionReturn(RetType, IsKernel, ReturnName, IsSExt);
    }
  }

  // Loop through all of the parameters and emit the types and
  // corresponding names.
  paramCounter = 0;

  // Clear arguments mapping.
  functionScalarArgumentOffsets.clear();
  functionVectorArgumentOffsets.clear();

  HSAILParamManager::param_iterator AI = PM.arg_begin();
  HSAILParamManager::param_iterator AE = PM.arg_end();

  FunctionType *FTy = F->getFunctionType();
  FunctionType::param_iterator PI = FTy->param_begin(),
                               PE = FTy->param_end();

  if (IsKernel && F->hasStructRetAttr()) {
    assert(PI != PE && "Invalid struct return function!");
    // If this is a struct-return function, don't process the hidden
    // struct-return argument.
    ++AI;
    ++PI;
  }

  for (unsigned N = 1; PI != PE; ++PI, ++AI, ++N) {
    assert(AI != AE);

    Type *Ty = *PI;
    const char *ArgName = PM.getParamName(*AI);

    // Here we will store an offset of DirectiveVariable
    bool IsSExt = Attrs.hasAttribute(N, Attribute::SExt);
    uint64_t ArgDirectiveOffset = EmitFunctionArgument(Ty, IsKernel, ArgName, IsSExt);
    functionScalarArgumentOffsets[ArgName] = ArgDirectiveOffset;
  }
}

//===------------------------------------------------------------------===//
// Dwarf Emission Helper Routines
//===------------------------------------------------------------------===//

bool BRIGAsmPrinter::getGroupVariableOffset(const GlobalVariable *GV,
                                            uint64_t *result) const {
  pvgvo_const_iterator i = groupVariablesOffsets.find(GV);
  if (i == groupVariablesOffsets.end()) {
    return false;
  }
  *result = i->second;
  return true;
}

bool BRIGAsmPrinter::getFunctionScalarArgumentOffset(const std::string &argName,
                                                     uint64_t *result) const {
  fao_iterator i = functionScalarArgumentOffsets.find(argName);
  if (i == functionScalarArgumentOffsets.end()) {
    return false;
  }
  *result = i->second;
  return true;
}

bool BRIGAsmPrinter::getFunctionVectorArgumentOffsets(
    const std::string &argName, VectorArgumentOffsets &result) const {
  fvo_iterator i = functionVectorArgumentOffsets.find(argName);
  if (i == functionVectorArgumentOffsets.end()) {
    return false;
  }
  result = i->second;
  return true;
}

void BRIGAsmPrinter::BrigEmitOperand(const MachineInstr *MI, unsigned opNum,
                                     HSAIL_ASM::Inst inst) {

  int AddressIndex =
      HSAIL::getNamedOperandIdx(MI->getOpcode(), HSAIL::OpName::address);
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

  BrigType16_t const expType = HSAIL_ASM::getOperandType(
      inst, m_opndList.size(), brigantine.getMachineModel(),
      brigantine.getProfile());

  switch (MO.getType()) {
  case MachineOperand::MO_Register:
    m_opndList.push_back(getBrigReg(MO));
    break;
  case MachineOperand::MO_Immediate:
    if (expType == BRIG_TYPE_B1) {
      m_opndList.push_back(
          brigantine.createImmed(MO.getImm() != 0 ? 1 : 0, expType));
    } else {
      m_opndList.push_back(brigantine.createImmed(MO.getImm(), expType));
    }
    break;
  case MachineOperand::MO_FPImmediate: {
    const ConstantFP *CFP = MO.getFPImm();
    if (CFP->getType()->isFloatTy()) {
      m_opndList.push_back(brigantine.createImmed(
          HSAIL_ASM::f32_t::fromRawBits(
              *CFP->getValueAPF().bitcastToAPInt().getRawData()),
          expType));
    } else if (CFP->getType()->isDoubleTy()) {
      m_opndList.push_back(brigantine.createImmed(
          HSAIL_ASM::f64_t::fromRawBits(
              *CFP->getValueAPF().bitcastToAPInt().getRawData()),
          expType));
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
                                                unsigned Segment) {
  assert(opNum + 2 < MI->getNumOperands());
  const MachineOperand &base = MI->getOperand(opNum),
                       &reg = MI->getOperand(opNum + 1),
                       &offset_op = MI->getOperand(opNum + 2);

  // Get offset
  assert(offset_op.isImm());
  int64_t offset = offset_op.getImm();

  // Get [%name]
  std::string base_name;
  if (base.isGlobal()) {
    SmallString<256> NameStr;
    getHSAILMangledName(NameStr, base.getGlobal());

    base_name = NameStr.str();
  }
  // Special cases for spill and private stack
  else if (base.isImm()) {
    int64_t addr = base.getImm();
    assert(isInt<32>(addr));
    assert(MI->getOpcode() == HSAIL::LD_SAMP);

    BrigEmitOperandImage(MI, opNum); // Constant sampler.
    return;
  }
  // Kernel or function argument
  else if (base.isSymbol()) {
    base_name = "%";
    base_name.append(base.getSymbolName());
  } else if (base.isMCSymbol()) {
    base_name = base.getMCSymbol()->getName();
  }

  // Get [$reg]
  HSAIL_ASM::SRef reg_name;
  if (reg.isReg() && reg.getReg() != 0) {
    reg_name = HSAIL_ASM::SRef(HSAILInstPrinter::getRegisterName(reg.getReg()));
  }

  const DataLayout &DL = getDataLayout();
  bool Is32Bit = (DL.getPointerSize(Segment) == 4);

  // Emit operand.
  m_opndList.push_back(
      brigantine.createRef(base_name, reg_name, offset, Is32Bit));
}

void BRIGAsmPrinter::BrigEmitVecArgDeclaration(const MachineInstr *MI) {
  const MachineOperand &Symbol =
      *TII->getNamedOperand(*MI, HSAIL::OpName::symbol);

  unsigned BT = TII->getNamedModifierOperand(*MI, HSAIL::OpName::TypeLength);
  int64_t NElts = TII->getNamedModifierOperand(*MI, HSAIL::OpName::size);
  unsigned Align = TII->getNamedModifierOperand(*MI, HSAIL::OpName::alignment);

  SmallString<64> Name;
  Name += '%';
  Name += Symbol.getSymbolName();

  HSAIL_ASM::DirectiveVariable ArgDecl;
  if (NElts != 0) {
    ArgDecl = brigantine.addArrayVariable(makeSRef(Name), NElts,
                                          BRIG_SEGMENT_ARG, BT);
  } else {
    ArgDecl = brigantine.addVariable(makeSRef(Name), BRIG_SEGMENT_ARG, BT);
  }

  ArgDecl.align() = getBrigAlignment(Align);
  ArgDecl.modifier().isDefinition() = true;
  ArgDecl.allocation() = BRIG_ALLOCATION_AUTOMATIC;
  ArgDecl.linkage() = BRIG_LINKAGE_ARG;

  return;
}

void BRIGAsmPrinter::BrigEmitOperandImage(const MachineInstr *MI,
                                          unsigned opNum) {
  MachineOperand object = MI->getOperand(opNum);
  unsigned idx = object.getImm();
  std::string sOp;
  // Indices for image_t and sampler_t args are biased, so now we un-bias them.
  // Note that the biased values rely on biasing performed by
  // HSAILPropagateImageOperands and HSAILISelLowering::LowerFormalArguments.
  if (idx < IMAGE_ARG_BIAS) {
    // This is the initialized sampler.
    HSAILSamplerHandle *hSampler =
        Subtarget->getImageHandles()->getSamplerHandle(idx);
    assert(hSampler && "Invalid sampler handle");
    std::string samplerName = hSampler->getSym();
    assert(!samplerName.empty() && "Expected symbol here");
    sOp = "&" + samplerName;
  } else {
    // This is the image
    std::string sym =
        Subtarget->getImageHandles()->getImageSymbol(idx - IMAGE_ARG_BIAS);
    assert(!sym.empty() && "Expected symbol here");
    sOp = "%" + sym;
  }

  m_opndList.push_back(brigantine.createRef(sOp));
}

HSAIL_ASM::OperandRegister BRIGAsmPrinter::getBrigReg(MachineOperand s) {
  assert(s.getType() == MachineOperand::MO_Register);
  return brigantine.createOperandReg(
    HSAIL_ASM::SRef(HSAILInstPrinter::getRegisterName(s.getReg())));
}

void BRIGAsmPrinter::BrigEmitVecOperand(const MachineInstr *MI,
                                        unsigned opStart, unsigned numRegs,
                                        HSAIL_ASM::Inst inst) {
  assert(numRegs >= 2 && numRegs <= 4);
  HSAIL_ASM::ItemList list;
  for (unsigned i = opStart; i < opStart + numRegs; ++i) {
    const MachineOperand &MO = MI->getOperand(i);
    if (MO.isReg()) {
      list.push_back(getBrigReg(MO));
    } else if (MO.isImm()) {
      BrigType16_t const expType = HSAIL_ASM::getOperandType(
          inst, m_opndList.size(), brigantine.getMachineModel(),
          brigantine.getProfile());
      list.push_back(brigantine.createImmed(MO.getImm(), expType));
    }
  }
  m_opndList.push_back(brigantine.createOperandList(list));
}

void BRIGAsmPrinter::BrigEmitImageInst(const MachineInstr *MI,
                                       HSAIL_ASM::InstImage inst) {
  unsigned opCnt = 0;

  if (inst.geometry() == BRIG_GEOMETRY_2DDEPTH ||
      inst.geometry() == BRIG_GEOMETRY_2DADEPTH) {
    BrigEmitOperand(MI, opCnt++, inst);
  } else {
    BrigEmitVecOperand(MI, opCnt, 4, inst);
    opCnt += 4;
  }

  switch (inst.opcode()) {
  case BRIG_OPCODE_RDIMAGE:
    BrigEmitOperand(MI, opCnt++, inst);
    BrigEmitOperand(MI, opCnt++, inst);
    break;
  case BRIG_OPCODE_LDIMAGE:
  case BRIG_OPCODE_STIMAGE:
    BrigEmitOperand(MI, opCnt++, inst);
    break;
  default:
    ;
  }

  switch (inst.geometry()) {
  case BRIG_GEOMETRY_1D:
  case BRIG_GEOMETRY_1DB:
    BrigEmitOperand(MI, opCnt++, inst);
    break;
  case BRIG_GEOMETRY_1DA:
  case BRIG_GEOMETRY_2D:
  case BRIG_GEOMETRY_2DDEPTH:
    BrigEmitVecOperand(MI, opCnt, 2, inst);
    opCnt += 2;
    break;
  case BRIG_GEOMETRY_2DA:
  case BRIG_GEOMETRY_2DADEPTH:
  case BRIG_GEOMETRY_3D:
    BrigEmitVecOperand(MI, opCnt, 3, inst);
    opCnt += 3;
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
  inst.modifier().ftz() =
      TII->getNamedOperand(MI, HSAIL::OpName::ftz)->getImm();

  inst.round() = TII->getNamedOperand(MI, HSAIL::OpName::round)->getImm();

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

  inst.compare() = TII->getNamedOperand(MI, HSAIL::OpName::op)->getImm();

  inst.modifier().ftz() =
      TII->getNamedOperand(MI, HSAIL::OpName::ftz)->getImm();

  inst.type() =
      TII->getNamedOperand(MI, HSAIL::OpName::destTypedestLength)->getImm();
  inst.sourceType() =
      TII->getNamedOperand(MI, HSAIL::OpName::sourceType)->getImm();

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

  inst.type() =
      TII->getNamedOperand(MI, HSAIL::OpName::destTypedestLength)->getImm();
  inst.sourceType() =
      TII->getNamedOperand(MI, HSAIL::OpName::sourceType)->getImm();

  // XXX - sourceType, destTypedestLength - These names are awful
  inst.modifier().ftz() =
      TII->getNamedOperand(MI, HSAIL::OpName::ftz)->getImm();
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
  HSAIL_ASM::InstSourceType inst =
      brigantine.addInst<HSAIL_ASM::InstSourceType>(BrigOpc);

  unsigned Opc = MI.getOpcode();

  inst.type() = TII->getNamedOperand(MI, HSAIL::OpName::TypeLength)->getImm();
  inst.sourceType() =
      TII->getNamedOperand(MI, HSAIL::OpName::sourceType)->getImm();

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
  inst.sourceType() =
      TII->getNamedOperand(MI, HSAIL::OpName::sourceType)->getImm();

  inst.width() = TII->getNamedOperand(MI, HSAIL::OpName::width)->getImm();

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
  HSAIL_ASM::InstSegCvt inst =
      brigantine.addInst<HSAIL_ASM::InstSegCvt>(BrigOpc);
  unsigned Opc = MI.getOpcode();

  inst.type() =
      TII->getNamedOperand(MI, HSAIL::OpName::destTypedestLength)->getImm();

  inst.sourceType() =
      TII->getNamedOperand(MI, HSAIL::OpName::sourceType)->getImm();

  unsigned Segment = TII->getNamedOperand(MI, HSAIL::OpName::segment)->getImm();
  inst.segment() = getHSAILSegment(Segment);

  inst.modifier().isNoNull() =
      TII->getNamedOperand(MI, HSAIL::OpName::nonull)->getImm();

  int DestIdx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::dest);
  BrigEmitOperand(&MI, DestIdx, inst);

  int Src0Idx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src0);
  BrigEmitOperand(&MI, Src0Idx, inst);

  return inst;
}

HSAIL_ASM::InstMemFence
BRIGAsmPrinter::BrigEmitInstMemFence(const MachineInstr &MI, unsigned BrigOpc) {
  HSAIL_ASM::InstMemFence inst =
      brigantine.addInst<HSAIL_ASM::InstMemFence>(BrigOpc, BRIG_TYPE_NONE);

  // FIXME: libHSAIL seems to not have been updated for change to remove
  // separate segment scope modifiers.
  inst.memoryOrder() = TII->getNamedModifierOperand(MI, HSAIL::OpName::order);
  inst.globalSegmentMemoryScope() =
      TII->getNamedModifierOperand(MI, HSAIL::OpName::scope);
  inst.groupSegmentMemoryScope() = inst.globalSegmentMemoryScope();
  inst.imageSegmentMemoryScope() = BRIG_MEMORY_SCOPE_NONE;

  return inst;
}

HSAIL_ASM::InstMem BRIGAsmPrinter::BrigEmitInstMem(const MachineInstr &MI,
                                                   unsigned BrigOpc) {
  HSAIL_ASM::InstMem inst = brigantine.addInst<HSAIL_ASM::InstMem>(BrigOpc);

  unsigned VecSize = 1; // FIXME: Stop special casing this.
  switch (MI.getOpcode()) {
  case HSAIL::LD_V2_S32:
  case HSAIL::LD_V2_U32:
  case HSAIL::LD_V2_F32:
  case HSAIL::LD_V2_S64:
  case HSAIL::LD_V2_U64:
  case HSAIL::LD_V2_F64:

  case HSAIL::ST_V2_U32:
  case HSAIL::ST_V2_F32:
  case HSAIL::ST_V2_U64:
  case HSAIL::ST_V2_F64:

  case HSAIL::RARG_LD_V2_S32:
  case HSAIL::RARG_LD_V2_U32:
  case HSAIL::RARG_LD_V2_F32:
  case HSAIL::RARG_LD_V2_S64:
  case HSAIL::RARG_LD_V2_U64:
  case HSAIL::RARG_LD_V2_F64:
    VecSize = 2;
    break;

  case HSAIL::LD_V3_S32:
  case HSAIL::LD_V3_U32:
  case HSAIL::LD_V3_F32:
  case HSAIL::LD_V3_S64:
  case HSAIL::LD_V3_U64:
  case HSAIL::LD_V3_F64:

  case HSAIL::ST_V3_U32:
  case HSAIL::ST_V3_F32:
  case HSAIL::ST_V3_U64:
  case HSAIL::ST_V3_F64:

  case HSAIL::RARG_LD_V3_S32:
  case HSAIL::RARG_LD_V3_U32:
  case HSAIL::RARG_LD_V3_F32:
  case HSAIL::RARG_LD_V3_S64:
  case HSAIL::RARG_LD_V3_U64:
  case HSAIL::RARG_LD_V3_F64:
    VecSize = 3;
    break;

  case HSAIL::LD_V4_S32:
  case HSAIL::LD_V4_U32:
  case HSAIL::LD_V4_F32:
  case HSAIL::LD_V4_S64:
  case HSAIL::LD_V4_U64:
  case HSAIL::LD_V4_F64:

  case HSAIL::ST_V4_U32:
  case HSAIL::ST_V4_F32:
  case HSAIL::ST_V4_U64:
  case HSAIL::ST_V4_F64:

  case HSAIL::RARG_LD_V4_S32:
  case HSAIL::RARG_LD_V4_U32:
  case HSAIL::RARG_LD_V4_F32:
  case HSAIL::RARG_LD_V4_S64:
  case HSAIL::RARG_LD_V4_U64:
  case HSAIL::RARG_LD_V4_F64:
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
  if (const MachineOperand *Mask =
          TII->getNamedOperand(MI, HSAIL::OpName::mask))
    inst.modifier().isConst() = Mask->getImm() & BRIG_MEMORY_CONST;

  if (const MachineOperand *Width =
          TII->getNamedOperand(MI, HSAIL::OpName::width))
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
  HSAIL_ASM::InstAtomic inst =
      brigantine.addInst<HSAIL_ASM::InstAtomic>(BrigOpc);
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

  int Src0Idx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src0);
  if (Src0Idx != -1)
    BrigEmitOperand(&MI, Src0Idx, inst);

  int Src1Idx = HSAIL::getNamedOperandIdx(Opc, HSAIL::OpName::src1);
  if (Src1Idx != -1)
    BrigEmitOperand(&MI, Src1Idx, inst);

  return inst;
}

HSAIL_ASM::InstImage BRIGAsmPrinter::BrigEmitInstImage(const MachineInstr &MI,
                                                       unsigned BrigOpc) {
  HSAIL_ASM::InstImage inst = brigantine.addInst<HSAIL_ASM::InstImage>(BrigOpc);
  unsigned Opc = MI.getOpcode();

  inst.imageType() =
      TII->getNamedOperand(MI, HSAIL::OpName::imageType)->getImm();
  inst.coordType() =
      TII->getNamedOperand(MI, HSAIL::OpName::coordType)->getImm();
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
  for (MachineFunction::const_iterator I = MF->begin(), E = MF->end(); I != E;
       ++I) {
    for (MachineBasicBlock::const_iterator II = I->begin(), IE = I->end();
         II != IE; ++II) {
      switch (II->getOpcode()) {
      default:
        continue;
      case HSAIL::GCN_ATOMIC_APPEND_U32:
      case HSAIL::GCN_ATOMIC_CONSUME_U32:
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
