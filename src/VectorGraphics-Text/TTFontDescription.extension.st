Extension { #name : 'TTFontDescription' }

{ #category : '*VectorGraphics-Text' }
TTFontDescription >> formGlyphForUtf8Byte1: byte1 byte2: byte2OrNil byte3: byte3OrNil byte4: byte4OrNil pixelSize: pixelSize [
	"Needed only for BitBltCanvasEngine.

	Bridges VectorGraphics-TrueType, which defines TTFontDescription and FormGlyph, and
	VectorGraphics-Engine, which defines VectorCanvas: this is the only method of the font
	reader that rasterises a glyph through the canvas, so it belongs to neither package and
	lives in VectorGraphics-Text instead."

	| utf8ByteArray toPixelsScale formWidth formHeight leftPixelOffset topPixelOffset horizontalStrokesAtPixelCenter form canvas advanceWidth boundsBottom boundsLeft boundsRight boundsTop i deltaXToCenter layout |
	i := self
		     contourDataPositionForByte1: byte1
		     byte2: byte2OrNil
		     byte3: byte3OrNil
		     byte4: byte4OrNil.
	utf8ByteArray := byte2OrNil
		                 ifNil: [ ByteArray with: byte1 ]
		                 ifNotNil: [
				                 byte3OrNil
					                 ifNil: [ ByteArray with: byte1 with: byte2OrNil ]
					                 ifNotNil: [
							                 byte4OrNil
								                 ifNil: [
								                 ByteArray
									                 with: byte1
									                 with: byte2OrNil
									                 with: byte3OrNil ]
								                 ifNotNil: [
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
	leftPixelOffset := layout first.
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

	deltaXToCenter := advanceWidth - (boundsRight + boundsLeft * 0.51)
	                  * toPixelsScale.
	byte1 = 204 ifTrue: [
			byte2OrNil = 128 ifTrue: [
					deltaXToCenter := advanceWidth
					                  - (boundsRight + boundsLeft * 0.43)
					                  * toPixelsScale ].
			byte2OrNil = 129 ifTrue: [
					deltaXToCenter := advanceWidth
					                  - (boundsRight + boundsLeft * 0.65)
					                  * toPixelsScale ] ].

	"DoubleWidth code points that combine above previous and following characters.
	Codepoints between 16r035C and 16r0363. Example: o͢o. Don't center them."
	(byte1 = 205 and: [ byte2OrNil between: 156 and: 163 ]) ifTrue: [
		deltaXToCenter := 0 ].

	^ (FormGlyph
		   form: form
		   leftOffset: leftPixelOffset
		   topOffset: topPixelOffset
		   advanceWidth: advanceWidth * toPixelsScale) deltaXToCenter:
		  deltaXToCenter
]
