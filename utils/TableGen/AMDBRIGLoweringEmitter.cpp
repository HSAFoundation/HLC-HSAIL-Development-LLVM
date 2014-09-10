//===- BRIGLoweringEmitter.cpp - Generate the BRIG lowering code -----------------===//
//
//                     
//
//===----------------------------------------------------------------------===//
//
// This tablegen backend generates code for the BRIG lowering phase.
//
//===----------------------------------------------------------------------===//

#include "AMDBRIGLoweringEmitter.h"
#include "AMDDAGWalker.h"
#include "AsmWriterInst.h"
#include "CodeGenTarget.h"
#include "llvm/TableGen/StringToOffsetTable.h"
#include "SequenceToOffsetTable.h"
#include "AMDHSAILVecMapEmiter.h"
#include "llvm/ADT/Twine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/TableGen/Error.h"
#include "llvm/TableGen/Record.h"
//#include "AsmWriterEmitter.h"
#include <sstream>

#include <algorithm>
using namespace llvm;

static void UnescapeString(std::string &Str) {
  for (unsigned i = 0; i != Str.size(); ++i) {
    if (Str[i] == '\\' && i != Str.size()-1) {
      switch (Str[i+1]) {
      default: continue;  // Don't execute the code after the switch.
      case 'a': Str[i] = '\a'; break;
      case 'b': Str[i] = '\b'; break;
      case 'e': Str[i] = 27; break;
      case 'f': Str[i] = '\f'; break;
      case 'n': Str[i] = '\n'; break;
      case 'r': Str[i] = '\r'; break;
      case 't': Str[i] = '\t'; break;
      case 'v': Str[i] = '\v'; break;
      case '"': Str[i] = '\"'; break;
      case '\'': Str[i] = '\''; break;
      case '\\': Str[i] = '\\'; break;
      }
      // Nuke the second character.
      Str.erase(Str.begin()+i+1);
    }
  }
}


