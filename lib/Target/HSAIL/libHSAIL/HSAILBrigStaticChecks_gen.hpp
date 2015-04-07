// University of Illinois/NCSA
// Open Source License
//
// Copyright (c) 2013-2015, Advanced Micro Devices, Inc.
// All rights reserved.
//
// Developed by:
//
//     HSA Team
//
//     Advanced Micro Devices, Inc
//
//     www.amd.com
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal with
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
//     * Redistributions of source code must retain the above copyright notice,
//       this list of conditions and the following disclaimers.
//
//     * Redistributions in binary form must reproduce the above copyright notice,
//       this list of conditions and the following disclaimers in the
//       documentation and/or other materials provided with the distribution.
//
//     * Neither the names of the LLVM Team, University of Illinois at
//       Urbana-Champaign, nor the names of its contributors may be used to
//       endorse or promote products derived from this Software without specific
//       prior written permission.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
// CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS WITH THE
// SOFTWARE.
static_assert(offsetof(BrigAluModifier, allBits) == 0, "bad alignment in BrigAluModifier");
static_assert(offsetof(BrigAluModifier, allBits)+sizeof(((BrigAluModifier*)0)->allBits) == sizeof(BrigAluModifier), "bad alignment in BrigAluModifier");



static_assert(offsetof(BrigDirectiveArgBlockEnd, base) == 0, "bad alignment in BrigDirectiveArgBlockEnd");
static_assert(offsetof(BrigDirectiveArgBlockEnd, base)+sizeof(((BrigDirectiveArgBlockEnd*)0)->base) == sizeof(BrigDirectiveArgBlockEnd), "bad alignment in BrigDirectiveArgBlockEnd");

static_assert(offsetof(BrigDirectiveArgBlockStart, base) == 0, "bad alignment in BrigDirectiveArgBlockStart");
static_assert(offsetof(BrigDirectiveArgBlockStart, base)+sizeof(((BrigDirectiveArgBlockStart*)0)->base) == sizeof(BrigDirectiveArgBlockStart), "bad alignment in BrigDirectiveArgBlockStart");

static_assert(offsetof(BrigDirectiveComment, base) == 0, "bad alignment in BrigDirectiveComment");
static_assert(offsetof(BrigDirectiveComment, name)+sizeof(((BrigDirectiveComment*)0)->name) == sizeof(BrigDirectiveComment), "bad alignment in BrigDirectiveComment");

static_assert(offsetof(BrigDirectiveControl, base) == 0, "bad alignment in BrigDirectiveControl");
static_assert(offsetof(BrigDirectiveControl, control)+sizeof(((BrigDirectiveControl*)0)->control) == offsetof(BrigDirectiveControl,reserved), "bad alignment in BrigDirectiveControl");
static_assert(offsetof(BrigDirectiveControl, reserved)+sizeof(((BrigDirectiveControl*)0)->reserved) == offsetof(BrigDirectiveControl,operands), "bad alignment in BrigDirectiveControl");
static_assert(offsetof(BrigDirectiveControl, operands)+sizeof(((BrigDirectiveControl*)0)->operands) == sizeof(BrigDirectiveControl), "bad alignment in BrigDirectiveControl");

static_assert(offsetof(BrigDirectiveExecutable, base) == 0, "bad alignment in BrigDirectiveExecutable");
static_assert(offsetof(BrigDirectiveExecutable, name)+sizeof(((BrigDirectiveExecutable*)0)->name) == offsetof(BrigDirectiveExecutable,outArgCount), "bad alignment in BrigDirectiveExecutable");
static_assert(offsetof(BrigDirectiveExecutable, outArgCount)+sizeof(((BrigDirectiveExecutable*)0)->outArgCount) == offsetof(BrigDirectiveExecutable,inArgCount), "bad alignment in BrigDirectiveExecutable");
static_assert(offsetof(BrigDirectiveExecutable, inArgCount)+sizeof(((BrigDirectiveExecutable*)0)->inArgCount) == offsetof(BrigDirectiveExecutable,firstInArg), "bad alignment in BrigDirectiveExecutable");
static_assert(offsetof(BrigDirectiveExecutable, firstInArg)+sizeof(((BrigDirectiveExecutable*)0)->firstInArg) == offsetof(BrigDirectiveExecutable,firstCodeBlockEntry), "bad alignment in BrigDirectiveExecutable");
static_assert(offsetof(BrigDirectiveExecutable, firstCodeBlockEntry)+sizeof(((BrigDirectiveExecutable*)0)->firstCodeBlockEntry) == offsetof(BrigDirectiveExecutable,nextModuleEntry), "bad alignment in BrigDirectiveExecutable");
static_assert(offsetof(BrigDirectiveExecutable, nextModuleEntry)+sizeof(((BrigDirectiveExecutable*)0)->nextModuleEntry) == offsetof(BrigDirectiveExecutable,modifier), "bad alignment in BrigDirectiveExecutable");
static_assert(offsetof(BrigDirectiveExecutable, modifier)+sizeof(((BrigDirectiveExecutable*)0)->modifier) == offsetof(BrigDirectiveExecutable,linkage), "bad alignment in BrigDirectiveExecutable");
static_assert(offsetof(BrigDirectiveExecutable, linkage)+sizeof(((BrigDirectiveExecutable*)0)->linkage) == offsetof(BrigDirectiveExecutable,reserved), "bad alignment in BrigDirectiveExecutable");
static_assert(offsetof(BrigDirectiveExecutable, reserved)+sizeof(((BrigDirectiveExecutable*)0)->reserved) == sizeof(BrigDirectiveExecutable), "bad alignment in BrigDirectiveExecutable");





