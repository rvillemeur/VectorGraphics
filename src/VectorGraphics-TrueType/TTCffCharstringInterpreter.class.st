"
I draw the glyph that a Type 2 charstring describes.

I read the bytes of one charstring: operands onto my stack, operators drawing with what is on it. Every number a charstring holds is a step from the point I am at, so I keep that point and answer contours whose points are absolute.

I am given the table the charstring came from, because a charstring reaches for what the table holds: its two subroutine indexes, and the two widths its private dictionary states.

I raise a TTCffError for an operator I do not know, naming the glyph and where in its bytes I was: a face stays usable for the glyphs that do read.
"
Class {
	#name : 'TTCffCharstringInterpreter',
	#superclass : 'Object',
	#instVars : [
		'table',
		'stack',
		'outline',
		'width',
		'stemCount',
		'widthRead',
		'stream',
		'depth',
		'glyphIndex'
	],
	#classVars : [
		'OperatorSelectors'
	],
	#category : 'VectorGraphics-TrueType-CFF',
	#package : 'VectorGraphics-TrueType',
	#tag : 'CFF'
}

{ #category : 'architecture' }
TTCffCharstringInterpreter class >> archRelations [
	"What an instance of me holds in a slot no accessor of mine exposes: the table whose
	 subroutines and widths I read a charstring against, and the builder that holds what the
	 charstring draws. Both are given when I am made, so neither is a cache. The stack, the
	 stream and the counters are bytes being read and are no holding of a class."

	^ #(
		#( #table #one #TTCffTableParser nil )
		#( #outline #one #TTCffOutlineBuilder nil ) )
]

{ #category : 'operators' }
TTCffCharstringInterpreter class >> biasForSubroutineCount: anInteger [
	"What a charstring adds to the number it pushes to reach a subroutine of an index that
	 holds this many of them."

	anInteger < 1240 ifTrue: [ ^ 107 ].
	anInteger < 33900 ifTrue: [ ^ 1131 ].
	^ 32768
]

{ #category : 'operators' }
TTCffCharstringInterpreter class >> codeOfOperatorNamed: aSymbol [
	"The code a charstring names this operator by."

	^ self operatorSelectors keyAtValue: aSymbol
]

{ #category : 'operators' }
TTCffCharstringInterpreter class >> maximumCallDepth [
	"How deep a charstring may call subroutines before I call it runaway. The specification
	 allows ten; a font that asks for more is one I refuse rather than follow."

	^ 10
]

{ #category : 'operators' }
TTCffCharstringInterpreter class >> maximumStackSize [
	"How many numbers a charstring may leave on the stack. A font that pushes more is writing
	 something no reader is meant to draw."

	^ 48
]

{ #category : 'operators' }
TTCffCharstringInterpreter class >> nameOfOperator: anInteger [
	^ self operatorSelectors at: anInteger ifAbsent: [ nil ]
]

{ #category : 'instance creation' }
TTCffCharstringInterpreter class >> on: aTableParser [
	^ self new
		  table: aTableParser;
		  yourself
]

{ #category : 'operators' }
TTCffCharstringInterpreter class >> operatorSelectors [
	"The operators of a Type 2 charstring: the code a charstring names each one by, and the
	 selector I run for it, which is the name the specification gives it. An escaped operator
	 is keyed as 1200 plus its second byte, so one integer names any operator."

	^ OperatorSelectors ifNil: [ OperatorSelectors := Dictionary newFromPairs: #(
			   1 #hstem 3 #vstem 4 #vmoveto 5 #rlineto 6 #hlineto 7 #vlineto
			   8 #rrcurveto 10 #callsubr 11 #return 14 #endchar 18 #hstemhm
			   19 #hintmask 20 #cntrmask 21 #rmoveto 22 #hmoveto 23 #vstemhm
			   24 #rcurveline 25 #rlinecurve 26 #vvcurveto 27 #hhcurveto
			   29 #callgsubr 30 #vhcurveto 31 #hvcurveto
			   1234 #hflex 1235 #flex 1236 #hflex1 1237 #flex1 ) ]
]

{ #category : 'operators' }
TTCffCharstringInterpreter class >> standardEncodingIdentifiers [
	"The string identifier that each code of the standard encoding names, 0 where it names
	 nothing. The printable ASCII codes name the first 95 standard strings in their own
	 order; the codes above them name the 54 that follow, with gaps. Only the old accented
	 form of endchar reads this, since nothing else in a charstring names a glyph by a code."

	| identifiers |
	identifiers := Array new: 256 withAll: 0.
	32 to: 126 do: [ :each | identifiers at: each + 1 put: each - 31 ].
	#( 161 96 162 97 163 98 164 99 165 100 166 101 167 102 168 103 169 104
	   170 105 171 106 172 107 173 108 174 109 175 110 177 111 178 112
	   179 113 180 114 182 115 183 116 184 117 185 118 186 119 187 120
	   188 121 189 122 191 123 193 124 194 125 195 126 196 127 197 128
	   198 129 199 130 200 131 202 132 203 133 205 134 206 135 207 136
	   208 137 225 138 227 139 232 140 233 141 234 142 235 143 241 144
	   245 145 248 146 249 147 250 148 251 149 ) pairsDo: [ :code :identifier |
		identifiers at: code + 1 put: identifier ].
	^ identifiers
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> alternatingCurvesStartingHorizontal: aBoolean [
	"Four numbers a curve: a step along one axis, a free step, then a step along the other
	 axis, the two axes changing places at every curve. A fifth number left at the very end
	 is the step the end point of the last curve makes off its axis."

	| numbers horizontal |
	numbers := stack asArray.
	horizontal := aBoolean.
	[ numbers size >= 4 ] whileTrue: [ | last away |
		last := numbers size = 5.
		away := last
			        ifTrue: [ numbers fifth ]
			        ifFalse: [ 0 ].
		horizontal
			ifTrue: [
				outline
					curveBy: numbers first @ 0
					by: numbers second @ numbers third
					by: away @ numbers fourth ]
			ifFalse: [
				outline
					curveBy: 0 @ numbers first
					by: numbers second @ numbers third
					by: numbers fourth @ away ].
		numbers := numbers allButFirst: 4.
		horizontal := horizontal not ].
	self clearStack
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> alternatingLinesStartingHorizontal: aBoolean [
	"One number a line, the axis changing at every line. The two operators that draw this way
	 differ only in the axis the first line is on."

	| horizontal |
	horizontal := aBoolean.
	stack do: [ :each |
		outline lineBy: (horizontal
				 ifTrue: [ each @ 0 ]
				 ifFalse: [ 0 @ each ]).
		horizontal := horizontal not ].
	self clearStack
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> axisLockedCurvesHorizontal: aBoolean [
	"Four numbers a curve: a step along the axis the operator is named for, a free step for the
	 second control point, and a step along that axis again. A number left over in front of
	 them moves the first control point of the first curve off the axis, and only it."

	| numbers across |
	numbers := stack asArray.
	across := 0.
	numbers size \\ 4 = 0 ifFalse: [
		across := numbers first.
		numbers := numbers allButFirst ].
	numbers groupsOf: 4 atATimeDo: [ :each |
		aBoolean
			ifTrue: [
				outline
					curveBy: each first @ across
					by: each second @ each third
					by: each fourth @ 0 ]
			ifFalse: [
				outline
					curveBy: across @ each first
					by: each second @ each third
					by: 0 @ each fourth ].
		across := 0 ].
	self clearStack
]

{ #category : 'drawing' }
TTCffCharstringInterpreter >> callSubroutineIn: anIndex named: aString [
	"The number on the stack, plus the bias of the index, says which subroutine to draw."

	| number |
	number := stack removeLast
	          + (self class biasForSubroutineCount: anIndex size) + 1.
	(number between: 1 and: anIndex size) ifFalse: [
		^ self refuse:
			  'the charstring calls ' , aString , ' subroutine ' , number printString
			  , ', which the font does not hold' ].
	depth := depth + 1.
	depth > self class maximumCallDepth ifTrue: [
		^ self refuse:
			  'the charstring calls subroutines ' , depth printString
			  , ' deep, which is a font calling itself' ].
	self interpret: (anIndex at: number).
	depth := depth - 1
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> callgsubr [
	"A subroutine of the index every font of the file shares."

	self callSubroutineIn: table globalSubrs named: 'global'
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> callsubr [
	"A subroutine of this font's own index."

	self callSubroutineIn: table localSubrs named: 'local'
]

{ #category : 'drawing' }
TTCffCharstringInterpreter >> clearStack [
	"Every operator that draws leaves the stack empty."

	stack := OrderedCollection new
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> cntrmask [
	"The mask of the counters, read exactly as a hint mask is."

	self hintmask
]

{ #category : 'accessing' }
TTCffCharstringInterpreter >> contours [
	"The contours I drew."

	^ outline contours
]

{ #category : 'drawing' }
TTCffCharstringInterpreter >> contoursOfGlyphAt: anIndex [
	"The contours the charstring of one glyph draws, in font units and absolute."

	glyphIndex := anIndex.
	stack := OrderedCollection new.
	outline := TTCffOutlineBuilder new.
	stemCount := 0.
	depth := 0.
	widthRead := false.
	width := table defaultWidthX.
	self interpret: (table charstringAt: anIndex).
	outline closeContour.
	^ outline contours
]

{ #category : 'drawing' }
TTCffCharstringInterpreter >> contoursOfGlyphCoded: aCode [
	"The contours of the glyph that the standard encoding gives this code, drawn apart from
	 the glyph that names it."

	| identifier index |
	identifier := self class standardEncodingIdentifiers at: aCode + 1.
	index := identifier = 0
		         ifTrue: [ nil ]
		         ifFalse: [ table glyphIndexOfIdentifier: identifier ].
	index ifNil: [
		^ self refuse:
			  'the accented glyph names the standard code ' , aCode printString
			  , ', which this font holds no glyph for' ].
	^ (self class on: table) contoursOfGlyphAt: index
]

{ #category : 'drawing' }
TTCffCharstringInterpreter >> countStems [
	"A stem is two numbers, an edge and the width from it. Nothing is drawn: the stems are
	 counted because the bytes of a hint mask are counted from them."

	self takeWidthFromStackWhen: stack size odd.
	stemCount := stemCount + (stack size // 2).
	self clearStack
]

{ #category : 'drawing' }
TTCffCharstringInterpreter >> curvesFrom: aCollection [
	"Curves of six numbers each, read in the order the numbers stand in."

	aCollection groupsOf: 6 atATimeDo: [ :each |
		outline
			curveBy: each first @ each second
			by: each third @ each fourth
			by: (each at: 5) @ (each at: 6) ]
]

{ #category : 'drawing' }
TTCffCharstringInterpreter >> drawAccentedGlyph [
	"The last four numbers are the step the accent takes and the codes of the two glyphs, in
	 the standard encoding. Each of them is drawn by an interpreter of its own, since each
	 starts from its own point and states its own width."

	| arguments step |
	arguments := self lastArguments: 4.
	step := self stepFrom: arguments.
	outline addContours: (self contoursOfGlyphCoded: (arguments at: 3)).
	outline addContours:
		((self contoursOfGlyphCoded: (arguments at: 4)) collect: [ :each |
			 each translatedBy: step ])
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> endchar [
	"The glyph ends here. Four numbers left on the stack say the glyph is an accented letter
	 drawn from two others, which is how a font wrote one before it could name a component."

	self takeWidthFromStackWhen: stack size odd.
	outline closeContour.
	stack size >= 4 ifTrue: [ self drawAccentedGlyph ].
	self clearStack
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> flex [
	"Two curves, twelve steps and a thirteenth number that says how flat the pair is. The
	 flatness is a hint: it says a renderer may draw the pair as one line, and I draw curves."

	self curvesFrom: (stack first: 12).
	self clearStack
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> flex1 [
	"Two curves given five steps and one number: dx1 dy1 dx2 dy2 dx3 dy3 dx4 dy4 dx5 dy5 d6.
	 The pair ends on the axis it travelled least along, so the number given is the step on
	 the other axis and the step back is what the five steps add up to."

	| numbers across up last |
	numbers := stack asArray.
	across := (1 to: 9 by: 2) inject: 0 into: [ :sum :each |
		          sum + (numbers at: each) ].
	up := (2 to: 10 by: 2) inject: 0 into: [ :sum :each |
		      sum + (numbers at: each) ].
	last := across abs > up abs
		        ifTrue: [ (numbers at: 11) @ up negated ]
		        ifFalse: [ across negated @ (numbers at: 11) ].
	outline
		curveBy: numbers first @ numbers second
		by: numbers third @ numbers fourth
		by: (numbers at: 5) @ (numbers at: 6).
	outline
		curveBy: (numbers at: 7) @ (numbers at: 8)
		by: (numbers at: 9) @ (numbers at: 10)
		by: last.
	self clearStack
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> hflex [
	"Two curves whose end points lie on one horizontal: dx1 dx2 dy2 dx3 dx4 dx5 dx6. The
	 second curve rises by what the first fell, so the pair ends at the y it started at."

	| numbers |
	numbers := stack asArray.
	outline
		curveBy: numbers first @ 0
		by: numbers second @ numbers third
		by: numbers fourth @ 0.
	outline
		curveBy: (numbers at: 5) @ 0
		by: (numbers at: 6) @ numbers third negated
		by: (numbers at: 7) @ 0.
	self clearStack
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> hflex1 [
	"Two curves that end at the y they started at: dx1 dy1 dx2 dy2 dx3 dx4 dx5 dy5 dx6. The
	 last step in y is not given, since it is whatever brings the point back."

	| numbers |
	numbers := stack asArray.
	outline
		curveBy: numbers first @ numbers second
		by: numbers third @ numbers fourth
		by: (numbers at: 5) @ 0.
	outline
		curveBy: (numbers at: 6) @ 0
		by: (numbers at: 7) @ (numbers at: 8)
		by: (numbers at: 9)
			@ (numbers second + numbers fourth + (numbers at: 8)) negated.
	self clearStack
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> hhcurveto [
	"Curves that leave and arrive horizontally, four numbers each."

	self axisLockedCurvesHorizontal: true
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> hintmask [
	"The mask that says which hints are on from here. Its bytes follow the operator, one for
	 every eight stems, and are not operands. Numbers standing in front of it declare stems
	 that no operator declared."

	self countStems.
	stream skip: (stemCount max: 1) + 7 // 8
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> hlineto [
	"One number a line, the first of them horizontal."

	self alternatingLinesStartingHorizontal: true
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> hmoveto [
	"One number, a step in x, opens a contour."

	self takeWidthFromStackWhen: stack size > 1.
	outline moveBy: (self lastArguments: 1) first @ 0.
	self clearStack
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> hstem [
	self countStems
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> hstemhm [
	self countStems
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> hvcurveto [
	"Curves that leave horizontally and arrive vertically, turning at every curve."

	self alternatingCurvesStartingHorizontal: true
]

{ #category : 'inspector' }
TTCffCharstringInterpreter >> inspectorContours: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Contours'>
	"One row per contour drawn, with the point it starts at, how many segments it holds and
	 how many of them are curves. The counts are asked of the contours themselves, so a
	 contour that changes shape changes this table with it."

	^ aBuilder newTable
		  addColumn: ((SpStringTableColumn title: 'Contour' evaluated: [ :each |
				    (self contours indexOf: each) printString ]) width: 80);
		  addColumn: ((SpStringTableColumn title: 'Starts at' evaluated: [ :each |
				    each start printString ]) width: 120);
		  addColumn: ((SpStringTableColumn title: 'Segments' evaluated: [ :each |
				    each segments size printString ]) width: 90);
		  addColumn: (SpStringTableColumn title: 'Curves' evaluated: [ :each |
			   (each segments count: [ :segment | segment size = 3 ]) printString ]);
		  items: self contours;
		  yourself
]

{ #category : 'inspector' }
TTCffCharstringInterpreter >> inspectorOperators: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Operators'>
	"Every operator this reader draws with, by the code that names it in a charstring and the
	 method that runs it. The rows are read from the table the reader itself dispatches on,
	 so an operator added or taken away shows here."

	^ aBuilder newTable
		  addColumn: ((SpStringTableColumn title: 'Code' evaluated: [ :each |
				    each printString ]) width: 80);
		  addColumn: ((SpStringTableColumn title: 'Operator' evaluated: [ :each |
				    (self class nameOfOperator: each) printString ]) width: 140);
		  addColumn: (SpStringTableColumn title: 'Drawn' evaluated: [ :each |
			   (self class canUnderstand: (self class nameOfOperator: each))
				   ifTrue: [ 'yes' ]
				   ifFalse: [ 'no' ] ]);
		  items: self class operatorSelectors keys asSortedCollection asArray;
		  yourself
]

{ #category : 'drawing' }
TTCffCharstringInterpreter >> interpret: aByteArray [
	"The bytes of one charstring, or of one subroutine it calls: operands onto my stack, and
	 every operator run as it is met. The stream I was reading is kept, since a subroutine
	 gives the bytes back where it was called from."

	| caller |
	caller := stream.
	stream := ReadStream on: aByteArray.
	[ stream atEnd ] whileFalse: [ | byte |
		byte := stream next.
		byte >= 32 | (byte = 28)
			ifTrue: [
				stack addLast: (self operandFrom: stream firstByte: byte).
				stack size > self class maximumStackSize ifTrue: [
					^ self refuse: 'more numbers are on the stack than a charstring may leave there' ] ]
			ifFalse: [ self runOperator: byte ] ].
	stream := caller
]

{ #category : 'drawing' }
TTCffCharstringInterpreter >> lastArguments: aCount [
	"The arguments of an operator are the last numbers on the stack: a font may have left one
	 in front of them, which is the width of the glyph."

	^ stack last: aCount
]

{ #category : 'drawing' }
TTCffCharstringInterpreter >> operandFrom: aStream firstByte: aByte [
	"A number of a charstring: the integer encodings a dictionary also uses, bar the byte 255,
	 which a charstring spells a 16.16 fixed-point number behind."

	aByte = 28 ifTrue: [
		^ self signed: (aStream next bitShift: 8) + aStream next bits: 16 ].
	aByte = 255 ifTrue: [ | value |
		value := 0.
		4 timesRepeat: [ value := (value bitShift: 8) + aStream next ].
		^ (self signed: value bits: 32) / 65536 ].
	aByte <= 246 ifTrue: [ ^ aByte - 139 ].
	aByte <= 250 ifTrue: [ ^ (aByte - 247 * 256) + aStream next + 108 ].
	^ (aByte - 251 * 256) negated - aStream next - 108
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> rcurveline [
	"Curves of six numbers, then one line of two: the two last numbers are the line."

	self curvesFrom: (stack allButLast: 2).
	outline lineBy: (self stepFrom: (stack last: 2)).
	self clearStack
]

{ #category : 'drawing' }
TTCffCharstringInterpreter >> refuse: aString [
	"Stop this glyph, saying what stopped it and where I stood when it did. A face stays
	 usable for the glyphs that do read."

	^ TTCffError signal: (String streamContents: [ :out |
			   out
				   nextPutAll: 'glyph ';
				   print: glyphIndex;
				   nextPutAll: ', byte ';
				   print: stream position;
				   nextPutAll: ': ';
				   nextPutAll: aString ])
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> return [
	"The subroutine ends here, whatever bytes follow it."

	stream setToEnd
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> rlinecurve [
	"Lines of two numbers, then one curve of six: the six last numbers are the curve."

	(stack allButLast: 6) pairsDo: [ :x :y | outline lineBy: x @ y ].
	self curvesFrom: (stack last: 6).
	self clearStack
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> rlineto [
	"A pair of numbers for each line: a step in x and a step in y."

	stack pairsDo: [ :x :y | outline lineBy: x @ y ].
	self clearStack
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> rmoveto [
	"Two numbers, a step in x and a step in y, open a contour."

	self takeWidthFromStackWhen: stack size > 2.
	outline moveBy: (self stepFrom: (self lastArguments: 2)).
	self clearStack
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> rrcurveto [
	"Six numbers a curve, every point of it free."

	self curvesFrom: stack asArray.
	self clearStack
]

{ #category : 'drawing' }
TTCffCharstringInterpreter >> runOperator: aByte [
	"One operator, named by its byte, or by 1200 plus a second byte when that byte is the
	 escape. An operator I do not draw with stops the glyph rather than drawing it wrongly."

	| code selector |
	code := aByte = 12
		        ifTrue: [ 1200 + stream next ]
		        ifFalse: [ aByte ].
	selector := self class nameOfOperator: code.
	(selector notNil and: [ self class canUnderstand: selector ]) ifFalse: [
		^ self refuse:
			  'operator ' , code printString , ' is one this reader does not draw' ].
	self perform: selector
]

{ #category : 'drawing' }
TTCffCharstringInterpreter >> runOperator: aByte from: aStream [
	"One operator, named by its byte, or by 1200 plus a second byte when that byte is the
	 escape. An operator I do not draw with stops the glyph rather than drawing it wrongly."

	| code selector |
	code := aByte = 12
		        ifTrue: [ 1200 + aStream next ]
		        ifFalse: [ aByte ].
	selector := self class nameOfOperator: code.
	(selector notNil and: [ self class canUnderstand: selector ]) ifFalse: [
		^ TTCffError signal: 'operator ' , code printString , ' is one this reader does not draw' ].
	self perform: selector
]

{ #category : 'drawing' }
TTCffCharstringInterpreter >> signed: anInteger bits: aBitCount [
	"The signed reading of a number that was written in as many bits as that."

	^ anInteger >= (1 bitShift: aBitCount - 1)
		  ifTrue: [ anInteger - (1 bitShift: aBitCount) ]
		  ifFalse: [ anInteger ]
]

{ #category : 'drawing' }
TTCffCharstringInterpreter >> stepFrom: aCollection [
	"The two first numbers of what I am given, as one step."

	^ aCollection first @ aCollection second
]

{ #category : 'initialization' }
TTCffCharstringInterpreter >> table: aTableParser [
	table := aTableParser
]

{ #category : 'drawing' }
TTCffCharstringInterpreter >> takeWidthFromStackWhen: aBoolean [
	"The first operator that clears the stack may carry the width of the glyph in front of its
	 own arguments, counted from nominalWidthX. Only the first one may, so what follows is an
	 argument wherever it stands."

	widthRead ifTrue: [ ^ self ].
	widthRead := true.
	aBoolean ifFalse: [ ^ self ].
	width := table nominalWidthX + stack removeFirst
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> vhcurveto [
	"Curves that leave vertically and arrive horizontally, turning at every curve."

	self alternatingCurvesStartingHorizontal: false
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> vlineto [
	"One number a line, the first of them vertical."

	self alternatingLinesStartingHorizontal: false
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> vmoveto [
	"One number, a step in y, opens a contour."

	self takeWidthFromStackWhen: stack size > 1.
	outline moveBy: 0 @ (self lastArguments: 1) first.
	self clearStack
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> vstem [
	self countStems
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> vstemhm [
	self countStems
]

{ #category : 'operators' }
TTCffCharstringInterpreter >> vvcurveto [
	"Curves that leave and arrive vertically, four numbers each."

	self axisLockedCurvesHorizontal: false
]

{ #category : 'accessing' }
TTCffCharstringInterpreter >> width [
	"How wide the glyph I drew is, in font units."

	^ width
]
