//==- HSAILRegisterInfo.td - Main HSAIL Register Definition -*- tablegen -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file describes the HSAIL register file, defining the registers themselves,
// aliases between the registers, and the register classes built out of the
// registers.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//  Register definitions...
//
class HSAILReg<string n, int d> : Register<n> {
  let Namespace = "HSAIL";
  let DwarfNumbers = [d];
}


//32-bit registers for signed, unsigned integers or float values
foreach N = 0-127 in {
  def S#N : HSAILReg<"$s"#N, !add(0, N)>;
}

//64-bit registers for signed, unsigned long integers or double float values
foreach N = 0-63 in {
  def D#N : HSAILReg<"$d"#N, !add(128, N)>;
}

//1-bit control registers
foreach N = 0-7 in {
  def C#N : HSAILReg<"$c"#N, !add(192, N)>;
}

//===----------------------------------------------------------------------===//
// HSAILReg Class Definitions... now that we have all of the pieces, define the
// top-level register classes.  The order specified in the register list is
// implicitly defined to be the register allocation order.
//
def GPR32 : RegisterClass<"HSAIL", [i32, f32], 32,
                         (sequence "S%u", 0, 127)> {
}

def GPR64 : RegisterClass<"HSAIL", [i64, f64], 64,
                         (sequence "D%u", 0, 63)> {
}

def CR : RegisterClass<"HSAIL", [i1], 32,
                         (sequence "C%u", 0, 7)> {
  let Size = 32;
}
