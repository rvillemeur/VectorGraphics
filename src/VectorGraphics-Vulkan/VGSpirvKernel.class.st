"
I am the plumbing every hand-built compute kernel of this engine shares.

A kernel of this engine is one entry point over a set of storage buffers at one descriptor set, numbered by their position in `bindingNames`, reading a few built-ins and keeping its working values in function variables named by `variableNames`. I declare all of that, assemble the module and serialise it; what a kernel computes is `emitBody`, and the shape of its workgroup is `localSize`.

My subclasses are VGTiledFillKernel, which draws a tile of a frame, and VGBlurBoxKernel, which runs one box pass of a Gaussian blur. I name nothing of either: a layout, a format or a constant of one of them kept here would be a fact held in two places.

Key methods: `spirv`, `module`, `emitBody`, `localSize`, `bindingNames`, `variableNames`, `freshKernel`.
"
Class {
	#name : 'VGSpirvKernel',
	#superclass : 'VGSpirvVocabulary',
	#instVars : [
		'bindings',
		'builtIns',
		'variables',
		'spirvModule',
		'spirv'
	],
	#category : 'VectorGraphics-Vulkan-Kernels',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Kernels'
}

{ #category : 'constants' }
VGSpirvKernel class >> bindingNames [
	"The buffers I read, in the order they are bound: the position of a name here, counted from
	 zero, is the binding number, so one list states the whole contract."

	^ self subclassResponsibility
]

{ #category : 'constants' }
VGSpirvKernel class >> builtInNumbers [
	"The built-ins I read, kept by their own number so that a reader of the module and a reader
	 of the class name the same thing."

	^ self subclassResponsibility
]

{ #category : 'module cache' }
VGSpirvKernel class >> clearSpirvCache [
	"Forget every module built so far. A kernel caches the bytes it emits, keyed by whatever its
	 shape varies by, and a subclass says what that is. The cache is a saving and never a decision,
	 so what is built next is byte for byte what was forgotten."

	^ self subclassResponsibility
]

{ #category : 'constants' }
VGSpirvKernel class >> columnComponent [
	"The component of the local invocation id that carries the column of the pixel inside the
	 tile."

	^ 0
]

{ #category : 'constants' }
VGSpirvKernel class >> descriptorSetIndex [
	"All seven buffers stand at one descriptor set, so one set is bound once a frame."

	^ 0
]

{ #category : 'constants' }
VGSpirvKernel class >> elementStride [
	"The bytes one element of a buffer takes, which is what the array stride decoration wants."

	^ self scalarBitWidth // 8
]

{ #category : 'constants' }
VGSpirvKernel class >> entryPointName [
	"The name every compute entry point of this engine carries, and the one the shader module
	 is asked for."

	^ 'main'
]

{ #category : 'constants' }
VGSpirvKernel class >> floatBindingNames [
	"The buffers whose elements are floats. Most kernels read words alone."

	^ #( )
]

{ #category : 'constants' }
VGSpirvKernel class >> floatVariableNames [
	"The function variables that hold a float. Most kernels have none."

	^ #( )
]

{ #category : 'constants' }
VGSpirvKernel class >> layerCount [
	"One layer: a tile is two dimensional, so the third dimension of the workgroup holds one
	 invocation."

	^ 1
]

{ #category : 'constants' }
VGSpirvKernel class >> rowComponent [
	^ 1
]

{ #category : 'constants' }
VGSpirvKernel class >> shaderCapability [
	"The serialiser maps this symbol to the Shader capability number, so the module names the
	 capability rather than repeating its value."

	^ #Shader
]

{ #category : 'constants' }
VGSpirvKernel class >> signedVariableNames [
	"The function variables that hold a signed integer. Most kernels have none."

	^ #( )
]

{ #category : 'constants' }
VGSpirvKernel class >> variableNames [
	"Every value the walk keeps between instructions, in the order it is declared."

	^ self wordVariableNames , self signedVariableNames , self floatVariableNames
]

{ #category : 'constants' }
VGSpirvKernel class >> wordVariableNames [
	"The function variables that hold a word."

	^ self subclassResponsibility
]

{ #category : 'inspecting' }
VGSpirvKernel >> bindingRows [
	"The binding contract as the kernel itself declares it: the position of a name in
	 bindingNames is its binding number, and floatBindingNames says which of them carry
	 coordinates."

	^ self class bindingNames withIndexCollect: [ :each :index |
		  {
			  (index - 1) printString.
			  each asString.
			  ((self class floatBindingNames includes: each)
				   ifTrue: [ 'f32' ]
				   ifFalse: [ 'u32' ]) } ]
]

{ #category : 'building' }
VGSpirvKernel >> buildModule [
	"Assemble the module. The built-ins, the buffers and the workgroup storage are declared
	 before the function, because a definition has to precede every use of its id, and the GLSL
	 set is imported because the walk takes a floor, a ceiling and three minima the core
	 instruction set has none of."

	builder := SpvBuilder new.
	builder addCapability: self class shaderCapability.
	self declareBuiltIns.
	self declareBuffers.
	self declareSharedStorage.
	glsl := builder importGLSL.
	values := Dictionary new.
	self emitMain.
	^ builder module
]

{ #category : 'private' }
VGSpirvKernel >> componentOfBuiltIn: aBuiltIn at: anInteger [
	^ builder
		  emitCompositeExtract:
		  (builder emitLoad: (builtIns at: aBuiltIn) id type: self vectorType)
		  type: self wordType
		  indices: { anInteger }
]

{ #category : 'building' }
VGSpirvKernel >> declareBuffers [
	"One variable per binding, numbered by its position in the contract. Two element types serve
	 all of them and the registry answers one array and one structure for each, so the stride and
	 the block decoration are written once per type and never twice."

	| pointerTypes |
	bindings := Dictionary new.
	pointerTypes := Dictionary new.
	self class bindingNames withIndexDo: [ :each :index |
		| element |
		element := self elementTypeOf: each.
		bindings
			at: each
			put: (self
					 newBufferVariableOfType:
					 (pointerTypes
						  at: element
						  ifAbsentPut: [ self newBufferPointerTypeOfElement: element ])
					 binding: index - 1) ]
]

{ #category : 'building' }
VGSpirvKernel >> declareBuiltIns [
	"The built-ins are kept by their own number, so a reader of the module and a reader of this
	 class name the same thing."

	builtIns := Dictionary new.
	self class builtInNumbers do: [ :each |
		builtIns at: each put: (self newBuiltInVariableOf: each) ]
]

{ #category : 'building' }
VGSpirvKernel >> declareFunctionVariables [
	"Every value the walk keeps between instructions, declared once in the function's first
	 block. SPIR-V has no early answer out of a loop, so each nil VGTileCoverage answers and
	 each loop it leaves early is carried here as a flag beside the value it guards."

	variables := Dictionary new.
	self class variableNames do: [ :each |
		variables
			at: each
			put: (builder emitVariableOfType: (self typeOfVariableNamed: each)) ]
]

{ #category : 'building' }
VGSpirvKernel >> declareSharedStorage [
	"The blocks of workgroup storage this kernel shares between the invocations of a workgroup,
	 declared with the buffers because a module-scope variable has to precede every use of it.
	 A kernel that shares nothing declares nothing."

	
]

{ #category : 'buffers' }
VGSpirvKernel >> elementOf: aBindingName at: anIndexId [
	^ builder
		  emitLoad: (self pointerTo: aBindingName at: anIndexId)
		  type: (self elementTypeOf: aBindingName)
]

{ #category : 'buffers' }
VGSpirvKernel >> elementOf: aBindingName atBase: aBaseId field: anInteger [
	"Fields count from one and a buffer is indexed from zero, so the word of a field sits one
	 before its number."

	^ self
		  elementOf: aBindingName
		  at: (self
				   sumOfWord: aBaseId
				   and: (self constantWord: anInteger - 1))
]

{ #category : 'private' }
VGSpirvKernel >> elementTypeOf: aBindingName [
	^ (self class floatBindingNames includes: aBindingName)
		  ifTrue: [ self floatType ]
		  ifFalse: [ self wordType ]
]

{ #category : 'emitting' }
VGSpirvKernel >> emitBody [
	"What this kernel computes, emitted into the entry point's first block."

	^ self subclassResponsibility
]

{ #category : 'building' }
VGSpirvKernel >> emitMain [
	"The entry point: its variables, its interface, the shape of its workgroup and the one
	 pixel it draws."

	| function |
	function := builder newFunction: builder types voidType.
	builder currentBlock: function addBlock.
	self declareFunctionVariables.
	builder
		addEntryPoint: function
		executionModel: SpvExecutionModel glCompute
		name: self class entryPointName
		interfaces: self interfaceVariables.
	builder
		addExecutionMode: function
		mode: SpvExecutionMode localSize
		literals: self localSize.
	self emitBody.
	builder emitReturn
]

{ #category : 'building' }
VGSpirvKernel >> freshKernel [
	"A kernel of my own kind, built from nothing I hold, which is what a view reads a module
	 from: building one leaves the object inspected holding a module it did not hold before."

	^ self subclassResponsibility
]

{ #category : 'inspector' }
VGSpirvKernel >> inspectorBindings: aBuilder [
	<inspectorPresentationOrder: 11 title: 'Bindings'>
	"The buffers of my one descriptor set, each with the number it is bound at and the width of its
	 own element."

	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Binding'
				   evaluated: [ :each | each first ]);
		  addColumn: (SpStringTableColumn
				   title: 'Buffer'
				   evaluated: [ :each | each second ]);
		  addColumn: (SpStringTableColumn
				   title: 'Element'
				   evaluated: [ :each | each third ]);
		  items: self bindingRows;
		  yourself
]

{ #category : 'inspecting' }
VGSpirvKernel >> inspectorBindingsContext: aContext [
	aContext active: self isReadyToBuild
]

{ #category : 'inspecting' }
VGSpirvKernel >> inspectorModule: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Module'>
	"What the module a dispatch would be given really holds: the shape of its workgroup, the
	 buffers and built-ins it names, and the two counts that state the rule of this kernel —
	 nothing shared and nothing synchronised."

	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Fact'
				   evaluated: [ :each | each first ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each second ]);
		  items: self moduleRows;
		  yourself
]

{ #category : 'inspecting' }
VGSpirvKernel >> inspectorModuleContext: aContext [
	aContext active: self isReadyToBuild
]

{ #category : 'building' }
VGSpirvKernel >> interfaceVariables [
	"Under SPIR-V 1.5 an entry point names every module-scope variable it touches, so a buffer,
	 a built-in or a block of workgroup storage left out of this list is a module a driver may
	 refuse."

	^ (self class builtInNumbers collect: [ :each | builtIns at: each ])
	  , (self class bindingNames collect: [ :each | bindings at: each ])
	  , self sharedVariables
]

{ #category : 'testing' }
VGSpirvKernel >> isReadyToBuild [
	"Whether I hold what a module needs. A kernel whose shape is given after it is created
	 answers false until it has it, and a view of its module is inactive until then."

	^ true
]

{ #category : 'private' }
VGSpirvKernel >> load: aName [
	^ builder
		  emitLoad: (variables at: aName)
		  type: (self typeOfVariableNamed: aName)
]

{ #category : 'accessing' }
VGSpirvKernel >> localSize [
	"The three dimensions of my workgroup, as the execution mode literal wants them."

	^ self subclassResponsibility
]

{ #category : 'accessing' }
VGSpirvKernel >> module [
	"What I build, built once per instance: the build allocates result ids from one counter, so
	 it is a fresh builder each time or nothing."

	^ spirvModule ifNil: [ spirvModule := self buildModule ]
]

{ #category : 'inspecting' }
VGSpirvKernel >> moduleRows [
	"What the emitted bytes say about themselves, read by the validator and not by this class,
	 so a view of them cannot restate a fact the module has stopped carrying. The kernel is
	 built afresh here, because a view may not leave the object it shows holding a module it
	 did not hold before."

	| fresh validator |
	fresh := self freshKernel.
	validator := PVSpirvValidator on: fresh spirv.
	^ {
		  { 'Bytes'. fresh spirv size printString }.
		  { 'Workgroup'. validator localSizeFromWords printString }.
		  { 'Built-ins'. (', ' join: validator builtInsFromWords) }.
		  { 'Storage buffers'.
		  (validator variableIdsInStorageClass: SpvStorageClass storageBuffer) size
			  printString }.
		  { 'Entry point interface'.
		  validator entryPointInterfaceIds size printString }.
		  { 'Workgroup storage'.
		  (validator variableIdsInStorageClass: SpvStorageClass workgroup) size
			  printString }.
		  { 'Barriers'.
		  (validator countOfOpcode: SpvOpcode opControlBarrier) printString }.
		  { 'Loops'.
		  (validator countOfOpcode: SpvOpcode opLoopMerge) printString }.
		  { 'Selections'.
		  (validator countOfOpcode: SpvOpcode opSelectionMerge) printString }.
		  { 'spirv-val'.
		  (PVSpirvValidator isAvailable
			   ifTrue: [
				   validator isValid
					   ifTrue: [ 'valid' ]
					   ifFalse: [ validator validationOutput ] ]
			   ifFalse: [ 'not installed' ]) } }
]

{ #category : 'building' }
VGSpirvKernel >> newBufferPointerTypeOfElement: anElementType [
	"One runtime array of that element inside one structure, which is what a storage buffer
	 binding looks like. The stride belongs to the array type and the offset to the member:
	 spirv-val refuses a stride on a structure member."

	| array structure |
	array := builder types runtimeArrayType: anElementType.
	structure := builder types structType: { array }.
	builder
		addDecoration: array id
		decoration: SpvDecoration arrayStride
		literals: { self class elementStride }.
	builder
		addDecoration: structure id
		decoration: SpvDecoration block
		literals: #( ).
	builder
		addMemberDecoration: structure id
		member: PVSPIRVEmitter bufferMemberIndex
		decoration: SpvDecoration offset
		literals: { PVSPIRVEmitter bufferMemberOffset }.
	^ builder types
		  pointerType: SpvStorageClass storageBuffer
		  type: structure
]

{ #category : 'building' }
VGSpirvKernel >> newBufferVariableOfType: aPointerType binding: anInteger [
	| variable |
	variable := builder
		            addGlobalVariable: aPointerType
		            storageClass: SpvStorageClass storageBuffer.
	builder
		addDecoration: variable id
		decoration: SpvDecoration descriptorSet
		literals: { self class descriptorSetIndex }.
	builder
		addDecoration: variable id
		decoration: SpvDecoration bindingDecoration
		literals: { anInteger }.
	^ variable
]

{ #category : 'building' }
VGSpirvKernel >> newBuiltInVariableOf: aBuiltIn [
	| variable |
	variable := builder
		            addGlobalVariable:
		            (builder types
			             pointerType: SpvStorageClass input
			             type: self vectorType)
		            storageClass: SpvStorageClass input.
	builder
		addDecoration: variable id
		decoration: SpvDecoration builtIn
		literals: { aBuiltIn }.
	^ variable
]

{ #category : 'buffers' }
VGSpirvKernel >> pointerTo: aBindingName at: anIndexId [
	"A pointer to one element of that buffer's runtime array: the structure's one member, then
	 the element inside it."

	^ builder
		  emitAccessChain: (bindings at: aBindingName) id
		  type: (builder types
				   pointerType: SpvStorageClass storageBuffer
				   type: (self elementTypeOf: aBindingName))
		  indices: {
				  (self constantWord: PVSPIRVEmitter bufferMemberIndex).
				  anIndexId }
]

{ #category : 'building' }
VGSpirvKernel >> sharedVariables [
	"The workgroup-storage variables this kernel declared, which the entry point has to name
	 beside its buffers and its built-ins."

	^ #( )
]

{ #category : 'accessing' }
VGSpirvKernel >> spirv [
	"The bytes of my module, which is what a shader module is created from."

	^ spirv ifNil: [ spirv := self module serialize ]
]

{ #category : 'private' }
VGSpirvKernel >> store: anId into: aName [
	builder emitStore: anId at: (variables at: aName)
]

{ #category : 'buffers' }
VGSpirvKernel >> storeWord: aValueId into: aBindingName at: anIndexId [
	builder
		emitStore: aValueId
		at: (self pointerTo: aBindingName at: anIndexId)
]

{ #category : 'private' }
VGSpirvKernel >> typeOfVariableNamed: aName [
	(self class signedVariableNames includes: aName) ifTrue: [
		^ self signedType ].
	(self class floatVariableNames includes: aName) ifTrue: [ ^ self floatType ].
	^ self wordType
]
