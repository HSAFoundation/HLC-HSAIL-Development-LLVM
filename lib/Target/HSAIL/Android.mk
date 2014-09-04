LOCAL_PATH:= $(call my-dir)

#	Disassembler/HSAILDisassemblerDecoder.c
hsail_SRC_FILES := \
	BRIGAsmPrinter.cpp \
	BRIGDwarfCompileUnit.cpp \
	BRIGDwarfDebug.cpp \
	BRIGDwarfStreamer.cpp \
	HSAILAddrSpaceCast.cpp \
	HSAILAsmBackend.cpp \
	HSAILControlDependencyAnalysis.cpp \
	HSAILDevice.cpp \
	HSAILDeviceInfo.cpp \
	HSAILEarlyCFGOpts.cpp \
	HSAILELFObjectWriter.cpp \
	HSAILELFTargetObjectFile.cpp \
	HSAILELFWriterInfo.cpp \
	HSAILFastISel.cpp \
	HSAILFrameLowering.cpp \
	HSAILGlobalOffsetInsertionPass.cpp \
	HSAILInsertKernelIndexMetadata.cpp \
	HSAILInstrInfo.cpp \
	HSAILIntrinsicInfo.cpp \
	HSAILISelDAGToDAG.cpp \
	HSAILISelLowering.cpp \
	HSAILKernelArgInsertion.cpp \
	HSAILKernelManager.cpp \
	HSAILLowerSPIRSamplers.cpp \
	HSAILMachineFunctionInfo.cpp \
	HSAILMCAsmInfo.cpp \
	HSAILMCCodeEmitter.cpp \
	HSAILMergeLoadStores.cpp \
	HSAILModuleInfo.cpp \
	HSAILNullPtrInsertion.cpp \
	HSAILOpaqueTypes.cpp \
	HSAILOptimizeMemoryOps.cpp \
	HSAILParamManager.cpp \
	HSAILParseMetadata.cpp \
	HSAILPrintfRuntimeBindingMetadata.cpp \
	HSAILPropImageOps.cpp \
	HSAILRegisterInfo.cpp \
	HSAILResizePointer.cpp \
	HSAILSelectionDAGInfo.cpp \
	HSAILSubtarget.cpp \
	HSAILSyntaxCleanupPass.cpp \
	HSAILTargetMachine.cpp \
	HSAILUniformOperations.cpp \
	HSAILUtilityFunctions.cpp \
	RawVectorOstream.cpp \
	TargetInfo/HSAILTargetInfo.cpp \
	../AMDIL/MDParser/AMDILDwarfParser.cpp \
	../AMDIL/MDParser/AMDILMDParser.tab.cpp \
	../AMDIL/MDParser/AMDILMDTypes.cpp \
	../AMDIL/MDParser/lex.yy.cpp

TBLGEN_TABLES := \
	HSAILGenRegisterInfo.inc \
	HSAILGenInstrInfo.inc \
	HSAILGenSubtarget.inc \
	HSAILGenIntrinsics.inc \
	HSAILGenBrigWriter.inc \
	HSAILGenDAGISel.inc \
	HSAILGenVecMap.inc

TBLGEN_TD_DIR := \
	$(LOCAL_PATH)
# For the host
# =====================================================
include $(CLEAR_VARS)

LOCAL_MODULE:= AMDlibLLVMHSAILCodeGen
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := $(hsail_SRC_FILES)

include $(LLVM_HOST_BUILD_MK)

LOCAL_C_INCLUDES +=	\
	$(LLVM_ROOT_PATH)/../hsail-tools \
	$(LLVM_ROOT_PATH)/lib/Target/AMDIL/MDParser \
	$(LLVM_ROOT_PATH)/../../api/opencl

include $(LLVM_TBLGEN_RULES_MK)

