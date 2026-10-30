"
I am a mask the backend reads in device space: a surface whose alpha channel says how much of the paint reaches each pixel, and the device point my top left corner sits at.

I am what the backend's blit message carries, so I stand where VGSegments stands for a fill, and like the segments I answer the backend's drawing message myself. A pixel outside me is no mask at all, which is Cairo's extend mode of none and leaves the destination alone under a bounded operator.

The context renders every mask pattern that is not one flat colour into a surface before building me, so I never have to sample a transformed pattern: a lookup of the nearest pixel is all I do. A flat colour never reaches me, because Cairo folds that alpha into the paint or carries it as a constant mask on the segments instead.
"
Class {
	#name : 'VGCairoSurfaceMask',
	#superclass : 'Object',
	#instVars : [
		'surface',
		'origin'
	],
	#category : 'VectorGraphics-Cairo-Display list',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Display list'
}

{ #category : 'instance creation' }
VGCairoSurfaceMask class >> surface: aSurface at: aPoint [
	^ self new
		  setSurface: aSurface origin: aPoint;
		  yourself
]

{ #category : 'accessing' }
VGCairoSurfaceMask >> alphaAtX: x y: y [
	"How much of the paint reaches the device pixel x, y: nothing at all outside me, which is
	 Cairo's extend mode of none."
	| point |
	point := x @ y - origin rounded.
	(point x between: 0 and: surface width - 1) ifFalse: [ ^ 0 ].
	(point y between: 0 and: surface height - 1) ifFalse: [ ^ 0 ].
	^ surface format alphaOfPixel: (surface pixelAtX: point x y: point y)
]

{ #category : 'reading' }
VGCairoSurfaceMask >> alphaBytesOver: aRectangle [
	"The alpha of every pixel of that rectangle, row by row from the top left, as one run. Byte
	 for byte what alphaAtX:y: gives pixel by pixel, which VGCairoDrawingTest holds me to; what
	 does not change from pixel to pixel is done once here instead. The frame is drained once, my
	 origin is rounded once, a row that lies off my surface is stepped over rather than asked
	 column by column, and the columns of a row that do lie on it are read as one run and copied
	 into place by the primitive. A run is as many pixels as the clip of a blit is wide times as
	 many as it is high, so the reference frame of unit 3.5 reads a quarter of a million of them
	 a frame."

	| bytes index width height shift first last start |
	bytes := ByteArray new: aRectangle width * aRectangle height.
	surface flush.
	width := surface width.
	height := surface height.
	shift := origin rounded.
	first := (aRectangle left - shift x) max: 0.
	last := (aRectangle right - 1 - shift x) min: width - 1.
	start := first + shift x - aRectangle left + 1.
	index := 0.
	aRectangle top to: aRectangle bottom - 1 do: [ :y |
		| row |
		row := y - shift y.
		((row between: 0 and: height - 1) and: [ first <= last ]) ifTrue: [
			bytes
				replaceFrom: index + start
				to: index + start + (last - first)
				with: (surface alphaBytesOfRow: row from: first to: last)
				startingAt: 1 ].
		index := index + aRectangle width ].
	^ bytes
]

{ #category : 'accessing' }
VGCairoSurfaceMask >> boundsRectangle [
	"The device rectangle I cover. A fractional origin lands on the nearest pixel, which is the
	 sampling this phase does everywhere; a filtered mask waits for the unit that scales a
	 pattern."
	^ origin rounded extent: surface extent
]

{ #category : 'drawing' }
VGCairoSurfaceMask >> drawOn: aBackend paint: aPaint clip: aClip operator: anOperator into: aTarget [
	"A recorded command names what it is by answering this: I am a mask, so the backend reads my
	 alpha instead of rasterising edges."
	aBackend
		maskWith: self
		paint: aPaint
		clip: aClip
		operator: anOperator
		into: aTarget
]

{ #category : 'inspecting' }
VGCairoSurfaceMask >> inspectorAlphaRun: aBuilder [
	<inspectorPresentationOrder: 11 title: 'Alpha run'>
	"The run of bytes the tiled rasteriser reads out of me in one go, sampled against the single
	 pixel reader beside it. The rectangle is mine grown by one pixel on each side, so the rows
	 and columns outside me are in the run as well, where a mask of Cairo's extend mode of none
	 lets nothing through. Each row asks both methods, so a run that stopped agreeing with the
	 reader would show as two different bytes rather than go unseen."

	| rectangle bytes points |
	rectangle := self boundsRectangle expandBy: 1.
	bytes := self alphaBytesOver: rectangle.
	points := OrderedCollection new.
	rectangle top to: rectangle bottom - 1 do: [ :y |
		rectangle left to: rectangle right - 1 do: [ :x | points add: x @ y ] ].
	^ aBuilder newTable
		  items: points asArray;
		  addColumn: (SpStringTableColumn title: 'Point' evaluated: [ :each |
					   each printString ]);
		  addColumn: (SpStringTableColumn title: 'In the run' evaluated: [ :each |
					   (bytes at:
						    (each y - rectangle top) * rectangle width + (each x - rectangle left)
						    + 1) printString ]);
		  addColumn: (SpStringTableColumn title: 'Read one by one' evaluated: [ :each |
					   (self alphaAtX: each x y: each y) printString ]);
		  yourself
]

{ #category : 'inspecting' }
VGCairoSurfaceMask >> inspectorAlphaRunContext: aContext [
	"A mask with no surface has no alpha to read."

	aContext active: surface isNotNil
]

{ #category : 'inspector' }
VGCairoSurfaceMask >> inspectorMask: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Mask'>
	"How much paint I let through, asked of the very method the backend asks, so that what is
	 shown cannot drift from the rule: a point in each half of my own rectangle, my centre, and a
	 point just outside me, where a mask of Cairo's extend mode of none lets nothing through."
	| bounds quarter |
	bounds := self boundsRectangle.
	quarter := bounds extent // 4.
	^ aBuilder newTable
		  items: {
				  ('Left half' -> (bounds origin + quarter)).
				  ('Right half'
				   -> (bounds origin + ((quarter x * 3) @ quarter y))).
				  ('Centre' -> bounds center).
				  ('Just outside' -> bounds corner) };
		  addColumn: (SpStringTableColumn
				   title: 'Where'
				   evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Point'
				   evaluated: [ :each | each value printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Alpha'
				   evaluated: [ :each |
					   (self alphaAtX: each value x y: each value y) printString ]);
		  yourself
]

{ #category : 'inspector' }
VGCairoSurfaceMask >> inspectorMaskContext: aContext [
	"Nothing to sample until I have a surface to sample."
	aContext active: surface notNil
]

{ #category : 'accessing' }
VGCairoSurfaceMask >> origin [
	"The device point my top left corner sits at."
	^ origin
]

{ #category : 'printing' }
VGCairoSurfaceMask >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: '(';
		print: surface extent;
		nextPutAll: ' at ';
		print: origin;
		nextPut: $)
]

{ #category : 'private' }
VGCairoSurfaceMask >> setSurface: aSurface origin: aPoint [
	surface := aSurface.
	origin := aPoint
]

{ #category : 'accessing' }
VGCairoSurfaceMask >> surface [
	"The surface whose alpha channel I am. Its colours are never read."
	^ surface
]
