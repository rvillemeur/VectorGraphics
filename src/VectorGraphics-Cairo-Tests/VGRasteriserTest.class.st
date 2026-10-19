"
I test the software scan converter: how much of each pixel a set of edges covers.

Coverage is what a fill rule and an antialiased edge both come down to, so the facts here are about
numbers rather than pixels: an aligned rectangle covers whole pixels, a half-pixel column covers
half of one, the coverage of a circle sums to its area, and a self-crossing path is hollow under the
even-odd rule and solid under the winding rule.
The rasteriser is exact across a pixel and samples down the pixel, which is where its stated
accuracy comes from.
"
Class {
	#name : 'VGRasteriserTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Cairo-Tests-Tests',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Tests'
}

{ #category : 'support' }
VGRasteriserTest >> circleOfRadius: aNumber center: aPoint [
	^ (0 to: 719) collect: [ :index |
		  | angle |
		  angle := index * 2 * Float pi / 720.
		  aPoint + (angle cos * aNumber @ (angle sin * aNumber)) ]
]

{ #category : 'support' }
VGRasteriserTest >> coverageOf: aPointArray rule: aSymbol [
	"The whole coverage grid as a Dictionary from point to coverage, which is what makes a fact
	 about one pixel readable in a test."
	^ self coverageOfAll: { aPointArray } rule: aSymbol
]

{ #category : 'support' }
VGRasteriserTest >> coverageOfAll: aCollectionOfPointArrays rule: aSymbol [
	| grid rasteriser |
	grid := Dictionary new.
	rasteriser := VGRasteriser
		              segments: (self segmentsOfAll: aCollectionOfPointArrays)
		              fillRule: aSymbol
		              clip: (0 @ 0 corner: 64 @ 64).
	rasteriser coverageRowsDo: [ :y :coverage :left |
		1 to: coverage size do: [ :index |
			| value |
			value := coverage at: index.
			value isZero ifFalse: [ grid at: left + index - 1 @ y put: value ] ] ].
	^ grid
]

{ #category : 'support' }
VGRasteriserTest >> fivePointedStarOfRadius: aNumber center: aPoint [
	"The points taken two apart, which is what makes the star one self-crossing path with a
	 pentagon inside it rather than five triangles."
	^ (0 to: 4) collect: [ :index |
		  | angle |
		  angle := index * 4 * Float pi / 5 - (Float pi / 2).
		  aPoint + (angle cos * aNumber @ (angle sin * aNumber)) ]
]

{ #category : 'support' }
VGRasteriserTest >> segmentsOfAll: aCollectionOfPointArrays [
	| stream |
	stream := WriteStream on: (Array new: 64).
	aCollectionOfPointArrays do: [ :points |
		1 to: points size do: [ :index |
			| from to |
			from := points at: index.
			to := points at: (index \\ points size) + 1.
			stream
				nextPut: from x asFloat;
				nextPut: from y asFloat;
				nextPut: to x asFloat;
				nextPut: to y asFloat ] ].
	^ stream contents
]

{ #category : 'tests - coverage' }
VGRasteriserTest >> testAHalfPixelColumnIsCoveredExactlyInHalf [
	"Coverage across a pixel is exact, because a span contributes the part of the pixel it really
	 covers rather than a sample of it."
	| grid |
	grid := self coverageOf: { 4 @ 4. 4.5 @ 4. 4.5 @ 6. 4 @ 6 } rule: #winding.
	self assert: ((grid at: 4 @ 4) - 0.5) abs < 1.0e-9.
	self assert: ((grid at: 4 @ 5) - 0.5) abs < 1.0e-9
]

{ #category : 'tests - coverage' }
VGRasteriserTest >> testAHalfPixelRowIsCoveredWithinOneSubRow [
	"Coverage down a pixel is sampled, one sample per sub-row, so a horizontal edge inside a row is
	 placed to within one sub-row and no closer. That is the rasteriser's stated accuracy."
	| grid error |
	grid := self coverageOf: { 4 @ 4. 6 @ 4. 6 @ 4.5. 4 @ 4.5 } rule: #winding.
	error := 1 / VGRasteriser samplesPerPixelRow.
	self assert: ((grid at: 4 @ 4) - 0.5) abs <= error.
	self assert: ((grid at: 5 @ 4) - 0.5) abs <= error
]

{ #category : 'tests - fill rules' }
VGRasteriserTest >> testASelfCrossingStarIsSolidUnderWindingAndHollowUnderEvenOdd [
	| star winding evenOdd |
	star := self fivePointedStarOfRadius: 24 center: 32 @ 32.
	winding := self coverageOf: star rule: #winding.
	evenOdd := self coverageOf: star rule: #evenOdd.
	self assert: (winding at: 32 @ 32) equals: 1.
	self assert: (evenOdd at: 32 @ 32 ifAbsent: [ 0 ]) equals: 0.
	self assert: (winding at: 32 @ 20) equals: 1.
	self assert: (evenOdd at: 32 @ 20) equals: 1
]

{ #category : 'tests - coverage' }
VGRasteriserTest >> testAnAlignedRectangleCoversWholePixelsAndNothingOutside [
	| grid |
	grid := self coverageOf: { 4 @ 4. 12 @ 4. 12 @ 9. 4 @ 9 } rule: #winding.
	self assert: (grid at: 4 @ 4) equals: 1.
	self assert: (grid at: 11 @ 8) equals: 1.
	self assert: (grid at: 12 @ 4 ifAbsent: [ 0 ]) equals: 0.
	self assert: (grid at: 3 @ 4 ifAbsent: [ 0 ]) equals: 0.
	self assert: grid size equals: 8 * 5
]

{ #category : 'tests - coverage' }
VGRasteriserTest >> testNothingOutsideTheClipIsEverVisited [
	| rasteriser rows |
	rasteriser := VGRasteriser
		              segments: (self segmentsOfAll: { { 0 @ 0. 64 @ 0. 64 @ 64. 0 @ 64 } })
		              fillRule: #winding
		              clip: (10 @ 20 corner: 14 @ 23).
	rows := OrderedCollection new.
	rasteriser coverageRowsDo: [ :y :coverage :left |
		rows add: y.
		self assert: left equals: 10.
		self assert: coverage size equals: 4 ].
	self assert: rows asArray equals: #( 20 21 22 )
]

{ #category : 'tests - coverage' }
VGRasteriserTest >> testTheCoverageOfACircleSumsToItsArea [
	| grid total expected |
	grid := self coverageOf: (self circleOfRadius: 20 center: 32 @ 32) rule: #winding.
	total := grid values inject: 0 into: [ :sum :each | sum + each ].
	expected := Float pi * 20 * 20.
	self assert: (total - expected) abs / expected < 0.01
]

{ #category : 'tests - fill rules' }
VGRasteriserTest >> testTheWindingRuleFillsANestedSquareAndTheEvenOddRuleLeavesItHollow [
	| outer inner winding evenOdd |
	outer := { 8 @ 8. 40 @ 8. 40 @ 40. 8 @ 40 }.
	inner := { 16 @ 16. 32 @ 16. 32 @ 32. 16 @ 32 }.
	winding := self coverageOfAll: { outer. inner } rule: #winding.
	evenOdd := self coverageOfAll: { outer. inner } rule: #evenOdd.
	self assert: (winding at: 24 @ 24) equals: 1.
	self assert: (evenOdd at: 24 @ 24 ifAbsent: [ 0 ]) equals: 0.
	self assert: (winding at: 12 @ 24) equals: 1.
	self assert: (evenOdd at: 12 @ 24) equals: 1
]