/// EmitPrintInstruction - Generate the code for the "printInstruction" method
/// implementation.
void BRIGLoweringEmitter::EmitPrintInstruction(raw_ostream &O) {
  CodeGenTarget Target(Records);
  Record *AsmWriter = Target.getAsmWriter();
  std::string ClassName = AsmWriter->getValueAsString("AsmWriterClassName");
  bool isMC = AsmWriter->getValueAsBit("isMCAsmWriter");
  const char *MachineInstrClassName = isMC ? "MCInst" : "MachineInstr";

  O << "  HSAIL_ASM::Inst BRIGAsmPrinter::BrigEmitInstruction(const MachineInstr *MI) {\n";
 
  std::vector<AsmWriterInst> Instructions;

  for (CodeGenTarget::inst_iterator I = Target.inst_begin(),
         E = Target.inst_end(); I != E; ++I)
    if (!(*I)->AsmString.empty() &&
        (*I)->TheDef->getName() != "PHI")
      Instructions.push_back(
        AsmWriterInst(**I,
                      AsmWriter->getValueAsInt("Variant"),
                      AsmWriter->getValueAsInt("OperandSpacing")));

  // Get the instruction numbering.
  NumberedInstructions = Target.getInstructionsByEnumValue();

  // Compute the CodeGenInstruction -> AsmWriterInst mapping.  Note that not
  // all machine instructions are necessarily being printed, so there may be
  // target instructions not in this map.
  for (unsigned i = 0, e = Instructions.size(); i != e; ++i)
    CGIAWIMap.insert(std::make_pair(Instructions[i].CGI, &Instructions[i]));

  // Build an aggregate string, and build a table of offsets into it.
  SequenceToOffsetTable<std::string> StringTable;

  /// OpcodeInfo - This encodes the index of the string to use for the first
  /// chunk of the output as well as indices used for operand printing.
  std::vector<unsigned> OpcodeInfo;
   // Add all strings to the string table upfront so it can generate an optimized
  // representation.
  for (unsigned i = 0, e = NumberedInstructions.size(); i != e; ++i) {
    AsmWriterInst *AWI = CGIAWIMap[NumberedInstructions[i]];
    if (AWI != 0 &&
        AWI->Operands[0].OperandType ==
                 AsmWriterOperand::isLiteralTextOperand &&
        !AWI->Operands[0].Str.empty()) {
      std::string Str = AWI->Operands[0].Str;
      UnescapeString(Str);
      StringTable.add(Str);
    }
  }

  StringTable.layout();

  unsigned MaxStringIdx = 0;
  for (unsigned i = 0, e = NumberedInstructions.size(); i != e; ++i) {
      AsmWriterInst *AWI = CGIAWIMap[NumberedInstructions[i]];
      unsigned Idx;
      if (AWI == 0) {
         // Something not handled by the asmwriter printer.
         Idx = ~0U;
      } else if (AWI->Operands[0].OperandType !=
                 AsmWriterOperand::isLiteralTextOperand ||
                 AWI->Operands[0].Str.empty()) {
      // Something handled by the asmwriter printer, but with no leading string.
      Idx = StringTable.get("");
    } else {
      std::string Str = AWI->Operands[0].Str;
      UnescapeString(Str);
      Idx = StringTable.get(Str);
      MaxStringIdx = std::max(MaxStringIdx, Idx);

      // Nuke the string from the operand list.  It is now handled!
      AWI->Operands.erase(AWI->Operands.begin());
    }

    // Bias offset by one since we want 0 as a sentinel.
    OpcodeInfo.push_back(Idx+1);
  }

  // Figure out how many bits we used for the string index.
  unsigned AsmStrBits = Log2_32_Ceil(MaxStringIdx+2);

  // To reduce code size, we compactify common instructions into a few bits
  // in the opcode-indexed table.
  unsigned BitsLeft = 32-AsmStrBits;

  std::vector<std::vector<std::string> > TableDrivenOperandPrinters;

  while (1) {
    std::vector<std::string> UniqueOperandCommands;
    std::vector<unsigned> InstIdxs;
    std::vector<unsigned> NumInstOpsHandled;
    FindUniqueOperandCommands(UniqueOperandCommands, InstIdxs,
                              NumInstOpsHandled);

    // If we ran out of operands to print, we're done.
    if (UniqueOperandCommands.empty()) break;

    // Compute the number of bits we need to represent these cases, this is
    // ceil(log2(numentries)).
    unsigned NumBits = Log2_32_Ceil(UniqueOperandCommands.size());

    // If we don't have enough bits for this operand, don't include it.
    if (NumBits > BitsLeft) {
      break;
    }

    // Otherwise, we can include this in the initial lookup table.  Add it in.
    BitsLeft -= NumBits;
    for (unsigned i = 0, e = InstIdxs.size(); i != e; ++i)
      if (InstIdxs[i] != ~0U)
        OpcodeInfo[i] |= InstIdxs[i] << (BitsLeft+AsmStrBits);

    // Remove the info about this operand.
    for (unsigned i = 0, e = NumberedInstructions.size(); i != e; ++i) {
      if (AsmWriterInst *Inst = getAsmWriterInstByID(i))
        if (!Inst->Operands.empty()) {
          unsigned NumOps = NumInstOpsHandled[InstIdxs[i]];
          assert(NumOps <= Inst->Operands.size() &&
                 "Can't remove this many ops!");
          Inst->Operands.erase(Inst->Operands.begin(),
                               Inst->Operands.begin()+NumOps);
        }
    }

    // Remember the handlers for this set of operands.
    TableDrivenOperandPrinters.push_back(UniqueOperandCommands);
  }


  O<<"  static const unsigned OpInfo[] = {\n";
  for (unsigned i = 0, e = NumberedInstructions.size(); i != e; ++i) {
    O << "    " << OpcodeInfo[i] << "U,\t// "
      << NumberedInstructions[i]->TheDef->getName() << "\n";
  }
  // Add a dummy entry so the array init doesn't end with a comma.
  O << "    0U\n";
  O << "  };\n\n";

  // Emit the string itself.
  O << "  static const char AsmStrs [] = { \n";
  StringTable.emit(O, printChar);
  O << " };\n\n";

  O << "  // Try to get the instruction mnemonic string from the table.\n"
    << "  unsigned Bits = OpInfo[MI->getOpcode()];\n"
    << "  assert(Bits != 0 && \"Cannot get the instruction mnemonic.\");\n";
  O << "  unsigned op_start = 0, operand = 0;\n";
  O << "  HSAIL_ASM::Inst inst = HSAIL_ASM::parseMnemo(AsmStrs+(Bits & "<< (1 << AsmStrBits)-1 <<")-1, brigantine);\n";
  O << "  switch(MI->getOpcode()) {\n";

  // needSpecialProcessing defined only under this macro
  HSAILVecMapEmiter vec_map(Records);

  for (unsigned i = 0, e = NumberedInstructions.size(); i != e; ++i) {
    const CodeGenInstruction * CGI = NumberedInstructions[i];
    std::string sInstName = CGI->AsmString;
    int numOperands = CGI->Operands.size();
    unsigned hasRef = CGI->needSpecialProcessing;

    if (CGI->isImageInst) {
      const std::string emission = "    BrigEmitImageInst(MI, inst);\n";
      BrigOperands[emission].push_back(i);
      continue;
    }

	if (CGI->isCrossLaneInst) {
      const std::string emission = "    BrigEmitVecOperand(MI, 0, 4);    BrigEmitOperand( MI, 4, inst);\n";
      BrigOperands[emission].push_back(i);
      continue;
    }

      
    if ( 0 != hasRef ) {
      std::ostringstream ss;

      const RecordVal *R = CGI->TheDef->getValue("Pattern");
      int vec_size = 1;

      // For vector loads and stores find equivalent scalar load or store
      Record *scalar_rec = vec_map.getVectorRec(CGI->TheDef, 1);
      if (scalar_rec != NULL)
      {
        vec_size = CGI->TheDef->getValueAsInt("VectorSize");
        R = scalar_rec->getValue("Pattern");
        numOperands -= vec_size - 1;
      }

      // Walk dag
      DAGWalker w(ss, vec_size);
      if (ListInit *LI = dyn_cast<ListInit>(R->getValue())) {
        if ( LI->getSize() > 0 ) {
          Init * dagR = LI->getElement(0);
          DagInit * dag = dyn_cast<DagInit>(dagR);
          w.WalkDAG(dag, numOperands);
        }
      }

      std::string sOperands = ss.str();
      BrigOperands[sOperands].push_back(i);
    }
  }

  std::map<std::string, std::vector<unsigned> >::const_iterator it = BrigOperands.begin();
  std::map<std::string, std::vector<unsigned> >::const_iterator en = BrigOperands.end();
  for(;it != en; it ++ ) {
    std::vector<unsigned>::const_iterator iit = it->second.begin();
    std::vector<unsigned>::const_iterator een = it->second.end();
    for(;iit != een; iit++) {
      O << "  case " << *iit << " :\t// " << NumberedInstructions[*iit]->TheDef->getName() << "\n";
    }
    O << it->first;
    O << "    return inst;\n\n";
  }

  O << "  }\n";

  O << "  unsigned nOperands = MI->getNumOperands();\n";
  O << "  for(unsigned opNum=0;opNum != nOperands; opNum++) {\n";
  O << "  BrigEmitOperand( MI, opNum, inst );\n\t";
  O << "  }\n";
  O << "  return inst;\n";
  

  O << "}\n";
}

