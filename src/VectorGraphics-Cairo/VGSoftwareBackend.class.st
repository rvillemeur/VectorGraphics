"
I draw a recorded frame in Pharo, with no library under me.

I take the entries of a display list, keep them until the frame is drained, and then rasterise each
one into the target surface in the order it was recorded. VGRasteriser turns edges and a fill rule
into coverage, and I composite the paint over the target at that coverage with the surface format's
own pixel arithmetic, so a pixel of mine agrees with Cairo's byte for byte wherever the coverage
agrees.
I am the failover path and the oracle for phase 2, so I must never need a device, a library or a
window.
"
Class {
	#name : 'VGSoftwareBackend',
	#superclass : 'VGBackend',
	#instVars : [
		'commands'
	],
	#category : 'VectorGraphics-Cairo-Backend',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Backend'
}

{ #category : 'drawing' }
VGSoftwareBackend >> blitSurface: aSurface at: aPoint paint: aPaint clip: aClip operator: anOperator [
	"Recorded, not drawn, like a fill. The surface is the mask: its alpha channel says how much
	 of the paint reaches each pixel and its colours are never read, which is Cairo's
	 cairo_mask_surface. Every other mask pattern is rendered into a surface by the context
	 before it arrives here, so this one message covers them all and a Vulkan backend has a
	 texture to bind."
	commands add: {
			(VGCairoSurfaceMask surface: aSurface at: aPoint).
			aPaint.
			aClip.
			anOperator }
]

{ #category : 'accessing' }
VGSoftwareBackend >> commands [
	^ commands asArray
]

{ #category : 'compositing' }
VGSoftwareBackend >> compose: aPixel mask: aMaskByte atX: x y: y operator: anOperator into: aTarget [
	"The read is the primitive one: I am called from inside the surface's own flush, and the
	 public reader flushes before it answers, so reading through it here would recurse. The mask
	 is the coverage of the pixel, and the operator decides what the coverage means: most of them
	 read it as a scaling of the source, while clear and source mix with the destination."

	| format |
	format := aTarget format.
	aTarget
		primitivePixelAtX: x
		y: y
		put: (anOperator
				 composeSource: aPixel
				 mask: aMaskByte
				 over: (aTarget primitivePixelAtX: x y: y)
				 in: format)
]

{ #category : 'drawing' }
VGSoftwareBackend >> drainInto: aTarget [
	"Each command says itself whether it is a fill or a mask, because the first slot holds the
	 shape and the shape knows."
	commands do: [ :each |
		(each at: 1)
			drawOn: self
			paint: (each at: 2)
			clip: (each at: 3)
			operator: (each at: 4)
			into: aTarget ].
	commands := OrderedCollection new
]

{ #category : 'drawing' }
VGSoftwareBackend >> fillSegments: aSegments paint: aPaint clip: aRectangle operator: aSymbol [
	"Recorded, not drawn: a pixel is written when the frame is drained and not before, so that the
	 whole frame is known before the first one moves."
	aSegments isEmpty ifTrue: [ ^ self ].
	commands add: {
			aSegments.
			aPaint.
			aRectangle.
			aSymbol }
]

{ #category : 'initialization' }
VGSoftwareBackend >> initialize [
	super initialize.
	commands := OrderedCollection new
]

{ #category : 'inspector' }
VGSoftwareBackend >> inspectorRecordedCommands: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Recorded commands'>
	"The fills waiting for a drain, in the order they will be rasterised. Reading them does not
	 drain them, so the frame is still intact after a look."

	^ aBuilder newTable
		  items: (1 to: commands size) asArray;
		  addColumn: (SpStringTableColumn
				   title: 'Order'
				   evaluated: [ :index | index printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Edges'
				   evaluated: [ :index | ((commands at: index) at: 1) size printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Fill rule'
				   evaluated: [ :index | ((commands at: index) at: 1) fillRule printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Paint'
				   evaluated: [ :index | ((commands at: index) at: 2) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Clip'
				   evaluated: [ :index | ((commands at: index) at: 3) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Operator'
				   evaluated: [ :index | ((commands at: index) at: 4) printString ]);
		  yourself
]

{ #category : 'inspector' }
VGSoftwareBackend >> inspectorRecordedCommandsContext: aContext [
	aContext active: commands notNil
]

{ #category : 'accessing' }
VGSoftwareBackend >> isEmpty [
	^ commands isEmpty
]

{ #category : 'drawing' }
VGSoftwareBackend >> maskWith: aMask paint: aPaint clip: aClip operator: anOperator into: aTarget [
	"One recorded mask: the mask's alpha stands where a fill's coverage stands, scaled by the
	 coverage of the clip. A mask carries no spans, so a clip cannot meet it the way it meets a
	 fill; Cairo multiplies the coverage of the clip into the mask instead, which keeps the rim of
	 the clip shaded. The whole clip is visited and not only the mask's own rectangle, because an
	 unbounded operator writes where the mask covers nothing; under a bounded one a mask byte of
	 zero leaves the destination exactly as it was, so visiting those pixels changes nothing. A
	 pixel the clip allows nothing of is left alone under every operator."

	| format unbounded |
	format := aTarget format.
	unbounded := anOperator isUnbounded.
	aClip coverageRowsDo: [ :y :coverage :left |
		1 to: coverage size do: [ :index |
			| mask source x allowed |
			allowed := coverage at: index.
			x := left + index - 1.
			allowed > 0 ifTrue: [
				mask := format
					        scaleByte: (aMask alphaAtX: x y: y)
					        by: (format maskByteForCoverage: allowed).
				source := mask > 0
					          ifTrue: [
					          anOperator sourceFromPaint: aPaint in: format atX: x y: y ]
					          ifFalse: [ nil ].
				source ifNil: [ mask := 0 ].
				(source notNil or: [ unbounded ]) ifTrue: [
					self
						compose: (source ifNil: [ 0 ])
						mask: mask
						atX: x
						y: y
						operator: anOperator
						into: aTarget ] ] ] ]
]

{ #category : 'private' }
VGSoftwareBackend >> rasterise: aSegments paint: aPaint clip: aClip operator: anOperator into: aTarget [
	"One recorded fill: the rasteriser says how much of each pixel the edges cover inside the
	 clip, and the paint is composited there with the operator in force. The fill rule, the
	 antialiasing mode and the constant alpha all ride inside the segments, because the three
	 messages of the backend carry none of them, and the clip carries its own. The operator
	 reads the paint rather than the paint being read for it, because eight of the operators
	 composite in floating point and want the source at the paint's own precision. A paint that
	 lays down nothing at a pixel leaves that pixel alone, which is how an extend mode of none
	 paints outside its own pattern, unless the operator is unbounded: those write where no
	 source covers, so they run over the whole clip and the pixels the shape misses are swept
	 afterwards."
	| rasteriser format unbounded written alphaByte |
	format := aTarget format.
	unbounded := anOperator isUnbounded.
	written := unbounded ifTrue: [ Set new ] ifFalse: [ nil ].
	alphaByte := format shortByteOf: aSegments alpha.
	rasteriser := VGRasteriser
		              segments: aSegments coordinates
		              fillRule: aSegments fillRule
		              antialias: aSegments antialias
		              clip: aClip.
	rasteriser coverageRowsDo: [ :y :coverage :left |
		1 to: coverage size do: [ :index |
			| mask source x |
			mask := format
				        scaleByte: (format maskByteForCoverage: (coverage at: index))
				        by: alphaByte.
			x := left + index - 1.
			source := mask > 0
				          ifTrue: [ anOperator sourceFromPaint: aPaint in: format atX: x y: y ]
				          ifFalse: [ nil ].
			source ifNil: [ mask := 0 ].
			(source notNil or: [ unbounded ]) ifTrue: [
				unbounded ifTrue: [ written add: x @ y ].
				self
					compose: (source ifNil: [ 0 ])
					mask: mask
					atX: x
					y: y
					operator: anOperator
					into: aTarget ] ] ].
	unbounded ifFalse: [ ^ self ].
	self
		sweep: aClip
		withoutSourceUnder: anOperator
		skipping: written
		into: aTarget
]

{ #category : 'compositing' }
VGSoftwareBackend >> sweep: aClip withoutSourceUnder: anOperator skipping: aSetOfPoints into: aTarget [
	"An unbounded operator writes something where the source covers nothing, so Cairo runs it
	 over the whole clip and not only over the shape. Measured on a live Cairo context: the
	 pixels of the clip the shape misses come out as a source of nothing leaves them, and
	 nothing outside the clip is touched at all."

	| extents |
	extents := aClip extents.
	extents top to: extents bottom - 1 do: [ :y |
		aClip
			pixelsInRowAt: y
			from: extents left
			to: extents right
			do: [ :x |
				(aSetOfPoints includes: x @ y) ifFalse: [
					self
						compose: 0
						mask: 0
						atX: x
						y: y
						operator: anOperator
						into: aTarget ] ] ]
]
