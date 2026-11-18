"
I test the interpreter of a Type 2 charstring: what it draws, where its numbers come from, which width it reads, and what it refuses.

Each of my tests builds a whole CFF table around the charstring it is about, with TTCffBytesFixture, and reads it back through TTCffTableParser. Nothing here is a stand-in for the reader: the bytes a test writes are the bytes a font would hold.
"
Class {
	#name : 'TTCffCharstringInterpreterTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-TrueType-Tests-Tests',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Tests'
}

{ #category : 'running' }
TTCffCharstringInterpreterTest >> contoursOfCharstring: aCollection [
	"The contours a charstring draws, read back through a whole CFF table written around it."

	| parser |
	parser := (TTCffTableParser on: (TTCffBytesFixture new
		            charstrings:
			            { (TTCffBytesFixture charstringBytesWith: aCollection) };
		            yourself) tableCursor) process.
	^ (TTCffCharstringInterpreter on: parser) contoursOfGlyphAt: 1
]

{ #category : 'running' }
TTCffCharstringInterpreterTest >> contoursOfCharstring: aCollection localSubrs: aFirstCollection globalSubrs: aSecondCollection [
	"The contours a charstring draws in a font that holds these subroutines, each of them given
	 the way a charstring is given."

	| parser |
	parser := (TTCffTableParser on: (TTCffBytesFixture new
		            charstrings:
			            { (TTCffBytesFixture charstringBytesWith: aCollection) };
		            localSubrs: (aFirstCollection collect: [ :each |
					             TTCffBytesFixture charstringBytesWith: each ]);
		            globalSubrs: (aSecondCollection collect: [ :each |
					             TTCffBytesFixture charstringBytesWith: each ]);
		            yourself) tableCursor) process.
	^ (TTCffCharstringInterpreter on: parser) contoursOfGlyphAt: 1
]

{ #category : 'running' }
TTCffCharstringInterpreterTest >> contoursOfCharstrings: aCollection at: anIndex [
	"The contours one glyph of a font of several draws, each charstring given the way a
	 charstring is given."

	| parser |
	parser := (TTCffTableParser on: (TTCffBytesFixture new
		            charstrings: (aCollection collect: [ :each |
					            TTCffBytesFixture charstringBytesWith: each ]);
		            yourself) tableCursor) process.
	^ (TTCffCharstringInterpreter on: parser) contoursOfGlyphAt: anIndex
]

{ #category : 'running' }
TTCffCharstringInterpreterTest >> errorOfCharstring: aCollection localSubrs: aSubroutineCollection [
	"The error a charstring raises when it is drawn, or nil when it draws."

	^ [
	  self
		  contoursOfCharstring: aCollection
		  localSubrs: aSubroutineCollection
		  globalSubrs: #(  ).
	  nil ]
		  on: TTCffError
		  do: [ :each | each ]
]

{ #category : 'running' }
TTCffCharstringInterpreterTest >> interpreterOfCharstring: aCollection privateEntries: aCollectionOfAssociations [
	"An interpreter over a font whose private dictionary holds these entries, having drawn the
	 one glyph the font has."

	| parser interpreter |
	parser := (TTCffTableParser on: (TTCffBytesFixture new
		            charstrings:
			            { (TTCffBytesFixture charstringBytesWith: aCollection) };
		            privateEntries: aCollectionOfAssociations;
		            yourself) tableCursor) process.
	interpreter := TTCffCharstringInterpreter on: parser.
	interpreter contoursOfGlyphAt: 1.
	^ interpreter
]

{ #category : 'tests' }
TTCffCharstringInterpreterTest >> testAHintMaskIsFollowedByOneByteForEveryEightStems [
	"The bytes of a hint mask are not operands and are not counted on the stack: the interpreter
	 has to know how many stems were declared to know how many bytes to step over. The numbers
	 standing in front of the first hintmask declare vertical stems, with no operator for them.

	 The mask bytes here are 255, which would be read as the start of a fixed-point number were
	 they taken for operands, so a miscount draws the wrong glyph rather than the same one."

	| oneByteOfMask twoBytesOfMask |
	oneByteOfMask := self contoursOfCharstring: {
			                 20.
			                 20.
			                 #hstem.
			                 100.
			                 50.
			                 #hintmask.
			                 #[ 255 ].
			                 0.
			                 0.
			                 #rmoveto.
			                 10.
			                 #hlineto.
			                 #endchar }.
	twoBytesOfMask := self contoursOfCharstring: ((1 to: 18) asArray , {
			                  #hstemhm.
			                  #hintmask.
			                  #[ 255 255 ].
			                  0.
			                  0.
			                  #rmoveto.
			                  10.
			                  #hlineto.
			                  #endchar }).
	self assert: oneByteOfMask first points equals: {
			(0 @ 0).
			(10 @ 0) }.
	self assert: twoBytesOfMask first points equals: {
			(0 @ 0).
			(10 @ 0) }
]

{ #category : 'tests' }
TTCffCharstringInterpreterTest >> testAMoveAndALineDrawOneClosedContour [
	"rmoveto opens a contour, hlineto draws one horizontal line from where it left the point, and
	 endchar ends the glyph. A contour of a charstring is closed by the fact of being a contour:
	 nothing in the bytes says so and nothing has to."

	| contours contour |
	contours := self contoursOfCharstring: #( 100 0 #rmoveto 50 #hlineto #endchar ).
	self assert: contours size equals: 1.
	contour := contours first.
	self assert: contour start equals: 100 @ 0.
	self assert: contour segments size equals: 1.
	self assert: contour segments first equals: { (150 @ 0) }.
	self assert: contour isClosed
]

{ #category : 'tests' }
TTCffCharstringInterpreterTest >> testASubroutineIsCalledByItsNumberLessTheBiasOfItsIndex [
	"callsubr and callgsubr take the number on the stack, add the bias of the index they read
	 from, and draw what they find there. A subroutine draws on the same stack and from the same
	 point as the charstring that called it, and return gives the bytes back to it."

	| contours |
	contours := self
		            contoursOfCharstring: #( 0 0 #rmoveto -107 #callsubr -107
			                                 #callgsubr #endchar )
		            localSubrs: { #( 10 #hlineto #return ) }
		            globalSubrs: { #( 20 #vlineto #return ) }.
	self assert: contours size equals: 1.
	self assert: contours first points equals: {
			(0 @ 0).
			(10 @ 0).
			(10 @ 20) }
]

{ #category : 'tests' }
TTCffCharstringInterpreterTest >> testASubroutineThatCallsItselfForeverIsStoppedAndSoIsAStackThatGrowsForever [
	"A font may call subroutines ten deep and leave forty-eight numbers on the stack. Beyond
	 either, the charstring is drawing nothing a reader can finish, so it is stopped rather than
	 followed until the image is."

	| recursion overflow |
	recursion := self
		             errorOfCharstring: #( 0 0 #rmoveto -107 #callsubr #endchar )
		             localSubrs: { #( -107 #callsubr #return ) }.
	overflow := self
		            errorOfCharstring:
		            ((1 to: 49) asArray , #( #rmoveto #endchar ))
		            localSubrs: #(  ).
	self assert: recursion notNil description: 'a subroutine called itself for ever'.
	self assert: (recursion messageText includesSubstring: 'deep').
	self assert: overflow notNil description: 'a charstring overfilled the stack'.
	self assert: (overflow messageText includesSubstring: 'glyph 1')
]

{ #category : 'tests' }
TTCffCharstringInterpreterTest >> testAnEndcharOfFourNumbersDrawsAnAccentedGlyphFromTwoOthers [
	"endchar with four numbers left on the stack is the old way of writing an accented letter:
	 the two glyphs are named by their codes in the standard encoding, and the accent is drawn
	 where the two first numbers put it. The base glyph is drawn where it stands."

	| contours |
	contours := self
		            contoursOfCharstrings: {
				            #( 100 50 33 34 #endchar ).
				            #( #endchar ).
				            #( 0 0 #rmoveto 10 #hlineto #endchar ).
				            #( 0 0 #rmoveto 20 #vlineto #endchar ) }
		            at: 1.
	self assert: contours size equals: 2.
	self assert: contours first points equals: {
			(0 @ 0).
			(10 @ 0) }.
	self assert: contours second points equals: {
			(100 @ 50).
			(100 @ 70) }
]

{ #category : 'tests' }
TTCffCharstringInterpreterTest >> testAnOperatorTheReaderDoesNotDrawStopsTheGlyphAndSaysWhereItStood [
	"A byte that is no operator of Type 2 stops this glyph and no other: the message names the
	 glyph and how far into its bytes the reader had read, so the font can be looked at there."

	| error |
	error := self
		         errorOfCharstring: { 0. 0. #rmoveto. #[ 15 ]. #endchar }
		         localSubrs: #(  ).
	self assert: error notNil description: 'a byte that is no operator was drawn with'.
	self assert: (error messageText includesSubstring: 'glyph 1').
	self assert: (error messageText includesSubstring: '15')
]

{ #category : 'tests' }
TTCffCharstringInterpreterTest >> testEveryMoveOpensAContourAndEveryLineOperatorDrawsFromWhereItStands [
	"rmoveto takes both steps, hmoveto and vmoveto one each and leave the other axis alone.
	 rlineto takes a pair for each of its lines, vlineto alternates like hlineto but starts
	 vertical. Every number is a step from the point reached so far."

	| contours |
	contours := self contoursOfCharstring:
		            #( 10 20 #rmoveto 30 40 10 0 #rlineto 100 #hmoveto 50 60
		               #vlineto 5 #vmoveto 7 #hlineto #endchar ).
	self assert: contours size equals: 3.
	self
		assert: (contours first points)
		equals: {
				(10 @ 20).
				(40 @ 60).
				(50 @ 60) }.
	self
		assert: (contours second points)
		equals: {
				(150 @ 60).
				(150 @ 110).
				(210 @ 110) }.
	self
		assert: (contours third points)
		equals: {
				(210 @ 115).
				(217 @ 115) }
]

{ #category : 'tests' }
TTCffCharstringInterpreterTest >> testTheAlternatingCurveOperatorsTurnTheAxisAtEveryCurve [
	"hvcurveto leaves horizontally and arrives vertically, vhcurveto the other way about, and
	 each curve after the first turns again. Four numbers a curve, and a fifth left over at the
	 very end is the free step of the last curve's end point."

	| contours |
	contours := self contoursOfCharstring:
		            #( 0 0 #rmoveto 10 20 30 40 #hvcurveto 100 0 #rmoveto 10 20
		               30 40 50 #vhcurveto 0 100 #rmoveto 10 20 30 40 50 60 70 80
		               #hvcurveto #endchar ).
	self assert: contours size equals: 3.
	self
		assert: contours first segments first
		equals: {
				(10 @ 0).
				(30 @ 30).
				(30 @ 70) }.
	self
		assert: contours second segments first
		equals: {
				(130 @ 80).
				(150 @ 110).
				(190 @ 160) }.
	self
		assert: contours third segments asArray
		equals: {
				{
					(200 @ 260).
					(220 @ 290).
					(220 @ 330) }.
				{
					(220 @ 380).
					(280 @ 450).
					(360 @ 450) } }
]

{ #category : 'tests' }
TTCffCharstringInterpreterTest >> testTheAxisLockedCurveOperatorsStartAndEndOnTheAxisTheyAreNamedFor [
	"hhcurveto draws curves that leave and arrive horizontally, four numbers each, and an odd
	 number left over is a step in y for the first control point of the first curve only.
	 vvcurveto is its twin on the other axis."

	| contours |
	contours := self contoursOfCharstring:
		            #( 0 0 #rmoveto 10 20 30 40 #hhcurveto 100 0 #rmoveto 5 10
		               20 30 40 #hhcurveto 0 100 #rmoveto 7 10 20 30 40
		               #vvcurveto #endchar ).
	self assert: contours size equals: 3.
	self
		assert: contours first segments first
		equals: {
				(10 @ 0).
				(30 @ 30).
				(70 @ 30) }.
	self
		assert: contours second segments first
		equals: {
				(180 @ 35).
				(200 @ 65).
				(240 @ 65) }.
	self
		assert: contours third segments first
		equals: {
				(247 @ 175).
				(267 @ 205).
				(267 @ 245) }
]

{ #category : 'tests' }
TTCffCharstringInterpreterTest >> testTheBiasOfAnIndexGrowsWithTheNumberOfSubroutinesItHolds [
	"The bias is what a charstring adds to the number it pushes to reach a subroutine, and it
	 depends on how many the index holds: 107 under 1240 subroutines, 1131 under 33900, and
	 32768 beyond. A font with fewer than 1240 subroutines numbers them from -107."

	self assert: (TTCffCharstringInterpreter biasForSubroutineCount: 0) equals: 107.
	self assert: (TTCffCharstringInterpreter biasForSubroutineCount: 1239) equals: 107.
	self assert: (TTCffCharstringInterpreter biasForSubroutineCount: 1240) equals: 1131.
	self assert: (TTCffCharstringInterpreter biasForSubroutineCount: 33899) equals: 1131.
	self assert: (TTCffCharstringInterpreter biasForSubroutineCount: 33900) equals: 32768
]

{ #category : 'tests' }
TTCffCharstringInterpreterTest >> testTheFourFlexOperatorsEachDrawTwoCurves [
	"A flex is two curves that a font writes as one operator, because a renderer may draw it as
	 a line. The four spellings differ only in which steps they leave out: hflex holds its two
	 end points on one horizontal, hflex1 brings its last point back to the y it started at, and
	 flex1 works out the step it was not given from the five it was."

	| contours |
	contours := self contoursOfCharstring:
		            #( 0 0 #rmoveto 10 10 10 10 10 0 10 0 10 -10 10 -10 50 #flex
		               100 0 #rmoveto 10 10 20 10 10 10 10 #hflex 0 100
		               #rmoveto 10 5 10 10 10 10 10 -5 10 #hflex1 100 0 #rmoveto
		               10 10 10 10 10 0 10 0 10 -10 10 #flex1 #endchar ).
	self assert: contours size equals: 4.
	self assert: (contours collect: [ :each | each segments size ]) equals: #( 2 2 2 2 ).
	self assert: contours first segments last equals: {
			(40 @ 20).
			(50 @ 10).
			(60 @ 0) }.
	self assert: contours second segments last equals: {
			(200 @ 20).
			(210 @ 0).
			(220 @ 0) }.
	self assert: contours third segments last equals: {
			(260 @ 115).
			(270 @ 110).
			(280 @ 100) }.
	self assert: contours fourth segments last equals: {
			(420 @ 120).
			(430 @ 110).
			(440 @ 100) }
]

{ #category : 'tests' }
TTCffCharstringInterpreterTest >> testTheFreeCurveOperatorsTakeTheirPointsSixNumbersAtATime [
	"rrcurveto takes three steps a curve, the two control points and the end point. rcurveline
	 ends its run of curves with one line, rlinecurve starts its run of lines and ends with one
	 curve: what is left on the stack says which numbers are which."

	| contours |
	contours := self contoursOfCharstring:
		            #( 0 0 #rmoveto 10 0 10 10 0 10 #rrcurveto 100 0 #rmoveto 10 0
		               10 10 0 10 5 5 #rcurveline 0 100 #rmoveto 5 0 10 0 10 10 0
		               10 #rlinecurve #endchar ).
	self assert: contours size equals: 3.
	self
		assert: contours first segments
		equals: (OrderedCollection with: {
					 (10 @ 0).
					 (20 @ 10).
					 (20 @ 20) }).
	self
		assert: contours second segments asArray
		equals: {
				{
					(130 @ 20).
					(140 @ 30).
					(140 @ 40) }.
				{ (145 @ 45) } }.
	self
		assert: contours third segments asArray
		equals: {
				{ (150 @ 145) }.
				{
					(160 @ 145).
					(170 @ 155).
					(170 @ 165) } }
]

{ #category : 'tests' }
TTCffCharstringInterpreterTest >> testTheWidthIsTheNumberStandingInFrontOfTheFirstOperatorThatClearsTheStack [
	"A glyph wider or narrower than the font's default states it once, as one number in front of
	 the first operator that clears the stack, counted from nominalWidthX. A glyph that states
	 nothing is as wide as defaultWidthX, and the number that would have been its width is an
	 argument of that operator like any other."

	| stated silent |
	stated := self
		          interpreterOfCharstring:
		          #( 50 100 0 #rmoveto 10 #hlineto #endchar )
		          privateEntries: {
				          (20 -> #( 480 )).
				          (21 -> #( 123 )) }.
	silent := self
		          interpreterOfCharstring: #( 100 0 #rmoveto 10 #hlineto #endchar )
		          privateEntries: {
				          (20 -> #( 480 )).
				          (21 -> #( 123 )) }.
	self assert: stated width equals: 173.
	self assert: silent width equals: 480.
	self assert: stated contours first start equals: 100 @ 0.
	self assert: silent contours first start equals: 100 @ 0
]
