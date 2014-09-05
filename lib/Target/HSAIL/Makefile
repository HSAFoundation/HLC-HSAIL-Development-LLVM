##===- lib/Target/HSAIL/Makefile ---------------------------*- Makefile -*-===##
#
#                     The LLVM Compiler Infrastructure
#
# This file is distributed under the University of Illinois Open Source
# License. See LICENSE.TXT for details.
#
##===----------------------------------------------------------------------===##

LEVEL = ../../..
LIBRARYNAME = LLVMHSAILCodeGen
TARGET = HSAIL


BUILT_SOURCES = HSAILGenRegisterInfo.inc HSAILGenInstrInfo.inc \
		HSAILGenDAGISel.inc  HSAILGenSubtargetInfo.inc \
		HSAILGenMCCodeEmitter.inc HSAILGenCallingConv.inc \
		HSAILGenIntrinsics.inc HSAILGenAsmWriter.inc


DIRS = libHSAIL TargetInfo

include $(LEVEL)/Makefile.common
