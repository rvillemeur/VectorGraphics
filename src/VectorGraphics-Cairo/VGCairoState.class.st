"
I am one entry of a context's state stack: the current transformation matrix, the source, the
fill rule and the clip. A context saves me by storing a copy and restores me by putting that copy
back, so all four come back together, which is what cairo_save and cairo_restore promise. The units
that implement the source, the fill rule and the clip set my fields; I only hold them.
"
Class {
	#name : 'VGCairoState',
	#superclass : 'VGCairoObject',
	#instVars : [
		'matrix',
		'source',
		'sourceMatrix',
		'fillRule',
		'clip',
		'strokeStyle',
		'tolerance',
		'antialias',
		'operator'
	],
	#category : 'VectorGraphics-Cairo-Context',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Context'
}

{ #category : 'converting' }
VGCairoState class >> antialiasFor: anObject [
	"One of my names, Cairo's integer code, or Alexandrie's own enumeration value."

	^ VGCairoStrokeStyle nameIn: self antialiasNames for: anObject
]

{ #category : 'accessing' }
VGCairoState class >> antialiasNames [
	"My names for Cairo's seven antialiasing modes, in the order of the CAIRO_ANTIALIAS
	 enumeration, so that an integer code indexes this list. Only #none changes what we draw: it
	 turns the sub-row sampling of the rasteriser into one sample at the centre of each pixel."

	^ #( #default #none #gray #subpixel #fast #good #best )
]

{ #category : 'accessing' }
VGCairoState class >> defaultTolerance [
	"Cairo's own default tolerance, in device units: a flattened curve stays within a tenth of a
	 pixel of the curve it approximates."

	^ 0.1
]

{ #category : 'constants' }
VGCairoState class >> minimumTolerance [
	"CAIRO_TOLERANCE_MINIMUM, one two hundred and fifty-sixth. Read from a live Cairo context,
	 which answers it back for a tolerance of zero and for a tolerance of minus one."

	^ 0.00390625
]

{ #category : 'accessing' }
VGCairoState >> antialias [
	^ antialias
]

{ #category : 'accessing' }
VGCairoState >> antialias: anAntialiasObject [
	"One of my class's names, Cairo's integer code or Alexandrie's own value."

	antialias := self class antialiasFor: anAntialiasObject
]

{ #category : 'accessing' }
VGCairoState >> clip [
	"The clip a fill is held to, or nil while the whole surface is the limit. A VGClip is
	 immutable - clipping one answers another - so a saved state and the state it was saved from
	 can share one and #postCopy has nothing to do for it."

	^ clip
]

{ #category : 'accessing' }
VGCairoState >> clip: aClip [
	clip := aClip
]

{ #category : 'accessing' }
VGCairoState >> fillRule [
	^ fillRule
]

{ #category : 'accessing' }
VGCairoState >> fillRule: aSymbol [
	fillRule := aSymbol
]

{ #category : 'initialization' }
VGCairoState >> initialize [
	"Cairo's own defaults: the identity matrix, a solid pattern of opaque black whose own
	 transformation is the identity, the winding fill rule, the stroke style of
	 VGCairoStrokeStyle, a tolerance of a tenth of a pixel, antialiasing left to the backend and
	 the source-over operator. Every one of them is measured against a live Cairo context in a
	 test."

	super initialize.
	matrix := VGCairoMatrix newIdentity.
	fillRule := #winding.
	source := VGCairoColorPattern r: 0.0 g: 0.0 b: 0.0 alpha: 1.0.
	sourceMatrix := VGCairoMatrix newIdentity.
	strokeStyle := VGCairoStrokeStyle new.
	tolerance := self class defaultTolerance.
	antialias := self class antialiasNames first.
	operator := VGCairoOperator over
]

{ #category : 'accessing' }
VGCairoState >> lineWidth [
	^ strokeStyle lineWidth
]

{ #category : 'accessing' }
VGCairoState >> lineWidth: aNumber [
	strokeStyle lineWidth: aNumber
]

{ #category : 'accessing' }
VGCairoState >> matrix [
	^ matrix
]

{ #category : 'accessing' }
VGCairoState >> matrix: aMatrix [
	matrix := aMatrix
]

{ #category : 'accessing' }
VGCairoState >> operator [
	^ operator
]

{ #category : 'accessing' }
VGCairoState >> operator: anOperator [
	operator := anOperator
]

{ #category : 'copying' }
VGCairoState >> postCopy [
	"My matrix is mutable and a context transforms it in place, and my stroke style is mutable
	 and a context sets its width and dash in place, so a saved state must hold its own of each.
	 My source matrix is a capture that no one transforms, but a copy costs nothing and keeps the
	 rule that a saved state shares no mutable part."

	super postCopy.
	matrix := matrix copy.
	sourceMatrix := sourceMatrix copy.
	strokeStyle := strokeStyle copy
]

{ #category : 'printing' }
VGCairoState >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(fillRule: ';
		nextPutAll: fillRule;
		nextPutAll: ' matrix: ';
		print: matrix;
		nextPut: $)
]

{ #category : 'accessing' }
VGCairoState >> source [
	^ source
]

{ #category : 'accessing' }
VGCairoState >> source: aSource [
	source := aSource
]

{ #category : 'accessing' }
VGCairoState >> sourceMatrix [
	"The transformation that was in force when the source was set. Measured: Cairo captures it
	 then and not when the source is used, so a scale applied afterwards does not move the
	 pattern."

	^ sourceMatrix
]

{ #category : 'accessing' }
VGCairoState >> sourceMatrix: aMatrix [
	sourceMatrix := aMatrix
]

{ #category : 'accessing' }
VGCairoState >> strokeStyle [
	"The width, cap, join, miter limit and dash a stroke of mine is widened with."

	^ strokeStyle
]

{ #category : 'accessing' }
VGCairoState >> tolerance [
	^ tolerance
]

{ #category : 'accessing' }
VGCairoState >> tolerance: aNumber [
	"Measured against a live Cairo context: a tolerance of zero or less is answered back as
	 Cairo's own minimum rather than refused, and the status stays clean."

	tolerance := aNumber max: self class minimumTolerance
]
