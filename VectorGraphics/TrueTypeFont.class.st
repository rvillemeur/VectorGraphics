"
TrueType fonts are the most widely used format for pixel independent vector Fonts.

In Cuis what is usually called TrueType Font is represented by TTFontDescription.

TrueTypeFonts, being part of the traditional AbstractFont hierarchy, adds a specific pointSize, and is the object used in texts.
"
Class {
	#name : #TrueTypeFont,
	#superclass : #AbstractFont,
	#instVars : [
		'ttFontDescription',
		'pointSize',
		'emphasis',
		'glyphForms',
		'glyphFormsByUtf8',
		'family',
		'baseFont',
		'derivativeFonts'
	],
	#category : #'VectorGraphics-TrueType'
}

{ #category : #initialization }
TrueTypeFont class >> assignmentGlyphSelectorPreferenceChanged [

	| selector |
	selector := Preferences assignmentGlyphSelector.
	TTFontDescription allInstancesDo: [ :ttFontDescription | 
		ttFontDescription perform: selector ].
	self allInstancesDo: [ :each | each resetAssignmentGlyph ]
]

{ #category : #'instance creation' }
TrueTypeFont class >> family: aTrueTypeFontFamily ttFontDescription: aTTFontDescription pointSize: aNumber [

	^ self new
		  family: aTrueTypeFontFamily
		  ttFontDescription: aTTFontDescription
		  pointSize: aNumber
]

{ #category : #initialization }
TrueTypeFont >> addDerivativeFont: aTrueTypeFont [

	derivativeFonts at: aTrueTypeFont emphasis put: aTrueTypeFont
]

{ #category : #emphasis }
TrueTypeFont >> addEmphasis: code [

	"Set the integer code for emphasis. See senders."

	emphasis := code.
	(emphasis anyMask: 4 + 8 + 64) ifTrue: [ "They need to be recreated" 
		glyphForms := Array new: 256 ]
]

{ #category : #accessing }
TrueTypeFont >> ascent [

	^ ttFontDescription ascent * pointSize
	  / ttFontDescription letterMTopSideBearing * 1.0
]

{ #category : #accessing }
TrueTypeFont >> baseFont [

	^ baseFont ifNil: [ self ]
]

{ #category : #initialization }
TrueTypeFont >> baseFont: aStrikeFont [

	baseFont := aStrikeFont.
	baseFont ifNotNil: [ derivativeFonts := nil ]
]

{ #category : #accessing }
TrueTypeFont >> baseKern [

	"self forwarding: #baseKern printOneStack: true."

	self revisar.
	^ 0 "uh?"
]

{ #category : #accessing }
TrueTypeFont >> cachedFormDepth [

	^ 32
]

{ #category : #accessing }
TrueTypeFont >> descent [

	^ ttFontDescription descent negated * pointSize
	  / ttFontDescription letterMTopSideBearing * 1.0
]

{ #category : #emphasis }
TrueTypeFont >> emphasis [

	^ emphasis
]

{ #category : #emphasis }
TrueTypeFont >> emphasized: code [

	"Answer a copy of the receiver with emphasis set to include code."

	| derivative addedEmphasis derivedFrom |
	self isBaseFont ifFalse: [ 
		^ self baseFont emphasized: (code bitOr: emphasis) ].
	code = 0 ifTrue: [ ^ self ].

	derivativeFonts ifNil: [ derivativeFonts := Dictionary new ].
	derivative := derivativeFonts at: code ifPresent: [ :der | ^ der ]. "Already have this style"

	"Dont have it -- derive from another with one with less emphasis"
	addedEmphasis := 1 bitShift: code highBit - 1.
	derivedFrom := self emphasized: code - addedEmphasis.

	"Order is Bold(B), Italic(i), Underlined(U), StruckThrough(X), Superscript(Sup), Subscript(Sub), WithST80Glyphs(ST80)"
	derivative := addedEmphasis caseOf: { 
			              ([ 1 ] -> [ ^ derivedFrom ]). "No synthetic Bold or Italic. Just use whatever we have."
			              ([ 2 ] -> [ ^ derivedFrom ]). "No synthetic Bold or Italic. Just use whatever we have."
			              ([ 4 ] -> [ derivedFrom copy ]).
			              ([ 8 ] -> [ derivedFrom copy ]).
			              ([ 16 ] -> [ derivedFrom syntheticSuperscript ]).
			              ([ 32 ] -> [ derivedFrom syntheticSubscript ]).
			              ([ 64 ] -> [ derivedFrom copy ]) }.

	derivative baseFont: self.
	derivative addEmphasis: code.
	derivativeFonts at: code put: derivative.
	^ derivative
]

{ #category : #initialization }
TrueTypeFont >> family: aTrueTypeFontFamily ttFontDescription: aTTFontDescription pointSize: aNumber [

	ttFontDescription := aTTFontDescription.
	emphasis := aTTFontDescription emphasis.
	pointSize := aNumber.
	glyphForms := Array new: 256.
	glyphFormsByUtf8 := Array new: 256.
	family := aTrueTypeFontFamily.
	baseFont := nil.
	derivativeFonts := emphasis = 0 ifTrue: [ Dictionary new ]
]

{ #category : #accessing }
TrueTypeFont >> familyName [

	^ ttFontDescription familyName
]

{ #category : #accessing }
TrueTypeFont >> fontDescription [

	^ ttFontDescription
]

{ #category : #'glyph access' }
TrueTypeFont >> glyphAt: aCharacter [

	"Needed only for BitBltCanvasEngine"

	| index |
	index := aCharacter numericValue + 1.
	^ (glyphForms at: index) ifNil: [ 
		  | formGlyph |
		  formGlyph := (ttFontDescription
			                formGlyphFor: aCharacter
			                useST80Glyphs: self isST80Glyphs
			                pixelSize: pointSize)
			               ifNil: [ #absentGlyph ]
			               ifNotNil: [ :theGlyph | 
				               (emphasis allMask: 4) ifTrue: [ 
					               self makeUnderlinedGlyph: theGlyph ].
				               (emphasis allMask: 8) ifTrue: [ 
					               self makeStruckThroughGlyph: theGlyph ].
				               theGlyph ].
		  glyphForms at: index put: formGlyph.
		  formGlyph ]
]

{ #category : #'glyph access' }
TrueTypeFont >> glyphAtUtf8Byte1: byte1 byte2: byte2OrNil byte3: byte3OrNil byte4: byte4OrNil [

	"Needed only for BitBltCanvasEngine"

	| lastArray lastIndex |
	lastArray := glyphFormsByUtf8.
	lastIndex := byte1 + 1.
	byte2OrNil notNil ifTrue: [ 
		(lastArray at: lastIndex) ifNil: [ 
			lastArray at: lastIndex put: (Array new: 64) ].
		lastArray := lastArray at: lastIndex.
		lastIndex := (byte2OrNil bitAnd: 63) + 1.
		byte3OrNil notNil ifTrue: [ 
			(lastArray at: lastIndex) ifNil: [ 
				lastArray at: lastIndex put: (Array new: 64) ].
			lastArray := lastArray at: lastIndex.
			lastIndex := (byte3OrNil bitAnd: 63) + 1.
			byte4OrNil notNil ifTrue: [ 
				(lastArray at: lastIndex) ifNil: [ 
					lastArray at: lastIndex put: (Array new: 64) ].
				lastArray := lastArray at: lastIndex.
				lastIndex := (byte4OrNil bitAnd: 63) + 1 ] ] ].
	^ (lastArray at: lastIndex) ifNil: [ 
		  | formGlyph |
		  formGlyph := (ttFontDescription
			                formGlyphForUtf8Byte1: byte1
			                byte2: byte2OrNil
			                byte3: byte3OrNil
			                byte4: byte4OrNil
			                pixelSize: pointSize)
			               ifNil: [ #absentGlyph ]
			               ifNotNil: [ :theGlyph | 
				               (emphasis allMask: 4) ifTrue: [ 
					               self makeUnderlinedGlyph: theGlyph ].
				               (emphasis allMask: 8) ifTrue: [ 
					               self makeStruckThroughGlyph: theGlyph ].
				               theGlyph ].
		  lastArray at: lastIndex put: formGlyph.
		  formGlyph ]
]

{ #category : #testing }
TrueTypeFont >> isBaseFont [

	^ baseFont isNil
]

{ #category : #testing }
TrueTypeFont >> isBold [

	^ self emphasis allMask: 1
]

{ #category : #testing }
TrueTypeFont >> isItalic [

	^ self emphasis allMask: 2
]

{ #category : #testing }
TrueTypeFont >> isST80Glyphs [

	^ emphasis allMask: 64
]

{ #category : #testing }
TrueTypeFont >> isStruckThrough [

	^ emphasis allMask: 8
]

{ #category : #testing }
TrueTypeFont >> isSubscript [

	^ emphasis allMask: 32
]

{ #category : #testing }
TrueTypeFont >> isSuperscript [

	^ emphasis allMask: 16
]

{ #category : #testing }
TrueTypeFont >> isUnderlined [

	^ emphasis allMask: 4
]

{ #category : #accessing }
TrueTypeFont >> lineGap [

	^ ttFontDescription lineGap * pointSize
	  / ttFontDescription letterMTopSideBearing * 1.0
]

{ #category : #'as yet unclassified' }
TrueTypeFont >> lineSpacing [

	"Answer the height of the receiver including any additional line gap."

	^ self ascent + self descent
]

{ #category : #'synthetic derivatives' }
TrueTypeFont >> makeStruckThroughGlyph: aFormGlyph [

	| form |
	form := aFormGlyph form.
	form fillBlack:
		(0 @ (aFormGlyph topOffset - self descent) extent: form width @ 1)
]

{ #category : #'synthetic derivatives' }
TrueTypeFont >> makeUnderlinedGlyph: aFormGlyph [

	| height y oldForm form d |
	d := (self descent / 4) ceiling.
	y := aFormGlyph topOffset + d.
	form := aFormGlyph form.
	height := aFormGlyph topOffset + (2 * d).
	height > form height ifTrue: [ 
		oldForm := form.
		form := Form extent: oldForm width @ height depth: oldForm depth.
		form fillWhite.
		form
			copyBits: oldForm boundingBox
			from: oldForm
			at: '0@0'
			clippingBox: form boundingBox
			rule: Form over.
		aFormGlyph form: form ].
	form fillBlack: (0 @ y extent: form width @ d)
]

{ #category : #'objects from disk' }
TrueTypeFont >> objectForDataStream: refStrm [

	"I am about to be written on an object file.  Write a textual reference instead.
	Warning: This saves a lot of space, but might fail if using other fonts than those in AvailableFonts"

	^ DiskProxy
		  global: #FontFamily
		  selector: #familyName:pointSize:
		  args: (Array with: self familyName with: self pointSize)
]

{ #category : #displaying }
TrueTypeFont >> onBitBltCanvasEngine: engine displayString: aString from: startIndex to: stopIndex at: p color: color [

	"Answer last affected pixel position.
	Answer nil if nothing was done."

	^ aString
		  displayOnBitBltCanvasEngine: engine
		  from: startIndex
		  to: stopIndex
		  at: p
		  trueTypeFont: self
		  color: color
]

{ #category : #accessing }
TrueTypeFont >> pointSize [

	"
p.ej.
scrollbarThickness
"

	"self forwarding: #pointSize printOneStack: true."

	^ pointSize
]

{ #category : #printing }
TrueTypeFont >> printOn: aStream [

	aStream
		nextPutAll: 'TrueTypeFont(''';
		nextPutAll: self familyName;
		nextPutAll: ''' ';
		space;
		print: self pointSize;
		nextPut: $)
]

{ #category : #'as yet unclassified' }
TrueTypeFont >> releaseCachedState [

	glyphForms atAllPut: nil.
	glyphFormsByUtf8 atAllPut: nil.
	derivativeFonts notNil ifTrue: [ 
		derivativeFonts keysAndValuesDo: [ :anEmphasis :derivedFont | 
			derivedFont releaseCachedState ] ]
]

{ #category : #initialization }
TrueTypeFont >> resetAssignmentGlyph [

	"Uses ST80 glyphs:"

	(emphasis anyMask: 64) ifTrue: [ "Re-cache glyphs that could have changed" 
		glyphForms at: $_ numericValue + 1 put: nil ]
]

{ #category : #'synthetic derivatives' }
TrueTypeFont >> syntheticSubscript [

	"Build and answer a derivative that is Subscript."

	| derivative |
	derivative := (family atPointSize: pointSize * 0.68) emphasized:
		              emphasis.
	^ derivative copy

	"
StrikeFont allInstances do: [ :a | a reset ].
('Hi ', (Text string: 'there' attribute: TextEmphasis superscript), ' how ', (Text string: 'are' attribute: TextEmphasis subscript), ' you?') edit.
"
]

{ #category : #'as yet unclassified' }
TrueTypeFont >> syntheticSuperscript [

	"Build and answer a derivative that is Subscript."

	| derivative |
	derivative := (family atPointSize: pointSize * 0.68) emphasized:
		              emphasis.
	^ derivative copy

	"
StrikeFont allInstances do: [ :a | a reset ].
('Hi ', (Text string: 'there' attribute: TextEmphasis superscript), ' how ', (Text string: 'are' attribute: TextEmphasis subscript), ' you?') edit.
"
]

{ #category : #'swapping glyphs' }
TrueTypeFont >> useShortUnderscore [

	
]

{ #category : #accessing }
TrueTypeFont >> widthOf: aCharacter [

	^ (aCharacter
		   widthInTrueTypeFontDescription: ttFontDescription
		   useST80Glyphs: self isST80Glyphs) * pointSize
]
