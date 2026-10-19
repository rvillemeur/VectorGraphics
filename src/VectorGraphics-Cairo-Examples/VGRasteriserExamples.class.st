"
I hold the one-click examples for the scan converter, which answers how much of each pixel a set of edges covers.

My examples rebuild their object on every call and assert nothing. The Coverage tab draws what the rasteriser really answers, one character per pixel, so the two fill rules can be compared on the same self-crossing shape.
"
Class {
	#name : 'VGRasteriserExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples-Examples',
	#package : 'VectorGraphics-Cairo-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGRasteriserExamples class >> rasteriserOnACircle [
	<sampleInstance>
	"A filled circle, the shape whose edge pixels show antialiasing most clearly."

	| builder count |
	builder := VGPathBuilder new.
	count := 64.
	0 to: count do: [ :index |
		| angle |
		angle := index * 2 * Float pi / count.
		builder lineTo: 32 @ 32 + (angle cos * 20 @ (angle sin * 20)) ].
	builder closePath.
	^ VGRasteriser
		  segments: builder path edgeCoordinates
		  fillRule: #winding
		  clip: (0 @ 0 corner: 64 @ 64)
]

{ #category : 'examples' }
VGRasteriserExamples class >> rasteriserOnAStarUnderTheEvenOddRule [
	<sampleInstance>
	"The self-crossing star read with the even-odd rule, which leaves its middle hollow. The same
	 edges under the winding rule fill it, which is what the Coverage tab makes visible."

	^ VGRasteriser
		  segments: VGPathExamples starPath edgeCoordinates
		  fillRule: #evenOdd
		  clip: (0 @ 0 corner: 64 @ 64)
]
