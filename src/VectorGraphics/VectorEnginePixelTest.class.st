Class {
	#name : 'VectorEnginePixelTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Tests',
	#package : 'VectorGraphics',
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