static_assert(offsetof(BrigDirectiveExtension, base) == 0, "bad alignment in BrigDirectiveExtension");
static_assert(offsetof(BrigDirectiveExtension, name)+sizeof(((BrigDirectiveExtension*)0)->name) == sizeof(BrigDirectiveExtension), "bad alignment in BrigDirectiveExtension");

static_assert(offsetof(BrigDirectiveFbarrier, base) == 0, "bad alignment in BrigDirectiveFbarrier");
static_assert(offsetof(BrigDirectiveFbarrier, name)+sizeof(((BrigDirectiveFbarrier*)0)->name) == offsetof(BrigDirectiveFbarrier,modifier), "bad alignment in BrigDirectiveFbarrier");
static_assert(offsetof(BrigDirectiveFbarrier, modifier)+sizeof(((BrigDirectiveFbarrier*)0)->modifier) == offsetof(BrigDirectiveFbarrier,linkage), "bad alignment in BrigDirectiveFbarrier");
static_assert(offsetof(BrigDirectiveFbarrier, linkage)+sizeof(((BrigDirectiveFbarrier*)0)->linkage) == offsetof(BrigDirectiveFbarrier,reserved), "bad alignment in BrigDirectiveFbarrier");
static_assert(offsetof(BrigDirectiveFbarrier, reserved)+sizeof(((BrigDirectiveFbarrier*)0)->reserved) == sizeof(BrigDirectiveFbarrier), "bad alignment in BrigDirectiveFbarrier");

static_assert(offsetof(BrigDirectiveLabel, base) == 0, "bad alignment in BrigDirectiveLabel");
static_assert(offsetof(BrigDirectiveLabel, name)+sizeof(((BrigDirectiveLabel*)0)->name) == sizeof(BrigDirectiveLabel), "bad alignment in BrigDirectiveLabel");

static_assert(offsetof(BrigDirectiveLoc, base) == 0, "bad alignment in BrigDirectiveLoc");
static_assert(offsetof(BrigDirectiveLoc, filename)+sizeof(((BrigDirectiveLoc*)0)->filename) == offsetof(BrigDirectiveLoc,line), "bad alignment in BrigDirectiveLoc");
static_assert(offsetof(BrigDirectiveLoc, line)+sizeof(((BrigDirectiveLoc*)0)->line) == offsetof(BrigDirectiveLoc,column), "bad alignment in BrigDirectiveLoc");
static_assert(offsetof(BrigDirectiveLoc, column)+sizeof(((BrigDirectiveLoc*)0)->column) == sizeof(BrigDirectiveLoc), "bad alignment in BrigDirectiveLoc");

static_assert(offsetof(BrigDirectiveModule, base) == 0, "bad alignment in BrigDirectiveModule");
static_assert(offsetof(BrigDirectiveModule, name)+sizeof(((BrigDirectiveModule*)0)->name) == offsetof(BrigDirectiveModule,hsailMajor), "bad alignment in BrigDirectiveModule");
static_assert(offsetof(BrigDirectiveModule, hsailMajor)+sizeof(((BrigDirectiveModule*)0)->hsailMajor) == offsetof(BrigDirectiveModule,hsailMinor), "bad alignment in BrigDirectiveModule");
static_assert(offsetof(BrigDirectiveModule, hsailMinor)+sizeof(((BrigDirectiveModule*)0)->hsailMinor) == offsetof(BrigDirectiveModule,profile), "bad alignment in BrigDirectiveModule");
static_assert(offsetof(BrigDirectiveModule, profile)+sizeof(((BrigDirectiveModule*)0)->profile) == offsetof(BrigDirectiveModule,machineModel), "bad alignment in BrigDirectiveModule");
static_assert(offsetof(BrigDirectiveModule, machineModel)+sizeof(((BrigDirectiveModule*)0)->machineModel) == offsetof(BrigDirectiveModule,defaultFloatRound), "bad alignment in BrigDirectiveModule");
static_assert(offsetof(BrigDirectiveModule, defaultFloatRound)+sizeof(((BrigDirectiveModule*)0)->defaultFloatRound) == offsetof(BrigDirectiveModule,reserved), "bad alignment in BrigDirectiveModule");
static_assert(offsetof(BrigDirectiveModule, reserved)+sizeof(((BrigDirectiveModule*)0)->reserved) == sizeof(BrigDirectiveModule), "bad alignment in BrigDirectiveModule");

