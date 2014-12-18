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
                                           Type *Ty,
                                           bool IsKernel,
                                           raw_ostream &O) const {
  bool IsVector = false;
  if (const VectorType *VT = dyn_cast<VectorType>(Ty)) {
    Ty = VT->getElementType();
    if (IsKernel) {
      for (unsigned I = 0, E = VT->getNumElements(); I < E; ++I) {
        EmitFunctionArgument(ParamIndex, Ty, IsKernel, O);
        if (I != (E - 1)) {
          O << ", ";
        }
      }
    } else
      IsVector = true;
  }

  // TODO_HSA: Need to emit alignment information.
  O << (IsKernel ? "kernarg" : "arg")
    << getArgTypeName(Ty)
    << ' ';

  if (IsKernel || !IsVector)
    O << "%arg_p" << ParamIndex;
  else
    O << "%argV_p" << ParamIndex;

  // For vector args, we ll use an HSAIL array.
  if (!IsKernel && IsVector)
    O << "[]";
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

void HSAILAsmPrinter::EmitFunctionLabel(const Function &F) const {
  std::string FunStr;
  raw_string_ostream O(FunStr);

  Type *RetTy = F.getReturnType();
  const FunctionType *FuncTy = F.getFunctionType();

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

    O << ") (";
  }

  // Loop through all of the parameters and emit the types and corresponding
  // names.
  for (unsigned I = 0, N = FuncTy->getNumParams(); I != N; ++I) {
    EmitFunctionArgument(I, FuncTy->getParamType(I), IsKernel, O);

    if (I + 1 != N)
      O << ", ";
  }

  O << ");\n\n";
  OutStreamer.EmitRawText(O.str());
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

void HSAILAsmPrinter::printConstantFP(const ConstantFP *CFP, raw_ostream &O) {
  uint64_t Val = CFP->getValueAPF().bitcastToAPInt().getZExtValue();
  if (CFP->getType()->isFloatTy())
    O << format("0F%" PRIx32, static_cast<uint32_t>(Val));
  else if (CFP->getType()->isDoubleTy())
    O << format("0D%" PRIx64, Val);
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

  uint64_t TotalSizeEmitted = 0;
  SmallVector<AddrInit, 16> AddrInits;


  if (const ConstantDataSequential *CDS = dyn_cast<ConstantDataSequential>(CV)) {
    unsigned EltSize = DL.getTypeAllocSize(CDS->getElementType());

    assert(!CDS->getElementType()->isAggregateType());
    O << '{';

    for (unsigned I = 0, E = CDS->getNumElements(); I != E; ++I) {
      if (I > 0)
        O << ", ";

      Constant *Elt = CDS->getElementAsConstant(I);
      printScalarConstant(Elt, AddrInits, TotalSizeEmitted, DL, O);
    }

    O << "};\n";

    for (auto Init : AddrInits) {
      printInitVarWithAddressPragma(GV.getName(), Init.first,
                                    Init.second, EltSize, O);
    }

    O << '\n';
    return;
  }

  // XXX - Need to flatten multidimensional.
  if (const ConstantArray *CA = dyn_cast<ConstantArray>(CV)) {
    Type *EltTy = CA->getType()->getElementType();
    if (!EltTy->isAggregateType()) {
      unsigned EltSize = DL.getTypeAllocSize(EltTy);

      O << '{';

      for (unsigned I = 0, E = CA->getNumOperands(); I != E; ++I) {
        if (I > 0)
          O << ", ";

        Constant *Elt = CA->getOperand(I);
        printScalarConstant(Elt, AddrInits, TotalSizeEmitted, DL, O);
      }

      O << "};\n";

      for (auto Init : AddrInits) {
        printInitVarWithAddressPragma(GV.getName(), Init.first,
                                      Init.second, EltSize, O);
      }

      O << '\n';
      return;
    }

    // struct arrays fallthrough to be treated as byte array.
  }

  // Write other cases as byte array.
  StoreInitializer store(1, *this);

  store.append(CV, GV.getName());

  O << '{';
  StringRef Str = store.str();
  for (size_t I = 0, E = Str.size(); I != E; ++I) {
    O << (static_cast<int>(Str[I]) & 0xff);

    if (I + 1 != E)
      O << ", ";
  }

  O << "};\n";

  for (const auto &VarInit : store.varInitAddresses()) {
    printInitVarWithAddressPragma(GV.getName(), VarInit.BaseOffset,
                                  VarInit.Expr, 1, O);
  }

  O << '\n';
}

static void printAlignTypeQualifier(const GlobalValue &GV,
                                    const DataLayout& DL,
                                    raw_ostream &O) {

  unsigned Align = GV.getAlignment();
  if (Align == 0)
    Align = DL.getABITypeAlignment(GV.getType());

  O << "align(" << Align << ") ";
}

static Type* printGVType(Type *ty, const DataLayout& DL, std::string &str) {
  if (const ArrayType *ATy = dyn_cast<ArrayType>(ty)) {
    std::string buf;
    raw_string_ostream ss(buf);
    ss << '[';
    uint64_t numElems = ATy->getNumElements();

    // Flatten multi-dimensional array declaration
    while (ATy->getElementType()->isArrayTy()) {
      ATy = dyn_cast<ArrayType>(ATy->getElementType());
      numElems *= ATy->getNumElements();
    }

    // There are no vector types in HSAIL, so global declarations for
    // arrays of composite types (vector, struct) are emitted as a single
    // array of a scalar type.

    // Flatten array of vector declaration
    if (ATy->getElementType()->isVectorTy()) {
      const VectorType *VTy = cast<VectorType>(ATy->getElementType());
      numElems *= VTy->getNumElements();
      ss << numElems << ']';
      str += ss.str();
      return printGVType(VTy->getElementType(), DL, str);
    }
    // Flatten array of struct declaration
    if (ATy->getElementType()->isStructTy()) {
      StructType *ST = cast<StructType>(ATy->getElementType());
      const StructLayout *layout = DL.getStructLayout(ST);
      numElems *= layout->getSizeInBytes();
    }
    ss << numElems << ']';
    str += ss.str();
    return printGVType(ATy->getElementType(), DL, str);
  } else if (const VectorType *VTy = dyn_cast<VectorType>(ty)) {
    std::string buf;
    raw_string_ostream ss(buf);

    uint64_t numElems = VTy->getNumElements();
    ss << '[' << numElems << ']';
    str += ss.str();
    return VTy->getElementType();
  } else
    return ty;
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
  std::string str;
  O << getSegmentName(AS)
    << getArgTypeName(printGVType(Ty->getElementType(), DL, str))
    << " &" << GVname << str;

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

    if (!F.isDeclaration() || F.getLinkage() == GlobalValue::ExternalLinkage)
      EmitFunctionLabel(F);
  }
}

