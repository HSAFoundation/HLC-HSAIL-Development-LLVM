//===-- HSAILAsmPrinter.cpp - HSAIL Assebly printer  ----------------------===//
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

#include "Brig_new.hpp"

using namespace llvm;

static AsmPrinter *createHSAILAsmPrinterPass(TargetMachine &tm,
                                             MCStreamer &Streamer) {
  return new HSAILAsmPrinter(tm, Streamer);
}

extern "C" void LLVMInitializeHSAILAsmPrinter() {
  TargetRegistry::RegisterAsmPrinter(TheHSAIL_32Target, createHSAILAsmPrinterPass);
  TargetRegistry::RegisterAsmPrinter(TheHSAIL_64Target, createHSAILAsmPrinterPass);
}

HSAILAsmPrinter::HSAILAsmPrinter(TargetMachine &TM, MCStreamer &Streamer)
    : AsmPrinter(TM, Streamer) {
}

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
  return AS == HSAILAS::CONSTANT_ADDRESS || AS == HSAILAS::GLOBAL_ADDRESS;
}

static StringRef getSegmentName(unsigned AS) {
  switch (AS) {
  case HSAILAS::GLOBAL_ADDRESS:
    return "global";
  case HSAILAS::CONSTANT_ADDRESS:
    return "readonly";
  case HSAILAS::GROUP_ADDRESS:
    return "group";
  case HSAILAS::PRIVATE_ADDRESS:
    return "private";
  default:
    llvm_unreachable("unhandled segment");
  }
}

void HSAILAsmPrinter::EmitFunctionArgument(unsigned ParamIndex,
                                           const Argument &A,
                                           bool IsKernel,
                                           raw_ostream &O) const {
  bool IsVector = false;
  Type *Ty = A.getType();
  unsigned NElts = 0;

  if (const VectorType *VT = dyn_cast<VectorType>(Ty)) {
    Ty = VT->getElementType();
    if (IsKernel) {
      for (unsigned I = 0, E = VT->getNumElements(); I < E; ++I) {
        EmitFunctionArgument(ParamIndex, A, IsKernel, O);
        if (I != (E - 1)) {
          O << ", ";
        }
      }
    } else
      IsVector = true;

    NElts = VT->getNumElements();
  }

  // TODO_HSA: Need to emit alignment information.
  O << (IsKernel ? "kernarg" : "arg")
    << '_'
    << getArgTypeName(Ty)
    << ' '
    << '%' << A.getName();


  // For vector args, we ll use an HSAIL array.
  if (!IsKernel && IsVector)
    O << '[' << NElts << ']';
}

void HSAILAsmPrinter::EmitFunctionReturn(Type *Ty,
                                         bool IsKernel,
                                         raw_ostream &O) const {
  unsigned NElts = 0;
  if (const VectorType *VT = dyn_cast<VectorType>(Ty)) {
    Ty = VT->getElementType();
    NElts = VT->getNumElements();
  }

  O << (IsKernel ? "kernarg" : "arg")
    << getArgTypeName(Ty)
    << " %ret_r0";
  if (NElts != 0)
    O << '[' << NElts << ']';
}

void HSAILAsmPrinter::EmitFunctionLabel(const Function &F, raw_ostream &O) const {
  Type *RetTy = F.getReturnType();

  // FIXME: Should define HSA calling conventions.
  bool IsKernel = HSAIL::isKernelFunc(&F);

  O << (IsKernel ? "kernel " : "function ");
  O << '&' << F.getName() << '(';


  // Functions with kernel linkage cannot have output args.
  if (!IsKernel) {
    // TODO_HSA: Need "good" names for the formal arguments and returned value.
    // TODO_HSA: Need to emit alignment information..
    if (!RetTy->isVoidTy())
      EmitFunctionReturn(RetTy, IsKernel, O);

    O << ")(";
  }

  // Avoid ugly line breaks with small argument lists.
  unsigned NArgs = F.arg_size();
  if (NArgs == 0) {
    O << ')';
  } else if (NArgs == 1) {
    EmitFunctionArgument(0, *F.arg_begin(), IsKernel, O);
    O << ')';
  } else {
    O << "\n\t";

    // Loop through all of the parameters and emit the types and corresponding
    // names.
    unsigned Index = 0;
    for (Function::const_arg_iterator I = F.arg_begin(), E = F.arg_end();
         I != E; ++Index) {
      EmitFunctionArgument(Index, *I++, IsKernel, O);
      if (I != E)
        O << ",\n\t";
    }

    O << ')';
  }
}