static void
emitRegisterNameString(raw_ostream &O, StringRef AltName,
  const std::vector<CodeGenRegister*> &Registers) {
  StringToOffsetTable StringTable;
  O << "  static const unsigned RegAsmOffset" << AltName << "[] = {\n    ";
  for (unsigned i = 0, e = Registers.size(); i != e; ++i) {
    const CodeGenRegister &Reg = *Registers[i];

    std::string AsmName;
    // "NoRegAltName" is special. We don't need to do a lookup for that,
    // as it's just a reference to the default register name.
    if (AltName == "" || AltName == "NoRegAltName") {
      AsmName = Reg.TheDef->getValueAsString("AsmName");
      if (AsmName.empty())
        AsmName = Reg.getName();
    } else {
      // Make sure the register has an alternate name for this index.
      std::vector<Record*> AltNameList =
        Reg.TheDef->getValueAsListOfDefs("RegAltNameIndices");
      unsigned Idx = 0, e;
      for (e = AltNameList.size();
           Idx < e && (AltNameList[Idx]->getName() != AltName);
           ++Idx)
        ;
      // If the register has an alternate name for this index, use it.
      // Otherwise, leave it empty as an error flag.
      if (Idx < e) {
        std::vector<std::string> AltNames =
          Reg.TheDef->getValueAsListOfStrings("AltNames");
        if (AltNames.size() <= Idx)
          PrintFatalError(Reg.TheDef->getLoc(),
                        (Twine("Register definition missing alt name for '") +
                        AltName + "'.").str());
        AsmName = AltNames[Idx];
      }
    }

    O << StringTable.GetOrAddStringOffset(AsmName);
    if (((i + 1) % 14) == 0)
      O << ",\n    ";
    else
      O << ", ";

  }
  O << "0\n"
    << "  };\n"
    << "\n";

  O << "  const char *AsmStrs" << AltName << " =\n";
  StringTable.EmitString(O);
  O << ";\n";
}

