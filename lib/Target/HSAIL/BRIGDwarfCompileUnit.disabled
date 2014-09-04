#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/MC/MCSection.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/Target/TargetRegisterInfo.h"
#include "BRIGDwarfCompileUnit.h"
#include "HSAILRegisterInfo.h"
#include <string>
#include <cassert>

using namespace llvm;

namespace llvm {

  class DIEBRIGOffset : public DIEValue {
    const MCSymbol* sectionBeginSym;
    const uint64_t  Offset;

    static const unsigned isBRIGOffset = (unsigned)(-1);
    /* this value should not match with any of isXXX values defined in DIEValue 
       There is no need to support dyn_cast for DIEBRIGOffset.
       We could use "isSectionOffset" value instead of -1, because it is not used.
       But it is not guaranteed to be safe, because it can be used by someone else
       in LLVM to implement dyn_cast for some other class derived from DIEValue.
       TODO_HSA(3) should we declare isBRIGOffset in the DIEValue class?
    */

  public:
    explicit DIEBRIGOffset(const MCSymbol* sectionBegin, const uint64_t Offs) :
       DIEValue(isBRIGOffset), sectionBeginSym(sectionBegin), Offset(Offs) {
    }

    /// EmitValue - Emit the offset in BRIG section.
    ///
    virtual void EmitValue(AsmPrinter *AP, dwarf::Form Form) const {
      AP->EmitLabelPlusOffset(sectionBeginSym, Offset, SizeOf(AP, Form));
    }

    /// SizeOf - Determine size of the offset in BRIG section in bytes.
    ///
    virtual unsigned SizeOf(AsmPrinter *AP, dwarf::Form Form) const {
      if (Form == dwarf::DW_FORM_data4) return 4;
      return AP->getDataLayout().getPointerSize();
    }

#ifndef NDEBUG
    virtual void print(raw_ostream &O) {
      O << sectionBeginSym->getName() << " + " << Offset;
    }
#endif
  };

  BRIGDwarfCompileUnit::BRIGDwarfCompileUnit(unsigned UID, 
    DIE *D, DICompileUnit CU, BRIGAsmPrinter *A, BRIGDwarfDebug *DW) :
    CompileUnit(UID, D, CU, A, DW, NULL), m_brigAP(A), m_brigDD(DW) {
  }

  BRIGDwarfCompileUnit::~BRIGDwarfCompileUnit() {
  }

  void BRIGDwarfCompileUnit::addVariableAddress(DbgVariable *&DV, DIE *Die, MachineLocation Location) {
    if (!Location.isReg()) {
      const MachineFunction& MF = *m_brigAP->MF;
      const TargetRegisterInfo *TRI = m_brigAP->TM.getRegisterInfo();
      assert(TRI->getFrameRegister(MF) == HSAIL::NoRegister);
      if (Location.getReg() == TRI->getFrameRegister(MF)) {
        // original offset
        int variableOffset = Location.getOffset(); 
        // translated offset
        int localOffset; 
        // BRIG offset of stack variable
        uint64_t stackOffset;
        if (m_brigAP->getPrivateStackOffset(&stackOffset)
            && m_brigAP->getLocalVariableStackOffset(variableOffset, &localOffset)) {
          
          // if there is a private array that is used to store local variables
          // - emit location expression as an offset in this array
          DIEBlock *Block = new (DIEValueAllocator) DIEBlock();
          addUInt(Block, (dwarf::Attribute)0, dwarf::DW_FORM_data1, dwarf::DW_OP_addr);
          addBRIGDirectiveOffset(Block, 0, dwarf::DW_FORM_addr, stackOffset);
          addUInt(Block, (dwarf::Attribute)0, dwarf::DW_FORM_data1, dwarf::DW_OP_plus_uconst);

          // ULEB128 encoding is required for DW_OP_plus_uconst operand
          unsigned int offs = static_cast<unsigned int>(localOffset);
          do {
            unsigned char Byte = static_cast<unsigned char>(offs & 0x7f);
            offs >>= 7;
            if (offs) {
              Byte |= 0x80;
            }
            addUInt(Block, (dwarf::Attribute)0, dwarf::DW_FORM_data1, Byte);
          } while (offs);
          addBlock(Die, dwarf::DW_AT_location, Block);
          return;
        }
        // otherwise let DwarfCompileUnit handle this address
      }
    }
    addVariableAddress(DV, Die, Location);
  }