// FIXME: Doesn't make sense to rely on address space for this.
char HSAILAsmPrinter::getSymbolPrefixForAddressSpace(unsigned AS) {
  return (AS == HSAILAS::GROUP_ADDRESS ||
          AS == HSAILAS::PRIVATE_ADDRESS) ? '%' : '&';
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
  (void) Res;
  assert(Res && "Could not evaluate MCExpr");
  assert(!Val.getSymB() && "Multi-symbol expressions not handled");

  const MCSymbol &Sym = Val.getSymA()->getSymbol();

  O << "initvarwithaddress:" << VarName
    << ':' << BaseOffset // Offset into the destination.
    << ':' << EltSize
    << ':' << getSymbolPrefix(Sym) << Sym.getName()
    << ':' << Val.getConstant() // Offset of the symbol being written.
    << ';'
    << '\n';
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

  if (const ConstantDataSequential *CDS = dyn_cast<ConstantDataSequential>(CPV)) {
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
    O << CI->getValue() << ';';
    return;
  }

  if (const ConstantFP *CFP = dyn_cast<ConstantFP>(CV)) {
    printConstantFP(CFP, O);
    O << ';';
    return;
  }

  unsigned NElts = 1;
  Type *EltTy = analyzeType(CV->getType(), NElts, DL, GV.getContext());

  unsigned EltSize = DL.getTypeAllocSize(EltTy);
  SmallVector<AddrInit, 16> AddrInits;

  // Write other cases as byte array.
  StoreInitializer store(EltTy, *this);

  store.append(CV, GV.getName());

  O << '{';
  store.print(O);
  O << "};\n";

  for (const auto &VarInit : store.varInitAddresses()) {
    printInitVarWithAddressPragma(GV.getName(), VarInit.BaseOffset,
                                  VarInit.Expr, EltSize, O);
  }

  O << '\n';
}

Type *HSAILAsmPrinter::analyzeType(Type *Ty,
                                   unsigned &NElts,
                                   const DataLayout &DL,
                                   LLVMContext &Ctx) {
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
    Type *Tmp = analyzeType(EltTy, EltElts, DL, Ctx);

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
    return EltTy;
  }

  if (isa<StructType>(Ty)) {
    NElts = DL.getTypeAllocSize(Ty);
    return Type::getInt8Ty(Ctx);
  }

  assert(!Ty->isAggregateType());

  NElts = 0;
  return Ty;
}

static void printAlignTypeQualifier(const GlobalValue &GV,
                                    const DataLayout& DL,
                                    raw_ostream &O) {

  unsigned Align = GV.getAlignment();
  if (Align == 0)
    Align = DL.getABITypeAlignment(GV.getType());

  O << "align(" << Align << ") ";
}

void HSAILAsmPrinter::EmitGlobalVariable(const GlobalVariable *GV) {
  if (HSAIL::isIgnoredGV(GV))
    return;

  StringRef GVname = GV->getName();
  SmallString<1024> Str;
  raw_svector_ostream O(Str);
  const DataLayout &DL = getDataLayout();

  PointerType *Ty = GV->getType();
  unsigned AS = Ty->getAddressSpace();


  printAlignTypeQualifier(*GV, DL, O);

  unsigned NElts = ~0u;
  Type *EmitTy = analyzeType(Ty->getElementType(), NElts, DL, GV->getContext());

  O << getSegmentName(AS) << '_' << getArgTypeName(EmitTy) << " &" << GVname;
  if (NElts != 0)
    O << '[' << NElts << ']';

  // TODO_HSA: if group memory has initializer, then emit instructions to
  // initialize dynamically.
  if (GV->hasInitializer() && canInitAddressSpace(AS)) {
    O << " = ";
    const Constant *Init = cast<Constant>(GV->getInitializer());

    // Emit trivial zero initializers as a single 0.
    if (Init->isNullValue()) {
      if (Init->getType()->isAggregateType())
        O << "{0}";
      else
        O << '0';
      O << ';';
    } else {
      printGVInitialValue(*GV, Init, DL, O);
    }
  }

  OutStreamer.EmitRawText(O.str());
}

