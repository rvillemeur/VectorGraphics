"
I hold the one-click examples for the path family: the builder that records the verbs, the immutable path it answers, and the flat edge array a path becomes when it crosses the backend boundary.

My examples rebuild their object on every call and assert nothing: open one from the browser and inspect the result. The Sub-paths and Edges tabs show what a fill will really be given.
"
Class {
	#name : 'VGPathExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples-Examples',
	#package : 'VectorGraphics-Cairo-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGPathExamples class >> builderMidCurve [
	<sampleInstance>
	"A builder with one finished run and a second still open, the second holding a cubic already
	 flattened to line segments. Inspecting it shows the current point and the tolerance that
	 decided how many segments the curve became."

	| builder |
	builder := VGPathBuilder new.
	builder
		moveTo: 4 @ 4;
		lineTo: 28 @ 4;
		closePath;
		moveTo: 6 @ 48;
		curveVia: 20 @ 4 via: 44 @ 60 to: 58 @ 16.
	^ builder
]

{ #category : 'examples' }
VGPathExamples class >> closedTriangleSubPath [
	<sampleInstance>
	"One run on its own, closed: the smallest thing a fill can be given."

	^ VGSubPath points: {
			  (8 @ 8).
			  (56 @ 16).
			  (24 @ 52) } closed: true
]

{ #category : 'examples' }
VGPathExamples class >> starPath [
	<sampleInstance>
	"A self-crossing five-pointed star, closed: the shape the two fill rules disagree about."

	| builder |
	builder := VGPathBuilder new.
	0 to: 4 do: [ :index |
		| angle point |
		angle := index * 4 * Float pi / 5 - (Float pi / 2).
		point := 32 @ 32 + (angle cos * 26 @ (angle sin * 26)).
		index isZero
			ifTrue: [ builder moveTo: point ]
			ifFalse: [ builder lineTo: point ] ].
	builder closePath.
	^ builder path
]

{ #category : 'examples' }
VGPathExamples class >> starSegmentsUnderTheEvenOddRule [
	<sampleInstance>
	"What the backend is really handed: a flat array of edge coordinates, with the fill rule
	 travelling inside it because the three messages of the boundary carry no rule of their own."

	^ self starPath segmentsWithFillRule: #evenOdd
]

{ #category : 'examples' }
VGPathExamples class >> subPathComingBackToItsStartSmoothly [
	<sampleInstance>
	"The run a full circle builds: its chords end where they began, and it carries the arc's own
	 tangents, so it passes through its first point with no corner there. That is the run whose
	 stroke needs a join in the seam rather than two caps."
	| surface context |
	surface := VGCairoImageSurface newFormat: VGCairoSurfaceFormat argb32 extent: 64 @ 64.
	context := surface newContext.
	context circleCenterX: 32 y: 32 radius: 20.
	^ context pathBuilder path subPaths first
]