  void BRIGDwarfCompileUnit::addString(DIE *Die, unsigned Attribute, StringRef String) {
    DIEValue *Value = new (DIEValueAllocator) DIEString(0, String);
    Die->addValue((dwarf::Attribute)Attribute, dwarf::DW_FORM_string, Value);
  }

  void BRIGDwarfCompileUnit::addLabel(DIE *Die, unsigned Attribute, 
                          unsigned Form, const MCSymbol *Label) {
    this->CompileUnit::addLabel(Die, (dwarf::Attribute)Attribute, (dwarf::Form)Form, Label);
  }

  void BRIGDwarfCompileUnit::addDelta(DIE *Die, unsigned Attribute, unsigned Form,
                          const MCSymbol *Hi, const MCSymbol *Lo) {
    this->CompileUnit::addDelta(Die, (dwarf::Attribute)Attribute, (dwarf::Form)Form, Hi, Lo);
  }

  void BRIGDwarfCompileUnit::addBRIGDirectiveOffset(DIE *Die, unsigned Attribute,
                                                    unsigned Form, uint64_t Integer) {
    MCSymbol *directivesBegin = m_brigAP->GetTempSymbol("directives_begin");
    DIEValue *Value = new (DIEValueAllocator) DIEBRIGOffset(directivesBegin, Integer);
    Die->addValue((dwarf::Attribute)Attribute, (dwarf::Form)Form, Value);
  }

  void BRIGDwarfCompileUnit::addGVLabelToBlock(DIEBlock* block, const DIGlobalVariable* GV) {
    const GlobalVariable* gv = GV->getGlobal();
    uint64_t offs = 0;

    if (gv->getType()->getAddressSpace() == HSAILAS::PRIVATE_ADDRESS ||
        gv->getType()->getAddressSpace() == HSAILAS::GROUP_ADDRESS) 
      return ; // TODO_HSA: process private and group variables

    if(m_brigAP->getGlobalVariableOffset(gv, &offs)) {
      //std::string n = GV->getName().str();
      //printf("GV %s [%p] has offset %lu and stored at offset %u from block's begin\n", n.c_str(), (const void*)GV, (unsigned long)offs, (unsigned)block->getOffset());
      addBRIGDirectiveOffset(block, 0, dwarf::DW_FORM_addr, offs);
      //TODO_HSA(3) add relocation record .brigdirectives + offset
    }
  }

  void BRIGDwarfCompileUnit::createGlobalVariableDIE(const MDNode *N) {
    DIGlobalVariable DV(N);
    if(!DV.Verify()) return;
    const GlobalVariable* gv = DV.getGlobal();
    // if this global variable is either private or group variable,
    // then we should not process it further here, BRIGDwarfDebug will
    // process them in endFunction().
    if (gv) {
      switch (gv->getType()->getAddressSpace()) {
      case HSAILAS::PRIVATE_ADDRESS:
        m_brigDD->addPrivateVariableMDNode(N);
        // errs() << "createGlobalVariableDIE: encountered private variable " << gv->getName() << "\n";
        return;
      case HSAILAS::GROUP_ADDRESS:
        m_brigDD->addGroupVariableMDNode(N);
        // errs() << "createGlobalVariableDIE: encountered group variable " << gv->getName() << "\n";
        return;
      default:;
        // do nothing
      }
    }
    this->CompileUnit::createGlobalVariableDIE(DV);
  }

