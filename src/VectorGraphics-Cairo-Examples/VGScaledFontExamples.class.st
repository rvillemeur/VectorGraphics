"
I hold the one-click examples for the text side of the VectorGraphics Cairo-compatible layer: a font face read from a system TrueType file, a scaled font at a size, the glyph atlas a drawn run fills, and one rasterised glyph mask.
My examples rebuild their object on every call and assert nothing. The font is a system file rather than one of Alexandrie's embedded fonts because this package, like the packages it shows off, names no Alexandrie class.
"
Class {
	#name : 'VGScaledFontExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples-Examples',
	#package : 'VectorGraphics-Cairo-Examples',
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
	 count, the units per em, the cmap and the outlines all come from the file itself."

	^ self fontFace
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