static_assert(offsetof(BrigDirectiveNone, base) == 0, "bad alignment in BrigDirectiveNone");
static_assert(offsetof(BrigDirectiveNone, base)+sizeof(((BrigDirectiveNone*)0)->base) == sizeof(BrigDirectiveNone), "bad alignment in BrigDirectiveNone");

static_assert(offsetof(BrigDirectivePragma, base) == 0, "bad alignment in BrigDirectivePragma");
static_assert(offsetof(BrigDirectivePragma, operands)+sizeof(((BrigDirectivePragma*)0)->operands) == sizeof(BrigDirectivePragma), "bad alignment in BrigDirectivePragma");

static_assert(offsetof(BrigDirectiveVariable, base) == 0, "bad alignment in BrigDirectiveVariable");
static_assert(offsetof(BrigDirectiveVariable, name)+sizeof(((BrigDirectiveVariable*)0)->name) == offsetof(BrigDirectiveVariable,init), "bad alignment in BrigDirectiveVariable");
static_assert(offsetof(BrigDirectiveVariable, init)+sizeof(((BrigDirectiveVariable*)0)->init) == offsetof(BrigDirectiveVariable,type), "bad alignment in BrigDirectiveVariable");
static_assert(offsetof(BrigDirectiveVariable, type)+sizeof(((BrigDirectiveVariable*)0)->type) == offsetof(BrigDirectiveVariable,segment), "bad alignment in BrigDirectiveVariable");
static_assert(offsetof(BrigDirectiveVariable, segment)+sizeof(((BrigDirectiveVariable*)0)->segment) == offsetof(BrigDirectiveVariable,align), "bad alignment in BrigDirectiveVariable");
static_assert(offsetof(BrigDirectiveVariable, align)+sizeof(((BrigDirectiveVariable*)0)->align) == offsetof(BrigDirectiveVariable,dim), "bad alignment in BrigDirectiveVariable");
static_assert(offsetof(BrigDirectiveVariable, dim)+sizeof(((BrigDirectiveVariable*)0)->dim) == offsetof(BrigDirectiveVariable,modifier), "bad alignment in BrigDirectiveVariable");
static_assert(offsetof(BrigDirectiveVariable, modifier)+sizeof(((BrigDirectiveVariable*)0)->modifier) == offsetof(BrigDirectiveVariable,linkage), "bad alignment in BrigDirectiveVariable");
static_assert(offsetof(BrigDirectiveVariable, linkage)+sizeof(((BrigDirectiveVariable*)0)->linkage) == offsetof(BrigDirectiveVariable,allocation), "bad alignment in BrigDirectiveVariable");
static_assert(offsetof(BrigDirectiveVariable, allocation)+sizeof(((BrigDirectiveVariable*)0)->allocation) == offsetof(BrigDirectiveVariable,reserved), "bad alignment in BrigDirectiveVariable");
static_assert(offsetof(BrigDirectiveVariable, reserved)+sizeof(((BrigDirectiveVariable*)0)->reserved) == sizeof(BrigDirectiveVariable), "bad alignment in BrigDirectiveVariable");

static_assert(offsetof(BrigInstBase, base) == 0, "bad alignment in BrigInstBase");
static_assert(offsetof(BrigInstBase, opcode)+sizeof(((BrigInstBase*)0)->opcode) == offsetof(BrigInstBase,type), "bad alignment in BrigInstBase");
static_assert(offsetof(BrigInstBase, type)+sizeof(((BrigInstBase*)0)->type) == offsetof(BrigInstBase,operands), "bad alignment in BrigInstBase");
static_assert(offsetof(BrigInstBase, operands)+sizeof(((BrigInstBase*)0)->operands) == sizeof(BrigInstBase), "bad alignment in BrigInstBase");

static_assert(offsetof(BrigInstAddr, base) == 0, "bad alignment in BrigInstAddr");
static_assert(offsetof(BrigInstAddr, segment)+sizeof(((BrigInstAddr*)0)->segment) == offsetof(BrigInstAddr,reserved), "bad alignment in BrigInstAddr");
static_assert(offsetof(BrigInstAddr, reserved)+sizeof(((BrigInstAddr*)0)->reserved) == sizeof(BrigInstAddr), "bad alignment in BrigInstAddr");

