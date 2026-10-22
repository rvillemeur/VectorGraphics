"
I hold the one-click examples for the clip, the immutable shape a fill is cut down to.

My examples rebuild their object on every call and assert nothing. Each answers a clip of a
different kind, because a clip has three: the rectangle, which needs no scan conversion at all,
the shape, which carries its own fill rule and antialiasing mode, and the empty one two disjoint
shapes leave behind. The Passed tab of a clip draws what a fill through it would keep.
"
Class {
	#name : 'VGClipExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples-Examples',
	#package : 'VectorGraphics-Cairo-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGClipExamples class >> clipOfACircle [
	<sampleInstance>
	"A clip that keeps a shape, because its edges are not a rectangle. The shape carries the fill
	 rule and the antialiasing mode in force when the clip was made."
	| builder count |
	builder := VGPathBuilder new.
	count := 64.
	0 to: count do: [ :index |
		| angle |
		angle := index * 2 * Float pi / count.
		builder lineTo: 32 @ 32 + (angle cos * 20 @ (angle sin * 20)) ].
	builder closePath.
	^ (VGClip bounds: (0 @ 0 corner: 64 @ 64)) clippedBy:
		  (builder path segmentsWithFillRule: #winding)
]

{ #category : 'examples' }
VGClipExamples class >> emptyClipOfTwoDisjointRectangles [
	<sampleInstance>
	"Two clips that do not meet. The intersection has no area, so the clip is plainly empty and
	 a fill through it paints nothing."
	^ ((VGClip bounds: (0 @ 0 corner: 64 @ 64))
		   clippedBy: (VGSegments rectangle: (0 @ 0 corner: 20 @ 20)))
		  clippedBy: (VGSegments rectangle: (40 @ 40 corner: 60 @ 60))
]

{ #category : 'examples' }
VGClipExamples class >> maskSizedNarrowingOfACircularClip [
	<sampleInstance>
	"The clip of #clipOfACircle narrowed the way the backend narrows it for a mask the size of a
	 glyph: the same shape and the same coverage, and no pixel outside the rectangle the mask
	 covers. Every glyph of a run of text asks this of the clip it draws through."

	^ self clipOfACircle narrowedTo: (24 @ 24 corner: 40 @ 40)
]

{ #category : 'examples' }
VGClipExamples class >> rectangularClip [
	<sampleInstance>
	"The fast path: a clip whose shape is four axis-aligned edges keeps no shape at all, only
	 bounds, so a fill through it needs no second scan conversion."
	| builder |
	builder := VGPathBuilder new.
	builder
		moveTo: 8 @ 8;
		lineTo: 56 @ 8;
		lineTo: 56 @ 40;
		lineTo: 8 @ 40;
		closePath.
	^ (VGClip bounds: (0 @ 0 corner: 64 @ 64)) clippedBy:
		  (builder path segmentsWithFillRule: #winding)
]
