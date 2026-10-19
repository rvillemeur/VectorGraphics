"
I am one entry of a context's state stack: the current transformation matrix, the source, the
fill rule and the clip. A context saves me by storing a copy and restores me by putting that copy
back, so all four come back together, which is what cairo_save and cairo_restore promise. The units
that implement the source, the fill rule and the clip set my fields; I only hold them.
"
Class {
	#name : 'VGCairoState',
	#superclass : 'Object',
	#instVars : [
		'matrix',
		'source',
		'fillRule',
		'clip',
		'lineWidth'
	],
	#category : 'VectorGraphics-Cairo-Context',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Context'
}

{ #category : 'accessing' }
VGCairoState >> clip [
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
	"Cairo's own defaults: the identity matrix, opaque black, the winding fill rule and a line
	 width of two user-space units. The setters for the source and the line width arrive in units
	 1.5 and 1.4, so the defaults are what every drawing uses until then."

	super initialize.
	matrix := VGCairoMatrix newIdentity.
	fillRule := #winding.
	source := Color black.
	lineWidth := 2.0
]

{ #category : 'accessing' }
VGCairoState >> lineWidth [
	^ lineWidth
]

{ #category : 'accessing' }
VGCairoState >> lineWidth: aNumber [
	lineWidth := aNumber
]

{ #category : 'accessing' }
VGCairoState >> matrix [
	^ matrix
]

{ #category : 'accessing' }
VGCairoState >> matrix: aMatrix [
	matrix := aMatrix
]

{ #category : 'copying' }
VGCairoState >> postCopy [
	"My matrix is mutable and a context transforms it in place, so a saved state must hold its own."
	super postCopy.
	matrix := matrix copy
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