static_assert(offsetof(BrigInstAtomic, base) == 0, "bad alignment in BrigInstAtomic");
static_assert(offsetof(BrigInstAtomic, segment)+sizeof(((BrigInstAtomic*)0)->segment) == offsetof(BrigInstAtomic,memoryOrder), "bad alignment in BrigInstAtomic");
static_assert(offsetof(BrigInstAtomic, memoryOrder)+sizeof(((BrigInstAtomic*)0)->memoryOrder) == offsetof(BrigInstAtomic,memoryScope), "bad alignment in BrigInstAtomic");
static_assert(offsetof(BrigInstAtomic, memoryScope)+sizeof(((BrigInstAtomic*)0)->memoryScope) == offsetof(BrigInstAtomic,atomicOperation), "bad alignment in BrigInstAtomic");
static_assert(offsetof(BrigInstAtomic, atomicOperation)+sizeof(((BrigInstAtomic*)0)->atomicOperation) == offsetof(BrigInstAtomic,equivClass), "bad alignment in BrigInstAtomic");
static_assert(offsetof(BrigInstAtomic, equivClass)+sizeof(((BrigInstAtomic*)0)->equivClass) == offsetof(BrigInstAtomic,reserved), "bad alignment in BrigInstAtomic");
static_assert(offsetof(BrigInstAtomic, reserved)+sizeof(((BrigInstAtomic*)0)->reserved) == sizeof(BrigInstAtomic), "bad alignment in BrigInstAtomic");

static_assert(offsetof(BrigInstBasic, base) == 0, "bad alignment in BrigInstBasic");
static_assert(offsetof(BrigInstBasic, base)+sizeof(((BrigInstBasic*)0)->base) == sizeof(BrigInstBasic), "bad alignment in BrigInstBasic");

static_assert(offsetof(BrigInstBr, base) == 0, "bad alignment in BrigInstBr");
static_assert(offsetof(BrigInstBr, width)+sizeof(((BrigInstBr*)0)->width) == offsetof(BrigInstBr,reserved), "bad alignment in BrigInstBr");
static_assert(offsetof(BrigInstBr, reserved)+sizeof(((BrigInstBr*)0)->reserved) == sizeof(BrigInstBr), "bad alignment in BrigInstBr");

static_assert(offsetof(BrigInstCmp, base) == 0, "bad alignment in BrigInstCmp");
static_assert(offsetof(BrigInstCmp, sourceType)+sizeof(((BrigInstCmp*)0)->sourceType) == offsetof(BrigInstCmp,modifier), "bad alignment in BrigInstCmp");
static_assert(offsetof(BrigInstCmp, modifier)+sizeof(((BrigInstCmp*)0)->modifier) == offsetof(BrigInstCmp,compare), "bad alignment in BrigInstCmp");
static_assert(offsetof(BrigInstCmp, compare)+sizeof(((BrigInstCmp*)0)->compare) == offsetof(BrigInstCmp,pack), "bad alignment in BrigInstCmp");
static_assert(offsetof(BrigInstCmp, pack)+sizeof(((BrigInstCmp*)0)->pack) == offsetof(BrigInstCmp,reserved), "bad alignment in BrigInstCmp");
static_assert(offsetof(BrigInstCmp, reserved)+sizeof(((BrigInstCmp*)0)->reserved) == sizeof(BrigInstCmp), "bad alignment in BrigInstCmp");

static_assert(offsetof(BrigInstCvt, base) == 0, "bad alignment in BrigInstCvt");
static_assert(offsetof(BrigInstCvt, sourceType)+sizeof(((BrigInstCvt*)0)->sourceType) == offsetof(BrigInstCvt,modifier), "bad alignment in BrigInstCvt");
static_assert(offsetof(BrigInstCvt, modifier)+sizeof(((BrigInstCvt*)0)->modifier) == offsetof(BrigInstCvt,round), "bad alignment in BrigInstCvt");
static_assert(offsetof(BrigInstCvt, round)+sizeof(((BrigInstCvt*)0)->round) == sizeof(BrigInstCvt), "bad alignment in BrigInstCvt");

static_assert(offsetof(BrigInstImage, base) == 0, "bad alignment in BrigInstImage");
static_assert(offsetof(BrigInstImage, imageType)+sizeof(((BrigInstImage*)0)->imageType) == offsetof(BrigInstImage,coordType), "bad alignment in BrigInstImage");
static_assert(offsetof(BrigInstImage, coordType)+sizeof(((BrigInstImage*)0)->coordType) == offsetof(BrigInstImage,geometry), "bad alignment in BrigInstImage");
static_assert(offsetof(BrigInstImage, geometry)+sizeof(((BrigInstImage*)0)->geometry) == offsetof(BrigInstImage,equivClass), "bad alignment in BrigInstImage");
static_assert(offsetof(BrigInstImage, equivClass)+sizeof(((BrigInstImage*)0)->equivClass) == offsetof(BrigInstImage,reserved), "bad alignment in BrigInstImage");
static_assert(offsetof(BrigInstImage, reserved)+sizeof(((BrigInstImage*)0)->reserved) == sizeof(BrigInstImage), "bad alignment in BrigInstImage");

