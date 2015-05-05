//===-- HSAILAsmPrinter.cpp - HSAIL Assembly printer ----------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
/// \file
///
/// The HSAILAsmPrinter is used to print both assembly string and also binary
/// code.  When passed an MCAsmStreamer it prints assembly and when passed
/// an MCObjectStreamer it outputs binary code.
//
//===----------------------------------------------------------------------===//
//

#include "HSAILAsmPrinter.h"
#include "HSAIL.h"
#include "HSAILMCInstLower.h"
#include "HSAILUtilityFunctions.h"
#include "HSAILSubtarget.h"
#include "HSAILStoreInitializer.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCSectionELF.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCValue.h"
#include "llvm/Support/Format.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Target/TargetLoweringObjectFile.h"

using namespace llvm;

static AsmPrinter *createHSAILAsmPrinterPass(TargetMachine &tm,
                                             MCStreamer &Streamer) {
  return new HSAILAsmPrinter(tm, Streamer);
}

extern "C" void LLVMInitializeHSAILAsmPrinter() {
  TargetRegistry::RegisterAsmPrinter(TheHSAIL_32Target,
                                     createHSAILAsmPrinterPass);
  TargetRegistry::RegisterAsmPrinter(TheHSAIL_64Target,
                                     createHSAILAsmPrinterPass);
}

HSAILAsmPrinter::HSAILAsmPrinter(TargetMachine &TM, MCStreamer &Streamer)
    : AsmPrinter(TM, Streamer) {}

bool HSAILAsmPrinter::doFinalization(Module &M) {
  EmitEndOfAsmFile(M);
  return false;
}

bool HSAILAsmPrinter::runOnMachineFunction(MachineFunction &MF) {
  SetupMachineFunction(MF);

  EmitFunctionEntryLabel();
  OutStreamer.SwitchSection(getObjFileLowering().getTextSection());
  EmitFunctionBody();

  return false;
}

static bool canInitAddressSpace(unsigned AS) {
  return AS == HSAILAS::READONLY_ADDRESS || AS == HSAILAS::GLOBAL_ADDRESS;
}

static StringRef getSegmentName(unsigned AS) {
  switch (AS) {
  case HSAILAS::GLOBAL_ADDRESS:
    return "global";
  case HSAILAS::READONLY_ADDRESS:
    return "readonly";
  case HSAILAS::GROUP_ADDRESS:
    return "group";
  case HSAILAS::PRIVATE_ADDRESS:
    return "private";
  default:
    llvm_unreachable("unhandled segment");
  }
}

static bool isProgramLinkage(const GlobalValue &GV) {
  switch (GV.getLinkage()) {
  case GlobalValue::ExternalLinkage:
  case GlobalValue::WeakAnyLinkage:
  case GlobalValue::WeakODRLinkage:
  case GlobalValue::AvailableExternallyLinkage:
  case GlobalValue::ExternalWeakLinkage:
  case GlobalValue::AppendingLinkage:
    return true;

  default:
    return false;
  }
}

static bool isModuleLinkage(const GlobalValue &GV) {
  return !isProgramLinkage(GV);
}

void HSAILAsmPrinter::EmitFunctionArgument(unsigned ParamIndex,
                                           const Argument &A, bool IsKernel,
                                           bool IsSExt, raw_ostream &O) const {
  const DataLayout &DL = getDataLayout();
  Type *Ty = A.getType();

  unsigned NElts = ~0u;
  Type *EltTy = HSAIL::analyzeType(Ty, NElts, DL);

  if (NElts > 1) {
    unsigned ABIAlign = DL.getABITypeAlignment(Ty);
    if (ABIAlign != DL.getABITypeAlignment(EltTy))
      O << "align(" << ABIAlign << ") ";
  }

  // TODO_HSA: Need to emit alignment information.
  O << (IsKernel ? "kernarg" : "arg") << '_' << getArgTypeName(EltTy, IsSExt)
    << ' ' << '%';

  StringRef Name = A.getName();
  if (Name.empty())
    O << "arg_p" << ParamIndex;
  else
    O << Name;

  // For vector args, we'll use an HSAIL array.
  if (NElts != 0)
    O << '[' << NElts << ']';
}

