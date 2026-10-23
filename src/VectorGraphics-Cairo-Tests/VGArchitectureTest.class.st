"
I hold the agreed layering of this project: which package may name a class of which other package.
The table is VGArchitectureTest class >> allowedDependencies, one entry per package, and my tests fail both when a package makes an edge the table does not grant and when the table grants an edge the code no longer makes, so the table cannot drift into a description of the project history.
I also hold the table against the organiser, against BaselineOfVectorGraphics and against a fixture that plants a reference three blocks deep, because a scan that reads only a method own literals misses every reference inside a block.
Two project-wide rules are not mine and stay where they were written: VGBackendSelectionTest holds that only the Vulkan family names a PharoVulkan class, through VGCairoReferenceScanner, and that every package of this project is named in the baseline.
I live in VectorGraphics-Cairo-Tests rather than in a package of my own, since this project has no aggregate test package and a new package would owe the baseline and the profiling stage table an entry for one class.
"
Class {
	#name : 'VGArchitectureTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Cairo-Tests-Tests',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Tests'
}

{ #category : 'layering' }
VGArchitectureTest class >> allowedDependencies [
	"The outgoing package references each package of this project may make, keyed by package
	 name. This table is the agreement: a package missing from it is one nobody has placed in
	 the layering, and an edge missing from a set is a dependency nobody has agreed to. My tests
	 fail on either, so adding a dependency means stating it here and in the baseline first.
	 The rule that only the Vulkan family may name a PharoVulkan class is held elsewhere, by
	 VGBackendSelectionTest through VGCairoReferenceScanner, so no edge out of this project
	 appears here."

	^ Dictionary newFrom: {
			  "The engine is the pure-Pharo rasteriser this project was built on and it knows
			   nothing of the layers above it."
			  'VectorGraphics' -> #(  ).
			  'VectorGraphics-Cairo' -> #( 'VectorGraphics' ).
			  "An examples class names its subject, and the subjects of these three examples
			   holders — the two corpora, the comparison and the font lifetime — live in the test
			   package, because they are fixtures of the conformance gate and of nothing else."
			  'VectorGraphics-Cairo-Examples'
			  -> #( 'VectorGraphics-Cairo' 'VectorGraphics-Cairo-Tests' ).
			  'VectorGraphics-Cairo-Tests'
			  -> #( 'VectorGraphics-Cairo' 'VectorGraphics-Cairo-Examples' ).
			  'VectorGraphics-Bloc' -> #( 'VectorGraphics-Cairo' ).
			  'VectorGraphics-Bloc-Examples'
			  -> #( 'VectorGraphics-Bloc' 'VectorGraphics-Cairo' ).
			  'VectorGraphics-Bloc-Tests'
			  -> #( 'VectorGraphics-Bloc' 'VectorGraphics-Bloc-Examples' 'VectorGraphics-Cairo' ).
			  "The device path reads the frame unit 1.11 profiles, which is drawn through the Bloc
			   renderer, so binning and the budget name that package as well as the display list."
			  'VectorGraphics-Vulkan' -> #( 'VectorGraphics-Bloc' 'VectorGraphics-Cairo' ).
			  'VectorGraphics-Vulkan-Examples'
			  -> #( 'VectorGraphics-Bloc' 'VectorGraphics-Cairo' 'VectorGraphics-Vulkan' ).
			  "The edge to the Cairo tests is the one edge this project allows between two test
			   packages: VGVulkanExamplesTest subclasses VGCairoExamplesTest and the backend tests
			   draw the frame fixture the engine tests draw, rather than keeping a second copy of
			   either."
			  'VectorGraphics-Vulkan-Tests'
			  -> #( 'VectorGraphics-Bloc' 'VectorGraphics-Cairo' 'VectorGraphics-Cairo-Tests'
				    'VectorGraphics-Vulkan' 'VectorGraphics-Vulkan-Examples' ) }
]