static_assert(offsetof(BrigInstLane, base) == 0, "bad alignment in BrigInstLane");
static_assert(offsetof(BrigInstLane, sourceType)+sizeof(((BrigInstLane*)0)->sourceType) == offsetof(BrigInstLane,width), "bad alignment in BrigInstLane");
static_assert(offsetof(BrigInstLane, width)+sizeof(((BrigInstLane*)0)->width) == offsetof(BrigInstLane,reserved), "bad alignment in BrigInstLane");
static_assert(offsetof(BrigInstLane, reserved)+sizeof(((BrigInstLane*)0)->reserved) == sizeof(BrigInstLane), "bad alignment in BrigInstLane");

static_assert(offsetof(BrigInstMem, base) == 0, "bad alignment in BrigInstMem");
static_assert(offsetof(BrigInstMem, segment)+sizeof(((BrigInstMem*)0)->segment) == offsetof(BrigInstMem,align), "bad alignment in BrigInstMem");
static_assert(offsetof(BrigInstMem, align)+sizeof(((BrigInstMem*)0)->align) == offsetof(BrigInstMem,equivClass), "bad alignment in BrigInstMem");
static_assert(offsetof(BrigInstMem, equivClass)+sizeof(((BrigInstMem*)0)->equivClass) == offsetof(BrigInstMem,width), "bad alignment in BrigInstMem");
static_assert(offsetof(BrigInstMem, width)+sizeof(((BrigInstMem*)0)->width) == offsetof(BrigInstMem,modifier), "bad alignment in BrigInstMem");
static_assert(offsetof(BrigInstMem, modifier)+sizeof(((BrigInstMem*)0)->modifier) == offsetof(BrigInstMem,reserved), "bad alignment in BrigInstMem");
static_assert(offsetof(BrigInstMem, reserved)+sizeof(((BrigInstMem*)0)->reserved) == sizeof(BrigInstMem), "bad alignment in BrigInstMem");

static_assert(offsetof(BrigInstMemFence, base) == 0, "bad alignment in BrigInstMemFence");
static_assert(offsetof(BrigInstMemFence, memoryOrder)+sizeof(((BrigInstMemFence*)0)->memoryOrder) == offsetof(BrigInstMemFence,globalSegmentMemoryScope), "bad alignment in BrigInstMemFence");
static_assert(offsetof(BrigInstMemFence, globalSegmentMemoryScope)+sizeof(((BrigInstMemFence*)0)->globalSegmentMemoryScope) == offsetof(BrigInstMemFence,groupSegmentMemoryScope), "bad alignment in BrigInstMemFence");
static_assert(offsetof(BrigInstMemFence, groupSegmentMemoryScope)+sizeof(((BrigInstMemFence*)0)->groupSegmentMemoryScope) == offsetof(BrigInstMemFence,imageSegmentMemoryScope), "bad alignment in BrigInstMemFence");
static_assert(offsetof(BrigInstMemFence, imageSegmentMemoryScope)+sizeof(((BrigInstMemFence*)0)->imageSegmentMemoryScope) == sizeof(BrigInstMemFence), "bad alignment in BrigInstMemFence");

static_assert(offsetof(BrigInstMod, base) == 0, "bad alignment in BrigInstMod");
static_assert(offsetof(BrigInstMod, modifier)+sizeof(((BrigInstMod*)0)->modifier) == offsetof(BrigInstMod,round), "bad alignment in BrigInstMod");
static_assert(offsetof(BrigInstMod, round)+sizeof(((BrigInstMod*)0)->round) == offsetof(BrigInstMod,pack), "bad alignment in BrigInstMod");
static_assert(offsetof(BrigInstMod, pack)+sizeof(((BrigInstMod*)0)->pack) == offsetof(BrigInstMod,reserved), "bad alignment in BrigInstMod");
static_assert(offsetof(BrigInstMod, reserved)+sizeof(((BrigInstMod*)0)->reserved) == sizeof(BrigInstMod), "bad alignment in BrigInstMod");

static_assert(offsetof(BrigInstQueryImage, base) == 0, "bad alignment in BrigInstQueryImage");
static_assert(offsetof(BrigInstQueryImage, imageType)+sizeof(((BrigInstQueryImage*)0)->imageType) == offsetof(BrigInstQueryImage,geometry), "bad alignment in BrigInstQueryImage");
static_assert(offsetof(BrigInstQueryImage, geometry)+sizeof(((BrigInstQueryImage*)0)->geometry) == offsetof(BrigInstQueryImage,imageQuery), "bad alignment in BrigInstQueryImage");
static_assert(offsetof(BrigInstQueryImage, imageQuery)+sizeof(((BrigInstQueryImage*)0)->imageQuery) == sizeof(BrigInstQueryImage), "bad alignment in BrigInstQueryImage");

