"
I hold the agreed layering of this project: which package may name a class of which other package, and which packages each group of the baseline loads.

The table is VGArchitectureTest class >> allowedDependencies, one entry per package, and my tests fail both when a package makes an edge the table does not grant and when the table grants an edge the code no longer makes, so the table cannot drift into a description of the project history.

I also hold the table against the organiser, against BaselineOfVectorGraphics and against a fixture that plants a reference three blocks deep, because a scan that reads only a method own literals misses every reference inside a block.

The second fact is mine since the renderer left the default group: no package the default group loads may name a class of Bloc or of Alexandrie and no class of those packages may inherit from one, so this project rasterises in an image where neither is present. The bloc group loads everything the default group loads plus the renderer, so using it as Alexandrie's replacement inside Bloc stays one Metacello load, and the cairo-examples and cairo-tests groups load without Bloc as well — of Alexandrie they are allowed, because the conformance gate compares this rasteriser with live Cairo and a comparison needs that positive control. Each test asks the same question of a group that must answer yes, so an empty answer cannot come from a walk that finds nothing at all. My class-side Groups tab shows every group live, and VGArchitectureTest class >> replacedStackPackageNames and >> blocPackageNames read the stack from the organiser by prefix.

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

{ #category : 'accessing' }
VGArchitectureTest class >> allowedDependencies [
	"The outgoing package references each package of this project may make, keyed by package
	 name. This table is the agreement: a package missing from it is one nobody has placed in
	 the layering, and an edge missing from a set is a dependency nobody has agreed to. My tests
	 fail on either, so adding a dependency means stating it here and in the baseline first.
	 The rule that only the Vulkan family may name a PharoVulkan class is held elsewhere, by
	 VGBackendSelectionTest through VGCairoReferenceScanner, so no edge out of this project
	 appears here.
	 An edge is a reference one package's methods make to another's classes, which is not the
	 same as what a package needs in order to load: the four documentation gates subclass
	 VectorGraphicsDocumentationTest without naming it in a method, so the baseline declares
	 that edge and this table cannot."

	^ Dictionary newFrom: {
			  "The front page holds no code since the split, only the package comment that says
			   which package holds what, so it names nothing and nothing names it."
			  'VectorGraphics' -> #(  ).
			  "The rasteriser, in four packages. Paths is the command language, Engine the
			   scan-line rasteriser, TrueType the font reader, Text the glue that lets the one
			   draw the other: no edge runs from Engine to TrueType or back, which is what the
			   split was for."
			  'VectorGraphics-Paths' -> #(  ).
			  'VectorGraphics-Paths-Examples'
			  -> #( 'VectorGraphics-Engine' 'VectorGraphics-Paths' ).
			  'VectorGraphics-Paths-Tests'
			  -> #( 'VectorGraphics-Paths' 'VectorGraphics-Paths-Examples' ).
			  'VectorGraphics-Engine' -> #(  ).
			  'VectorGraphics-Engine-Examples' -> #( 'VectorGraphics-Engine' ).
			  "The engine tests run paths through the engine, which is what the engine is for,
			   and the paths examples draw into a canvas, so both name the other layer. Neither
			   edge is one the code itself makes."
			  'VectorGraphics-Engine-Tests'
			  -> #( 'VectorGraphics-Engine' 'VectorGraphics-Engine-Examples' 'VectorGraphics-Paths' ).
			  'VectorGraphics-TrueType' -> #( 'VectorGraphics-Paths' ).
			  'VectorGraphics-TrueType-Examples' -> #( 'VectorGraphics-TrueType' ).
			  "The font tests read a glyph as path commands and name no engine class: a font can
			   be parsed and measured with no rasteriser in the image."
			  'VectorGraphics-TrueType-Tests'
			  -> #( 'VectorGraphics-Paths' 'VectorGraphics-TrueType'
				    'VectorGraphics-TrueType-Examples' ).
			  "Text is six extension methods on classes of the two packages it joins, so it
			   holds no class of its own and nothing can name it."
			  'VectorGraphics-Text' -> #( 'VectorGraphics-Engine' 'VectorGraphics-TrueType' ).
			  'VectorGraphics-Text-Examples'
			  -> #( 'VectorGraphics-Engine' 'VectorGraphics-TrueType' ).
			  'VectorGraphics-Text-Tests'
			  -> #( 'VectorGraphics-Engine' 'VectorGraphics-Text-Examples'
				    'VectorGraphics-TrueType' ).
			  "The abstract documentation gate the four concrete ones subclass. It reads its
			   package from the subclass hook and the organiser, so it names no package of ours."
			  'VectorGraphics-Tests' -> #(  ).
			  "The Cairo backend draws text through the font reader and knows nothing of the
			   other three packages of the rasteriser."
			  'VectorGraphics-Cairo' -> #( 'VectorGraphics-TrueType' ).
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
			  "The budget — the two benchmarks and the drawing kit — lives in the test package,
			   because measuring this project against Cairo means naming Alexandrie's classes and
			   a package the failover loads may name none. So the examples that open a benchmark
			   name the test package, as the Cairo examples name theirs."
			  'VectorGraphics-Vulkan-Examples'
			  -> #( 'VectorGraphics-Bloc' 'VectorGraphics-Cairo' 'VectorGraphics-Vulkan'
				    'VectorGraphics-Vulkan-Tests' ).
			  "The edge to the Cairo tests is the one edge this project allows between two test
			   packages: VGVulkanExamplesTest subclasses VGCairoExamplesTest and the backend tests
			   draw the frame fixture the engine tests draw, rather than keeping a second copy of
			   either."
			  'VectorGraphics-Vulkan-Tests'
			  -> #( 'VectorGraphics-Bloc' 'VectorGraphics-Cairo' 'VectorGraphics-Cairo-Tests'
				    'VectorGraphics-Vulkan' 'VectorGraphics-Vulkan-Examples' ) }
]

