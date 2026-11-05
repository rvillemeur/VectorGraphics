"
The examples of the text glue: the six that need both halves of the project at once, a font read by VectorGraphics-TrueType drawn by VectorGraphics-Engine.

Every one of them exercises a method of VectorGraphics-Text, which is why none of them can live with the canvas examples or with the font examples: `drawString` and `drawUtf8` send the canvas methods, and the four glyph examples go through TTFontDescription >> formGlyphForUtf8Byte1:byte2:byte3:byte4:pixelSize:, which rasterises on a canvas of its own.

`defaultFontPath` and `loadFontFrom:` read the .ttf file, and `newForm` and `newCanvasOn:` build the surface drawn on. They are copies of the helpers in TrueTypeExamples and VectorCanvasExamples rather than sends to them, so that this package needs no examples package of another layer.

## The examples

- `drawString` — a Latin string and a row of digits through drawString:from:to:at:font:color:
- `drawUtf8` — pre-encoded UTF-8, with the two-byte é and ï, through drawUtf8:at:font:color:
- `glyphForm`, `glyphSmall`, `glyphLarge` — one glyph rasterised at 48, 12 and 96 pixels
- `multipleGlyphs` — five glyphs placed side by side on one Form, each with its own advance
"
Class {
	#name : 'TextDrawingExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Text-Examples-Examples',
	#package : 'VectorGraphics-Text-Examples',
	#tag : 'Examples'
}

{ #category : 'private' }
TextDrawingExamples class >> defaultFontPath [
	"Override this or pass a path directly to loadFontFrom:.
	Set this to the absolute path of any .ttf file on your system."
	^ '/home/renaud/Downloads/Digital7Mono-Yz9J4.ttf'
]

{ #category : 'examples' }
TextDrawingExamples class >> drawString [
	"Render a Latin string using drawString:from:to:at:font:color:.
	Requires a TTF font at defaultFontPath.
	TextDrawingExamples drawString inspect"
<sampleInstance>
	| form canvas font str |
	font := (TrueTypeFontFamily
		baseTTFontDescription: (self loadFontFrom: self defaultFontPath))
		atPointSize: 28.
	form := self newForm.
	form fillColor: Color white.
	canvas := self newCanvasOn: form.
	str := 'Hello, VectorCanvas!'.
	canvas drawString: str from: 1 to: str size at: 10 @ 10 font: font color: Color black.
	str := '0123456789'.
	canvas drawString: str from: 1 to: str size at: 10 @ 80 font: font color: Color blue.
	^ form
]

{ #category : 'examples' }
TextDrawingExamples class >> drawUtf8 [
	"Render pre-encoded UTF-8 bytes using drawUtf8:at:font:color:.
	Demonstrates multi-byte characters: 'café' encodes é as #[195 169].
	Requires a TTF font at defaultFontPath.
	TextDrawingExamples drawUtf8 inspect"
<sampleInstance>
	| form canvas font cafe greeting |
	font := (TrueTypeFontFamily
		baseTTFontDescription: (self loadFontFrom: self defaultFontPath))
		atPointSize: 28.
	form := self newForm.
	form fillColor: Color white.
	canvas := self newCanvasOn: form.
	"UTF-8 for 'café': c a f é (é = 195, 169)"
	cafe := #[99 97 102 195 169].
	canvas drawUtf8: cafe at: 10 @ 10 font: font color: Color black.
	"UTF-8 for 'naïve': n a ï (195, 175) v e"
	greeting := #[110 97 195 175 118 101].
	canvas drawUtf8: greeting at: 10 @ 80 font: font color: (Color blue darker).
	^ form
]

{ #category : 'examples' }
TextDrawingExamples class >> glyphForm [
	"Render a single character glyph to a Form and inspect it.
	TextDrawingExamples glyphForm inspect"
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
TextDrawingExamples class >> glyphLarge [
	"Render a glyph at large size (96px).
	TextDrawingExamples glyphLarge inspect"
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
TextDrawingExamples class >> glyphSmall [
	"Render a glyph at small size (12px).
	TextDrawingExamples glyphSmall inspect"
<sampleInstance>
	| font bytes |
	font := self loadFontFrom: self defaultFontPath.
	bytes := Character utf8BytesOf: $g codePoint.
	^ (font
		formGlyphForUtf8Byte1: (bytes at: 1)
		byte2: nil byte3: nil byte4: nil
		pixelSize: 12) form
]

{ #category : 'private' }
TextDrawingExamples class >> loadFontFrom: aPathString [
	"Load a TTFontDescription from a .ttf file path."
	| bytes |
	bytes := aPathString asFileReference binaryReadStreamDo: [ :s | s contents ].
	^ TTFontReader readTTFFrom: bytes
]

{ #category : 'examples' }
TextDrawingExamples class >> multipleGlyphs [
	"Render several glyphs side by side onto a single Form.
	TextDrawingExamples multipleGlyphs inspect"
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
TextDrawingExamples class >> newCanvasOn: aForm [
	"Identity transform set by VectorCanvas class >> onForm: — direct pixel coordinates."

	^ VectorCanvas onForm: aForm
]

{ #category : 'private' }
TextDrawingExamples class >> newForm [
	"White 300x200 32-bit form ready for vector rendering."

	| form |
	form := Form extent: 300 @ 200 depth: 32.
	form fillColor: Color white.
	^ form
]