void HSAILAsmPrinter::EmitFunctionReturn(Type *Ty, StringRef Name,
                                         bool IsKernel, bool IsSExt,
                                         raw_ostream &O) const {
  const DataLayout &DL = getDataLayout();

  unsigned NElts = ~0u;
  Type *EltTy = HSAIL::analyzeType(Ty, NElts, DL);

  if (NElts > 1) {
    unsigned ABIAlign = DL.getABITypeAlignment(Ty);
    if (ABIAlign != DL.getABITypeAlignment(EltTy))
      O << "align(" << ABIAlign << ") ";
  }

  O << (IsKernel ? "kernarg" : "arg") << '_' << getArgTypeName(EltTy, IsSExt)
    << ' ' << '%' << Name;
  if (NElts != 0)
    O << '[' << NElts << ']';
}

void HSAILAsmPrinter::EmitFunctionLabel(const Function &F, raw_ostream &O,
                                        bool IsDecl) const {
  Type *RetTy = F.getReturnType();

  // FIXME: Should define HSA calling conventions.
  bool IsKernel = HSAIL::isKernelFunc(&F);

  SmallString<256> Name;
  getHSAILMangledName(Name, &F);

  O << (IsKernel ? "kernel " : "function ") << Name << '(';

  // Functions with kernel linkage cannot have output args.
  if (!IsKernel) {
    // TODO_HSA: Need "good" names for the formal arguments and returned value.
    // TODO_HSA: Need to emit alignment information..
    if (!RetTy->isVoidTy()) {
      StringRef RetName = IsDecl ? "ret" : F.getName();

      const auto &RetAttrs = F.getAttributes().getRetAttributes();

      bool IsSExt =
          RetAttrs.hasAttribute(AttributeSet::ReturnIndex, Attribute::SExt);
      bool IsZExt =
          RetAttrs.hasAttribute(AttributeSet::ReturnIndex, Attribute::ZExt);

      if (IsSExt || IsZExt) {
        EmitFunctionReturn(Type::getInt32Ty(RetTy->getContext()), RetName,
                           IsKernel, IsSExt, O);
      } else
        EmitFunctionReturn(RetTy, RetName, IsKernel, IsSExt, O);
    }

    O << ")(";
  }

  const auto &Attrs = F.getAttributes();

  // Avoid ugly line breaks with small argument lists.
  unsigned NArgs = F.arg_size();
  if (NArgs == 0) {
    O << ')';
  } else if (NArgs == 1) {
    bool IsSExt = Attrs.hasAttribute(1, Attribute::SExt);
    EmitFunctionArgument(0, *F.arg_begin(), IsKernel, IsSExt, O);
    O << ')';
  } else {
    O << "\n\t";

    // Loop through all of the parameters and emit the types and corresponding
    // names.
    unsigned Index = 0;
    for (Function::const_arg_iterator I = F.arg_begin(), E = F.arg_end();
         I != E; ++Index) {
      bool IsSExt = Attrs.hasAttribute(Index + 1, Attribute::SExt);
      EmitFunctionArgument(Index, *I++, IsKernel, IsSExt, O);
      if (I != E)
        O << ",\n\t";
    }

    O << ')';
  }
}

// FIXME: Doesn't make sense to rely on address space for this.
char HSAILAsmPrinter::getSymbolPrefixForAddressSpace(unsigned AS) {
  return (AS == HSAILAS::GROUP_ADDRESS || AS == HSAILAS::PRIVATE_ADDRESS) ? '%'
                                                                          : '&';
}

