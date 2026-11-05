Extension { #name : 'VectorEngineAbstract' }

{ #category : '*VectorGraphics-Text' }
VectorEngineAbstract >> displayUtf8: aByteArray at: aPoint trueTypeFont: aTTFontDescription color: aColor scaleX: ssx scaleY: ssy [
	"ssx and ssy to honor font pointSize.

	Bridges VectorGraphics-Engine, which defines VectorEngineAbstract, and
	VectorGraphics-TrueType, which defines TTFontDescription: this loop walks the contour data
	a font description holds, and asks that class where a code point it does not map lives, so
	it is the one method of the engine that names the font reader. It belongs to neither package
	and lives in VectorGraphics-Text, which leaves the engine able to load with no font code at
	all."
	| destX destY sx sy contourData contourDataIndexes trueTypeScale cpX cpY epX epY moveToX moveToY advanceWidth boundsLeft boundsRight boundsTop boundsBottom numContours numBeziers baseIndex |
	trueTypeScale := 1.0 / aTTFontDescription letterMTopSideBearing.
	sx := ssx * trueTypeScale.
	sy := ssy * trueTypeScale.
	contourData := aTTFontDescription contourDataForUtf8.
	contourDataIndexes := aTTFontDescription contourDataIndexesByUtf8.
	self fillColor: aColor do: [
		destY := aPoint y.
		destX := aPoint x.
		baseIndex := 0.
		aByteArray do: [ :byte |
			| i |
			"The map holds a slot only for a code point the font maps, so a byte can have no entry.
			 Skipping the continuation bytes of such a code point keeps one unmapped character from
			 drawing one unknown glyph per byte, and a byte with no entry reads the unknown glyph's
			 position rather than position zero, which is outside the data."
			(baseIndex = 0 and: [ TTFontDescription isUtf8ContinuationByte: byte ]) ifFalse: [
				i := contourDataIndexes at: baseIndex + byte + 1.
				i = 0 ifTrue: [ i := TTFontDescription unknownGlyphContourDataPosition ].
				i < 0
					ifTrue: [ baseIndex := i negated ]
					ifFalse: [
						advanceWidth := contourData at: i.
						i := i + 1.
						boundsLeft := contourData at: i.
						i := i + 1.
						boundsRight := contourData at: i.
						i := i + 1.
						boundsTop := contourData at: i.
						i := i + 1.
						boundsBottom := contourData at: i.
						i := i + 1.
						numContours := (contourData at: i) asInteger.
						i := i + 1.
						numContours timesRepeat: [
							numBeziers := (contourData at: i) asInteger.
							i := i + 1.
							moveToX := contourData at: i.
							i := i + 1.
							moveToY := contourData at: i.
							i := i + 1.
							self abs_MoveTo: (moveToX * sx + destX) @ (moveToY * sy + destY).
							numBeziers timesRepeat: [
								epX := contourData at: i.
								i := i + 1.
								epY := contourData at: i.
								i := i + 1.
								cpX := contourData at: i.
								i := i + 1.
								cpY := contourData at: i.
								i := i + 1.
								self
									rel_QuadraticBezierTo: (epX * sx) @ (epY * sy)
									control: (cpX * sx) @ (cpY * sy) ] ].
						destX := destX + (advanceWidth * sx).
						baseIndex := 0 ] ] ] ]
]
