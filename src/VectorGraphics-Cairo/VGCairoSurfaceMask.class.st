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
