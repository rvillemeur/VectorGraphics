Class {
	#name : 'TTGlyphTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-tests',
	#package : 'VectorGraphics',
	#tag : 'tests'
}

{ #category : 'helpers' }
TTGlyphTest >> makeGlyphWithPoints: anInt16PointArray flags: aByteArray [

	| contour glyph |
	contour := TTContourConstruction new.
	contour instVarNamed: 'points' put: anInt16PointArray.
	contour instVarNamed: 'controlPointFlags' put: aByteArray.
	glyph := TTGlyph new.
	glyph contours: (Array with: contour).
	^ glyph
]

{ #category : 'tests' }
TTGlyphTest >> testAdvanceWidth [

	| glyph |
	glyph := TTGlyph new.
	glyph advanceWidth: 600.
	self assert: glyph advanceWidth equals: 600
]

{ #category : 'tests' }
TTGlyphTest >> testBoundsGettersAfterSet [

	| glyph |
	glyph := TTGlyph new.
	glyph boundsLeft: 10 boundsRight: 900 boundsTop: 50 boundsBottom: 750.
	self assert: glyph boundsLeft equals: 10.
	self assert: glyph boundsRight equals: 900.
	self assert: glyph boundsTop equals: 50.
	self assert: glyph boundsBottom equals: 750
]

{ #category : 'tests' }
TTGlyphTest >> testContourCountEmptyGlyph [

	self assert: TTGlyph new contourCount equals: 0
]

{ #category : 'tests' }
TTGlyphTest >> testContourCountSkipsEmptyContours [

	| glyph pts1 pts2 flags |
	"One contour with 1 point (isEmpty → skipped), one with 2 (counted)"
	pts1 := Int16PointArray new: 1.
	pts2 := Int16PointArray new: 2.
	flags := ByteArray newBits: 2.
	glyph := TTGlyph new.
	glyph contours: {
		(TTContourConstruction new instVarNamed: 'points' put: pts1; yourself).
		(TTContourConstruction new instVarNamed: 'points' put: pts2; instVarNamed: 'controlPointFlags' put: flags; yourself) }.
	self assert: glyph contourCount equals: 1
]

{ #category : 'tests' }
TTGlyphTest >> testInitializeState [

	| glyph |
	glyph := TTGlyph new.
	self assert: glyph boundsLeft equals: 0.
	self assert: glyph boundsRight equals: 0.
	self assert: glyph boundsTop equals: 0.
	self assert: glyph boundsBottom equals: 0.
	self assert: glyph advanceWidth equals: 0.
	self assert: glyph leftSideBearing equals: 0.
	self assert: glyph rightSideBearing equals: 0.
	self assert: glyph contours isEmpty
]

{ #category : 'tests' }
TTGlyphTest >> testIsComposite [

	self deny: TTGlyph new isComposite
]

{ #category : 'tests' }
TTGlyphTest >> testMakePointsAbsolute [

	| glyph pts contour flags |
	pts := Int16PointArray new: 3.
	pts at: 1 put: 10 @ 20.
	pts at: 2 put: 5 @ 3.   "delta"
	pts at: 3 put: -2 @ 1.  "delta"
	flags := ByteArray newBits: 3.
	contour := TTContourConstruction new
		instVarNamed: 'points' put: pts;
		instVarNamed: 'controlPointFlags' put: flags;
		yourself.
	glyph := TTGlyph new.
	glyph contours: (Array with: contour).
	glyph makePointsAbsolute.
	self assert: (pts at: 1) equals: 10 @ 20.
	self assert: (pts at: 2) equals: 15 @ 23.
	self assert: (pts at: 3) equals: 13 @ 24
]

{ #category : 'tests' }
TTGlyphTest >> testPrintOn [

	| glyph stream |
	glyph := TTGlyph new.
	stream := WriteStream on: String new.
	glyph printOn: stream.
	self assert: (stream contents includesSubstring: 'TTGlyph')
]

{ #category : 'tests' }
TTGlyphTest >> testReplaceIndexesByComponentGlyphsIsNoop [

	"TTGlyph replaceIndexesByComponentGlyphsIn: is a NOP — must not raise"

	TTGlyph new replaceIndexesByComponentGlyphsIn: #()
]

{ #category : 'tests' }
TTGlyphTest >> testTopSideBearingReturnsYMax [

	"In the Pharo port boundsBottom stores yMax (TrueType Y-up).
	topSideBearing must return boundsBottom."

	| glyph |
	glyph := TTGlyph new.
	glyph boundsLeft: 0 boundsRight: 600 boundsTop: 20 boundsBottom: 700.
	self assert: glyph topSideBearing equals: 700
]

{ #category : 'tests' }
TTGlyphTest >> testUpdateRightSideBearing [

	| glyph |
	glyph := TTGlyph new.
	glyph boundsLeft: 50 boundsRight: 850 boundsTop: 0 boundsBottom: 700.
	glyph advanceWidth: 1000.
	glyph leftSideBearing: 50.
	glyph updateRightSideBearing.
	"rightSideBearing = advanceWidth - leftSideBearing - boundsRight + boundsLeft"
	"= 1000 - 50 - 850 + 50 = 150"
	self assert: glyph rightSideBearing equals: 150
]
