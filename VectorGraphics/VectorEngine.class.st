"
I'm the main class for Vector painting and drawing 

This a quick summary to Juan Manuel Vuletich paper, with concrete element used in the code highlighted
The main paper is available at: [Prefiltering Antialiasing for General Vector Graphics](https://www.researchgate.net/publication/267152327_Prefiltering_Antialiasing_for_General_Vector_Graphics)
More information are available on [juan manuel vuletich web site](https://jvuletich.org/Morphic3/Morphic3-201006.html)

# assumption and model used
The model use:
- A line with a width **W** - **strokeWidth** in this class, and a color
- The destination frame buffer, targetForm
- a filter size parameter **r** - **antiAliasingWidth** in this class, the distance of the transition between transparent to opaque.
- a prefiltering pen: a pen with an opaque center and translucent border. The area under the opacity function is the same as the line, and equals **strokeWidth**
- An auxiliary distance buffer, with the same extent as the destination. It is needed to store for each pixel in the destination a number. **alphaMask and edgeCounts??**


The value of the anti aliasing width can vary between 1 (very crisp, some jaggies are visible) to 2 (very soft, absolutely no jaggies or aliasing). 

the transition from transparent to opaque is gradual, leading to a translucent stripe of width **antiAliasingWidth** at each border of the line drawn by the pen

Each point can be seen as the center of a circle, with the following radius:
- opaque radius: strokeWidth - antiAliasingWidth.
- translucent radius: strokeWidth - alpha mask of 
- tranparent radius: strokeWidth + antiAliasingWidth.
- jumps between each points: **hops**

Opacity if managed through the Alpha mask  channel.
As a reminder:
alpha mask = 16r00 -> completely opaque
alpha mask = 16rff -> completely transparent
alpha mask = 16r7f -> In between, this is the value used between opaque and translucent radius


# algorithm
The algorithm for drawing the Outline of a Shape is as follows:
1. The Destination starts filled with whatever background we need to draw on top of. The distance buffer is assumed to be initially filled with 'infinite' (in practice, any sufficiently large value will do).

2. The algorithm continues by following the trajectory specified by the outline. This is done in discrete steps or jumps (**hops**). At each step, the pen is moved to a new point in the trajectory, jumping by a fraction of a pixel. A step of about 1/4 of a pixel is small enough. => method _primLineFrom: aPoint1 to: aPoint2 hops: hops increment: aPoint3_ and other prim method

3. For each step, the pen is at some point. The possibly affected pixels are in the circle defined by the pen outer diameter (w+r). For each of these pixels, the euclidean distance from the pixel center to the pen center is computed. This distance is stored in the distance buffer if it is less that the value already there. => method _updateAlphasFor: aPoint_ and _updateEdgesAndBoundsForX: x y: y_

4. When the pen has finished following the prescribed trajectory, the distance buffer contains, for each pixel, the minimum distance d to the trajectory. The opacity value is obtained by evaluating the opacity function of the filtering pen at distance d. This opacity value is used to alpha-blend the shape color over the destination frame buffer. Afterwards, the distance buffer is filled with infinite, to be ready for the next call
"
Class {
	#name : #VectorEngine,
	#superclass : #Object,
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
	#category : #'VectorGraphics-kernel'
}

{ #category : #'instance creation' }
VectorEngine class >> defaultAntiAliasingWidth [

	^ 1.0
]

{ #category : #'instance creation' }
VectorEngine class >> onForm: aForm [

	^ self new initializeOnForm: aForm
]

{ #category : #'as yet unclassified' }
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

{ #category : #accessing }
VectorEngine >> antiAliasingWidth: aNumber [

	antiAliasingWidth := aNumber.
	auxAntiAliasingWidthScaledInverse := 127.0 / antiAliasingWidth
]

{ #category : #'as yet unclassified' }
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

{ #category : #initialization }
VectorEngine >> initializeOnForm: aForm [
	self pvtSetForm: aForm
]

{ #category : #'primitive algorithms' }
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

{ #category : #private }
VectorEngine >> pvtFillColor: aFillColorOrNil [

	fillColor := aFillColorOrNil
]

{ #category : #private }
VectorEngine >> pvtSetForm: aForm [
|s|
	targetForm := aForm.
	
	s := targetForm width * targetForm height.
	alphaMask := ByteArray new: s.
	edgeCounts := ByteArray new: s
]

{ #category : #private }
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

{ #category : #'primitive algorithms - aux' }
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

{ #category : #'primitive algorithms - aux' }
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

{ #category : #'primitive algorithms - aux' }
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
