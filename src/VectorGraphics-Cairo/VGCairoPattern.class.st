"
I am the abstract replacement for AeCairoPattern: a source of colour other than a single flat colour.

My subclasses are VGCairoColorPattern, VGCairoLinearGradientPattern, VGCairoRadialGradientPattern and VGCairoSurfacePattern. Whatever the subclass, what reaches a backend is the frozen paint ABI of rule two: a tag, a block of thirty-two-bit floats, and for a gradient a two-hundred-and-fifty-six-entry stop lookup table. Nothing below the backend boundary knows I exist.

Unit 1.5 implements me.
"
Class {
	#name : 'VGCairoPattern',
	#superclass : 'VGCairoObject',
	#instVars : [
		'matrix',
		'paint'
	],
	#category : 'VectorGraphics-Cairo-Pattern',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Pattern'
}

{ #category : 'accessing' }
VGCairoPattern class >> paintClass [
	"The paint class that holds what a pattern of mine means to the backend."

	^ self subclassResponsibility
]

{ #category : 'accessing' }
VGCairoPattern >> extend [
	^ paint extend
]

{ #category : 'accessing' }
VGCairoPattern >> extend: anExtendMode [
	"One of my paint's names, Cairo's integer code or Alexandrie's own value."

	paint extend: anExtendMode
]

{ #category : 'accessing' }
VGCairoPattern >> filter [
	^ paint filter
]

{ #category : 'accessing' }
VGCairoPattern >> filter: aFilter [
	paint filter: aFilter
]

{ #category : 'initialization' }
VGCairoPattern >> initialize [
	super initialize.
	matrix := VGCairoMatrix newIdentity.
	paint := self class paintClass new
]

{ #category : 'inspector' }
VGCairoPattern >> inspectorPaint: aBuilder [

	<inspectorPresentationOrder: 20 title: 'Paint'>
	^ aBuilder newTable
		  items: self paintDescription;
		  addColumn: (SpStringTableColumn title: 'Property' evaluated: [ :each | each key ]);
		  addColumn:
			  (SpStringTableColumn title: 'Value' evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGCairoPattern >> inspectorPaintContext: aContext [

	aContext active: paint notNil
]

{ #category : 'testing' }
VGCairoPattern >> isSolid [
	"Whether I am one flat colour everywhere. Cairo asks this of a mask before it decides
	 whether to carry the mask's alpha on the paint instead of reading pixels."
	^ paint isSolid
]

{ #category : 'accessing' }
VGCairoPattern >> matrix [
	"A copy, because Cairo answers the numbers rather than the pattern's own matrix."
	^ matrix copy
]

{ #category : 'accessing' }
VGCairoPattern >> matrix: aMatrix [
	matrix := aMatrix copy
]

{ #category : 'accessing' }
VGCairoPattern >> paint [
	"The paint the backend reads. It is mine and not a copy, because Cairo keeps a reference to a
	 pattern and sees a change made to it after it has been set as a source."

	^ paint
]

{ #category : 'printing' }
VGCairoPattern >> paintDescription [
	"What I am, property by property, read back through the methods a caller uses, so a reader of
	 the Paint tab sees what the backend will see and not a second statement of it. The last entry
	 is the paint a fill records when no transformation is in force."

	^ {
		  ('type' -> self type).
		  ('tag' -> paint tag).
		  ('extend' -> self extend).
		  ('filter' -> self filter).
		  ('matrix' -> self matrix).
		  ('paint at an identity device matrix'
		   -> (self paintForDeviceMatrix: VGCairoMatrix newIdentity)) }
]

{ #category : 'converting' }
VGCairoPattern >> paintForDeviceMatrix: aMatrix [
	"A snapshot of my paint whose matrix maps a device point into paint space. A device point gets
	 there in two steps: back through the transformation that was in force when I was set as a
	 source, and then forward through my own matrix. A transformation that cannot be undone maps
	 nothing, and answers no paint at all."

	aMatrix isInvertible ifFalse: [ ^ nil ].
	^ paint copy
		  matrix: (matrix copy preMultiply: aMatrix inverted);
		  yourself
]

{ #category : 'accessing' }
VGCairoPattern >> type [
	"Cairo's own pattern type, by name. Alexandrie answers an AeCairoPatternType; a symbol is the
	 vocabulary on this side, as it already is for the extend mode and the filter."

	^ VGPaint nameIn: VGPaint typeNames for: paint tag
]