void BRIGLoweringEmitter::EmitGetRegisterName(raw_ostream &O) {
  CodeGenTarget Target(Records);
  Record *AsmWriter = Target.getAsmWriter();
  std::string ClassName = AsmWriter->getValueAsString("AsmWriterClassName");
  const std::vector<CodeGenRegister*> &Registers =
    Target.getRegBank().getRegisters();
  std::vector<Record*> AltNameIndices = Target.getRegAltNameIndices();
  bool hasAltNames = AltNameIndices.size() > 1;

  std::string sTargetName = "BRIGAsmPrinter";
  O <<
  "\n\n/// getRegisterName - This method is automatically generated by tblgen\n"
  "/// from the register set description.  This returns the assembler name\n"
  "/// for the specified register.\n"
  "const char *" << sTargetName << "::";
  if (hasAltNames)
    O << "\ngetRegisterName(unsigned RegNo, unsigned AltIdx) {\n";
  else
    O << "getRegisterName(unsigned RegNo) {\n";
  O << "  assert(RegNo && RegNo < " << (Registers.size()+1)
    << " && \"Invalid register number!\");\n"
    << "\n";

  if (hasAltNames) {
    for (unsigned i = 0, e = AltNameIndices.size(); i < e; ++i)
      emitRegisterNameString(O, AltNameIndices[i]->getName(), Registers);
  } else
    emitRegisterNameString(O, "", Registers);

  if (hasAltNames) {
    O << "  const unsigned *RegAsmOffset;\n"
      << "  const char *AsmStrs;\n"
      << "  switch(AltIdx) {\n"
      << "  default: assert(0 && \"Invalid register alt name index!\");\n";
    for (unsigned i = 0, e = AltNameIndices.size(); i < e; ++i) {
      StringRef Namespace = AltNameIndices[1]->getValueAsString("Namespace");
      StringRef AltName(AltNameIndices[i]->getName());
      O << "  case " << Namespace << "::" << AltName
        << ":\n"
        << "    AsmStrs = AsmStrs" << AltName  << ";\n"
        << "    RegAsmOffset = RegAsmOffset" << AltName << ";\n"
        << "    break;\n";
    }
    O << "}\n";
  }

  O << "  assert (*(AsmStrs+RegAsmOffset[RegNo-1]) &&\n"
    << "          \"Invalid alt name index for register!\");\n"
    << "  return AsmStrs+RegAsmOffset[RegNo-1];\n"
    << "}\n";
}

void BRIGLoweringEmitter::run(raw_ostream &O) {
  //EmitSourceFileHeader("Assembly Writer Source Fragment", O);

  EmitPrintInstruction(O);
  EmitGetRegisterName(O);
  //EmitGetInstructionName(O);
  //EmitPrintAliasInstruction(O);
}

