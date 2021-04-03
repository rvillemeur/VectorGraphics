"
Morph Bounds Finder
"
Class {
	#name : #VectorEngineBoundsFinder,
	#superclass : #VectorEngineAbstract,
	#instVars : [
		'auxStrokeWidthDilatedHalf'
	],
	#category : #'VectorGraphics-Kernel'
}

{ #category : #'instance creation' }
VectorEngineBoundsFinder class >> defaultAntiAliasingWidth [

	^ 1.7
]

{ #category : #accessing }
VectorEngineBoundsFinder >> clipRect: aRectangle [
]

{ #category : #'stroke & fill' }
VectorEngineBoundsFinder >> fillColor: aFillColor do: pathCommandsBlock [

	"Prepare parameters for drawing fill."

	(aFillColor isNil or: [ aFillColor alpha = 0.0 ]) ifTrue: [ ^ self ].
	self pvtStrokeWidth: 0.0.
	hopsPerPixel := 8. "See #experimentHopsPerPixel3"
	self initializePath.
	pathCommandsBlock valueWithPossibleArgument: self.
	self finishPath: true
]

{ #category : #private }
VectorEngineBoundsFinder >> finishPath: ensureClosePath [

	"Blend stroke and/or fill over background, according to the just computed pen alphas (distance from pixel to center of stroke)"

	morphBoundsLeft := (morphBoundsLeft - auxStrokeWidthDilatedHalf)
		                   truncated + 1.
	morphBoundsTop := (morphBoundsTop - auxStrokeWidthDilatedHalf)
		                  truncated + 1.
	morphBoundsRight := (morphBoundsRight + auxStrokeWidthDilatedHalf)
		                    truncated. "+1" "Make room not just for updated mask, but also edges (hence, +1) NOT IN THIS CLASS"
	morphBoundsBottom := (morphBoundsBottom + auxStrokeWidthDilatedHalf)
		                     truncated.

	"Most likely useless."
	pathFirstX := 0.0.
	pathFirstY := 0.0.
	pathCurrentX := 0.0.
	pathCurrentY := 0.0.
	previousCallX := 0.0.
	previousCallY := 0.0.
	previousCallControlX := previousCallX.
	previousCallControlY := previousCallY
]

{ #category : #private }
VectorEngineBoundsFinder >> morph: aMorph isAtPoint: aPoint [

	self shouldNotHappen
]

{ #category : #'primitive algorithms' }
VectorEngineBoundsFinder >> primArcCenterX: cx centerY: cy radiusX: rx radiusY: ry start: startAngle rotationCos: thetaCos rotationSin: thetaSin hops: hops angleDelta: d [

	| angle xp yp x y |
	angle := startAngle.
	hops + 1 timesRepeat: [ 
		xp := angle cos * rx.
		yp := angle sin * ry.
		x := thetaCos * xp - (thetaSin * yp) + cx.
		y := thetaSin * xp + (thetaCos * yp) + cy.
		self updateBoundsForX: x y: y.
		angle := angle + d ]
]

{ #category : #'primitive algorithms' }
VectorEngineBoundsFinder >> primCubicBezierFromX: xFrom y: yFrom toX: xTo y: yTo control1X: xControl1 y: yControl1 control2X: xControl2 y: yControl2 hops: hops [

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
		self updateBoundsForX: x y: y.
		t := t + increment ].
	self updateBoundsForX: xTo y: yTo
]

{ #category : #'primitive algorithms' }
VectorEngineBoundsFinder >> primLineFromX: xFrom y: yFrom toX: xTo y: yTo hops: hops incrementX: incrementX incrementY: incrementY [

	self updateBoundsForX: xFrom y: yFrom.
	self updateBoundsForX: xTo y: yTo
]

{ #category : #'primitive algorithms' }
VectorEngineBoundsFinder >> primQuadraticBezierFromX: xFrom y: yFrom toX: xTo y: yTo controlX: xControl y: yControl hops: hops [

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
		self updateBoundsForX: x y: y.
		t := t + increment ].
	self updateBoundsForX: xTo y: yTo
]

{ #category : #private }
VectorEngineBoundsFinder >> pvtSetForm: aForm [

	targetForm := aForm.
	targetWidth := targetForm width.
	self resetMorphBounds.
	self antiAliasingWidth: self class defaultAntiAliasingWidth
]

{ #category : #private }
VectorEngineBoundsFinder >> pvtStrokeWidth: aNumber [

	super pvtStrokeWidth: aNumber.
	auxStrokeWidthDilatedHalf := strokeWidth + antiAliasingWidth * 0.5
]

{ #category : #'stroke & fill' }
VectorEngineBoundsFinder >> strokeWidth: clientStrokeWidth color: aStrokeColor do: pathCommandsBlock ensureClosePath: ensureClosePath [

	"Prepare parameters for drawing stroke."

	| aStrokeWidth |
	(aStrokeColor isNil or: [ aStrokeColor alpha = 0.0 ]) ifTrue: [ 
		^ self ].
	clientStrokeWidth = 0.0 ifTrue: [ ^ self ].
	aStrokeWidth := geometryTransformation externalizeScalar:
		                clientStrokeWidth.
	self pvtStrokeWidth: (aStrokeWidth max: antiAliasingWidth).
	hopsPerPixel := 10.0 / strokeWidth + 1. "See #experimentHopsPerPixel2"
	self initializePath.
	pathCommandsBlock valueWithPossibleArgument: self.
	self finishPath: ensureClosePath
]

{ #category : #'stroke & fill' }
VectorEngineBoundsFinder >> strokeWidth: clientStrokeWidth color: aStrokeColor fillColor: aFillColor do: pathCommandsBlock [

	"Prepare parameters for drawing stroke, fill, or both."

	(aStrokeColor isNil or: [ aStrokeColor alpha = 0.0 ]) ifTrue: [ 
		^ self fillColor: aFillColor do: pathCommandsBlock ].
	clientStrokeWidth = 0.0 ifTrue: [ 
		^ self fillColor: aFillColor do: pathCommandsBlock ].
	^ self
		  strokeWidth: clientStrokeWidth
		  color: aStrokeColor
		  do: pathCommandsBlock
		  ensureClosePath: true
]

{ #category : #'primitive algorithms - aux' }
VectorEngineBoundsFinder >> updateBoundsForX: x y: y [

	morphBoundsLeft := morphBoundsLeft min: x.
	morphBoundsTop := morphBoundsTop min: y.
	morphBoundsRight := morphBoundsRight max: x.
	morphBoundsBottom := morphBoundsBottom max: y
]