  /// constructVariableDIE - Construct a DIE for the given private or group variable.
  DIE* BRIGDwarfCompileUnit::constructPGVariableDIE(DbgPGVariable *Var) {
    StringRef Name = Var->getName();
    if (Name.empty()) return NULL;

    // Translate tag to proper Dwarf tag.
    unsigned Tag = Var->getTag();

    // Define variable debug information entry.
    DIE *VariableDie = new DIE(Tag);

    addString(VariableDie, dwarf::DW_AT_name, Name);
    addSourceLine(VariableDie, Var->getPGVariable());
    addType(VariableDie, Var->getType());

    // Add variable address.
    unsigned Offset = Var->getDotDebugLocOffset();
    assert(Offset != ~0U && Offset != 0 && "Invalid offset of private/group variable");
    addDebugLocOffset(0, VariableDie, Offset);
    Var->setDIE(VariableDie);
    return VariableDie;
  }

  void BRIGDwarfCompileUnit::addDebugLocOffset(const DbgVariable *Var, DIE* VariableDie, unsigned int Offset) {
    DIEBlock *Block = new (DIEValueAllocator) DIEBlock();
    if (Offset != 0) {
      // valid BRIG offset
      addUInt(Block, (dwarf::Attribute)0, dwarf::DW_FORM_data1, dwarf::DW_OP_addr);
      addBRIGDirectiveOffset(Block, 0, dwarf::DW_FORM_addr, Offset);
    }
    else {
      assert(Var != 0);
      // Is it a vector argument? Query BRIGDwarfDebug.
      BRIGAsmPrinter::VectorArgumentOffsets offsets;
      bool rv = m_brigAP->getFunctionVectorArgumentOffsets(Var->getName().str(), offsets);
      if (!rv) {
        // probably this variable has been optimized out
        // errs() << "BRIG DWARF: could not find location of variable " << Var->getName() << ": it was probably optimized out\n";
        // do not add location attribute in this case
        Block->~DIEBlock();
        operator delete(Block, DIEValueAllocator);
        return;
      }
      assert(offsets.size() > 0);
      // construct address
      for (unsigned int i = 0, e = offsets.size(); i != e; i++) {
        addUInt(Block, (dwarf::Attribute)0, dwarf::DW_FORM_data1, dwarf::DW_OP_addr);
        addBRIGDirectiveOffset(Block, 0, dwarf::DW_FORM_addr, offsets[i].first);
        uint64_t size = offsets[i].second; // size in bits
        // size of HSAIL type can either be 1 bit or 8*N bits
        // not sure whether do we have a vector of bits
        assert( size == 1 || (size % 8 == 0) ); 
        if (size != 1) {
          // size = 8*N
          // TODO_HSA(3) implement ULEB128 encoding and support types that are more than 1024 bits in size
          assert(size/8 < 128); 
          addUInt(Block, (dwarf::Attribute)0, dwarf::DW_FORM_data1, dwarf::DW_OP_piece);
          // BRIG primary type size is less than 128 bytes. These values don't change 
          // after ULEB128 encoding, so we can emit them directly as bytes
          addUInt(Block, (dwarf::Attribute)0, dwarf::DW_FORM_data1, size/8);
        }
        else {
          /* describe 1 bit piece of variable that is 1 bit next to the previous part */
          addUInt(Block, (dwarf::Attribute)0, dwarf::DW_FORM_data1, dwarf::DW_OP_bit_piece);
          /* 1 bit piece */
          addUInt(Block, (dwarf::Attribute)0, dwarf::DW_FORM_data1, 1);
          /* 1 bit from previous part, or 0 if it's the first element in bit vector */
          addUInt(Block, (dwarf::Attribute)0, dwarf::DW_FORM_data1, i == 0 ? 0 : 1);
        }
      }
    }
    addBlock(VariableDie, dwarf::DW_AT_location, Block);
  }

} // namespace llvm