// FIXME: Duplicated in BRIGAsmPrinter
char HSAILAsmPrinter::getSymbolPrefix(const MCSymbol &Sym) const {
  const GlobalVariable *GV = MMI->getModule()->getNamedGlobal(Sym.getName());
  assert(GV && "Need prefix for undefined GlobalVariable");

  unsigned AS = GV->getType()->getAddressSpace();
  return getSymbolPrefixForAddressSpace(AS);
}

void HSAILAsmPrinter::printInitVarWithAddressPragma(StringRef VarName,
                                                    uint64_t BaseOffset,
                                                    const MCExpr *Expr,
                                                    unsigned EltSize,
                                                    raw_ostream &O) {
  MCValue Val;
  bool Res = Expr->EvaluateAsValue(Val, nullptr, nullptr);
  (void)Res;
  assert(Res && "Could not evaluate MCExpr");
  assert(!Val.getSymB() && "Multi-symbol expressions not handled");

  const MCSymbol &Sym = Val.getSymA()->getSymbol();

  O << "pragma \"initvarwithaddress:" << VarName << ':'
    << BaseOffset // Offset into the destination.
    << ':' << EltSize << ':' << getSymbolPrefix(Sym) << Sym.getName() << ':'
    << Val.getConstant() // Offset of the symbol being written.
    << '\"' << ';' << '\n';
}

void HSAILAsmPrinter::printFloat(uint32_t Val, raw_ostream &O) {
  O << format("0F%" PRIx32, Val);
}

void HSAILAsmPrinter::printDouble(uint64_t Val, raw_ostream &O) {
  O << format("0F%" PRIx64, Val);
}

void HSAILAsmPrinter::printConstantFP(const ConstantFP *CFP, raw_ostream &O) {
  uint64_t Val = CFP->getValueAPF().bitcastToAPInt().getZExtValue();
  if (CFP->getType()->isFloatTy())
    printFloat(static_cast<uint32_t>(Val), O);
  else if (CFP->getType()->isDoubleTy())
    printDouble(Val, O);
  else
    llvm_unreachable("unhandled ConstantFP");
}

void HSAILAsmPrinter::printScalarConstant(const Constant *CPV,
                                          SmallVectorImpl<AddrInit> &Addrs,
                                          uint64_t &TotalSizeEmitted,
                                          const DataLayout &DL,
                                          raw_ostream &O) {
  if (const ConstantInt *CI = dyn_cast<ConstantInt>(CPV)) {
    TotalSizeEmitted += DL.getTypeAllocSize(CI->getType());
    O << CI->getValue();
    return;
  }

  if (const ConstantFP *CFP = dyn_cast<ConstantFP>(CPV)) {
    TotalSizeEmitted += DL.getTypeAllocSize(CFP->getType());
    printConstantFP(CFP, O);
    return;
  }

  if (const ConstantDataSequential *CDS =
          dyn_cast<ConstantDataSequential>(CPV)) {
    for (unsigned I = 0, E = CDS->getNumElements(); I != E; ++I) {
      if (I > 0)
        O << ", ";

      const Constant *Elt = CDS->getElementAsConstant(I);
      printScalarConstant(Elt, Addrs, TotalSizeEmitted, DL, O);
    }

    return;
  }

  if (isa<ConstantPointerNull>(CPV)) {
    TotalSizeEmitted += DL.getTypeAllocSize(CPV->getType());
    O << '0';
    return;
  }

  if (const GlobalValue *GV = dyn_cast<GlobalValue>(CPV)) {
    O << '0';

    auto ME = MCSymbolRefExpr::Create(getSymbol(GV), OutContext);
    Addrs.push_back(std::make_pair(TotalSizeEmitted, ME));
    TotalSizeEmitted += DL.getTypeAllocSize(GV->getType());
    return;
  }

  if (const ConstantExpr *CExpr = dyn_cast<ConstantExpr>(CPV)) {
    const MCExpr *ME = lowerConstant(CPV);
    O << '0';

    Addrs.push_back(std::make_pair(TotalSizeEmitted, ME));
    TotalSizeEmitted += DL.getTypeAllocSize(CExpr->getType());
    return;
  }

  llvm_unreachable("unhandled scalar constant type");
}

