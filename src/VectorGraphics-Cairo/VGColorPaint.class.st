"
I am a single colour, the paint `sourceColor:` and `VGCairoColorPattern` build.

My coefficient block holds the colour unpremultiplied in fields 9 to 12, as red, green, blue and alpha in the range zero to one. My matrix is the identity and my extend mode and filter carry no meaning, because a colour is the same at every point.
"
Class {
	#name : 'VGColorPaint',
	#superclass : 'VGPaint',
	#category : 'VectorGraphics-Cairo-Paint',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Paint'
}

{ #category : 'instance creation' }
VGColorPaint class >> color: aColor [
	^ (self new) color: aColor; yourself
]

{ #category : 'constants' }
VGColorPaint class >> paintTag [
	^ 0
]

{ #category : 'instance creation' }
VGColorPaint class >> r: red g: green b: blue alpha: alpha [
	^ (self new)
		  setRed: red green: green blue: blue alpha: alpha;
		  yourself
]

{ #category : 'accessing' }
VGColorPaint >> color: aColor [
	self
		setRed: aColor red
		green: aColor green
		blue: aColor blue
		alpha: aColor alpha
]

{ #category : 'evaluating' }
VGColorPaint >> quantise: anArray in: aFormat [
	"A solid colour is the one paint Cairo converts once, into four sixteen-bit shorts, rather than
	 evaluating per pixel, and the shorts truncate where the byte rule rounds. Measured: it stores
	 16r7F3F1F5F for r 0.5 g 0.25 b 0.75 alpha 0.5, one short of what rounding writes."

	^ aFormat pixelForRgbaThroughShorts: anArray
]

{ #category : 'evaluating' }
VGColorPaint >> rgbaInPaintSpace: aPoint [
	"A colour is the same at every point, so the point is not read at all."

	^ {
		  (coefficients at: 9).
		  (coefficients at: 10).
		  (coefficients at: 11).
		  (coefficients at: 12) }
]

{ #category : 'initialization' }
VGColorPaint >> setRed: red green: green blue: blue alpha: alpha [
	"Stored unpremultiplied, in fields 9 to 12, because a gradient interpolates unpremultiplied
	 and a colour is a gradient of one stop. Four floats and not a Color: Cairo takes doubles, and
	 a Pharo Color would quantise a half to 127 of 255 on the way through."

	coefficients at: 9 put: red asFloat.
	coefficients at: 10 put: green asFloat.
	coefficients at: 11 put: blue asFloat.
	coefficients at: 12 put: alpha asFloat
]
