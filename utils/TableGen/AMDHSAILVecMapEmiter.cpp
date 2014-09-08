#include "AMDHSAILVecMapEmiter.h"
#include "CodeGenTarget.h"

#include <sstream>

using namespace llvm;

///
/// Emit vector load and store instruction mapping
///
/// TODO_HSA: Once we have InstrMappings in llvm 
/// reimplement our scalar to vector maps using core llvm functionality
void HSAILVecMapEmiter::run(raw_ostream &O)
{
  CodeGenTarget Target(Records);

  // No vector operations at all, quick return
  Record *Class = Records.getClass("VectorOperation");
  if (!Class)
    return;

  // Emit conversion switch based on VecInstMap
  O << "switch (Opc) {\n"
    << "  default: isOk = false; break;\n";

  for (std::map<std::string, std::vector<Record*> >::const_iterator 
       it = VecInstMap.begin(), it_end = VecInstMap.end(); it != it_end; ++it)
  {
    // Map vector size and vector definition
    CodeGenInstruction *vec_ops[4] = {0};

    for (unsigned i = 0; i < it->second.size(); ++i)
    {
      int vec_size = it->second[i]->getValueAsInt("VectorSize");
      // Normally we should not get any vectors larger than 4 element
      if (vec_size > 4)
        continue;
      vec_ops[vec_size - 1] = &Target.getInstruction(it->second[i]);
    }

    if (vec_ops[0] == 0 || (vec_ops[1] == 0 && 
                            vec_ops[2] == 0 && 
                            vec_ops[3] == 0))
      continue;

    // Emit switch case 
    O << 
      "  case " << vec_ops[0]->Namespace << "::" << 
                   vec_ops[0]->TheDef->getName() << ": \n";
    if (vec_ops[3] != 0)
      O  << "    if (Size == 4) return " << vec_ops[3]->Namespace << "::" 
                                    << vec_ops[3]->TheDef->getName() << ";\n";
    if (vec_ops[2] != 0)
      O  << "    if (Size == 3) return " << vec_ops[2]->Namespace << "::" 
                                    << vec_ops[2]->TheDef->getName() << ";\n";
    if (vec_ops[1] != 0)
      O  << "    if (Size == 2) return " << vec_ops[1]->Namespace << "::" 
         << vec_ops[1]->TheDef->getName() << ";\n";
    O  << "    break;\n";

  } 
  O << "}\n";
}

std::string llvm::HSAILVecMapEmiter::getBaseName( Record *rec )
{
  std::string name = rec->getName();

  std::size_t pos = name.find("_v");
  if (pos == std::string::npos)
    return "";

  name.replace(pos, 3, "");

  return name;
}

void HSAILVecMapEmiter::buildVecMap()
{
  std::vector<Record*> vector_ops = 
    Records.getAllDerivedDefinitions("VectorOperation");

  for (unsigned i = 0; i < vector_ops.size(); ++i)
  {
    std::string name = getBaseName(vector_ops[i]);
    if (name == "")
      continue;
    VecInstMap[name].push_back(vector_ops[i]);
  }
}

Record *llvm::HSAILVecMapEmiter::getVectorRec( Record *Src, int VecSize )
{
  std::string base_name = getBaseName(Src);
  if (base_name == "")
    return NULL;

  VecInstMapType::iterator it = VecInstMap.find(base_name);
  if (it == VecInstMap.end())
    return NULL;

  for (std::size_t i = 0; i < it->second.size(); ++i)
  {
    if (VecSize == it->second[i]->getValueAsInt("VectorSize"))
      return it->second[i];
  }
  return NULL;
}

namespace llvm {
  void EmitHSAILVecMap(RecordKeeper &RK, raw_ostream &OS) 
  {
    emitSourceFileHeader("HSAIL Vec Map Source Fragment", OS);
    HSAILVecMapEmiter(RK).run(OS);

  } 
} // End llvm namespace

