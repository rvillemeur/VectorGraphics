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
VGStrokerExamples class >> strokerOnADashedLine [
	<sampleInstance>
	"Nine on and four off along a line, started two into the cycle. Each painted run is a
	 sub-path of its own and carries its own pair of caps."

	| builder state |
	builder := VGPathBuilder new.
	builder
		moveTo: 6 @ 32;
		lineTo: 58 @ 32.
	state := VGCairoState new.
	state strokeStyle
		lineWidth: 6.0;
		dashPattern: #( 9 4 ) offset: 2.
	^ VGStroker path: builder path state: state
]

{ #category : 'examples' }
VGStrokerExamples class >> strokerOnAFlattenedCurve [
	<sampleInstance>
	"A wide stroke along a curve under the identity matrix: one quadrilateral per flattened
	 segment, with the default butt cap at each end and a miter join at every vertex between
	 them."

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

{ #category : 'examples' }
VGStrokerExamples class >> strokerWithABevelledSharpCorner [
	<sampleInstance>
	"A corner sharp enough to pass a miter limit of one and a quarter, so the join falls back to
	 the bevel. Ask the stroker whether its first corner is mitered and it answers false."

	| builder state |
	builder := VGPathBuilder new.
	builder
		moveTo: 8 @ 40;
		lineTo: 56 @ 44;
		lineTo: 8 @ 48.
	state := VGCairoState new.
	state strokeStyle
		lineWidth: 8.0;
		miterLimit: 1.25.
	^ VGStroker path: builder path state: state
]

{ #category : 'examples' }
VGStrokerExamples class >> strokerWithRoundCapsAndJoins [
	<sampleInstance>
	"A chevron under a round cap and a round join, the one pair that needs no orientation at
	 all: a disc serves at both ends and at the corner."

	| builder state |
	builder := VGPathBuilder new.
	builder
		moveTo: 10 @ 50;
		lineTo: 32 @ 12;
		lineTo: 54 @ 50.
	state := VGCairoState new.
	state strokeStyle
		lineWidth: 12.0;
		lineCap: #round;
		lineJoin: #round.
	^ VGStroker path: builder path state: state
]