std::string HSAILAsmPrinter::getArgTypeName(Type *Ty) const {
  std::string Str;

  switch (Ty->getTypeID()) {
  case Type::VoidTyID:
    break;
  case Type::FloatTyID:
    Str += "_f32";
    break;
  case Type::DoubleTyID:
    Str += "_f64";
    break;
  case Type::IntegerTyID: {
    unsigned BitWidth = cast<IntegerType>(Ty)->getBitWidth();
    if (BitWidth == 8)
      Str += "_u8";
    else if (BitWidth == 16)
      Str += "_u16";
    else if (BitWidth == 32)
      Str += "_u32";
    else if (BitWidth == 64)
      Str += "_u64";
    else if (BitWidth == 1)
      Str += "_b1";
    else
      llvm_unreachable("unhandled integer width argument");
    break;
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
        Str += "_RWImg";
      } else if (Name.startswith("struct._sampler_t")) {
        Str += "_Samp";
      } else if (Name == "struct._counter32_t" || Name == "struct._event_t") {
        if (Subtarget->is64Bit())
          Str += "_u64";
        else
          Str += "_u32";
      } else {
        llvm_unreachable("unhandled struct type argument");
      }
    } else {
      if (Subtarget->is64Bit())
        Str += "_u64";
      else
        Str += "_u32";
    }
    break;
  }
  case Type::StructTyID: // Treat struct as array of bytes.
    Str += "_u8";
    break;
  case Type::VectorTyID: {
    // Treat as array of elements.
    const VectorType *VT = cast<VectorType>(Ty);

    Str += getArgTypeName(VT->getElementType());
    break;
  }
  case Type::ArrayTyID: {
    llvm_unreachable("FIXME");
  }
  default:
    llvm_unreachable("unhandled argument type id");
  }

  return Str;
}

void HSAILAsmPrinter::EmitFunctionBodyStart() {
  std::string FunStr;
  raw_string_ostream O(FunStr);
  O << "{\n";

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
  for (MachineFunction::const_iterator I = MF->begin(), E = MF->end();
       I != E; ++I){
    for (MachineBasicBlock::const_iterator II = I->begin(), IE = I->end();
         II != IE; ++II) {
      const MachineInstr *LastMI = II;
      for (unsigned int opNum = 0; opNum < LastMI->getNumOperands(); ++opNum) {
        const MachineOperand &MO = LastMI->getOperand(opNum);
        if (MO.isGlobal()) {
          if (const GlobalVariable *GV = dyn_cast<GlobalVariable>(MO.getGlobal())){
            if (GV->getType()->getAddressSpace() == HSAILAS::PRIVATE_ADDRESS)
              FuncPvtVarsSet.insert(GV);

            if (GV->getType()->getAddressSpace() == HSAILAS::GROUP_ADDRESS)
              FuncGrpVarsSet.insert(GV);
          }
        }
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
        O << getSegmentName(AS)
          << getArgTypeName(printGVType(Ty->getElementType(), DL, str))
          << " %" << GV.getName() << str;
      }
    }
  }

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
        O << getSegmentName(AS)
          << getArgTypeName(printGVType(Ty->getElementType(), DL, str))
          << " %" << GV.getName() << str;
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
