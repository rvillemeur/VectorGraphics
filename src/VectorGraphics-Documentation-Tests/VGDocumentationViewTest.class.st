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
VGDocumentationViewTest >> testTheComponentsTabIsOfferedOnThePackagesAMapClaimsAlone [
	"A package no map claims has no components to show, so the tab is not built for it. The
	 architecture tab stays wherever it was: the two altitudes sit side by side."

	self assert: (self isComponentsTabActiveFor: 'VectorGraphics-Canvas-Fonts').
	self assert: (self isComponentsTabActiveFor: 'VectorGraphics-Bloc-Text').
	self deny: (self isComponentsTabActiveFor: 'VectorGraphics-Engine').
	self assert: (self isArchitectureTabActiveFor: 'VectorGraphics-Engine')
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
