"
I hold the facts of unit 1.4: the stroke style a context carries, the caps, joins, dashes and miter limit a stroke is widened with, the tolerance a curve is flattened to and the antialiasing mode a fill is sampled with.

Every number I assert is measured against live Cairo through Alexandrie, either in the test itself or in the conformance corpus, so a fact that Cairo changes fails here rather than drifting.
"
Class {
	#name : 'VGCairoStrokeTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Cairo-Tests-Tests',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Tests'
}

{ #category : 'helpers' }
VGCairoStrokeTest >> alphaMask [
	"The alpha channel of an ARGB32 pixel, which is what tells a painted pixel from an untouched one."

	^ 16rFF000000
]

{ #category : 'helpers' }
VGCairoStrokeTest >> cairoFormOf: aBlock [
	"The same script drawn by live Cairo. A test package may name an Alexandrie class; the
	 VectorGraphics-Cairo package may not."

	| surface |
	surface := AeCairoImageSurface extent: self caseExtent.
	aBlock value: surface newContext.
	surface flush.
	^ surface asForm
]

{ #category : 'helpers' }
VGCairoStrokeTest >> caseExtent [
	"The size every picture here is drawn on, which is the size the conformance corpus uses too."

	^ 64 @ 64
]

{ #category : 'helpers' }
VGCairoStrokeTest >> formOf: aBlock [
	"The picture the replacement draws for that script."

	| surface |
	surface := VGCairoImageSurface extent: self caseExtent.
	aBlock value: surface newContext.
	surface flush.
	^ surface asForm
]

{ #category : 'helpers' }
VGCairoStrokeTest >> isPaintedIn: aForm at: aPoint [
	^ ((aForm pixelValueAt: aPoint) bitAnd: self alphaMask) ~= 0
]

{ #category : 'helpers' }
VGCairoStrokeTest >> newContext [
	^ (VGCairoImageSurface extent: self caseExtent) newContext
]

{ #category : 'private' }
VGCairoStrokeTest >> paintedBoundsIn: aForm [
	"The whole-pixel rectangle the painted pixels live in, or nil when nothing is painted. The
	 corner is one past the last painted pixel, so the rectangle's extent counts pixels."

	| painted bounds |
	painted := self paintedPointsIn: aForm.
	painted ifEmpty: [ ^ nil ].
	bounds := Rectangle encompassing: painted.
	^ bounds origin corner: bounds corner + (1 @ 1)
]

{ #category : 'helpers' }
VGCairoStrokeTest >> paintedPixelCountIn: aForm [
	"How many pixels of the picture carry any alpha at all. A shape that paints nothing answers
	 zero here, which is how a degenerate stroke is told from a stroke."

	| count |
	count := 0.
	0 to: aForm height - 1 do: [ :y |
		0 to: aForm width - 1 do: [ :x |
			(self isPaintedIn: aForm at: x @ y) ifTrue: [ count := count + 1 ] ] ].
	^ count
]

{ #category : 'private' }
VGCairoStrokeTest >> paintedPointsIn: aForm [
	"Every pixel of the form that carries any paint at all."

	^ (0 to: aForm height - 1) flatCollect: [ :y |
		  ((0 to: aForm width - 1) select: [ :x | self isPaintedIn: aForm at: x @ y ])
			  collect: [ :x | x @ y ] ]
]

{ #category : 'helpers' }
VGCairoStrokeTest >> paintedRunCountInRow: anInteger of: aForm [
	"How many separate painted stretches that row holds, which is how a dashed stroke is counted."

	| count wasPainted |
	count := 0.
	wasPainted := false.
	0 to: aForm width - 1 do: [ :x |
		| painted |
		painted := self isPaintedIn: aForm at: x @ anInteger.
		(painted and: [ wasPainted not ]) ifTrue: [ count := count + 1 ].
		wasPainted := painted ].
	^ count
]

{ #category : 'helpers' }
VGCairoStrokeTest >> strokeCaps [
	"The three caps, as Alexandrie's own enumeration objects, because a script drawn on both
	 contexts has to name a cap the way live Cairo reads it too."

	^ {
		  AeCairoStrokeCap butt.
		  AeCairoStrokeCap round.
		  AeCairoStrokeCap square }
]

{ #category : 'tests - caps' }
VGCairoStrokeTest >> testAButtCapStopsAtTheEndPointAndTheOtherTwoOverhangByHalfTheWidth [
	"The overhang is what a cap is for: a round and a square cap each reach half the line width
	 past the end point and a butt cap reaches nothing. Live Cairo is asked the same question in
	 the same test, so the expected rectangles are measured rather than assumed. A script that
	 has to draw on either context names the cap the way both of them read it, which is
	 Alexandrie's own enumeration object; our symbol spelling is the extra one and the
	 normalisation test covers it."

	| line |
	line := [ :cap |
	         [ :context |
	         context
		         strokeCap: cap;
		         strokeSize: 8;
		         lineFrom: 10 @ 32 to: 50 @ 32;
		         stroke ] ].
	self strokeCaps do: [ :cap |
		self
			assert: (self paintedBoundsIn: (self formOf: (line value: cap)))
			equals: (self paintedBoundsIn: (self cairoFormOf: (line value: cap))) ].
	self
		assert: (self paintedBoundsIn: (self formOf: (line value: AeCairoStrokeCap butt)))
		equals: (10 @ 28 corner: 50 @ 36).
	self
		assert: (self paintedBoundsIn: (self formOf: (line value: AeCairoStrokeCap square)))
		equals: (6 @ 28 corner: 54 @ 36).
	self
		assert:
		(self paintedPixelCountIn: (self formOf: (line value: AeCairoStrokeCap round)))
		< (self paintedPixelCountIn: (self formOf: (line value: AeCairoStrokeCap square)))
		description: 'a round cap is a half disc inside the half square a square cap paints'
]

{ #category : 'tests - caps' }
VGCairoStrokeTest >> testAClosedDegenerateSubPathPaintsADotUnderARoundCap [
	"A closed run of one point is still a run, which is why Cairo paints its round cap; a move
	 that closes nothing is not a run at all and paints nothing whatever the cap."

	| closed lonely |
	closed := [ :context |
	           context
		           strokeCap: AeCairoStrokeCap round;
		           strokeSize: 6;
		           moveTo: 32 @ 32;
		           closePath;
		           stroke ].
	lonely := [ :context |
	           context
		           strokeCap: AeCairoStrokeCap round;
		           strokeSize: 6;
		           moveTo: 32 @ 32;
		           stroke ].
	self assert: (self paintedPixelCountIn: (self formOf: closed)) > 0.
	self assert: (self paintedPixelCountIn: (self cairoFormOf: closed)) > 0.
	self assert: (self paintedPixelCountIn: (self formOf: lonely)) equals: 0.
	self assert: (self paintedPixelCountIn: (self cairoFormOf: lonely)) equals: 0
]

{ #category : 'tests - joins' }
VGCairoStrokeTest >> testAClosedStrokeIsJoinedAtItsStartingPointToo [
	"A closed run has a join where it comes back to its first point, and Cairo puts no cap
	 anywhere on it, so the picture must agree with Cairo's at the starting corner as well."

	| script comparison |
	script := [ :context |
	           context
		           strokeSize: 7;
		           strokeJoin: AeCairoStrokeJoin miter;
		           moveTo: 10 @ 50;
		           lineTo: 32 @ 10;
		           lineTo: 54 @ 50;
		           closePath;
		           stroke ].
	comparison := VGFormComparison
		              between: (self formOf: script)
		              and: (self cairoFormOf: script).
	self assert: comparison isComparable.
	self assert: comparison extraneousPixelCount equals: 0.
	self
		assert: comparison maximumChannelDistance
				<= VGConformanceCorpus antialiasingTolerance
		description: 'the closed join differs from Cairo by '
			, comparison maximumChannelDistance printString
]

{ #category : 'tests - dashes' }
VGCairoStrokeTest >> testADashOffsetLargerThanThePatternPeriodWraps [
	"Thirteen is the period of nine on and four off, so an offset of fifteen draws what an offset
	 of two draws."

	| script |
	script := [ :offset |
	           [ :context |
	           context
		           strokeSize: 5;
		           strokeDashPattern: #( 9 4 ) offset: offset;
		           lineFrom: 6 @ 32 to: 58 @ 32;
		           stroke ] ].
	self
		assert: (self formOf: (script value: 15)) bits
		equals: (self formOf: (script value: 2)) bits.
	self
		deny: (self formOf: (script value: 15)) bits
		equals: (self formOf: (script value: 0)) bits
]

{ #category : 'tests - dashes' }
VGCairoStrokeTest >> testADashPatternSplitsTheStrokeIntoRunsOfItsOwn [
	"Nine on, four off, along a line fifty-two long: four painted runs, and each one carries its
	 own caps because Cairo treats a dash run as a sub-path."

	| script ourForm |
	script := [ :context |
	           context
		           strokeSize: 5;
		           strokeDashPattern: #( 9 4 ) offset: 0;
		           lineFrom: 6 @ 32 to: 58 @ 32;
		           stroke ].
	ourForm := self formOf: script.
	self assert: (self paintedRunCountInRow: 32 of: ourForm) equals: 4.
	self
		assert: (self paintedRunCountInRow: 32 of: (self cairoFormOf: script))
		equals: 4
]

{ #category : 'tests - dashes' }
VGCairoStrokeTest >> testADashSizeSmallerThanTheArrayUsesOnlyThatMuchOfIt [
	"AeCanvas passes an external double array and the count separately, so the count rules: the
	 tail of the array is not part of the pattern."

	| script |
	script := [ :context |
	           context
		           strokeSize: 5;
		           strokeDashPattern: #( 9 4 99 ) size: 2 offset: 0;
		           lineFrom: 6 @ 32 to: 58 @ 32;
		           stroke ].
	self
		assert: (self formOf: script) bits
		equals: (self formOf: [ :context |
				 context
					 strokeSize: 5;
					 strokeDashPattern: #( 9 4 ) offset: 0;
					 lineFrom: 6 @ 32 to: 58 @ 32;
					 stroke ]) bits.
	self
		assert: (self newContext strokeDashPattern: #( 9 4 99 ) size: 2 offset: 0) state
				strokeStyle dashPattern
		equals: #( 9 4 )
]

{ #category : 'tests - caps' }
VGCairoStrokeTest >> testADegenerateSubPathPaintsADotOnlyUnderARoundCap [
	"Measured in live Cairo: a zero length run has no direction to orient a square cap with, so
	 Cairo draws the round cap's disc and nothing at all for the other two."

	self strokeCaps do: [ :cap |
		| script ours |
		script := [ :context |
		           context
			           strokeCap: cap;
			           strokeSize: 6;
			           moveTo: 32 @ 32;
			           lineTo: 32 @ 32;
			           stroke ].
		ours := self paintedPixelCountIn: (self formOf: script).
		(VGCairoStrokeStyle capFor: cap) == #round
			ifTrue: [ self assert: ours > 0 ]
			ifFalse: [ self assert: ours equals: 0 ].
		self
			assert: (self paintedPixelCountIn: (self cairoFormOf: script)) > 0
			equals: ours > 0 ]
]

{ #category : 'tests - defaults' }
VGCairoStrokeTest >> testAFreshContextCarriesTheStrokeDefaultsLiveCairoReports [
	"Every default is read from a live Cairo context rather than from the documentation, so the
	 two cannot drift apart."

	| ours reference style |
	ours := self newContext.
	reference := (AeCairoImageSurface extent: self caseExtent) newContext.
	style := ours state strokeStyle.
	self assert: style lineWidth equals: reference strokeSize.
	self assert: ours state tolerance equals: reference tolerance.
	self assert: reference antialias asInteger equals: 0.
	self assert: ours state antialias equals: #default.
	self deny: reference hasStrokeDashPattern.
	self deny: style hasDashPattern.
	self assert: style lineCap equals: #butt.
	self assert: style lineJoin equals: #miter.
	self assert: style miterLimit equals: 10.0
]

{ #category : 'tests - joins' }
VGCairoStrokeTest >> testAFullCircleLeavesNoWedgeWhereItsTwoEndsMeet [
	"A full circle is one run that arrives where it began and arrives there in the direction it
	 left, because cairo_arc ends with the tangent it started with. Cairo strokes the spline
	 itself, so its stroke is the whole annulus with no seam in it; ours flattens the spline, so
	 the two end chords meet at a small angle and the wedge between them has to be filled, or the
	 stroke shows a notch Cairo has not got."
	| script comparison |
	script := [ :context |
		          context
			          strokeSize: 8;
			          circleCenterX: 32 y: 32 radius: 20;
			          stroke ].
	comparison := VGFormComparison
		              between: (self formOf: script)
		              and: (self cairoFormOf: script).
	self assert: comparison isComparable.
	self assert: comparison extraneousPixelCount equals: 0.
	self
		assert: comparison maximumChannelDistance
				<= VGConformanceCorpus antialiasingTolerance
		description: 'the seam of the circle differs from Cairo by '
			, comparison maximumChannelDistance printString
]

{ #category : 'tests - joins' }
VGCairoStrokeTest >> testAMiterJoinBecomesABevelOnceItPassesTheMiterLimit [
	"Cairo compares one over the sine of half the turn with the limit, so a right angle needs a
	 limit of the square root of two. Measured live: the far corner pixel of a right-angled
	 corner is painted at a limit of 1.5 and left alone at 1.3, and a bevel or a round join never
	 paints it."

	| corner |
	corner := [ :join :limit |
	           [ :context |
	           context
		           strokeSize: 8;
		           strokeJoin: join;
		           strokeJoinMiterLimit: limit;
		           moveTo: 12 @ 32;
		           lineTo: 32 @ 32;
		           lineTo: 32 @ 12;
		           stroke ] ].
	self assert: (2 sqrt between: 1.3 and: 1.5).
	{
		(AeCairoStrokeJoin miter -> 1.5) -> true.
		(AeCairoStrokeJoin miter -> 1.3) -> false.
		(AeCairoStrokeJoin bevel -> 10) -> false.
		(AeCairoStrokeJoin round -> 10) -> false } do: [ :each |
		| script |
		script := corner value: each key key value: each key value.
		self
			assert: (self isPaintedIn: (self formOf: script) at: 35 @ 35)
			equals: each value.
		self
			assert: (self isPaintedIn: (self cairoFormOf: script) at: 35 @ 35)
			equals: each value ]
]

{ #category : 'tests - dashes' }
VGCairoStrokeTest >> testAPatternOfOneLengthAlternatesOnAndOffWithThatLength [
	"Cairo reads a single length as that much on and that much off, so the period is twice the
	 length: an offset of eight draws what an offset of nothing draws and an offset of four draws
	 the gaps instead."

	| script |
	script := [ :offset |
	           [ :context |
	           context
		           strokeSize: 5;
		           strokeDashPattern: #( 4 ) offset: offset;
		           lineFrom: 6 @ 32 to: 58 @ 32;
		           stroke ] ].
	self
		assert: (self formOf: (script value: 8)) bits
		equals: (self formOf: (script value: 0)) bits.
	self
		deny: (self formOf: (script value: 4)) bits
		equals: (self formOf: (script value: 0)) bits.
	self
		assert: (self paintedPixelCountIn: (self formOf: (script value: 0)))
		equals: (self paintedPixelCountIn: (self cairoFormOf: (script value: 0)))
]

{ #category : 'tests - joins' }
VGCairoStrokeTest >> testARunOfLinesThatComesBackToItsStartIsStillCappedThere [
	"Coming back to the first point is not a close: Cairo caps both ends of such a run and leaves
	 the outer corner between them unpainted. Measured on a live Cairo surface, which is what
	 keeps a seam join from being drawn where Cairo draws none."
	| script comparison |
	script := [ :context |
		          context
			          strokeSize: 8;
			          strokeJoin: AeCairoStrokeJoin miter;
			          moveTo: 16 @ 16;
			          lineTo: 48 @ 16;
			          lineTo: 48 @ 48;
			          lineTo: 16 @ 48;
			          lineTo: 16 @ 16;
			          stroke ].
	self
		deny: (self isPaintedIn: (self formOf: script) at: 13 @ 13)
		description: 'the corner between the two caps is painted as though the seam were joined'.
	comparison := VGFormComparison
		              between: (self formOf: script)
		              and: (self cairoFormOf: script).
	self assert: comparison isComparable.
	self assert: comparison extraneousPixelCount equals: 0.
	self assert: comparison maximumChannelDistance equals: 0
]

{ #category : 'tests - naming' }
VGCairoStrokeTest >> testAStrokeCapIsNamedBySymbolByCodeAndByAlexandriesOwnValue [
	"AeCanvas passes Alexandrie's enumeration object, a script of ours passes a symbol, and a
	 caller reading Cairo's documentation passes the integer; the three must mean the same cap."

	#( #butt #round #square ) doWithIndex: [ :each :index |
		self assert: (self newContext strokeCap: each) state strokeStyle lineCap equals: each.
		self
			assert: (self newContext strokeCap: index - 1) state strokeStyle lineCap
			equals: each.
		self
			assert: (self newContext strokeCap: (AeCairoStrokeCap perform: each)) state
					strokeStyle lineCap
			equals: each.
		self assert: (AeCairoStrokeCap perform: each) asInteger equals: index - 1 ]
]

{ #category : 'tests - naming' }
VGCairoStrokeTest >> testAStrokeJoinIsNamedBySymbolByCodeAndByAlexandriesOwnValue [
	#( #miter #round #bevel ) doWithIndex: [ :each :index |
		self assert: (self newContext strokeJoin: each) state strokeStyle lineJoin equals: each.
		self
			assert: (self newContext strokeJoin: index - 1) state strokeStyle lineJoin
			equals: each.
		self
			assert: (self newContext strokeJoin: (AeCairoStrokeJoin perform: each)) state
					strokeStyle lineJoin
			equals: each.
		self assert: (AeCairoStrokeJoin perform: each) asInteger equals: index - 1 ]
]

{ #category : 'tests - caps' }
VGCairoStrokeTest >> testAStrokeOfZeroWidthPaintsNothing [
	"Cairo has no hairline: half of nothing is nothing on each side of the line."

	| script |
	script := [ :context |
	           context
		           strokeSize: 0;
		           lineFrom: 8 @ 32 to: 56 @ 32;
		           stroke ].
	self assert: (self paintedPixelCountIn: (self formOf: script)) equals: 0.
	self assert: (self paintedPixelCountIn: (self cairoFormOf: script)) equals: 0
]

{ #category : 'tests - dashes' }
VGCairoStrokeTest >> testAZeroLengthDashRunPaintsADotUnderARoundOrASquareCapButNotAButtCap [
	"A dash run of no length still runs along the path, so a square cap has a direction to sit on
	 and paints a square; this is the one place a square cap draws on nothing at all, and it is
	 what Cairo's own documentation offers for dotted lines."

	self strokeCaps do: [ :cap |
		| script ours |
		script := [ :context |
		           context
			           strokeSize: 6;
			           strokeCap: cap;
			           strokeDashPattern: #( 0 12 ) offset: 0;
			           lineFrom: 8 @ 32 to: 56 @ 32;
			           stroke ].
		ours := self paintedPixelCountIn: (self formOf: script).
		(VGCairoStrokeStyle capFor: cap) == #butt
			ifTrue: [ self assert: ours equals: 0 ]
			ifFalse: [ self assert: ours > 0 ].
		self
			assert: (self paintedPixelCountIn: (self cairoFormOf: script)) > 0
			equals: ours > 0 ]
]

{ #category : 'tests - antialias' }
VGCairoStrokeTest >> testAnAliasedFillPaintsWholePixelsOnly [
	"Antialiasing off means every pixel is painted or untouched, with no shade in between, which
	 is the one visible difference between the two modes we tell apart."

	| form shades |
	form := self formOf: [ :context |
		        context
			        antialias: #none;
			        circleCenterX: 32 y: 32 radius: 20;
			        fill ].
	shades := Set new.
	0 to: form height - 1 do: [ :y |
		0 to: form width - 1 do: [ :x |
			shades add: ((form pixelValueAt: x @ y) bitAnd: self alphaMask) ] ].
	self assert: shades asSortedCollection asArray equals: { 0. self alphaMask }
]

{ #category : 'tests - naming' }
VGCairoStrokeTest >> testAnAntialiasModeIsNamedBySymbolByCodeAndByAlexandriesOwnValue [
	"Cairo has seven modes and we tell only two of them apart, but a caller may name any of the
	 seven and must get the mode it named back."

	#( #default #none #gray #subpixel #fast #good #best ) doWithIndex: [ :each :index |
		self assert: (self newContext antialias: each) state antialias equals: each.
		self assert: (self newContext antialias: index - 1) state antialias equals: each.
		self
			assert: (self newContext antialias: (AeCairoAntialias perform: each)) state antialias
			equals: each.
		self assert: (AeCairoAntialias perform: each) asInteger equals: index - 1 ]
]

{ #category : 'tests - dashes' }
VGCairoStrokeTest >> testAnEmptyDashPatternTurnsDashingOff [
	"Cairo says a pattern of no lengths disables dashing, so the stroke comes back whole."

	| dashed |
	dashed := self newContext.
	dashed strokeDashPattern: #( 9 4 ) offset: 0.
	self assert: dashed state strokeStyle hasDashPattern.
	dashed strokeDashPattern: #() offset: 0.
	self deny: dashed state strokeStyle hasDashPattern.
	self
		assert: (self formOf: [ :context |
				 context
					 strokeSize: 5;
					 strokeDashPattern: #( 9 4 ) offset: 0;
					 strokeDashPattern: #() offset: 0;
					 lineFrom: 6 @ 32 to: 58 @ 32;
					 stroke ]) bits
		equals: (self formOf: [ :context |
				 context
					 strokeSize: 5;
					 lineFrom: 6 @ 32 to: 58 @ 32;
					 stroke ]) bits
]

{ #category : 'tests - dashes' }
VGCairoStrokeTest >> testAnInvalidDashPatternLatchesCairosStatusAndStopsTheDrawing [
	"Cairo reports a negative length and an all-zero pattern as CAIRO_STATUS_INVALID_DASH, code
	 nineteen, and a latched context then paints nothing. The code is read from a live Cairo
	 context here rather than written from memory."

	| reference |
	reference := (AeCairoImageSurface extent: self caseExtent) newContext.
	reference strokeDashPattern: #( 0 0 ) offset: 0.
	self assert: reference status asInteger equals: VGCairoStatus invalidDashCode.
	{ #( -1 2 ). #( 0 0 ). #( 0 ) } do: [ :pattern |
		| context |
		context := self newContext.
		context strokeDashPattern: pattern offset: 0.
		self assert: context status code equals: VGCairoStatus invalidDashCode.
		self assert: context isInError.
		self deny: context state strokeStyle hasDashPattern ].
	self
		assert: (self paintedPixelCountIn: (self formOf: [ :context |
					  context
						  strokeDashPattern: #( 0 0 ) offset: 0;
						  lineFrom: 8 @ 32 to: 56 @ 32;
						  stroke ]))
		equals: 0
]

{ #category : 'tests - conformance' }
VGCairoStrokeTest >> testEveryStrokeCaseOfTheCorpusMatchesLiveCairo [
	"The gate of the unit: the cap, join, dash and antialias cases are rendered twice from one
	 script, once by the replacement and once by Cairo, and must agree."

	| cases |
	cases := VGConformanceCorpus strokeCases.
	self assert: cases size equals: 4.
	cases do: [ :each |
		self
			assert: each blockingFailure isNil
			description: each name , ' still stops on a skeleton'.
		self
			assert: each matchesCairo
			description: each name , ' differs from Cairo: '
				, each comparisonWithCairo printString ]
]

{ #category : 'tests - state' }
VGCairoStrokeTest >> testEveryStrokeSetterIsIgnoredOnceTheContextIsInError [
	"A latched context ignores every request, which is what Cairo does, so the defaults are still
	 in place after the whole stroke vocabulary has been sent to it."

	| context |
	context := self newContext.
	context matrix: (VGCairoMatrix
			 newX: 0
			 y: 0
			 sx: 0
			 sy: 0
			 shx: 0
			 shy: 0).
	self assert: context isInError.
	context
		strokeSize: 11;
		strokeCap: #round;
		strokeJoin: #round;
		strokeJoinMiterLimit: 1;
		strokeDashPattern: #( 3 3 ) offset: 1;
		strokeDashPattern: #( 3 3 ) size: 2 offset: 1;
		tolerance: 5;
		antialias: #none;
		useStrokeCapSquare;
		useStrokeJoinBevel.
	self assert: context state strokeStyle lineWidth equals: 2.0.
	self assert: context state strokeStyle lineCap equals: #butt.
	self assert: context state strokeStyle lineJoin equals: #miter.
	self assert: context state strokeStyle miterLimit equals: 10.0.
	self deny: context state strokeStyle hasDashPattern.
	self assert: context state tolerance equals: 0.1.
	self assert: context state antialias equals: #default.
	self assert: context status code equals: VGCairoStatus invalidMatrixCode
]

{ #category : 'tests - state' }
VGCairoStrokeTest >> testSavingTheStateAndRestoringItBringsTheWholeStrokeStyleBack [
	"Cairo saves the stroke parameters with the rest of the graphics state. The saved state holds
	 a style object of its own, so the style mutated while the state was saved is not the style
	 that comes back."

	| context mutated |
	context := self newContext.
	context
		strokeSize: 7;
		strokeCap: #round;
		strokeJoin: #bevel;
		strokeJoinMiterLimit: 3;
		strokeDashPattern: #( 5 2 ) offset: 1;
		tolerance: 2;
		antialias: #none.
	context saveState.
	mutated := context state strokeStyle.
	context
		strokeSize: 1;
		strokeCap: #square;
		strokeJoin: #miter;
		strokeJoinMiterLimit: 9;
		strokeDashPattern: #( 1 1 ) offset: 0;
		tolerance: 0.5;
		antialias: #best.
	context restoreState.
	self deny: context state strokeStyle == mutated.
	self assert: context state strokeStyle lineWidth equals: 7.
	self assert: context state strokeStyle lineCap equals: #round.
	self assert: context state strokeStyle lineJoin equals: #bevel.
	self assert: context state strokeStyle miterLimit equals: 3.
	self assert: context state strokeStyle dashPattern equals: #( 5 2 ).
	self assert: context state strokeStyle dashOffset equals: 1.
	self assert: context state tolerance equals: 2.
	self assert: context state antialias equals: #none
]

{ #category : 'tests - antialias' }
VGCairoStrokeTest >> testTheAntialiasModeTravelsInsideTheSegments [
	"The backend answers three messages and none of them carries a mode, so the mode rides in the
	 segment object, exactly as the fill rule does."

	| surface context entry |
	surface := VGCairoImageSurface extent: self caseExtent.
	context := surface newContext.
	context
		antialias: #none;
		circleCenterX: 32 y: 32 radius: 20;
		fill.
	entry := surface displayList entries first.
	self assert: entry segments antialias equals: #none.
	self assert: entry segments isAliased.
	self deny: VGSegments empty isAliased
]

{ #category : 'tests - outline' }
VGCairoStrokeTest >> testThePolygonsOfAnOutlineAllWindTheSameWay [
	"The outline is a union of overlapping polygons under the winding rule, so a polygon handed
	 over the wrong way round would punch a hole in the stroke. The stroker normalises the
	 winding, so the same polygon in either order gives the same edges."

	| stroker clockwise anticlockwise square |
	stroker := VGStroker path: VGPath new state: VGCairoState new.
	square := {
		          (0 @ 0).
		          (4 @ 0).
		          (4 @ 4).
		          (0 @ 4) }.
	clockwise := WriteStream on: (Array new: 16).
	anticlockwise := WriteStream on: (Array new: 16).
	stroker appendPolygon: square into: clockwise.
	stroker appendPolygon: square reversed into: anticlockwise.
	self assert: clockwise contents asArray equals: anticlockwise contents asArray
]

{ #category : 'tests - naming' }
VGCairoStrokeTest >> testTheSixUseVerbsSetTheThreeCapsAndTheThreeJoins [
	{ #useStrokeCapButt -> #butt.
	#useStrokeCapRound -> #round.
	#useStrokeCapSquare -> #square } do: [ :each |
		self
			assert: (self newContext perform: each key) state strokeStyle lineCap
			equals: each value ].
	{ #useStrokeJoinMiter -> #miter.
	#useStrokeJoinRound -> #round.
	#useStrokeJoinBevel -> #bevel } do: [ :each |
		self
			assert: (self newContext perform: each key) state strokeStyle lineJoin
			equals: each value ]
]

{ #category : 'tests - tolerance' }
VGCairoStrokeTest >> testTheToleranceReachesTheFlatteningOfACurve [
	"Tolerance is the one number that says how coarsely a curve may be approximated, so a coarse
	 tolerance must buy fewer points on the same curve than a fine one."

	| coarse fine curve |
	curve := [ :context |
	          context
		          moveTo: 6 @ 48;
		          curveVia: 20 @ 4 via: 44 @ 60 to: 58 @ 16 ].
	coarse := self newContext.
	coarse tolerance: 8.
	curve value: coarse.
	fine := self newContext.
	fine tolerance: 0.01.
	curve value: fine.
	self assert: coarse pathBuilder path pointCount < fine pathBuilder path pointCount.
	self assert: coarse pathBuilder flatteningTolerance equals: 8.
	self assert: coarse state tolerance equals: 8
]

{ #category : 'tests - tolerance' }
VGCairoStrokeTest >> testTheToleranceReachesTheVertexCountOfARoundJoin [
	"The disc a round join and a round cap are drawn with is a polygon, and the tolerance says
	 how many vertices it needs: a coarse tolerance buys fewer."

	| strokerWith |
	strokerWith := [ :tolerance |
	                | context |
	                context := self newContext.
	                context
		                tolerance: tolerance;
		                strokeSize: 20;
		                moveTo: 10 @ 10;
		                lineTo: 50 @ 50.
	                VGStroker path: context pathBuilder path state: context state ].
	self
		assert: (strokerWith value: 4) discPointCount
		< (strokerWith value: 0.01) discPointCount
]
