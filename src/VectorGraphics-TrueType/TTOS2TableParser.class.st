"
I read the three fields of an OS/2 table that classify a face: usWeightClass on the 100 to 1000
scale, usWidthClass on the 1 to 9 scale that starts at ultra-condensed, and the fsSelection bits,
of which bit 0 says italic and bit 9 says oblique. My process answers them in a Dictionary under
#usWeightClass, #usWidthClass and #fsSelection.

I am the tenth table parser of this package, and the one fact FreeType was not giving us anyway:
upstream, AeFaceEntry guesses weight, width and slant by tokenising the style name string. The
font states them here, so reading them is better information and not a port.

I read nothing else. The subscript, superscript and strikeout metrics, the family class, PANOSE,
the Unicode ranges and the vendor id sit between usWidthClass and fsSelection, and I skip them.
"
Class {
	#name : 'TTOS2TableParser',
	#superclass : 'TTFontParser',
	#category : 'VectorGraphics-TrueType-Reading',
	#package : 'VectorGraphics-TrueType',
	#tag : 'Reading'
}

{ #category : 'parsing' }
TTOS2TableParser >> process [
	| weightClass widthClass |
	entry skip: 4. "version(2) + xAvgCharWidth(2)"
	weightClass := entry nextUShort.
	widthClass := entry nextUShort.
	entry skip: 54. "fsType(2) + subscript, superscript and strikeout metrics(20)
	 + sFamilyClass(2) + panose(10) + ulUnicodeRange1 to 4(16) + achVendID(4)"
	^ Dictionary
		  with: #usWeightClass -> weightClass
		  with: #usWidthClass -> widthClass
		  with: #fsSelection -> entry nextUShort
]
