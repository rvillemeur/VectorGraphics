Extension { #name : 'VectorCanvas' }

{ #category : '*VectorGraphics-Text' }
VectorCanvas >> drawString: aString from: firstIndex to: lastIndex at: aPoint font: fontOrNil color: aColor [
	"Render a substring of aString onto the canvas using the VectorEngine text pipeline.
	aPoint is the top-left corner in Morphic coordinates; the baseline offset and y-axis
	flip are applied here before delegating to engine >> displayUtf8:at:trueTypeFont:...

	Bridges VectorGraphics-Engine, which defines VectorCanvas, and VectorGraphics-TrueType,
	which defines FontFamily. It belongs to neither: it is one of the two methods that make the
	canvas name a font class, and moving it into VectorGraphics-Text is what lets either half
	be loaded without the other."

	| font utf8 baseline |
	font := fontOrNil ifNil: [ FontFamily defaultFamilyAndPointSize ].
	font ifNil: [ ^ self ].
	utf8 := ByteArray streamContents: [ :stream |
		firstIndex to: lastIndex do: [ :i |
			Character
				evaluate: [ :b | stream nextPut: b ]
				withUtf8BytesOf: (aString at: i) codePoint ] ].
	baseline := aPoint + (0 @ (font ascent + font lineGap - 1)).
	engine
		displayUtf8: utf8
		at: baseline
		trueTypeFont: font fontDescription
		color: aColor
		scaleX: 1.0 * font pointSize
		scaleY: -1.0 * font pointSize
]

{ #category : '*VectorGraphics-Text' }
VectorCanvas >> drawUtf8: aByteArray at: aPoint font: aTrueTypeFont color: aColor [
	"Render pre-encoded UTF-8 bytes onto the canvas using the VectorEngine text pipeline.
	aPoint is the top-left corner in Morphic coordinates; the baseline offset and y-axis
	flip are applied here before delegating to engine >> displayUtf8:at:trueTypeFont:...

	Bridges VectorGraphics-Engine, which defines VectorCanvas, and VectorGraphics-TrueType,
	which defines FontFamily. It belongs to neither, for the same reason as
	drawString:from:to:at:font:color:, so it lives in VectorGraphics-Text."

	| font baseline |
	font := aTrueTypeFont ifNil: [ FontFamily defaultFamilyAndPointSize ].
	font ifNil: [ ^ self ].
	baseline := aPoint + (0 @ (font ascent + font lineGap - 1)).
	engine
		displayUtf8: aByteArray
		at: baseline
		trueTypeFont: font fontDescription
		color: aColor
		scaleX: 1.0 * font pointSize
		scaleY: -1.0 * font pointSize
]
