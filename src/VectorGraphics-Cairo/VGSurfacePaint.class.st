"
I am another surface used as paint, which is what `sourceSurface:` and `VGCairoSurfacePattern` build.

The surface itself is not a float and so does not live in the coefficient block: it rides beside it, in my `surface` slot, and a phase 2 backend binds it as an image instead. Fields 9 and 10 of the block are its extent, which is what the extend mode is applied to.

My default extend mode is `#none`, not `#pad`, which is the one place a surface pattern and a gradient disagree, and it is Cairo's own default.
"
Class {
	#name : 'VGSurfacePaint',
	#superclass : 'VGPaint',
	#instVars : [
		'surface'
	],
	#category : 'VectorGraphics-Cairo-Paint',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Paint'
}

{ #category : 'constants' }
VGSurfacePaint class >> defaultExtend [
	"Cairo's default for a surface pattern is none, not the pad a gradient gets."

	^ #none
]

{ #category : 'constants' }
VGSurfacePaint class >> paintTag [
	^ 1
]

{ #category : 'instance creation' }
VGSurfacePaint class >> surface: aSurface [
	^ (self new) surface: aSurface; yourself
]

{ #category : 'inspector' }
VGSurfacePaint >> inspectorExtend: aBuilder [
	<inspectorPresentationOrder: 21 title: 'Extend'>
	| width |
	width := (coefficients at: self class surfaceWidthFieldIndex) rounded.
	^ aBuilder newTable
		  items: (-4 to: width * 2 + 3);
		  addColumn: (SpStringTableColumn title: 'x' evaluated: [ :each | each printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Reads pixel'
				   evaluated: [ :each |
					   (self sample: each along: width)
						   ifNil: [ 'nothing painted' ]
						   ifNotNil: [ :index | index printString ] ]);
		  addColumn: (SpStringTableColumn
				   title: 'Channels at y nought'
				   evaluated: [ :each |
					   (self rgbaAtX: each + 0.5 y: 0.5)
						   ifNil: [ '' ]
						   ifNotNil: [ :channels |
							   (channels collect: [ :channel | (channel * 255) rounded ])
								   printString ] ]);
		  yourself
]

{ #category : 'inspector' }
VGSurfacePaint >> inspectorExtendContext: aContext [

	aContext active: surface notNil
]

{ #category : 'evaluating' }
VGSurfacePaint >> rgbaInPaintSpace: aPoint [
	"Every filter samples the nearest pixel in this unit. Measured against live Cairo, the good,
	 best and nearest filters answer the same pixels at one to one, which is what the corpus draws;
	 a scaled surface pattern needs the real sampling rules and waits for the unit that scales one."

	| x y |
	x := self
		     sample: aPoint x floor
		     along: (coefficients at: self class surfaceWidthFieldIndex) rounded.
	x ifNil: [ ^ nil ].
	y := self
		     sample: aPoint y floor
		     along: (coefficients at: self class surfaceHeightFieldIndex) rounded.
	y ifNil: [ ^ nil ].
	^ surface format rgbaForPixel: (surface pixelAtX: x y: y)
]

{ #category : 'evaluating' }
VGSurfacePaint >> sample: anIndex along: anExtent [
	"The pixel index that index reads along one axis of a surface of that extent, under my extend
	 mode, or nil where the mode leaves the surface unpainted. A surface of no extent has no pixel
	 to read whatever the mode says."

	| folded |
	anExtent <= 0 ifTrue: [ ^ nil ].
	(anIndex between: 0 and: anExtent - 1) ifTrue: [ ^ anIndex ].
	self extend = #none ifTrue: [ ^ nil ].
	self extend = #pad ifTrue: [ ^ (anIndex max: 0) min: anExtent - 1 ].
	self extend = #repeat ifTrue: [ ^ anIndex \\ anExtent ].
	folded := anIndex \\ (2 * anExtent).
	^ folded < anExtent
		  ifTrue: [ folded ]
		  ifFalse: [ 2 * anExtent - 1 - folded ]
]

{ #category : 'accessing' }
VGSurfacePaint >> surface [
	^ surface
]

{ #category : 'accessing' }
VGSurfacePaint >> surface: aSurface [
	"The surface rides beside the block, because it is not a float. Its extent does go in the
	 block, in the two fields the ABI names for it, because that is what the extend mode is
	 applied to."

	surface := aSurface.
	coefficients
		at: self class surfaceWidthFieldIndex
		put: aSurface width asFloat.
	coefficients
		at: self class surfaceHeightFieldIndex
		put: aSurface height asFloat
]
