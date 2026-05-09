"
TrueType fonts are the most widely used format for pixel independent vector Fonts.

TrueTypeFonts, being part of the traditional AbstractFont hierarchy, adds a specific
pointSize, and is the object used in texts.
"
Class {
	#name : 'TrueTypeFont',
	#superclass : 'AbstractFont',
	#instVars : [
		'ttFontDescription',
		'pointSize',
		'emphasis',
		'glyphFormsByUtf8',
		'family',
		'baseFont',
		'derivativeFonts'
	],
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'instance creation' }
TrueTypeFont class >> family: aTrueTypeFontFamily ttFontDescription: aTTFontDescription pointSize: aNumber [

	^ self new
		  family: aTrueTypeFontFamily
		  ttFontDescription: aTTFontDescription
		  pointSize: aNumber
]

{ #category : 'initialization' }
TrueTypeFont >> addDerivativeFont: aTrueTypeFont [

	derivativeFonts at: aTrueTypeFont emphasis put: aTrueTypeFont
]

{ #category : 'emphasis' }
TrueTypeFont >> addEmphasis: code [

	"Set the integer code for emphasis. See senders."

	emphasis := code.
	(emphasis anyMask: 4 + 8) ifTrue: [ "They need to be recreated"
		glyphFormsByUtf8 := Array new: 256 ]
]

{ #category : 'accessing' }
TrueTypeFont >> ascent [

	^ ttFontDescription ascent * pointSize
	  / ttFontDescription letterMTopSideBearing * 1.0
]

{ #category : 'accessing' }
TrueTypeFont >> baseFont [

	^ baseFont ifNil: [ self ]
]

{ #category : 'initialization' }
TrueTypeFont >> baseFont: aFont [

	baseFont := aFont.
	baseFont ifNotNil: [ derivativeFonts := nil ]
]

{ #category : 'accessing' }
TrueTypeFont >> cachedFormDepth [

	^ 32
]

{ #category : 'accessing' }
TrueTypeFont >> descent [

	^ ttFontDescription descent negated * pointSize
	  / ttFontDescription letterMTopSideBearing * 1.0
]

{ #category : 'emphasis' }
TrueTypeFont >> emphasis [

	^ emphasis
]

{ #category : 'emphasis' }
TrueTypeFont >> emphasized: code [

	"Answer a copy of the receiver with emphasis set to include code."

	| derivative addedEmphasis derivedFrom |
	self isBaseFont ifFalse: [
		^ self baseFont emphasized: (code bitOr: emphasis) ].
	code = 0 ifTrue: [ ^ self ].

	derivativeFonts ifNil: [ derivativeFonts := Dictionary new ].
	derivativeFonts at: code ifPresent: [ :der | ^ der ]. "Already have this style"

	"Bold+Italic requested but not available.
	Handle this case before decomposing, because neither can be built synthetic.
	Answer Italic if present. Otherwise answer Bold if present. Or just the base font."
	code = 3 ifTrue: [
		derivativeFonts at: 2 ifPresent: [ :der | ^ der ].
		derivativeFonts at: 1 ifPresent: [ :der | ^ der ].
		^ self baseFont ].
	"Bold or Italic requested but not available. Just use base font."
	code < 3 ifTrue: [ ^ self baseFont ].

	"Dont have it -- derive from another with one with less emphasis"
	addedEmphasis := 1 bitShift: code highBit - 1.
	derivedFrom := self emphasized: code - addedEmphasis.

	derivative := addedEmphasis caseOf: {
		[ 4 ]  -> [ derivedFrom copy ].
		[ 8 ]  -> [ derivedFrom copy ].
		[ 16 ] -> [ derivedFrom syntheticSuperscript ].
		[ 32 ] -> [ derivedFrom syntheticSubscript ]
	}.

	derivative baseFont: self.
	derivative addEmphasis: code.
	derivativeFonts at: code put: derivative.
	^ derivative
]

{ #category : 'accessing' }
TrueTypeFont >> family [

	^ family
]

{ #category : 'initialization' }
TrueTypeFont >> family: aTrueTypeFontFamily ttFontDescription: aTTFontDescription pointSize: aNumber [

	ttFontDescription := aTTFontDescription.
	emphasis := aTTFontDescription emphasis.
	pointSize := aNumber.
	glyphFormsByUtf8 := Array new: 256.
	family := aTrueTypeFontFamily.
	baseFont := nil.
	derivativeFonts := emphasis = 0 ifTrue: [ Dictionary new ]
]

{ #category : 'accessing' }
TrueTypeFont >> familyName [

	^ family familyName
]

{ #category : 'accessing' }
TrueTypeFont >> fontDescription [

	^ ttFontDescription
]

{ #category : 'glyph access' }
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
				               self isUnderlined ifTrue: [
					               self makeUnderlinedGlyph: theGlyph ].
				               self isStruckThrough ifTrue: [
					               self makeStruckThroughGlyph: theGlyph ].
				               theGlyph ].
		  lastArray at: lastIndex put: formGlyph.
		  formGlyph ]
]

{ #category : 'testing' }
TrueTypeFont >> isBaseFont [

	^ baseFont isNil
]

{ #category : 'testing' }
TrueTypeFont >> isBold [

	^ self emphasis allMask: 1
]

{ #category : 'testing' }
TrueTypeFont >> isItalic [

	^ self emphasis allMask: 2
]

{ #category : 'testing' }
TrueTypeFont >> isStruckThrough [

	^ emphasis allMask: 8
]

{ #category : 'testing' }
TrueTypeFont >> isSubscript [

	^ emphasis allMask: 32
]

{ #category : 'testing' }
TrueTypeFont >> isSuperscript [

	^ emphasis allMask: 16
]

{ #category : 'testing' }
TrueTypeFont >> isUnderlined [

	^ emphasis allMask: 4
]

{ #category : 'accessing' }
TrueTypeFont >> lineGap [

	^ ttFontDescription lineGap * pointSize
	  / ttFontDescription letterMTopSideBearing * 1.0
]

{ #category : 'accessing' }
TrueTypeFont >> lineSpacing [

	"Answer the height of the receiver including any additional line gap."

	^ self ascent + self descent
]

{ #category : 'synthetic derivatives' }
TrueTypeFont >> makeStruckThroughGlyph: aFormGlyph [

	| form |
	form := aFormGlyph form.
	form fillBlack:
		(0 @ (aFormGlyph topOffset - self descent) extent: form width @ 1)
]

{ #category : 'synthetic derivatives' }
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
			at: 0 @ 0
			clippingBox: form boundingBox
			rule: Form over.
		aFormGlyph form: form ].
	form fillBlack: (0 @ y extent: form width @ d)
]

{ #category : 'accessing' }
TrueTypeFont >> pointSize [

	^ pointSize
]

{ #category : 'printing' }
TrueTypeFont >> printOn: aStream [

	aStream
		nextPutAll: 'TrueTypeFont(''';
		nextPutAll: self familyName;
		nextPutAll: ''' ';
		space;
		print: self pointSize;
		space;
		nextPutAll: ttFontDescription subfamilyName;
		nextPut: $)
]

{ #category : 'caching' }
TrueTypeFont >> releaseCachedState [

	glyphFormsByUtf8 atAllPut: nil.
	derivativeFonts notNil ifTrue: [
		derivativeFonts keysAndValuesDo: [ :anEmphasis :derivedFont |
			derivedFont releaseCachedState ] ]
]

{ #category : 'synthetic derivatives' }
TrueTypeFont >> syntheticSubscript [

	"Build and answer a derivative that is Subscript."

	| derivative |
	derivative := (family atPointSize: pointSize * 0.68) emphasized: emphasis.
	^ derivative copy
]

{ #category : 'synthetic derivatives' }
TrueTypeFont >> syntheticSuperscript [

	"Build and answer a derivative that is Superscript."

	| derivative |
	derivative := (family atPointSize: pointSize * 0.68) emphasized: emphasis.
	^ derivative copy
]

{ #category : 'accessing' }
TrueTypeFont >> widthOf: aCharacter [

	^ (ttFontDescription widthOf: aCharacter) * pointSize
]

{ #category : 'accessing' }
TrueTypeFont >> widthOfUtf8Byte1: aByte1 b2: aByte2OrNil b3: aByte3OrNil b4: aByte4OrNil [

	^ (ttFontDescription
		   widthOfUtf8Byte1: aByte1
		   b2: aByte2OrNil
		   b3: aByte3OrNil
		   b4: aByte4OrNil) * pointSize
]
