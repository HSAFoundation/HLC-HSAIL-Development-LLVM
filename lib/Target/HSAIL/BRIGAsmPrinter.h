//===- BRIGAsmPrinter.h - Convert HSAIL LLVM code to assembly --*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#ifndef _BRIG_ASM_PRINTER_H_
#define _BRIG_ASM_PRINTER_H_

#include "BRIGAsmPrinter.h"

#include "HSAIL.h"
#include "HSAILAsmPrinter.h"
#include "HSAILInstrInfo.h"
#include "HSAILBrig.h"
#include "HSAILSubtarget.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/CodeGen/MachineOperand.h"
#include "llvm/Support/FormattedStream.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Support/TargetRegistry.h"

// below all are in assembler/libHSAIL
//
#include "MCTargetDesc/RawVectorOstream.h"
#include "libHSAIL/HSAILItemBase.h"
#include "libHSAIL/HSAILItems.h"
#include "libHSAIL/HSAILParser.h"
#include "libHSAIL/HSAILBrigantine.h"

namespace llvm {

class Argument;
class HSAILKernelManager;
class HSAILMachineFunctionInfo;
class MachineBasicBlock;
class MachineConstantPoolValue;
class MachineFunction;
class MachineInstr;
class MachineJumptableInfo;
class MCContext;
class MCInst;
class MCStreamer;
class MCSymbol;
class Module;
class raw_ostream;

class LLVM_LIBRARY_VISIBILITY BRIGAsmPrinter : public HSAILAsmPrinter {
  friend class StoreInitializer;

  const HSAILSubtarget *Subtarget;

  // Used for the callee part of the calling convention and be cleared
  // at every function
  std::string FuncArgsStr;
  std::string FuncRetValStr;

  // Do counting for returned values and parameters of a function and
  // be cleared at every function
  unsigned retValCounter;
  unsigned paramCounter;

  // Do counting for 1-bit, 32-bit, and 64-bit parameters or returned
  // values in a function call and be cleared at every call site
  // twice---one for parameters and the other for returned values
  unsigned reg1Counter;
  unsigned reg32Counter;
  unsigned reg64Counter;

  const DataLayout &getDataLayout() const {
    return *Subtarget->getDataLayout();
  }

public:
  explicit BRIGAsmPrinter(TargetMachine& TM, MCStreamer &Streamer);

  virtual ~BRIGAsmPrinter();

  virtual const char* getPassName() const { return "BRIG Container Filler"; }

  const HSAILSubtarget& getSubtarget() const { return *Subtarget; }

  /// EmitGlobalVariable - Emit the specified global variable to the .s file.
  virtual void EmitGlobalVariable(const GlobalVariable *GV);

  void EmitFunctionLabel(const Function &, const llvm::StringRef sFuncName);

  /// override by targets that emit something at start of file
  virtual void EmitStartOfAsmFile(Module &);

  /// override by targets that emit something at end of file.
  virtual void EmitEndOfAsmFile(Module &);

  /// override to emit stuff before the first basic block in function.
  virtual void EmitFunctionBodyStart();

  /// Targets can override this to emit stuff after
  /// the last basic block in the function.
  virtual void EmitFunctionBodyEnd();

  /// Targets should implement this to emit instructions [required]
  virtual void EmitInstruction(const MachineInstr *);

  virtual void EmitFunctionEntryLabel();

  /// Emit ld_* or st_* instruction.
  HSAIL_ASM::Inst EmitLoadOrStore(const MachineInstr *MI, bool isLoad,
                                  unsigned vec_size);

  /// isBlockOnlyReachableByFallthough - Return true if the basic block has
  /// exactly one predecessor and the control transfer mechanism between
  /// the predecessor and this block is a fall-through.
  virtual bool isBlockOnlyReachableByFallthrough(
    const MachineBasicBlock *MBB) const;

  bool doFinalization(Module &M);

  //===------------------------------------------------------------------===//
  // Dwarf Emission Helper Routines
  //===------------------------------------------------------------------===//

  /// Get the value for DW_AT_APPLE_isa. Zero if no isa encoding specified.
  virtual unsigned getISAEncoding();

public:

  bool runOnMachineFunction(MachineFunction &F);
  bool isMacroFunc(const MachineInstr *MI);
  void EmitSamplerDefs();

  // Vector that keeps offsets and sizes (in bits) of all the BRIG variables
  // generated for some vector argument
  typedef SmallVector<std::pair<uint64_t, uint64_t>, 16> VectorArgumentOffsets;

  bool getGlobalVariableOffset(const GlobalVariable* GV, uint64_t *result) const;
  bool getFunctionScalarArgumentOffset(const std::string& argName, uint64_t *result) const;
  bool getFunctionVectorArgumentOffsets(const std::string& argName, VectorArgumentOffsets& result) const;
  bool getGroupVariableOffset(const GlobalVariable* GV, uint64_t *result) const;

  // returns true and the offset of %privateStack BRIG variable, or false if there is no local stack
  bool getPrivateStackOffset(uint64_t *privateStackOffset) const;

  // returns true and the offset of %spillStack BRIG variable, or false if there is no stack for spills
  bool getSpillStackOffset(uint64_t *spillStackOffset) const;

  // this function is used to translate stack objects' offsets reported by MachineFrameInfo
  // to actual offsets in the %privateStack array
  bool getLocalVariableStackOffset(int varOffset, int *stackOffset) const;

  // this function is used to translate stack objects' offsets reported by MachineFrameInfo
  // to actual offsets in the %spillStack array
  bool getSpillVariableStackOffset(int varOffset, int *stackOffset) const;

protected:


  virtual void emitMacroFunc(const MachineInstr *MI, raw_ostream &O);

  HSAILTargetMachine *mTM;
  const HSAILInstrInfo *TII;
  HSAILKernelManager *mMeta;    /* metadata required by the runtime */
  HSAILMachineFunctionInfo *mMFI; /* current function being processed */

  /// name of the kernel wrapper of the current function
  std::string mKernelName;
  bool m_bIsKernel;  // is 'true' if the current function being processed is OpenCL kernel

  HSAIL_ASM::BrigContainer bc;
  HSAIL_ASM::Brigantine brigantine;

  static char getSymbolPrefixForAddressSpace(unsigned AS);
  char getSymbolPrefix(const MCSymbol &S) const;

  void BrigEmitInitVarWithAddressPragma(StringRef VarName,
                                        uint64_t BaseOffset,
                                        const MCExpr *E,
                                        unsigned EltSize);
  void BrigEmitGlobalInit(HSAIL_ASM::DirectiveVariable, Type *EltTy, Constant *);
  void BrigEmitOperand(const MachineInstr *MI, unsigned opNum, HSAIL_ASM::Inst inst);
  void BrigEmitOperandLdStAddress(const MachineInstr *MI, unsigned opNum);
  void BrigEmitVecArgDeclaration(const MachineInstr *MI);
  void BrigEmitOperandImage(const MachineInstr *MI, unsigned opNum);
  void BrigEmitImageInst(const MachineInstr *MI, HSAIL_ASM::InstImage inst);

  HSAIL_ASM::InstBasic BrigEmitBasicInst(const MachineInstr &MI,
                                         unsigned BrigOpc);
  HSAIL_ASM::InstMod BrigEmitModInst(const MachineInstr &MI, unsigned BrigOpc);
  HSAIL_ASM::InstSourceType BrigEmitSourceTypeInst(const MachineInstr &MI,
                                                   unsigned BrigOpc);

  HSAIL_ASM::InstLane BrigEmitLaneInst(const MachineInstr &MI,
                                       unsigned BrigOpc);
  HSAIL_ASM::InstBr BrigEmitBrInst(const MachineInstr &MI,
                                   unsigned BrigOpc);
  HSAIL_ASM::InstSeg BrigEmitSegInst(const MachineInstr &MI,
                                     unsigned BrigOpc);

  void BrigEmitVecOperand(const MachineInstr *MI, unsigned opStart,
                          unsigned numRegs, HSAIL_ASM::Inst inst);
  
  // Stream that captures DWARF data to the internal buffer
  RawVectorOstream* mDwarfStream;
  // Stream that will receive all BRIG data
  raw_ostream*      mBrigStream;
  // Stream that will receive all captured DWARF data in the case of -odebug
  raw_fd_ostream*   mDwarfFileStream;

