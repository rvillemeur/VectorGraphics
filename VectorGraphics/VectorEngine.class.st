"
I'm the main class for Vector painting and drawing 

This a quick summary to Juan Manuel Vuletich paper, with concrete element used in the code highlighted

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
- opaque radius: strokeWidth - antiAliasingWidth
- translucent radius: strokeWidth
- transparent radius: strokeWidth + antiAliasingWidth
- jumps between each points: **hops**


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
		'edgeCounts'
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

{ #category : #accessing }
VectorEngine >> antiAliasingWidth: aNumber [

	antiAliasingWidth := aNumber.
	auxAntiAliasingWidthScaledInverse := 127.0 / antiAliasingWidth
]

{ #category : #'as yet unclassified' }
VectorEngine >> drawingAreaOf: aPoint [

	"Compute affected rect. Honor clipRect"

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

	"slight optimization possible when we know width = 0... perhaps implement: 
			-we know palpha is never 127 
			- we know distanceToEdge is always > erodedHalfWidth. 
				In smalltalk, performance icrease 1.5%. Perhaps in c/asm it is more than that... 
					Mas importante: 		Cuando width es medio grande, entonces dibujar la bolita rellena de entrada es importante... en los casos en que no necesito calcular la distancia"

	| x y drawingArea distanceToAxisSquared alpha prevAlpha dx dy pixelIndex    |
	x := aPoint x.
	y := aPoint y.
	
 	drawingArea := self drawingAreaOf: aPoint.

	drawingArea top to: drawingArea bottom do: [ :displayY | 
		pixelIndex := displayY * (targetForm width) + drawingArea left.
		dy := displayY - y.
		drawingArea left to: drawingArea right do: [ :displayX | 
			pixelIndex := pixelIndex + 1.
			prevAlpha := alphaMask at: pixelIndex.
			prevAlpha = 16r7F ifFalse: [ "le précédent alpha était déjà dans la zone w-r"
				dx := displayX - x.
				distanceToAxisSquared := dx squared + dy squared. "pythagore, square distance"
				distanceToAxisSquared < halfTransparentRadiusSquared "we are in the area to be colorred "ifTrue: [ 
					alpha := distanceToAxisSquared <= halfTranslucentRadiusSquared
						         ifTrue: [ 16r7F ]
						         ifFalse: [ 
							         (halfTransparentRadius
							          - distanceToAxisSquared sqrt
							          * auxAntiAliasingWidthScaledInverse) rounded ].
					alpha > prevAlpha ifTrue: [ alphaMask at: pixelIndex put: alpha ] ] ] ] ]
]

{ #category : #'primitive algorithms - aux' }
VectorEngine >> updateAlphasForX: x y: y [

	"slight optimization possible when we know width = 0... perhaps implement: 
			-we know palpha is never 127 
			- we know distanceToEdge is always > erodedHalfWidth. 
				In smalltalk, performance icrease 1.5%. Perhaps in c/asm it is more than that... 
					Mas importante: 		Cuando width es medio grande, entonces dibujar la bolita rellena de entrada es importante... en los casos en que no necesito calcular la distancia"

	| distanceToAxisSquared alpha t b l r prevAlpha dx dy pixelIndex auxStrokeWidthDilatedHalf clipTop clipBottom clipLeft clipRight targetWidth alphaMask auxStrokeWidthDilatedHalfSquared auxStrokeWidthErodedHalfSquared auxAntiAliasingWidthScaledInverse |
	"Compute affected rect. Honor clipRect"
	t := (y - auxStrokeWidthDilatedHalf) truncated + 1.
	t := t max: clipTop.
	b := (y + auxStrokeWidthDilatedHalf) truncated.
	b := b min: clipBottom.
	l := (x - auxStrokeWidthDilatedHalf) truncated + 1.
	l := l max: clipLeft.
	r := (x + auxStrokeWidthDilatedHalf) truncated.
	r := r min: clipRight.

	t to: b do: [ :displayY | 
		pixelIndex := displayY * targetWidth + l.
		dy := displayY - y.
		l to: r do: [ :displayX | 
			pixelIndex := pixelIndex + 1.
			prevAlpha := alphaMask at: pixelIndex.
			prevAlpha = 16r7F ifFalse: [ "le précédent alpha était déjà dans la zone w-r"
				dx := displayX - x.
				distanceToAxisSquared := dx * dx + (dy * dy). "pythagore, square distance"
				distanceToAxisSquared < auxStrokeWidthDilatedHalfSquared "we are in the area to be colorred "ifTrue: [ 
					alpha := distanceToAxisSquared <= auxStrokeWidthErodedHalfSquared
						         ifTrue: [ 16r7F ]
						         ifFalse: [ 
							         (auxStrokeWidthDilatedHalf
							          - distanceToAxisSquared sqrt
							          * auxAntiAliasingWidthScaledInverse) rounded ].
					alpha > prevAlpha ifTrue: [ alphaMask at: pixelIndex put: alpha ] ] ] ] ]
]

{ #category : #'primitive algorithms - aux' }
VectorEngine >> updateEdgesAndBoundsForX: x y: y [

	| thisYTruncated pixelY pixelIndex increment count pixelX blendLeft blendTop blendRight blendBottom fillColor clipTop clipBottom prevYTruncated clipLeft clipRight targetWidth edgeCounts |
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
