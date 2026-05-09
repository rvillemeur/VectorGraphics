"
Holds a TrueType font in memory.

See
https://www.freetype.org/freetype2/docs/glyphs/glyphs-3.html
"
Class {
	#name : 'TTFontDescription',
	#superclass : 'Object',
	#instVars : [
		'folderName',
		'contourDataForUtf8',
		'contourDataIndexesByUtf8',
		'kernPairs',
		'copyright',
		'familyName',
		'fullName',
		'subfamilyName',
		'uniqueName',
		'versionName',
		'postscriptName',
		'trademark',
		'bounds',
		'unitsPerEm',
		'ascent',
		'descent',
		'lineGap',
		'letterMTopSideBearing'
	],
	#classVars : [
		'Descriptions'
	],
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'class initialization' }
TTFontDescription class >> initialize [

	"	TTFontDescription initialize 	"

	Descriptions := nil
]

{ #category : 'instance creation' }
TTFontDescription class >> read: aDirectoryEntry [

	"	TTFontDescription read: DirectoryEntry smalltalkImageDirectory / 'TrueTypeFonts'	"

	| readFamilyNames |
	Descriptions ifNil: [ Descriptions := Dictionary new ].
	readFamilyNames := Set new.
	aDirectoryEntry
		allFilesDo: [ :file |
			| ttf |
			ttf := TTFontReader readTTFFrom: file binaryContents.
			ttf folderName: file parent name.
			(Descriptions at: ttf familyName ifAbsentPut: [ Dictionary new ])
				at: ttf emphasis
				put: ttf.
			readFamilyNames add: ttf familyName ]
		matches: [ :file | '*.ttf' match: file name ].
	^ readFamilyNames
]

{ #category : 'instance accessing' }
TTFontDescription class >> withFamilyName: aString [

	"	TTFontDescription withFamilyName: 'DejaVu Sans'	"

	^ Descriptions at: aString
]

{ #category : 'private-initialization' }
TTFontDescription >> appendGlyphDataTo: stream glyphsArray: glyphsArray indexes: indexes base: baseIndex [

	glyphsArray withIndexDo: [ :glyphOrArrayOrNil :index |
		glyphOrArrayOrNil notNil ifTrue: [
			glyphOrArrayOrNil isArray
				ifTrue: [
					| nextBaseIndex |
					nextBaseIndex := indexes size - 128.
					indexes addAll: (IntegerArray new: 64).
					indexes at: baseIndex + index put: nextBaseIndex negated.
					self
						appendGlyphDataTo: stream
						glyphsArray: glyphOrArrayOrNil
						indexes: indexes
						base: nextBaseIndex ]
				ifFalse: [
					indexes at: baseIndex + index put: stream position + 1.
					glyphOrArrayOrNil addContourDataTo: stream ] ] ]
]

{ #category : 'properties' }
TTFontDescription >> ascent [

	"Ascent of the font. Relative to unitsPerEm. Usually positive."

	^ ascent
]

{ #category : 'properties' }
TTFontDescription >> bounds [

	^ bounds
]

{ #category : 'private' }
TTFontDescription >> computeGlyphLayoutForLeft: boundsLeft right: boundsRight top: boundsTop bottom: boundsBottom pixelSize: pixelSize [

	"Returns {leftPixelOffset. topPixelOffset. formWidth. formHeight. toPixelsScale}."

	| xtra toPixelsScale leftPixelOffset topPixelOffset formWidth formHeight |
	xtra := 3.
	toPixelsScale := pixelSize * 1.0 / self letterMTopSideBearing.
	leftPixelOffset := (boundsLeft * toPixelsScale - xtra) floor.
	formWidth := boundsRight - boundsLeft * toPixelsScale + (xtra * 2).
	topPixelOffset := (boundsBottom * toPixelsScale + xtra) ceiling.
	formHeight := boundsBottom - boundsTop * toPixelsScale + (xtra * 2).
	^ { leftPixelOffset. topPixelOffset. formWidth. formHeight. toPixelsScale }
]

{ #category : 'accessing' }
TTFontDescription >> contourDataForUtf8 [

	^ contourDataForUtf8
]

{ #category : 'accessing' }
TTFontDescription >> contourDataIndexesByUtf8 [

	^ contourDataIndexesByUtf8
]

{ #category : 'private' }
TTFontDescription >> contourDataPositionForByte1: b1 byte2: b2 byte3: b3 byte4: b4 [

	| i |
	i := contourDataIndexesByUtf8 at: b1 + 1.
	b2 notNil ifTrue: [ i := contourDataIndexesByUtf8 at: i negated + b2 + 1 ].
	b3 notNil ifTrue: [ i := contourDataIndexesByUtf8 at: i negated + b3 + 1 ].
	b4 notNil ifTrue: [ i := contourDataIndexesByUtf8 at: i negated + b4 + 1 ].
	i = 0 ifTrue: [ i := 1 ].
	^ i
]

{ #category : 'information' }
TTFontDescription >> copyright [

	^ copyright
]

{ #category : 'properties' }
TTFontDescription >> descent [

	"Descender of the font. Relative to unitsPerEm. Usually negative."

	^ descent
]

{ #category : 'emphasis' }
TTFontDescription >> emphasis [

	"Use same encoding as StrikeFont. See senders of emphasis:"

	| emphasis |
	familyName = fullName ifTrue: [ ^ 0 ].
	emphasis := 0.
	('*Bold*' match: subfamilyName) ifTrue: [
		emphasis := emphasis bitOr: 1 ].
	('*Oblique*' match: subfamilyName) ifTrue: [
		emphasis := emphasis bitOr: 2 ].
	('*Italic*' match: subfamilyName) ifTrue: [
		emphasis := emphasis bitOr: 2 ].
	^ emphasis
]

{ #category : 'information' }
TTFontDescription >> familyName [

	^ familyName
]

{ #category : 'private-initialization' }
TTFontDescription >> familyName: aString subFamilyName: anotherString [

	familyName := aString.
	subfamilyName := anotherString
]

{ #category : 'accessing' }
TTFontDescription >> first [

	^ self
]

{ #category : 'accessing' }
TTFontDescription >> folderName [

	^ folderName
]

{ #category : 'accessing' }
TTFontDescription >> folderName: aString [

	folderName := aString
]

{ #category : 'conversion' }
TTFontDescription >> formGlyphForUtf8Byte1: byte1 byte2: byte2OrNil byte3: byte3OrNil byte4: byte4OrNil pixelSize: pixelSize [

	"Needed only for BitBltCanvasEngine"

	| utf8ByteArray toPixelsScale formWidth formHeight leftPixelOffset topPixelOffset horizontalStrokesAtPixelCenter form canvas advanceWidth boundsBottom boundsLeft boundsRight boundsTop i deltaXToCenter layout |
	i := self
		     contourDataPositionForByte1: byte1
		     byte2: byte2OrNil
		     byte3: byte3OrNil
		     byte4: byte4OrNil.
	utf8ByteArray := byte2OrNil isNil
		                 ifTrue: [ ByteArray with: byte1 ]
		                 ifFalse: [
			                 byte3OrNil isNil
				                 ifTrue: [ ByteArray with: byte1 with: byte2OrNil ]
				                 ifFalse: [
					                 byte4OrNil isNil
						                 ifTrue: [
							                 ByteArray
								                 with: byte1
								                 with: byte2OrNil
								                 with: byte3OrNil ]
						                 ifFalse: [
							                 ByteArray
								                 with: byte1
								                 with: byte2OrNil
								                 with: byte3OrNil
								                 with: byte4OrNil ] ] ].

	advanceWidth := contourDataForUtf8 at: i.
	i := i + 1.
	boundsLeft := contourDataForUtf8 at: i.
	i := i + 1.
	boundsRight := contourDataForUtf8 at: i.
	i := i + 1.
	boundsTop := contourDataForUtf8 at: i.
	i := i + 1.
	boundsBottom := contourDataForUtf8 at: i.

	horizontalStrokesAtPixelCenter := 0.5.
	layout := self
		           computeGlyphLayoutForLeft: boundsLeft
		           right: boundsRight
		           top: boundsTop
		           bottom: boundsBottom
		           pixelSize: pixelSize.
	leftPixelOffset := layout at: 1.
	topPixelOffset := layout at: 2.
	formWidth := layout at: 3.
	formHeight := layout at: 4.
	toPixelsScale := layout at: 5.

	form := Form extent: formWidth @ formHeight depth: 32.
	form fillColor: Color white.
	canvas := VectorCanvas onForm: form.
	canvas doSubPixelAntiAliasing.
	canvas engine
		displayUtf8: utf8ByteArray
		at: leftPixelOffset negated
			@ (topPixelOffset - horizontalStrokesAtPixelCenter)
		trueTypeFont: self
		color: Color black
		scaleX: 1.0 * pixelSize
		scaleY: -1.0 * pixelSize.

	deltaXToCenter := (advanceWidth - (boundsRight + boundsLeft * 0.51))
	                  * toPixelsScale.
	byte1 = 204 ifTrue: [
		byte2OrNil = 128 ifTrue: [
			deltaXToCenter := (advanceWidth - (boundsRight + boundsLeft * 0.43))
			                  * toPixelsScale ].
		byte2OrNil = 129 ifTrue: [
			deltaXToCenter := (advanceWidth - (boundsRight + boundsLeft * 0.65))
			                  * toPixelsScale ] ].

	"DoubleWidth code points that combine above previous and following characters.
	Codepoints between 16r035C and 16r0363. Example: o͢o. Don't center them."
	(byte1 = 205 and: [ byte2OrNil between: 156 and: 163 ]) ifTrue: [
		deltaXToCenter := 0 ].

	^ (FormGlyph
		   form: form
		   leftOffset: leftPixelOffset
		   topOffset: topPixelOffset
		   advanceWidth: advanceWidth * toPixelsScale)
		  deltaXToCenter: deltaXToCenter
]

{ #category : 'information' }
TTFontDescription >> fullName [

	^ fullName
]

{ #category : 'private-initialization' }
TTFontDescription >> glyphsByUtf8Bytes: glyphsByUTF8 unknownGlyph: theUnknownGlyph [

	| mGlyph |
	mGlyph := glyphsByUTF8 at: $M codePoint + 1.
	letterMTopSideBearing := (mGlyph ifNil: [ theUnknownGlyph ]) topSideBearing.

	contourDataIndexesByUtf8 := (IntegerArray new: 256) as: OrderedCollection.
	contourDataForUtf8 := Float32Array streamContents: [ :stream |
		theUnknownGlyph addContourDataTo: stream tx: nil. "First data is for unknownGlyph"
		self
			appendGlyphDataTo: stream
			glyphsArray: glyphsByUTF8
			indexes: contourDataIndexesByUtf8
			base: 0 ].
	contourDataIndexesByUtf8 := contourDataIndexesByUtf8 as: IntegerArray
]

{ #category : 'testing' }
TTFontDescription >> includesAscii [

	"Answer true if we include the basic ASCII characters.
	If not, we are not suitable for displaying Smalltalk code."

	^ (33 to: 127) allSatisfy: [ :codePoint |
		  (contourDataIndexesByUtf8 at: codePoint + 1) > 1 ]
]

{ #category : 'testing' }
TTFontDescription >> isBaseFont [

	^ self emphasis = 0
]

{ #category : 'properties' }
TTFontDescription >> letterMTopSideBearing [

	"This number is what needs to be scaled by i.e. 12 to render a 12 pixel font"

	^ letterMTopSideBearing
]

{ #category : 'properties' }
TTFontDescription >> lineGap [

	"Leading of the font. Relative to unitsPerEm."

	^ lineGap
]

{ #category : 'properties' }
TTFontDescription >> lineSpacing [

	^ ascent - descent + lineGap
]

{ #category : 'accessing' }
TTFontDescription >> name [

	^ self familyName copyWithout: Character space
]

{ #category : 'information' }
TTFontDescription >> postscriptName [

	^ postscriptName
]

{ #category : 'printing' }
TTFontDescription >> printOn: aStream [

	super printOn: aStream.
	aStream nextPut: $(.
	fullName printOn: aStream.
	aStream nextPut: $)
]

{ #category : 'private-initialization' }
TTFontDescription >> setAscent: asc descent: desc lineGap: lgap [

	ascent := asc.
	descent := desc.
	lineGap := lgap
]

{ #category : 'private-initialization' }
TTFontDescription >> setBounds: aRect unitsPerEm: aNumber [

	bounds := aRect.
	unitsPerEm := aNumber
]

{ #category : 'private-initialization' }
TTFontDescription >> setKernPairs: array [

	kernPairs := array
]

{ #category : 'private-initialization' }
TTFontDescription >> setStrings: anArray [

	copyright := anArray at: 1.
	familyName := anArray at: 2.
	subfamilyName := anArray at: 3.
	uniqueName := anArray at: 4.
	fullName := anArray at: 5.
	versionName := anArray at: 6.
	postscriptName := anArray at: 7.
	trademark := anArray at: 8
]

{ #category : 'information' }
TTFontDescription >> subfamilyName [

	^ subfamilyName
]

{ #category : 'information' }
TTFontDescription >> trademark [

	^ trademark
]

{ #category : 'information' }
TTFontDescription >> uniqueName [

	^ uniqueName
]

{ #category : 'properties' }
TTFontDescription >> unitsPerEm [

	^ unitsPerEm
]

{ #category : 'information' }
TTFontDescription >> versionName [

	^ versionName
]

{ #category : 'glyph properties' }
TTFontDescription >> widthOf: aCharacter [

	| bytes |
	bytes := Character utf8BytesOf: aCharacter codePoint.
	^ self
		  widthOfUtf8Byte1: (bytes at: 1)
		  b2: (bytes size >= 2 ifTrue: [ bytes at: 2 ])
		  b3: (bytes size >= 3 ifTrue: [ bytes at: 3 ])
		  b4: (bytes size >= 4 ifTrue: [ bytes at: 4 ])
]

{ #category : 'glyph properties' }
TTFontDescription >> widthOfCodePoint: aUnicodeCodePoint [

	| bytes |
	bytes := Character utf8BytesOf: aUnicodeCodePoint.
	^ (contourDataForUtf8 at: (self
		   contourDataPositionForByte1: (bytes at: 1)
		   byte2: (bytes size >= 2 ifTrue: [ bytes at: 2 ])
		   byte3: (bytes size >= 3 ifTrue: [ bytes at: 3 ])
		   byte4: (bytes size >= 4 ifTrue: [ bytes at: 4 ]))) / letterMTopSideBearing
]

{ #category : 'glyph properties' }
TTFontDescription >> widthOfUtf8Byte1: aByte1 b2: aByte2OrNil b3: aByte3OrNil b4: aByte4OrNil [

	^ (contourDataForUtf8 at: (self
		   contourDataPositionForByte1: aByte1
		   byte2: aByte2OrNil
		   byte3: aByte3OrNil
		   byte4: aByte4OrNil)) / letterMTopSideBearing
]
