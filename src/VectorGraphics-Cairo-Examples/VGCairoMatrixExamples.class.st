"
I hold the matrix examples: one affine transformation built the way a drawing builds it, and one that collapses the plane so no inverse exists.
Every example answers a fresh VGCairoMatrix, so an inspector view or a test can transform what it
got without disturbing anything else.
"
Class {
	#name : 'VGCairoMatrixExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples-Examples',
	#package : 'VectorGraphics-Cairo-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGCairoMatrixExamples class >> rotatedAndShearedMatrix [
	<sampleInstance>
	"The transformation a drawing builds when it moves to a place, turns and then stretches the
	 axes by different amounts, which is the shear the inspector view makes visible."
	^ VGCairoMatrix newIdentity
		  translateByX: 12 y: -5;
		  rotateByRadians: Float pi / 7;
		  scaleByX: 2 y: 3;
		  yourself
]

{ #category : 'examples' }
VGCairoMatrixExamples class >> singularMatrix [
	<sampleInstance>
	"Both axes land on the same line, so the determinant is zero, #invert answers an error status
	 and a context given this matrix draws nothing."
	^ VGCairoMatrix newX: 0 y: 0 sx: 2 sy: 2 shx: 1 shy: 4
]
