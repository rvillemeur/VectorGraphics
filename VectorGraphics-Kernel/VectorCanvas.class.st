"
A canvas specially built for Morphic 3.

self runningWorld backgroundImage displayAt: 0@0. (VectorCanvas onForm: Display) fullDraw: self runningWorld. Display copy inspect.
Display writePNGfileNamed: 'm3z.png'

On any Morph:
| c |
c := VectorCanvas onForm: Display.
self allOwnersReverseDo: [ :m | c into: m ].
c fullDraw: self.
Display forceToScreen
"
Class {
	#name : #VectorCanvas,
	#superclass : #Canvas,
	#instVars : [
		'boundsFinderEngine',
		'form',
		'engine',
		'currentMorph',
		'clippingMorphDisplayBounds',
		'currentTransformation'
	],
	#category : #'VectorGraphics-Kernel'
}

{ #category : #'class initialization' }
VectorCanvas class >> initialize [

	"	VectorCanvas initialize
			0.33: r - b
			0.1: b - r
				"

	" AffineTransformation doIntegerTransformations: false"

	
]

{ #category : #'Morphic support' }
VectorCanvas >> boundingRectOfCurrentMorphAfterDraw [

	"In targetForm coordinates.
	Clipped to owner if appropriate.
	Only valid _after_ drawing currentMorph."

	^ clippingMorphDisplayBounds
		  ifNotNil: [ :ownerClips | 
		  engine morphBoundsAfterDraw intersect: ownerClips ]
		  ifNil: [ engine morphBoundsAfterDraw ]
]

{ #category : #'Morphic support' }
VectorCanvas >> clippingMorph: aMorph [

	engine clippingMorph: aMorph
]

{ #category : #paths }
VectorCanvas >> closePath [

	engine do_ClosePath
]

{ #category : #paths }
VectorCanvas >> cubicBezier: points [
	"points must be of size 4
	http://en.wikipedia.org/wiki/Bezier_curve"

	| start control1 control2 end |
	start := points first.
	control1 := points second.
	control2 := points third.
	end := points fourth.
	engine abs_MoveToX: start x y: start y.
	engine
		abs_CubicBezierToX: end x y: end y
		control1X: control1 x y: control1 y
		control2X: control2 x y: control2 y
]

{ #category : #paths }
VectorCanvas >> curveToX: xTo y: yTo control1X: xC1 y: yC1 control2X: xC2 y: yC2 [

	engine
		abs_CubicBezierToX: xTo
		y: yTo
		control1X: xC1
		y: yC1
		control2X: xC2
		y: yC2
]

{ #category : #private }
VectorCanvas >> doSubPixelAntiAliasing [

	"
	Instead of just whole pixel anti-aliasing.
	"

	engine := VectorEngineSubPixel onForm: form.
	self newClipRect: nil
]

{ #category : #'drawing - icons' }
VectorCanvas >> drawButtonIconFromCurrentMorph [

	currentMorph iconName ifNotNil: [ :selector | 
		self perform: selector.
		^ true ].
	^ false
]

{ #category : #'drawing - icons' }
VectorCanvas >> drawCloseIcon [

	self strokeWidth: 1.0 color: Color black do: [ 
		self
			ellipseCenterX: 9
			y: 9
			rx: 6
			ry: 6 ]
]

{ #category : #'drawing - icons' }
VectorCanvas >> drawCollapseIcon [

	self drawCloseIcon
]

{ #category : #'drawing - icons' }
VectorCanvas >> drawDownIcon [

	self drawCloseIcon
]

{ #category : #'drawing - icons' }
VectorCanvas >> drawExpandIcon [

	self drawCloseIcon
]

{ #category : #'drawing - icons' }
VectorCanvas >> drawLeftIcon [

	self drawCloseIcon
]

{ #category : #'drawing - icons' }
VectorCanvas >> drawMenuIcon [

	self drawCloseIcon
]

{ #category : #'drawing - icons' }
VectorCanvas >> drawRightIcon [

	self drawCloseIcon
]

{ #category : #'drawing - text' }
VectorCanvas >> drawString: aString from: firstIndex to: lastIndex at: aPoint font: fontOrNil color: aColor [

	"
| s c f |
c := VectorCanvas onForm: Display.
c engine geometryTransformation: (AffineTransformation withRadians: 0.1).
f := FontFamily familyName: 'DejaVu Sans' pointSize: 72.
s := 'Latin text in VectorGraphics'.
c drawString:  s from: 1 to: s size at: 10@10 font: f color: Color black.
Display forceToScreen
	"

	"Slight optimization when there's nothing to do."

	"
	port clipHeight = 0 ifTrue: [^self].
	port clipWidth = 0 ifTrue: [^self].
	"

	"	| font |
	font := FontFamily defaultOrTrueTypeFamilyAndPointSize.
	^font
		ifNil: [ aPoint ] 
		ifNotNil: [
			engine
				displayString: aString
				from: firstIndex
				to: lastIndex
				at: aPoint + (0@(font ascent + font lineGap-1))
				trueTypeFont: font fontDescription
				useST80Glyphs: font isST80Glyphs
				color: aColor
				scaleX: 1.0 * font pointSize
				scaleY: -1.0 * font pointSize ]"

	"The conversion from top of glyph (morphic canvas) to baseline (engine, TrueType) is done here.
	The conversion from Y-increases-downwards (morphic canvas) to Y-increases-upwards (engine, TrueType) is done here.
	
	The scaling of internal TrueType integer points to FloatingPoint where[0.0...1.0] equals #letterMTopSideBearing is done in the engine.
	It should actually be done in TrueType. No one else cares!"

	
]

{ #category : #'drawing - icons' }
VectorCanvas >> drawUpIcon [

	self drawCloseIcon
]

{ #category : #'drawing - text' }
VectorCanvas >> drawUtf8: aByteArray at: aPoint font: aTrueTypeFont color: aColor [

	"
| c f |
Preferences disable: #loadOnlyLatinGlyphData. 'And now load optional fonts'.
c := VectorCanvas onForm: Display.
f := FontFamily familyName: 'DejaVu Sans' pointSize: 72.
c drawString: 'Hola' at: 10@10 font: f color: Color random.
c drawUtf8: #[208 176 208 177 208 178 208 179 208 180 208 181 209 145 208 182 208 183 208 184 208 185 208 186 208 187 208 188 208 189 208 190 209 143 209 142 209 141 209 140 209 139 209 138 209 137 209 136 209 135 209 134 209 133 209 132 209 131 209 130 209 129 209 128 208 191] at: 10@100 font: f color: Color random.
c drawUtf8:  #[208 146 208 190 209 130 32 208 184 208 183 32 208 181 208 189 32 208 184 208 179 208 183 208 176 208 188 208 191 208 187 32 208 190 209 132 32 208 181 208 189 32 208 152 208 189 208 179 208 187 208 184 209 136 32 209 130 208 181 208 186 209 129 209 130 32 209 128 208 184 209 130 208 189 32 208 184 208 189 32 208 180 32 208 161 208 184 209 128 208 184 208 187 208 184 208 186 32 208 176 208 187 209 132 208 176 208 177 208 181 209 130 63]  at: 10@200 font: f color: Color random.
c drawString: 'a񯧠at: 10@300 font: f color: Color random.
c drawUtf8:  #[97 195 177 111 ]  at: 10@400 font: f color: Color random.
Display forceToScreen
	"

	"Slight optimization when there's nothing to do."

	"
	port clipHeight = 0 ifTrue: [^self].
	port clipWidth = 0 ifTrue: [^self].
	"

	"| font |
	font := aTrueTypeFont ifNil: [ FreeTypeFontFamily  defaultFamilyAndPointSize ].
	engine
		displayUtf8: aByteArray
		at: aPoint + (0@font ascent + font lineGap-1)
		trueTypeFont: font fontDescription
		color: aColor
		scaleX: 1.0 * font pointSize
		scaleY: -1.0 * font pointSize"

	"The conversion from top of glyph (morphic canvas) to baseline (engine, TrueType) is done here.
	The conversion from Y-increases-downwards (morphic canvas) to Y-increases-upwards (engine, TrueType) is done here.
	
	The scaling of internal TrueType integer points to FloatingPoint where[0.0...1.0] equals #letterMTopSideBearing is done in the engine.
	It should actually be done in TrueType. No one else cares!"

	
]

{ #category : #paths }
VectorCanvas >> ellipseCenterX: mcx y: mcy rx: mrx ry: mry [

	engine
		abs_EllipseCenterX: mcx
		y: mcy
		radiusX: mrx
		radiusY: mry
]

{ #category : #'drawing - FormCanvas protocol' }
VectorCanvas >> ellipseCenterX: mcx y: mcy rx: mrx ry: mry borderWidth: morphStrokeWidth borderColor: strokeColorOrGradient fillColor: fillColorOrGradient [

	self
		strokeWidth: morphStrokeWidth
		color: strokeColorOrGradient
		fillColor: fillColorOrGradient
		do: [ 
			self
				ellipseCenterX: mcx
				y: mcy
				rx: mrx
				ry: mry ]
]

{ #category : #accessing }
VectorCanvas >> engine [

	^ engine
]

{ #category : #'context and parameters for path' }
VectorCanvas >> fillColor: aFillColor do: pathCommandsBlock [

	"Prepare parameters for drawing stroke, fill, or both."

	engine fillColor: aFillColor do: pathCommandsBlock
]

{ #category : #'drawing - FormCanvas protocol' }
VectorCanvas >> fillRectangle: aRectangle color: aColor [

	"For BitBltCanvas protocol, aRectangle:
	- uses Squeak / Smalltalk-80 convention: do include topLeft, but don't include bottomRight. (too pixel oriented for M3 taste)"

	self fillColor: aColor do: [ 
		self
			rectangleMinX: aRectangle left - 0.5
			maxX: aRectangle right - 0.5
			minY: aRectangle top - 0.5
			maxY: aRectangle bottom - 0.5 ]
]

{ #category : #'drawing - FormCanvas protocol' }
VectorCanvas >> fillRectangle: aRectangle color: aColor borderWidth: morphStrokeWidth borderStyleSymbol: aSymbol baseColorForBorder: baseColorForBorder [

	"For BitBltCanvas protocol, aRectangle:
	- means the bounding rectangle of the affected pixels, not the rectangle followed by the tip
	- uses Squeak / Smalltalk-80 convention: do include topLeft, but don't include bottomRight. (too pixel oriented for M3 taste)"

	| brColor tlColor d1 d2 |
	d1 := morphStrokeWidth * 0.5 - 0.5.
	d2 := morphStrokeWidth * 0.5 + 0.5.
	tlColor := baseColorForBorder.
	aSymbol == #raised ifTrue: [ 
		tlColor := baseColorForBorder quiteWhiter.
		brColor := baseColorForBorder quiteBlacker ].

	aSymbol == #inset ifTrue: [ 
		tlColor := baseColorForBorder quiteBlacker.
		brColor := baseColorForBorder quiteWhiter ].

	self
		strokeWidth: morphStrokeWidth
		color: tlColor
		fillColor: aColor
		do: [ 
			self
				rectangleMinX: aRectangle left + d1
				maxX: aRectangle right - d2
				minY: aRectangle top + d1
				maxY: aRectangle bottom - d2 ].

	brColor ifNotNil: [ 
		self strokeWidth: morphStrokeWidth color: brColor do: [ 
			self moveToX: aRectangle left + d1 y: aRectangle bottom - d2.
			self lineToX: aRectangle right - d2 y: aRectangle bottom - d2.
			self lineToX: aRectangle right - d2 y: aRectangle top + d1 ] ]
]

{ #category : #'drawing - FormCanvas protocol' }
VectorCanvas >> frameAndFillRectangle: aRectangle fillColor: aColor borderWidth: borderWidth borderColor: borderColor [

	"For BitBltCanvas protocol, aRectangle:
	- uses Squeak / Smalltalk-80 convention: do include topLeft, but don't include bottomRight. (too pixel oriented for M3 taste)"

	self
		strokeWidth: borderWidth
		color: borderColor
		fillColor: aColor
		do: [ 
			self
				rectangleMinX: aRectangle left - 0.5
				maxX: aRectangle right - 0.5
				minY: aRectangle top - 0.5
				maxY: aRectangle bottom - 0.5 ]
]

{ #category : #'drawing - FormCanvas protocol' }
VectorCanvas >> frameRectangle: aRectangle borderWidth: borderWidth color: borderColor [

	"For BitBltCanvas protocol, aRectangle:
	- means the bounding rectangle of the affected pixels, not the rectangle followed by the tip
	- uses Squeak / Smalltalk-80 convention: do include topLeft, but don't include bottomRight. (too pixel oriented for M3 taste)"

	| d1 d2 |
	d1 := borderWidth * 0.5 - 0.5.
	d2 := borderWidth * 0.5 + 0.5.

	self strokeWidth: borderWidth color: borderColor do: [ 
		self
			rectangleMinX: aRectangle left + d1
			maxX: aRectangle right - d2
			minY: aRectangle top + d1
			maxY: aRectangle bottom - d2 ]
]

{ #category : #'drawing - FormCanvas protocol' }
VectorCanvas >> image: aForm multipliedBy: aColor at: aPoint [

	"NO quiero usar imagenes en M3... ver como hacer... quizas meter un servicio en el canvas que en m2 use imagenes y en m3 no..."

	"no!!!!"

	"	self halt"

	super image: aForm multipliedBy: aColor at: aPoint
]

{ #category : #'Morphic support' }
VectorCanvas >> initializeWith: aForm origin: aPoint [

	super initializeWith: aForm origin: aPoint.
	engine geometryTransformation: currentTransformation
]

{ #category : #'Morphic support' }
VectorCanvas >> into: aMorph [

	super into: aMorph.
	engine currentMorph: currentMorph.
	engine geometryTransformation: currentTransformation.
	engine resetMorphBounds
]

{ #category : #'drawing - FormCanvas protocol' }
VectorCanvas >> line: pt1 to: pt2 width: morphStrokeWidth color: aStrokeColor [

	self strokeWidth: morphStrokeWidth color: aStrokeColor do: [ 
		self moveToX: pt1 x y: pt1 y.
		self lineToX: pt2 x y: pt2 y ]
]

{ #category : #paths }
VectorCanvas >> lineToX: xTo y: yTo [

	engine abs_LineToX: xTo y: yTo
]

{ #category : #'Morphic support' }
VectorCanvas >> morph: aMorph isAtPoint: aPoint [

	^ engine morph: aMorph isAtPoint: aPoint
]

{ #category : #paths }
VectorCanvas >> moveToX: x y: y [

	engine abs_MoveToX: x y: y
]

{ #category : #'paths - sequences' }
VectorCanvas >> multiArc: coordinatesAreRelative rs: rs xAxisRotations: xAxisRotations toPoints: toPoints doLargerArcs: doLargerArcs useIncreasingAngless: useIncreasingAngless [

	| to r |
	coordinatesAreRelative
		ifFalse: [ 
			1 to: toPoints size do: [ :i | 
				to := toPoints at: i.
				r := rs at: i.
				engine
					abs_ArcToX: to x
					y: to y
					radiusX: r x
					radiusY: r y
					angleOfXAxis: (xAxisRotations at: i)
					largeFlag: (doLargerArcs at: i)
					sweepFlag: (useIncreasingAngless at: i) ] ]
		ifTrue: [ 
			1 to: toPoints size do: [ :i | 
				to := toPoints at: i.
				r := rs at: i.
				engine
					rel_ArcToX: to x
					y: to y
					radiusX: r x
					radiusY: r y
					angleOfXAxis: (xAxisRotations at: i)
					largeFlag: (doLargerArcs at: i)
					sweepFlag: (useIncreasingAngless at: i) ] ]
]

{ #category : #'paths - sequences' }
VectorCanvas >> multiCurveTo: coordinatesAreRelative toPoints: toPoints control1Points: control1Points control2Points: control2Points [

	| c1 c2 to |
	coordinatesAreRelative
		ifFalse: [ 
			1 to: toPoints size do: [ :i | 
				to := toPoints at: i.
				c1 := control1Points at: i.
				c2 := control2Points at: i.
				engine
					abs_CubicBezierToX: to x
					y: to y
					control1X: c1 x
					y: c1 y
					control2X: c2 x
					y: c2 y ] ]
		ifTrue: [ 
			1 to: toPoints size do: [ :i | 
				to := toPoints at: i.
				c1 := control1Points at: i.
				c2 := control2Points at: i.
				engine
					rel_CubicBezierToX: to x
					y: to y
					control1X: c1 x
					y: c1 y
					control2X: c2 x
					y: c2 y ] ]
]

{ #category : #'paths - sequences' }
VectorCanvas >> multiCurveToSmooth: coordinatesAreRelative toPoints: toPoints control2Points: control2Points [

	| c2 to |
	coordinatesAreRelative
		ifFalse: [ 
			1 to: toPoints size do: [ :i | 
				to := toPoints at: i.
				c2 := control2Points at: i.
				engine
					abs_CubicBezierSmoothToX: to x
					y: to y
					control2X: c2 x
					y: c2 y ] ]
		ifTrue: [ 
			1 to: toPoints size do: [ :i | 
				to := toPoints at: i.
				c2 := control2Points at: i.
				engine
					rel_CubicBezierSmoothToX: to x
					y: to y
					control2X: c2 x
					y: c2 y ] ]
]

{ #category : #'paths - sequences' }
VectorCanvas >> multiLineTo: coordinatesAreRelative points: toPoints [

	| to |
	coordinatesAreRelative
		ifFalse: [ 
			1 to: toPoints size do: [ :i | 
				to := toPoints at: i.
				engine abs_LineToX: to x y: to y ] ]
		ifTrue: [ 
			1 to: toPoints size do: [ :i | 
				to := toPoints at: i.
				engine rel_LineToX: to x y: to y ] ]
]

{ #category : #'paths - sequences' }
VectorCanvas >> multiLineTo: coordinatesAreRelative xs: xs [

	coordinatesAreRelative
		ifFalse: [ xs do: [ :x | engine abs_LineToX: x ] ]
		ifTrue: [ xs do: [ :x | engine rel_LineToX: x y: 0 ] ]
]

{ #category : #'paths - sequences' }
VectorCanvas >> multiLineTo: coordinatesAreRelative ys: ys [

	coordinatesAreRelative
		ifFalse: [ ys do: [ :y | engine abs_LineToY: y ] ]
		ifTrue: [ ys do: [ :y | engine rel_LineToX: 0 y: y ] ]
]

{ #category : #'paths - sequences' }
VectorCanvas >> multiMoveTo: coordinatesAreRelative points: points [

	| isFirst |
	isFirst := true.
	coordinatesAreRelative
		ifFalse: [ 
			points do: [ :p | 
				isFirst
					ifTrue: [ engine abs_MoveToX: p x y: p y ]
					ifFalse: [ engine abs_LineToX: p x y: p y ].
				isFirst := false ] ]
		ifTrue: [ 
			points do: [ :p | 
				isFirst
					ifTrue: [ engine rel_MoveToX: p x y: p y ]
					ifFalse: [ engine rel_LineToX: p x y: p y ].
				isFirst := false ] ]
]

{ #category : #'paths - sequences' }
VectorCanvas >> multiQuadraticCurveTo: coordinatesAreRelative toPoints: toPoints controlPoints: controlPoints [

	| c to |
	coordinatesAreRelative
		ifFalse: [ 
			1 to: toPoints size do: [ :i | 
				to := toPoints at: i.
				c := controlPoints at: i.
				engine
					abs_QuadraticBezierToX: to x
					y: to y
					controlX: c x
					y: c y ] ]
		ifTrue: [ 
			1 to: toPoints size do: [ :i | 
				to := toPoints at: i.
				c := controlPoints at: i.
				engine
					rel_QuadraticBezierToX: to x
					y: to y
					controlX: c x
					y: c y ] ]
]

{ #category : #'paths - sequences' }
VectorCanvas >> multiQuadraticCurveToSmooth: coordinatesAreRelative toPoints: toPoints [

	| to |
	coordinatesAreRelative
		ifFalse: [ 
			1 to: toPoints size do: [ :i | 
				to := toPoints at: i.
				engine abs_QuadraticBezierSmoothToX: to x y: to y ] ]
		ifTrue: [ 
			1 to: toPoints size do: [ :i | 
				to := toPoints at: i.
				engine rel_QuadraticBezierSmoothToX: to x y: to y ] ]
]

{ #category : #'Morphic support' }
VectorCanvas >> outOfMorph [

	super outOfMorph.
	engine currentMorph: currentMorph.
	engine geometryTransformation: currentTransformation
]

{ #category : #paths }
VectorCanvas >> polyLine: points [

	| p |
	p := points first.
	engine abs_MoveToX: p x y: p y.
	2 to: points size do: [ :i | 
		p := points at: i.
		engine abs_LineToX: p x y: p y ]
]

{ #category : #paths }
VectorCanvas >> quadraticBezier: points [

	"points must be of size 3
	http://en.wikipedia.org/wiki/Bezier_curve"

	| start control end |
	start := points first.
	control := points second.
	end := points third.
	engine abs_MoveToX: start x y: start y.
	engine
		abs_QuadraticBezierToX: end x
		y: end y
		controlX: control x
		y: control y
]

{ #category : #paths }
VectorCanvas >> rectangleMinX: xMin maxX: xMax minY: yMin maxY: yMax [

	engine
		abs_MoveToX: xMin y: yMin;
		abs_LineToX: xMax y: yMin;
		abs_LineToX: xMax y: yMax;
		abs_LineToX: xMin y: yMax;
		do_ClosePath
]

{ #category : #'Morphic support' }
VectorCanvas >> restorePatch: savedPatch [

	"Argument must previously be obtained by calling #savePatch:bounds:
	Senders should not assume anything about the returned object, except that it will not be nil."

	| savedIdsPatch hack bb savedDisplayPatch |
	"	super restorePatch: savedPatch first.""aForm := savedPatch first.
	self image: aForm
		at: aForm offset
		sourceRect: aForm boundingBox."
	savedDisplayPatch := savedPatch first.
	bb := BitBlt toForm: form.
	bb
		sourceForm: savedDisplayPatch;
		combinationRule: Form over;
		sourceX: 0;
		sourceY: 0;
		destX: savedDisplayPatch offset x
		destY: savedDisplayPatch offset y
		width: savedDisplayPatch width
		height: savedDisplayPatch height;
		copyBits.

	"Tanto el hack como el bb podrian guardarse."
	savedIdsPatch := savedPatch second.
	hack := Form
		        extent: form extent
		        depth: 32
		        bits: (engine instVarNamed: 'morphIds').
	bb := BitBlt toForm: hack.
	bb
		sourceForm: savedIdsPatch;
		combinationRule: Form over;
		sourceX: 0;
		sourceY: 0;
		destX: savedIdsPatch offset x
		destY: savedIdsPatch offset y
		width: savedIdsPatch width
		height: savedIdsPatch height;
		copyBits
]

{ #category : #paths }
VectorCanvas >> roundBottomRectangleMinX: xMin maxX: xMax minY: yMin maxY: yMax rx: mrx ry: mry [

	| corner1 corner2 corner3 corner4 dx dy p5 p6 p7 p8 |
	(mrx = 0.0 or: [ mry = 0.0 ]) ifTrue: [ 
		^ self
			  rectangleMinX: xMin
			  maxX: xMax
			  minY: yMin
			  maxY: yMax ].

	corner1 := xMin @ yMin.
	corner2 := xMax @ yMin.
	corner3 := xMax @ yMax.
	corner4 := xMin @ yMax.
	dx := mrx @ 0.
	dy := 0 @ mry.
	p5 := corner3 - dy.
	p6 := corner3 - dx.
	p7 := corner4 + dx.
	p8 := corner4 - dy.
	"
	rx := dx r.
	ry := dy r.
	phi := dx theta.
	doLargerArc := false.
	useIncreasingAngles := true.
	"
	engine
		abs_MoveToX: corner1 x y: corner1 y;
		abs_LineToX: corner2 x y: corner2 y;
		abs_LineToX: p5 x y: p5 y;
		"		abs_ArcToX: p6 x y: p6 y radiusX: rx radiusY: ry angleOfXAxis: phi largeFlag: doLargerArc sweepFlag: useIncreasingAngles;"
		abs_QuadraticBezierToX: p6 x
		y: p6 y
		controlX: corner3 x
		y: corner3 y;
		abs_LineToX: p7 x y: p7 y;
		"		abs_ArcToX: p8 x y: p8 y radiusX: rx radiusY: ry angleOfXAxis: phi largeFlag: doLargerArc sweepFlag: useIncreasingAngles;"
		abs_QuadraticBezierToX: p8 x
		y: p8 y
		controlX: corner4 x
		y: corner4 y;
		do_ClosePath
]

{ #category : #'drawing - FormCanvas protocol' }
VectorCanvas >> roundRect: aRectangle color: aColor radius: r [

	"For BitBltCanvas protocol, aRectangle:
		- uses Squeak / Smalltalk-80 convention: do include topLeft, but don't include bottomRight. (too pixel oriented for M3 taste)"

	self fillColor: aColor do: [ 
		self
			roundRectangleMinX: aRectangle left - 0.5
			maxX: aRectangle right - 0.5
			minY: aRectangle top - 0.5
			maxY: aRectangle bottom - 0.5
			rx: r
			ry: r ]
]

{ #category : #paths }
VectorCanvas >> roundRectangleMinX: xMin maxX: xMax minY: yMin maxY: yMax rx: mrx ry: mry [

	| corner1 corner2 corner3 corner4 dx dy p1 p2 p3 p4 p5 p6 p7 p8 |
	(mrx = 0.0 or: [ mry = 0.0 ]) ifTrue: [ 
		^ self
			  rectangleMinX: xMin
			  maxX: xMax
			  minY: yMin
			  maxY: yMax ].

	corner1 := xMin @ yMin.
	corner2 := xMax @ yMin.
	corner3 := xMax @ yMax.
	corner4 := xMin @ yMax.
	dx := mrx @ 0.
	dy := 0 @ mry.
	p1 := corner1 + dy.
	p2 := corner1 + dx.
	p3 := corner2 - dx.
	p4 := corner2 + dy.
	p5 := corner3 - dy.
	p6 := corner3 - dx.
	p7 := corner4 + dx.
	p8 := corner4 - dy.
	"
	rx := dx r.
	ry := dy r.
	phi := dx theta.
	doLargerArc := false.
	useIncreasingAngles := true.
	"
	engine
		abs_MoveToX: p1 x y: p1 y;
		"		abs_ArcToX: p2 x y: p2 y radiusX: rx radiusY: ry angleOfXAxis: phi largeFlag: doLargerArc sweepFlag: useIncreasingAngles;"
		abs_QuadraticBezierToX: p2 x
		y: p2 y
		controlX: corner1 x
		y: corner1 y;
		abs_LineToX: p3 x y: p3 y;
		"		abs_ArcToX: p4 x y: p4 y radiusX: rx radiusY: ry angleOfXAxis: phi largeFlag: doLargerArc sweepFlag: useIncreasingAngles;"
		abs_QuadraticBezierToX: p4 x
		y: p4 y
		controlX: corner2 x
		y: corner2 y;
		abs_LineToX: p5 x y: p5 y;
		"		abs_ArcToX: p6 x y: p6 y radiusX: rx radiusY: ry angleOfXAxis: phi largeFlag: doLargerArc sweepFlag: useIncreasingAngles;"
		abs_QuadraticBezierToX: p6 x
		y: p6 y
		controlX: corner3 x
		y: corner3 y;
		abs_LineToX: p7 x y: p7 y;
		"		abs_ArcToX: p8 x y: p8 y radiusX: rx radiusY: ry angleOfXAxis: phi largeFlag: doLargerArc sweepFlag: useIncreasingAngles;"
		abs_QuadraticBezierToX: p8 x
		y: p8 y
		controlX: corner4 x
		y: corner4 y;
		do_ClosePath
]

{ #category : #paths }
VectorCanvas >> roundTopRectangleMinX: xMin maxX: xMax minY: yMin maxY: yMax rx: mrx ry: mry [

	| corner1 corner2 corner3 corner4 dx dy p1 p2 p3 p4 |
	(mrx = 0.0 or: [ mry = 0.0 ]) ifTrue: [ 
		^ self
			  rectangleMinX: xMin
			  maxX: xMax
			  minY: yMin
			  maxY: yMax ].

	corner1 := xMin @ yMin.
	corner2 := xMax @ yMin.
	corner3 := xMax @ yMax.
	corner4 := xMin @ yMax.
	dx := mrx @ 0.
	dy := 0 @ mry.
	p1 := corner1 + dy.
	p2 := corner1 + dx.
	p3 := corner2 - dx.
	p4 := corner2 + dy.
	"
	rx := dx r.
	ry := dy r.
	phi := dx theta.
	doLargerArc := false.
	useIncreasingAngles := true.
	"
	engine
		abs_MoveToX: p1 x y: p1 y;
		"		abs_ArcToX: p2 x y: p2 y radiusX: rx radiusY: ry angleOfXAxis: phi largeFlag: doLargerArc sweepFlag: useIncreasingAngles;"
		abs_QuadraticBezierToX: p2 x
		y: p2 y
		controlX: corner1 x
		y: corner1 y;
		abs_LineToX: p3 x y: p3 y;
		"		abs_ArcToX: p4 x y: p4 y radiusX: rx radiusY: ry angleOfXAxis: phi largeFlag: doLargerArc sweepFlag: useIncreasingAngles;"
		abs_QuadraticBezierToX: p4 x
		y: p4 y
		controlX: corner2 x
		y: corner2 y;
		abs_LineToX: corner3 x y: corner3 y;
		abs_LineToX: corner4 x y: corner4 y;
		do_ClosePath
]

{ #category : #'Morphic support' }
VectorCanvas >> savePatch: prevSavedPatch bounds: aRectangle [

	"Senders don't need to know any details of what is answered, but just store it for further calls, and calls to restorePatch:"

	"Details: The previously used patch Form is recycled when possible to reduce the burden on storage management."

	| patchForm savedIdsPatch hack bb answer morphIds |
	self flag: #jmvHacks.
	answer := prevSavedPatch.
	(answer is: #Array) ifFalse: [ answer := Array new: 2 ].
	patchForm := super savePatch: answer first bounds: aRectangle.

	patchForm == answer first
		ifTrue: [ 
			savedIdsPatch := answer second.
			savedIdsPatch offset: 0 @ 0 ]
		ifFalse: [ 
			savedIdsPatch := Form extent: aRectangle extent depth: 32.
			answer at: 1 put: patchForm.
			answer at: 2 put: savedIdsPatch ].

	morphIds := engine instVarNamed: 'morphIds'.
	"Tanto el hack como el bb podrian guardarse."
	hack := Form extent: form extent depth: 32 bits: morphIds.
	bb := BitBlt toForm: savedIdsPatch.
	bb
		sourceForm: hack;
		combinationRule: Form over;
		sourceX: aRectangle left;
		sourceY: aRectangle top;
		width: aRectangle width;
		height: aRectangle height;
		copyBits.
	savedIdsPatch offset: aRectangle topLeft.
	^ answer
]

{ #category : #private }
VectorCanvas >> setClipRect: aRectangle [

	"In targetForm coordinates"

	super setClipRect: aRectangle.
	engine clipRect: aRectangle
]

{ #category : #private }
VectorCanvas >> setForm: aForm [

	"
	World extent: World extent
	"

	aForm depth = 32 ifFalse: [ 
		self error: 'VectorCanvas can only work on 32 bit destination' ].
	form := aForm.
	engine := VectorEngineWholePixel onForm: form.
	boundsFinderEngine := VectorEngineBoundsFinder onForm: form.
	self newClipRect: nil
]

{ #category : #'context and parameters for path' }
VectorCanvas >> strokeWidth: morphStrokeWidth color: aStrokeColor do: pathCommandsBlock [

	"Prepare parameters for drawing stroke, fill, or both."

	"Gradients should be transformed with currentTransformation!"

	engine
		strokeWidth: morphStrokeWidth
		color: aStrokeColor
		do: pathCommandsBlock
]

{ #category : #'context and parameters for path' }
VectorCanvas >> strokeWidth: morphStrokeWidth color: aStrokeColor fillColor: aFillColor do: pathCommandsBlock [

	"Prepare parameters for drawing stroke, fill, or both."

	"Gradients should be transformed with currentTransformation!"

	engine
		strokeWidth: morphStrokeWidth
		color: aStrokeColor
		fillColor: aFillColor
		do: pathCommandsBlock
]

{ #category : #'drawing - FormCanvas protocol' }
VectorCanvas >> textComposition: aTextComposition bounds: boundddsRect color: c selectionColor: sc [

	"ojo que es un quad, o sea un rect en coordenadas del morph..."

	"	self halt"

	super
		textComposition: aTextComposition
		bounds: boundddsRect
		color: c
		selectionColor: sc
]

{ #category : #private }
VectorCanvas >> updatingMorphBoundsDo: aBlock [

	| prevEngine |
	prevEngine := engine.
	[ 
	engine := boundsFinderEngine.
	aBlock value ] ensure: [ engine := prevEngine ]
]

{ #category : #'drawing - FormCanvas protocol' }
VectorCanvas >> windowFrame: aRectangle color: aColor radius: r border: morphStrokeWidth labelHeight: lh gradientTop: topFactor gradientBottom: bottomFactor insideColor: insideColor [

	"For BitBltCanvas protocol, aRectangle:
	- means the bounding rectangle of the affected pixels, not the rectangle followed by the tip
	- uses Squeak / Smalltalk-80 convention: do include topLeft, but don't include bottomRight. (too pixel oriented for M3 taste)"

	"
	Display getCanvas windowFrame: (10@10 extent: 200@100) color: Color red radius: 10  border: 5 labelHeight: 25 gradientTop: 1.0 gradientBottom: 0.5 insideColor: Color green.
	VectorCanvas onForm: Display :: into: self runningWorld; windowFrame: (210@10 extent: 200@100) color: Color red radius: 10  border: 5 labelHeight: 25 gradientTop: 1.0 gradientBottom: 0.5 insideColor: Color green.
	Display forceToScreen
	"

	"
	| hbw |
	self strokeWidth: morphStrokeWidth color: aColor fillColor: insideColor do: [
		self roundRectangleMinX: aRectangle left maxX: aRectangle right minY: aRectangle top maxY: aRectangle bottom rx: r ry: r ].
	hbw := morphStrokeWidth *0.5.
	self fillColor: aColor do: [
		self rectangleMinX: aRectangle left+hbw maxX: aRectangle right-hbw minY: aRectangle top+hbw maxY: aRectangle top + lh-hbw ].
	"

	| d1 d2 |
	d1 := morphStrokeWidth * 0.5 - 0.5.
	d2 := morphStrokeWidth * 0.5 + 0.5.

	self
		strokeWidth: morphStrokeWidth
		color: aColor
		fillColor: aColor
		do: [ 
			self
				roundTopRectangleMinX: aRectangle left + d1
				maxX: aRectangle right - d2
				minY: aRectangle top + d1
				maxY: aRectangle top + lh - d2
				rx: r
				ry: r ].
	self
		strokeWidth: morphStrokeWidth
		color: aColor
		fillColor: insideColor
		do: [ 
			self
				roundBottomRectangleMinX: aRectangle left + d1
				maxX: aRectangle right - d2
				minY: aRectangle top + lh - d2
				maxY: aRectangle bottom - d2
				rx: r
				ry: r ]
]
