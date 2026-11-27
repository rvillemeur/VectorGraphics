"
I hold the declarations of the font route honest. Every relation a font class declares must name a class that exists, every stated opposite must be stated from both sides, and every `<sampleInstance>` example of those packages must hold what its class declares it holds — a structural holding of one actually holding an object of another kind is a fault, while an unbuilt cache is not.

I also count the declarations, because a gate over no declarations passes for the wrong reason, and I say that no example of the route raises. Two examples read an OpenType font this repository does not carry: they answer nil and carry `<needsAFontThisMachineMayLack:>`, which names what to install, so there is no whitelist here and a broken example is a failure.

What the font classes may depend on is not my business: `VGArchitectureTest class >> allowedDependencies` states that, and the manifest of the documentation package states the layering of the drawing.
"
Class {
	#name : 'VGFontArchitectureTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Documentation-Tests',
	#package : 'VectorGraphics-Documentation-Tests'
}

{ #category : 'accessing' }
VGFontArchitectureTest >> fontPackageNames [
	"The packages of the font route whose declarations this gate holds. Slice one declares the two
	 that carry the Bloc replacement; VectorGraphics-TrueType joins them when its relations are
	 written."

	^ #( 'VectorGraphics-Canvas-Fonts' 'VectorGraphics-Bloc-Text' )
]

{ #category : 'accessing' }
VGFontArchitectureTest >> fontRoutePackageNames [
	"Every package of the font work, the reader included: the four whose manifests must say where
	 a reader starts. It is held apart from fontPackageNames, which is what the route map claims,
	 and from trueTypePackageName, which is the reader alone."

	^ self fontPackageNames
		, { 'VectorGraphics-Bloc-FontEngine'. self trueTypePackageName }
]

{ #category : 'tests' }
VGFontArchitectureTest >> testEveryDeclarationOfTheFontPackagesResolvesAndAgreesWithItsSamples [
	"The gate of the declarations: a target class that is gone, an opposite only one side states, or
	 a sample instance holding something other than what it declares are all reported here rather
	 than found by a reader of the diagram."

	self fontPackageNames do: [ :each |
		self
			assert:
			((ArchDocChecker onPackageNamed: each) findings collect: [ :finding |
				 finding explanation ]) asArray
			equals: #() ]
]

{ #category : 'tests' }
VGFontArchitectureTest >> testEveryDeclarationOfTheTrueTypePackageResolvesAndAgreesWithItsSamples [
	"The same gate as the one over the drawing packages, over the reader: a target class that is
	 gone, an opposite only one side states, or a sample instance holding something other than
	 what it declares are reported here rather than found by a reader of the diagram."

	self
		assert:
		((ArchDocChecker onPackageNamed: self trueTypePackageName) findings
			 collect: [ :each | each explanation ]) asArray
		equals: #()
]

{ #category : 'tests' }
VGFontArchitectureTest >> testEveryPackageOfTheFontRouteSaysWhereAReaderStarts [
	"A diagram of seventeen boxes says what exists and not what to read first, and the formula
	 that orders them knows nothing of intention. So each manifest of the route declares its own
	 entry points, and this gate says that none of the four is silent and that every name
	 declared is a class of the package declaring it."

	self fontRoutePackageNames do: [ :each |
		| model |
		model := ArchDocModel onPackageNamed: each.
		self
			deny: model entryPointNames isEmpty
			description: each , ' declares no entry point'.
		self
			assert: (model entryPointClasses collect: [ :class | class name ]) asArray
			equals: (model entryPointNames collect: [ :name | name asString ]) asArray ]
]

{ #category : 'tests' }
VGFontArchitectureTest >> testNoExampleOfTheFontRouteRaisesAndAFixturelessOneSaysWhatToInstall [
	"An example that raises hides whichever declaration it would have proved, so none of the route
	 may raise. Two examples read an OpenType font this repository does not carry: they answer nil
	 and say what to install through <needsAFontThisMachineMayLack:>, which the example gates read,
	 and ArchDoc counts a nil as no instance rather than as a fault. So nothing is pinned here any
	 more — a broken example is a failure, and the pragma is what keeps the missing fixture stated
	 in one place."

	| broken |
	broken := (self fontPackageNames , { self trueTypePackageName }) flatCollect: [
		          :each | (ArchDocChecker onPackageNamed: each) brokenExamples ].
	self
		assert: (broken collect: [ :each | each explanation ]) asArray
		equals: #().
	self
		assert: ((VGScaledFontExamples class >> #fontFaceOfAnOpenTypeFont)
				 hasPragmaNamed: #needsAFontThisMachineMayLack:)
		description: 'fontFaceOfAnOpenTypeFont does not say which font it needs'
]

{ #category : 'tests' }
VGFontArchitectureTest >> testTheFontPackagesDeclareTheTwentyHoldingsOfTheRoute [
	"A gate over no declarations passes for the wrong reason, so count them. Twenty is what the
	 route holds today: five on the scaled font, one on the atlas, one on the mask, two on the
	 Alexandrie adapter, four the font face states in its two class-side tables, and the six of
	 the Bloc side — the adapter a text context is posed with, the catalogue a font manager
	 answers from, its three caches of faces, and the two managers its class keeps."

	| declared |
	declared := self fontPackageNames
		inject: 0
		into: [ :sum :each | sum + (ArchDocModel onPackageNamed: each) relations size ].
	self assert: declared equals: 20
]

{ #category : 'tests' }
VGFontArchitectureTest >> testTheRouteMapClaimsTheFontPackagesAndMapsEveryClassOfThem [
	"The component map is the altitude a reader meets first, so a class added to the route must be
	 put in a part of it. The map answers its own faults: a class no part names, a class two parts
	 name, and a part naming a class the image does not hold."

	| map |
	map := VGFontRouteMap new.
	self assert: VGFontRouteMap packageNames asArray equals: self fontPackageNames.
	self
		assert: (map unmappedClasses collect: [ :each | each name ]) asArray
		equals: #().
	self assert: map ambiguousClasses asArray equals: #().
	self assert: map unknownClassNames asArray equals: #().
	self
		assert: (map findings collect: [ :each | each explanation ]) asArray
		equals: #()
]

{ #category : 'tests' }
VGFontArchitectureTest >> testTheTrueTypePackageDeclaresEveryHoldingOfItsFourTags [
	"The reader is declared one tag at a time, so the gate counts per tag and says which tag is
	 short. A tag at zero is a tag whose relations are not written yet.
	 A class-side table is inherited, so one row on TTFontParser is a declaration of every table
	 parser, which is the truth about them: each one holds the entry it reads from. That is why
	 the Reading tag counts eighteen for six written rows, and why the CFF tag counts the row
	 TTCffTableParser inherits among its ten. A pragma is read from the methods a class defines
	 itself, so it is counted once however many subclasses inherit the accessor."

	| byTag |
	byTag := Dictionary new.
	#( 'Reading' 'Glyphs' 'Fonts' 'CFF' ) do: [ :each | byTag at: each put: 0 ].
	(ArchDocModel onPackageNamed: self trueTypePackageName) relations do: [ :each |
		| tag |
		tag := each declaringClass instanceSide packageTag name.
		byTag at: tag put: (byTag at: tag ifAbsent: [ 0 ]) + 1 ].
	self
		assert: byTag
		equals: (Dictionary newFrom: { 'Reading' -> 18. 'Glyphs' -> 3. 'Fonts' -> 11. 'CFF' -> 10 })
]

{ #category : 'accessing' }
VGFontArchitectureTest >> trueTypePackageName [
	"The package that reads a font file. It is held apart from fontPackageNames, because that
	 list is also what the route map claims, and the map is about the drawing of text and not
	 about the forty-four classes of the reader."

	^ 'VectorGraphics-TrueType'
]
