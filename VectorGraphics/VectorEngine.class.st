Class {
	#name : #VectorEngine,
	#superclass : #Object,
	#instVars : [
		'targetForm'
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

	targetForm := aForm.
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