void HSAILAsmPrinter::printGVInitialValue(const GlobalValue &GV,
                                          const Constant *CV,
                                          const DataLayout &DL,
                                          raw_ostream &O) {
  if (const ConstantInt *CI = dyn_cast<ConstantInt>(CV)) {
    if (CI->getType()->isIntegerTy(1))
      O << (CI->getZExtValue() ? '1' : '0') << ';';
    else
      O << CI->getValue() << ';';
    return;
  }

  if (const ConstantFP *CFP = dyn_cast<ConstantFP>(CV)) {
    printConstantFP(CFP, O);
    O << ';';
    return;
  }

  unsigned NElts = 1;
  Type *EltTy = HSAIL::analyzeType(CV->getType(), NElts, DL);

  unsigned EltSize = DL.getTypeAllocSize(EltTy);
  SmallVector<AddrInit, 16> AddrInits;

  // Write other cases as byte array.
  StoreInitializer store(EltTy, *this);

  store.append(CV, GV.getName());

  // Make sure this is actually an array. For the special case of a single
  // pointer initializer, we don't want the braces.
  if (NElts != 0)
    O << getArgTypeName(EltTy) << "[](";

  store.print(O);

  if (NElts != 0)
    O << ')';

  O << ';';

  if (!store.varInitAddresses().empty())
    O << '\n';

  for (const auto &VarInit : store.varInitAddresses()) {
    char Pre = getSymbolPrefixForAddressSpace(GV.getType()->getAddressSpace());
    SmallString<128> Name;
    Name += Pre;
    Name += GV.getName();

    printInitVarWithAddressPragma(Name, VarInit.BaseOffset, VarInit.Expr,
                                  EltSize, O);
  }

  O << '\n';
}

void HSAILAsmPrinter::getHSAILMangledName(SmallString<256> &NameStr,
                                          const GlobalValue *GV) const {
  if (isa<Function>(GV))
    NameStr += '&';
  else if (const GlobalAlias *GA = dyn_cast<GlobalAlias>(GV)) {
    if (isa<Function>(GA->getAliasee()))
      NameStr += '&';
    else
      llvm_unreachable("Not handled");
  } else {
    unsigned AS = GV->getType()->getAddressSpace();
    NameStr += getSymbolPrefixForAddressSpace(AS);
  }

  SmallString<256> Mangled;
  SmallString<256> Sanitized;

  getNameWithPrefix(Mangled, GV);

  NameStr += Mangled;

#if 0
  // FIXME: We need a way to deal with invalid identifiers, e.g. leading
  // period. We can replace them with something here, but need a way to resolve
  // possible conflicts.
  if (HSAIL::sanitizedGlobalValueName(Mangled, Sanitized))
    NameStr += Sanitized;
  else
    NameStr += Mangled;
#endif
}

// FIXME: Mostly duplicated in BRIGAsmPrinter
static void printAlignTypeQualifier(const GlobalValue &GV, const DataLayout &DL,
                                    Type *InitTy, Type *EmitTy, unsigned NElts,
                                    bool IsLocal, raw_ostream &O) {
  unsigned Alignment = GV.getAlignment();
  if (Alignment == 0)
    Alignment = DL.getPrefTypeAlignment(InitTy);
  else {
    // If an alignment is specified, it must be equal to or greater than the
    // variable's natural alignment.
    unsigned NaturalAlign = IsLocal ? DL.getPrefTypeAlignment(EmitTy)
                                    : DL.getABITypeAlignment(EmitTy);

    Alignment = std::max(Alignment, NaturalAlign);
  }

  // Align arrays at least by 4 bytes
  if (Alignment < 4 && NElts != 0)
    Alignment = 4;

  if (Alignment != DL.getABITypeAlignment(EmitTy))
    O << "align(" << Alignment << ") ";
}

