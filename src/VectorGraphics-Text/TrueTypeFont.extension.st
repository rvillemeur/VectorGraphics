Extension { #name : 'TrueTypeFont' }

{ #category : '*VectorGraphics-Text' }
TrueTypeFont >> glyphAtUtf8Byte1: byte1 byte2: byte2OrNil byte3: byte3OrNil byte4: byte4OrNil [

	"Needed only for BitBltCanvasEngine.

	Bridges VectorGraphics-TrueType, which defines TrueTypeFont, and VectorGraphics-Engine:
	the cache it fills holds Forms rasterised by TTFontDescription >>
	formGlyphForUtf8Byte1:byte2:byte3:byte4:pixelSize:, which draws on a VectorCanvas. It
	follows that method into VectorGraphics-Text so that VectorGraphics-TrueType alone sends
	nothing it cannot answer."

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