void HSAILAsmPrinter::EmitStartOfAsmFile(Module &M) {
  SmallString<32> Str;
  raw_svector_ostream O(Str);

  const HSAILSubtarget *Subtarget = &TM.getSubtarget<HSAILSubtarget>();

  O << "version "
    << BRIG_VERSION_HSAIL_MAJOR
    << ':'
    << BRIG_VERSION_HSAIL_MINOR
    << ':'
    << (Subtarget->isFull() ? "$full" : "$base")
    << ':'
    << (Subtarget->is64Bit() ? "$large" : "$small")
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

    if (!F.isDeclaration() || F.getLinkage() == GlobalValue::ExternalLinkage) {
      Str.clear();
      O.resync();

      O << "decl prog ";
      EmitFunctionLabel(F, O);
      O << ";\n\n";
      OutStreamer.EmitRawText(O.str());
    }
  }
}

StringRef HSAILAsmPrinter::getArgTypeName(Type *Ty) const {
  switch (Ty->getTypeID()) {
  case Type::VoidTyID:
    break;
  case Type::FloatTyID:
    return "f32";
  case Type::DoubleTyID:
    return "f64";
  case Type::IntegerTyID: {
    unsigned BitWidth = Ty->getIntegerBitWidth();
    if (BitWidth == 8)
      return "u8";
    else if (BitWidth == 16)
      return "u16";
    else if (BitWidth == 32)
      return "u32";
    else if (BitWidth == 64)
      return "u64";
    else if (BitWidth == 1)
      return "b1";
    else
      llvm_unreachable("unhandled integer width argument");
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
      return Subtarget->is64Bit() ? "u64" : "u32";
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

  O << "prog ";
  EmitFunctionLabel(*MF->getFunction(), O);
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

  SmallPtrSet<const GlobalVariable *,16> FuncPvtVarsSet;
  SmallPtrSet<const GlobalVariable *,16> FuncGrpVarsSet;
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
  const Module* M = MF->getMMI().getModule();
  for (const GlobalVariable &GV : M->globals()) {
    PointerType *Ty = GV.getType();
    unsigned AS = Ty->getAddressSpace();
    if (AS == HSAILAS::GROUP_ADDRESS) {
      if (FuncGrpVarsSet.count(&GV)){
        std::string str;
        O << '\t';
        printAlignTypeQualifier(GV, DL, O);

        unsigned NElts = 1;
        Type *EmitTy = analyzeType(Ty->getElementType(), NElts,
                                   DL, M->getContext());

        O << getSegmentName(AS) << '_' << getArgTypeName(EmitTy)
          << " %" << GV.getName();

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
      if (FuncPvtVarsSet.count(&GV)){
        StringRef GVname = GV.getName();
        bool ChangeName = false;
        SmallVector<StringRef, 10> NameParts;
        const char *tmp_opt_name = "tmp_opt_var";
        std::string str;
        if (GVname.empty()){
          str = tmp_opt_name;
          ChangeName = true;
        } else if (!isalpha(GVname[0]) && GVname[0] != '_'){
          str = tmp_opt_name;
          str.append(GVname);
          ChangeName = true;
        }

        { // replace all '.' with '_'
          size_t pos = str.find('.');
          if (pos != std::string::npos)
            ChangeName = true;

          while (pos != std::string::npos){
            str.replace(pos++, 1, "_");
            pos = str.find('.', pos);
          }
        }

        if (ChangeName) {
          // FIXME
          (const_cast<GlobalVariable*>(&GV))->setName(str);
        }

        O << '\t';
        printAlignTypeQualifier(GV, DL, O);
        str = "";

        unsigned NElts = ~0u;
        Type *EmitTy = analyzeType(Ty->getElementType(), NElts,
                                   DL, M->getContext());
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
    O <<  "\tspill_u32 %stack[" << (StackSize >> 2) << "];\n";
  }

  O << '@' << F->getName() << "_entry:\n";

#if 0
  // Allocate gcn region for gcn atomic counter, if required.
  if (usesGCNAtomicCounter())
    O << "\tgcn_region_alloc 4;\n";
#endif

  OutStreamer.EmitRawText(O.str());
}

void HSAILAsmPrinter::EmitFunctionBodyEnd() {
  OutStreamer.EmitRawText("};");
}
