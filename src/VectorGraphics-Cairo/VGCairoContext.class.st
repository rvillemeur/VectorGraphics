"
I am the replacement for AeCairoContext: the paint API that Bloc and AeCanvas really drive.

I record rather than rasterise. Every drawing message appends an entry to a display list, which a backend drains once per frame; that is rule one of VECTORCANVAS-PLAN.md, and it is what lets the Vulkan backend of phase 2 and the software backend of phase 1 sit behind the same object. I also keep the Cairo state machine - source, matrix, fill rule, stroke parameters, clip stack - because the Cairo API is stateful and immediate, and because fillPreservingPath and strokePreservingPath mean a path outlives the operation that drew it.

Most of my selectors are still skeletons: they signal VGNotYetImplemented naming the unit that will implement them. VGCairoInventory says which selectors I must answer, and VGCairoInventoryTest fails if one is missing.
"
Class {
	#name : 'VGCairoContext',
	#superclass : 'VGCairoObject',
	#instVars : [
		'surface',
		'state',
		'stateStack',
		'status',
		'pathBuilder'
	],
	#category : 'VectorGraphics-Cairo-Context',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Context'
}

{ #category : 'instance creation' }
VGCairoContext class >> newFor: aSurface [
	| context |
	context := self new.
	context setSurface: aSurface.
	^ context
]

{ #category : 'constants' }
VGCairoContext class >> threeHalvesPi [
	"Three quarters of a turn, which is where a rounded rectangle's top corners meet. Alexandrie
	 keeps the same number under the same name in a shared pool."

	^ Float pi * 1.5
]

{ #category : 'path' }
VGCairoContext >> annulusSectorCenter: aPoint from: startRadians to: stopRadians innerRadius: anInnerRadius outerRadius: anOuterRadius [
	"A slice of a ring: out along the outer arc, back along the inner one, then closed. The start
	 angle is below the stop angle."

	self
		arcCenterX: aPoint x
			centerY: aPoint y
			radius: anOuterRadius
			startAngle: startRadians
			endAngle: stopRadians;
		arcNegativeCenterX: aPoint x
			centerY: aPoint y
			radius: anInnerRadius
			startAngle: stopRadians
			endAngle: startRadians;
		closePath
]

{ #category : 'stroke style' }
VGCairoContext >> antialias: anObject [
	"How a fill is sampled: #default, #none, #gray, #subpixel, #fast, #good or #best, or
	 Alexandrie's own AeCairoAntialias, or Cairo's integer. Only #none changes what we draw,
	 because it takes one sample at the centre of each pixel and every other mode keeps the
	 sub-row sampling Cairo itself uses."

	self isInError ifTrue: [ ^ self ].
	state antialias: anObject
]

{ #category : 'private' }
VGCairoContext >> appendArcCenter: aCenter radius: aRadius from: startRadians to: endRadians [
	"The arc as a polyline fine enough that it stays within the flattening tolerance of the true
	 arc in device space. Every point is a lineTo, which Cairo turns into a move when the path has
	 no current point, so the arc joins what is already there exactly as Cairo's does."

	| sweep count |
	sweep := endRadians - startRadians.
	count := self arcPointCountForRadius: aRadius sweep: sweep abs.
	0 to: count do: [ :index |
		| angle |
		angle := startRadians + (sweep * index / count).
		self lineTo: aCenter + (aRadius * angle cos @ (aRadius * angle sin)) ]
]

{ #category : 'skeleton - unit 1.8' }
VGCairoContext >> appendGlyphsPath: arg1 [
	^ self notYetImplementedIn: '1.8' selector: #appendGlyphsPath:
]

{ #category : 'path' }
VGCairoContext >> arcCenter: aPoint radius: aRadius startAngle: startRadians endAngle: endRadians [
	self
		arcCenterX: aPoint x
		centerY: aPoint y
		radius: aRadius
		startAngle: startRadians
		endAngle: endRadians
]

{ #category : 'path' }
VGCairoContext >> arcCenter: aPoint radius: aRadius startAngle: startRadians endAngle: endRadians cw: isClockwise [
	isClockwise
		ifTrue: [
			self
				arcCenter: aPoint
				radius: aRadius
				startAngle: startRadians
				endAngle: endRadians ]
		ifFalse: [
			self
				arcNegativeCenter: aPoint
				radius: aRadius
				startAngle: startRadians
				endAngle: endRadians ]
]

{ #category : 'path' }
VGCairoContext >> arcCenter: aPoint radius: aRadius startAngle: startRadians sweep: sweepRadians [
	"The sign of the sweep says which way the arc turns."

	self
		arcCenter: aPoint
		radius: aRadius
		startAngle: startRadians
		endAngle: startRadians + sweepRadians
		cw: sweepRadians positive
]

{ #category : 'path' }
VGCairoContext >> arcCenterX: centerX centerY: centerY radius: aRadius startAngle: startRadians endAngle: endRadians [
	"An arc in the direction of increasing angles. Cairo raises the end angle by whole turns until
	 it is not below the start, and joins the arc to the path with a line from the current point,
	 or a move when there is none."

	self isInError ifTrue: [ ^ self ].
	self
		appendArcCenter: centerX @ centerY
		radius: aRadius
		from: startRadians
		to: (self raise: endRadians above: startRadians)
]

{ #category : 'path' }
VGCairoContext >> arcNegativeCenter: aPoint radius: aRadius startAngle: startRadians endAngle: endRadians [
	self
		arcNegativeCenterX: aPoint x
		centerY: aPoint y
		radius: aRadius
		startAngle: startRadians
		endAngle: endRadians
]

{ #category : 'path' }
VGCairoContext >> arcNegativeCenterX: centerX centerY: centerY radius: aRadius startAngle: startRadians endAngle: endRadians [
	"An arc in the direction of decreasing angles. Cairo lowers the end angle by whole turns until
	 it is not above the start."

	self isInError ifTrue: [ ^ self ].
	self
		appendArcCenter: centerX @ centerY
		radius: aRadius
		from: startRadians
		to: (self lower: endRadians below: startRadians)
]

{ #category : 'private' }
VGCairoContext >> arcPointCountForRadius: aRadius sweep: aSweep [
	"How many chords an arc of that radius and sweep needs. A chord of angle h over radius r
	 departs from the arc by r times one minus the cosine of half h, so the tolerance fixes h.
	 The radius is measured in device space, where the tolerance lives; the scale factors are read
	 as a length, which overstates an anisotropic scale and so only ever buys extra chords."

	| deviceRadius tolerance step |
	tolerance := VGPathBuilder defaultFlatteningTolerance.
	deviceRadius := aRadius abs * state matrix scaleFactors r.
	deviceRadius <= tolerance ifTrue: [ ^ 1 ].
	step := 2.0 * (1.0 - (tolerance / deviceRadius)) arcCos.
	step isZero ifTrue: [ ^ 1 ].
	^ (aSweep / step) ceiling max: 1
]

{ #category : 'path' }
VGCairoContext >> beginSubPath [
	"The path keeps everything it holds and loses its current point, so the next arc needs no
	 move to its own first point."

	self isInError ifTrue: [ ^ self ].
	self pathBuilder beginSubPath
]

{ #category : 'transformations' }
VGCairoContext >> changeMatrixBy: aBlock [
	"Cairo ignores every request once the context is in error, which is how a singular matrix ends
	 as an empty drawing instead of a signal."
	self isInError ifTrue: [ ^ self ].
	aBlock value: state matrix
]

{ #category : 'path' }
VGCairoContext >> circleCenter: aPoint radius: aRadius [
	self circleCenterX: aPoint x y: aPoint y radius: aRadius
]

{ #category : 'path' }
VGCairoContext >> circleCenterX: x y: y radius: aRadius [
	self
		arcCenterX: x
		centerY: y
		radius: aRadius
		startAngle: 0.0
		endAngle: Float twoPi
]

{ #category : 'path' }
VGCairoContext >> circleRadius: aRadius [
	"The circle that fills the square of that radius' diameter at the origin, so its centre is at
	 the radius in both axes."

	self
		arcCenterX: aRadius
		centerY: aRadius
		radius: aRadius
		startAngle: 0.0
		endAngle: Float twoPi
]

{ #category : 'path' }
VGCairoContext >> circleSectorCenter: aPoint from: startRadians to: stopRadians radius: aRadius [
	"A pie slice: the arc, then a line back to the centre, then closed. The start angle is below
	 the stop angle."

	self
		arcCenterX: aPoint x
			centerY: aPoint y
			radius: aRadius
			startAngle: startRadians
			endAngle: stopRadians;
		lineToX: aPoint x y: aPoint y;
		closePath
]

{ #category : 'painting' }
VGCairoContext >> clearColor: aColor [
	"Every pixel of my target in aColor. The operator and the clip arrive in units 1.6 and 1.7, so
	 this is a plain fill of the whole surface for now."
	self isInError ifTrue: [ ^ self ].
	surface fillPixel: (surface format pixelForColor: aColor)
]

{ #category : 'painting' }
VGCairoContext >> clearTransparent [
	self isInError ifTrue: [ ^ self ].
	surface fillPixel: 0
]

{ #category : 'skeleton - unit 1.6' }
VGCairoContext >> clip [
	^ self notYetImplementedIn: '1.6' selector: #clip
]

{ #category : 'skeleton - unit 1.6' }
VGCairoContext >> clipPreservingPath [
	^ self notYetImplementedIn: '1.6' selector: #clipPreservingPath
]

{ #category : 'path' }
VGCairoContext >> closePath [
	self isInError ifTrue: [ ^ self ].
	self pathBuilder closePath
]

{ #category : 'path' }
VGCairoContext >> cubicCurveFrom: aStartPoint controlPoint1: aFirstControlPoint controlPoint2: aSecondControlPoint to: anEndPoint [
	self
		moveTo: aStartPoint;
		curveVia: aFirstControlPoint via: aSecondControlPoint to: anEndPoint
]

{ #category : 'private' }
VGCairoContext >> currentClip [
	"The area a fill may touch. The clip verbs arrive in unit 1.6; until then the state holds no
	 clip and the whole surface is the limit. The surface bounds are always one of the terms, so
	 the rasteriser is never asked for a pixel the target does not have."

	^ state clip
		  ifNil: [ surface boundsRectangle ]
		  ifNotNil: [ :rectangle | rectangle intersect: surface boundsRectangle ]
]

{ #category : 'private' }
VGCairoContext >> currentOperator [
	"Unit 1.7 brings the operator to the state. Until then every fill composites source over
	 destination, which is Cairo's own default operator."

	^ #over
]

{ #category : 'accessing' }
VGCairoContext >> currentPointInUserSpace [
	"Cairo answers the origin, not nothing, when there is no current point, and it answers in user
	 space although the path it holds is in device space, so the same path answers a different
	 point after a transformation. Both facts are measured against a live context."

	self hasCurrentPoint ifFalse: [ ^ 0.0 @ 0.0 ].
	^ self userPointFor: self pathBuilder currentPoint
]

{ #category : 'painting' }
VGCairoContext >> currentTarget [
	^ surface
]

{ #category : 'path' }
VGCairoContext >> curveVia: aFirstControlPoint via: aSecondControlPoint to: anEndPoint [
	self isInError ifTrue: [ ^ self ].
	self pathBuilder
		curveVia: (self devicePointFor: aFirstControlPoint)
		via: (self devicePointFor: aSecondControlPoint)
		to: (self devicePointFor: anEndPoint)
]

{ #category : 'path' }
VGCairoContext >> curveViaX: x1 y: y1 viaX: x2 y: y2 toX: x3 y: y3 [
	self curveVia: x1 @ y1 via: x2 @ y2 to: x3 @ y3
]

{ #category : 'private' }
VGCairoContext >> devicePointFor: aPoint [
	^ state matrix value: aPoint
]

{ #category : 'path' }
VGCairoContext >> ellipseWidth: aWidth height: aHeight [
	"An ellipse is the unit circle under a scale, and the path records in device space, so the
	 scale is undone as soon as the arc is appended."

	self saveState.
	self
		scaleByX: aWidth y: aHeight;
		arcCenterX: 0.5
			centerY: 0.5
			radius: 0.5
			startAngle: 0.0
			endAngle: Float twoPi.
	self restoreState
]

{ #category : 'painting' }
VGCairoContext >> fill [
	self isInError ifTrue: [ ^ self ].
	self recordFillOfPath.
	self newPath
]

{ #category : 'painting' }
VGCairoContext >> fillPreserve [
	"Cairo's own spelling of fillPreservingPath; Alexandrie offers both."

	self fillPreservingPath
]

{ #category : 'painting' }
VGCairoContext >> fillPreservingPath [
	self isInError ifTrue: [ ^ self ].
	self recordFillOfPath
]

{ #category : 'painting' }
VGCairoContext >> fillPreservingPath: aBoolean [
	aBoolean
		ifTrue: [ self fillPreservingPath ]
		ifFalse: [ self fill ]
]

{ #category : 'fill rule' }
VGCairoContext >> fillRule: aSymbol [
	"Either #winding or #evenOdd. Alexandrie passes an AeCairoFillRule here; the rule is a symbol
	 on this side, because the state has always held one and no enumeration class is needed to
	 name two values."

	self isInError ifTrue: [ ^ self ].
	state fillRule: aSymbol
]

{ #category : 'skeleton - unit 1.8' }
VGCairoContext >> fontExtents [
	^ self notYetImplementedIn: '1.8' selector: #fontExtents
]

{ #category : 'skeleton - unit 1.8' }
VGCairoContext >> fontSize: arg1 [
	^ self notYetImplementedIn: '1.8' selector: #fontSize:
]

{ #category : 'skeleton - unit 1.8' }
VGCairoContext >> getGlyphExtentsOf: arg1 size: arg2 into: arg3 [
	^ self notYetImplementedIn: '1.8' selector: #getGlyphExtentsOf:size:into:
]

{ #category : 'testing' }
VGCairoContext >> hasCurrentPoint [
	^ self pathBuilder hasCurrentPoint
]

{ #category : 'initialization' }
VGCairoContext >> initialize [
	super initialize.
	state := VGCairoState new.
	stateStack := OrderedCollection new.
	status := VGCairoStatus success
]

{ #category : 'inspector' }
VGCairoContext >> inspectorPath: aBuilder [
	<inspectorPresentationOrder: 13 title: 'Path'>
	"The path a fill or a stroke would consume, in device space. The current point is read
	 through the public reader, which answers the origin when there is none, so the row beside it
	 says whether there really is one."

	| path |
	path := self pathBuilder path.
	^ aBuilder newTable
		  items: {
				  ('Runs' -> path subPaths size).
				  ('Points' -> path pointCount).
				  ('Closed runs' -> (path subPaths count: [ :each | each isClosed ])).
				  ('Current point in user space' -> self currentPointInUserSpace).
				  ('Has a current point' -> self hasCurrentPoint).
				  ('Fill rule' -> state fillRule).
				  ('Clip a fill would get' -> self currentClip).
				  ('Bounding box' -> path boundingBox) };
		  addColumn: (SpStringTableColumn
				   title: 'Property'
				   evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGCairoContext >> inspectorPathContext: aContext [
	aContext active: (state notNil and: [ surface notNil ])
]

{ #category : 'inspecting' }
VGCairoContext >> inspectorStateStack: aBuilder [
	<inspectorPresentationOrder: 12 title: 'State stack'>
	^ aBuilder newTable
		  items: self stateStackDescription;
		  addColumn: (SpStringTableColumn
				   title: 'Depth'
				   evaluated: [ :each | each first ]);
		  addColumn: (SpStringTableColumn
				   title: 'Fill rule'
				   evaluated: [ :each | each second fillRule printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Source'
				   evaluated: [ :each | each second source printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Clip'
				   evaluated: [ :each | each second clip printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Matrix'
				   evaluated: [ :each | each second matrix printString ]);
		  yourself
]

{ #category : 'inspecting' }
VGCairoContext >> inspectorStateStackContext: aContext [
	aContext active: state notNil
]

{ #category : 'accessing' }
VGCairoContext >> isInError [
	"Cairo latches a failure on the context and then ignores every request, so the drawing a bad
	 matrix would have produced is empty rather than signalled."
	^ status isSuccess not
]

{ #category : 'private' }
VGCairoContext >> isValidDashPattern: aCollection [
	"Cairo's two rules, measured against a live context: no length may be negative, and a
	 pattern that holds lengths at all must hold one that is not zero. An empty pattern is
	 valid and turns dashing off."

	(aCollection anySatisfy: [ :each | each < 0 ]) ifTrue: [ ^ false ].
	^ aCollection isEmpty or: [ aCollection anySatisfy: [ :each | each > 0 ] ]
]

{ #category : 'path' }
VGCairoContext >> lineFrom: aPoint to: anotherPoint [
	self
		moveTo: aPoint;
		lineTo: anotherPoint
]

{ #category : 'path' }
VGCairoContext >> lineTo: aPoint [
	"With no current point this acts as a move, which is what Cairo's cairo_line_to does."

	self isInError ifTrue: [ ^ self ].
	self pathBuilder lineTo: (self devicePointFor: aPoint)
]

{ #category : 'path' }
VGCairoContext >> lineToX: x y: y [
	self lineTo: x @ y
]

{ #category : 'private' }
VGCairoContext >> lower: anEndAngle below: aStartAngle [
	| angle |
	angle := anEndAngle.
	[ angle > aStartAngle ] whileTrue: [ angle := angle - Float twoPi ].
	^ angle
]

{ #category : 'skeleton' }
VGCairoContext >> mask: anArgument1 [
	^ self notYetImplementedIn: '1.7' selector: #mask:
]

{ #category : 'skeleton - unit 1.7' }
VGCairoContext >> maskGroupWith: arg1 [
	^ self notYetImplementedIn: '1.7' selector: #maskGroupWith:
]

{ #category : 'skeleton - unit 1.7' }
VGCairoContext >> maskSurface: arg1 x: arg2 y: arg3 [
	^ self notYetImplementedIn: '1.7' selector: #maskSurface:x:y:
]

{ #category : 'transformations' }
VGCairoContext >> matrix [
	"A copy, because Alexandrie answers a fresh matrix and a caller may transform what it got."
	^ state matrix copy
]

{ #category : 'transformations' }
VGCairoContext >> matrix: aMatrix [
	self isInError ifTrue: [ ^ self ].
	aMatrix isInvertible
		ifTrue: [ state matrix: aMatrix copy ]
		ifFalse: [ status := VGCairoStatus invalidMatrix ]
]

{ #category : 'path' }
VGCairoContext >> moveTo: aPoint [
	self isInError ifTrue: [ ^ self ].
	self pathBuilder moveTo: (self devicePointFor: aPoint)
]

{ #category : 'path' }
VGCairoContext >> moveToX: x y: y [
	self moveTo: x @ y
]

{ #category : 'private' }
VGCairoContext >> newPath [
	"Forget the path. Every painting verb that does not say it preserves the path ends with this,
	 which is what Cairo does."

	pathBuilder := nil
]

{ #category : 'skeleton' }
VGCairoContext >> operator: anArgument1 [
	^ self notYetImplementedIn: '1.7' selector: #operator:
]

{ #category : 'painting' }
VGCairoContext >> paint [
	"The source everywhere the clip allows, which is what Cairo's paint is: a fill of the clip
	 extents. The path is not touched."

	self isInError ifTrue: [ ^ self ].
	self recordFillOf: (VGSegments rectangle: self currentClip)
]

{ #category : 'skeleton - unit 1.7' }
VGCairoContext >> paintGroupWith: arg1 [
	^ self notYetImplementedIn: '1.7' selector: #paintGroupWith:
]

{ #category : 'skeleton - unit 1.7' }
VGCairoContext >> paintGroupWith: arg1 alpha: arg2 [
	^ self notYetImplementedIn: '1.7' selector: #paintGroupWith:alpha:
]

{ #category : 'skeleton - unit 1.7' }
VGCairoContext >> paintWithAlpha: arg1 [
	^ self notYetImplementedIn: '1.7' selector: #paintWithAlpha:
]

{ #category : 'accessing' }
VGCairoContext >> pathBuilder [
	"The path I am building, in device space. Cairo transforms a point as the path verb is sent,
	 not as the paint is drawn, so a path survives a later change of matrix unmoved. The builder
	 flattens a curve to the tolerance the state carries."

	^ pathBuilder ifNil: [
		  pathBuilder := VGPathBuilder new
			                 flatteningTolerance: state tolerance;
			                 yourself ]
]

{ #category : 'path' }
VGCairoContext >> quadraticCurveFromCurrentPoint: aStartPoint via: aControlPoint to: anEndPoint [
	"Cairo has no quadratic primitive, so the curve is raised to the cubic with the same end
	 points whose controls lie two thirds of the way to the quadratic's control point. Alexandrie
	 passes the current point as the first argument; starting there honours it and also makes the
	 call work on an empty path."

	self isInError ifTrue: [ ^ self ].
	self hasCurrentPoint ifFalse: [ self moveTo: aStartPoint ].
	self pathBuilder
		quadraticVia: (self devicePointFor: aControlPoint)
		to: (self devicePointFor: anEndPoint)
]

{ #category : 'private' }
VGCairoContext >> raise: anEndAngle above: aStartAngle [
	| angle |
	angle := anEndAngle.
	[ angle < aStartAngle ] whileTrue: [ angle := angle + Float twoPi ].
	^ angle
]

{ #category : 'private' }
VGCairoContext >> recordFillOf: aSegments [
	"One entry on the surface's display list. Nothing is rasterised here: the frame appears when
	 the list is drained, which is the first rule of the plan."

	aSegments isEmpty ifTrue: [ ^ self ].
	surface displayList add: (VGFillEntry
			 segments: aSegments
			 paint: state source
			 clip: self currentClip
			 operator: self currentOperator)
]

{ #category : 'private' }
VGCairoContext >> recordFillOfPath [
	"The fill rule and the antialiasing mode both travel inside the segment array, because the
	 backend's three messages are frozen and none of them carries either one."

	self recordFillOf: (self pathBuilder path
			 segmentsWithFillRule: state fillRule
			 antialias: state antialias)
]

{ #category : 'private' }
VGCairoContext >> recordStrokeOfPath [
	"A stroke is a fill of the widened path: the backend fills segments and knows nothing else.
	 The whole stroke style travels in the state, because the caps, joins, dashes and miter
	 limit all shape the outline."

	self recordFillOf: (VGStroker path: self pathBuilder path state: state) segments
]

{ #category : 'path' }
VGCairoContext >> rectangle: aRectangle [
	self
		rectangleX: aRectangle left
		y: aRectangle top
		width: aRectangle width
		height: aRectangle height
]

{ #category : 'path' }
VGCairoContext >> rectangleTo: anExtentPoint [
	"Always from the origin, with the argument as the extent."

	self
		rectangleX: 0.0
		y: 0.0
		width: anExtentPoint x
		height: anExtentPoint y
]

{ #category : 'path' }
VGCairoContext >> rectangleX: x y: y width: aWidth height: aHeight [
	"The width and the height may be negative, as Cairo's own rectangle allows."

	self isInError ifTrue: [ ^ self ].
	self
		moveToX: x y: y;
		lineToX: x + aWidth y: y;
		lineToX: x + aWidth y: y + aHeight;
		lineToX: x y: y + aHeight;
		closePath
]

{ #category : 'path' }
VGCairoContext >> relativeLineTo: aDeltaPoint [
	"The delta is a user-space offset from the current point. Cairo latches a no-current-point
	 failure rather than guessing an origin, and a latched context then ignores everything."

	self isInError ifTrue: [ ^ self ].
	self hasCurrentPoint ifFalse: [ ^ status := VGCairoStatus noCurrentPoint ].
	self lineTo: self currentPointInUserSpace + aDeltaPoint
]

{ #category : 'state' }
VGCairoContext >> restoreState [
	stateStack isEmpty ifTrue: [ ^ self ].
	state := stateStack removeLast
]

{ #category : 'state' }
VGCairoContext >> restoreStateAfter: aBlock [
	"The block runs with my state saved, and the state comes back even when the block raises: a
	 painting that fails must not leave the next frame transformed."
	self saveState.
	^ aBlock ensure: [ self restoreState ]
]

{ #category : 'transformations' }
VGCairoContext >> rotateByRadians: anAngle [
	self changeMatrixBy: [ :each | each rotateByRadians: anAngle ]
]

{ #category : 'transformations' }
VGCairoContext >> rotateByRadians: anAngle center: aPoint [
	self changeMatrixBy: [ :each | each rotateByRadians: anAngle center: aPoint ]
]

{ #category : 'path' }
VGCairoContext >> roundedRectangleLeft: left top: top right: right bottom: bottom tl: aTopLeftRadius tr: aTopRightRadius br: aBottomRightRadius bl: aBottomLeftRadius [
	"The four corners in order, each an arc of a quarter turn or a plain corner when its radius is
	 zero. The radii are assumed to fit: two radii on one side never exceed that side's length."

	aTopLeftRadius isZero
		ifFalse: [
			self
				arcCenterX: left + aTopLeftRadius
				centerY: top + aTopLeftRadius
				radius: aTopLeftRadius
				startAngle: Float pi
				endAngle: self class threeHalvesPi ]
		ifTrue: [ self lineToX: left y: top ].
	aTopRightRadius isZero
		ifFalse: [
			self
				arcCenterX: right - aTopRightRadius
				centerY: top + aTopRightRadius
				radius: aTopRightRadius
				startAngle: self class threeHalvesPi
				endAngle: Float twoPi ]
		ifTrue: [ self lineToX: right y: top ].
	aBottomRightRadius isZero
		ifFalse: [
			self
				arcCenterX: right - aBottomRightRadius
				centerY: bottom - aBottomRightRadius
				radius: aBottomRightRadius
				startAngle: 0.0
				endAngle: Float halfPi ]
		ifTrue: [ self lineToX: right y: bottom ].
	aBottomLeftRadius isZero
		ifFalse: [
			self
				arcCenterX: left + aBottomLeftRadius
				centerY: bottom - aBottomLeftRadius
				radius: aBottomLeftRadius
				startAngle: Float halfPi
				endAngle: Float pi ]
		ifTrue: [ self lineToX: left y: bottom ].
	self closePath
]

{ #category : 'state' }
VGCairoContext >> saveState [
	stateStack addLast: state copy
]

{ #category : 'transformations' }
VGCairoContext >> scaleBy: aPoint [
	self changeMatrixBy: [ :each | each scaleBy: aPoint ]
]

{ #category : 'transformations' }
VGCairoContext >> scaleByX: aNumber y: anotherNumber [
	self changeMatrixBy: [ :each | each scaleByX: aNumber y: anotherNumber ]
]

{ #category : 'skeleton - unit 1.8' }
VGCairoContext >> scaledFont: arg1 [
	^ self notYetImplementedIn: '1.8' selector: #scaledFont:
]

{ #category : 'transformations' }
VGCairoContext >> setIdentityMatrix [
	self changeMatrixBy: [ :each | each beIdentity ]
]

{ #category : 'skeleton - unit 1.7' }
VGCairoContext >> setOperatorClear [
	^ self notYetImplementedIn: '1.7' selector: #setOperatorClear
]

{ #category : 'private' }
VGCairoContext >> setSurface: aSurface [
	surface := aSurface
]

{ #category : 'skeleton - unit 1.8' }
VGCairoContext >> showGlyphs: arg1 [
	^ self notYetImplementedIn: '1.8' selector: #showGlyphs:
]

{ #category : 'skeleton' }
VGCairoContext >> showText: anArgument1 [
	^ self notYetImplementedIn: '1.8' selector: #showText:
]

{ #category : 'skeleton - unit 1.5' }
VGCairoContext >> source [
	^ self notYetImplementedIn: '1.5' selector: #source
]

{ #category : 'skeleton - unit 1.5' }
VGCairoContext >> sourceColor: arg1 [
	^ self notYetImplementedIn: '1.5' selector: #sourceColor:
]

{ #category : 'skeleton - unit 1.5' }
VGCairoContext >> sourceColorR: arg1 g: arg2 b: arg3 [
	^ self notYetImplementedIn: '1.5' selector: #sourceColorR:g:b:
]

{ #category : 'skeleton - unit 1.5' }
VGCairoContext >> sourceColorR: arg1 g: arg2 b: arg3 a: arg4 [
	^ self notYetImplementedIn: '1.5' selector: #sourceColorR:g:b:a:
]

{ #category : 'skeleton - unit 1.5' }
VGCairoContext >> sourcePattern: arg1 [
	^ self notYetImplementedIn: '1.5' selector: #sourcePattern:
]

{ #category : 'skeleton - unit 1.5' }
VGCairoContext >> sourceSurface: arg1 [
	^ self notYetImplementedIn: '1.5' selector: #sourceSurface:
]

{ #category : 'skeleton' }
VGCairoContext >> sourceSurface: anArgument1 x: anArgument2 y: anArgument3 [
	^ self notYetImplementedIn: '1.5' selector: #sourceSurface:x:y:
]

{ #category : 'accessing' }
VGCairoContext >> state [
	"My current graphics state: the matrix, the source, the fill rule and the clip that #saveState
	 pushes and #restoreState brings back together."
	^ state
]

{ #category : 'inspecting' }
VGCairoContext >> stateStackDescription [
	"One row for my current state and one for each state waiting under it, newest first, read from
	 the stack itself so the view shows what #restoreState will really bring back."
	^ ({ state } , stateStack reversed) withIndexCollect: [ :each :index |
		  {
			  (index = 1
				   ifTrue: [ 'current' ]
				   ifFalse: [ 'saved ' , (index - 1) printString ]).
			  each } ]
]

{ #category : 'accessing' }
VGCairoContext >> status [
	^ status
]

{ #category : 'painting' }
VGCairoContext >> stroke [
	self isInError ifTrue: [ ^ self ].
	self recordStrokeOfPath.
	self newPath
]

{ #category : 'stroke style' }
VGCairoContext >> strokeCap: anObject [
	"The cap drawn past each end of an open run: #butt, #round or #square. Alexandrie passes an
	 AeCairoStrokeCap and Cairo's own integer names the same three, so all three are accepted."

	self isInError ifTrue: [ ^ self ].
	state strokeStyle lineCap: (VGCairoStrokeStyle capFor: anObject)
]

{ #category : 'stroke style' }
VGCairoContext >> strokeDashPattern: aCollection offset: aNumber [
	"The on and off lengths along the path, and how far into the cycle the first run starts. An
	 empty pattern turns dashing off. Cairo refuses a negative length, and a pattern whose
	 lengths are all zero, with CAIRO_STATUS_INVALID_DASH; a refused pattern leaves the style as
	 it was."

	self isInError ifTrue: [ ^ self ].
	(self isValidDashPattern: aCollection)
		ifTrue: [ state strokeStyle dashPattern: aCollection offset: aNumber ]
		ifFalse: [ status := VGCairoStatus invalidDash ]
]

{ #category : 'stroke style' }
VGCairoContext >> strokeDashPattern: aCollection size: anInteger offset: aNumber [
	"AeCanvas hands over an array and the count of entries to read separately, so the count
	 rules and the tail of the array is no part of the pattern."

	self
		strokeDashPattern: (aCollection first: anInteger)
		offset: aNumber
]

{ #category : 'stroke style' }
VGCairoContext >> strokeJoin: anObject [
	"The wedge drawn where two segments meet: #miter, #round or #bevel. Alexandrie passes an
	 AeCairoStrokeJoin and Cairo's own integer names the same three, so all three are accepted."

	self isInError ifTrue: [ ^ self ].
	state strokeStyle lineJoin: (VGCairoStrokeStyle joinFor: anObject)
]

{ #category : 'stroke style' }
VGCairoContext >> strokeJoinMiterLimit: aNumber [
	"How far a miter join may run out from the vertex, as a multiple of half the line width.
	 Cairo draws the bevel instead once the tip would pass it."

	self isInError ifTrue: [ ^ self ].
	state strokeStyle miterLimit: aNumber asFloat
]

{ #category : 'painting' }
VGCairoContext >> strokePreservingPath [
	self isInError ifTrue: [ ^ self ].
	self recordStrokeOfPath
]

{ #category : 'stroke style' }
VGCairoContext >> strokeSize: aNumber [
	"The line width, in user space. Cairo's own name for it is the line width; Alexandrie calls
	 it the stroke size and that is the name the inventory holds."

	self isInError ifTrue: [ ^ self ].
	state lineWidth: aNumber
]

{ #category : 'accessing' }
VGCairoContext >> surface [
	^ surface
]

{ #category : 'stroke style' }
VGCairoContext >> tolerance: aNumber [
	"How far a flattened curve, and the polygon a round cap is drawn with, may stand from the
	 real shape, in device space. Measured, Cairo answers a tolerance of zero or less back as
	 its own minimum and keeps its status clean."

	self isInError ifTrue: [ ^ self ].
	state tolerance: aNumber.
	pathBuilder ifNotNil: [ pathBuilder flatteningTolerance: state tolerance ]
]

{ #category : 'transformations' }
VGCairoContext >> transformWith: aMatrix [
	"The argument acts first and my own matrix after it, which is cairo_transform."
	self changeMatrixBy: [ :each | each preMultiply: aMatrix ]
]

{ #category : 'transformations' }
VGCairoContext >> translateBy: aPoint [
	self changeMatrixBy: [ :each | each translateBy: aPoint ]
]

{ #category : 'transformations' }
VGCairoContext >> translateByX: aNumber y: anotherNumber [
	self changeMatrixBy: [ :each | each translateByX: aNumber y: anotherNumber ]
]

{ #category : 'fill rule' }
VGCairoContext >> useFillRuleEvenOdd [
	self fillRule: #evenOdd
]

{ #category : 'fill rule' }
VGCairoContext >> useFillRuleWinding [
	self fillRule: #winding
]

{ #category : 'stroke style' }
VGCairoContext >> useStrokeCapButt [
	"Alexandrie's verb for the cap that stops at the end point."

	self strokeCap: #butt
]

{ #category : 'stroke style' }
VGCairoContext >> useStrokeCapRound [
	"Alexandrie's verb for the cap that is a half disc past the end point."

	self strokeCap: #round
]

{ #category : 'stroke style' }
VGCairoContext >> useStrokeCapSquare [
	"Alexandrie's verb for the cap that runs half the line width past the end point."

	self strokeCap: #square
]

{ #category : 'stroke style' }
VGCairoContext >> useStrokeJoinBevel [
	"Alexandrie's verb for the join that closes the turn with one straight edge."

	self strokeJoin: #bevel
]

{ #category : 'stroke style' }
VGCairoContext >> useStrokeJoinMiter [
	"Alexandrie's verb for the join that runs out to the tip, within the miter limit."

	self strokeJoin: #miter
]

{ #category : 'stroke style' }
VGCairoContext >> useStrokeJoinRound [
	"Alexandrie's verb for the join that fills the turn with a disc."

	self strokeJoin: #round
]

{ #category : 'private' }
VGCairoContext >> userPointFor: aPoint [
	^ state matrix inverted value: aPoint
]
