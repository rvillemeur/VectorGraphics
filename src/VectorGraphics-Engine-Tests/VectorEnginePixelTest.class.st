"
I hold `VectorEnginePixel class >> computeStrokeRadii:antiAliasingWidth:`, the arithmetic that turns a stroke width and an anti-aliasing width into the four radii the inner loop compares a pixel against.

The dilated half is the outer edge of the stroke and the eroded half the inner one, each kept squared as well, because the loop compares squared distances and must not take a square root per pixel.

The case worth a test of its own is a stroke thinner than the anti-aliasing width, where the eroded half goes negative. The squared value then keeps the sign of the half it came from, so the comparison in the loop stays on the right side of zero; a plain squaring would make a hairline behave like a thick stroke with a hole in it.
"
Class {
	#name : 'VectorEnginePixelTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Engine-Tests-Tests',
	#package : 'VectorGraphics-Engine-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
VectorEnginePixelTest >> testComputeStrokeRadiiDilatedHalf [

	| radii |
	radii := VectorEnginePixel computeStrokeRadii: 4.0 antiAliasingWidth: 2.0.
	self assert: (radii at: #dilatedHalf) equals: 3.0.
	self assert: (radii at: #dilatedHalfSquared) equals: 9.0
]

{ #category : 'tests' }
VectorEnginePixelTest >> testComputeStrokeRadiiErodedHalfSquaredNegative [

	| radii erodedHalfSquared |
	radii := VectorEnginePixel computeStrokeRadii: 1.0 antiAliasingWidth: 3.0.
	erodedHalfSquared := radii at: #erodedHalfSquared.
	"erodedHalf = (1-3)*0.5 = -1.0, so sign = -1, result = 1.0 * -1 = -1.0"
	self assert: erodedHalfSquared equals: -1.0
]

{ #category : 'tests' }
VectorEnginePixelTest >> testComputeStrokeRadiiErodedHalfSquaredPositive [

	| radii erodedHalfSquared |
	radii := VectorEnginePixel computeStrokeRadii: 6.0 antiAliasingWidth: 2.0.
	erodedHalfSquared := radii at: #erodedHalfSquared.
	"erodedHalf = (6-2)*0.5 = 2.0, result = 2.0*2.0 * 1 = 4.0"
	self assert: erodedHalfSquared equals: 4.0
]