{ #category : 'layering' }
VGArchitectureTest class >> blocPackageNames [
	"Every package of Bloc present in this image, read from the organiser by prefix. Alexandrie
	 is left out, unlike replacedStackPackageNames: the Cairo test package names Alexandrie's
	 Cairo bindings on purpose, because the conformance gate proves this rasteriser matches
	 live Cairo and a comparison needs that positive control."

	^ (PackageOrganizer default packages select: [ :each |
		   each name beginsWith: 'Bloc' ]) collect: [ :each | each name asString ]
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

{ #category : 'accessing' }
VGArchitectureTest class >> edgesTheBaselineCannotDeclare [
	"The edges of allowedDependencies that BaselineOfVectorGraphics may not state, because the
	 reverse edge is stated and Metacello loads requires in order: a pair declared both ways is
	 a cycle and no load order exists for it. Only these two pairs qualify, both of them an
	 examples package on the test package its subjects live in, and the two packages of each
	 pair always load together, so nothing is lost by leaving one half out.
	 Every entry is held by testEveryEdgeTheBaselineCannotDeclareIsOneHalfOfACycle, which reads
	 the reverse from the baseline rather than taking this comment on trust."

	^ {
		  ('VectorGraphics-Cairo-Examples' -> 'VectorGraphics-Cairo-Tests').
		  ('VectorGraphics-Vulkan-Examples' -> 'VectorGraphics-Vulkan-Tests') }
]

{ #category : 'layering' }
VGArchitectureTest class >> groupReport [
	"One row per group of BaselineOfVectorGraphics: its name, the packages loading that group
	 brings in, and the classes of Bloc or Alexandrie those packages name. The packages come
	 from the spec and the classes from a live scan, so a reader of the report and
	 testNoPackageOfTheDefaultGroupNamesAClassOfTheStackItReplaces cannot be looking at
	 different numbers."

	| scanner |
	scanner := VGCairoReferenceScanner new.
	^ ((BaselineOfVectorGraphics project version groups collect: [ :each |
		    each name asString ]) asSortedCollection asArray) collect: [ :groupName |
		  | loaded named |
		  loaded := (self packagesLoadedByGroupNamed: groupName) asSortedCollection asArray.
		  named := Set new.
		  loaded do: [ :package |
			  (scanner
				   offendersIn: package
				   naming: self replacedStackPackageNames) do: [ :each |
				  each value do: [ :one | named add: one name asString ] ] ].
		  {
			  groupName.
			  (self packageNameSeparator join: loaded).
			  (self packageNameSeparator join: named asSortedCollection) } ]
]

{ #category : 'layering' }
VGArchitectureTest class >> inheritanceOfGroupNamed: aGroupName into: aCollectionOfPackageNames [
	"The links from a class of that group to a superclass or trait in one of those packages,
	 as 'Subject -> Behaviour' strings. A superclass and a trait are named by the class
	 definition, not by any method, so the literal scan of VGCairoReferenceScanner cannot see
	 them, and this is the link Metacello fails on first."

	| found |
	found := OrderedCollection new.
	(self packagesLoadedByGroupNamed: aGroupName) do: [ :packageName |
		(PackageOrganizer default packageNamed: packageName) definedClasses do: [ :each |
			| behaviours |
			behaviours := each allSuperclasses asOrderedCollection
				              addAll: each traits;
				              addAll: each class traits;
				              yourself.
			behaviours do: [ :one |
				(one package notNil and: [
					 aCollectionOfPackageNames includes: one package name asString ]) ifTrue: [
					found add: each name , ' -> ' , one name ] ] ] ].
	^ found asSortedCollection asArray
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
VGArchitectureTest class >> inspectorGroups: aBuilder [
	"What each group of the baseline loads, and which classes of the stack this project
	 replaces those packages name. Reads groupReport, so the tab is a live scan of the image
	 the moment it opens: the default group's third cell is empty exactly while the project
	 loads in an image with no Bloc. It mutates nothing it shows."

	<inspectorPresentationOrder: 20 title: 'Groups'>
	^ aBuilder newTable
		  addColumn: (SpStringTableColumn title: 'Group' evaluated: [ :each | each first ]);
		  addColumn:
			  (SpStringTableColumn title: 'Loads' evaluated: [ :each | each second ]);
		  addColumn: (SpStringTableColumn
				   title: 'Names of Bloc or Alexandrie'
				   evaluated: [ :each | each third ]);
		  items: self groupReport;
		  yourself
]

{ #category : 'layering' }
VGArchitectureTest class >> inspectorGroupsContext: aContext [
	"The tab belongs to whichever class in this hierarchy reads the baseline's groups, which
	 today is this one and only one. Asking the baseline rather than naming the class keeps the
	 gate true if a second project ever subclasses me for its own layering."

	^ aContext active: BaselineOfVectorGraphics project version groups notEmpty
]

{ #category : 'layering' }
VGArchitectureTest class >> packageNameSeparator [
	"What dependencyReport puts between two package names inside one table cell."

	^ ', '
]

{ #category : 'layering' }
VGArchitectureTest class >> packagesLoadedByGroupNamed: aGroupName [
	"The packages of this project that Metacello loads for one group of
	 BaselineOfVectorGraphics: the names that group includes, every group among them expanded in
	 turn, and everything those packages require. Read from the spec rather than listed here, so
	 a group edited in the baseline moves this answer with it. An external project the baseline
	 names, such as Bloc, is left out: it is a name in another repository's baseline, and the
	 image happens to hold a package of the same name."

	| groups found todo |
	groups := Dictionary new.
	BaselineOfVectorGraphics project version groups do: [ :each |
		groups at: each name put: each includes ].
	found := Set new.
	todo := OrderedCollection with: aGroupName.
	[ todo isEmpty ] whileFalse: [
		| next |
		next := todo removeFirst.
		(groups includesKey: next)
			ifTrue: [ todo addAll: (groups at: next) ]
			ifFalse: [
				((found includes: next) or: [
					 (next beginsWith: self projectPackageNamePrefix) not ]) ifFalse: [
					found add: next.
					todo addAll: (self requiresOfPackageNamed: next) ] ] ].
	^ found
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

{ #category : 'layering' }
VGArchitectureTest class >> replacedStackPackageNamePrefixes [
	"Bloc and the Alexandrie packages Bloc is built on. This project exists to replace
	 Alexandrie's canvas inside Bloc, so the Bloc layer of this project may name both and no
	 other layer may name either."

	^ #( 'Bloc' 'Alexandrie' )
]

{ #category : 'layering' }
VGArchitectureTest class >> replacedStackPackageNames [
	"Every package of Bloc and of Alexandrie present in this image, read from the organiser by
	 prefix so that a package a Bloc update adds is covered without this method being edited."

	^ (PackageOrganizer default packages select: [ :each |
		   self replacedStackPackageNamePrefixes anySatisfy: [ :prefix |
			   each name beginsWith: prefix ] ]) collect: [ :each | each name asString ]
]

{ #category : 'layering' }
VGArchitectureTest class >> requiresOfPackageNamed: aPackageName [
	"What BaselineOfVectorGraphics says one package needs. A name the baseline declares as a
	 group or as an external project is not a package of ours and needs nothing here."

	^ (BaselineOfVectorGraphics project version packages
		   detect: [ :each | each name = aPackageName ]
		   ifNone: [ ^ #(  ) ]) requires
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

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testEngineExamplesStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Engine-Examples'
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testEngineStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Engine'
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testEngineTestsStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Engine-Tests'
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

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testEveryPackageOfThisProjectIsScannedByOneOfMyTests [
	"The table covering a package is not the same as a test scanning it: a package can appear in
	 allowedDependencies with an empty set and never be read, in which case every reference it
	 makes is allowed by nobody. One test per package names it, so the failure says which
	 package broke; this reads the package name out of each of those tests rather than listing
	 them, so the twenty-three stay in step with the organiser."

	| scanned |
	scanned := Set new.
	(self class selectors select: [ :each | each beginsWith: 'test' ]) do: [ :selector |
		| method |
		method := self class >> selector.
		(method sendsSelector: #assertEdgesOfPackageNamed:) ifTrue: [
			method literals do: [ :literal |
				(literal isString and: [
					 self class projectPackageNames includes: literal asString ]) ifTrue: [
					scanned add: literal asString ] ] ] ].
	self
		assert: scanned asSortedCollection asArray
		equals: self class projectPackageNames asSortedCollection asArray
]

{ #category : 'tests' }
VGArchitectureTest >> testNoClassOfTheCairoExampleAndTestGroupsInheritsFromBloc [
	"The cairo-examples and cairo-tests groups install in an image with no Bloc, which the
	 literal scan of testTheCairoExampleAndTestGroupsNameNoBlocClass cannot prove on its own:
	 a superclass is named by the class definition. Alexandrie is not asked about here —
	 blocPackageNames says why."

	#( 'cairo-examples' 'cairo-tests' ) do: [ :group |
		self
			assert: (self class inheritanceOfGroupNamed: group into: self class blocPackageNames)
			equals: #(  ) ].
	self
		assert: (self class inheritanceOfGroupNamed: 'bloc' into: self class blocPackageNames)
				notEmpty
		description: 'the walk finds nothing at all, so the empty answers above prove nothing'
]

{ #category : 'tests' }
VGArchitectureTest >> testNoClassOfTheDefaultGroupInheritsFromTheStackItReplaces [
	"This is the link that fails the load first: VGRenderer is a subclass of BARenderer, and
	 Metacello cannot install the class at all without Bloc in the image. The same question is
	 asked of the Cairo examples and tests by
	 testNoClassOfTheCairoExampleAndTestGroupsInheritsFromBloc."

	self
		assert: (self class
				 inheritanceOfGroupNamed: 'default'
				 into: self class replacedStackPackageNames)
		equals: #(  ).
	self
		assert:
			(self class inheritanceOfGroupNamed: 'bloc' into: self class replacedStackPackageNames)
				notEmpty
		description: 'the walk finds nothing at all, so the empty answer above proves nothing'
]

{ #category : 'tests - hierarchy' }
VGArchitectureTest >> testNoClassOfThisProjectInheritsFromAnObsoleteClass [
	"A class whose superclass is obsolete looks right in the browser and answers right in the
	 tests, because the obsolete copy still holds the methods the live class holds. It is still
	 broken: the live class is no longer in its own hierarchy, so a method added to it never
	 reaches the subclass, and the package the obsolete copy was filed under holds a class
	 nothing can find. Reparenting a class moved between packages, and reloading one from its
	 Tonel file after a crash, are the two ways this project has made one.
	 This is asked of every package of the project rather than of a list, so a package added
	 tomorrow is covered."

	| strays |
	strays := Set new.
	self class projectPackageNames do: [ :name |
		(PackageOrganizer default packageNamed: name) definedClasses do: [ :cls |
			cls allSuperclasses do: [ :each |
				each isObsolete ifTrue: [
					strays add: cls name asString , ' < ' , each name asString ] ] ] ].
	self assert: strays asSortedCollection asArray equals: #(  )
]

{ #category : 'tests' }
VGArchitectureTest >> testNoPackageOfTheDefaultGroupNamesAClassOfTheStackItReplaces [
	"Loading this project with no group named must not reach Bloc or Alexandrie. The engine and
	 the Cairo backend are what a user loads to rasterise; the Bloc renderer is the opt-in layer
	 that replaces Alexandrie's canvas inside Bloc. A package of the default group that names a
	 class of either fails to load in an image where neither is present, and VGRenderer, a
	 subclass of BARenderer, is how that was found."

	| scanner offenders |
	scanner := VGCairoReferenceScanner new.
	offenders := (self class packagesLoadedByGroupNamed: 'default') asSortedCollection asArray
		             flatCollect: [ :package |
			             (scanner
				              offendersIn: package
				              naming: self class replacedStackPackageNames) collect: [ :each |
				             package , ': ' , each key methodClass name , '>>'
				             , each key selector , ' names '
				             , (each value collect: [ :one | one name ]) asArray printString ] ].
	self assert: offenders asSortedCollection asArray equals: #(  )
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testPathsExamplesStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Paths-Examples'
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testPathsStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Paths'
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testPathsTestsStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Paths-Tests'
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testTextExamplesStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Text-Examples'
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testTextStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Text'
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testTextTestsStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Text-Tests'
]

{ #category : 'tests' }
VGArchitectureTest >> testTheBaselineNamesOnlyBlocAndMuTalkAsExternalProjects [
	"Every project outside this repository that a load can reach, named here so one cannot be
	 added without saying which group needs it: Bloc for the renderer group, MuTalk for the dev
	 group. PharoVulkan is deliberately not among them — it is unpublished, and the vulkan
	 group expects it loaded by hand."

	self
		assert: (BaselineOfVectorGraphics project version projects collect: [ :each |
				 each name ]) asSortedCollection asArray
		equals: #( 'Bloc' 'MuTalk' )
]

{ #category : 'tests' }
VGArchitectureTest >> testTheBlocGroupLoadsEverythingTheDefaultGroupLoadsAndTheRenderer [
	"Using this project as Alexandrie's replacement stays one load: the bloc group brings the
	 renderer and everything the default group brings. Dropping the renderer out of the default
	 group must not make it harder to reach."

	| loaded |
	loaded := self class packagesLoadedByGroupNamed: 'bloc'.
	self assert: (loaded includes: 'VectorGraphics-Bloc').
	self assert: ((self class packagesLoadedByGroupNamed: 'default') allSatisfy: [ :each |
			 loaded includes: each ])
]

{ #category : 'tests' }
VGArchitectureTest >> testTheBlocLayerRequiresTheExternalBlocProject [
	"The renderer subclasses BARenderer, so the group that loads it must fetch Bloc rather than
	 assume an image that already holds it. No package of the default stack requires Bloc,
	 which is the other half of the same fact."

	| requires |
	requires := Dictionary new.
	BaselineOfVectorGraphics project version packages do: [ :each |
		requires at: each name put: each requires asSet ].
	self assert: ((requires at: 'VectorGraphics-Bloc') includes: 'Bloc').
	(self class packagesLoadedByGroupNamed: 'default') do: [ :each |
		self deny: ((requires at: each) includes: 'Bloc') ]
]

{ #category : 'tests - groups' }
VGArchitectureTest >> testTheCairoExampleAndTestGroupsNameNoBlocClass [
	"The examples and the tests of the Cairo layer load without Bloc too, each from a group of
	 its own: the project-wide examples and tests groups span every layer, so asking for them
	 fetches Bloc and wants PharoVulkan, which a user of the Cairo backend wants neither of.
	 Neither group brings the front page or the other three packages of the rasteriser, because
	 the Cairo backend names the font reader alone. Alexandrie is not asked about here —
	 blocPackageNames says why. A group that does not exist would pass on an empty scan, so the
	 packages each one must bring in are named first."

	| scanner offenders |
	scanner := VGCairoReferenceScanner new.
	self
		assert: (self class packagesLoadedByGroupNamed: 'cairo-examples')
		equals: #( 'VectorGraphics-Cairo' 'VectorGraphics-Cairo-Examples' 'VectorGraphics-Paths'
			   'VectorGraphics-TrueType' ) asSet.
	self
		assert: (self class packagesLoadedByGroupNamed: 'cairo-tests')
		equals: #( 'VectorGraphics-Cairo' 'VectorGraphics-Cairo-Examples'
			   'VectorGraphics-Cairo-Tests' 'VectorGraphics-Paths' 'VectorGraphics-TrueType' ) asSet.
	offenders := #( 'cairo-examples' 'cairo-tests' ) flatCollect: [ :group |
		             (self class packagesLoadedByGroupNamed: group) asSortedCollection asArray
			             flatCollect: [ :package |
				             (scanner
					              offendersIn: package
					              naming: self class blocPackageNames) collect: [ :each |
					             group , ' ' , package , ': ' , each key methodClass name , '>>'
					             , each key selector ] ] ].
	self assert: offenders asSortedCollection asArray equals: #(  )
]

{ #category : 'tests - groups' }
VGArchitectureTest >> testTheDefaultGroupLoadsTheRasteriserAndTheCairoBackendAlone [
	"What `Metacello load: 'VectorGraphics'` brings in, named here so the group cannot grow a
	 layer back by accident. The rasteriser is four packages since the split and the default
	 group brings all four, because that is what the one package it replaced held. Every layer
	 above it is a group of its own."

	self
		assert: (self class packagesLoadedByGroupNamed: 'default') asSortedCollection asArray
		equals: #( 'VectorGraphics' 'VectorGraphics-Cairo' 'VectorGraphics-Engine'
			   'VectorGraphics-Paths' 'VectorGraphics-Text' 'VectorGraphics-TrueType' )
]

{ #category : 'tests - groups' }
VGArchitectureTest >> testTheDevGroupBringsNoBlocAndNoVulkanPackage [
	"The dev group must load in a plain Pharo image. The renderer layers are the two that need
	 something outside this repository — Bloc from its own repository, PharoVulkan by hand — so
	 a dev group that reached them would make a mutation run depend on a machine with a Vulkan
	 driver."

	| loaded |
	loaded := self class packagesLoadedByGroupNamed: 'dev'.
	self assert: (loaded reject: [ :each |
			 (each includesSubstring: 'Bloc') or: [
				 each includesSubstring: 'Vulkan' ] ]) equals: loaded.
	self assert: (loaded includes: 'VectorGraphics-Cairo-Tests').
	#( 'Paths' 'Engine' 'TrueType' 'Text' ) do: [ :layer |
		self assert: (loaded includes: 'VectorGraphics-' , layer , '-Tests') ]
]

{ #category : 'tests - groups' }
VGArchitectureTest >> testTheDevGroupLoadsTheDefaultStackItsTestsAndMuTalk [
	"The group a developer of this project loads: what `default` loads, the tests of those same
	 layers, and MuTalk. MuTalk mutates production methods and asks whether a test notices, so a
	 dev group without the tests of the code under test would report everything as survived.
	 The four layer test groups and cairo-tests are named one by one rather than through the
	 project-wide `tests` group, because that one spans every layer: it fetches Bloc and wants
	 PharoVulkan, neither of which a mutation run of the Cairo stack needs."

	| groups |
	groups := Dictionary new.
	BaselineOfVectorGraphics project version groups do: [ :each |
		groups at: each name put: each includes ].
	self assert: (groups includesKey: 'dev').
	self
		assert: (groups at: 'dev') asSortedCollection asArray
		equals: #( 'MuTalk' 'cairo-tests' 'default' 'engine-tests' 'paths-tests'
			   'text-tests' 'truetype-tests' )
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testTheDocumentationGatePackageStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Tests'
]

{ #category : 'tests - groups' }
VGArchitectureTest >> testTheExamplesAndTestsGroupsAreTheUnionOfTheirLayerGroups [
	"One group per layer for examples and for tests, and the project-wide group is their union.
	 Stating the union as the layer group names rather than as package names is what keeps the
	 two from drifting apart when a layer gains a package. Seven layers since the split: the
	 four packages of the rasteriser, then Cairo, Bloc and Vulkan."

	| groups |
	groups := Dictionary new.
	BaselineOfVectorGraphics project version groups do: [ :each |
		groups at: each name put: each includes asArray ].
	self assert: (groups at: 'examples') equals: #( 'paths-examples' 'engine-examples'
			 'truetype-examples' 'text-examples' 'cairo-examples' 'bloc-examples'
			 'vulkan-examples' ).
	self assert: (groups at: 'tests') equals: #( 'paths-tests' 'engine-tests' 'truetype-tests'
			 'text-tests' 'cairo-tests' 'bloc-tests' 'vulkan-tests' ).
	#( 'examples' 'tests' ) do: [ :name |
		self
			assert: (self class packagesLoadedByGroupNamed: name)
			equals: ((groups at: name) inject: Set new into: [ :all :layer |
					 all
						 addAll: (self class packagesLoadedByGroupNamed: layer);
						 yourself ]) ]
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testTheFrontPagePackageStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics'
]

{ #category : 'tests - groups' }
VGArchitectureTest >> testTheMuTalkProjectIsPinnedToATagAndNotToMaster [
	"MuTalk is a development tool that rewrites production methods in the image, so the version
	 it rewrites with is part of this project's own setup: a tag, never the moving `master`.
	 Bloc is pinned to master on purpose and is the exception — it has no release tags."

	| repositories |
	repositories := Dictionary new.
	BaselineOfVectorGraphics project version projects do: [ :each |
		repositories at: each name put: each repositories map keys asSortedCollection asArray ].
	self
		assert: (repositories at: 'MuTalk')
		equals: #( 'github://pharo-contributions/mutalk:v3.0.8/src' )
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

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testTrueTypeExamplesStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-TrueType-Examples'
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testTrueTypeStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-TrueType'
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testTrueTypeTestsStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-TrueType-Tests'
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