static_assert(offsetof(BrigInstQuerySampler, base) == 0, "bad alignment in BrigInstQuerySampler");
static_assert(offsetof(BrigInstQuerySampler, samplerQuery)+sizeof(((BrigInstQuerySampler*)0)->samplerQuery) == offsetof(BrigInstQuerySampler,reserved), "bad alignment in BrigInstQuerySampler");
static_assert(offsetof(BrigInstQuerySampler, reserved)+sizeof(((BrigInstQuerySampler*)0)->reserved) == sizeof(BrigInstQuerySampler), "bad alignment in BrigInstQuerySampler");

static_assert(offsetof(BrigInstQueue, base) == 0, "bad alignment in BrigInstQueue");
static_assert(offsetof(BrigInstQueue, segment)+sizeof(((BrigInstQueue*)0)->segment) == offsetof(BrigInstQueue,memoryOrder), "bad alignment in BrigInstQueue");
static_assert(offsetof(BrigInstQueue, memoryOrder)+sizeof(((BrigInstQueue*)0)->memoryOrder) == offsetof(BrigInstQueue,reserved), "bad alignment in BrigInstQueue");
static_assert(offsetof(BrigInstQueue, reserved)+sizeof(((BrigInstQueue*)0)->reserved) == sizeof(BrigInstQueue), "bad alignment in BrigInstQueue");

static_assert(offsetof(BrigInstSeg, base) == 0, "bad alignment in BrigInstSeg");
static_assert(offsetof(BrigInstSeg, segment)+sizeof(((BrigInstSeg*)0)->segment) == offsetof(BrigInstSeg,reserved), "bad alignment in BrigInstSeg");
static_assert(offsetof(BrigInstSeg, reserved)+sizeof(((BrigInstSeg*)0)->reserved) == sizeof(BrigInstSeg), "bad alignment in BrigInstSeg");

static_assert(offsetof(BrigInstSegCvt, base) == 0, "bad alignment in BrigInstSegCvt");
static_assert(offsetof(BrigInstSegCvt, sourceType)+sizeof(((BrigInstSegCvt*)0)->sourceType) == offsetof(BrigInstSegCvt,segment), "bad alignment in BrigInstSegCvt");
static_assert(offsetof(BrigInstSegCvt, segment)+sizeof(((BrigInstSegCvt*)0)->segment) == offsetof(BrigInstSegCvt,modifier), "bad alignment in BrigInstSegCvt");
static_assert(offsetof(BrigInstSegCvt, modifier)+sizeof(((BrigInstSegCvt*)0)->modifier) == sizeof(BrigInstSegCvt), "bad alignment in BrigInstSegCvt");

static_assert(offsetof(BrigInstSignal, base) == 0, "bad alignment in BrigInstSignal");
static_assert(offsetof(BrigInstSignal, signalType)+sizeof(((BrigInstSignal*)0)->signalType) == offsetof(BrigInstSignal,memoryOrder), "bad alignment in BrigInstSignal");
static_assert(offsetof(BrigInstSignal, memoryOrder)+sizeof(((BrigInstSignal*)0)->memoryOrder) == offsetof(BrigInstSignal,signalOperation), "bad alignment in BrigInstSignal");
static_assert(offsetof(BrigInstSignal, signalOperation)+sizeof(((BrigInstSignal*)0)->signalOperation) == sizeof(BrigInstSignal), "bad alignment in BrigInstSignal");

static_assert(offsetof(BrigInstSourceType, base) == 0, "bad alignment in BrigInstSourceType");
static_assert(offsetof(BrigInstSourceType, sourceType)+sizeof(((BrigInstSourceType*)0)->sourceType) == offsetof(BrigInstSourceType,reserved), "bad alignment in BrigInstSourceType");
static_assert(offsetof(BrigInstSourceType, reserved)+sizeof(((BrigInstSourceType*)0)->reserved) == sizeof(BrigInstSourceType), "bad alignment in BrigInstSourceType");

static_assert(offsetof(BrigExecutableModifier, allBits) == 0, "bad alignment in BrigExecutableModifier");
static_assert(offsetof(BrigExecutableModifier, allBits)+sizeof(((BrigExecutableModifier*)0)->allBits) == sizeof(BrigExecutableModifier), "bad alignment in BrigExecutableModifier");

static_assert(offsetof(BrigMemoryModifier, allBits) == 0, "bad alignment in BrigMemoryModifier");
static_assert(offsetof(BrigMemoryModifier, allBits)+sizeof(((BrigMemoryModifier*)0)->allBits) == sizeof(BrigMemoryModifier), "bad alignment in BrigMemoryModifier");


