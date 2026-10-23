"
I hold the facts about the SPIR-V module of the tiled fill rasteriser: what the kernel of
VGTiledFillKernel emits, what VGTiledFillPixelEmitter emits into that same module, and what
neither of them may name.

My tests read the module and the two classes, and draw nothing at all, so they run on a machine
with no driver. The tests that draw pixels, through the device or through the software backend,
live in VGTiledFillTest, which is why the two classes are separate: a fact about the emitted words
is checked by reading the words, and a fact about a frame is checked by comparing pixels.
"
Class {
	#name : 'VGTiledFillKernelTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'private' }
VGTiledFillKernelTest >> classesNamedBy: aMethod [
	"Every class that method names, read from its literals, so a rule about what a method may
	 name is checked against the compiled method and not against its text."

	^ (aMethod literals
		   select: [ :each |
		   each isVariableBinding and: [ each value isBehavior ] ])
		  collect: [ :each | each value ]
]

{ #category : 'private' }
VGTiledFillKernelTest >> kernelDecorationLiterals: aDecoration [
	"Every literal that decoration carries in the kernel's module, read from the module's own
	 decoration instructions and not from the bytes."

	^ ((VGTiledFillKernel default module decorations select: [ :each |
		    (each first = #decorate and: [ each third = aDecoration ]) ]) collect: [
		   :each | each fourth ]) flattened
]

{ #category : 'private' }
VGTiledFillKernelTest >> kernelValidator [
	"The kernel of the default grid, read by the one tool that knows what a module may be."

	^ PVSpirvValidator on: VGTiledFillKernel default spirv
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testAPixelEmitterSharesTheModuleOfTheKernelThatBuildsIt [
	"The emitter is a second vocabulary of one module: the builder it emits into and the value
	 table it reads are the kernel's own objects and not copies of them, because an identifier
	 the kernel remembers is an identifier the emitter uses and the two of them are emitting one
	 function."
	| kernel emitter |
	kernel := VGTiledFillKernel default.
	kernel spirv.
	emitter := VGTiledFillPixelEmitter on: kernel.
	self assert: emitter kernel identicalTo: kernel.
	self assert: emitter builder identicalTo: kernel builder.
	self assert: emitter values identicalTo: kernel values.
	self
		assert: (emitter valueNamed: #alphaByte)
		equals: (kernel valueNamed: #alphaByte)
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testEveryCompositionSelectorOfThePixelEmitterIsAMethodOfItsOwn [
	"The table names arithmetic by selector, so a selector in it that the emitter does not
	 implement is a frame that fails while its module is built. The table is held to the class
	 rather than to a list written twice."
	VGTiledFillPixelEmitter compositionSelectors keysAndValuesDo: [
		:name
		:selector |
		self
			assert: (VGTiledFillPixelEmitter includesSelector: selector)
			description: name ]
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testTheKernelBindsOneBufferForEveryBufferItReads [
	"The seven buffers of the binding contract: the five VGTiledFillEncoding writes, the target
	 pixels and the size of the frame. They stand at one descriptor set, numbered from zero in
	 the order bindingNames holds them."

	self
		assert: (self kernelValidator variableIdsInStorageClass:
				 SpvStorageClass storageBuffer) size
		equals: VGTiledFillKernel bindingNames size.
	self
		assert:
		(self kernelDecorationLiterals: SpvDecoration bindingDecoration)
			asSortedCollection asArray
		equals: (0 to: VGTiledFillKernel bindingNames size - 1) asArray.
	self
		assert: (self kernelDecorationLiterals: SpvDecoration descriptorSet) asSet
		equals: { VGTiledFillKernel descriptorSetIndex } asSet
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testTheKernelModuleIsValidSpirv [
	"The whole walk, assembled by hand: the block order, the merge instruction of every loop
	 and the function variables that stand where VGTileCoverage answers early. spirv-val reads
	 all of it, and a driver refuses what it refuses."

	| validator |
	PVSpirvValidator isAvailable ifFalse: [ ^ self skip ].
	validator := self kernelValidator.
	self
		assert: validator isValid
		description: 'the tiled fill kernel produced invalid SPIR-V: '
			, validator validationOutput
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testTheKernelNamesEveryBufferAndBuiltInInItsInterface [
	"Under SPIR-V 1.5 an entry point names every module-scope variable it touches, so a buffer
	 or a built-in left out of the interface is a module a driver may refuse."

	self
		assert: self kernelValidator entryPointInterfaceIds size
		equals: VGTiledFillKernel bindingNames size
			+ VGTiledFillKernel builtInNumbers size
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testTheKernelNamesNoOpcodeWhereItEmits [
	"Every instruction of the kernel comes out of the vocabulary it is written in, so nothing
	 that emits names an opcode at all: one written in the walk would be an instruction whose
	 type and arithmetic no other reader of that vocabulary could hold to. The inspecting
	 methods are left out, because they count opcodes in a module already built instead of
	 adding any."

	self assert: (VGTiledFillKernel inheritsFrom: VGSpirvVocabulary).
	VGTiledFillKernel methods , VGTiledFillKernel class methods do: [ :each |
		each protocolName = #inspecting ifFalse: [
			self
				deny: ((self classesNamedBy: each) includes: SpvOpcode)
				description: each printString , ' names an opcode' ] ]
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testTheKernelReadsTheTileFromTheWorkgroupAndThePixelFromTheInvocation [
	"Two built-ins and no more: which tile this workgroup owns and which pixel of that tile
	 this invocation owns. Nothing reads the global invocation id, because a tile is addressed
	 by its record in the table and not by its place in the dispatch."

	self
		assert: self kernelValidator builtInsFromWords asSet
		equals: (VGTiledFillKernel builtInNumbers collect: [ :each |
				 PVSpirvValidator builtInNameFor: each ]) asSet
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testTheKernelRefusesAnOperatorWithNoArithmeticOfItsOwn [
	"Every operator of the rasteriser's subset has its own mix of source, mask and destination
	 in the pixel emitter. One added to the subset without arithmetic there is refused while the
	 module is built, so no frame is drawn by a branch that composites nothing."
	VGTiledFillRasteriser supportedOperators do: [ :each |
		self assert:
			(VGTiledFillPixelEmitter compositionSelectorFor: each) isSymbol ].
	self
		should: [
		VGTiledFillPixelEmitter compositionSelectorFor: VGCairoOperator add ]
		raise: Error
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testTheKernelSharesNothingAndSynchronisesNothing [
	"A pixel belongs to one invocation alone: the kernel declares no workgroup storage and
	 holds no barrier, which is what lets the tiles be dispatched in any order at all."

	| validator |
	validator := self kernelValidator.
	self assert:
		(validator variableIdsInStorageClass: SpvStorageClass workgroup) isEmpty.
	self
		assert: (validator countOfOpcode: SpvOpcode opControlBarrier)
		equals: 0
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testTheVocabularyNamesNothingOfThisRasteriser [
	"The vocabulary is the SPIR-V a hand-built module is written in and nothing of this
	 rasteriser: a layout, a constant or a format named there would be a fact kept in two
	 places, and the kernel is where the facts of the tiled fill belong."

	VGSpirvVocabulary methods , VGSpirvVocabulary class methods do: [ :each |
		(self classesNamedBy: each) do: [ :class |
			self
				deny: (class name beginsWith: 'VG')
				description: each printString , ' names ' , class name ] ]
]