  // table that stores offsets of all emitted global variables - used in DWARF
  std::map<const llvm::GlobalVariable*, uint64_t> globalVariableOffsets;
  typedef std::map<const llvm::GlobalVariable*, uint64_t>::const_iterator gvo_iterator;

  std::map<int, int> spillMapforStack;
  std::map<int, int> LocalVarMapforStack;
  typedef std::map<int, int>::const_iterator stack_map_iterator;

  // offset of BRIG variables %privateStack and %spillStack
  uint64_t privateStackBRIGOffset;
  uint64_t spillStackBRIGOffset;

  // table that stores offsets of scalar arguments of function being emitted - used in DWARF
  typedef std::map<std::string, uint64_t> ScalarArgumentOffsetsMap;
  typedef ScalarArgumentOffsetsMap::const_iterator fao_iterator;
  ScalarArgumentOffsetsMap functionScalarArgumentOffsets;

  // table that stores offsets of BRIG variables generated for vector arguments - used in DWARF
  typedef std::map<std::string, VectorArgumentOffsets> VectorArgumentOffsetsMap;
  typedef VectorArgumentOffsetsMap::const_iterator fvo_iterator;
  VectorArgumentOffsetsMap functionVectorArgumentOffsets;


  // tables that store offsets of private and group variables - used in both DWARF and EmitFunctionBodyStart
  typedef DenseMap<const llvm::GlobalVariable*, uint64_t> PVGVOffsetMap;
  PVGVOffsetMap groupVariablesOffsets;
  typedef PVGVOffsetMap::iterator pvgvo_iterator;
  typedef PVGVOffsetMap::const_iterator pvgvo_const_iterator;
  typedef PVGVOffsetMap::value_type pvgvo_record;


  typedef DenseMap<const Function *, std::vector<llvm::StringRef> > FuncAliasMap;
  FuncAliasMap funcAliases;

private:

  HSAIL_ASM::ItemList m_opndList;

  int mBuffer;

  typedef enum {
    ARG_TYPE_NONE = 0,
    ARG_TYPE_FUNC = 1,
    ARG_TYPE_KERNEL = 2,
    ARG_TYPE_POINTER = 3,
    ARG_TYPE_VALUE = 4
  } HSAIL_ARG_TYPE;

  std::string getHSAILArgType( Type* type,
                              HSAIL_ARG_TYPE arg_type = ARG_TYPE_NONE);
  std::string getHSAILReg(Type* type);

  Brig::BrigSegment8_t getHSAILSegment(unsigned AddressSpace) const;
  Brig::BrigSegment8_t getHSAILSegment(const GlobalVariable* gv) const;

  Brig::BrigAtomicOperation getAtomicOpcode(const MachineInstr *MI) const;
  Brig::BrigSegment getAtomicSegment(const MachineInstr *MI) const;
  Brig::BrigMemoryOrder getAtomicOrder(const MachineInstr *MI) const;
  Brig::BrigMemoryScope getAtomicScope(const MachineInstr *MI) const;
  Brig::BrigTypeX getAtomicType(const MachineInstr *MI) const;

  bool canInitHSAILAddressSpace(const GlobalVariable* gv) const;
  void EmitBasicBlockStart(const MachineBasicBlock &MBB);
  // returns an offset of corresponding DirectiveVariable
  uint64_t EmitFunctionArgument(Type* type, bool isKernel,
                                const StringRef argName, bool isSExt);
  void EmitFunctionReturn(Type* type, bool isKernel, const StringRef RetName,
                          bool isSExt);

  bool usesGCNAtomicCounter(void);

  HSAIL_ASM::OperandReg getBrigReg(MachineOperand s);

  HSAIL_ASM::DirectiveVariable EmitLocalVariable(const GlobalVariable *GV, Brig::BrigSegment8_t segment);

  Brig::BrigAlignment8_t getBrigAlignment(unsigned align_value);

  HSAIL_ASM::Inst EmitInstructionImpl(const MachineInstr *);
};

} // end namespace llvm
#endif // _BRIG_ASM_PRINTER_H_
