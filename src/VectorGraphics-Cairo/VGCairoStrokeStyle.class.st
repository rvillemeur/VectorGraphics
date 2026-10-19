"
I am the part of a graphics state a stroke is widened with: the line width, the cap at the end of an open run, the join at a turn, the miter limit a miter join falls back to a bevel at, and the dash pattern with its offset.

I hold Cairo's own defaults, which are measured from a live context in VGCairoStrokeTest: two user-space units of width, a butt cap, a miter join, a miter limit of ten and no dash.

A cap or a join may be named by one of my symbols, by Cairo's integer code or by Alexandrie's own enumeration value, because AeCanvas passes the last of the three; #capFor: and #joinFor: answer my symbol for any of them.

I am copied with the state that holds me, so a dash pattern set after a #saveState cannot reach back into the saved state.
"
Class {
	#name : 'VGCairoStrokeStyle',
	#superclass : 'Object',
	#instVars : [
		'lineWidth',
		'lineCap',
		'lineJoin',
		'miterLimit',
		'dashPattern',
		'dashOffset'
	],
	#category : 'VectorGraphics-Cairo-Context',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Context'
}

{ #category : 'converting' }
VGCairoStrokeStyle class >> capFor: anObject [
	^ self nameIn: self capNames for: anObject
]

{ #category : 'accessing' }
VGCairoStrokeStyle class >> capNames [
	"My names for Cairo's three caps, in the order of the CAIRO_LINE_CAP enumeration, so that an
	 integer code indexes this list."

	^ #( #butt #round #square )
]

{ #category : 'accessing' }
VGCairoStrokeStyle class >> defaultLineWidth [
	"Cairo's own default line width, in user-space units."

	^ 2.0
]

{ #category : 'accessing' }
VGCairoStrokeStyle class >> defaultMiterLimit [
	"Cairo's own default miter limit: a join turns into a bevel once the miter would reach ten
	 half-widths past the corner, which is a turn of about eleven degrees."

	^ 10.0
]

{ #category : 'converting' }
VGCairoStrokeStyle class >> joinFor: anObject [
	^ self nameIn: self joinNames for: anObject
]

{ #category : 'accessing' }
VGCairoStrokeStyle class >> joinNames [
	"My names for Cairo's three joins, in the order of the CAIRO_LINE_JOIN enumeration."

	^ #( #miter #round #bevel )
]

{ #category : 'converting' }
VGCairoStrokeStyle class >> nameIn: aCollection for: anObject [
	"Answer the name aCollection holds for anything that names one of its entries: the name
	 itself, Cairo's integer code, or an Alexandrie enumeration value, which answers its code to
	 #asInteger. Taking the Alexandrie value this way is what lets the VectorGraphics-Cairo
	 package stay free of Ae class names while AeCanvas passes Alexandrie's own constants
	 straight through, as VGCairoSurfaceFormat already does for a pixel format."

	^ (aCollection includes: anObject)
		  ifTrue: [ anObject ]
		  ifFalse: [ aCollection at: anObject asInteger + 1 ]
]

{ #category : 'accessing' }
VGCairoStrokeStyle >> dashLengths [
	"The cycle a dash walk really repeats. Cairo reads a pattern of an odd number of lengths as
	 alternating on and off each time round, which is the same cycle as the pattern written out
	 twice, so a single length of four means four on and four off."

	| lengths |
	lengths := dashPattern collect: [ :each | each asFloat ].
	^ lengths size odd
		  ifTrue: [ lengths , lengths ]
		  ifFalse: [ lengths ]
]

{ #category : 'accessing' }
VGCairoStrokeStyle >> dashOffset [
	^ dashOffset
]

{ #category : 'accessing' }
VGCairoStrokeStyle >> dashPattern [
	^ dashPattern
]

{ #category : 'accessing' }
VGCairoStrokeStyle >> dashPattern: aCollection offset: aNumber [
	"The lengths of the alternating on and off stretches, on first, and how far into the cycle
	 the stroke begins. An empty pattern turns dashing off, which is what Cairo does for a
	 pattern of no lengths."

	dashPattern := aCollection asArray.
	dashOffset := aNumber
]

{ #category : 'accessing' }
VGCairoStrokeStyle >> dashPeriod [
	"The length the dash cycle repeats over, which is what an offset is taken modulo."

	^ self dashLengths inject: 0.0 into: [ :sum :each | sum + each ]
]

{ #category : 'testing' }
VGCairoStrokeStyle >> hasDashPattern [
	^ dashPattern notEmpty
]

{ #category : 'initialization' }
VGCairoStrokeStyle >> initialize [
	super initialize.
	lineWidth := self class defaultLineWidth.
	lineCap := self class capNames first.
	lineJoin := self class joinNames first.
	miterLimit := self class defaultMiterLimit.
	dashPattern := #().
	dashOffset := 0.0
]

{ #category : 'inspector' }
VGCairoStrokeStyle >> inspectorDashCycle: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Dash cycle'>
	"The cycle the stroker really walks: an odd pattern is written out twice, and whether an
	 entry paints is asked of the predicate the walk itself asks, so the two cannot drift
	 apart."

	^ aBuilder newTable
		  items: ((1 to: self dashLengths size) collect: [ :index |
					   index -> (self dashLengths at: index) ]);
		  addColumn: (SpStringTableColumn
				   title: 'Entry'
				   evaluated: [ :each | each key printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Length'
				   evaluated: [ :each | each value printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Paints'
				   evaluated: [ :each |
					   (self paintsDashEntryAt: each key)
						   ifTrue: [ 'yes' ]
						   ifFalse: [ 'no' ] ]);
		  yourself
]

{ #category : 'inspector' }
VGCairoStrokeStyle >> inspectorDashCycleContext: aContext [
	aContext active: self hasDashPattern
]

{ #category : 'inspector' }
VGCairoStrokeStyle >> inspectorStyle: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Style'>
	"The six parameters a stroke is widened with, each one read from the style itself, and the
	 names the setters accept alongside them so the browser shows what a caller may pass."

	^ aBuilder newTable
		  items: {
				  ('Line width' -> lineWidth).
				  ('Cap' -> lineCap).
				  ('Caps a setter accepts' -> self class capNames).
				  ('Join' -> lineJoin).
				  ('Joins a setter accepts' -> self class joinNames).
				  ('Miter limit' -> miterLimit).
				  ('Dash pattern as given' -> dashPattern).
				  ('Dash offset' -> dashOffset).
				  ('Dash period' -> self dashPeriod) };
		  addColumn: (SpStringTableColumn
				   title: 'Property'
				   evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGCairoStrokeStyle >> inspectorStyleContext: aContext [
	aContext active: lineCap notNil
]

{ #category : 'accessing' }
VGCairoStrokeStyle >> lineCap [
	^ lineCap
]

{ #category : 'accessing' }
VGCairoStrokeStyle >> lineCap: aCapObject [
	"A symbol of mine, Cairo's integer code or Alexandrie's own value; all three name a cap."

	lineCap := self class capFor: aCapObject
]

{ #category : 'accessing' }
VGCairoStrokeStyle >> lineJoin [
	^ lineJoin
]

{ #category : 'accessing' }
VGCairoStrokeStyle >> lineJoin: aJoinObject [
	"A symbol of mine, Cairo's integer code or Alexandrie's own value; all three name a join."

	lineJoin := self class joinFor: aJoinObject
]

{ #category : 'accessing' }
VGCairoStrokeStyle >> lineWidth [
	^ lineWidth
]

{ #category : 'accessing' }
VGCairoStrokeStyle >> lineWidth: aNumber [
	lineWidth := aNumber
]

{ #category : 'accessing' }
VGCairoStrokeStyle >> miterLimit [
	^ miterLimit
]

{ #category : 'accessing' }
VGCairoStrokeStyle >> miterLimit: aNumber [
	miterLimit := aNumber
]

{ #category : 'testing' }
VGCairoStrokeStyle >> paintsDashEntryAt: anIndex [
	"The doubled pattern starts with a painted entry and alternates from there, so an odd index
	 paints and an even one leaves a gap."

	^ anIndex odd
]

{ #category : 'copying' }
VGCairoStrokeStyle >> postCopy [
	"The pattern is an array a later #strokeDashPattern:offset: replaces rather than edits, but a
	 copy of my own costs nothing and keeps a saved state independent of mine whatever a caller
	 does to the array it handed over."

	super postCopy.
	dashPattern := dashPattern copy
]

{ #category : 'printing' }
VGCairoStrokeStyle >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: '(width: ';
		print: lineWidth;
		nextPutAll: ' cap: ';
		nextPutAll: lineCap;
		nextPutAll: ' join: ';
		nextPutAll: lineJoin.
	self hasDashPattern ifTrue: [
		aStream
			nextPutAll: ' dash: ';
			print: dashPattern;
			nextPutAll: ' offset: ';
			print: dashOffset ].
	aStream nextPut: $)
]
