"
Standalone reference implementation of the Vuletich prefiltering anti-aliasing algorithm.

VectorEngine is a sibling of VectorEngineAbstract (both inherit from Object), not a subclass.
It is simpler and self-contained: alphaMask and edgeCounts are plain ByteArrays; there is no
Morphic integration, no path command API, and no subclassing hierarchy. It is used as the
reference implementation for VectorEngineTest and for understanding the core algorithm.

For production use, prefer VectorEngineAbstract and its concrete subclasses (VectorEngineWholePixel,
VectorEngineSubPixel), which add the full path state machine, morph clipping, and Morphic
Canvas integration.

## Algorithm (Vuletich prefiltering)
The engine rasterizes strokes by walking the path in sub-pixel hops, computing per-pixel
distances to the trajectory, and alpha-blending based on a prefiltered opacity function:

1. `alphaMask` stores, per pixel, the minimum distance to the trajectory so far.
2. `edgeCounts` tracks winding-number increments for fill rendering.
3. After the path is complete, the mask is used to blend the stroke/fill color over targetForm.

Key numeric invariants:
  alphaMask = 16r7F → opaque (at center of stroke)
  alphaMask = 16r00 → fully transparent (beyond outer edge)
  antiAliasingWidth controls the width of the translucent transition band.

Paper: [Prefiltering Antialiasing for General Vector Graphics](https://www.researchgate.net/publication/267152327_Prefiltering_Antialiasing_for_General_Vector_Graphics)
Reference: https://jvuletich.org/Morphic3/Morphic3-201006.html

## Key methods
- `pvtStrokeWidth: w`        — sets strokeWidth and computes auxiliary radius values
- `updateAlphasFor: aPoint`  — update alphaMask for all pixels near the given hop position
- `alphaValueAtDistance: dx and: dy` — opacity function for a pixel at distance (dx,dy)
- `primLineFrom: p1 to: p2 hops: n increment: delta` — walks a line segment in n hops
- `drawingAreaOf: aPoint`    — returns the bounding rectangle of pixels affected by a pen at aPoint
"
Class {
	#name : 'VectorEngine',
	#superclass : 'Object',
	#instVars : [
		'targetForm',
		'strokeWidth',
		'antiAliasingWidth',
		'auxAntiAliasingWidthScaledInverse',
		'halfTransparentRadius',
		'halfTransparentRadiusSquared',
		'halfTranslucentRadiusSquared',
		'alphaMask',
		'edgeCounts',
		'fillColor'
	],
	#category : 'VectorGraphics-Kernel',
	#package : 'VectorGraphics',
	#tag : 'Kernel'
}

