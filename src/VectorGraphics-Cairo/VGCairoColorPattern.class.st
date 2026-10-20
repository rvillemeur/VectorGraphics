"
I am a VGCairoPattern holding a single colour, which Cairo models as a pattern so that every source is one kind of thing.

I answer the frozen paint ABI of rule two of VECTORCANVAS-PLAN.md, and unit 1.5 implements me.
"
Class {
	#name : 'VGCairoColorPattern',
	#superclass : 'VGCairoPattern',
	#category : 'VectorGraphics-Cairo-Pattern',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Pattern'
}

{ #category : 'instance creation' }
VGCairoColorPattern class >> newFrom: aColor [
	^ self
		  r: aColor red
		  g: aColor green
		  b: aColor blue
		  alpha: aColor alpha
]

{ #category : 'accessing' }
VGCairoColorPattern class >> paintClass [
	^ VGColorPaint
]

{ #category : 'instance creation' }
VGCairoColorPattern class >> r: red g: green b: blue [
	^ self r: red g: green b: blue alpha: 1.0
]

{ #category : 'instance creation' }
VGCairoColorPattern class >> r: red g: green b: blue alpha: alpha [
	^ (self new)
		  setRed: red green: green blue: blue alpha: alpha;
		  yourself
]

{ #category : 'accessing' }
VGCairoColorPattern >> alpha [
	"My one colour's alpha, which is the whole of me when I am used as a mask."
	^ (paint rgbaInPaintSpace: 0 @ 0) fourth
]

{ #category : 'initialization' }
VGCairoColorPattern >> setRed: red green: green blue: blue alpha: alpha [
	paint setRed: red green: green blue: blue alpha: alpha
]
