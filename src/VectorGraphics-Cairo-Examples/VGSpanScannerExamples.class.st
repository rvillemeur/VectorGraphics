"
I hold the one-click examples for the span scanner, the scan conversion the rasteriser and the
clip share.

My examples rebuild their object on every call and assert nothing. The Spans tab lists the spans a
scanner answers on every sub-row of every pixel row its edges reach, which is where an aliased
scanner, answering whole pixels, parts from an antialiased one.
"
Class {
	#name : 'VGSpanScannerExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples-Examples',
	#package : 'VectorGraphics-Cairo-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGSpanScannerExamples class >> aliasedScannerOnATriangle [
	<sampleInstance>
	"The same scan conversion read with antialiasing off: every sub-row of a pixel row answers
	 the same whole pixels, which is how one sample at the pixel centre is reached."
	| builder |
	builder := VGPathBuilder new.
	builder
		moveTo: 6.5 @ 6.5;
		lineTo: 40.25 @ 12.75;
		lineTo: 12 @ 38;
		closePath.
	^ VGSpanScanner of:
		  (builder path segmentsWithFillRule: #winding antialias: #none)
]

{ #category : 'examples' }
VGSpanScannerExamples class >> scannerOnAStarUnderTheEvenOddRule [
	<sampleInstance>
	"A self-crossing shape, so the spans show where the even-odd rule leaves the heart hollow."
	| builder centre |
	builder := VGPathBuilder new.
	centre := 32 @ 32.
	builder moveTo: centre + (0 @ -26).
	1 to: 9 do: [ :index |
		| angle radius |
		angle := index * Float pi / 5.0.
		radius := index odd
			          ifTrue: [ 11 ]
			          ifFalse: [ 26 ].
		builder lineTo: centre + (angle sin * radius @ (angle cos * radius) negated) ].
	builder closePath.
	^ VGSpanScanner of: (builder path segmentsWithFillRule: #evenOdd)
]
