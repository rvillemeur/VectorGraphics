"
Holds a TrueType font in memory.

See
https://www.freetype.org/freetype2/docs/glyphs/glyphs-3.html
"
Class {
	#name : #TTFontDescription,
	#superclass : #Object,
	#instVars : [
		'folderName',
		'contourDataForIso8859s15',
		'contourDataIndexesByIso8859s15',
		'contourDataIndexesForSmalltalkGlyphs',
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
	#category : #'VectorGraphics-TrueType'
}

{ #category : #'class initialization' }
TTFontDescription class >> initialize [

	"	TTFontDescription  initialize 	"

	Descriptions := nil
]

{ #category : #'instance creation' }
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

{ #category : #'instance accessing' }
TTFontDescription class >> withFamilyName: aString [

	"	TTFontDescription withFamilyName: 'DejaVu Sans'	"

	^ Descriptions at: aString
]

{ #category : #'private-initialization' }
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

{ #category : #properties }
TTFontDescription >> ascent [

	"Ascent of the font. Relative to unitsPerEm. Usually positive."

	^ ascent
]

{ #category : #properties }
TTFontDescription >> bounds [

	^ bounds
]

{ #category : #accessing }
TTFontDescription >> contourDataForIso8859s15 [

	^ contourDataForIso8859s15
]

{ #category : #accessing }
TTFontDescription >> contourDataForUtf8 [

	^ contourDataForUtf8
]

{ #category : #accessing }
TTFontDescription >> contourDataIndexesByIso8859s15 [

	^ contourDataIndexesByIso8859s15
]

{ #category : #accessing }
TTFontDescription >> contourDataIndexesByIso8859s15ST80Glyphs: aBoolean [

	^ aBoolean
		  ifTrue: [ contourDataIndexesForSmalltalkGlyphs ]
		  ifFalse: [ contourDataIndexesByIso8859s15 ]
]

{ #category : #accessing }
TTFontDescription >> contourDataIndexesByUtf8 [

	^ contourDataIndexesByUtf8
]

{ #category : #information }
TTFontDescription >> copyright [

	^ copyright
]

{ #category : #properties }
TTFontDescription >> descent [

	"Descender of the font. Relative to unitsPerEm. Usually negative."

	^ descent
]

{ #category : #emphasis }
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

{ #category : #information }
TTFontDescription >> familyName [

	^ familyName
]

{ #category : #accessing }
TTFontDescription >> first [

	^ self
]

{ #category : #accessing }
TTFontDescription >> folderName [

	^ folderName
]

{ #category : #accessing }
TTFontDescription >> folderName: aString [

	folderName := aString
]

{ #category : #conversion }
TTFontDescription >> formGlyphFor: aCharacter useST80Glyphs: aBoolean pixelSize: pixelSize [

	"Needed only for BitBltCanvasEngine"

	| toPixelsScale formWidth formHeight leftPixelOffset topPixelOffset xtraSpaceForAntiAliasingAndRounding horizontalStrokesAtPixelCenter form canvas advanceWidth boundsBottom boundsLeft boundsRight boundsTop i |
	i := (self contourDataIndexesByIso8859s15ST80Glyphs: aBoolean) at:
		     aCharacter numericValue + 1.
	advanceWidth := contourDataForIso8859s15 at: i.
	i := i + 1.
	boundsLeft := contourDataForIso8859s15 at: i.
	i := i + 1.
	boundsRight := contourDataForIso8859s15 at: i.
	i := i + 1.
	boundsTop := contourDataForIso8859s15 at: i.
	i := i + 1.
	boundsBottom := contourDataForIso8859s15 at: i.
	i := i + 1.

	horizontalStrokesAtPixelCenter := 0.5.
	xtraSpaceForAntiAliasingAndRounding := 3.
	toPixelsScale := pixelSize * 1.0 / self letterMTopSideBearing.

	"If positive, pixels we save at the left. if negative, xtra pix needed"
	leftPixelOffset := (boundsLeft * toPixelsScale
	                    - xtraSpaceForAntiAliasingAndRounding) floor.
	formWidth := boundsRight - boundsLeft * toPixelsScale
	             + (xtraSpaceForAntiAliasingAndRounding * 2).

	"Usually positive. Needed pixels above the baseline"
	topPixelOffset := (boundsBottom * toPixelsScale
	                   + xtraSpaceForAntiAliasingAndRounding) ceiling.
	formHeight := boundsBottom - boundsTop * toPixelsScale
	              + (xtraSpaceForAntiAliasingAndRounding * 2).

	form := Form extent: formWidth @ formHeight depth: 32.
	form fillColor: Color white.
	canvas := VectorCanvas onForm: form.
	canvas doSubPixelAntiAliasing.
	canvas engine
		displayString: aCharacter asString
		from: 1
		to: 1
		at: leftPixelOffset negated
			@ (topPixelOffset - horizontalStrokesAtPixelCenter)
		trueTypeFont: self
		useST80Glyphs: aBoolean
		color: Color black
		scaleX: 1.0 * pixelSize
		scaleY: -1.0 * pixelSize.
	^ FormGlyph
		  form: form
		  leftOffset: leftPixelOffset
		  topOffset: topPixelOffset
		  advanceWidth: advanceWidth * toPixelsScale
]

{ #category : #conversion }
TTFontDescription >> formGlyphForUtf8Byte1: byte1 byte2: byte2OrNil byte3: byte3OrNil byte4: byte4OrNil pixelSize: pixelSize [

	"Needed only for BitBltCanvasEngine"

	| utf8ByteArray toPixelsScale formWidth formHeight leftPixelOffset topPixelOffset xtraSpaceForAntiAliasingAndRounding horizontalStrokesAtPixelCenter form canvas advanceWidth boundsBottom boundsLeft boundsRight boundsTop i |
	i := contourDataIndexesByUtf8 at: byte1 + 1.
	utf8ByteArray := ByteArray with: byte1.
	byte2OrNil notNil ifTrue: [ 
		i := contourDataIndexesByUtf8 at: i negated + byte2OrNil + 1.
		utf8ByteArray := ByteArray with: byte1 with: byte2OrNil.
		byte3OrNil notNil ifTrue: [ 
			i := contourDataIndexesByUtf8 at: i negated + byte3OrNil + 1.
			utf8ByteArray := ByteArray
				                 with: byte1
				                 with: byte2OrNil
				                 with: byte3OrNil.
			byte4OrNil notNil ifTrue: [ 
				i := contourDataIndexesByUtf8 at: i negated + byte4OrNil + 1.
				utf8ByteArray := ByteArray
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
	i := i + 1.

	horizontalStrokesAtPixelCenter := 0.5.
	xtraSpaceForAntiAliasingAndRounding := 3.
	toPixelsScale := pixelSize * 1.0 / self letterMTopSideBearing.

	"If positive, pixels we save at the left. if negative, xtra pix needed"
	leftPixelOffset := (boundsLeft * toPixelsScale
	                    - xtraSpaceForAntiAliasingAndRounding) floor.
	formWidth := boundsRight - boundsLeft * toPixelsScale
	             + (xtraSpaceForAntiAliasingAndRounding * 2).

	"Usually positive. Needed pixels above the baseline"
	topPixelOffset := (boundsBottom * toPixelsScale
	                   + xtraSpaceForAntiAliasingAndRounding) ceiling.
	formHeight := boundsBottom - boundsTop * toPixelsScale
	              + (xtraSpaceForAntiAliasingAndRounding * 2).

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
	^ FormGlyph
		  form: form
		  leftOffset: leftPixelOffset
		  topOffset: topPixelOffset
		  advanceWidth: advanceWidth * toPixelsScale
]

{ #category : #information }
TTFontDescription >> fullName [

	^ fullName
]

{ #category : #'private-initialization' }
TTFontDescription >> glyphsByIso8859s15: array8 glyphsByUtf8Bytes: arrayUtf8 unknownGlyph: theUnknownGlyph [

	| mGlyph |
	mGlyph := array8 at: $M numericValue + 1.
	letterMTopSideBearing := mGlyph topSideBearing.

	contourDataIndexesByIso8859s15 := IntegerArray new: array8 size.
	contourDataForIso8859s15 := Float32Array streamContents: [ :stream | 
		                            theUnknownGlyph addContourDataTo: stream. "First data is for unknownGlyph"
		                            array8 withIndexDo: [ :ttGlyphOrNil :index | 
			                            ttGlyphOrNil notNil
				                            ifTrue: [ 
					                            contourDataIndexesByIso8859s15
						                            at: index
						                            put: stream position + 1.
					                            ttGlyphOrNil addContourDataTo: stream ]
				                            ifFalse: [ 
				                            contourDataIndexesByIso8859s15
					                            at: index
					                            put: 1 ] ] ].
	self perform: Preferences assignmentGlyphSelector.

	"This takes a significant amout of space, makes loading slower, and we're still not able to take full advantage of it."
	Preferences loadOnlyLatinGlyphData ifFalse: [ 
		contourDataIndexesByUtf8 := (IntegerArray new: 256) as:
			                            OrderedCollection.
		contourDataForUtf8 := Float32Array streamContents: [ :stream | 
			                      theUnknownGlyph addContourDataTo: stream. "First data is for unknownGlyph"
			                      self
				                      appendGlyphDataTo: stream
				                      glyphsArray: arrayUtf8
				                      indexes: contourDataIndexesByUtf8
				                      base: 0 ].
		contourDataIndexesByUtf8 := contourDataIndexesByUtf8 as:
			                            IntegerArray ]
]

{ #category : #testing }
TTFontDescription >> isBaseFont [

	^ self emphasis = 0
]

{ #category : #properties }
TTFontDescription >> letterMTopSideBearing [

	"This number is what needs to be scaled by i.e. 12 to render a 12 pixel font"

	^ letterMTopSideBearing
]

{ #category : #properties }
TTFontDescription >> lineGap [

	"Leading of the font. Relative to unitsPerEm."

	^ lineGap
]

{ #category : #properties }
TTFontDescription >> lineSpacing [

	^ ascent - descent + lineGap
]

{ #category : #accessing }
TTFontDescription >> name [

	^ self familyName copyWithout: Character space
]

{ #category : #information }
TTFontDescription >> postscriptName [

	^ postscriptName
]

{ #category : #printing }
TTFontDescription >> printOn: aStream [

	super printOn: aStream.
	aStream nextPut: $(.
	fullName printOn: aStream.
	aStream nextPut: $)
]

{ #category : #'private-initialization' }
TTFontDescription >> setAscent: asc descent: desc lineGap: lgap [

	ascent := asc.
	descent := desc.
	lineGap := lgap
]

{ #category : #'private-initialization' }
TTFontDescription >> setBounds: aRect unitsPerEm: aNumber [

	bounds := aRect.
	unitsPerEm := aNumber
]

{ #category : #'private-initialization' }
TTFontDescription >> setKernPairs: array [

	kernPairs := array
]

{ #category : #'private-initialization' }
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

{ #category : #information }
TTFontDescription >> subfamilyName [

	^ subfamilyName
]

{ #category : #information }
TTFontDescription >> trademark [

	^ trademark
]

{ #category : #information }
TTFontDescription >> uniqueName [

	^ uniqueName
]

{ #category : #properties }
TTFontDescription >> unitsPerEm [

	^ unitsPerEm
]

{ #category : #'private-initialization' }
TTFontDescription >> useAlwaysLeftArrow [

	"Not only when Smalltalk glyphs requested."

	| arrowIndex |
	contourDataIndexesForSmalltalkGlyphs := contourDataIndexesByIso8859s15
		                                        copy.
	arrowIndex := contourDataIndexesByIso8859s15 at:
		              Character arrowLeft numericValue + 1.
	arrowIndex = 1 ifFalse: [ "If font doesn't include the arrow, don't do substitution."
		contourDataIndexesByIso8859s15
			at: $_ numericValue + 1
			put: arrowIndex.
		contourDataIndexesForSmalltalkGlyphs
			at: $_ numericValue + 1
			put: arrowIndex ].
	arrowIndex := contourDataIndexesByIso8859s15 at:
		              Character arrowUp numericValue + 1.
	arrowIndex = 1 ifFalse: [ "If font doesn't include the arrow, don't do substitution."
		contourDataIndexesForSmalltalkGlyphs
			at: $^ numericValue + 1
			put: arrowIndex ]
]

{ #category : #'private-initialization' }
TTFontDescription >> useLeftArrow [

	"When Smalltalk glyphs requested"

	| arrowIndex |
	contourDataIndexesForSmalltalkGlyphs := contourDataIndexesByIso8859s15
		                                        copy.
	arrowIndex := contourDataIndexesByIso8859s15 at:
		              Character arrowLeft numericValue + 1.
	arrowIndex = 1 ifFalse: [ "If font doesn't include the arrow, don't do substitution."
		contourDataIndexesForSmalltalkGlyphs
			at: $_ numericValue + 1
			put: arrowIndex ].
	arrowIndex := contourDataIndexesByIso8859s15 at:
		              Character arrowUp numericValue + 1.
	arrowIndex = 1 ifFalse: [ "If font doesn't include the arrow, don't do substitution."
		contourDataIndexesForSmalltalkGlyphs
			at: $^ numericValue + 1
			put: arrowIndex ]
]

{ #category : #'private-initialization' }
TTFontDescription >> useRightArrow [

	"When Smalltalk glyphs requested"

	| arrowIndex |
	contourDataIndexesForSmalltalkGlyphs := contourDataIndexesByIso8859s15
		                                        copy.
	arrowIndex := contourDataIndexesByIso8859s15 at:
		              Character arrowRight numericValue + 1.
	arrowIndex = 1 ifFalse: [ "If font doesn't include the arrow, don't do substitution."
		contourDataIndexesForSmalltalkGlyphs
			at: $_ numericValue + 1
			put: arrowIndex ].
	arrowIndex := contourDataIndexesByIso8859s15 at:
		              Character arrowUp numericValue + 1.
	arrowIndex = 1 ifFalse: [ "If font doesn't include the arrow, don't do substitution."
		contourDataIndexesForSmalltalkGlyphs
			at: $^ numericValue + 1
			put: arrowIndex ]
]

{ #category : #information }
TTFontDescription >> versionName [

	^ versionName
]

{ #category : #'glyph properties' }
TTFontDescription >> widthOf: aCharacter useST80Glyphs: aBoolean [

	| i advanceWidth |
	i := (self contourDataIndexesByIso8859s15ST80Glyphs: aBoolean) at:
		     aCharacter numericValue + 1.
	advanceWidth := contourDataForIso8859s15 at: i.
	^ advanceWidth / letterMTopSideBearing
]

{ #category : #'glyph properties' }
TTFontDescription >> widthOfCodePoint: aUnicodeCodePoint [

	| i advanceWidth |
	i := contourDataIndexesByUtf8 at: aUnicodeCodePoint + 1.
	Character
		evaluateOnce: [ :byte1 :byte2OrNil :byte3OrNil :byte4OrNil | 
			i := contourDataIndexesByUtf8 at: byte1 + 1.
			byte2OrNil notNil ifTrue: [ 
				i := contourDataIndexesByUtf8 at: i negated + byte2OrNil + 1.
				byte3OrNil notNil ifTrue: [ 
					i := contourDataIndexesByUtf8 at: i negated + byte3OrNil + 1.
					byte4OrNil notNil ifTrue: [ 
						i := contourDataIndexesByUtf8 at: i negated + byte4OrNil + 1 ] ] ] ]
		withUtf8BytesOfUnicodeCodePoint: aUnicodeCodePoint.
	advanceWidth := contourDataForUtf8 at: i.
	^ advanceWidth / letterMTopSideBearing
]
