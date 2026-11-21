"
I am an affine transformation, in the six numbers and the field names Cairo uses: a point is
mapped to (sx * x + shx * y + x) @ (shy * x + sy * y + y). Cairo's composition order is mine:
#translateBy:, #scaleBy: and #rotateByRadians: build a transformation that acts first and is then
followed by what I already held, which is why #translateBy: on a scaling matrix moves by the scaled
distance. #invert answers a status rather than signalling when I am singular, as Cairo does, and
#inverted signals, as Alexandrie's does. Six numbers decide my equality.
"
Class {
	#name : 'VGCairoMatrix',
	#superclass : 'Object',
	#instVars : [
		'sx',
		'shy',
		'shx',
		'sy',
		'x',
		'y'
	],
	#category : 'VectorGraphics-Canvas-Matrix',
	#package : 'VectorGraphics-Canvas',
	#tag : 'Matrix'
}

{ #category : '*VectorGraphics-Canvas' }
VGCairoMatrix >> invert [
	"Cairo answers a status rather than signalling, because a singular matrix is something a caller
	 is expected to handle: the drawing it would have produced is empty."

	"An extension on VGCairoMatrix, which the geometry package holds: the status this answers is a
	 class of VectorGraphics-Canvas, so the method stays here and the geometry leaf names nothing.
	 Alexandrie''s classes are the reason the project extends rather than edits; here the reason is
	 the layering."

	| det adjointX adjointY |

	self isInvertible ifFalse: [ ^ VGCairoStatus invalidMatrix ].
	det := self determinant.
	adjointX := shx * y - (sy * x).
	adjointY := shy * x - (sx * y).
	self
		beX: adjointX / det
		y: adjointY / det
		sx: sy / det
		sy: sx / det
		shx: shx negated / det
		shy: shy negated / det.
	^ VGCairoStatus success
]

{ #category : '*VectorGraphics-Canvas' }
VGCairoMatrix >> inverted [
	"An inverted copy, or an error, which is what Alexandrie''s #inverted does."

	"An extension on VGCairoMatrix for the same reason as #invert: it reads the status that method
	 answers, and that class belongs to VectorGraphics-Canvas."

	| inverse |

	inverse := self copy.
	inverse invert ensureIsSuccess.
	^ inverse
]