void HSAILAsmPrinter::EmitGlobalVariable(const GlobalVariable *GV) {
  if (HSAIL::isIgnoredGV(GV))
    return;

  SmallString<256> Name;
  getHSAILMangledName(Name, GV);

  SmallString<1024> Str;
  raw_svector_ostream O(Str);
  const DataLayout &DL = getDataLayout();

  PointerType *Ty = GV->getType();
  Type *InitTy = Ty->getElementType();
  unsigned AS = Ty->getAddressSpace();

  if (isProgramLinkage(*GV))
    O << "prog ";

  if (AS != HSAILAS::READONLY_ADDRESS)
    O << "alloc(agent) ";

  unsigned NElts = ~0u;
  Type *EmitTy = HSAIL::analyzeType(InitTy, NElts, DL);

  printAlignTypeQualifier(*GV, DL, InitTy, EmitTy, NElts, false, O);

  O << getSegmentName(AS) << '_' << getArgTypeName(EmitTy) << ' ' << Name;

  if (NElts != 0)
    O << '[' << NElts << ']';

  // TODO_HSA: if group memory has initializer, then emit instructions to
  // initialize dynamically.
  if (GV->hasInitializer() && canInitAddressSpace(AS)) {
    const Constant *Init = cast<Constant>(GV->getInitializer());

    if (isa<UndefValue>(Init))
      O << ';';
    else {
      O << " = ";

      // Emit trivial zero initializers as a single 0.
      if (Init->isNullValue()) {
        Type *Ty = Init->getType();
        if (Ty->isAggregateType() || Ty->isVectorTy()) {
          O << getArgTypeName(EmitTy) << "[](";

          // FIXME: Use uint64_t for NElts
          for (unsigned I = 0; I < NElts; ++I) {
            if (I > 0)
              O << ", ";
            O << '0';
          }

          O << ')';
        } else
          O << '0';
        O << ';';
      } else {
        printGVInitialValue(*GV, Init, DL, O);
      }
    }
  } else {
    O << ';';
  }

  OutStreamer.EmitRawText(O.str());
}

void HSAILAsmPrinter::EmitStartOfAsmFile(Module &M) {
  SmallString<32> Str;
  raw_svector_ostream O(Str);

  const HSAILSubtarget *Subtarget = &TM.getSubtarget<HSAILSubtarget>();

  O << "module &__llvm_hsail_module:" << BRIG_VERSION_HSAIL_MAJOR << ':'
    << BRIG_VERSION_HSAIL_MINOR << ':'
    << (Subtarget->isFull() ? "$full" : "$base") << ':'
    << (Subtarget->is64Bit() ? "$large" : "$small") << ':'
    << "$near" // TODO: Get from somewhere
    << ";\n\n";

  if (Subtarget->isGCN())
    O << "extension \"amd:gcn\";\n";

  if (Subtarget->hasImages())
    O << "extension \"IMAGE\";\n";

  OutStreamer.EmitRawText(O.str());

  for (const GlobalVariable &GV : M.globals()) {
    unsigned AS = GV.getType()->getAddressSpace();
    if (AS != HSAILAS::PRIVATE_ADDRESS && AS != HSAILAS::GROUP_ADDRESS)
      EmitGlobalVariable(&GV);
  }

  // Emit function declarations, except for kernels or intrinsics.
  for (const Function &F : M) {
    if (F.isIntrinsic())
      continue;

    if (F.isDeclaration() && isModuleLinkage(F))
      continue;

    if (!HSAIL::isKernelFunc(&F)) {
      Str.clear();
      O.resync();

      O << "decl ";

      if (isProgramLinkage(F))
        O << "prog ";

      EmitFunctionLabel(F, O, true);
      O << ";\n\n";
      OutStreamer.EmitRawText(O.str());
    }
  }
}