{ #category : 'layering' }
VGArchitectureTest class >> dependencyReport [
	"One row per package of this project: its name, the edges allowedDependencies grants it, the
	 edges it really makes, and the edges BaselineOfVectorGraphics declares for it. All four are
	 computed here, so a reader of the report and my tests cannot be looking at different
	 numbers."

	| declared |
	declared := Dictionary new.
	BaselineOfVectorGraphics project version packages do: [ :each |
		declared at: each name put: each requires asSet ].
	^ self projectPackageNames asSortedCollection asArray collect: [ :each |
		  {
			  each.
			  (self packageNameSeparator join:
					   (self allowedDependencies at: each ifAbsent: [ #(  ) ])
						   asSortedCollection).
			  (self packageNameSeparator join: (self edgesOf: each) asSortedCollection).
			  (self packageNameSeparator join:
					   (declared at: each ifAbsent: [ Set new ]) asSortedCollection) } ]
]

{ #category : 'layering' }
VGArchitectureTest class >> edgesOf: aPackageName [
	"The packages aPackageName own methods name, itself excluded. Asking the package for its
	 methods reads its extension methods on base classes too."

	| package found |
	package := PackageOrganizer default packageNamed: aPackageName.
	found := Set new.
	package methods do: [ :method | found addAll: (self packagesNamedBy: method) ].
	^ found copyWithout: aPackageName
]

{ #category : 'layering' }
VGArchitectureTest class >> edgesTheBaselineCannotDeclare [
	"The edges of allowedDependencies that BaselineOfVectorGraphics may not state, because the
	 reverse edge is stated and Metacello loads requires in order: a pair declared both ways is
	 a cycle and no load order exists for it. Only this pair qualifies, and the two packages
	 always load together, so nothing is lost by leaving one half out.
	 Every entry is held by testEveryEdgeTheBaselineCannotDeclareIsOneHalfOfACycle, which reads
	 the reverse from the baseline rather than taking this comment on trust."

	^ {('VectorGraphics-Cairo-Examples' -> 'VectorGraphics-Cairo-Tests')}
]

{ #category : 'inspecting' }
VGArchitectureTest class >> inspectorDependencies: aBuilder [
	"The granted, the real and the declared outgoing edges side by side, for every package of
	 this project. Reads dependencyReport, so the tab states what the table, a live scan and the
	 baseline say rather than a stored summary, and it mutates nothing it shows."

	<inspectorPresentationOrder: 10 title: 'Dependencies'>
	^ aBuilder newTable
		  addColumn: (SpStringTableColumn title: 'Package' evaluated: [ :each | each first ]);
		  addColumn: (SpStringTableColumn title: 'Granted' evaluated: [ :each | each second ]);
		  addColumn: (SpStringTableColumn title: 'Real' evaluated: [ :each | each third ]);
		  addColumn: (SpStringTableColumn title: 'Baseline' evaluated: [ :each | each fourth ]);
		  items: self dependencyReport;
		  yourself
]

{ #category : 'inspecting' }
VGArchitectureTest class >> inspectorDependenciesContext: aContext [
	"The tab belongs to whichever class in this hierarchy holds the table, which today is this
	 one and only one. Asking the table rather than naming the class keeps the gate true if a
	 second project ever subclasses me for its own layering."

	^ aContext active: self allowedDependencies notEmpty
]

{ #category : 'layering' }
VGArchitectureTest class >> packageNameSeparator [
	"What dependencyReport puts between two package names inside one table cell."

	^ ', '
]

{ #category : 'layering' }
VGArchitectureTest class >> packagesNamedBy: aCompiledMethod [
	"The packages of this project whose classes aCompiledMethod names, reading the literals of
	 every block inside it as well as its own, to any depth."

	| found scan |
	found := Set new.
	scan := nil.
	scan := [ :compiled |
	        compiled literals do: [ :literal |
		        literal isVariableBinding
			        ifTrue: [
				        literal value isBehavior ifTrue: [
					        literal value instanceSide package ifNotNil: [ :package |
						        (package name beginsWith: self projectPackageNamePrefix)
							        ifTrue: [ found add: package name asString ] ] ] ]
			        ifFalse: [
				        literal class = CompiledBlock ifTrue: [ scan value: literal ] ] ] ].
	scan value: aCompiledMethod.
	^ found
]

{ #category : 'layering' }
VGArchitectureTest class >> projectPackageNamePrefix [
	"Every package of this project begins with this. BaselineOfVectorGraphics does not, which is
	 why the baseline is read through its own class and not found by this prefix."

	^ 'VectorGraphics'
]

{ #category : 'layering' }
VGArchitectureTest class >> projectPackageNames [
	"Every package of this project, asked of the organiser so that a package added tomorrow is
	 covered by the coverage test rather than by a list written out by hand."

	^ ((PackageOrganizer default packages select: [ :each |
		    each name beginsWith: self projectPackageNamePrefix ]) collect: [ :each |
		   each name asString ]) asSet
]

{ #category : 'running' }
VGArchitectureTest >> assertEdgesOfPackageNamed: aPackageName [
	"Fail naming every method that makes a reference allowedDependencies does not grant. A bare
	 package name would say that the layering broke without saying where to look for it. The
	 class name is asked for as a string, because a symbol would carry its quoting into the
	 failure message."

	| allowed strays |
	allowed := (self class allowedDependencies at: aPackageName ifAbsent: [ #(  ) ]) asSet.
	strays := Set new.
	(PackageOrganizer default packageNamed: aPackageName) methods do: [ :method |
		((self class packagesNamedBy: method) copyWithout: aPackageName) do: [ :each |
			(allowed includes: each) ifFalse: [
				strays add: method methodClass name asString , ' >> '
					, method selector asString , ' -> ' , each ] ] ].
	self assert: strays asSortedCollection asArray equals: #(  )
]

{ #category : 'tests' }
VGArchitectureTest >> testBlocExamplesStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Bloc-Examples'
]

{ #category : 'tests' }
VGArchitectureTest >> testBlocStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Bloc'
]

{ #category : 'tests' }
VGArchitectureTest >> testBlocTestsStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Bloc-Tests'
]

{ #category : 'tests' }
VGArchitectureTest >> testCairoExamplesStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Cairo-Examples'
]

{ #category : 'tests' }
VGArchitectureTest >> testCairoStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Cairo'
]

{ #category : 'tests' }
VGArchitectureTest >> testCairoTestsStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Cairo-Tests'
]

{ #category : 'tests' }
VGArchitectureTest >> testEveryAllowedDependencyIsDeclaredInTheBaseline [
	"A package can load only what the baseline says it needs. An edge the table grants but the
	 baseline leaves out works in this image, where every package is present already, and fails
	 for whoever loads the project one group at a time. The edges of
	 edgesTheBaselineCannotDeclare are left out here and held by their own test."

	| declared missing |
	declared := Dictionary new.
	BaselineOfVectorGraphics project version packages do: [ :each |
		declared at: each name put: each requires asSet ].
	missing := Set new.
	self class allowedDependencies keysAndValuesDo: [ :package :allowed |
		allowed do: [ :each |
			((self class edgesTheBaselineCannotDeclare includes: package -> each) or: [
				 (declared at: package ifAbsent: [ Set new ]) includes: each ]) ifFalse: [
				missing add: package , ' -> ' , each ] ] ].
	self assert: missing asSortedCollection asArray equals: #(  )
]

{ #category : 'tests' }
VGArchitectureTest >> testEveryAllowedDependencyIsOneThePackageReallyMakes [
	"A dependency that stopped being real has to come out of the table, or the table stops
	 describing the code and starts describing its history."

	| stale |
	stale := Set new.
	self class allowedDependencies keysAndValuesDo: [ :package :allowed |
		| actual |
		actual := self class edgesOf: package.
		allowed do: [ :each |
			(actual includes: each) ifFalse: [ stale add: package , ' -> ' , each ] ] ].
	self assert: stale asSortedCollection asArray equals: #(  )
]

{ #category : 'tests' }
VGArchitectureTest >> testEveryAllowedDependencyNamesAPackageOfThisProject [
	"A renamed package leaves its old name behind in the table, where it would silently grant
	 nothing and hide the edge that replaced it."

	| strays |
	strays := Set new.
	self class allowedDependencies keysAndValuesDo: [ :package :allowed |
		allowed do: [ :each |
			(self class projectPackageNames includes: each) ifFalse: [
				strays add: package , ' -> ' , each ] ] ].
	self assert: strays asSortedCollection asArray equals: #(  )
]

{ #category : 'tests' }
VGArchitectureTest >> testEveryEdgeTheBaselineCannotDeclareIsOneHalfOfACycle [
	"The exemption is not a place for an edge somebody forgot to declare. An edge belongs there
	 only because its reverse is declared, which is what makes the pair a cycle no baseline can
	 state, and the reverse is read from the baseline rather than asserted here."

	| declared wrong |
	declared := Dictionary new.
	BaselineOfVectorGraphics project version packages do: [ :each |
		declared at: each name put: each requires asSet ].
	wrong := Set new.
	self class edgesTheBaselineCannotDeclare do: [ :edge |
		((declared at: edge value ifAbsent: [ Set new ]) includes: edge key) ifFalse: [
			wrong add: edge key , ' -> ' , edge value ] ].
	self assert: wrong asSortedCollection asArray equals: #(  )
]

{ #category : 'tests' }
VGArchitectureTest >> testEveryPackageOfThisProjectHasADeclaredAllowedSet [
	"A package added tomorrow goes unscanned until it appears in the table, so the table is
	 checked against the organiser rather than against a list written out by hand."

	self
		assert: self class allowedDependencies keys asSortedCollection asArray
		equals: self class projectPackageNames asSortedCollection asArray
]

{ #category : 'tests' }
VGArchitectureTest >> testTheEngineStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics'
]

{ #category : 'tests' }
VGArchitectureTest >> testTheScanReadsAReferencePlantedInsideANestedBlock [
	"The scan must read the literals of every block inside a method, at any depth. Most of this
	 project draws inside a block — a display list entry is replayed from one, a conformance case
	 is a draw block — so a scan of a method own literals alone would pass exactly the code it is
	 meant to watch. VGNestedBlockReferenceFixture names VGCairoMatrix three blocks deep and
	 nowhere else."

	self
		assert: (self class packagesNamedBy:
				 VGNestedBlockReferenceFixture >> #reachThroughThreeBlocks)
		equals: (Set with: VGCairoMatrix package name asString)
]

{ #category : 'tests' }
VGArchitectureTest >> testVulkanExamplesStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Vulkan-Examples'
]

{ #category : 'tests' }
VGArchitectureTest >> testVulkanStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Vulkan'
]

{ #category : 'tests' }
VGArchitectureTest >> testVulkanTestsStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Vulkan-Tests'
]