#generate *_gen.hpp files
DK := $(DK_ROOT)
COMPILER := $(LLVM_ROOT_PATH)/..
HOSTSTATIC := $(TOP)/out/host/linux-x86/obj/STATIC_LIBRARIES
PERLLIB := $(DK_ROOT)/perl/5.16.1/lib
$(addprefix $(intermediates)/,BRIGAsmPrinter.o):$(addprefix $(intermediates)/,HSAILTemplateUtilities_gen.hpp)
$(addprefix $(intermediates)/,HSAILTemplateUtilities_gen.hpp):$(COMPILER)/hsail-tools/libHSAIL/generate.pl $(COMPILER)/hsail-tools/libHSAIL/HDLProcessor.pl
	$(DK_ROOT)/perl/5.16.1/bin/perl -I "$(PERLLIB)" $(COMPILER)/hsail-tools/libHSAIL/generate.pl --dk=$(DK_ROOT) $(COMPILER)/hsail-tools/libHSAIL $(HOSTSTATIC)/AMDlibLLVMHSAILCodeGen_intermediates
	$(DK_ROOT)/perl/5.16.1/bin/perl-static -I "$(PERLLIB)" $(COMPILER)/hsail-tools/libHSAIL/HDLProcessor.pl -target=validator <$(COMPILER)/hsail-tools/libHSAIL/HSAILBrigInstr.hdl >$(HOSTSTATIC)/AMDlibLLVMHSAILCodeGen_intermediates/HSAILInstValidation_gen.hpp.tmp

#include $(LLVM_GEN_INTRINSICS_MK)
#include $(BUILD_STATIC_LIBRARY)
# For the device
# =====================================================
include $(CLEAR_VARS)
LOCAL_MODULE_CLASS := STATIC_LIBRARIES
LOCAL_MODULE:= AMDlibLLVMHSAILCodeGen
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := $(hsail_SRC_FILES)
intermediates := $(call local-intermediates-dir)
AMDlibLLVMHSAILCodeGen_intermediates := $(intermediates)


STATIC := $(TOP)/out/debug/target/product/prototype/obj/STATIC_LIBRARIES

include $(LLVM_DEVICE_BUILD_MK)

#LOCAL_C_INCLUDES +=	\
	$(LLVM_ROOT_PATH)/../hsail-tools \
	$(LLVM_ROOT_PATH)/lib/Target/AMDIL/MDParser \
	$(LLVM_ROOT_PATH)/../../api/opencl \
	$(AMDlibLLVMHSAILCodeGen_intermediates)/

LOCAL_C_INCLUDES +=	\
	$(LLVM_ROOT_PATH)/lib/Target/HSAIL \
	$(LLVM_ROOT_PATH)/lib/Target/HSAIL/TargetInfo \
	$(LLVM_ROOT_PATH)/lib/Target/AMDIL/MDParser \
	$(LLVM_ROOT_PATH)/../../api/opencl \
	$(LLVM_ROOT_PATH)/../../compiler/hsail-tools \
	$(LLVM_ROOT_PATH)/../../compiler/hsail-tools/libHSAIL/build/lnx/B_hsa_dbg \
	$(LLVM_ROOT_PATH)/include \
	$(LLVM_ROOT_PATH)/lib/VMCore/build/lnx/B_hsa_dbg \
	$(LLVM_ROOT_PATH)/linux/include \
	$(LLVM_ROOT_PATH)/../../support/libcxx/include

include $(LLVM_TBLGEN_RULES_MK)

LOCAL_CPPFLAGS +=	\
#	-std=c++11

#generate *_gen.hpp files
TARCOMPILER := $(LLVM_ROOT_PATH)/..
#PERLLIB := /home/todli/p4sw/dk/lnx/perl/5.16.1/lib

$(addprefix $(intermediates)/,BRIGAsmPrinter.o):$(addprefix $(intermediates)/,HSAILTemplateUtilities_gen.hpp)
$(addprefix $(intermediates)/,HSAILTemplateUtilities_gen.hpp):$(TARCOMPILER)/hsail-tools/libHSAIL/generate.pl $(TARCOMPILER)/hsail-tools/libHSAIL/HDLProcessor.pl
	$(DK_ROOT)/perl/5.16.1/bin/perl -I "$(PERLLIB)" $(TARCOMPILER)/hsail-tools/libHSAIL/generate.pl --dk=$(DK_ROOT) $(TARCOMPILER)/hsail-tools/libHSAIL $(AMDlibLLVMHSAILCodeGen_intermediates)
	$(DK_ROOT)/perl/5.16.1/bin/perl-static -I "$(PERLLIB)" $(TARCOMPILER)/hsail-tools/libHSAIL/HDLProcessor.pl -target=validator <$(COMPILER)/hsail-tools/libHSAIL/HSAILBrigInstr.hdl >$(AMDlibLLVMHSAILCodeGen_intermediates)/HSAILInstValidation_gen.hpp.tmp

include $(LLVM_GEN_INTRINSICS_MK)
include $(BUILD_STATIC_LIBRARY)
