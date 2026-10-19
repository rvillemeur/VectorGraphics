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
VGSoftwareBackend >> blitSurface: aSurface at: aPoint paint: aPaint [
	"Unit 1.5 brings the surface paint, which is what a blit draws with."
	^ VGNotYetImplemented signalForSelector: #blitSurface:at:paint: unit: '1.5'
]

{ #category : 'accessing' }
VGSoftwareBackend >> commands [
	^ commands asArray
]

{ #category : 'private' }
VGSoftwareBackend >> compose: aPixel atX: x y: y operator: aSymbol into: aTarget [
	"The read is the primitive one: I am called from inside the surface's own flush, and the
	 public reader flushes before it answers, so reading through it here would recurse."

	aSymbol == #source
		ifTrue: [ aTarget primitivePixelAtX: x y: y put: aPixel ]
		ifFalse: [
			aTarget
				primitivePixelAtX: x
				y: y
				put: (aTarget format
						 blendPixel: aPixel
						 over: (aTarget primitivePixelAtX: x y: y)) ]
]

{ #category : 'draining' }
VGSoftwareBackend >> drainInto: aTarget [
	commands do: [ :each |
		self
			rasterise: (each at: 1)
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

{ #category : 'rasterising' }
VGSoftwareBackend >> rasterise: aSegments paint: aPaint clip: aRectangle operator: aSymbol into: aTarget [
	"One recorded fill: the rasteriser says how much of each pixel the edges cover, and the paint
	 is composited over the target at that coverage. The fill rule and the antialiasing mode both
	 ride inside the segments, because the three messages of the backend carry neither. A paint
	 that lays down nothing at a pixel leaves that pixel alone, which is how an extend mode of
	 none paints outside its own pattern. Unit 1.7 brings the operators other than over and
	 source."

	| rasteriser format |
	format := aTarget format.
	rasteriser := VGRasteriser
		              segments: aSegments coordinates
		              fillRule: aSegments fillRule
		              antialias: aSegments antialias
		              clip: aRectangle.
	rasteriser coverageRowsDo: [ :y :coverage :left |
		1 to: coverage size do: [ :index |
			| value pixel x |
			value := coverage at: index.
			value > 0 ifTrue: [
				x := left + index - 1.
				pixel := aPaint
					         pixelIn: format
					         atX: x
					         y: y
					         coverage: value.
				pixel ifNotNil: [
					self
						compose: pixel
						atX: x
						y: y
						operator: aSymbol
						into: aTarget ] ] ] ]
]
