"
I hold the one-click examples for the text side of the VectorGraphics Cairo-compatible layer: a font face read from a system TrueType file, a scaled font at a size, the glyph atlas a drawn run fills, and one rasterised glyph mask.
My examples rebuild their object on every call and assert nothing. The font is a system file rather than one of Alexandrie's embedded fonts because this package, like the packages it shows off, names no Alexandrie class.
"
Class {
	#name : 'VGScaledFontExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Canvas-Fonts-Examples-Examples',
	#package : 'VectorGraphics-Canvas-Fonts-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGScaledFontExamples class >> atlasFilledByARunDrawnTwice [
	<sampleInstance>
	"The glyph atlas after the same run has been drawn twice, once moved by a whole pixel. The
	 rasterised glyph count is lower than the number of glyphs drawn, which is the point of the
	 atlas: a glyph is rasterised once for a given sub-pixel phase and matrix, and the space
	 inks nothing at all so it is never rasterised."

	| context |
	context := self contextWithTextDrawnThroughTheAtlas.
	context
		moveTo: 9 @ 44;
		showText: self exampleRun.
	^ context scaledFont atlas
]

{ #category : 'fixture' }
VGScaledFontExamples class >> canReadAFaceOf: aFileReference [
	"Whether this file reads into a face. A font of a format the reader refuses is a no and not a
	 failure: the question asked is which fonts of a machine the examples can show, and the font
	 directory holds collections, bitmap fonts and CFF2 files too."

	^ [ (VGFontFace newForFile: aFileReference) notNil ]
		  on: Error
		  do: [ :error | false ]
]

{ #category : 'fixture' }
VGScaledFontExamples class >> candidateFontFileNames [
	"Plain TrueType faces that carry glyph outlines in a glyf table, in the order they are
	 preferred. One of them is on almost any desktop; a font with its outlines in a CFF table
	 would not do, which is why the list is named rather than a search for any file at all."

	^ #( 'DejaVuSans.ttf' 'LiberationSans-Regular.ttf' 'NotoSans-Regular.ttf'
		  'AdwaitaSans-Regular.ttf' 'AdwaitaMono-Regular.ttf' )
]

{ #category : 'examples' }
VGScaledFontExamples class >> contextWithTextDrawnThroughTheAtlas [
	<sampleInstance>
	"A surface with a run of text on it, drawn the way a caller that does not shape draws it. The
	 context answers the surface it drew on, and the scaled font it used still holds the masks."

	| context |
	context := (VGCairoImageSurface extent: 180 @ 64) newContext.
	context
		scaledFont: self scaledFontAtAReadableSize;
		sourceColorR: 0.1 g: 0.1 b: 0.35;
		moveTo: 8 @ 44;
		showText: self exampleRun.
	^ context
]

{ #category : 'fixture' }
VGScaledFontExamples class >> exampleFontSize [
	"Big enough that a glyph mask has visible shape when it is inspected."

	^ 36
]

{ #category : 'fixture' }
VGScaledFontExamples class >> exampleRun [
	"A short run with a round letter, a straight letter and a space in it."

	^ 'Hi a'
]

{ #category : 'fixture' }
VGScaledFontExamples class >> fontDirectory [
	"Where a Linux distribution installs its fonts."

	^ '/usr/share/fonts' asFileReference
]

{ #category : 'fixture' }
VGScaledFontExamples class >> fontFace [
	"A font face over the first candidate system font, which is what every example here reads."

	^ VGFontFace newForFile: self fontFile
]

{ #category : 'examples' }
VGScaledFontExamples class >> fontFaceOfASystemFont [
	<sampleInstance>
	"The TrueType tables of a system font, read with no help from any other package: the glyph
	 count, the units per em, the cmap, the outlines and the family and style the font names
	 itself all come from the file itself. Open the Face tab to read the names back."

	^ self fontFace
]

{ #category : 'examples' }
VGScaledFontExamples class >> fontFaceOfAnOpenTypeFont [
	"The tables of an installed OpenType font, whose outlines are charstrings in a CFF table
	 rather than contours in a glyf table. The face reads the same way either format is
	 written: the same glyph count, the same metrics, the same outlines. Its glyphs draw
	 themselves the first time one is asked for its shape, so opening the face reads no
	 charstring at all.
	 Answers nil on a machine whose .otf files are all CFF2, a format the reader does not read.
	 Open the Glyphs tab and click a glyph to see one drawn.

	 VGScaledFontExamples fontFaceOfAnOpenTypeFont inspect"

	<sampleInstance>
	<needsAFontThisMachineMayLack: 'an installed font with a CFF table of Type 2 charstrings'>
	^ self openTypeFontFile ifNotNil: [ :file | VGFontFace newForFile: file ]
]

{ #category : 'fixture' }
VGScaledFontExamples class >> fontFile [
	"The first candidate font that is on this machine, searched for by name because the directory
	 a distribution puts a font family in is its own business."

	| files |
	self fontDirectory exists ifFalse: [
		^ Error signal: 'no font directory at ' , self fontDirectory fullName ].
	files := self fontDirectory allChildrenMatching: '*.ttf'.
	self candidateFontFileNames do: [ :each |
		(files detect: [ :file | file basename = each ] ifNone: [ nil ]) ifNotNil: [ :file |
			^ file ] ].
	^ Error signal: 'none of the candidate system fonts is installed under '
		  , self fontDirectory fullName
]

{ #category : 'examples' }
VGScaledFontExamples class >> glyphMaskOfOneLetter [
	<sampleInstance>
	"One rasterised glyph: an alpha mask with the offset that places it against the whole pixel
	 the glyph origin falls on. This is what the atlas caches and what a draw blits."

	| font context |
	font := self scaledFontAtAReadableSize.
	context := (VGCairoImageSurface extent: 64 @ 64) newContext.
	context
		scaledFont: font;
		moveTo: 8 @ 48;
		showText: 'a'.
	^ font atlas masks values detect: [ :each | each notNil ]
]

{ #category : 'fixture' }
VGScaledFontExamples class >> openTypeFontFile [
	"The first installed .otf file this layer can read into a face, or nil when the machine has
	 none. The extension alone is not the rule: a .otf can hold its outlines in CFF2, a format
	 the reader does not read, and such a file made the example raise on the missing table
	 instead of showing a face. This package may not name the reader's table classes, so
	 building the face is how the question is asked."

	self fontDirectory exists ifFalse: [ ^ nil ].
	^ (self fontDirectory allChildrenMatching: '*.otf')
		  detect: [ :each | self canReadAFaceOf: each ]
		  ifNone: [ nil ]
]

{ #category : 'examples' }
VGScaledFontExamples class >> scaledFontAtAReadableSize [
	<sampleInstance>
	"A font face at a size, which is the object that answers metrics and holds the glyph atlas.
	 It is immutable, so the same scaled font can be shared by every state of a context."

	^ VGScaledFont
		  fontFace: self fontFace
		  fontMatrix: (VGCairoMatrix newScalingBy: self exampleFontSize asPoint)
		  userToDeviceMatrix: VGCairoMatrix newIdentity
		  options: VGFontOptions new
]

{ #category : 'examples' }
VGScaledFontExamples class >> scaledFontBuiltTheWayCairoSpellsIt [
	<sampleInstance>
	"The same scaled font as #scaledFontAtAReadableSize, built the way a drawing written against
	 Alexandrie builds one: the options named through the four enumeration classes, and the font
	 asked of the face rather than of the scaled font class."

	^ self fontFace
		  newScaledFontWithFontMatrix:
			  (VGCairoMatrix newScalingBy: self exampleFontSize asPoint)
		  userToDeviceMatrix: VGCairoMatrix newIdentity
		  options: (VGFontOptions new
				   antialias: VGCairoAntialias gray;
				   hintMetrics: VGCairoHintMetrics off;
				   hintStyle: VGCairoHintStyle none;
				   subpixelOrder: VGCairoSubpixelOrder default;
				   yourself)
]

{ #category : 'examples' }
VGScaledFontExamples class >> textExtentsOfARun [
	<sampleInstance>
	"The geometry of a laid out run: the inked box relative to the origin of the first glyph, and
	 the advance to where the next run would start. This is the record a text backend reads to
	 place a line, and the one our fonts hand to Bloc."

	| font |
	font := self scaledFontAtAReadableSize.
	^ font glyphExtentsOf: (font glyphArrayForString: self exampleRun)
]
