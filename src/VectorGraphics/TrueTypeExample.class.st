Class {
	#name : 'TrueTypeExample',
	#superclass : 'Object',
	#category : 'VectorGraphics-examples',
	#package : 'VectorGraphics',
	#tag : 'examples'
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

	| font widths |
	font := self loadFontFrom: self defaultFontPath.
	widths := Dictionary new.
	(Character value: 32) to: (Character value: 126) do: [ :char |
		widths at: char put: (font widthOf: char useST80Glyphs: false) ].
	^ widths
]

{ #category : 'examples' }
TrueTypeExample class >> exampleFontMetadata [
	"Load a TTF file and inspect its metadata.
	TrueTypeExample exampleFontMetadata inspect"

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

	| font |
	font := self loadFontFrom: self defaultFontPath.
	^ (font formGlyphFor: $A useST80Glyphs: false pixelSize: 48) form
]

{ #category : 'examples' }
TrueTypeExample class >> exampleGlyphLarge [
	"Render a glyph at large size (96px).
	TrueTypeExample exampleGlyphLarge inspect"

	| font |
	font := self loadFontFrom: self defaultFontPath.
	^ (font formGlyphFor: $Q useST80Glyphs: false pixelSize: 96) form
]

{ #category : 'examples' }
TrueTypeExample class >> exampleGlyphSmall [
	"Render a glyph at small size (12px).
	TrueTypeExample exampleGlyphSmall inspect"

	| font |
	font := self loadFontFrom: self defaultFontPath.
	^ (font formGlyphFor: $g useST80Glyphs: false pixelSize: 12) form
]

{ #category : 'examples' }
TrueTypeExample class >> exampleMultipleGlyphs [
	"Render several glyphs side by side onto a single Form.
	TrueTypeExample exampleMultipleGlyphs inspect"

	| font form x glyphForm |
	font := self loadFontFrom: self defaultFontPath.
	form := Form extent: 400 @ 120 depth: 32.
	form fillColor: Color white.
	x := 10.
	'Hello' do: [ :char |
		glyphForm := (font formGlyphFor: char useST80Glyphs: false pixelSize: 48) form.
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
