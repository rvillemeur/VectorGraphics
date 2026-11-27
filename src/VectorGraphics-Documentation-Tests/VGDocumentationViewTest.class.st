"
I hold the two inspector tabs this project's documentation package installs to their shape: each one builds through a real presenter builder, draws the classes or the objects a reader expects to see, and the *Architecture* tab is offered on this project's packages alone.

I build a tab the way the inspector does, through `StInspectionContext >> basicNewInspectionPresenter:`, and never through `newInspectionPresenterOnApplication:`, which catches every error and answers a debug presenter — a broken view would pass.
"
Class {
	#name : 'VGDocumentationViewTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Documentation-Tests',
	#package : 'VectorGraphics-Documentation-Tests'
}

{ #category : 'running' }
VGDocumentationViewTest >> isArchitectureTabActiveFor: aPackageName [
	"Ask the gate the way the inspector does: it is handed a context and decides whether to
	 build the tab at all."

	| context |
	context := StInspectionContext new
		inspectedObject: (Smalltalk packageOrganizer packageNamed: aPackageName);
		methodSelector: #inspectionArchitecture:;
		yourself.
	(Smalltalk packageOrganizer packageNamed: aPackageName)
		inspectionArchitectureContext: context.
	^ context isActive
]

{ #category : 'running' }
VGDocumentationViewTest >> isComponentsTabActiveFor: aPackageName [
	"Ask the gate the way the inspector does, for the components tab this time."

	| context package |
	package := Smalltalk packageOrganizer packageNamed: aPackageName.
	context := StInspectionContext new
		inspectedObject: package;
		methodSelector: #inspectionComponents:;
		yourself.
	package inspectionComponentsContext: context.
	^ context isActive
]

{ #category : 'private' }
VGDocumentationViewTest >> isNeighboursTabActiveFor: aPackageName [
	"Ask the gate the way the inspector does, for the neighbours tab this time."

	| context package |
	package := Smalltalk packageOrganizer packageNamed: aPackageName.
	context := StInspectionContext new
		inspectedObject: package;
		methodSelector: #inspectionNeighbours:;
		yourself.
	package inspectionNeighboursContext: context.
	^ context isActive
]

{ #category : 'running' }
VGDocumentationViewTest >> isWhereToStartTabActiveFor: aPackageName [
	"Ask the gate the way the inspector does, for the where-to-start tab this time."

	| context package |
	package := Smalltalk packageOrganizer packageNamed: aPackageName.
	context := StInspectionContext new
		inspectedObject: package;
		methodSelector: #inspectionWhereToStart:;
		yourself.
	package inspectionWhereToStartContext: context.
	^ context isActive
]

{ #category : 'running' }
VGDocumentationViewTest >> presenterOf: anObject on: aSelector [
	"Build one inspector tab the way a reader opens it, through the inspection context, which is
	 what hands the view its presenter builder. Not newInspectionPresenterOnApplication:, which
	 catches every error and answers a debug presenter, so a broken view would pass."

	| context |
	context := StInspectionContext new
		inspectedObject: anObject;
		methodSelector: aSelector;
		yourself.
	^ context basicNewInspectionPresenter:
		(SpPresenterBuilder newApplication: SpApplication new)
]

{ #category : 'tests' }
VGDocumentationViewTest >> testBothExamplesAnswerSomethingDrawable [
	"The examples are what a reader clicks in the browser, so they are run here too: each answers
	 an object whose own inspector draws the picture, and a canvas with no node would mean the tab
	 shows a reader nothing."

	| architecture objects |
	architecture := VGDocumentationExamples architectureOfTheFontPackage.
	self assert: architecture canvas nodes notEmpty.
	objects := VGDocumentationExamples objectGraphOfAWarmScaledFont.
	self assert: (ArchDocGraphRenderer on: objects graph) canvas nodes notEmpty
]

{ #category : 'tests' }
VGDocumentationViewTest >> testTheArchitectureTabIsOfferedOnThisProjectsPackagesAlone [
	"Every package of the image would otherwise carry the tab, and deciding by reading the
	 declarations of a package costs a scan of all its methods. The gate is the project's own
	 package names, which is what this extension is entitled to answer for."

	self assert: (self isArchitectureTabActiveFor: 'VectorGraphics-Canvas-Fonts').
	self deny: (self isArchitectureTabActiveFor: 'Kernel')
]

{ #category : 'tests' }
VGDocumentationViewTest >> testTheArchitectureTabOfTheTrueTypePackageDrawsTheArrowsTheReaderDeclares [
	"The reader's declarations must reach the picture, not only the checker: a catalogue over its
	 entries, and a table parser over the directory entry it reads from."

	| package presenter lines |
	package := Smalltalk packageOrganizer packageNamed: 'VectorGraphics-TrueType'.
	presenter := self presenterOf: package on: #inspectionArchitecture:.
	lines := presenter canvas lines collect: [ :each | each model ].
	self assert: (lines anySatisfy: [ :each |
		each source name = #TTFontCatalogue and: [ each target name = #TTFontCatalogueEntry ] ]).
	self assert: (lines anySatisfy: [ :each |
		each source name = #TTCmapTableParser
			and: [ each target name = #TTFontTableDirEntry ] ])
]

{ #category : 'tests' }
VGDocumentationViewTest >> testTheComponentsTabIsOfferedOnThePackagesAMapClaimsAlone [
	"A package no map claims has no components to show, so the tab is not built for it. The
	 architecture tab stays wherever it was: the two altitudes sit side by side."

	self assert: (self isComponentsTabActiveFor: 'VectorGraphics-Canvas-Fonts').
	self assert: (self isComponentsTabActiveFor: 'VectorGraphics-Bloc-Text').
	self deny: (self isComponentsTabActiveFor: 'VectorGraphics-Engine').
	self assert: (self isArchitectureTabActiveFor: 'VectorGraphics-Engine')
]

{ #category : 'tests' }
VGDocumentationViewTest >> testTheFontManagerObjectGraphTabWalksTheManagerAndTheFacesItKeeps [
	"The Bloc side of the route starts at the manager Bloc asks for a face. What it holds now is
	 the catalogue it answers from and the faces a session has drawn with, and neither is visible
	 in the declarations alone: a manager nobody drew with keeps no face at all."

	| presenter labels |
	presenter := self
		presenterOf: VGDocumentationExamples objectGraphOfTheSharedFontManager root
		on: #inspectionObjectGraph:.
	labels := presenter canvas nodes collect: [ :each |
		(each shapes detect: [ :shape | shape class = RSLabel ]) text ].
	self assert: (labels anySatisfy: [ :each | each includesSubstring: 'VGFontManager' ]).
	self assert: (labels anySatisfy: [ :each | each includesSubstring: 'TTFontCatalogue' ])
]

{ #category : 'tests' }
VGDocumentationViewTest >> testTheNeighboursTabDrawsTheWholeProjectWithThisPackageInFocus [
	"A reader opening a package of this project meets the project first: every package of it, the
	 arrows between them, and the one they came from filled apart from the rest. The picture is
	 drawn once here: a force layout over forty-five boxes is not something to ask for twice."

	| package presenter project renderer |
	package := Smalltalk packageOrganizer packageNamed: 'VectorGraphics-Canvas-Fonts'.
	project := package archDocProject.
	presenter := self presenterOf: package on: #inspectionNeighbours:.
	renderer := ArchDocPackageRenderer onProject: project focusing: package.
	self assert: (project packages includes: package).
	self assert: presenter canvas nodes size equals: project graph nodes size.
	self assert: (renderer fillFor: package) equals: renderer focusColor
]

{ #category : 'tests' }
VGDocumentationViewTest >> testTheNeighboursTabIsOfferedOnThisProjectsPackagesAlone [
	"This package answers for its own project. Reading another project's layering would cost a
	 scan of every method of every package a reader opens, and would claim to speak for code
	 this project does not own."

	self assert: (self isNeighboursTabActiveFor: 'VectorGraphics-Canvas-Fonts').
	self assert: (self isNeighboursTabActiveFor: 'VectorGraphics-Documentation').
	self deny: (self isNeighboursTabActiveFor: 'Kernel')
]

{ #category : 'tests' }
VGDocumentationViewTest >> testThePackageArchitectureTabDrawsTheDeclaredFontGraph [
	"A reader opens the font package and sees its classes and what they hold. The tab is on
	 Package, so it is reached from the browser without knowing this library exists."

	| presenter canvas |
	presenter := self
		presenterOf: (Smalltalk packageOrganizer packageNamed: 'VectorGraphics-Canvas-Fonts')
		on: #inspectionArchitecture:.
	canvas := presenter canvas.
	self assert: ((canvas nodes collect: [ :each | each model ]) includes: VGScaledFont).
	self assert: ((canvas lines collect: [ :each | each model label ]) includes: 'fontFace')
]

{ #category : 'tests' }
VGDocumentationViewTest >> testThePackageComponentsTabDrawsTheRouteMap [
	| package presenter boxes |
	package := Smalltalk packageOrganizer packageNamed: 'VectorGraphics-Canvas-Fonts'.
	presenter := self presenterOf: package on: #inspectionComponents:.
	boxes := presenter canvas nodes select: [ :each | each class = RSComposite ].
	self
		assert: (boxes collect: [ :each | each model name ]) asArray
		equals: (VGFontRouteMap new components collect: [ :each | each name ]) asArray
]

{ #category : 'tests' }
VGDocumentationViewTest >> testTheScaledFontObjectGraphTabWalksARealFont [
	"A reader holds one scaled font and asks what it actually holds now, which is the question the
	 declarations alone cannot answer: a cache that was never asked for reads as absent."

	| presenter labels |
	presenter := self
		presenterOf: VGScaledFontExamples scaledFontAtAReadableSize
		on: #inspectionObjectGraph:.
	labels := presenter canvas nodes collect: [ :each |
		(each shapes detect: [ :shape | shape class = RSLabel ]) text ].
	self assert: (labels anySatisfy: [ :each | each includesSubstring: 'VGScaledFont' ]).
	self assert: (labels anySatisfy: [ :each | each includesSubstring: 'VGFontFace' ])
]

{ #category : 'tests' }
VGDocumentationViewTest >> testTheWhereToStartTabOrdersTheClassesOfThePackageAndIsOfferedOnThisProjectAlone [
	"A reader who has seen where the package sits asks which of its classes to read first. The
	 tab answers the reading order over the package's own class graph, and it is gated by the
	 same rule as its siblings: this project's packages alone."

	| package presenter order |
	package := Smalltalk packageOrganizer packageNamed: 'VectorGraphics-Canvas-Fonts'.
	presenter := self presenterOf: package on: #inspectionWhereToStart:.
	order := ArchDocReadingOrder on: (ArchDocModel onPackage: package) graph.
	self assert: presenter items asArray equals: order nodesInOrder.
	self deny: presenter items isEmpty.
	self assert: (self isWhereToStartTabActiveFor: 'VectorGraphics-Canvas-Fonts').
	self deny: (self isWhereToStartTabActiveFor: 'Kernel')
]
