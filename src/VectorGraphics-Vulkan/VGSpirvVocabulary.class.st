"
I am the vocabulary a hand-built SPIR-V module of this project is written in: one SpvBuilder, the
GLSL.std.450 set imported beside it, and the ids of the values a subclass names as it emits.

My methods are the typed scalars of such a module and nothing more — a 32-bit word, a signed word,
a single float and a boolean — with their arithmetic, their comparisons, the conversions between
them and the five GLSL instructions the core instruction set has none of.
Each answers the result id of one instruction, so a subclass reads as the arithmetic it means
rather than as a sequence of opcodes and type lookups.

A subclass builds the module: it creates the builder, imports the set, declares its own buffers and
variables and emits its own function. VGTiledFillKernel is the one that does, and remember:as: and
valueNamed: are what its deeper emitters read the ids of the pixel and the entry they stand inside
from, instead of taking eight arguments each.
"
Class {
	#name : 'VGSpirvVocabulary',
	#superclass : 'Object',
	#instVars : [
		'builder',
		'glsl',
		'values'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'inspecting' }
VGSpirvVocabulary class >> inspectorVocabulary: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Vocabulary'>
	"The words a hand-built module of this project is written in, by protocol: the scalars and
	 their constants, the arithmetic, the comparisons and the instructions of the imported GLSL
	 set. The table reflects over the class itself, so a word added or dropped shows here
	 without this method being touched."

	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Protocol'
				   evaluated: [ :each | each first ]);
		  addColumn: (SpStringTableColumn
				   title: 'Word'
				   evaluated: [ :each | each second ]);
		  items: self vocabularyRows;
		  yourself
]

