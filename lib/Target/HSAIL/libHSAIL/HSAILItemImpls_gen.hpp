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
unsigned align2num(unsigned arg);
const char* align2str(unsigned arg);
BrigAlignment num2align(uint64_t arg);
const char* allocation2str(unsigned arg);
const char* atomicOperation2str(unsigned arg);
const char* compareOperation2str(unsigned arg);
const char* controlDirective2str(unsigned arg);
const char* imageChannelOrder2str(unsigned arg);
const char* imageChannelType2str(unsigned arg);
bool isBrigGeometryDepth(unsigned geo);
unsigned getBrigGeometryDim(unsigned geo);
const char* imageGeometry2str(unsigned arg);
const char* imageQuery2str(unsigned arg);
bool isBodyOnly(Directive d);
bool isToplevelOnly(Directive d);
const char* kind2str(unsigned arg);
int size_of_brig_record(unsigned arg);
const char* linkage2str(unsigned arg);
const char* machineModel2str(unsigned arg);
const char* memoryOrder2str(unsigned arg);
const char* memoryScope2str(unsigned arg);
bool instHasType(BrigOpcode16_t arg);
const char* opcode2str(unsigned arg);
int instNumDstOperands(BrigOpcode16_t arg);
const char* pack2str(unsigned arg);
const char* profile2str(unsigned arg);
unsigned getRegBits(BrigRegisterKind16_t arg);
const char* registerKind2str(unsigned arg);
bool isFloatRounding(unsigned rounding);
bool isIntRounding(unsigned rounding);
const char* round2str(unsigned arg);
bool isSatRounding(unsigned rounding);
bool isSignalingRounding(unsigned rounding);
const char* samplerAddressing2str(unsigned arg);
const char* samplerCoordNormalization2str(unsigned arg);
const char* samplerFilter2str(unsigned arg);
const char* samplerQuery2str(unsigned arg);
const char* sectionIndex2str(unsigned arg);
const char* segment2str(unsigned arg);
unsigned arrayType2elementType(unsigned type);
bool isArrayType(unsigned type);
unsigned elementType2arrayType(unsigned type);
const char* type2str(unsigned arg);
unsigned getBrigTypeNumBits(unsigned arg);
unsigned getBrigTypeNumBytes(unsigned arg);
const char* type2name(unsigned type);
const char* anyEnum2str( BrigAlignment arg );
const char* anyEnum2str( BrigAllocation arg );
const char* anyEnum2str( BrigAluModifierMask arg );
const char* anyEnum2str( BrigAtomicOperation arg );
const char* anyEnum2str( BrigCompareOperation arg );
const char* anyEnum2str( BrigControlDirective arg );
const char* anyEnum2str( BrigImageChannelOrder arg );
const char* anyEnum2str( BrigImageChannelType arg );
const char* anyEnum2str( BrigImageGeometry arg );
const char* anyEnum2str( BrigImageQuery arg );
const char* anyEnum2str( BrigKind arg );
const char* anyEnum2str( BrigLinkage arg );
const char* anyEnum2str( BrigMachineModel arg );
const char* anyEnum2str( BrigMemoryModifierMask arg );
const char* anyEnum2str( BrigMemoryOrder arg );
const char* anyEnum2str( BrigMemoryScope arg );
const char* anyEnum2str( BrigOpcode arg );
const char* anyEnum2str( BrigPack arg );
const char* anyEnum2str( BrigProfile arg );
const char* anyEnum2str( BrigRegisterKind arg );
const char* anyEnum2str( BrigRound arg );
const char* anyEnum2str( BrigSamplerAddressing arg );
const char* anyEnum2str( BrigSamplerCoordNormalization arg );
const char* anyEnum2str( BrigSamplerFilter arg );
const char* anyEnum2str( BrigSamplerQuery arg );
const char* anyEnum2str( BrigSectionIndex arg );
const char* anyEnum2str( BrigSegCvtModifierMask arg );
const char* anyEnum2str( BrigSegment arg );
const char* anyEnum2str( BrigType arg );
const char* anyEnum2str( BrigWidth arg );
inline ValRef<uint8_t> AluModifier::allBits() { return valRef(&brig()->allBits); }
inline BitValRef<0> AluModifier::ftz() { return bitValRef<0>(&brig()->allBits); }
inline StrRef DirectiveComment::name() { return strRef(&brig()->name); }
inline EnumValRef<BrigControlDirective,uint16_t> DirectiveControl::control() { return enumValRef<BrigControlDirective,uint16_t>(&brig()->control); }
inline ListRef<Operand> DirectiveControl::operands() { return listRef<Operand>(&brig()->operands); }
inline StrRef DirectiveExecutable::name() { return strRef(&brig()->name); }
inline ValRef<uint16_t> DirectiveExecutable::outArgCount() { return valRef(&brig()->outArgCount); }
inline ValRef<uint16_t> DirectiveExecutable::inArgCount() { return valRef(&brig()->inArgCount); }
inline ItemRef<Code> DirectiveExecutable::firstInArg() { return itemRef<Code>(&brig()->firstInArg); }
inline ItemRef<Code> DirectiveExecutable::firstCodeBlockEntry() { return itemRef<Code>(&brig()->firstCodeBlockEntry); }
inline ItemRef<Code> DirectiveExecutable::nextModuleEntry() { return itemRef<Code>(&brig()->nextModuleEntry); }
inline ExecutableModifier DirectiveExecutable::modifier() { return subItem<ExecutableModifier>(&brig()->modifier); }
inline EnumValRef<BrigLinkage,uint8_t> DirectiveExecutable::linkage() { return enumValRef<BrigLinkage,uint8_t>(&brig()->linkage); }
inline StrRef DirectiveExtension::name() { return strRef(&brig()->name); }
inline StrRef DirectiveFbarrier::name() { return strRef(&brig()->name); }
inline VariableModifier DirectiveFbarrier::modifier() { return subItem<VariableModifier>(&brig()->modifier); }
inline EnumValRef<BrigLinkage,uint8_t> DirectiveFbarrier::linkage() { return enumValRef<BrigLinkage,uint8_t>(&brig()->linkage); }
inline StrRef DirectiveLabel::name() { return strRef(&brig()->name); }
inline StrRef DirectiveLoc::filename() { return strRef(&brig()->filename); }
inline ValRef<uint32_t> DirectiveLoc::line() { return valRef(&brig()->line); }
inline ValRef<uint32_t> DirectiveLoc::column() { return valRef(&brig()->column); }
inline StrRef DirectiveModule::name() { return strRef(&brig()->name); }
inline ValRef<uint32_t> DirectiveModule::hsailMajor() { return valRef(&brig()->hsailMajor); }
inline ValRef<uint32_t> DirectiveModule::hsailMinor() { return valRef(&brig()->hsailMinor); }
inline EnumValRef<BrigProfile,uint8_t> DirectiveModule::profile() { return enumValRef<BrigProfile,uint8_t>(&brig()->profile); }
inline EnumValRef<BrigMachineModel,uint8_t> DirectiveModule::machineModel() { return enumValRef<BrigMachineModel,uint8_t>(&brig()->machineModel); }
inline EnumValRef<BrigRound,uint8_t> DirectiveModule::defaultFloatRound() { return enumValRef<BrigRound,uint8_t>(&brig()->defaultFloatRound); }
inline ListRef<Operand> DirectivePragma::operands() { return listRef<Operand>(&brig()->operands); }
inline StrRef DirectiveVariable::name() { return strRef(&brig()->name); }
inline ItemRef<Operand> DirectiveVariable::init() { return itemRef<Operand>(&brig()->init); }
inline EnumValRef<BrigType,uint16_t> DirectiveVariable::type() { return enumValRef<BrigType,uint16_t>(&brig()->type); }
inline bool DirectiveVariable::isArray() { return isArrayType(type()); }
inline unsigned DirectiveVariable::elementType() { return isArray()? arrayType2elementType(type()) : type(); }
inline EnumValRef<BrigSegment,uint8_t> DirectiveVariable::segment() { return enumValRef<BrigSegment,uint8_t>(&brig()->segment); }
inline EnumValRef<BrigAlignment,uint8_t> DirectiveVariable::align() { return enumValRef<BrigAlignment,uint8_t>(&brig()->align); }
inline UInt64 DirectiveVariable::dim() { return subItem<UInt64>(&brig()->dim); }
inline VariableModifier DirectiveVariable::modifier() { return subItem<VariableModifier>(&brig()->modifier); }
inline EnumValRef<BrigLinkage,uint8_t> DirectiveVariable::linkage() { return enumValRef<BrigLinkage,uint8_t>(&brig()->linkage); }
inline EnumValRef<BrigAllocation,uint8_t> DirectiveVariable::allocation() { return enumValRef<BrigAllocation,uint8_t>(&brig()->allocation); }
inline EnumValRef<BrigOpcode,uint16_t> Inst::opcode() { return enumValRef<BrigOpcode,uint16_t>(&brig()->opcode); }
inline EnumValRef<BrigType,uint16_t> Inst::type() { return enumValRef<BrigType,uint16_t>(&brig()->type); }
inline ListRef<Operand> Inst::operands() { return listRef<Operand>(&brig()->operands); }
inline Operand Inst::operand(int index) { return operands()[index]; }
inline EnumValRef<BrigSegment,uint8_t> InstAddr::segment() { return enumValRef<BrigSegment,uint8_t>(&brig()->segment); }
inline EnumValRef<BrigSegment,uint8_t> InstAtomic::segment() { return enumValRef<BrigSegment,uint8_t>(&brig()->segment); }
inline EnumValRef<BrigMemoryOrder,uint8_t> InstAtomic::memoryOrder() { return enumValRef<BrigMemoryOrder,uint8_t>(&brig()->memoryOrder); }
inline EnumValRef<BrigMemoryScope,uint8_t> InstAtomic::memoryScope() { return enumValRef<BrigMemoryScope,uint8_t>(&brig()->memoryScope); }
inline EnumValRef<BrigAtomicOperation,uint8_t> InstAtomic::atomicOperation() { return enumValRef<BrigAtomicOperation,uint8_t>(&brig()->atomicOperation); }
inline ValRef<uint8_t> InstAtomic::equivClass() { return valRef(&brig()->equivClass); }
inline EnumValRef<BrigWidth,uint8_t> InstBr::width() { return enumValRef<BrigWidth,uint8_t>(&brig()->width); }
inline EnumValRef<BrigType,uint16_t> InstCmp::sourceType() { return enumValRef<BrigType,uint16_t>(&brig()->sourceType); }
inline AluModifier InstCmp::modifier() { return subItem<AluModifier>(&brig()->modifier); }
inline EnumValRef<BrigCompareOperation,uint8_t> InstCmp::compare() { return enumValRef<BrigCompareOperation,uint8_t>(&brig()->compare); }
inline EnumValRef<BrigPack,uint8_t> InstCmp::pack() { return enumValRef<BrigPack,uint8_t>(&brig()->pack); }
inline EnumValRef<BrigType,uint16_t> InstCvt::sourceType() { return enumValRef<BrigType,uint16_t>(&brig()->sourceType); }
inline AluModifier InstCvt::modifier() { return subItem<AluModifier>(&brig()->modifier); }
inline EnumValRef<BrigRound,uint8_t> InstCvt::round() { return enumValRef<BrigRound,uint8_t>(&brig()->round); }
inline EnumValRef<BrigType,uint16_t> InstImage::imageType() { return enumValRef<BrigType,uint16_t>(&brig()->imageType); }
inline EnumValRef<BrigType,uint16_t> InstImage::coordType() { return enumValRef<BrigType,uint16_t>(&brig()->coordType); }
inline EnumValRef<BrigImageGeometry,uint8_t> InstImage::geometry() { return enumValRef<BrigImageGeometry,uint8_t>(&brig()->geometry); }
inline ValRef<uint8_t> InstImage::equivClass() { return valRef(&brig()->equivClass); }
inline EnumValRef<BrigType,uint16_t> InstLane::sourceType() { return enumValRef<BrigType,uint16_t>(&brig()->sourceType); }
inline EnumValRef<BrigWidth,uint8_t> InstLane::width() { return enumValRef<BrigWidth,uint8_t>(&brig()->width); }
inline EnumValRef<BrigSegment,uint8_t> InstMem::segment() { return enumValRef<BrigSegment,uint8_t>(&brig()->segment); }
inline EnumValRef<BrigAlignment,uint8_t> InstMem::align() { return enumValRef<BrigAlignment,uint8_t>(&brig()->align); }
inline ValRef<uint8_t> InstMem::equivClass() { return valRef(&brig()->equivClass); }
inline EnumValRef<BrigWidth,uint8_t> InstMem::width() { return enumValRef<BrigWidth,uint8_t>(&brig()->width); }
inline MemoryModifier InstMem::modifier() { return subItem<MemoryModifier>(&brig()->modifier); }
inline EnumValRef<BrigMemoryOrder,uint8_t> InstMemFence::memoryOrder() { return enumValRef<BrigMemoryOrder,uint8_t>(&brig()->memoryOrder); }
inline EnumValRef<BrigMemoryScope,uint8_t> InstMemFence::globalSegmentMemoryScope() { return enumValRef<BrigMemoryScope,uint8_t>(&brig()->globalSegmentMemoryScope); }
inline EnumValRef<BrigMemoryScope,uint8_t> InstMemFence::groupSegmentMemoryScope() { return enumValRef<BrigMemoryScope,uint8_t>(&brig()->groupSegmentMemoryScope); }
inline EnumValRef<BrigMemoryScope,uint8_t> InstMemFence::imageSegmentMemoryScope() { return enumValRef<BrigMemoryScope,uint8_t>(&brig()->imageSegmentMemoryScope); }
inline AluModifier InstMod::modifier() { return subItem<AluModifier>(&brig()->modifier); }
inline EnumValRef<BrigRound,uint8_t> InstMod::round() { return enumValRef<BrigRound,uint8_t>(&brig()->round); }
inline EnumValRef<BrigPack,uint8_t> InstMod::pack() { return enumValRef<BrigPack,uint8_t>(&brig()->pack); }
inline EnumValRef<BrigType,uint16_t> InstQueryImage::imageType() { return enumValRef<BrigType,uint16_t>(&brig()->imageType); }
inline EnumValRef<BrigImageGeometry,uint8_t> InstQueryImage::geometry() { return enumValRef<BrigImageGeometry,uint8_t>(&brig()->geometry); }
inline EnumValRef<BrigImageQuery,uint8_t> InstQueryImage::imageQuery() { return enumValRef<BrigImageQuery,uint8_t>(&brig()->imageQuery); }
inline EnumValRef<BrigSamplerQuery,uint8_t> InstQuerySampler::samplerQuery() { return enumValRef<BrigSamplerQuery,uint8_t>(&brig()->samplerQuery); }
inline EnumValRef<BrigSegment,uint8_t> InstQueue::segment() { return enumValRef<BrigSegment,uint8_t>(&brig()->segment); }
inline EnumValRef<BrigMemoryOrder,uint8_t> InstQueue::memoryOrder() { return enumValRef<BrigMemoryOrder,uint8_t>(&brig()->memoryOrder); }
inline EnumValRef<BrigSegment,uint8_t> InstSeg::segment() { return enumValRef<BrigSegment,uint8_t>(&brig()->segment); }
inline EnumValRef<BrigType,uint16_t> InstSegCvt::sourceType() { return enumValRef<BrigType,uint16_t>(&brig()->sourceType); }
inline EnumValRef<BrigSegment,uint8_t> InstSegCvt::segment() { return enumValRef<BrigSegment,uint8_t>(&brig()->segment); }
inline SegCvtModifier InstSegCvt::modifier() { return subItem<SegCvtModifier>(&brig()->modifier); }
inline EnumValRef<BrigType,uint16_t> InstSignal::signalType() { return enumValRef<BrigType,uint16_t>(&brig()->signalType); }
inline EnumValRef<BrigMemoryOrder,uint8_t> InstSignal::memoryOrder() { return enumValRef<BrigMemoryOrder,uint8_t>(&brig()->memoryOrder); }
inline EnumValRef<BrigAtomicOperation,uint8_t> InstSignal::signalOperation() { return enumValRef<BrigAtomicOperation,uint8_t>(&brig()->signalOperation); }
inline EnumValRef<BrigType,uint16_t> InstSourceType::sourceType() { return enumValRef<BrigType,uint16_t>(&brig()->sourceType); }
inline ValRef<uint8_t> ExecutableModifier::allBits() { return valRef(&brig()->allBits); }
inline BitValRef<0> ExecutableModifier::isDefinition() { return bitValRef<0>(&brig()->allBits); }
inline ValRef<uint8_t> MemoryModifier::allBits() { return valRef(&brig()->allBits); }
inline BitValRef<0> MemoryModifier::isConst() { return bitValRef<0>(&brig()->allBits); }
inline ItemRef<DirectiveVariable> OperandAddress::symbol() { return itemRef<DirectiveVariable>(&brig()->symbol); }
inline ItemRef<OperandRegister> OperandAddress::reg() { return itemRef<OperandRegister>(&brig()->reg); }
inline UInt64 OperandAddress::offset() { return subItem<UInt64>(&brig()->offset); }
inline EnumValRef<BrigAlignment,uint8_t> OperandAlign::align() { return enumValRef<BrigAlignment,uint8_t>(&brig()->align); }
inline ListRef<Code> OperandCodeList::elements() { return listRef<Code>(&brig()->elements); }
inline unsigned OperandCodeList::elementCount() { return elements().size(); }
inline Code OperandCodeList::elements(int index) { return elements()[index]; }
inline ItemRef<Code> OperandCodeRef::ref() { return itemRef<Code>(&brig()->ref); }
inline EnumValRef<BrigType,uint16_t> OperandConstantBytes::type() { return enumValRef<BrigType,uint16_t>(&brig()->type); }
inline StrRef OperandConstantBytes::bytes() { return strRef(&brig()->bytes); }
inline EnumValRef<BrigType,uint16_t> OperandConstantImage::type() { return enumValRef<BrigType,uint16_t>(&brig()->type); }
inline EnumValRef<BrigImageGeometry,uint8_t> OperandConstantImage::geometry() { return enumValRef<BrigImageGeometry,uint8_t>(&brig()->geometry); }
inline EnumValRef<BrigImageChannelOrder,uint8_t> OperandConstantImage::channelOrder() { return enumValRef<BrigImageChannelOrder,uint8_t>(&brig()->channelOrder); }
inline EnumValRef<BrigImageChannelType,uint8_t> OperandConstantImage::channelType() { return enumValRef<BrigImageChannelType,uint8_t>(&brig()->channelType); }
inline UInt64 OperandConstantImage::width() { return subItem<UInt64>(&brig()->width); }
inline UInt64 OperandConstantImage::height() { return subItem<UInt64>(&brig()->height); }
inline UInt64 OperandConstantImage::depth() { return subItem<UInt64>(&brig()->depth); }
inline UInt64 OperandConstantImage::array() { return subItem<UInt64>(&brig()->array); }
inline EnumValRef<BrigType,uint16_t> OperandConstantOperandList::type() { return enumValRef<BrigType,uint16_t>(&brig()->type); }
inline ListRef<Operand> OperandConstantOperandList::elements() { return listRef<Operand>(&brig()->elements); }
inline unsigned OperandConstantOperandList::elementCount() { return elements().size(); }
inline Operand OperandConstantOperandList::elements(int index) { return elements()[index]; }
inline EnumValRef<BrigType,uint16_t> OperandConstantSampler::type() { return enumValRef<BrigType,uint16_t>(&brig()->type); }
inline EnumValRef<BrigSamplerCoordNormalization,uint8_t> OperandConstantSampler::coord() { return enumValRef<BrigSamplerCoordNormalization,uint8_t>(&brig()->coord); }
inline EnumValRef<BrigSamplerFilter,uint8_t> OperandConstantSampler::filter() { return enumValRef<BrigSamplerFilter,uint8_t>(&brig()->filter); }
inline EnumValRef<BrigSamplerAddressing,uint8_t> OperandConstantSampler::addressing() { return enumValRef<BrigSamplerAddressing,uint8_t>(&brig()->addressing); }
inline ListRef<Operand> OperandOperandList::elements() { return listRef<Operand>(&brig()->elements); }
inline unsigned OperandOperandList::elementCount() { return elements().size(); }
inline Operand OperandOperandList::elements(int index) { return elements()[index]; }
inline EnumValRef<BrigRegisterKind,uint16_t> OperandRegister::regKind() { return enumValRef<BrigRegisterKind,uint16_t>(&brig()->regKind); }
inline ValRef<uint16_t> OperandRegister::regNum() { return valRef(&brig()->regNum); }
inline StrRef OperandString::string() { return strRef(&brig()->string); }
inline ValRef<uint8_t> SegCvtModifier::allBits() { return valRef(&brig()->allBits); }
inline BitValRef<0> SegCvtModifier::isNoNull() { return bitValRef<0>(&brig()->allBits); }
inline ValRef<uint32_t> UInt64::lo() { return valRef(&brig()->lo); }
inline ValRef<uint32_t> UInt64::hi() { return valRef(&brig()->hi); }
inline UInt64& UInt64::operator=(uint64_t rhs) { lo() = (uint32_t)rhs; hi() = (uint32_t)(rhs >> 32); return *this; }
inline UInt64::operator uint64_t() { return ((uint64_t)hi()) << 32 | lo(); }
inline ValRef<uint8_t> VariableModifier::allBits() { return valRef(&brig()->allBits); }
inline BitValRef<0> VariableModifier::isDefinition() { return bitValRef<0>(&brig()->allBits); }
inline BitValRef<1> VariableModifier::isConst() { return bitValRef<1>(&brig()->allBits); }
