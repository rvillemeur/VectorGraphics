"
I hold the two buffers of `VectorEngineWholePixel` to the form it draws on, and the engine to the pixels it writes.

The alpha mask and the edge counts carry one entry per pixel of the target, so they are allocated from the form's extent and must be re-allocated when the engine is given another form: a buffer shorter than the form is a silent out-of-bounds in the inner loop. The test reads them with `instVarNamed:` because they are private to the engine and have no accessor, which is deliberate.

The other test strokes a line and asserts that some pixel of the target changed, which is the thinnest possible end-to-end fact about the whole-pixel engine: the coverage values themselves are held by the conformance corpus of the Cairo layer, where they can be compared against a reference rasteriser.
"
Class {
	#name : 'VectorEngineWholePixelTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Engine-Tests-Tests',
	#package : 'VectorGraphics-Engine-Tests',
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
