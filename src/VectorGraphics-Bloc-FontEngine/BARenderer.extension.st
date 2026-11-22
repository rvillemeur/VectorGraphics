Extension { #name : 'BARenderer' }

{ #category : '*vectorgraphics-bloc-fontengine' }
BARenderer class >> measureTextDuring: aBlock [
	"Extension on BARenderer class, in this package because only the font engine knows what to
	 do about the answer. Every renderer class in play descends from me, and each says which
	 faces its text measuring reads, in measuresTextWithFacesOfThisProject. A renderer of this
	 project lays a string out in VGScaledFont, which reads the character map of a VGFontFace;
	 the Cairo kit draws a glyph through AeCairoContext >> scaledFont:, a uFFI call that reads
	 the FreeType handle of an AeFTFace. So the manager posed must build the faces the renderer
	 can draw, or the message sent to the face is not understood inside Bloc's measuring
	 process, where no test sees it."

	^ VGFontManager
		  poseFacesOfThisProject: self measuresTextWithFacesOfThisProject
		  during: aBlock
]
