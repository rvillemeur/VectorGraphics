Class {
	#name : 'TrueTypeExample',
	#superclass : 'Object',
	#category : 'VectorGraphics-Examples',
	#package : 'VectorGraphics',
	#tag : 'Examples'
}

{ #category : 'private' }
TrueTypeExample class >> defaultFontPath [
	"Override this or pass a path directly to loadFontFrom:.
	Set this to the absolute path of any .ttf file on your system."
	^ '/home/renaud/Downloads/Digital7Mono-Yz9J4.ttf'
]

{ #category : 'examples' }
TrueTypeExample class >> exampleCharacterWidths [
	"Inspect the advance widths of printable ASCII characters.
	TrueTypeExample exampleCharacterWidths inspect"
<sampleInstance>
	| font widths |
	font := self loadFontFrom: self defaultFontPath.
	widths := Dictionary new.
	32 to: 126 do: [ :code |
		| char |
		char := Character value: code.
		widths at: char put: (font widthOf: char) ].
	^ widths
]

{ #category : 'examples' }
TrueTypeExample class >> exampleFontMetadata [
	"Load a TTF file and inspect its metadata.
	TrueTypeExample exampleFontMetadata inspect"
<sampleInstance>
	| font info |
	font := self loadFontFrom: self defaultFontPath.
	info := Dictionary new.
	info at: 'familyName'  put: font familyName.
	info at: 'fullName'    put: font fullName.
	info at: 'emphasis'    put: font emphasis.
	info at: 'copyright'   put: font copyright.
	info at: 'unitsPerEm'  put: font unitsPerEm.
	info at: 'ascent'      put: font ascent.
	info at: 'descent'     put: font descent.
	info at: 'lineGap'     put: font lineGap.
	info at: 'bounds'      put: font bounds.
	^ info
]

{ #category : 'examples' }
TrueTypeExample class >> exampleGlyphForm [
	"Render a single character glyph to a Form and inspect it.
	TrueTypeExample exampleGlyphForm inspect"
<sampleInstance>
	| font bytes |
	font := self loadFontFrom: self defaultFontPath.
	bytes := Character utf8BytesOf: $A codePoint.
	^ (font
		formGlyphForUtf8Byte1: (bytes at: 1)
		byte2: nil byte3: nil byte4: nil
		pixelSize: 48) form
]

{ #category : 'examples' }
TrueTypeExample class >> exampleGlyphLarge [
	"Render a glyph at large size (96px).
	TrueTypeExample exampleGlyphLarge inspect"
<sampleInstance>
	| font bytes |
	font := self loadFontFrom: self defaultFontPath.
	bytes := Character utf8BytesOf: $Q codePoint.
	^ (font
		formGlyphForUtf8Byte1: (bytes at: 1)
		byte2: nil byte3: nil byte4: nil
		pixelSize: 96) form
]

{ #category : 'examples' }
TrueTypeExample class >> exampleGlyphSmall [
	"Render a glyph at small size (12px).
	TrueTypeExample exampleGlyphSmall inspect"
<sampleInstance>
	| font bytes |
	font := self loadFontFrom: self defaultFontPath.
	bytes := Character utf8BytesOf: $g codePoint.
	^ (font
		formGlyphForUtf8Byte1: (bytes at: 1)
		byte2: nil byte3: nil byte4: nil
		pixelSize: 12) form
]

{ #category : 'examples' }
TrueTypeExample class >> exampleMultipleGlyphs [
	"Render several glyphs side by side onto a single Form.
	TrueTypeExample exampleMultipleGlyphs inspect"
<sampleInstance>
	| font form x glyphForm bytes |
	font := self loadFontFrom: self defaultFontPath.
	form := Form extent: 400 @ 120 depth: 32.
	form fillColor: Color white.
	x := 10.
	'Hello' do: [ :char |
		bytes := Character utf8BytesOf: char codePoint.
		glyphForm := (font
			formGlyphForUtf8Byte1: (bytes at: 1)
			byte2: nil byte3: nil byte4: nil
			pixelSize: 48) form.
		glyphForm displayOn: form at: x @ 20 rule: Form paint.
		x := x + glyphForm width + 4 ].
	^ form
]

{ #category : 'private' }
TrueTypeExample class >> loadFontFrom: aPathString [
	"Load a TTFontDescription from a .ttf file path."
	| bytes |
	bytes := aPathString asFileReference binaryReadStreamDo: [ :s | s contents ].
	^ TTFontReader readTTFFrom: bytes
]

{ #category : 'see class side' }
TrueTypeExample >> seeClassSide [ 
]
