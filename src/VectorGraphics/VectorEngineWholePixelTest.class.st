Class {
	#name : 'VectorEngineWholePixelTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Tests',
	#package : 'VectorGraphics',
	#tag : 'Tests'
}

{ #category : 'helpers' }
VectorEngineWholePixelTest >> engineOnForm: aForm [

	^ VectorEngineWholePixel onForm: aForm
]

{ #category : 'tests' }
VectorEngineWholePixelTest >> testAlphaMaskResizedWithForm [

	"alphaMask and edgeCounts must match form area."

	| form engine |
	form := Form extent: 20 @ 30 depth: 32.
	engine := self engineOnForm: form.
	self
		assert: (engine instVarNamed: 'alphaMask') size
		equals: 20 * 30.
	self
		assert: (engine instVarNamed: 'edgeCounts') size
		equals: 20 * 30
]

{ #category : 'tests' }
VectorEngineWholePixelTest >> testStrokeWritesNonZeroPixels [

	"Drawing a horizontal line must mark some pixels in the form."

	| form engine pixelsBefore pixelsAfter changed |
	form := Form extent: 50 @ 50 depth: 32.
	engine := self engineOnForm: form.
	pixelsBefore := form bits copy.
	engine
		strokeWidth: 3.0
		color: Color black
		do: [
			engine abs_MoveTo: 5 @ 25.
			engine abs_LineTo: 45 @ 25 ].
	pixelsAfter := form bits.
	changed := false.
	1 to: pixelsAfter size do: [ :i |
		(pixelsAfter at: i) ~= (pixelsBefore at: i) ifTrue: [ changed := true ] ].
	self assert: changed
]
