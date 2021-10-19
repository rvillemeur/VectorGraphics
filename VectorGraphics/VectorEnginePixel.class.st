Class {
	#name : #VectorEnginePixel,
	#superclass : #VectorEngineAbstract,
	#instVars : [
		'edgeCounts',
		'alphaMask',
		'blendLeft',
		'blendTop',
		'blendRight',
		'blendBottom',
		'strokeColor',
		'fillColor',
		'clipLeft',
		'clipTop',
		'clipRight',
		'clipBottom',
		'prevYTruncated',
		'auxAntiAliasingWidthScaledInverse',
		'auxStrokeWidthDilatedHalf',
		'auxStrokeWidthDilatedHalfSquared',
		'auxStrokeWidthErodedHalfSquared'
	],
	#category : #'VectorGraphics-kernel'
}

{ #category : #accessing }
VectorEnginePixel >> antiAliasingWidth: aNumber [

	super antiAliasingWidth: aNumber.
	auxAntiAliasingWidthScaledInverse := 127.0 / antiAliasingWidth
]

{ #category : #accessing }
VectorEnginePixel >> clipRect: aRectangle [

	"by convention, aRectangle includes left and top but does not include right and bottom.
		We do draw clipRight and clipBottom but not beyond. 	"

	"In targetForm coordinates"

	clipLeft := aRectangle left asInteger max: 0.
	clipTop := aRectangle top asInteger max: 0.
	clipRight := (aRectangle right asInteger min: targetWidth) - 1.
	clipBottom := (aRectangle bottom asInteger min: targetForm height)
	              - 1
]

{ #category : #private }
VectorEnginePixel >> initializePath [

	super initializePath.

	blendLeft := targetWidth. "drawable right. Will later be refined."
	blendTop := targetForm height. "drawable bottom. Will later be refined."
	blendRight := 0. "drawable left. Will later be refined."
	blendBottom := 0 "drawable top. Will later be refined."
]

{ #category : #private }
VectorEnginePixel >> newTrajectoryFragment [

	prevYTruncated := nil
]

{ #category : #'primitive algorithms' }
VectorEnginePixel >> primArcCenterX: cx centerY: cy radiusX: rx radiusY: ry start: startAngle rotationCos: thetaCos rotationSin: thetaSin hops: hops angleDelta: d [

	| angle xp yp x y |
	angle := startAngle.
	hops + 1 timesRepeat: [ 
		xp := angle cos * rx.
		yp := angle sin * ry.
		x := thetaCos * xp - (thetaSin * yp) + cx.
		y := thetaSin * xp + (thetaCos * yp) + cy.
		self updateAlphasForX: x y: y.
		self updateEdgesAndBoundsForX: x y: y.
		angle := angle + d ]
]

{ #category : #'primitive algorithms' }
VectorEnginePixel >> primCubicBezierFromX: xFrom y: yFrom toX: xTo y: yTo control1X: xControl1 y: yControl1 control2X: xControl2 y: yControl2 hops: hops [

	| t oneLessT increment f2 f3 f1 f23 f4 x y |
	t := 0.0.
	increment := 1.0 / hops.
	hops timesRepeat: [ 
		oneLessT := 1.0 - t.
		f1 := oneLessT * oneLessT * oneLessT.
		f23 := 3 * oneLessT * t.
		f2 := f23 * oneLessT.
		f3 := f23 * t.
		f4 := t * t * t.
		x := f1 * xFrom + (f2 * xControl1) + (f3 * xControl2) + (f4 * xTo).
		y := f1 * yFrom + (f2 * yControl1) + (f3 * yControl2) + (f4 * yTo).
		self updateAlphasForX: x y: y.
		self updateEdgesAndBoundsForX: x y: y.
		t := t + increment ].
	self updateAlphasForX: xTo y: yTo.
	self updateEdgesAndBoundsForX: xTo y: yTo
]

{ #category : #'primitive algorithms' }
VectorEnginePixel >> primLineFrom: aPoint1 to: aPoint2 hops: hops increment: aPoint3 [

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

{ #category : #'primitive algorithms' }
VectorEnginePixel >> primLineFromX: xFrom y: yFrom toX: xTo y: yTo hops: hops incrementX: incrementX incrementY: incrementY [

	| x y |
	x := xFrom.
	y := yFrom.
	hops timesRepeat: [ 
		self updateAlphasForX: x y: y.
		self updateEdgesAndBoundsForX: x y: y.
		x := x + incrementX.
		y := y + incrementY ].
	self updateAlphasForX: xTo y: yTo.
	self updateEdgesAndBoundsForX: xTo y: yTo
]

{ #category : #'primitive algorithms' }
VectorEnginePixel >> primQuadraticBezierFromX: xFrom y: yFrom toX: xTo y: yTo controlX: xControl y: yControl hops: hops [

	| t oneLessT increment f2 f3 f1 x y |
	t := 0.0.
	increment := 1.0 / hops.
	hops timesRepeat: [ 
		oneLessT := 1.0 - t.
		f1 := oneLessT * oneLessT.
		f2 := 2 * oneLessT * t.
		f3 := t * t.
		x := f1 * xFrom + (f2 * xControl) + (f3 * xTo).
		y := f1 * yFrom + (f2 * yControl) + (f3 * yTo).
		self updateAlphasForX: x y: y.
		self updateEdgesAndBoundsForX: x y: y.
		t := t + increment ].
	self updateAlphasForX: xTo y: yTo.
	self updateEdgesAndBoundsForX: xTo y: yTo
]

{ #category : #private }
VectorEnginePixel >> pvtFillColor: aFillColorOrNil [

	fillColor := aFillColorOrNil
]

{ #category : #private }
VectorEnginePixel >> pvtStrokeColor: aStrokeColorOrNil [

	strokeColor := aStrokeColorOrNil
]

{ #category : #private }
VectorEnginePixel >> pvtStrokeWidth: aNumber [

	| swErodedHalf |
	super pvtStrokeWidth: aNumber.
	auxStrokeWidthDilatedHalf := strokeWidth + antiAliasingWidth * 0.5.
	auxStrokeWidthDilatedHalfSquared := auxStrokeWidthDilatedHalf
	                                    * auxStrokeWidthDilatedHalf.
	swErodedHalf := strokeWidth - antiAliasingWidth * 0.5.
	auxStrokeWidthErodedHalfSquared := swErodedHalf * swErodedHalf
	                                   * swErodedHalf sign
]

{ #category : #'primitive algorithms - aux' }
VectorEnginePixel >> updateAlphasForX: x y: y [

	^ self subclassResponsibility
]

{ #category : #'primitive algorithms - aux' }
VectorEnginePixel >> updateEdgesAndBoundsForX: x y: y [

	^ self subclassResponsibility
]
