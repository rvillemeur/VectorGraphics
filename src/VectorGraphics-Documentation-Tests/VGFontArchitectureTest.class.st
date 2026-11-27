"
I hold the declarations of the font route honest. Every relation a font class declares must name a class that exists, every stated opposite must be stated from both sides, and every `<sampleInstance>` example of those packages must hold what its class declares it holds — a structural holding of one actually holding an object of another kind is a fault, while an unbuilt cache is not.

I also count the declarations, because a gate over no declarations passes for the wrong reason, and I pin the one example of the route that cannot run in this image: it asks for an OpenType font with a CFF table and raises when the font directory holds none. That pin is what fails when the example is fixed, so the defect cannot be forgotten and cannot silently grow a second case.

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

{ #category : 'private' }
VGFontArchitectureTest >> isKnownBrokenExample: aFinding [
	"One example of the font package cannot run in an image whose fonts carry no CFF table, which
	 is a defect of that example and not of any declaration. It is pinned by
	 testTheOpenTypeExampleIsTheOnlyExampleThatCannotRun, so this gate stays about declarations
	 while the defect stands, and the pin is what fails once it is fixed."

	^ aFinding kind = #brokenExample
		and: [ aFinding explanation includesSubstring: self openTypeExampleSelector ]
]

{ #category : 'accessing' }
VGFontArchitectureTest >> openTypeExampleSelector [
	"The one example of the font packages known not to run: it asks for an OpenType font with a CFF
	 table, and an image whose font directory holds none cannot answer."

	^ 'fontFaceOfAnOpenTypeFont'
]

{ #category : 'tests' }
VGFontArchitectureTest >> testEveryDeclarationOfTheFontPackagesResolvesAndAgreesWithItsSamples [
	"The gate of the declarations: a target class that is gone, an opposite only one side states, or
	 a sample instance holding something other than what it declares are all reported here rather
	 than found by a reader of the diagram."

	self fontPackageNames do: [ :each |
		| findings |
		findings := (ArchDocChecker onPackageNamed: each) findings
			reject: [ :finding | self isKnownBrokenExample: finding ].
		self
			assert: (findings collect: [ :finding | finding explanation ]) asArray
			equals: #() ]
]

{ #category : 'tests' }
VGFontArchitectureTest >> testTheFontPackagesDeclareTheThirteenHoldingsOfTheRoute [
	"A gate over no declarations passes for the wrong reason, so count them. Thirteen is what the
	 route holds today: five on the scaled font, one on the atlas, one on the mask, two on the
	 Alexandrie adapter, and four the font face states in its two class-side tables."

	| declared |
	declared := self fontPackageNames
		inject: 0
		into: [ :sum :each | sum + (ArchDocModel onPackageNamed: each) relations size ].
	self assert: declared equals: 13
]

{ #category : 'tests' }
VGFontArchitectureTest >> testTheOpenTypeExampleIsTheOnlyExampleThatCannotRun [
	"A pin on a defect, not a rule: VGScaledFontExamples >> fontFaceOfAnOpenTypeFont raises in an
	 image whose font directory holds no font with a CFF table. The declaration gate ignores that
	 one example by name, so this test is what fails when the example is fixed or when a second
	 example starts to raise."

	| broken |
	broken := self fontPackageNames flatCollect: [ :each |
		(ArchDocChecker onPackageNamed: each) brokenExamples ].
	self
		assert: (broken collect: [ :each | each explanation ]) asArray size
		equals: 1.
	self assert: (broken allSatisfy: [ :each | self isKnownBrokenExample: each ])
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