{ #category : 'inspecting' }
VGSpirvVocabulary class >> inspectorVocabularyContext: aContext [
	"The vocabulary of the hierarchy is a fact about its root, so the tab stands on this class
	 alone and not on each subclass that writes a module in it."

	aContext active: self superclass = Object
]

{ #category : 'constants' }
VGSpirvVocabulary class >> scalarBitWidth [
	"Every scalar of a module built with this vocabulary is thirty-two bits wide: a word of a
	 buffer, a single float of a coordinate and the signed winding number alike. The vocabulary
	 itself owns the width, because the three type methods below read it and every vocabulary
	 sharing one module must answer the same one."
	^ 32
]

{ #category : 'inspecting' }
VGSpirvVocabulary class >> vocabularyRows [
	"Every word of the vocabulary, read from the class's own methods and grouped by the
	 protocol each is filed under, so the table cannot name an instruction the class has stopped
	 answering."

	^ ((self instanceSide methods collect: [ :each |
		    {
			    each protocolName asString.
			    each selector asString } ]) asSortedCollection: [ :one :other |
		   one first = other first
			   ifTrue: [ one second <= other second ]
			   ifFalse: [ one first <= other first ] ]) asArray
]

{ #category : 'arithmetic' }
VGSpirvVocabulary >> bitsOfSigned: anId and: anotherId [
	^ builder
		  emitBinaryOp: SpvOpcode opBitwiseAnd
		  left: anId
		  right: anotherId
		  type: self signedType
]

{ #category : 'arithmetic' }
VGSpirvVocabulary >> bitsOfWord: anId and: anotherId [
	^ builder
		  emitBinaryOp: SpvOpcode opBitwiseAnd
		  left: anId
		  right: anotherId
		  type: self wordType
]

{ #category : 'types' }
VGSpirvVocabulary >> boolType [
	^ builder types boolType
]

{ #category : 'comparing' }
VGSpirvVocabulary >> both: anId and: anotherId [
	^ builder
		  emitBinaryOp: SpvOpcode opLogicalAnd
		  left: anId
		  right: anotherId
		  type: self boolType
]

{ #category : 'accessing' }
VGSpirvVocabulary >> builder [
	^ builder
]

{ #category : 'extended' }
VGSpirvVocabulary >> ceilingOfFloat: anId [
	^ self
		  extended: GlslStd450 ceil
		  of: { anId }
		  type: self floatType
]

{ #category : 'types' }
VGSpirvVocabulary >> constantFloat: aNumber [
	^ builder constants constantFloat32: aNumber asFloat
]

{ #category : 'types' }
VGSpirvVocabulary >> constantSigned: anInteger [
	^ builder constants constantInt32: anInteger
]

{ #category : 'types' }
VGSpirvVocabulary >> constantWord: anInteger [
	^ builder constants constantUInt32: anInteger
]

{ #category : 'arithmetic' }
VGSpirvVocabulary >> differenceOfFloat: anId and: anotherId [
	^ builder
		  emitBinaryOp: SpvOpcode opFSub
		  left: anId
		  right: anotherId
		  type: self floatType
]

{ #category : 'arithmetic' }
VGSpirvVocabulary >> differenceOfWord: anId and: anotherId [
	^ builder
		  emitBinaryOp: SpvOpcode opISub
		  left: anId
		  right: anotherId
		  type: self wordType
]

{ #category : 'comparing' }
VGSpirvVocabulary >> either: anId or: anotherId [
	^ builder
		  emitBinaryOp: SpvOpcode opLogicalOr
		  left: anId
		  right: anotherId
		  type: self boolType
]

{ #category : 'extended' }
VGSpirvVocabulary >> extended: anInstruction of: anArray type: aType [
	"One instruction of the imported GLSL set, which carries the minima, the floor and the
	 ceiling the core instruction set has none of."

	^ builder
		  emitExtInst: glsl
		  op: anInstruction
		  operands: anArray
		  type: aType
]

{ #category : 'comparing' }
VGSpirvVocabulary >> float: anId above: anotherId [
	^ builder
		  emitBinaryOp: SpvOpcode opFOrdGreaterThan
		  left: anId
		  right: anotherId
		  type: self boolType
]

{ #category : 'comparing' }
VGSpirvVocabulary >> float: anId atLeast: anotherId [
	^ builder
		  emitBinaryOp: SpvOpcode opFOrdGreaterThanEqual
		  left: anId
		  right: anotherId
		  type: self boolType
]

{ #category : 'comparing' }
VGSpirvVocabulary >> float: anId below: anotherId [
	^ builder
		  emitBinaryOp: SpvOpcode opFOrdLessThan
		  left: anId
		  right: anotherId
		  type: self boolType
]

{ #category : 'comparing' }
VGSpirvVocabulary >> float: anId equals: anotherId [
	^ builder
		  emitBinaryOp: SpvOpcode opFOrdEqual
		  left: anId
		  right: anotherId
		  type: self boolType
]

{ #category : 'comparing' }
VGSpirvVocabulary >> float: anId notAbove: anotherId [
	^ builder
		  emitBinaryOp: SpvOpcode opFOrdLessThanEqual
		  left: anId
		  right: anotherId
		  type: self boolType
]

{ #category : 'arithmetic' }
VGSpirvVocabulary >> floatOfWord: anId [
	^ builder
		  emitConvertUToF: anId
		  fromType: self wordType
		  toType: self floatType
]

{ #category : 'types' }
VGSpirvVocabulary >> floatType [
	^ builder types floatType: self class scalarBitWidth
]

{ #category : 'extended' }
VGSpirvVocabulary >> floorOfFloat: anId [
	^ self
		  extended: GlslStd450 floor
		  of: { anId }
		  type: self floatType
]

{ #category : 'accessing' }
VGSpirvVocabulary >> glsl [
	^ glsl
]

{ #category : 'comparing' }
VGSpirvVocabulary >> integer: anId differsFrom: anotherId [
	^ builder
		  emitBinaryOp: SpvOpcode opINotEqual
		  left: anId
		  right: anotherId
		  type: self boolType
]

{ #category : 'comparing' }
VGSpirvVocabulary >> integer: anId equals: anotherId [
	"One instruction serves a word and a signed integer alike, because equality reads the bits."

	^ builder
		  emitBinaryOp: SpvOpcode opIEqual
		  left: anId
		  right: anotherId
		  type: self boolType
]

{ #category : 'extended' }
VGSpirvVocabulary >> largerFloatOf: anId and: anotherId [
	^ self
		  extended: GlslStd450 fMax
		  of: {
				  anId.
				  anotherId }
		  type: self floatType
]

{ #category : 'comparing' }
VGSpirvVocabulary >> negation: anId [
	"The complement of a condition, which is what stands in for the arm emitIf:then: has not
	 got: the condition is computed once and both arms branch on the same value."

	^ builder
		  emitUnaryOp: SpvOpcode opLogicalNot
		  operand: anId
		  type: self boolType
]

{ #category : 'arithmetic' }
VGSpirvVocabulary >> productOfFloat: anId and: anotherId [
	^ builder
		  emitBinaryOp: SpvOpcode opFMul
		  left: anId
		  right: anotherId
		  type: self floatType
]

{ #category : 'arithmetic' }
VGSpirvVocabulary >> productOfWord: anId and: anotherId [
	^ builder
		  emitBinaryOp: SpvOpcode opIMul
		  left: anId
		  right: anotherId
		  type: self wordType
]

{ #category : 'arithmetic' }
VGSpirvVocabulary >> quotientOfFloat: anId by: anotherId [
	^ builder
		  emitBinaryOp: SpvOpcode opFDiv
		  left: anId
		  right: anotherId
		  type: self floatType
]

{ #category : 'private' }
VGSpirvVocabulary >> remember: anId as: aName [
	"The ids of the pixel and of the entry the emission stands inside. The deeper emitters read
	 them from here rather than taking eight arguments each."

	values at: aName put: anId
]

{ #category : 'comparing' }
VGSpirvVocabulary >> select: aConditionId ifTrue: anId ifFalse: anotherId type: aType [
	^ builder
		  emitSelect: aConditionId
		  ifTrue: anId
		  ifFalse: anotherId
		  type: aType
]

{ #category : 'initialization' }
VGSpirvVocabulary >> shareStateWith: aVocabulary [
	"Emit into the module another vocabulary is building, with its GLSL set and its value table.
	 The table is held and not copied, because a value one of us remembers is a value the other
	 reads: the two of us are emitting one function and an identifier means the same thing in
	 both. A vocabulary that shares this way may only emit while the other is emitting, since the
	 builder answers nothing once its module is serialised."
	builder := aVocabulary builder.
	glsl := aVocabulary glsl.
	values := aVocabulary values
]

{ #category : 'types' }
VGSpirvVocabulary >> signedType [
	^ builder types intType: self class scalarBitWidth signed: true
]

{ #category : 'extended' }
VGSpirvVocabulary >> smallerFloatOf: anId and: anotherId [
	^ self
		  extended: GlslStd450 fMin
		  of: {
				  anId.
				  anotherId }
		  type: self floatType
]

{ #category : 'extended' }
VGSpirvVocabulary >> smallerWordOf: anId and: anotherId [
	^ self
		  extended: GlslStd450 uMin
		  of: {
				  anId.
				  anotherId }
		  type: self wordType
]

{ #category : 'arithmetic' }
VGSpirvVocabulary >> squareRootOfFloat: anId [
	"The square root of a float, which the core instruction set has none of. A negative argument
	 answers a NaN rather than raising, so a caller that can reach one selects the result away
	 instead of branching around it."

	^ self
		  extended: GlslStd450 sqrt
		  of: { anId }
		  type: self floatType
]

{ #category : 'arithmetic' }
VGSpirvVocabulary >> sumOfFloat: anId and: anotherId [
	^ builder
		  emitBinaryOp: SpvOpcode opFAdd
		  left: anId
		  right: anotherId
		  type: self floatType
]

{ #category : 'arithmetic' }
VGSpirvVocabulary >> sumOfSigned: anId and: anotherId [
	^ builder
		  emitBinaryOp: SpvOpcode opIAdd
		  left: anId
		  right: anotherId
		  type: self signedType
]

{ #category : 'arithmetic' }
VGSpirvVocabulary >> sumOfWord: anId and: anotherId [
	^ builder
		  emitBinaryOp: SpvOpcode opIAdd
		  left: anId
		  right: anotherId
		  type: self wordType
]

{ #category : 'private' }
VGSpirvVocabulary >> valueNamed: aName [
	^ values at: aName
]

{ #category : 'accessing' }
VGSpirvVocabulary >> values [
	^ values
]

{ #category : 'types' }
VGSpirvVocabulary >> vectorType [
	"The shape of every invocation built-in the kernel reads."

	^ builder types vectorType: self wordType count: 3
]

{ #category : 'comparing' }
VGSpirvVocabulary >> word: anId below: anotherId [
	^ builder
		  emitBinaryOp: SpvOpcode opULessThan
		  left: anId
		  right: anotherId
		  type: self boolType
]

{ #category : 'arithmetic' }
VGSpirvVocabulary >> word: anId dividedBy: anotherId [
	^ builder
		  emitBinaryOp: SpvOpcode opUDiv
		  left: anId
		  right: anotherId
		  type: self wordType
]

{ #category : 'comparing' }
VGSpirvVocabulary >> word: anId equals: anotherId [
	^ self integer: anId equals: anotherId
]

{ #category : 'arithmetic' }
VGSpirvVocabulary >> word: anId shiftedLeftBy: anInteger [
	^ builder
		  emitBinaryOp: SpvOpcode opShiftLeftLogical
		  left: anId
		  right: (self constantWord: anInteger)
		  type: self wordType
]

{ #category : 'arithmetic' }
VGSpirvVocabulary >> word: anId shiftedRightBy: anInteger [
	^ builder
		  emitBinaryOp: SpvOpcode opShiftRightLogical
		  left: anId
		  right: (self constantWord: anInteger)
		  type: self wordType
]

{ #category : 'arithmetic' }
VGSpirvVocabulary >> word: anId shiftedRightByWord: anotherId [
	"The same shift by a width computed on the device rather than written into the module, which
	 is what reading one byte out of a word of a buffer needs: the byte wanted is not known until
	 the invocation knows which pixel it owns."

	^ builder
		  emitBinaryOp: SpvOpcode opShiftRightLogical
		  left: anId
		  right: anotherId
		  type: self wordType
]

{ #category : 'arithmetic' }
VGSpirvVocabulary >> wordOfFloat: anId [
	"A float truncated to an unsigned word. Every value converted here is a coverage or a byte
	 and so never negative."

	^ builder
		  emitUnaryOp: SpvOpcode opConvertFToU
		  operand: anId
		  type: self wordType
]

{ #category : 'types' }
VGSpirvVocabulary >> wordType [
	"The registry deduplicates, so asking it for a type each time it is needed costs one lookup
	 and cannot drift from the type the rest of the module uses."

	^ builder types intType: self class scalarBitWidth signed: false
]