void BRIGLoweringEmitter::FindUniqueOperandCommands(std::vector<std::string> &UniqueOperandCommands,
                          std::vector<unsigned> &InstIdxs, std::vector<unsigned> &InstOpsUsed) const {
  InstIdxs.assign(NumberedInstructions.size(), ~0U);

  // This vector parallels UniqueOperandCommands, keeping track of which
  // instructions each case are used for.  It is a comma separated string of
  // enums.
  std::vector<std::string> InstrsForCase;
  InstrsForCase.resize(UniqueOperandCommands.size());
  InstOpsUsed.assign(UniqueOperandCommands.size(), 0);

  for (unsigned i = 0, e = NumberedInstructions.size(); i != e; ++i) {
    const AsmWriterInst *Inst = getAsmWriterInstByID(i);
    if (Inst == 0) continue;  // PHI, INLINEASM, PROLOG_LABEL, etc.

    std::string Command;
    if (Inst->Operands.empty())
      continue;   // Instruction already done.

    Command = "    " + Inst->Operands[0].getCode() + "\n";

    // Check to see if we already have 'Command' in UniqueOperandCommands.
    // If not, add it.
    bool FoundIt = false;
    for (unsigned idx = 0, e = UniqueOperandCommands.size(); idx != e; ++idx)
      if (UniqueOperandCommands[idx] == Command) {
        InstIdxs[i] = idx;
        InstrsForCase[idx] += ", ";
        InstrsForCase[idx] += Inst->CGI->TheDef->getName();
        FoundIt = true;
        break;
      }
    if (!FoundIt) {
      InstIdxs[i] = UniqueOperandCommands.size();
      UniqueOperandCommands.push_back(Command);
      InstrsForCase.push_back(Inst->CGI->TheDef->getName());

      // This command matches one operand so far.
      InstOpsUsed.push_back(1);
    }
  }

  // For each entry of UniqueOperandCommands, there is a set of instructions
  // that uses it.  If the next command of all instructions in the set are
  // identical, fold it into the command.
  for (unsigned CommandIdx = 0, e = UniqueOperandCommands.size();
       CommandIdx != e; ++CommandIdx) {

    for (unsigned Op = 1; ; ++Op) {
      // Scan for the first instruction in the set.
      std::vector<unsigned>::iterator NIT =
        std::find(InstIdxs.begin(), InstIdxs.end(), CommandIdx);
      if (NIT == InstIdxs.end()) break;  // No commonality.

      // If this instruction has no more operands, we isn't anything to merge
      // into this command.
      const AsmWriterInst *FirstInst =
        getAsmWriterInstByID(NIT-InstIdxs.begin());
      if (!FirstInst || FirstInst->Operands.size() == Op)
        break;

      // Otherwise, scan to see if all of the other instructions in this command
      // set share the operand.
      bool AllSame = true;
      // Keep track of the maximum, number of operands or any
      // instruction we see in the group.
      size_t MaxSize = FirstInst->Operands.size();

      for (NIT = std::find(NIT+1, InstIdxs.end(), CommandIdx);
           NIT != InstIdxs.end();
           NIT = std::find(NIT+1, InstIdxs.end(), CommandIdx)) {
        // Okay, found another instruction in this command set.  If the operand
        // matches, we're ok, otherwise bail out.
        const AsmWriterInst *OtherInst =
          getAsmWriterInstByID(NIT-InstIdxs.begin());

        if (OtherInst &&
            OtherInst->Operands.size() > FirstInst->Operands.size())
          MaxSize = std::max(MaxSize, OtherInst->Operands.size());

        if (!OtherInst || OtherInst->Operands.size() == Op ||
            OtherInst->Operands[Op] != FirstInst->Operands[Op]) {
          AllSame = false;
          break;
        }
      }
      if (!AllSame) break;

      // Okay, everything in this command set has the same next operand.  Add it
      // to UniqueOperandCommands and remember that it was consumed.
      std::string Command = "    " + FirstInst->Operands[Op].getCode() + "\n";

      UniqueOperandCommands[CommandIdx] += Command;
      InstOpsUsed[CommandIdx]++;
    }
  }

  // Prepend some of the instructions each case is used for onto the case val.
  for (unsigned i = 0, e = InstrsForCase.size(); i != e; ++i) {
    std::string Instrs = InstrsForCase[i];
    if (Instrs.size() > 70) {
      Instrs.erase(Instrs.begin()+70, Instrs.end());
      Instrs += "...";
    }

    if (!Instrs.empty())
      UniqueOperandCommands[i] = "    // " + Instrs + "\n" +
        UniqueOperandCommands[i];
  }
}

namespace llvm {

void EmitBrigWriter(RecordKeeper &RK, raw_ostream &OS) {
  emitSourceFileHeader("Lowered BRIG Source Fragment", OS);
  BRIGLoweringEmitter(RK).run(OS);
}

} // End llvm namespace