static_assert(offsetof(BrigOperandAddress, base) == 0, "bad alignment in BrigOperandAddress");
static_assert(offsetof(BrigOperandAddress, symbol)+sizeof(((BrigOperandAddress*)0)->symbol) == offsetof(BrigOperandAddress,reg), "bad alignment in BrigOperandAddress");
static_assert(offsetof(BrigOperandAddress, reg)+sizeof(((BrigOperandAddress*)0)->reg) == offsetof(BrigOperandAddress,offset), "bad alignment in BrigOperandAddress");
static_assert(offsetof(BrigOperandAddress, offset)+sizeof(((BrigOperandAddress*)0)->offset) == sizeof(BrigOperandAddress), "bad alignment in BrigOperandAddress");

static_assert(offsetof(BrigOperandAlign, base) == 0, "bad alignment in BrigOperandAlign");
static_assert(offsetof(BrigOperandAlign, align)+sizeof(((BrigOperandAlign*)0)->align) == offsetof(BrigOperandAlign,reserved), "bad alignment in BrigOperandAlign");
static_assert(offsetof(BrigOperandAlign, reserved)+sizeof(((BrigOperandAlign*)0)->reserved) == sizeof(BrigOperandAlign), "bad alignment in BrigOperandAlign");

static_assert(offsetof(BrigOperandCodeList, base) == 0, "bad alignment in BrigOperandCodeList");
static_assert(offsetof(BrigOperandCodeList, elements)+sizeof(((BrigOperandCodeList*)0)->elements) == sizeof(BrigOperandCodeList), "bad alignment in BrigOperandCodeList");

static_assert(offsetof(BrigOperandCodeRef, base) == 0, "bad alignment in BrigOperandCodeRef");
static_assert(offsetof(BrigOperandCodeRef, ref)+sizeof(((BrigOperandCodeRef*)0)->ref) == sizeof(BrigOperandCodeRef), "bad alignment in BrigOperandCodeRef");

static_assert(offsetof(BrigOperandConstantBytes, base) == 0, "bad alignment in BrigOperandConstantBytes");
static_assert(offsetof(BrigOperandConstantBytes, type)+sizeof(((BrigOperandConstantBytes*)0)->type) == offsetof(BrigOperandConstantBytes,reserved), "bad alignment in BrigOperandConstantBytes");
static_assert(offsetof(BrigOperandConstantBytes, reserved)+sizeof(((BrigOperandConstantBytes*)0)->reserved) == offsetof(BrigOperandConstantBytes,bytes), "bad alignment in BrigOperandConstantBytes");
static_assert(offsetof(BrigOperandConstantBytes, bytes)+sizeof(((BrigOperandConstantBytes*)0)->bytes) == sizeof(BrigOperandConstantBytes), "bad alignment in BrigOperandConstantBytes");

static_assert(offsetof(BrigOperandConstantImage, base) == 0, "bad alignment in BrigOperandConstantImage");
static_assert(offsetof(BrigOperandConstantImage, type)+sizeof(((BrigOperandConstantImage*)0)->type) == offsetof(BrigOperandConstantImage,geometry), "bad alignment in BrigOperandConstantImage");
static_assert(offsetof(BrigOperandConstantImage, geometry)+sizeof(((BrigOperandConstantImage*)0)->geometry) == offsetof(BrigOperandConstantImage,channelOrder), "bad alignment in BrigOperandConstantImage");
static_assert(offsetof(BrigOperandConstantImage, channelOrder)+sizeof(((BrigOperandConstantImage*)0)->channelOrder) == offsetof(BrigOperandConstantImage,channelType), "bad alignment in BrigOperandConstantImage");
static_assert(offsetof(BrigOperandConstantImage, channelType)+sizeof(((BrigOperandConstantImage*)0)->channelType) == offsetof(BrigOperandConstantImage,reserved), "bad alignment in BrigOperandConstantImage");
static_assert(offsetof(BrigOperandConstantImage, reserved)+sizeof(((BrigOperandConstantImage*)0)->reserved) == offsetof(BrigOperandConstantImage,width), "bad alignment in BrigOperandConstantImage");
static_assert(offsetof(BrigOperandConstantImage, width)+sizeof(((BrigOperandConstantImage*)0)->width) == offsetof(BrigOperandConstantImage,height), "bad alignment in BrigOperandConstantImage");
static_assert(offsetof(BrigOperandConstantImage, height)+sizeof(((BrigOperandConstantImage*)0)->height) == offsetof(BrigOperandConstantImage,depth), "bad alignment in BrigOperandConstantImage");
static_assert(offsetof(BrigOperandConstantImage, depth)+sizeof(((BrigOperandConstantImage*)0)->depth) == offsetof(BrigOperandConstantImage,array), "bad alignment in BrigOperandConstantImage");
static_assert(offsetof(BrigOperandConstantImage, array)+sizeof(((BrigOperandConstantImage*)0)->array) == sizeof(BrigOperandConstantImage), "bad alignment in BrigOperandConstantImage");