StringRef HSAILAsmPrinter::getArgTypeName(Type *Ty, bool Signed) const {
  switch (Ty->getTypeID()) {
  case Type::VoidTyID:
    break;
  case Type::FloatTyID:
    return "f32";
  case Type::DoubleTyID:
    return "f64";
  case Type::IntegerTyID: {
    switch (Ty->getIntegerBitWidth()) {
    case 32:
      return Signed ? "s32" : "u32";
    case 64:
      return Signed ? "s64" : "u64";
    case 1:
      return "b1";
    case 8:
      return Signed ? "s8" : "u8";
    case 16:
      return Signed ? "s16" : "u16";
    default:
      llvm_unreachable("unhandled integer width argument");
    }
  }
  case Type::PointerTyID: {
    const PointerType *PT = cast<PointerType>(Ty);
    const StructType *ST = dyn_cast<StructType>(PT->getElementType());
    const HSAILSubtarget *Subtarget = &TM.getSubtarget<HSAILSubtarget>();
    if (ST && ST->isOpaque()) {
      StringRef Name = ST->getName();
      if (Name.startswith("struct._image1d_t") ||
          Name.startswith("struct._image1d_array_t") ||
          Name.startswith("struct._image1d_buffer_t") ||
          Name.startswith("struct._image2d_t") ||
          Name.startswith("struct._image2d_array_t") ||
          Name.startswith("struct._image3d_t")) {
        return "_RWImg";
      } else if (Name.startswith("struct._sampler_t")) {
        return "_Samp";
      } else if (Name == "struct._counter32_t" || Name == "struct._event_t") {
        return Subtarget->is64Bit() ? "u64" : "u32";
      } else {
        llvm_unreachable("unhandled struct type argument");
      }
    } else {
      unsigned AS = PT->getAddressSpace();
      return getDataLayout().getPointerSize(AS) == 4 ? "u32" : "u64";
    }
  }
  case Type::StructTyID: // Treat struct as array of bytes.
    return "u8";

  case Type::VectorTyID:
  case Type::ArrayTyID: {
    // Treat as array of elements.
    const SequentialType *ST = cast<SequentialType>(Ty);

    return getArgTypeName(ST->getElementType());
  }
  default:
    llvm_unreachable("unhandled argument type id");
  }

  return "";
}

void HSAILAsmPrinter::EmitFunctionEntryLabel() {
  std::string FunStr;
  raw_string_ostream O(FunStr);

  const Function *F = MF->getFunction();

  if (isProgramLinkage(*F))
    O << "prog ";
  EmitFunctionLabel(*F, O, false);
  O << "\n{";

  OutStreamer.EmitRawText(O.str());
}

