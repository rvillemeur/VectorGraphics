"
I hold the inventory of the Cairo calling surface that Bloc and AeCanvas really use, and I check our replacement answers all of it.

The inventory is frozen in VGCairoInventory as three lists of selectors, one for the context, one for the surface and one for the pattern classes. A frozen list is needed because the engine image loads neither Bloc nor Alexandrie, so nothing reflective is available there. When Alexandrie is loaded, testFrozenInventoryMatchesTheLiveCairoClasses measures the real thing again and fails if the frozen list has drifted, so the list cannot go stale unnoticed.
"
Class {
	#name : 'VGCairoInventoryTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Cairo-Tests-Tests',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Tests'
}

{ #category : 'asserting' }
VGCairoInventoryTest >> assert: aClass answers: aCollectionOfSelectors [
	"A skeleton selector counts as answered: it exists and names the unit that will implement it.
	 This assertion is about the shape of the calling surface, not about behaviour."

	| missing |
	missing := (aCollectionOfSelectors reject: [ :each | aClass canUnderstand: each ])
		           asSortedCollection asArray.
	self
		assert: missing isEmpty
		description: aClass name , ' does not answer ' , missing printString
]

{ #category : 'asserting' }
VGCairoInventoryTest >> assertFrozen: frozenSelectors matchesMeasuredOn: aClassName excluding: excludedClassNames classSide: isClassSide [
	"Fail if the frozen list has drifted from what the live Alexandrie classes show. Without this,
	 the frozen lists would be a restatement that nothing checks."

	| measured found |
	measured := VGCairoInventory
		            measuredSelectorsOf: (Smalltalk at: aClassName)
		            excluding: excludedClassNames.
	found := isClassSide
		         ifTrue: [ measured value ]
		         ifFalse: [ measured key ].
	found := (found difference: VGCairoInventory selectorsExcludedFromInventory) asSortedCollection
		         asArray.
	self assert: found equals: frozenSelectors asSortedCollection asArray
]

{ #category : 'tests' }
VGCairoInventoryTest >> testContextAnswersEverySelectorItsCallersSend [
	self assert: VGCairoContext answers: VGCairoInventory contextSelectors.
	self assert: VGCairoContext class answers: VGCairoInventory contextClassSelectors
]

{ #category : 'tests - drift' }
VGCairoInventoryTest >> testFrozenContextInventoryMatchesTheLiveCairoClass [
	VGCairoInventory isLiveCairoAvailable ifFalse: [ ^ self skip ].
	self
		assertFrozen: VGCairoInventory contextSelectors
		matchesMeasuredOn: #AeCairoContext
		excluding: #()
		classSide: false.
	self
		assertFrozen: VGCairoInventory contextClassSelectors
		matchesMeasuredOn: #AeCairoContext
		excluding: #()
		classSide: true
]

{ #category : 'tests - drift' }
VGCairoInventoryTest >> testFrozenPatternInventoryMatchesTheLiveCairoClass [
	VGCairoInventory isLiveCairoAvailable ifFalse: [ ^ self skip ].
	self
		assertFrozen: VGCairoInventory patternSelectors
		matchesMeasuredOn: #AeCairoPattern
		excluding: VGCairoInventory excludedPatternClassNames
		classSide: false.
	self
		assertFrozen: VGCairoInventory patternClassSelectors
		matchesMeasuredOn: #AeCairoPattern
		excluding: VGCairoInventory excludedPatternClassNames
		classSide: true
]

{ #category : 'tests - drift' }
VGCairoInventoryTest >> testFrozenSurfaceInventoryMatchesTheLiveCairoClass [
	VGCairoInventory isLiveCairoAvailable ifFalse: [ ^ self skip ].
	self
		assertFrozen: VGCairoInventory surfaceSelectors
		matchesMeasuredOn: #AeCairoSurface
		excluding: #()
		classSide: false.
	self
		assertFrozen: VGCairoInventory surfaceClassSelectors
		matchesMeasuredOn: #AeCairoSurface
		excluding: #()
		classSide: true
]

{ #category : 'tests' }
VGCairoInventoryTest >> testPatternAnswersEverySelectorItsCallersSend [
	"A pattern constructor belongs to the subclass it builds, the way AeCairoLinearGradientPattern
	 owns from:to:, so the inventory is satisfied by the family rather than by one class."

	self assert: VGCairoPattern answers: VGCairoInventory patternSelectors.
	VGCairoInventory patternClassSelectors do: [ :each |
		self
			assert: (VGCairoPattern withAllSubclasses anySatisfy: [ :one |
					 one class canUnderstand: each ])
			description: 'no pattern class answers ' , each ]
]

{ #category : 'tests' }
VGCairoInventoryTest >> testSurfaceAnswersEverySelectorItsCallersSend [
	"A constructor belongs to the class it builds, the way AeCairoExportSurface owns extent:to:,
	 so the class side of the inventory is satisfied by the surface family rather than by one
	 class. This is what the pattern family already does, for the same reason."

	self assert: VGCairoImageSurface answers: VGCairoInventory surfaceSelectors.
	VGCairoInventory surfaceClassSelectors do: [ :each |
		self
			assert: (VGCairoImageSurface withAllSubclasses anySatisfy: [ :one |
					 one class canUnderstand: each ])
			description: 'no surface class answers ' , each ]
]
