"
I am one glyph of a font whose outlines are CFF charstrings, drawn the first time somebody asks me for my shape.

A face reads the horizontal metrics of every glyph of a font and draws none of them: a page of text shows twenty glyphs of a font that holds three thousand. So I hold my table and my index until something asks for my contours or my box, and only then does TTCffTableParser interpret my charstring. My advance width and my left side bearing are written into me by TTHmtxTableParser, exactly as they are written into the TTGlyph records a glyf table gives, and they need no charstring.

My index is counted from one, as the charstrings of a CFF table are.
"
Class {
	#name : 'TTCffGlyph',
	#superclass : 'TTGlyph',
	#instVars : [
		'table',
		'index',
		'drawn'
	],
	#category : 'VectorGraphics-TrueType-CFF',
	#package : 'VectorGraphics-TrueType',
	#tag : 'CFF'
}

{ #category : 'instance creation' }
TTCffGlyph class >> onTable: aTableParser count: anInteger [
	"One record a glyph of a font whose outlines are that CFF table, counted from one. Not a
	 charstring is read: each record draws itself the first time somebody asks for its shape."

	^ (1 to: anInteger) collect: [ :each |
		  self onTable: aTableParser index: each ]
]

{ #category : 'instance creation' }
TTCffGlyph class >> onTable: aTableParser index: anInteger [
	"The glyph the charstring at this index of this table draws. Nothing is interpreted here."

	^ self new
		  setTable: aTableParser index: anInteger;
		  yourself
]

{ #category : 'accessing' }
TTCffGlyph >> boundsBottom [
	"The largest y of the points I draw, which TTGlyph calls the bottom."

	self drawIfNeeded.
	^ super boundsBottom
]

{ #category : 'accessing' }
TTCffGlyph >> boundsLeft [
	"The smallest x of the points I draw."

	self drawIfNeeded.
	^ super boundsLeft
]

{ #category : 'accessing' }
TTCffGlyph >> boundsRight [
	"The largest x of the points I draw."

	self drawIfNeeded.
	^ super boundsRight
]

{ #category : 'accessing' }
TTCffGlyph >> boundsTop [
	"The smallest y of the points I draw, which TTGlyph calls the top."

	self drawIfNeeded.
	^ super boundsTop
]

{ #category : 'accessing' }
TTCffGlyph >> contourCount [
	"How many contours I draw, which takes drawing them."

	self drawIfNeeded.
	^ super contourCount
]

{ #category : 'accessing' }
TTCffGlyph >> contours [
	"My contours, drawn the first time they are asked for."

	self drawIfNeeded.
	^ super contours
]

{ #category : 'drawing' }
TTCffGlyph >> drawIfNeeded [
	"Interpret my charstring once, and keep the contours and the box it draws. The right side
	 bearing is the advance less the box, so it is computed here, where the box first exists.
	 A charstring this reader cannot walk raises here, where it is asked for, and not where
	 the font is read."

	drawn ifTrue: [ ^ self ].
	self takeShapeOf: (table glyphAt: index).
	drawn := true.
	self recomputeRightSideBearing
]

{ #category : 'inspector' }
TTCffGlyph >> inspectorRecord: aBuilder [
	<inspectorPresentationOrder: 25 title: 'Record'>
	"What this record knows before a charstring is read: which glyph it is, whether it has
	 been drawn yet, how many bytes the charstring that draws it holds, and the advance width
	 the hmtx table filled in, which costs no charstring. Reading the record must leave it
	 undrawn, so this view sends nothing that draws: the other tabs of a glyph do draw it, by
	 asking for its contours."

	^ aBuilder newTable
		  addColumn: ((SpStringTableColumn title: 'Fact' evaluated: [ :each |
				    each first ]) width: 160; yourself);
		  addColumn: (SpStringTableColumn title: 'Value' evaluated: [ :each |
				   each second ]);
		  items: {
				  { 'glyph index'. index printString }.
				  { 'drawn'. drawn printString }.
				  { 'charstring bytes'.
				  (table charstringAt: index) size printString }.
				  { 'advance width'. advanceWidth printString }.
				  { 'default width x'. table defaultWidthX printString }.
				  { 'nominal width x'. table nominalWidthX printString } };
		  yourself
]

{ #category : 'printing' }
TTCffGlyph >> printOn: aStream [
	"Printing me never draws me: an inspector walks a font of three thousand glyphs, and a
	 glyph that is not drawn yet says so rather than being interpreted to be printed."

	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: index.
	drawn
		ifTrue: [
			aStream
				nextPutAll: ', ';
				print: self contours size;
				nextPutAll: ' contours)' ]
		ifFalse: [ aStream nextPutAll: ', not drawn)' ]
]

{ #category : 'accessing' }
TTCffGlyph >> rightSideBearing [
	"The room my box leaves at the end of my advance. It needs the box, so it waits until I
	 am drawn, and drawing computes it."

	self drawIfNeeded.
	^ super rightSideBearing
]

{ #category : 'initialization' }
TTCffGlyph >> setTable: aTableParser index: anInteger [
	table := aTableParser.
	index := anInteger.
	drawn := false
]

{ #category : 'private' }
TTCffGlyph >> takeShapeOf: aGlyph [
	"Take the contours and the box of the glyph my table drew for me. The advance and the
	 side bearings stay mine: hmtx wrote them before anybody asked for my shape."

	self contours: aGlyph contours.
	self
		boundsLeft: aGlyph boundsLeft
		boundsRight: aGlyph boundsRight
		boundsTop: aGlyph boundsTop
		boundsBottom: aGlyph boundsBottom
]

{ #category : 'private-initialization' }
TTCffGlyph >> updateRightSideBearing [
	"Nothing to do yet. hmtx sends this to every glyph of a font as it reads it, and my right
	 side bearing is the advance less my box, which is not known until I am drawn. Drawing me
	 computes the figure."

	^ self
]