static_assert(offsetof(BrigOperandConstantOperandList, base) == 0, "bad alignment in BrigOperandConstantOperandList");
static_assert(offsetof(BrigOperandConstantOperandList, type)+sizeof(((BrigOperandConstantOperandList*)0)->type) == offsetof(BrigOperandConstantOperandList,reserved), "bad alignment in BrigOperandConstantOperandList");
static_assert(offsetof(BrigOperandConstantOperandList, reserved)+sizeof(((BrigOperandConstantOperandList*)0)->reserved) == offsetof(BrigOperandConstantOperandList,elements), "bad alignment in BrigOperandConstantOperandList");
static_assert(offsetof(BrigOperandConstantOperandList, elements)+sizeof(((BrigOperandConstantOperandList*)0)->elements) == sizeof(BrigOperandConstantOperandList), "bad alignment in BrigOperandConstantOperandList");

static_assert(offsetof(BrigOperandConstantSampler, base) == 0, "bad alignment in BrigOperandConstantSampler");
static_assert(offsetof(BrigOperandConstantSampler, type)+sizeof(((BrigOperandConstantSampler*)0)->type) == offsetof(BrigOperandConstantSampler,coord), "bad alignment in BrigOperandConstantSampler");
static_assert(offsetof(BrigOperandConstantSampler, coord)+sizeof(((BrigOperandConstantSampler*)0)->coord) == offsetof(BrigOperandConstantSampler,filter), "bad alignment in BrigOperandConstantSampler");
static_assert(offsetof(BrigOperandConstantSampler, filter)+sizeof(((BrigOperandConstantSampler*)0)->filter) == offsetof(BrigOperandConstantSampler,addressing), "bad alignment in BrigOperandConstantSampler");
static_assert(offsetof(BrigOperandConstantSampler, addressing)+sizeof(((BrigOperandConstantSampler*)0)->addressing) == offsetof(BrigOperandConstantSampler,reserved), "bad alignment in BrigOperandConstantSampler");
static_assert(offsetof(BrigOperandConstantSampler, reserved)+sizeof(((BrigOperandConstantSampler*)0)->reserved) == sizeof(BrigOperandConstantSampler), "bad alignment in BrigOperandConstantSampler");

static_assert(offsetof(BrigOperandOperandList, base) == 0, "bad alignment in BrigOperandOperandList");
static_assert(offsetof(BrigOperandOperandList, elements)+sizeof(((BrigOperandOperandList*)0)->elements) == sizeof(BrigOperandOperandList), "bad alignment in BrigOperandOperandList");

static_assert(offsetof(BrigOperandRegister, base) == 0, "bad alignment in BrigOperandRegister");
static_assert(offsetof(BrigOperandRegister, regKind)+sizeof(((BrigOperandRegister*)0)->regKind) == offsetof(BrigOperandRegister,regNum), "bad alignment in BrigOperandRegister");
static_assert(offsetof(BrigOperandRegister, regNum)+sizeof(((BrigOperandRegister*)0)->regNum) == sizeof(BrigOperandRegister), "bad alignment in BrigOperandRegister");

static_assert(offsetof(BrigOperandString, base) == 0, "bad alignment in BrigOperandString");
static_assert(offsetof(BrigOperandString, string)+sizeof(((BrigOperandString*)0)->string) == sizeof(BrigOperandString), "bad alignment in BrigOperandString");

static_assert(offsetof(BrigOperandWavesize, base) == 0, "bad alignment in BrigOperandWavesize");
static_assert(offsetof(BrigOperandWavesize, base)+sizeof(((BrigOperandWavesize*)0)->base) == sizeof(BrigOperandWavesize), "bad alignment in BrigOperandWavesize");

static_assert(offsetof(BrigSegCvtModifier, allBits) == 0, "bad alignment in BrigSegCvtModifier");
static_assert(offsetof(BrigSegCvtModifier, allBits)+sizeof(((BrigSegCvtModifier*)0)->allBits) == sizeof(BrigSegCvtModifier), "bad alignment in BrigSegCvtModifier");

static_assert(offsetof(BrigUInt64, lo) == 0, "bad alignment in BrigUInt64");
static_assert(offsetof(BrigUInt64, hi)+sizeof(((BrigUInt64*)0)->hi) == sizeof(BrigUInt64), "bad alignment in BrigUInt64");

static_assert(offsetof(BrigVariableModifier, allBits) == 0, "bad alignment in BrigVariableModifier");
static_assert(offsetof(BrigVariableModifier, allBits)+sizeof(((BrigVariableModifier*)0)->allBits) == sizeof(BrigVariableModifier), "bad alignment in BrigVariableModifier");

