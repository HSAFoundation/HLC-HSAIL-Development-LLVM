//===- llvm-link.cpp - Low-level LLVM linker ------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This utility may be invoked in the following manner:
//  llvm-link a.bc b.bc c.bc -o x.bc
//
//===----------------------------------------------------------------------===//

#include "llvm/Linker/Linker.h"
#include "llvm/Bitcode/ReaderWriter.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/ManagedStatic.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/PrettyStackTrace.h"
#include "llvm/Support/Signals.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/SystemUtils.h"
#include "llvm/Support/ToolOutputFile.h"
#include "llvm/AMDResolveLinker.h"
#include <memory>
using namespace llvm;

static cl::list<std::string>
InputFilenames(cl::Positional, cl::OneOrMore,
               cl::desc("<input bitcode files>"));

static cl::opt<std::string>
OutputFilename("o", cl::desc("Override output filename"), cl::init("-"),
               cl::value_desc("filename"));

static cl::opt<bool>
Force("f", cl::desc("Enable binary output on terminals"));

static cl::opt<bool>
OutputAssembly("S",
         cl::desc("Write output as LLVM assembly"), cl::Hidden);

static cl::opt<bool>
Verbose("v", cl::desc("Print information about actions taken"));

static cl::opt<bool>
DumpAsm("d", cl::desc("Print assembly as linked"), cl::Hidden);

static cl::opt<bool>
PreLinkOpt("prelink-opt", cl::desc("Enable pre-link optimizations"));

static cl::opt<bool>
EnableWholeProgram("whole", cl::desc("Enable whole program mode"));

static cl::list<std::string> Libraries("l", cl::Prefix,
                                       cl::desc("Specify libraries to link to"),
                                       cl::value_desc("library prefix"));


static cl::opt<bool>
SuppressWarnings("suppress-warnings", cl::desc("Suppress all linking warnings"),
                 cl::init(false));

// Read the specified bitcode file in and return it. This routine searches the
// link path for the specified file to try to find it...
//
static std::unique_ptr<Module>
loadFile(const char *argv0, const std::string &FN, LLVMContext &Context) {
  SMDiagnostic Err;
  if (Verbose) errs() << "Loading '" << FN << "'\n";

  std::unique_ptr<Module> Result = parseIRFile(FN, Err, Context);
  if (!Result) 
      Err.print(argv0, errs());
  return Result;
}


int main(int argc, char **argv) {
  // Print a stack trace if we signal out.
  sys::PrintStackTraceOnErrorSignal();
  PrettyStackTraceProgram X(argc, argv);

  LLVMContext &Context = getGlobalContext();
  llvm_shutdown_obj Y;  // Call llvm_shutdown() on exit.
  cl::ParseCommandLineOptions(argc, argv, "llvm linker\n");

  unsigned BaseArg = 0;
  std::string ErrorMessage;

  std::unique_ptr<Module> Composite =
      loadFile(argv[0], InputFilenames[BaseArg], Context);
  if (!Composite.get()) {
    errs() << argv[0] << ": error loading file '"
           << InputFilenames[BaseArg] << "'\n";
    return 1;
  }

  Linker L(Composite.get(), SuppressWarnings);
  for (unsigned i = BaseArg+1; i < InputFilenames.size(); ++i) {
    std::unique_ptr<Module> M = loadFile(argv[0], InputFilenames[i], Context);
    if (!M.get()) {
      errs() << argv[0] << ": error loading file '" <<InputFilenames[i]<< "'\n";
      return 1;
    }

    if (Verbose) errs() << "Linking in '" << InputFilenames[i] << "'\n";

    if (L.linkInModule(M.get(), &ErrorMessage)) {
      errs() << argv[0] << ": link error in '" << InputFilenames[i]
             << "': " << ErrorMessage << "\n";
      return 1;
    }
  }

  // TODO: Iterate over the -l list and link in any modules containing
  // global symbols that have not been resolved so far.


  // Link unresolved symbols from libraries
  std::vector<Module*> Libs;
  for (std::vector<std::string>::iterator i = Libraries.begin(),
       e = Libraries.end(); i != e; ++i) {
    std::unique_ptr<Module> M(loadFile(argv[0], *i, Context));
    if (M.get() == 0) {
      SMDiagnostic Err(*i, SourceMgr::DK_Error, "error loading file");
      Err.print(argv[0], errs());
      return 1;
    }
    if (Verbose) errs() << "Linking in '" << *i << "'\n";
    Libs.push_back(M.get());
    M.release();
  }

  if (Libs.size() > 0) {
    std::string ErrorMsg;
    if (resolveLink(Composite.get(), Libs, &ErrorMsg)) {
      SMDiagnostic Err(InputFilenames[BaseArg], SourceMgr::DK_Error, ErrorMsg);
      Err.print(argv[0], errs());
      return 1;
    }
  }


  if (DumpAsm) errs() << "Here's the assembly:\n" << *Composite;

  std::error_code EC;
  tool_output_file Out(OutputFilename, EC, sys::fs::F_None);
  if (EC) {
    errs() << EC.message() << '\n';
    return 1;
  }

  if (verifyModule(*Composite)) {
    errs() << argv[0] << ": linked module is broken!\n";
    return 1;
  }

  if (Verbose) errs() << "Writing bitcode...\n";
  if (OutputAssembly) {
    Out.os() << *Composite;
  } else if (Force || !CheckBitcodeOutputToConsole(Out.os(), true))
    WriteBitcodeToFile(Composite.get(), Out.os());

  // Declare success.
  Out.keep();

  return 0;
}