{ #category : 'instance creation' }
VectorEngine class >> defaultAntiAliasingWidth [

	^ 1.0
]

{ #category : 'instance creation' }
VectorEngine class >> onForm: aForm [

	^ self new initializeOnForm: aForm
]

{ #category : 'as yet unclassified' }
VectorEngine >> alphaValueAtDistance: deltaX and: deltaY [

	| distanceToAxisSquared alpha |
	distanceToAxisSquared := deltaX squared + deltaY squared.
	distanceToAxisSquared < halfTransparentRadiusSquared ifTrue: [ 
		alpha := distanceToAxisSquared <= halfTranslucentRadiusSquared
			         ifTrue: [ 16r7F ]
			         ifFalse: [ 
				         (halfTransparentRadius - distanceToAxisSquared sqrt
				          * auxAntiAliasingWidthScaledInverse) rounded ] ] ifFalse:[alpha := 16r0].

	^ alpha
]

{ #category : 'accessing' }
VectorEngine >> antiAliasingWidth: aNumber [

	antiAliasingWidth := aNumber.
	auxAntiAliasingWidthScaledInverse := 127.0 / antiAliasingWidth
]

{ #category : 'as yet unclassified' }
VectorEngine >> drawingAreaOf: aPoint [

	"targetForm is a rectangle from 0@0 to width@height. Drawing area cannot be outside targetForm"

	| top bottom left right |
	top := (aPoint y - halfTransparentRadius) truncated + 1.
	top := top max: 0.
	bottom := (aPoint y + halfTransparentRadius) truncated.
	bottom := bottom min: targetForm height.
	left := (aPoint x - halfTransparentRadius) truncated + 1.
	left := left max: 0.
	right := (aPoint x + halfTransparentRadius) truncated.
	right := right min: targetForm width.
	^ Rectangle
		  left: left
		  right: right
		  top: top
		  bottom: bottom
]

{ #category : 'initialization' }
VectorEngine >> initializeOnForm: aForm [
	self pvtSetForm: aForm
]

{ #category : 'primitive algorithms' }
VectorEngine >> primLineFrom: aPoint1 to: aPoint2 hops: hops increment: aPoint3 [

	| x y stepX stepY line|
	x := aPoint1 x.
	y := aPoint1 y.
	stepX := aPoint3 x.
	stepY := aPoint3 y.
	line := OrderedCollection new.
	hops timesRepeat: [ 
		line add: x@y.
		x := x + stepX.
		y := y + stepY ].
	line add: aPoint2.
	^line
]

{ #category : 'private' }
VectorEngine >> pvtFillColor: aFillColorOrNil [

	fillColor := aFillColorOrNil
]

{ #category : 'private' }
VectorEngine >> pvtSetForm: aForm [
|s|
	targetForm := aForm.
	
	s := targetForm width * targetForm height.
	alphaMask := ByteArray new: s.
	edgeCounts := ByteArray new: s
]

{ #category : 'private' }
VectorEngine >> pvtStrokeWidth: aNumber [

	| halfTranslucentRadius translucentRadius transparentRadius |
	strokeWidth := aNumber.
	transparentRadius := strokeWidth + antiAliasingWidth.
	translucentRadius := strokeWidth - antiAliasingWidth.

	halfTransparentRadius := transparentRadius / 2.
	halfTransparentRadiusSquared := halfTransparentRadius squared.
	halfTranslucentRadius := translucentRadius * 0.5.
	halfTranslucentRadiusSquared := halfTranslucentRadius squared
	                                * halfTranslucentRadius sign
]

{ #category : 'primitive algorithms - aux' }
VectorEngine >> updateAlphasFor: aPoint [
	| drawingArea alpha  prevAlpha deltaX deltaY pixelIndex |

	drawingArea := self drawingAreaOf: aPoint.

	drawingArea top to: drawingArea bottom do: [ :displayY |
		pixelIndex := displayY * targetForm width + drawingArea left.
		deltaY := displayY - aPoint y.
		drawingArea left to: drawingArea right do: [ :displayX |
			pixelIndex := pixelIndex + 1.
			prevAlpha := alphaMask at: pixelIndex.
			prevAlpha = 16r7F ifFalse: [  
				deltaX := displayX - aPoint x.
				alpha := self alphaValueAtDistance: deltaX and: deltaY.
				alpha > prevAlpha ifTrue: [ alphaMask at: pixelIndex put: alpha ] ] ] ].
	^alphaMask
]

{ #category : 'primitive algorithms - aux' }
VectorEngine >> updateEdgesAndBoundsFor: aPoint [

	| thisYTruncated pixelY pixelIndex increment count pixelX blendLeft blendTop blendRight blendBottom clipTop clipBottom prevYTruncated clipLeft clipRight targetWidth |
	blendLeft := blendLeft min: aPoint x.
	blendTop := blendTop min: aPoint y.
	blendRight := blendRight max: aPoint x.
	blendBottom := blendBottom max: aPoint y.
	fillColor notNil ifFalse: [ ^ self ].
	thisYTruncated := aPoint y truncated.
	(thisYTruncated between: clipTop - 1 and: clipBottom) ifTrue: [ 
		prevYTruncated
			ifNil: [ prevYTruncated := thisYTruncated ]
			ifNotNil: [ 
				thisYTruncated = prevYTruncated ifFalse: [ "All edge count at the left of the clipRect are added there (at the left of the clipRect).
											The effect is the same, and we need to clean up less stuff afterwards.
												More important, it avoids trying to acess pixels outside our form, i.e. invalid array acesses."
					pixelX := aPoint x truncated + 1 max: clipLeft.
					pixelX <= clipRight ifTrue: [ 
						pixelY := thisYTruncated max: prevYTruncated.
						increment := (thisYTruncated - prevYTruncated) sign.
						pixelIndex := pixelY * targetWidth + pixelX + 1.
						count := edgeCounts at: pixelIndex.
						count := count + increment bitAnd: 16rFF.
						edgeCounts at: pixelIndex put: count ].
					prevYTruncated := thisYTruncated ] ] ]
]

{ #category : 'primitive algorithms - aux' }
VectorEngine >> updateEdgesAndBoundsForX: x y: y [

	| thisYTruncated pixelY pixelIndex increment count pixelX blendLeft blendTop blendRight blendBottom fillColor clipTop clipBottom prevYTruncated clipLeft clipRight targetWidth |
	blendLeft := blendLeft min: x.
	blendTop := blendTop min: y.
	blendRight := blendRight max: x.
	blendBottom := blendBottom max: y.
	fillColor notNil ifFalse: [ ^ self ].
	thisYTruncated := y truncated.
	(thisYTruncated between: clipTop - 1 and: clipBottom) ifTrue: [ 
		prevYTruncated
			ifNil: [ prevYTruncated := thisYTruncated ]
			ifNotNil: [ 
				thisYTruncated = prevYTruncated ifFalse: [ "All edge count at the left of the clipRect are added there (at the left of the clipRect).
											The effect is the same, and we need to clean up less stuff afterwards.
												More important, it avoids trying to acess pixels outside our form, i.e. invalid array acesses."
					pixelX := x truncated + 1 max: clipLeft.
					pixelX <= clipRight ifTrue: [ 
						pixelY := thisYTruncated max: prevYTruncated.
						increment := (thisYTruncated - prevYTruncated) sign.
						pixelIndex := pixelY * targetWidth + pixelX + 1.
						count := edgeCounts at: pixelIndex.
						count := count + increment bitAnd: 16rFF.
						edgeCounts at: pixelIndex put: count ].
					prevYTruncated := thisYTruncated ] ] ]
]