void HSAILAsmPrinter::EmitFunctionBodyStart() {
  std::string FunStr;
  raw_string_ostream O(FunStr);

  const DataLayout &DL = getDataLayout();
  const Function *F = MF->getFunction();

#if 0
  if (isKernelFunc(*F)) { // Emitting block data inside of kernel.
    uint32_t id = 0;
    mMeta->setID(id);
    mMeta->setKernel(true);
    ++mBuffer;
    if (isKernel) {
      mMeta->printHeader(mKernelName);
      if (isOpenCLKernel)
        mMeta->processArgMetadata(O, mBuffer, isKernel);
      mMeta->printMetaData(O, id, isKernel);
    }
  }
#endif

  SmallPtrSet<const GlobalVariable *, 16> FuncPvtVarsSet;
  SmallPtrSet<const GlobalVariable *, 16> FuncGrpVarsSet;
  for (const MachineBasicBlock &MBB : *MF) {
    for (const MachineInstr &MI : MBB) {
      for (const MachineOperand &MO : MI.operands()) {
        if (!MO.isGlobal())
          continue;

        const GlobalVariable *GV = dyn_cast<GlobalVariable>(MO.getGlobal());
        if (!GV)
          continue;

        unsigned AS = GV->getType()->getAddressSpace();
        if (AS == HSAILAS::PRIVATE_ADDRESS)
          FuncPvtVarsSet.insert(GV);

        if (AS == HSAILAS::GROUP_ADDRESS)
          FuncGrpVarsSet.insert(GV);
      }
    }
  }

  // Emit group variable declarations.
  const Module *M = MF->getMMI().getModule();
  for (const GlobalVariable &GV : M->globals()) {
    PointerType *Ty = GV.getType();
    unsigned AS = Ty->getAddressSpace();
    if (AS == HSAILAS::GROUP_ADDRESS) {
      if (FuncGrpVarsSet.count(&GV)) {
        std::string str;
        O << '\t';

        Type *InitTy = Ty->getElementType();

        unsigned NElts = ~0u;
        Type *EmitTy = HSAIL::analyzeType(InitTy, NElts, DL);
        printAlignTypeQualifier(GV, DL, InitTy, EmitTy, NElts, true, O);

        O << getSegmentName(AS) << '_' << getArgTypeName(EmitTy) << " %"
          << GV.getName();

        if (NElts != 0)
          O << '[' << NElts << ']';

        O << ";\n";
      }
    }
  }

  O << '\n';

  // Emit private variable declarations.
  for (const GlobalVariable &GV : M->globals()) {
    PointerType *Ty = GV.getType();
    unsigned AS = Ty->getAddressSpace();
    if (AS == HSAILAS::PRIVATE_ADDRESS) {
      if (FuncPvtVarsSet.count(&GV)) {
        StringRef GVname = GV.getName();
        bool ChangeName = false;
        SmallVector<StringRef, 10> NameParts;
        const char *tmp_opt_name = "tmp_opt_var";
        std::string str;
        if (GVname.empty()) {
          str = tmp_opt_name;
          ChangeName = true;
        } else if (!isalpha(GVname[0]) && GVname[0] != '_') {
          str = tmp_opt_name;
          str.append(GVname);
          ChangeName = true;
        }

        { // replace all '.' with '_'
          size_t pos = str.find('.');
          if (pos != std::string::npos)
            ChangeName = true;

          while (pos != std::string::npos) {
            str.replace(pos++, 1, "_");
            pos = str.find('.', pos);
          }
        }

        if (ChangeName) {
          // FIXME
          (const_cast<GlobalVariable *>(&GV))->setName(str);
        }

        O << '\t';

        Type *InitTy = Ty->getElementType();

        unsigned NElts = ~0u;
        Type *EmitTy = HSAIL::analyzeType(InitTy, NElts, DL);

        printAlignTypeQualifier(GV, DL, InitTy, EmitTy, NElts, true, O);
        str = "";

        O << '_' << getArgTypeName(EmitTy) << " %" << GV.getName();
        if (NElts != 0)
          O << '[' << NElts << ']';

        if (GV.hasInitializer() && canInitAddressSpace(AS)) {
          O << " = ";
          printGVInitialValue(GV, cast<Constant>(GV.getInitializer()), DL, O);
        }
      }
    }
  }

  const MachineFrameInfo *MFI = MF->getFrameInfo();
  size_t StackSize = MFI->getOffsetAdjustment() + MFI->getStackSize();
  if (StackSize) {
    // Dimension is in units of type length.
    O << "\tspill_u32 %stack[" << (StackSize >> 2) << "];\n";
  }

  O << '@' << F->getName() << "_entry:\n";

#if 0
  // Allocate gcn region for gcn atomic counter, if required.
  if (usesGCNAtomicCounter())
    O << "\tgcn_region_alloc 4;\n";
#endif

  OutStreamer.EmitRawText(O.str());
}

void HSAILAsmPrinter::EmitFunctionBodyEnd() { OutStreamer.EmitRawText("};"); }

void HSAILAsmPrinter::EmitInstruction(const MachineInstr *MI) {
  HSAILMCInstLower MCInstLowering(OutContext, *this);

  MCInst TmpInst;
  MCInstLowering.lower(MI, TmpInst);
  EmitToStreamer(OutStreamer, TmpInst);
}
