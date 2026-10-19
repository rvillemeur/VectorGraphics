"
I hold the one-click examples for the stroker, which widens a path into an area to fill.

My examples rebuild their object on every call and assert nothing. The pair of them shows the one fact about stroking that is easy to get wrong: the width is a user-space length, so the same path under an anisotropic scale comes out thicker along one axis.
"
Class {
	#name : 'VGStrokerExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples-Examples',
	#package : 'VectorGraphics-Cairo-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGStrokerExamples class >> strokerOnAFlattenedCurve [
	<sampleInstance>
	"A wide stroke along a curve under the identity matrix: one quadrilateral per flattened
	 segment, with a disc at every join."

	| builder |
	builder := VGPathBuilder new.
	builder
		moveTo: 6 @ 48;
		curveVia: 20 @ 4 via: 44 @ 60 to: 58 @ 16.
	^ VGStroker
		  path: builder path
		  matrix: VGCairoMatrix newIdentity
		  lineWidth: 6.0
]

{ #category : 'examples' }
VGStrokerExamples class >> strokerUnderAnAnisotropicScale [
	<sampleInstance>
	"The same straight line widened under a matrix that stretches one axis three times: the
	 outline is three times as tall as it is wide, because the width is measured in user space."

	| matrix builder |
	matrix := VGCairoMatrix newIdentity.
	matrix scaleByX: 1 y: 3.
	builder := VGPathBuilder new.
	builder
		moveTo: (matrix value: 4 @ 8);
		lineTo: (matrix value: 28 @ 8).
	^ VGStroker path: builder path matrix: matrix lineWidth: 2.0
]
